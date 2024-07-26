// ignore_for_file: depend_on_referenced_packages, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io'; 
import 'dart:async';
import 'dart:convert';
import 'socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class LocalizationProvider with ChangeNotifier {
  Map<String, String> _localizedStrings = {};
  String _currentLanguage = 'ru';

  String get currentLanguage => _currentLanguage;

  LocalizationProvider() {
    _loadLanguage();
  }

  Future<void> loadLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    String jsonString = await rootBundle.loadString('lang/$languageCode.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    await _saveLanguage(languageCode);
    notifyListeners();
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  void _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String langCode = prefs.getString('language') ?? 'ru';
    await loadLanguage(langCode);
  }

  Future<void> _saveLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  void _saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }
}

class LogManager {
  static final Logger _logger = Logger('DonatTimerApp');
  static IOSink? _logFile;
  static String? _logFilePath;

  static Future<void> init() async {
    final String appDir = await _getAppDirectory();
    _logFilePath = path.join(appDir, 'logs.txt');


    await File(_logFilePath!).writeAsString('');

    _logFile = File(_logFilePath!).openWrite(mode: FileMode.append);

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      final message = '${record.time}: ${record.level.name}: ${record.message}'; 
      _logFile?.writeln(message);
    });

    log(Level.INFO, 'Логирование инициализировано. Путь к файлу логов: $_logFilePath');
  }

  static Future<String> _getAppDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return path.dirname(Platform.resolvedExecutable);
    } else {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      return appDocDir.path;
    }
  }

  static void log(Level level, String message) {
    _logger.log(level, message);
  }

  static Future<void> dispose() async {
    await _logFile?.flush();
    await _logFile?.close();
    log(Level.INFO, 'Логирование завершено');
  }

  static Future<String> getLogContent() async {
    if (_logFilePath != null) {
      return await File(_logFilePath!).readAsString();
    }
    return 'Логи не найдены';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LogManager.init();
  LogManager.log(Level.INFO, 'Запуск..');
  await windowManager.ensureInitialized();
  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(700, 600));
    WindowManager.instance.setMaximumSize(const Size(700, 1080));
    LogManager.log(Level.INFO, 'Размеры окна заданы');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
      ],
      child: const DonatTimerApp(),
    ),
  );
}

