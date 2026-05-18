import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import '../models/donation.dart';
import 'donation_service_adapter.dart';
import 'log_manager.dart';

/// Адаптер для CloudTips.
/// Использует WebSocket (протокол SignalR/JSON) для получения донатов.
///
/// Протокол:
/// 1. GET /notification/{token}/init -> {"connectionToken": "..."}
/// 2. GET /connection?connectionToken=...&authType=Notifications -> {"status":"Ok"}
/// 3. WSS /notification/socket?connectionToken=...
///    -> Отправить: {"protocol":"json","version":1}\x1e
///    -> Слушать type=1, target="SendNotification"
///    -> Ping/pong: на {"type":6} отвечаем {"type":6}\x1e
class CloudTipsAdapter extends BaseDonationServiceAdapter {
  final Logger _logger = Logger('CloudTipsAdapter');

  WebSocket? _webSocket;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  /// Токен из URL ссылки (последний сегмент пути)
  String? _linkToken;

  /// Токен подключения, полученный от API
  String? _connectionToken;

  static const String _apiBase = 'streamers-api.cloudtips.ru';
  static const String _wsBase = 'wss://streamers-api.cloudtips.ru:3030';

  /// Разделитель сообщений SignalR (Record Separator, 0x1e)
  static const String _signalrTerminator = '\x1e';

  @override
  String get serviceName => 'CloudTips';

