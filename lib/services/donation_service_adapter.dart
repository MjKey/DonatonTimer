import 'dart:async';
import '../models/donation.dart';

/// Статус подключения адаптера донат-сервиса.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Базовый интерфейс для адаптеров донат-сервисов.
abstract class DonationServiceAdapter {
  /// The name of the donation service.
  String get serviceName;

  /// Whether the adapter is currently connected.
  bool get isConnected;

  /// Current connection status.
  ConnectionStatus get status;

  /// Stream of donations received from the service.
  Stream<Donation> get donationStream;

  /// Stream of connection status changes.
  Stream<ConnectionStatus> get statusStream;

  /// Connects to the donation service.
  /// [config] contains service-specific configuration (tokens, URLs, etc.)
  Future<void> connect(Map<String, dynamic> config);

  /// Disconnects from the donation service.
  Future<void> disconnect();

  /// Disposes of resources used by the adapter.
  Future<void> dispose();
}

/// Базовая реализация адаптера донат-сервиса.
abstract class BaseDonationServiceAdapter implements DonationServiceAdapter {
  final StreamController<Donation> _donationController = StreamController<Donation>.broadcast();
  final StreamController<ConnectionStatus> _statusController = StreamController<ConnectionStatus>.broadcast();
  
  ConnectionStatus _status = ConnectionStatus.disconnected;
  
  @override
  ConnectionStatus get status => _status;
  
  @override
  bool get isConnected => _status == ConnectionStatus.connected;
  
  @override
  Stream<Donation> get donationStream => _donationController.stream;
  
  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  
  /// Updates the connection status and notifies listeners.
  void updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }
  
  /// Emits a donation to the stream.
  void emitDonation(Donation donation) {
    _donationController.add(donation);
  }
  
  @override
  Future<void> dispose() async {
    await disconnect();
    await _donationController.close();
    await _statusController.close();
  }
}
