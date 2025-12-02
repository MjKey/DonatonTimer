import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nes_ui/nes_ui.dart';

import 'providers/localization_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'services/donation_service.dart';
import 'services/donation_alerts_adapter.dart';
import 'services/donate_pay_adapter.dart';
import 'services/donate_stream_adapter.dart';
import 'services/donatex_adapter.dart';
import 'services/web_server_service.dart';
import 'services/sound_service.dart';
import 'services/log_manager.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  await LogManager.init();
  LogManager.info('Запуск приложения DonatonTimer v3.0.1 by MjKey');

  // Initialize window manager for desktop
  await windowManager.ensureInitialized();
  LogManager.info('Window manager инициализирован');

  const WindowOptions windowOptions = WindowOptions(
    size: Size(900, 700),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'DonatonTimer v3.0.1 by MjKey',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize storage service
  final storageService = StorageService();
  await storageService.init();
  LogManager.info('Storage service инициализирован');

  // Initialize localization
  final localizationProvider = LocalizationProvider();
  await localizationProvider.init();
  LogManager.info('Локализация инициализирована');

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  LogManager.info('Theme provider инициализирован');

  // Initialize timer provider with storage service
  final timerProvider = TimerProvider(storageService);
  await timerProvider.init();
  LogManager.info('Timer provider инициализирован');

  // Initialize donation service
  final donationService = DonationService(storageService);
  await donationService.init();
  LogManager.info('Donation service инициализирован');
  
  // Register donation service adapters
  LogManager.info('Регистрация адаптеров донат-сервисов...');
  donationService.registerAdapter(DonationAlertsAdapter());
  LogManager.info('Адаптер DonationAlerts зарегистрирован');
  donationService.registerAdapter(DonatePayAdapter());
  LogManager.info('Адаптер DonatePay зарегистрирован');
  donationService.registerAdapter(DonateStreamAdapter());
  LogManager.info('Адаптер DonateStream зарегистрирован');
  donationService.registerAdapter(DonateXAdapter());
  LogManager.info('Адаптер DonateX зарегистрирован');
  
  // Auto-connect enabled services from saved settings
  final settings = donationService.settings;
  LogManager.info('Проверка сохранённых настроек сервисов...');
  for (final config in settings.serviceConfigs.values) {
    LogManager.info('Сервис ${config.serviceName}: enabled=${config.enabled}');
    if (config.enabled) {
      try {
        LogManager.info('Подключение к ${config.serviceName}...');
        await donationService.connectAdapter(config.serviceName, config.credentials);
        LogManager.info('${config.serviceName} успешно подключён');
      } catch (e) {
        LogManager.error('Не удалось подключиться к ${config.serviceName}: $e');
      }
    }
  }
  
  // Connect donation service to timer
  donationService.onTimeAdded = (seconds) {
    timerProvider.addTime(seconds);
  };

  // Initialize sound service for donation notifications
  final soundService = SoundService();
  await soundService.init();
  LogManager.info('Sound service инициализирован');
  
  // Load sound and logging settings from app settings
  final savedSettings = storageService.loadSettings();
  if (savedSettings != null) {
    soundService.soundEnabled = savedSettings.soundEnabled;
    soundService.randomSoundEnabled = savedSettings.randomSoundEnabled;
    LogManager.enabled = savedSettings.loggingEnabled;
    LogManager.info('Настройки звука и логирования загружены');
  }

  // Initialize web server service for OBS integration and mobile control
  final webServerService = WebServerService();
  await webServerService.init();
  LogManager.info('Web server service инициализирован');
  
  // Connect web server to timer provider
  webServerService.onStartTimer = () => timerProvider.start();
  webServerService.onStopTimer = () => timerProvider.stop();
  webServerService.onChangeTime = (seconds) => timerProvider.addTime(seconds);
  
  // Listen to timer changes and broadcast to web clients
  timerProvider.addListener(() {
    webServerService.updateTimerDuration(timerProvider.duration);
  });
  
  // Listen to donation changes and broadcast to web clients
  donationService.addListener(() {
    final stats = donationService.statistics;
    webServerService.updateDonations(
      recentDonations: stats.recentDonations.map((d) => {
        'username': d.username,
        'minutesAdded': d.minutesAdded,
      }).toList(),
      topDonators: stats.topDonators,
    );
  });
  
  // Play sound when donation is received
  donationService.donationStream.listen((_) {
    soundService.playSound();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localizationProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: timerProvider),
        ChangeNotifierProvider<DonationService>.value(value: donationService),
        ChangeNotifierProvider<WebServerService>.value(value: webServerService),
        ChangeNotifierProvider<SoundService>.value(value: soundService),
      ],
      child: const DonatonTimerApp(),
    ),
  );
}

class DonatonTimerApp extends StatelessWidget {
  const DonatonTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: localization.tr('app_title'),
      debugShowCheckedModeBanner: false,
      locale: localization.locale,
      supportedLocales: LocalizationProvider.supportedLanguages
          .map((code) => Locale(code))
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Use nes_ui theme for retro 8-bit style
      theme: flutterNesTheme(
        brightness: Brightness.light,
        nesTheme: const NesTheme(pixelSize: 4),
        primaryColor: const Color(0xffb4b6f6),
      ),
      darkTheme: flutterNesTheme(
        brightness: Brightness.dark,
        nesTheme: const NesTheme(pixelSize: 4),
        primaryColor: const Color(0xff8b8dca),
      ),
      themeMode: themeProvider.themeMode,
      home: const MainScreen(),
    );
  }
}
