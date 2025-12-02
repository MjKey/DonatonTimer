import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../models/donation.dart';
import '../models/donation_record.dart';
import '../models/service_config.dart';
import '../models/statistics.dart';
import 'donation_service_adapter.dart';
import 'storage_service.dart';
import 'log_manager.dart';

/// Сервис для управления адаптерами донат-сервисов и обработки донатов.
class DonationService extends ChangeNotifier {
  final StorageService _storageService;
  
  /// List of registered donation service adapters.
  final List<DonationServiceAdapter> _adapters = [];
  
  /// Set of processed donation IDs for duplicate detection.
  final Set<String> _processedDonationIds = {};
  
  /// Stream subscriptions for each adapter.
  final Map<String, StreamSubscription<Donation>> _subscriptions = {};
  
  /// Combined stream controller for all donations.
  final StreamController<Donation> _donationController = StreamController<Donation>.broadcast();
  
  /// Current statistics.
  Statistics _statistics = const Statistics();
  
  /// Application settings.
  AppSettings _settings = const AppSettings();
  
  /// Rate for calculating time (amount per 60 minutes).
  double _rate = 600.0;
  
  /// Callback for when time should be added to the timer.
  void Function(int seconds)? onTimeAdded;
  
  /// Callback for broadcasting timer updates.
  void Function(Map<String, dynamic> message)? onBroadcast;
  
  /// Creates a DonationService with the given StorageService.
  DonationService(this._storageService);
  
  /// Gets the list of registered adapters.
  List<DonationServiceAdapter> get adapters => List.unmodifiable(_adapters);
  
  /// Gets the combined stream of donations from all adapters.
  Stream<Donation> get donationStream => _donationController.stream;
  
  /// Gets the current statistics.
  Statistics get statistics => _statistics;
  
  /// Gets the current rate.
  double get rate => _rate;

  /// Gets the current settings.
  AppSettings get settings => _settings;

  /// Sets the rate for calculating time.
  set rate(double value) {
    if (value > 0) {
      _rate = value;
    }
  }
  
  /// Initializes the service by loading saved statistics and settings.
  Future<void> init() async {
    // Load settings
    final savedSettings = _storageService.loadSettings();
    if (savedSettings != null) {
      _settings = savedSettings;
      _rate = savedSettings.minutesPerAmount;
    }
    
    // Load statistics
    final savedStats = _storageService.loadStatistics();
    if (savedStats != null) {
      _statistics = savedStats;
    }
    
    notifyListeners();
  }
  
