import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';
import '../models/statistics.dart';

/// Сервис для хранения данных таймера, настроек и статистики.
/// Данные хранятся в %APPDATA%/MerryJoyKeyStudio/DonatonTimer
class StorageService {
  static const String _companyName = 'MerryJoyKeyStudio';
  static const String _appName = 'DonatonTimer';
  static const String _dataFileName = 'data.json';

  Directory? _appDataDir;
  Map<String, dynamic> _data = {};

  /// Получает путь к директории данных приложения.
  Future<Directory> _getAppDataDir() async {
    if (_appDataDir != null) return _appDataDir!;
    
    final appData = await getApplicationSupportDirectory();
    // Navigate to parent and create custom path: %APPDATA%/MerryJoyKeyStudio/DonatonTimer
    final roamingPath = appData.parent.parent.path; // Gets to %APPDATA%
    _appDataDir = Directory('$roamingPath/$_companyName/$_appName');
    
    if (!await _appDataDir!.exists()) {
      await _appDataDir!.create(recursive: true);
    }
    
    return _appDataDir!;
  }

  /// Получает файл данных.
  Future<File> _getDataFile() async {
    final dir = await _getAppDataDir();
    return File('${dir.path}/$_dataFileName');
  }

  /// Инициализирует сервис хранения.
  Future<void> init() async {
    try {
      final file = await _getDataFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        _data = jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      _data = {};
    }
  }

  /// Сохраняет все данные в файл.
  Future<void> _saveData() async {
    try {
      final file = await _getDataFile();
      await file.writeAsString(jsonEncode(_data));
    } catch (e) {
      // Ignore save errors
    }
  }

  void _ensureInitialized() {}

  /// Сохраняет текущую длительность таймера.
  Future<void> saveTimerDuration(int durationSeconds) async {
    _ensureInitialized();
    _data['timer_duration'] = durationSeconds;
    await _saveData();
  }

  /// Загружает длительность таймера.
  int? loadTimerDuration() {
    _ensureInitialized();
    return _data['timer_duration'] as int?;
  }

  /// Сохраняет состояние запуска таймера.
  Future<void> saveTimerRunning(bool isRunning) async {
    _ensureInitialized();
    _data['timer_running'] = isRunning;
    await _saveData();
  }

  /// Загружает состояние запуска таймера.
  bool loadTimerRunning() {
    _ensureInitialized();
    return _data['timer_running'] as bool? ?? false;
  }

  /// Сохраняет настройки приложения.
  Future<void> saveSettings(AppSettings settings) async {
    _ensureInitialized();
    _data['settings'] = settings.toJson();
    await _saveData();
  }

  /// Загружает настройки приложения.
  AppSettings? loadSettings() {
    _ensureInitialized();
    final settingsData = _data['settings'];
    if (settingsData == null) {
      return null;
    }
    try {
      return AppSettings.fromJson(settingsData as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Сохраняет статистику.
  Future<void> saveStatistics(Statistics statistics) async {
    _ensureInitialized();
    _data['statistics'] = statistics.toJson();
    await _saveData();
  }

  /// Загружает статистику.
  Statistics? loadStatistics() {
    _ensureInitialized();
    final statsData = _data['statistics'];
    if (statsData == null) {
      return null;
    }
    try {
      return Statistics.fromJson(statsData as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Очищает все данные.
  Future<void> clearAll() async {
    _ensureInitialized();
    _data.clear();
    await _saveData();
  }

  /// Очищает только длительность таймера.
  Future<void> clearTimerDuration() async {
    _ensureInitialized();
    _data.remove('timer_duration');
    await _saveData();
  }

  /// Очищает только статистику.
  Future<void> clearStatistics() async {
    _ensureInitialized();
    _data.remove('statistics');
    await _saveData();
  }

  /// Возвращает путь к директории хранения.
  Future<String> getStoragePath() async {
    final dir = await _getAppDataDir();
    return dir.path;
  }
}
