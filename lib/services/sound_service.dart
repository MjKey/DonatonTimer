import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'log_manager.dart';

/// Service for managing sound notifications on donations.
/// 
class SoundService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  
  /// List of available sound files.
  List<File> _soundFiles = [];
  
  /// Current sound file to play (when not in random mode).
  File? _currentSoundFile;
  
  /// Directory containing sound files.
  Directory? _soundDirectory;
  
  /// Whether sound notifications are enabled.
  bool _soundEnabled = true;
  
  /// Whether random sound mode is enabled.
  bool _randomSoundEnabled = false;
  
  /// Whether the service is initialized.
  bool _isInitialized = false;
  
  /// Gets the list of available sound files.
  List<File> get soundFiles => List.unmodifiable(_soundFiles);
  
  /// Gets the current sound file.
  File? get currentSoundFile => _currentSoundFile;
  
  /// Gets the sound directory path.
  String? get soundDirectoryPath => _soundDirectory?.path;
  
  /// Gets whether sound is enabled.
  bool get soundEnabled => _soundEnabled;
  
  /// Gets whether random sound mode is enabled.
  bool get randomSoundEnabled => _randomSoundEnabled;
  
  /// Gets whether the service is initialized.
  bool get isInitialized => _isInitialized;
  
  /// Gets the number of available sound files.
  int get soundCount => _soundFiles.length;
  
  /// Sets whether sound is enabled.
  set soundEnabled(bool value) {
    _soundEnabled = value;
    notifyListeners();
  }
  
  /// Sets whether random sound mode is enabled.
  set randomSoundEnabled(bool value) {
    _randomSoundEnabled = value;
    notifyListeners();
  }
  
  /// Initializes the sound service.
  /// Creates the sound folder if it doesn't exist and loads available sounds.
  /// 
  Future<void> init() async {
    try {
      // Get the application directory
      final appDir = await _getAppDirectory();
      _soundDirectory = Directory('$appDir${Platform.pathSeparator}sound');
      
      // Create the sound folder if it doesn't exist
      if (!await _soundDirectory!.exists()) {
        await _soundDirectory!.create(recursive: true);
        LogManager.info('Папка sound создана: ${_soundDirectory!.path}');
      } else {
        LogManager.info('Папка sound найдена: ${_soundDirectory!.path}');
      }
      
      // Load sound files
      await _loadSoundFiles();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SoundService: $e');
      _isInitialized = false;
    }
  }
  
  /// Gets the application directory path.
  Future<String> _getAppDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop, use the directory where the executable is located
      return Directory.current.path;
    } else {
      // For mobile, use the application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    }
  }
  
  /// Loads sound files from the sound directory.
  /// 
  Future<void> _loadSoundFiles() async {
    if (_soundDirectory == null || !await _soundDirectory!.exists()) {
      _soundFiles = [];
      _currentSoundFile = null;
      return;
    }
    
    try {
      final entities = await _soundDirectory!.list().toList();
      _soundFiles = entities
          .whereType<File>()
          .where((file) => _isSupportedAudioFile(file.path))
          .toList();
      
      // Sort files by name for consistent ordering
      _soundFiles.sort((a, b) => a.path.compareTo(b.path));
      
      // Set current sound file
      if (_soundFiles.isNotEmpty) {
        _currentSoundFile = _soundFiles.first;
        debugPrint('Loaded ${_soundFiles.length} sound files');
        debugPrint('Current sound file: ${_currentSoundFile?.path}');
      } else {
        _currentSoundFile = null;
        debugPrint('No sound files found in ${_soundDirectory!.path}');
      }
    } catch (e) {
      debugPrint('Error loading sound files: $e');
      _soundFiles = [];
      _currentSoundFile = null;
    }
  }
  
  /// Checks if a file is a supported audio format.
  bool _isSupportedAudioFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp3') ||
           lowerPath.endsWith('.wav') ||
           lowerPath.endsWith('.ogg') ||
           lowerPath.endsWith('.m4a') ||
           lowerPath.endsWith('.aac');
  }
  
  /// Refreshes the list of available sound files.
  /// 
  Future<void> refreshSounds() async {
    await _loadSoundFiles();
    notifyListeners();
  }

  
  /// Plays a notification sound.
  /// 
  Future<void> playSound() async {
    if (!_soundEnabled) {
      debugPrint('Sound notifications disabled');
      return;
    }
    
    if (_soundFiles.isEmpty) {
      debugPrint('No sound files available');
      return;
    }
    
    File? soundToPlay;
    
    if (_randomSoundEnabled) {
      // Requirement 8.2: Random sound mode
      final randomIndex = _random.nextInt(_soundFiles.length);
      soundToPlay = _soundFiles[randomIndex];
      debugPrint('Random sound selected: ${soundToPlay.path}');
    } else {
      soundToPlay = _currentSoundFile;
    }
    
    if (soundToPlay == null || !await soundToPlay.exists()) {
      debugPrint('Sound file not found or null');
      return;
    }
    
    try {
      LogManager.info('Воспроизведение звука: ${soundToPlay.path}');
      await _audioPlayer.play(DeviceFileSource(soundToPlay.path));
      LogManager.info('Звук успешно воспроизведён');
    } catch (e) {
      LogManager.error('Ошибка воспроизведения звука: $e');
    }
  }
  
  /// Stops any currently playing sound.
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping sound: $e');
    }
  }
  
  /// Sets the current sound file by index.
  void setCurrentSoundByIndex(int index) {
    if (index >= 0 && index < _soundFiles.length) {
      _currentSoundFile = _soundFiles[index];
      notifyListeners();
    }
  }
  
  /// Sets the current sound file by file name.
  void setCurrentSoundByName(String fileName) {
    try {
      _currentSoundFile = _soundFiles.firstWhere(
        (file) => file.path.endsWith(fileName),
      );
      notifyListeners();
    } catch (_) {
      debugPrint('Sound file not found: $fileName');
    }
  }
  
  /// Gets the file name from a file path.
  String getFileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }
  
  /// Gets the list of sound file names.
  List<String> get soundFileNames {
    return _soundFiles.map((file) => getFileName(file)).toList();
  }
  
  /// Opens the sound folder in the system file explorer.
  Future<void> openSoundFolder() async {
    if (_soundDirectory == null) return;
    
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [_soundDirectory!.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [_soundDirectory!.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [_soundDirectory!.path]);
      }
    } catch (e) {
      debugPrint('Error opening sound folder: $e');
    }
  }
  
  /// Disposes of the audio player resources.
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