  /// Updates the application settings.
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    _rate = newSettings.minutesPerAmount;
    await _storageService.saveSettings(newSettings);
    notifyListeners();
  }
  
  /// Updates a service configuration.
  Future<void> updateServiceConfig(ServiceConfig config) async {
    _settings = _settings.updateServiceConfig(config);
    await _storageService.saveSettings(_settings);
    
    // Reconnect the adapter if it exists and is enabled
    final adapter = getAdapter(config.serviceName);
    if (adapter != null) {
      if (config.enabled) {
        try {
          await adapter.connect(config.credentials);
        } catch (e) {
          debugPrint('Failed to connect ${config.serviceName}: $e');
        }
      } else {
        try {
          await adapter.disconnect();
        } catch (e) {
          debugPrint('Failed to disconnect ${config.serviceName}: $e');
        }
      }
    }
    
    notifyListeners();
  }
  
  /// Registers a donation service adapter.
  /// The adapter's donation stream will be merged into the combined stream.
  void registerAdapter(DonationServiceAdapter adapter) {
    if (_adapters.any((a) => a.serviceName == adapter.serviceName)) {
      debugPrint('Adapter ${adapter.serviceName} already registered');
      return;
    }
    
    _adapters.add(adapter);
    _subscribeToAdapter(adapter);
    notifyListeners();
  }
  
  /// Unregisters a donation service adapter by name.
  void unregisterAdapter(String serviceName) {
    final adapter = _adapters.firstWhere(
      (a) => a.serviceName == serviceName,
      orElse: () => throw ArgumentError('Adapter $serviceName not found'),
    );
    
    _unsubscribeFromAdapter(serviceName);
    _adapters.remove(adapter);
    notifyListeners();
  }
  
  /// Gets an adapter by service name.
  DonationServiceAdapter? getAdapter(String serviceName) {
    try {
      return _adapters.firstWhere((a) => a.serviceName == serviceName);
    } catch (_) {
      return null;
    }
  }
  
  /// Subscribes to an adapter's donation stream.
  void _subscribeToAdapter(DonationServiceAdapter adapter) {
    final subscription = adapter.donationStream.listen(
      (donation) => _processDonation(donation),
      onError: (error) {
        debugPrint('Error from ${adapter.serviceName}: $error');
      },
    );
    _subscriptions[adapter.serviceName] = subscription;
  }
  
  /// Unsubscribes from an adapter's donation stream.
  void _unsubscribeFromAdapter(String serviceName) {
    _subscriptions[serviceName]?.cancel();
    _subscriptions.remove(serviceName);
  }
  
  /// Обрабатывает донат от любого адаптера.
  void _processDonation(Donation donation) {
    // Create unique key combining service name and donation ID
    final uniqueKey = '${donation.serviceName}:${donation.id}';
    
    // Check for duplicate
    if (_processedDonationIds.contains(uniqueKey)) {
      LogManager.warning('Дубликат доната игнорирован: $uniqueKey');
      return;
    }
    
    LogManager.info('Получен донат: ${donation.username} - ${donation.amount} ${donation.currency} от ${donation.serviceName}');
    
    // Mark as processed
    _processedDonationIds.add(uniqueKey);
    
    // Limit the size of processed IDs set to prevent memory issues
    if (_processedDonationIds.length > 10000) {
      // Remove oldest entries (first 1000)
      final toRemove = _processedDonationIds.take(1000).toList();
      for (final id in toRemove) {
        _processedDonationIds.remove(id);
      }
    }
    
    // Рассчитываем время для добавления
    final secondsToAdd = donation.calculateSeconds(_rate);
    final minutesAdded = (secondsToAdd / 60).round();
    
    // Create donation record for statistics
    final record = DonationRecord(
      username: donation.username,
      minutesAdded: minutesAdded,
      timestamp: donation.timestamp,
      serviceName: donation.serviceName,
      amount: donation.amount,
      currency: donation.currency,
    );
    
    // Обновляем статистику
    _statistics = _statistics.addDonation(record);
    _saveStatistics();
    
    // Emit donation to combined stream
    _donationController.add(donation);
    
    // Добавляем время к таймеру
    if (onTimeAdded != null && secondsToAdd > 0) {
      onTimeAdded!(secondsToAdd);
    }
    
    // Отправляем обновление
    if (onBroadcast != null) {
      onBroadcast!({
        'type': 'donation',
        'username': donation.username,
        'amount': donation.amount,
        'currency': donation.currency,
        'minutesAdded': minutesAdded,
        'service': donation.serviceName,
      });
    }
    
    notifyListeners();
    LogManager.info('Обработан донат: ${donation.username} - ${donation.amount} ${donation.currency} = $minutesAdded мин');
  }

  /// Manually processes a donation (for testing or manual entry).
  void processDonation(Donation donation) {
    _processDonation(donation);
  }
  
  /// Connects all enabled adapters with their configurations.
  Future<void> connectAll(Map<String, Map<String, dynamic>> configs) async {
    for (final adapter in _adapters) {
      final config = configs[adapter.serviceName];
      if (config != null && config['enabled'] == true) {
        try {
          await adapter.connect(config);
          debugPrint('Connected to ${adapter.serviceName}');
        } catch (e) {
          debugPrint('Failed to connect to ${adapter.serviceName}: $e');
        }
      }
    }
  }
  
  /// Disconnects all adapters.
  Future<void> disconnectAll() async {
    for (final adapter in _adapters) {
      try {
        await adapter.disconnect();
        debugPrint('Disconnected from ${adapter.serviceName}');
      } catch (e) {
        debugPrint('Error disconnecting from ${adapter.serviceName}: $e');
      }
    }
  }
  
  /// Connects a specific adapter.
  Future<void> connectAdapter(String serviceName, Map<String, dynamic> config) async {
    final adapter = getAdapter(serviceName);
    if (adapter == null) {
      throw ArgumentError('Adapter $serviceName not found');
    }
    await adapter.connect(config);
  }
  
  /// Disconnects a specific adapter.
  Future<void> disconnectAdapter(String serviceName) async {
    final adapter = getAdapter(serviceName);
    if (adapter == null) {
      throw ArgumentError('Adapter $serviceName not found');
    }
    await adapter.disconnect();
  }
  
  /// Gets the connection status of all adapters.
  Map<String, ConnectionStatus> getConnectionStatuses() {
    final statuses = <String, ConnectionStatus>{};
    for (final adapter in _adapters) {
      statuses[adapter.serviceName] = adapter.status;
    }
    return statuses;
  }
  
  /// Clears the statistics.
  void clearStatistics() {
    _statistics = const Statistics();
    _saveStatistics();
    notifyListeners();
  }
  
  /// Clears the processed donation IDs cache.
  void clearProcessedIds() {
    _processedDonationIds.clear();
  }
  
  /// Saves statistics to persistent storage.
  Future<void> _saveStatistics() async {
    try {
      await _storageService.saveStatistics(_statistics);
    } catch (e) {
      debugPrint('Error saving statistics: $e');
    }
  }
  
  /// Disposes of all resources.
  @override
  Future<void> dispose() async {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    
    // Disconnect and dispose all adapters
    for (final adapter in _adapters) {
      try {
        await adapter.dispose();
      } catch (e) {
        debugPrint('Error disposing ${adapter.serviceName}: $e');
      }
    }
    _adapters.clear();
    
    // Close the combined stream
    await _donationController.close();
    
    super.dispose();
  }
}
