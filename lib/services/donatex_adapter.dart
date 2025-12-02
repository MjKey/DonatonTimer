import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';
import '../models/donation.dart';
import 'donation_service_adapter.dart';
import 'log_manager.dart';

/// Адаптер для DonateX.
/// Использует SignalR WebSocket протокол.
class DonateXAdapter extends BaseDonationServiceAdapter {
  static const String _negotiateUrl = 'https://donatex.gg/api/controls-hub/negotiate?negotiateVersion=1';
  static const String _wsBaseUrl = 'wss://donatex.gg/api/donations-hub';
  
  final Logger _logger = Logger('DonateXAdapter');
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _authToken;
  String? _widgetId;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 15);
  
  // SignalR record separator
  static const String _recordSeparator = '\x1e';
  
  @override
  String get serviceName => 'DonateX';
  
  @override
  Future<void> connect(Map<String, dynamic> config) async {
    _authToken = config['token'] as String?;
    _widgetId = config['widgetId'] as String?;
    
    if (_authToken == null || _authToken!.isEmpty) {
      LogManager.warning('DonateX: токен не указан');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    if (_widgetId == null || _widgetId!.isEmpty) {
      LogManager.warning('DonateX: widget ID не указан');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    updateStatus(ConnectionStatus.connecting);
    LogManager.info('DonateX: подключение...');
    
    try {
      // Get connection token via negotiate
      LogManager.info('DonateX: получение connectionToken...');
      final connectionToken = await _negotiate();
      if (connectionToken == null) {
        LogManager.error('DonateX: не удалось получить connectionToken');
        updateStatus(ConnectionStatus.error);
        return;
      }
      LogManager.info('DonateX: connectionToken получен');
      
      // Connect via WebSocket
      await _initWebSocket(connectionToken);
      
    } catch (e, stackTrace) {
      _logger.severe('Error connecting to DonateX: $e\n$stackTrace');
      LogManager.error('DonateX: ошибка подключения - $e');
      updateStatus(ConnectionStatus.error);
    }
  }
  
  Future<String?> _negotiate() async {
    try {
      final response = await http.post(
        Uri.parse(_negotiateUrl),
        headers: {'Authorization': 'Bearer $_authToken'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['connectionToken'] as String?;
      }
      
      LogManager.error('DonateX: ошибка negotiate - ${response.statusCode}');
      return null;
    } catch (e) {
      LogManager.error('DonateX: ошибка запроса negotiate - $e');
      return null;
    }
  }
  
  Future<void> _initWebSocket(String connectionToken) async {
    try {
      final wsUrl = '$_wsBaseUrl?id=$connectionToken';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      LogManager.info('DonateX: WebSocket создан');
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          LogManager.error('DonateX: ошибка WebSocket - $error');
          updateStatus(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          LogManager.warning('DonateX: соединение закрыто (code: $closeCode, reason: $closeReason)');
          if (status != ConnectionStatus.disconnected) {
            updateStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          }
        },
      );
      
      // Send protocol handshake after small delay
      Future.delayed(const Duration(milliseconds: 100), _sendProtocolHandshake);
      
    } catch (e) {
      LogManager.error('DonateX: ошибка создания WebSocket - $e');
      updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }
  
  void _sendProtocolHandshake() {
    // SignalR protocol handshake
    final handshake = jsonEncode({'protocol': 'json', 'version': 1});
    _channel?.sink.add('$handshake$_recordSeparator');
    LogManager.info('DonateX: отправлен protocol handshake');
  }
  
  void _sendPing() {
    // SignalR ping (type: 6)
    final ping = jsonEncode({'type': 6});
    _channel?.sink.add('$ping$_recordSeparator');
  }
  
  void _joinWidgetGroup() {
    // Join donation widget group
    final joinMsg = jsonEncode({
      'arguments': [_widgetId],
      'invocationId': '0',
      'target': 'JoinDonationWidgetGroup',
      'type': 1,
    });
    _channel?.sink.add('$joinMsg$_recordSeparator');
    LogManager.info('DonateX: подписка на виджет $_widgetId');
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      _sendPing();
    });
  }
  
  void _handleMessage(dynamic message) {
    final data = message.toString();
    
    // Split by record separator (SignalR sends multiple messages)
    for (final part in data.split(_recordSeparator)) {
      if (part.trim().isEmpty) continue;
      
      try {
        final json = jsonDecode(part) as Map<String, dynamic>;
        
        // Empty {} response after handshake is normal
        if (json.isEmpty) {
          // Handshake acknowledged, send ping and join group
          _sendPing();
          _joinWidgetGroup();
          updateStatus(ConnectionStatus.connected);
          _reconnectAttempts = 0;
          _startPingTimer();
          LogManager.info('DonateX: подключено');
          continue;
        }
        
        _processSignalRMessage(json);
      } catch (e) {
        LogManager.info('DonateX: не-JSON сообщение: $part');
      }
    }
  }
  
  void _processSignalRMessage(Map<String, dynamic> json) {
    final type = json['type'] as int?;
    final target = json['target'] as String?;
    
    // type 1 = invocation (donation or response)
    if (type == 1 && target == 'ReceiveDonation') {
      final arguments = json['arguments'] as List?;
      if (arguments != null && arguments.isNotEmpty) {
        _handleDonation(arguments[0] as Map<String, dynamic>);
      }
      return;
    }
    
    // type 6 = ping response, ignore
    if (type == 6) return;
    
    // type 7 = close
    if (type == 7) {
      LogManager.warning('DonateX: сервер закрыл соединение');
      return;
    }
    
    // Log other messages for debugging
    final logData = json.toString();
    LogManager.info('DonateX: получено: ${logData.length > 200 ? '${logData.substring(0, 200)}...' : logData}');
  }
  
  void _handleDonation(Map<String, dynamic> data) {
    try {
      final id = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final username = data['username'] as String? ?? 'Anonymous';
      final amount = _parseDoubleField(data['amount']);
      final currency = data['currency'] as String? ?? 'RUB';
      final donationMessage = data['message'] as String?;
      
      final donation = Donation(
        id: '${serviceName}_$id',
        serviceName: serviceName,
        username: username,
        amount: amount,
        currency: currency,
        message: donationMessage,
        timestamp: DateTime.now(),
      );
      
      LogManager.info('DonateX: донат от $username - $amount $currency');
      emitDonation(donation);
      
    } catch (e, stackTrace) {
      LogManager.error('DonateX: ошибка обработки доната - $e');
      _logger.severe('Error: $e\n$stackTrace');
    }
  }
  
  double _parseDoubleField(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      LogManager.error('DonateX: превышено число попыток переподключения');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () async {
      _reconnectAttempts++;
      LogManager.info('DonateX: попытка переподключения #$_reconnectAttempts');
      updateStatus(ConnectionStatus.reconnecting);
      
      final connectionToken = await _negotiate();
      if (connectionToken != null) {
        await _initWebSocket(connectionToken);
      } else {
        _scheduleReconnect();
      }
    });
  }
  
  @override
  Future<void> disconnect() async {
    LogManager.info('DonateX: отключение...');
    updateStatus(ConnectionStatus.disconnected);
    
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    
    _channel = null;
    _subscription = null;
    LogManager.info('DonateX: отключено');
  }
  
  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
  }
}