class DonatTimerApp extends StatelessWidget {
  const DonatTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocalizationProvider>(
      builder: (context, themeProvider, localizationProvider, child) {
        return MaterialApp(
          title: context.read<LocalizationProvider>().translate('app_title'),
          theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
          home: const MainScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', ''),
            Locale('en', ''),
          ],
          locale: Locale(localizationProvider.currentLanguage, ''),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _timerDuration = 0;
  double _minutesPer100Rubles = 10.0;
  Timer? _timer;
  bool _isRunning = false;
  final TextEditingController _minutesController = TextEditingController();
  List<DonationRecord> _recentDonations = [];
  Map<String, int> _topDonators = {};
  late HttpServer _server;
  late HttpServer _webSocketServer;
  String _tokenPreview = '';
  final List<WebSocketChannel> _webSocketClients = [];
  String _socketUrl = 'https://socket5.donationalerts.ru';
  SocketService? _socketService;
  String _localIpAddress = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _httpPort = 8080;
  int _wsPort = 4040;
  

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStatistics(); 
    _initSocketService();
    _startWebServer();
    _startWebSocketServer();
    _getLocalIpAddress();
  }

  void _incrementCounter() {
    setState(() {
      _audioPlayer.play(AssetSource('pepe.mp3'));
      _showAuthorInfo();
    });
  }

  Future<void> _getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      final ipAddress = await info.getWifiIP();
      setState(() {
        _localIpAddress = ipAddress ?? '';
      });
    } catch (e) {
      setState(() {
        _localIpAddress = '';
      });
    }
  }

  void _showQRCodeDialog() {
  if (_localIpAddress.isEmpty) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.read<LocalizationProvider>().translate('remote')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
              width: 200.0, 
              height: 200.0, 
              child: QrImageView(
                data: 'http://$_localIpAddress:$_httpPort/dashboard',
                version: QrVersions.auto,
                size: 200.0, 
              ),
            ),
              const SizedBox(height: 20),
              Text(context.read<LocalizationProvider>().translate('wifi')),
            ],
          ),
          actions: [
            TextButton(
              child: Text(context.read<LocalizationProvider>().translate('close')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  });
}

  void _showAuthorInfo() {
  LogManager.log(Level.INFO, 'Отображение информации об авторе');
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title:  Column(
          children: <Widget>[Text('★ ${context.read<LocalizationProvider>().translate('info')} ★')],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            RichText(
              text: TextSpan(
                text: '${context.read<LocalizationProvider>().translate('author')}: ',
                style: theme.textTheme.bodyLarge,
                children: <TextSpan>[
                  TextSpan(
                    text: 'MjKey',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 33, 219, 243),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri url = Uri.parse('https://mjkey.ru/'); 
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          throw 'Не удалось открыть $url';
                        }
                      },
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                text: '${context.read<LocalizationProvider>().translate('version')}: ',
                style: theme.textTheme.bodyLarge,
                children: <TextSpan>[
                  TextSpan(
                    text: '2.0.0',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 243, 33, 226),
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri url = Uri.parse('https://github.com/MjKey/DonatonTimer/releases'); 
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          throw 'Не удалось открыть $url';
                        }
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                context.read<LocalizationProvider>().translate('chengelog'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('• Исправление багов'),
                Text('• Оптимизация кода'),
                Text('• Поддержка языков'),
                Text('• Выбор темы'),
                Text('• Управление с телефона'),
                Text('• Релиз на GitHub'),
              ],
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                text: '${context.read<LocalizationProvider>().translate('ps')} ',
                style: theme.textTheme.bodySmall,
                children: <TextSpan>[
                  TextSpan(
                    text: 'AbadonBlack\'а',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri url = Uri.parse('https://www.twitch.tv/abadonblack');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          throw 'Не удалось открыть $url';
                        }
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton(
                child: Text(context.read<LocalizationProvider>().translate('okpon')),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 10), 
              TextButton(
                child: Text(context.read<LocalizationProvider>().translate('support')),
                onPressed: () async {
                  final Uri url = Uri.parse('https://mjkey.ru/#donate');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    throw 'Не удалось открыть $url';
                  }
                },
              ),
            ],
            ),
        ],
      );
    },
  );
}

  void _saveTimerDuration() async {
    LogManager.log(Level.INFO, 'Сохранение длительности таймера: $_timerDuration');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timer_duration', _timerDuration);
  }

  void _loadSettings() async {
    LogManager.log(Level.INFO, 'Загрузка настроек');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _httpPort = prefs.getInt('httpPort') ?? 8080;
      _wsPort = prefs.getInt('wsPort') ?? 4040;
      _timerDuration = prefs.getInt('timer_duration') ?? 0;
      _minutesPer100Rubles = prefs.getDouble('minutes_per_100_rubles') ?? 10.0;
      String? token = prefs.getString('donation_alerts_token');
      _tokenPreview = token != null ? '${token.substring(0, 3)}...${token.substring(token.length - 3)}' : '';
    });
    if (_timerDuration == 0) {
      _showSetInitialTimeDialog();
    }
    LogManager.log(Level.INFO, 'Настройки загружены: таймер = $_timerDuration, минут за 100 рублей = $_minutesPer100Rubles');
  }

  Future<void> _initSocketService() async {
    LogManager.log(Level.INFO, 'Инициализация SocketService');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('donation_alerts_token');
    String socketUrl = prefs.getString('socket_url') ?? _socketUrl;
    if (token != null) {
      _tokenPreview = '${token.substring(0, 3)}...${token.substring(token.length - 3)}';
      _socketService = SocketService(token, socketUrl);
      _socketService!.socket.on('donation', (data) {
        LogManager.log(Level.INFO, 'SocketService Data | $data');
        _handleDonation(data);
      });
      await _socketService!.connect();  
      LogManager.log(Level.INFO, 'SocketService инициализирован');
    } else {
      LogManager.log(Level.WARNING, 'Токен не найден');
    }
  }

  void _updatePorts(int httpPort, int wsPort) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('httpPort', httpPort);
    await prefs.setInt('wsPort', wsPort);

    setState(() {
      _httpPort = httpPort;
      _wsPort = wsPort;
    });

    _restartServers();
  }

  void _restartServers() {
    _webSocketServer.close();
    _server.close();
    _startWebSocketServer();
    _startWebServer();
  }

  void _showPortSettingsDialog() {
    TextEditingController httpPortController = TextEditingController(text: _httpPort.toString());
    TextEditingController wsPortController = TextEditingController(text: _wsPort.toString());
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(context.read<LocalizationProvider>().translate('port_settings')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: httpPortController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'HTTP ${context.read<LocalizationProvider>().translate('port')}',
                      errorText: errorMessage,
                    ),
                  ),
                  TextField(
                    controller: wsPortController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'WebSocket ${context.read<LocalizationProvider>().translate('port')}',
                      errorText: errorMessage,
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(context.read<LocalizationProvider>().translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    int? httpPort = int.tryParse(httpPortController.text);
                    int? wsPort = int.tryParse(wsPortController.text);
                    if (httpPort != null && wsPort != null && httpPort > 0 && wsPort > 0) {
                      _updatePorts(httpPort, wsPort);
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        errorMessage = context.read<LocalizationProvider>().translate('err_port');
                      });
                    }
                  },
                  child: Text(context.read<LocalizationProvider>().translate('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleDonation(dynamic data) {
    LogManager.log(Level.INFO, 'Получено пожертвование: $data');
    var donationData = json.decode(data);
    var curr = donationData['currency'] ?? 'NOT DATA';
    var show = donationData['is_shown'] ?? 'NOT DATA';
    var bsys = donationData['billing_system'] ?? 'NOT DATA';
    var bsyt = donationData['billing_system_type'] ?? 'NOT DATA';
    if (donationData['currency'] == 'RUB' || 
        donationData['is_shown'] == 0 || 
        donationData['billing_system'] != 'TWITCH' || 
        donationData['billing_system_type'] != 'REWARDS') {
      double amountMain = donationData['amount_main'].toDouble();
      String username = donationData['username'] ?? context.read<LocalizationProvider>().translate('Anon');
      int minutesAdded = ((amountMain * _minutesPer100Rubles) / 100).round();
      LogManager.log(Level.INFO, 'Добавляется: $minutesAdded минут');

      setState(() {
        _timerDuration += minutesAdded * 60;
        _recentDonations.insert(0, DonationRecord(username, minutesAdded));
        if (_recentDonations.length > 10) _recentDonations.removeLast();

        _topDonators.update(username, (value) => value + minutesAdded, ifAbsent: () => minutesAdded);
        _topDonators = Map.fromEntries(_topDonators.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value)));
      });

      _broadcastWebSocketMessage(json.encode({'action': 'update_timer', 'duration': _timerDuration}));
      _saveStatistics();
      _broadcastWebSocketMessage(json.encode({
      'action': 'update_donations',
      'recentDonations': _recentDonations.map((d) => {'username': d.username, 'minutesAdded': d.minutesAdded}).toList(),
      'topDonators': _topDonators
    }));
    LogManager.log(Level.INFO, 'Обработан донат: $username добавил $minutesAdded минут');
  } else {
    LogManager.log(Level.INFO, 'Это был не донат. Критерии: currency = $curr (RUB) | is_shown = $show (0) | billing_system = $bsys (!TWITCH) | billing_system_type = $bsyt (!REWARDS)');
    return;
  }
  }

  void _saveSettings() async {
    LogManager.log(Level.INFO, 'Сохранение настроек');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timer_duration', _timerDuration);
    await prefs.setDouble('minutes_per_100_rubles', _minutesPer100Rubles);
  }

  void _showSetInitialTimeDialog() {
    LogManager.log(Level.INFO, 'Установка начального времени');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          String hours = '', minutes = '', seconds = '';
          return AlertDialog(
            title: Text(context.read<LocalizationProvider>().translate('start_time')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: context.read<LocalizationProvider>().translate('hours')),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => hours = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: context.read<LocalizationProvider>().translate('minuts')),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => minutes = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: context.read<LocalizationProvider>().translate('seconds')),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => seconds = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(context.read<LocalizationProvider>().translate('setup')),
                onPressed: () {
                  int h = int.tryParse(hours) ?? 0;
                  int m = int.tryParse(minutes) ?? 0;
                  int s = int.tryParse(seconds) ?? 0;
                  setState(() {
                    _timerDuration = h * 3600 + m * 60 + s;
                  });
                  _saveSettings();
                  LogManager.log(Level.INFO, 'Установлено начальное время: $_timerDuration');
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  void _startTimer() {
    LogManager.log(Level.INFO, 'Запуск таймера');
    if (_timerDuration == 0) {
      _showSetInitialTimeDialog();
      return;
    }
    if (!_isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_timerDuration > 0) {
            _timerDuration--;
          } else {
            _stopTimer();
          }
        });
        _broadcastWebSocketMessage(json.encode({'action': 'update_timer', 'duration': _timerDuration}));
      });
      setState(() {
        _isRunning = true;
      });
    }
    _saveTimerDuration();
    _broadcastWebSocketMessage(json.encode({'action': 'update_timer', 'duration': _timerDuration}));
  }

  void _stopTimer() {
    LogManager.log(Level.INFO, 'Остановка таймера');
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    }
    _saveTimerDuration();
    _broadcastWebSocketMessage(json.encode({'action': 'update_timer', 'duration': _timerDuration}));
  }

  void _changeTimer(int seconds) {
    LogManager.log(Level.INFO, 'Изменение таймера на $seconds');
    setState(() {
      _timerDuration += seconds;
      if (_timerDuration < 0) _timerDuration = 0;
    });
    _saveSettings();
    _saveTimerDuration();
    _broadcastWebSocketMessage(json.encode({'action': 'update_timer', 'duration': _timerDuration}));
  }

  String _formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<String?> _extractSocketUrl(String widgetUrl) async {
    try {
      final response = await http.get(Uri.parse(widgetUrl));
      if (response.statusCode == 200) {
        final body = response.body;
        final match = RegExp(r"wss?:\/\/socket\d+\.donationalerts\.ru:\d+").firstMatch(body);
        if (match != null) {
          String wsUrl = match.group(0)!;
          return 'https://${wsUrl.split('://')[1].split(':')[0]}';
        }
      }
    } catch (e) {
      LogManager.log(Level.INFO, 'Error extracting socket URL: $e');
    }
    return null;
  }

  void _showSettingsDialog() {
  LogManager.log(Level.INFO, 'Диалог настроек');
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String newWidgetUrl = '';
      return AlertDialog(
        title: Text(context.read<LocalizationProvider>().translate('settings')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tokenPreview.isNotEmpty
                ? '${context.read<LocalizationProvider>().translate('token')}: $_tokenPreview'
                : context.read<LocalizationProvider>().translate('not_token'),
              style: TextStyle(
                color: _tokenPreview.isNotEmpty ? Colors.green : Colors.red,
              ),
            ),
            TextField(
              decoration: InputDecoration(labelText: context.read<LocalizationProvider>().translate('min100')),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _minutesPer100Rubles = double.tryParse(value) ?? _minutesPer100Rubles;
              },
              controller: TextEditingController(text: _minutesPer100Rubles.toString()),
            ),
            TextField(
              decoration: InputDecoration(labelText: context.read<LocalizationProvider>().translate('linkDA')),
              onChanged: (value) {
                newWidgetUrl = value;
              },
              obscureText: true, 
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(context.read<LocalizationProvider>().translate('cancel')),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(context.read<LocalizationProvider>().translate('save')),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('minutes_per_100_rubles', _minutesPer100Rubles);
              if (newWidgetUrl.isNotEmpty) {
                Uri uri = Uri.parse(newWidgetUrl);
                String? token = uri.queryParameters['token'];
                if (token != null) {
                  await prefs.setString('donation_alerts_token', token);
                  String? socketUrl = await _extractSocketUrl(newWidgetUrl);
                  if (socketUrl != null) {
                    _socketUrl = socketUrl;
                    await prefs.setString('socket_url', socketUrl);
                  }
                  await _reinitSocketService();
                }
              }
              _saveSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> _reinitSocketService() async {
    LogManager.log(Level.INFO, 'Переинициализация SocketService');

    await _socketService?.dispose();

    await _initSocketService();
  }

void _saveStatistics() async {
  LogManager.log(Level.INFO, 'Сохранение статистик');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> recentDonationsJson = _recentDonations.map((record) => json.encode({'username': record.username, 'minutesAdded': record.minutesAdded})).toList();
  await prefs.setStringList('recent_donations', recentDonationsJson);
  
  List<String> topDonatorsJson = _topDonators.entries.map((e) => json.encode({'username': e.key, 'minutesAdded': e.value})).toList();
  await prefs.setStringList('top_donators', topDonatorsJson);
}

void _loadStatistics() async {
  LogManager.log(Level.INFO, 'Загрузка статистик');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? recentDonationsJson = prefs.getStringList('recent_donations');
  if (recentDonationsJson != null) {
    setState(() {
      _recentDonations = recentDonationsJson.map((jsonString) {
        final jsonMap = json.decode(jsonString);
        return DonationRecord(jsonMap['username'], jsonMap['minutesAdded']);
      }).toList();
    });
  }

  List<String>? topDonatorsJson = prefs.getStringList('top_donators');
  if (topDonatorsJson != null) {
    setState(() {
      _topDonators = Map.fromEntries(topDonatorsJson.map((jsonString) {
        final jsonMap = json.decode(jsonString);
        return MapEntry(jsonMap['username'], jsonMap['minutesAdded']);
      }));
      _topDonators = Map.fromEntries(_topDonators.entries.toList()
        ..sort((e1, e2) => e2.value.compareTo(e1.value)));
    });
  }
}


  void _resetSettings() async {
  LogManager.log(Level.INFO, 'Ресет настроек');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  setState(() {
    _timerDuration = 0;
    _minutesPer100Rubles = 10.0;
    _tokenPreview = '';
  });
  _initSocketService();  
  _startWebServer();  
  

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.read<LocalizationProvider>().translate('settings_clear')))
  );
}


  void _startWebServer() async {
    LogManager.log(Level.INFO, 'Запуск страницы для OBS');
    var handler = const Pipeline().addHandler(_webHandler);
    _server = await io.serve(handler, '0.0.0.0', _httpPort);
  }

  Future<Response> _webHandler(Request request) async {
    if (request.requestedUri.path == '/timer') {
      String htmlContent = '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Донатон Таймер</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Kode+Mono:wght@400..700&display=swap" rel="stylesheet">
    <style id="dynamic-css">
      body {
        font-family: "Kode Mono", monospace;
        font-optical-sizing: auto;
        font-style: normal;
        text-align: center;
        background-color: #f0f0f0;
        color: #fff;
      }
      #timer {
        font-size: 48px;
        margin-top: 50px;
      }
    </style>
</head>
<body>
    <div id="timer">00:00:00</div>
    <script>
      const socket = new WebSocket('ws://$_localIpAddress:$_wsPort'); 
      socket.onmessage = function(event) {
        const data = JSON.parse(event.data);
        if (data.action === 'update_timer') {
          const duration = data.duration;
          let hours = Math.floor(duration / 3600);
          let minutes = Math.floor((duration % 3600) / 60);
          let seconds = duration % 60;
          document.getElementById('timer').innerText = [hours, minutes, seconds].map(num => num.toString().padStart(2, '0')).join(':');
        }
      };
    </script>
</body>
</html>
      ''';
      return Response.ok(htmlContent, headers: {'Content-Type': 'text/html'});
    } else if (request.requestedUri.path == '/dashboard') {
    String htmlContent = '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Донатон Таймер - Панель управления</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
    <style>
        .hero.is-fullheight {
            min-height: 100vh;
        }
        #timer {
            font-size: 4rem;
            font-weight: bold;
        }
        .donation-list {
            max-height: 300px;
            overflow-y: auto;
        }
    </style>
</head>
<body>
    <section class="hero is-fullheight is-light">
        <div class="hero-body">
            <div class="container">
                <h1 class="title has-text-centered is-size-2 mb-6">
                    Донатон Таймер
                </h1>
                <div class="columns is-centered">
                    <div class="column is-narrow">
                        <div class="box">
                            <div id="timer" class="has-text-centered mb-4">00:00:00</div>
                            <div class="buttons are-medium is-centered">
                                <button class="button is-primary" onclick="startStop()">
                                    <span class="icon">
                                        <i class="fa fa-play"></i>
                                    </span>
                                    <span>Старт/Стоп</span>
                                </button>
                            </div>
                            <div class="buttons are-medium is-centered">
                                <button class="button is-danger" onclick="changeTime(-60)">
                                    <span class="icon">
                                        <i class="fa fa-minus"></i>
                                    </span>
                                    <span>1 мин</span>
                                </button>
                                <button class="button is-success" onclick="changeTime(60)">
                                    <span class="icon">
                                        <i class="fa fa-plus"></i>
                                    </span>
                                    <span>1 мин</span>
                                </button>
                            </div>
                            <div class="field has-addons has-addons-centered mt-4">
                                <div class="control">
                                    <input class="input" type="number" id="minutesInput" placeholder="&#177;Минуты">
                                </div>
                                <div class="control">
                                    <button class="button is-info" onclick="addCustomTime()">
                                        Добавить/Отнять
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="columns mt-6">
                    <div class="column">
                        <div class="box">
                            <h2 class="title is-4 has-text-centered">Последние донаты</h2>
                            <div class="donation-list">
                                <ul id="recentDonationsList"></ul>
                            </div>
                        </div>
                    </div>
                    <div class="column">
                        <div class="box">
                            <h2 class="title is-4 has-text-centered">Топ донатеров</h2>
                            <div class="donation-list">
                                <ul id="topDonatorsList"></ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>
    <footer>
    <center><p>Dev. MjKey</p><a href="http://$_localIpAddress:$_httpPort/mini">Мини-версия</a></center>
    </footer>

    <script>
        const socket = new WebSocket('ws://$_localIpAddress:$_wsPort');
        let isRunning = false;

        socket.onmessage = function(event) {
            const data = JSON.parse(event.data);
            if (data.action === 'update_timer') {
                updateTimer(data.duration);
            } else if (data.action === 'update_donations') {
                updateDonations(data.recentDonations, data.topDonators);
            }
        };

        function updateTimer(duration) {
            let hours = Math.floor(duration / 3600);
            let minutes = Math.floor((duration % 3600) / 60);
            let seconds = duration % 60;
            document.getElementById('timer').innerText = [hours, minutes, seconds].map(num => num.toString().padLeft(2, '0')).join(':');
        }

        function startStop() {
            isRunning = !isRunning;
            socket.send(JSON.stringify({action: isRunning ? 'start' : 'stop'}));
        }

        function changeTime(seconds) {
            socket.send(JSON.stringify({action: 'change_time', seconds: seconds}));
        }

        function addCustomTime() {
            const minutes = document.getElementById('minutesInput').value;
            if (minutes) {
                changeTime(parseInt(minutes) * 60);
            }
        }

        function updateDonations(recentDonations, topDonators) {
            const recentList = document.getElementById('recentDonationsList');
            const topList = document.getElementById('topDonatorsList');
            
            recentList.innerHTML = recentDonations.map(d => `<li class="mb-2">\${d.username}: \${d.minutesAdded} мин</li>`).join('');
            topList.innerHTML = Object.entries(topDonators)
                .map(([name, minutes]) => `<li class="mb-2">\${name}: \${minutes} мин</li>`)
                .join('');
        }


        if (!String.prototype.padLeft) {
            String.prototype.padLeft = function padLeft(length, char) {
                char = char || '0';
                return char.repeat(Math.max(0, length - this.length)) + this;
            };
        }
    </script>
</body>
</html>
    ''';
    return Response.ok(htmlContent, headers: {'Content-Type': 'text/html'});
  }else if (request.requestedUri.path == '/mini') {
    String htmlContent = '''
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Донатон Таймер - Панель управления</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
    <style>
        .hero.is-fullheight {
            min-height: 100vh;
        }
        .hero-body{
            padding: 0px;
            flex-grow: 0;
        }
        #timer {
            font-size: 4rem;
            font-weight: bold;
        }
        .box{
            padding-top: 0px;
        }
        .buttons:not(:last-child) {
            margin-bottom: 0px;
        }
    </style>
</head>
<body>
    <section class="hero is-fullheight is-light">
        <div class="hero-body">
            <div class="container">
                <div class="columns is-centered">
                    <div class="column is-narrow">
                        <div class="box">
                            <div id="timer" class="has-text-centered mb-4">00:00:00</div>
                            <div class="buttons are-medium is-centered">
                                <button class="button is-primary" onclick="startStop()">
                                    <span class="icon">
                                        <i class="fa fa-play"></i>
                                    </span>
                                    <span>Старт/Стоп</span>
                                </button>
                            </div>
                            <div class="buttons are-medium is-centered">
                                <button class="button is-danger" onclick="changeTime(-60)">
                                    <span class="icon">
                                        <i class="fa fa-minus"></i>
                                    </span>
                                    <span>1 мин</span>
                                </button>
                                <button class="button is-success" onclick="changeTime(60)">
                                    <span class="icon">
                                        <i class="fa fa-plus"></i>
                                    </span>
                                    <span>1 мин</span>
                                </button>
                            </div>
                            <div class="field has-addons has-addons-centered mt-4">
                                <div class="control">
                                    <input class="input" type="number" id="minutesInput" placeholder="&#177;Минуты">
                                </div>
                                <div class="control">
                                    <button class="button is-info" onclick="addCustomTime()">
                                        Добавить/Отнять
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <script>
        const socket = new WebSocket('ws://$_localIpAddress:$_wsPort');
        let isRunning = false;

        socket.onmessage = function(event) {
            const data = JSON.parse(event.data);
            if (data.action === 'update_timer') {
                updateTimer(data.duration);
            } else if (data.action === 'update_donations') {
                updateDonations(data.recentDonations, data.topDonators);
            }
        };

        function updateTimer(duration) {
            let hours = Math.floor(duration / 3600);
            let minutes = Math.floor((duration % 3600) / 60);
            let seconds = duration % 60;
            document.getElementById('timer').innerText = [hours, minutes, seconds].map(num => num.toString().padLeft(2, '0')).join(':');
        }

        function startStop() {
            isRunning = !isRunning;
            socket.send(JSON.stringify({action: isRunning ? 'start' : 'stop'}));
        }

        function changeTime(seconds) {
            socket.send(JSON.stringify({action: 'change_time', seconds: seconds}));
        }

        function addCustomTime() {
            const minutes = document.getElementById('minutesInput').value;
            if (minutes) {
                changeTime(parseInt(minutes) * 60);
            }
        }


        if (!String.prototype.padLeft) {
            String.prototype.padLeft = function padLeft(length, char) {
                char = char || '0';
                return char.repeat(Math.max(0, length - this.length)) + this;
            };
        }
    </script>
</body>
</html>
    ''';
    return Response.ok(htmlContent, headers: {'Content-Type': 'text/html'});
  }
    return Response.notFound('Not Found');
  }

  void _startWebSocketServer() async {
    _webSocketServer = await HttpServer.bind('0.0.0.0', _wsPort);
    _webSocketServer.listen((HttpRequest request) {
      if (request.uri.path == '/') {
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          WebSocketChannel channel = IOWebSocketChannel(socket);
          _webSocketClients.add(channel);
          channel.sink.add(json.encode({
            'action': 'update_timer',
            'duration': _timerDuration
          }));
          channel.sink.add(json.encode({
            'action': 'update_donations',
            'recentDonations': _recentDonations.map((d) => {'username': d.username, 'minutesAdded': d.minutesAdded}).toList(),
            'topDonators': _topDonators
          }));

          channel.stream.listen((message) {
            _handleWebSocketMessage(message);
          }, onDone: () {
            _webSocketClients.remove(channel);
          });
        });
      }
    });
  }

  void _handleWebSocketMessage(String message) {
    var data = json.decode(message);
    switch (data['action']) {
      case 'start':
        _startTimer();
        break;
      case 'stop':
        _stopTimer();
        break;
      case 'change_time':
        _changeTimer(data['seconds']);
        break;
    }
  }

  void _broadcastWebSocketMessage(String message) {
    for (var client in _webSocketClients) {
      client.sink.add(message);
    }
  }

  void _copyLinkToClipboard() {
    LogManager.log(Level.INFO, 'Скопирована ссылка');
    Clipboard.setData(ClipboardData(text: 'http://localhost:$_httpPort/timer'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<LocalizationProvider>().translate('OBScopy'))));
  }

  void _clearStatistics() async {
    LogManager.log(Level.INFO, 'Статистика очищена');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_donations');
    await prefs.remove('top_donators');
    setState(() {
      _recentDonations = [];
      _topDonators = {};
    });
    _broadcastWebSocketMessage(json.encode({'action': 'update_timer', 'duration': _timerDuration}));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<LocalizationProvider>().translate('stat_clear'))));
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
          ],
        ),

        flexibleSpace: Stack(
          children: [
            Align(
              alignment: Alignment.center, 
              child: MouseRegion(
                cursor: SystemMouseCursors.click, 
                child: GestureDetector(
                  onTap: _incrementCounter,
                  child: Image.asset(
                    'assets/pepe.gif',  
                    height: 50,  
                  ),
                ),
              ),
            ),
          ],
        ),
          
        
        // title: Center(
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       GestureDetector(
        //         onTap: _incrementCounter,
        //         child: Image.asset(
        //           'assets/pepe.gif',  // Укажи ссылку на свою гифку
        //           height: 50,  // Настроить размер
        //         ),),
        //       ],
        //   ),
        // ),
        actions: [
          PopupMenuButton<String>(
            tooltip: context.read<LocalizationProvider>().translate('m_lang'),
            icon: const Icon(Icons.language),
            onSelected: (String languageCode) {
              localizationProvider.loadLanguage(languageCode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'ru',
                child: Text('Русский'),
              ),
              const PopupMenuItem<String>(
                value: 'en',
                child: Text('English'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: context.read<LocalizationProvider>().translate('m_settings'),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _showSettingsDialog();
                  break;
                case 'reset':
                  _resetSettings();
                  break;
                case 'change_timer':
                  _showSetInitialTimeDialog();
                  break;
                case 'copy_link':
                  _copyLinkToClipboard();
                  break;
                case 'phone_control':
                  _showQRCodeDialog();
                  break;
                case 'clear_statistics':
                  _clearStatistics();
                  break;
                case 'port_settings':
                  _showPortSettingsDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'settings', child: Text(context.read<LocalizationProvider>().translate('settings'))),
                PopupMenuItem(value: 'port_settings', child: Text(context.read<LocalizationProvider>().translate('port_settings'))),
                PopupMenuItem(value: 'reset', child: Text(context.read<LocalizationProvider>().translate('clear_settings'))),
                PopupMenuItem(value: 'change_timer', child: Text(context.read<LocalizationProvider>().translate('edit'))),
                PopupMenuItem(value: 'copy_link', child: Text(context.read<LocalizationProvider>().translate('copyOBS'))),
                PopupMenuItem(value: 'phone_control', child: Text(context.read<LocalizationProvider>().translate('remote'))),
                PopupMenuItem(value: 'clear_statistics', child: Text(context.read<LocalizationProvider>().translate('clear_stat'))),
              ];
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDuration(_timerDuration),
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isRunning ? _stopTimer : _startTimer,
                      child: Text(_isRunning ? context.read<LocalizationProvider>().translate('pause') : context.read<LocalizationProvider>().translate('start')),
                    ),
                  ],
                ),
                SizedBox(
                      width: 165,
                      child: TextField(
                        textAlign: TextAlign.center,
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: context.read<LocalizationProvider>().translate('+-hint')),
                      ),
                    ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: () => _changeTimer(-60), child: Text(context.read<LocalizationProvider>().translate('-min'))),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () => _changeTimer(-600), child: Text(context.read<LocalizationProvider>().translate('-10min'))),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        onPressed: () {
                          int? minutes = int.tryParse(_minutesController.text);
                          if (minutes != null) _changeTimer(minutes * 60);
                        },
                        child: Text(context.read<LocalizationProvider>().translate('+-')),
                      ),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () => _changeTimer(600), child: Text(context.read<LocalizationProvider>().translate('+10min'))),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: () => _changeTimer(60), child: Text(context.read<LocalizationProvider>().translate('+min'))),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(context.read<LocalizationProvider>().translate('LDon'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _recentDonations.length,
                          itemBuilder: (context, index) {
                            var donation = _recentDonations[index];
                            double amount = (donation.minutesAdded * 100) / _minutesPer100Rubles;
                            return ListTile(
                              title: Text(donation.username),
                              trailing: Text('${amount.toStringAsFixed(2)}₽ / ${DonationRecord.formattedTime(context,donation.minutesAdded)}'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(
                  color: Colors.black,  
                  thickness: 1,  
                  width: 20,  
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(context.read<LocalizationProvider>().translate('TDon'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _topDonators.length,
                          itemBuilder: (context, index) {
                            String key = _topDonators.keys.elementAt(index);
                            int minutes = _topDonators[key]!;
                            // double amount = (minutes * 100) / _minutesPer100Rubles;
                            return ListTile(
                              title: Text(key),
                              trailing: Text('${((minutes * 100) / _minutesPer100Rubles).toStringAsFixed(2)}₽ / ${minutes ~/ 60}${context.read<LocalizationProvider>().translate('h')} ${(minutes % 60).toString().padLeft(1, '0')}${context.read<LocalizationProvider>().translate('m')}'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    LogManager.log(Level.INFO, 'Закрытие всего и вся');
    LogManager.dispose();
    _timer?.cancel();
    _socketService?.dispose();
    _server.close();
    _webSocketServer.close();
    _saveTimerDuration();
    super.dispose();
  }
  
}

class DonationRecord {
  final String username;
  final int minutesAdded;

  DonationRecord(this.username, this.minutesAdded);

  static String formattedTime(BuildContext context, int minutesAdded) {
    int hours = minutesAdded ~/ 60;
    int minutes = minutesAdded % 60;
    return '$hours${context.read<LocalizationProvider>().translate('h')} ${minutes.toString().padLeft(2, '0')}${context.read<LocalizationProvider>().translate('m')}';
  }
}