  /// Маскирует токен, оставляя только первые 5 символов
  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'null';
    if (token.length <= 5) return '***';
    return '${token.substring(0, 5)}***';
  }

  /// Извлекает токен из ссылки вида:
  /// https://stream.cloudtips.ru/n/AAAL4ItkOPY2iphRhUCY
  static String? extractLinkToken(String input) {
    input = input.trim();
    // Пробуем разобрать как URL
    final uri = Uri.tryParse(input);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      // Берём последний сегмент пути
      final last = uri.pathSegments.last;
      if (last.isNotEmpty) return last;
    }
    // Если это просто голый токен без URL
    if (!input.contains('/') && !input.contains(' ')) {
      return input;
    }
    return null;
  }

  @override
  Future<void> connect(Map<String, dynamic> config) async {
    await disconnect();

    final input = config['token'] as String?;
    if (input == null || input.isEmpty) {
      LogManager.warning('CloudTips: токен или ссылка не указаны');
      updateStatus(ConnectionStatus.error);
      return;
    }

    _linkToken = extractLinkToken(input);
    if (_linkToken == null) {
      LogManager.warning('CloudTips: не удалось извлечь токен из "$input"');
      updateStatus(ConnectionStatus.error);
      return;
    }

    LogManager.info('CloudTips: токен ${_maskToken(_linkToken)}, инициализация...');
    updateStatus(ConnectionStatus.connecting);
    await _initConnection();
  }

  Future<void> _initConnection() async {
    try {
      final httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);

      // 1. Получаем connectionToken
      final initUrl = Uri.https(_apiBase, '/notification/$_linkToken/init');
      final initReq = await httpClient.getUrl(initUrl);
      final initResp = await initReq.close();

      if (initResp.statusCode != 200) {
        throw Exception('init failed: HTTP ${initResp.statusCode}');
      }

      final initBody = await initResp.transform(utf8.decoder).join();
      final initJson = json.decode(initBody) as Map<String, dynamic>;
      _connectionToken = initJson['connectionToken'] as String?;
      httpClient.close();

      if (_connectionToken == null || _connectionToken!.isEmpty) {
        throw Exception('connectionToken not found in response');
      }

      LogManager.info('CloudTips: connectionToken получен (${_maskToken(_connectionToken)}), подключение к WS...');

      // 2. Подключаемся к WebSocket
      final wsUrl = '$_wsBase/notification/socket?connectionToken=${Uri.encodeComponent(_connectionToken!)}';
      _webSocket = await WebSocket.connect(wsUrl);

      LogManager.info('CloudTips: WebSocket подключён, отправка handshake...');
      updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      // 3. SignalR handshake
      _webSocket!.add('${json.encode({"protocol": "json", "version": 1})}$_signalrTerminator');

      // 4. Слушаем входящие сообщения
      _webSocket!.listen(
        _handleMessage,
        onError: (e) {
          _logger.severe('WebSocket error: $e');
          LogManager.error('CloudTips: ошибка WS - $e');
          _handleDisconnect();
        },
        onDone: () {
          LogManager.warning('CloudTips: WS соединение закрыто');
          _handleDisconnect();
        },
      );

      // 5. Periodic ping каждые 15 секунд (на случай если сервер не пингует)
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (_webSocket?.readyState == WebSocket.open) {
          _webSocket!.add('${json.encode({"type": 6})}$_signalrTerminator');
        }
      });
    } catch (e, st) {
      _logger.severe('CloudTips connect error: $e\n$st');
      LogManager.error('CloudTips: ошибка подключения - $e');
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    final text = raw.toString();
    // SignalR разделяет сообщения символом \x1e
    final parts = text.split(_signalrTerminator);
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      try {
        final msg = json.decode(trimmed) as Map<String, dynamic>;
        _processMessage(msg);
      } catch (_) {
        // Игнорируем нераспознанные сообщения
      }
    }
  }

  void _processMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as int?;

    // Ping - отвечаем pong
    if (type == 6) {
      if (_webSocket?.readyState == WebSocket.open) {
        _webSocket!.add('${json.encode({"type": 6})}$_signalrTerminator');
      }
      return;
    }

    // type=1 — это вызов метода на клиенте
    if (type == 1) {
      final target = msg['target'] as String?;
      if (target != 'SendNotification') return;

      final arguments = msg['arguments'] as List<dynamic>?;
      if (arguments == null || arguments.isEmpty) return;

      final payload = arguments[0] as Map<String, dynamic>?;
      if (payload == null) return;

      _processDonation(payload);
    }
  }

  void _processDonation(Map<String, dynamic> payload) {
    try {
      // Сумму берём ТОЛЬКО из поля title по шаблону "... N₽."
      // Защита: ищем последнее вхождение числа перед знаком ₽
      final title = payload['title'] as String? ?? '';
      final amount = _extractAmountFromTitle(title);
      if (amount == null || amount <= 0) {
        LogManager.warning('CloudTips: не удалось извлечь сумму из "$title"');
        return;
      }

      // Извлекаем имя из title: всё до " отправил"
      final username = _extractUsernameFromTitle(title);

      final comment = payload['comment'] as String?;
      final id = payload['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();

      final donation = Donation(
        id: '${serviceName}_$id',
        serviceName: serviceName,
        username: username,
        amount: amount,
        currency: 'RUB',
        message: comment,
        timestamp: DateTime.now(),
      );

      _logger.info('Donation: $username - $amount RUB');
      LogManager.info('CloudTips: донат от $username - $amount RUB');
      emitDonation(donation);
    } catch (e, st) {
      _logger.severe('Error processing CloudTips donation: $e\n$st');
      LogManager.error('CloudTips: ошибка обработки доната - $e');
    }
  }

  /// Извлекает сумму из строки вида "Имя отправил 49₽."
  /// Берём ПОСЛЕДНЕЕ число непосредственно перед знаком ₽.
  /// Это защищает от случаев, когда пользователь вписывает число/₽ в имя.
  double? _extractAmountFromTitle(String title) {
    // Ищем: последовательность цифр (возможно с запятой/точкой), стоящая прямо перед "₽"
    final matches = RegExp(r'(\d[\d\s]*)₽').allMatches(title);
    if (matches.isEmpty) return null;

    // Берём ПОСЛЕДНЕЕ совпадение
    final last = matches.last;
    final numberStr = last.group(1)?.replaceAll(RegExp(r'\s'), '').trim();
    if (numberStr == null || numberStr.isEmpty) return null;
    return double.tryParse(numberStr.replaceAll(',', '.'));
  }

  /// Извлекает имя из строки "Имя отправил 49₽."
  /// Обрезаем по последнему вхождению " отправил "
  String _extractUsernameFromTitle(String title) {
    final idx = title.lastIndexOf(' отправил ');
    if (idx > 0) {
      return title.substring(0, idx).trim();
    }
    return title;
  }

  void _handleDisconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    if (status != ConnectionStatus.disconnected) {
      updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.severe('Max reconnect attempts reached');
      LogManager.error('CloudTips: превышено число попыток переподключения');
      updateStatus(ConnectionStatus.error);
      return;
    }

    _reconnectTimer?.cancel();
    final delay = _reconnectDelay * (_reconnectAttempts + 1);
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      LogManager.info('CloudTips: попытка переподключения #$_reconnectAttempts...');
      updateStatus(ConnectionStatus.reconnecting);
      _initConnection();
    });
  }

  @override
  Future<void> disconnect() async {
    LogManager.info('CloudTips: отключение...');
    updateStatus(ConnectionStatus.disconnected);

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer = null;

    await _webSocket?.close();
    _webSocket = null;

    LogManager.info('CloudTips: отключено');
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
  }
}
