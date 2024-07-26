import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logging/logging.dart';

class SocketService {
  late IO.Socket socket;
  final Logger _logger = Logger('SocketService');
  final String token;
  final String socketUrl;

  SocketService(this.token, this.socketUrl) {
    _logger.info('Инициализация SocketService');
    _initSocket();
  }

  void _initSocket() {
    _logger.info('Инициализация socket соединения');
    socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      _logger.info('Socket подключен');
      socket.emit('add-user', {'token': token, 'type': 'minor'});
      _logger.info('Отправлен запрос на добавление пользователя');
    });

    socket.on('connect_error', (error) {
      print('Connection error: $error');
      _logger.severe('Ошибка подключения socket: $error');
    });

    socket.on('error', (error) {
      _logger.severe('Socket ошибка: $error');
    });

    socket.on('disconnect', (reason) {
      _logger.warning('Socket отключен. Причина: $reason');
    });

    socket.on('reconnect', (attemptNumber) {
      _logger.info('Socket переподключен. Попытка №$attemptNumber');
    });

    socket.on('reconnect_attempt', (attemptNumber) {
      _logger.info('Попытка переподключения socket. Попытка №$attemptNumber');
    });
  }

  Future<void> connect() async {
    _logger.info('Подключение к socket');
    socket.connect();
    await Future.delayed(Duration(seconds: 2));
    if (socket.connected) {
      _logger.info('Socket успешно подключен');
    } else {
      _logger.warning('Не удалось подключиться к socket');
    }
  }

  Future<void> dispose() async {
    _logger.info('Закрытие socket соединения');
    socket.disconnect();
    socket.dispose();
    await Future.delayed(Duration(milliseconds: 500));
    _logger.info('Socket соединение закрыто');
  }
}
