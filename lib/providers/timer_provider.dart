import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/log_manager.dart';

/// Провайдер для управления состоянием таймера донатона.
class TimerProvider extends ChangeNotifier {
  final StorageService _storageService;
  
  int _duration = 0;
  bool _isRunning = false;
  Timer? _timer;
  
  /// Creates a TimerProvider with the given StorageService.
  TimerProvider(this._storageService);
  
  /// Current timer duration in seconds.
  int get duration => _duration;
  
  /// Whether the timer is currently running (counting down).
  bool get isRunning => _isRunning;
  
  /// Hours component of the current duration.
  int get hours => _duration ~/ 3600;
  
  /// Minutes component of the current duration (0-59).
  int get minutes => (_duration % 3600) ~/ 60;
  
  /// Seconds component of the current duration (0-59).
  int get seconds => _duration % 60;
  
  /// Initializes the provider by loading saved timer state.
  Future<void> init() async {
    final savedDuration = _storageService.loadTimerDuration();
    if (savedDuration != null && savedDuration > 0) {
      _duration = savedDuration;
      notifyListeners();
    }
  }

  /// Starts the timer countdown.
  void start() {
    if (_isRunning) return;
    if (_duration <= 0) return;
    
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    LogManager.info('Таймер запущен: ${formatDuration()}');
    notifyListeners();
  }
  
  /// Stops the timer countdown.
  void stop() {
    if (!_isRunning) return;
    
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    LogManager.info('Таймер остановлен: ${formatDuration()}');
    notifyListeners();
  }
  
  /// Toggles between running and stopped states.
  void toggle() {
    if (_isRunning) {
      stop();
    } else {
      start();
    }
  }
  
  /// Adds time to the timer.
  /// [seconds] - Number of seconds to add (can be negative for subtraction).
  void addTime(int seconds) {
    _duration += seconds;
    if (_duration < 0) {
      _duration = 0;
    }
    _saveTimerDuration();
    notifyListeners();
  }
  
  /// Adds one minute (60 seconds) to the timer.
  void addMinute() {
    addTime(60);
  }
  
  /// Subtracts one minute (60 seconds) from the timer.
  void subtractMinute() {
    addTime(-60);
  }
  
  /// Adds specified number of minutes to the timer.
  void addMinutes(int minutes) {
    addTime(minutes * 60);
  }
  
  /// Sets the timer to a specific time.
  void setTime(int hours, int minutes, int seconds) {
    _duration = (hours * 3600) + (minutes * 60) + seconds;
    if (_duration < 0) {
      _duration = 0;
    }
    _saveTimerDuration();
    notifyListeners();
  }
  
  /// Sets the timer duration directly in seconds.
  void setDuration(int seconds) {
    _duration = seconds < 0 ? 0 : seconds;
    _saveTimerDuration();
    notifyListeners();
  }
  
  /// Resets the timer to zero and stops it.
  void reset() {
    stop();
    _duration = 0;
    _saveTimerDuration();
    notifyListeners();
  }
  
  /// Formats the current duration as HH:MM:SS.
  String formatDuration() {
    final h = hours.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
  
  /// Formats a given duration in seconds as HH:MM:SS.
  static String formatSeconds(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
  
  /// Timer tick callback - decrements duration by 1 second.
  void _onTick(Timer timer) {
    if (_duration > 0) {
      _duration--;
      _saveTimerDuration();
      notifyListeners();
    } else {
      // Timer reached zero
      stop();
    }
  }
  
  /// Saves the current timer duration to persistent storage.
  Future<void> _saveTimerDuration() async {
    try {
      await _storageService.saveTimerDuration(_duration);
    } catch (e) {
      LogManager.error('Ошибка сохранения таймера: $e');
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
