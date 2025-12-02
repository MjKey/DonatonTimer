import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';
import '../models/donation.dart';
import 'donation_service_adapter.dart';
import 'log_manager.dart';

/// Адаптер для Donate.Stream.
/// Использует WebSocket с протоколом Socket.IO.
class DonateStreamAdapter extends BaseDonationServiceAdapter {
  static const String _wsUrl = 'wss://donate.stream/wss/socket.io/?EIO=4&transport=websocket';
  
  final Logger _logger = Logger('DonateStreamAdapter');
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  String? _token;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 25);
  
  @override
  String get serviceName => 'DonateStream';
  
  /// Extracts token from URL or returns the input if it's already a token.
  /// Supports: https://donate.stream/widget-alert?uid=XXX&token=YYY
  static String extractToken(String input) {
    if (input.contains('donate.stream') && input.contains('token=')) {
      final uri = Uri.tryParse(input);
      if (uri != null) {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
    }
    return input;
  }
  
  @override
  Future<void> connect(Map<String, dynamic> config) async {
    final rawToken = config['token'] as String?;
    _token = rawToken != null ? extractToken(rawToken) : null;
    
    if (_token == null || _token!.isEmpty) {
      _logger.warning('Token is required for DonateStream connection');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    updateStatus(ConnectionStatus.connecting);
    _logger.info('Connecting to DonateStream...');
    
    await _initWebSocket();
  }
  
  Future<void> _initWebSocket() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _logger.severe('WebSocket error: $error');
          updateStatus(ConnectionStatus.error);
          _scheduleReconnect();
        },
        onDone: () {
          _logger.warning('WebSocket connection closed');
          if (status != ConnectionStatus.disconnected) {
            updateStatus(ConnectionStatus.reconnecting);
            _scheduleReconnect();
          }
        },
      );
      
      _logger.info('WebSocket connection established');
      
    } catch (e, stackTrace) {
      _logger.severe('Error connecting to DonateStream: $e\n$stackTrace');
      updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    final data = message.toString();
    _logger.fine('Received message: $data');
    
    // Handle Socket.IO ping/pong
    // Server sends: 2, Client responds: 3
    if (data == '2') {
      _channel?.sink.add('3');
      _logger.fine('Ping received, pong sent');
      return;
    }
    
    // Handle initial connection: 0{"sid": ...}
    if (data.startsWith('0')) {
      _channel?.sink.add('40');
      _logger.info('Initial handshake, sent 40');
      return;
    }
    
    // Handle auth request: 42["auth"...]
    if (data.startsWith('42["auth"')) {
      _sendAuthToken();
      return;
    }
    
    // Handle successful auth: contains "authResult"
    if (data.contains('"authResult"')) {
      _logger.info('Authentication successful');
      LogManager.info('DonateStream: подключено');
      _joinChannels();
      updateStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startPingTimer();
      return;
    }
    
    // Handle donation alert: 42["alert"...]
    if (data.startsWith('42["alert"')) {
      _handleAlert(data);
      return;
    }
  }
  
  void _sendAuthToken() {
    final authMessage = '42["auth.token",{"token":"$_token"}]';
    _channel?.sink.add(authMessage);
    _logger.info('Sent auth token');
  }
  
  void _joinChannels() {
    // Join donates channel
    _channel?.sink.add('42["join",{"channel":"donates"}]');
    _logger.info('Joined donates channel');
    
    // Join widget-alerts channel
    _channel?.sink.add('42["join",{"channel":"widget-alerts"}]');
    _logger.info('Joined widget-alerts channel');
  }
  
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      // Send ping to keep connection alive
      _channel?.sink.add('2');
    });
  }
  
  void _handleAlert(String data) {
    try {
      // Remove "42" prefix and parse JSON array
      final jsonStr = data.substring(2);
      final arr = json.decode(jsonStr) as List;
      
      if (arr.length < 2) {
        _logger.warning('Invalid alert format');
        return;
      }
      
      final alertData = arr[1] as Map<String, dynamic>;
      
      final id = alertData['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final username = alertData['nickname'] as String? ?? 'Anonymous';
      final sum = _parseDoubleField(alertData['sum']);
      final currency = alertData['currency'] as String? ?? 'RUB';
      final message = alertData['message'] as String?;
      
      // Only process RUB donations
      if (currency != 'RUB') {
        _logger.info('Skipping non-RUB donation: currency=$currency');
        return;
      }
      
      final donation = Donation(
        id: '${serviceName}_$id',
        serviceName: serviceName,
        username: username,
        amount: sum,
        currency: currency,
        message: message,
        timestamp: DateTime.now(),
      );
      
      _logger.info('Processed donation: $donation');
      emitDonation(donation);
      
    } catch (e, stackTrace) {
      _logger.severe('Error processing alert: $e\n$stackTrace');
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
      _logger.severe('Max reconnect attempts reached');
      updateStatus(ConnectionStatus.error);
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      _logger.info('Reconnect attempt #$_reconnectAttempts');
      updateStatus(ConnectionStatus.reconnecting);
      _initWebSocket();
    });
  }
  
  @override
  Future<void> disconnect() async {
    _logger.info('Disconnecting from DonateStream...');
    updateStatus(ConnectionStatus.disconnected);
    
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    
    _channel = null;
    _subscription = null;
    _logger.info('Disconnected from DonateStream');
  }
  
  @override
  Future<void> dispose() async {
    await disconnect();
    await super.dispose();
  }
}
