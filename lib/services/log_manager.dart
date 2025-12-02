import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Уровни логирования
enum LogLevel {
  info('INFO'),
  warning('WARNING'),
  error('ERROR');

  final String name;
  const LogLevel(this.name);
}

/// Менеджер логирования для записи логов в файл
/// 
/// Поддерживает три уровня логирования:
/// - INFO - информационные сообщения
/// - WARNING - предупреждения
/// - ERROR - ошибки
class LogManager {
  static IOSink? _logFile;
  static String? _logFilePath;
  static bool _isInitialized = false;
  static bool _enabled = true;
  
  /// Включено ли логирование
  static bool get enabled => _enabled;
  
  /// Включить/выключить логирование
  static set enabled(bool value) {
    _enabled = value;
  }

  /// Инициализация логирования
  /// 
  /// Создаёт файл логов в директории приложения
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      final String appDir = await _getAppDirectory();
      final separator = Platform.pathSeparator;
      _logFilePath = '$appDir${separator}logs.txt';

      // Создаём или очищаем файл логов
      final logFile = File(_logFilePath!);
      if (!await logFile.exists()) {
        await logFile.create(recursive: true);
      }
      
      // Открываем файл для записи (append mode)
      _logFile = logFile.openWrite(mode: FileMode.append);
      _isInitialized = true;

      log(LogLevel.info, 'Логирование инициализировано. Путь: $_logFilePath');
    } catch (e) {
      // Если не удалось инициализировать, выводим в консоль
      debugPrint('Ошибка инициализации логирования: $e');
    }
  }


  /// Получение директории приложения
  static Future<String> _getAppDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Get directory of the executable
      final execPath = Platform.resolvedExecutable;
      final lastSeparator = execPath.lastIndexOf(Platform.pathSeparator);
      return lastSeparator > 0 ? execPath.substring(0, lastSeparator) : execPath;
    } else {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    }
  }

  /// Запись лога
  /// 
  /// [level] - уровень логирования (INFO, WARNING, ERROR)
  /// [message] - сообщение для записи
  static void log(LogLevel level, String message) {
    if (!_enabled) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '$timestamp: ${level.name}: $message';

    // Выводим в консоль
    debugPrint(logMessage);

    // Записываем в файл если инициализирован
    if (_isInitialized && _logFile != null) {
      _logFile!.writeln(logMessage);
    }
  }

  /// Логирование информационного сообщения
  static void info(String message) {
    log(LogLevel.info, message);
  }

  /// Логирование предупреждения
  static void warning(String message) {
    log(LogLevel.warning, message);
  }

  /// Логирование ошибки
  static void error(String message) {
    log(LogLevel.error, message);
  }

  /// Завершение логирования
  /// 
  /// Сбрасывает буфер и закрывает файл
  static Future<void> dispose() async {
    if (_isInitialized && _logFile != null) {
      log(LogLevel.info, 'Логирование завершено');
      await _logFile!.flush();
      await _logFile!.close();
      _logFile = null;
      _isInitialized = false;
    }
  }

  /// Получение содержимого файла логов
  static Future<String> getLogContent() async {
    if (_logFilePath != null) {
      try {
        final file = File(_logFilePath!);
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (e) {
        return 'Ошибка чтения логов: $e';
      }
    }
    return 'Логи не найдены';
  }

  /// Очистка файла логов
  static Future<void> clearLogs() async {
    if (_logFilePath != null) {
      try {
        final file = File(_logFilePath!);
        if (await file.exists()) {
          await file.writeAsString('');
          log(LogLevel.info, 'Логи очищены');
        }
      } catch (e) {
        debugPrint('Ошибка очистки логов: $e');
      }
    }
  }

  /// Получение пути к файлу логов
  static String? get logFilePath => _logFilePath;

  /// Проверка инициализации
  static bool get isInitialized => _isInitialized;
}
