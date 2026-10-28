@Tags(['widget'])
library;

import 'package:donaton_timer/main.dart';
import 'package:donaton_timer/models/app_ui_style.dart';
import 'package:donaton_timer/providers/localization_provider.dart';
import 'package:donaton_timer/providers/theme_provider.dart';
import 'package:donaton_timer/providers/timer_provider.dart';
import 'package:donaton_timer/screens/appearance_settings_tab.dart';
import 'package:donaton_timer/screens/settings_screen.dart';
import 'package:donaton_timer/services/donation_service.dart';
import 'package:donaton_timer/services/log_manager.dart';
import 'package:donaton_timer/services/storage_service.dart';
import 'package:donaton_timer/theme/app_theme.dart';
import 'package:donaton_timer/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryStorage extends StorageService {
  @override
  Future<void> saveTimerDuration(int durationSeconds) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeProvider theme;
  late LocalizationProvider localization;
  late TimerProvider timer;
  late DonationService donations;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    theme = ThemeProvider();
    await theme.init();
    localization = LocalizationProvider();
    await localization.init('en');
    final storage = _MemoryStorage();
    timer = TimerProvider(storage);
    donations = DonationService(storage);
    final loggingEnabled = LogManager.enabled;
    LogManager.enabled = false;
    addTearDown(() => LogManager.enabled = loggingEnabled);
    addTearDown(theme.dispose);
    addTearDown(localization.dispose);
    addTearDown(timer.dispose);
    addTearDown(donations.dispose);
  });

  Widget app() => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: theme),
      ChangeNotifierProvider.value(value: localization),
      ChangeNotifierProvider.value(value: timer),
      ChangeNotifierProvider.value(value: donations),
    ],
    child: const DonatonTimerApp(),
  );

  Future<void> openAppearance(WidgetTester tester) async {
    await tester.tap(find.byTooltip(localization.tr('tooltip_settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(localization.tr('appearance')));
    await tester.pumpAndSettle();
  }

  Future<void> selectStyle(WidgetTester tester, AppUiStyle style) async {
    await tester.tap(find.byKey(const ValueKey('app-ui-style')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(localization.tr('app_ui_style_${style.name}')).last,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('switches both ways in settings without restarting the timer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await theme.setThemeMode(ThemeMode.dark);
    timer.setTime(1, 2, 3);
    timer.start();
    final originalSettings = donations.settings;
    final originalStatistics = donations.statistics;

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(NesContainer), findsWidgets);

    await openAppearance(tester);
    await selectStyle(tester, AppUiStyle.classic);
    expect(theme.isClassic, isTrue);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(AppearanceSettingsTab), findsOneWidget);
    expect(find.byType(NesContainer), findsNothing);
    expect(find.byType(NesButton), findsNothing);
    expect(
      Theme.of(tester.element(find.byType(AppearanceSettingsTab))).brightness,
      Brightness.dark,
    );
    expect(timer.isRunning, isTrue);
    expect(timer.duration, inInclusiveRange(3700, 3723));
    expect(donations.settings, same(originalSettings));
    expect(donations.statistics, same(originalStatistics));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    await tester.tap(find.text(localization.tr('pause')));
    await tester.pumpAndSettle();
    expect(timer.isRunning, isFalse);
    final pausedDuration = timer.duration;
    await tester.tap(find.text('+1 ${localization.tr('min')}'));
    await tester.pumpAndSettle();
    expect(timer.duration, pausedDuration + 60);

    await openAppearance(tester);
    await selectStyle(tester, AppUiStyle.retro);
    expect(theme.uiStyle, AppUiStyle.retro);
    expect(theme.themeMode, ThemeMode.dark);
    expect(find.byType(AppearanceSettingsTab), findsOneWidget);
    await tester.tap(find.byType(NesButton).first);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NesContainer), findsWidgets);
    expect(timer.duration, pausedDuration + 60);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('classic $brightness uses Material controls and reset dialog', (
      tester,
    ) async {
      await theme.setUiStyle(AppUiStyle.classic);
      await theme.setThemeMode(
        brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      );
      timer.setTime(0, 5, 0);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byType(NesButton), findsNothing);
      expect(find.byType(NesContainer), findsNothing);
      expect(
        Theme.of(tester.element(find.byType(AppBar))).brightness,
        brightness,
      );
      await tester.ensureVisible(find.text(localization.tr('reset')));
      await tester.tap(find.text(localization.tr('reset')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text(localization.tr('cancel')));
      await tester.pumpAndSettle();
      expect(timer.duration, 300);

      await tester.tap(find.text(localization.tr('reset')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(localization.tr('reset')),
        ),
      );
      await tester.pumpAndSettle();
      expect(timer.duration, 0);
      expect(tester.takeException(), isNull);
    });
  }

  test('styles use separate fonts and support both brightness modes', () {
    for (final brightness in Brightness.values) {
      final retro = buildAppTheme(AppUiStyle.retro, brightness);
      final classic = buildAppTheme(AppUiStyle.classic, brightness);
      expect(retro.brightness, brightness);
      expect(classic.brightness, brightness);
      expect(retro.extension<NesTheme>(), isNotNull);
      expect(classic.extension<NesTheme>(), isNull);
      expect(
        classic.textTheme.bodyMedium?.fontFamily,
        isNot(retro.textTheme.bodyMedium?.fontFamily),
      );
    }
  });

  testWidgets('classic panels support expanding editor content', (
    tester,
  ) async {
    await theme.setUiStyle(AppUiStyle.classic);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: theme,
        child: MaterialApp(
          theme: buildAppTheme(theme.uiStyle, Brightness.light),
          home: const Scaffold(
            body: AppPanel(
              label: 'CSS',
              child: Column(
                children: [
                  Text('Preview'),
                  Expanded(child: TextField(expands: true, maxLines: null)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
