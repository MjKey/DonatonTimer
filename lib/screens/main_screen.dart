import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_container.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_confirm_dialog.dart';

import 'package:qr_flutter/qr_flutter.dart';

import '../providers/timer_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/theme_provider.dart';
import '../services/donation_service.dart';
import '../services/web_server_service.dart';
import '../models/donation_record.dart';
import 'settings_screen.dart';
import 'style_generator_screen.dart';

/// Главный экран приложения DonatonTimer.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();
  final TextEditingController _addMinutesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webServer = context.read<WebServerService?>();
      if (webServer != null && webServer.hasOldPortsWarning) {
        _showOldPortsWarning();
      }
    });
  }

  void _showOldPortsWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: AppContainer(
          label: 'Внимание!',
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(iconData: NesIcons.exclamationMarkBlock, size: const Size(48, 48)),
                const SizedBox(height: 16),
                const Text(
                  'Обнаружены старые настройки портов (8080/4040).\n\n'
                  'Они могут конфликтовать со Streamer.bot или другими программами.\n'
                  'Нажмите кнопку ниже, чтобы автоматически применить новые порты (7575/3434).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                AppButton(
                  type: AppButtonType.success,
                  text: 'Исправить порты',
                  onPressed: () {
                    final webServer = context.read<WebServerService?>();
                    final donationService = context.read<DonationService?>();
                    if (webServer != null && donationService != null) {
                      webServer.hasOldPortsWarning = false;
                      
                      final currentSettings = donationService.settings;
                      final newSettings = currentSettings.copyWith(
                        httpPort: 7575,
                        wsPort: 3434,
                      );
                      donationService.updateSettings(newSettings);
                      webServer.restartServers(httpPort: 7575, wsPort: 3434);
                    }
                    Navigator.of(context).pop();
                    
                    AppSnackbar.show(
                      context,
                      text: 'Порты успешно обновлены!',
                      type: AppSnackbarType.success,
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  type: AppButtonType.normal,
                  text: 'Игнорировать',
                  onPressed: () {
                    final webServer = context.read<WebServerService?>();
                    if (webServer != null) {
                      webServer.hasOldPortsWarning = false;
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows navigation menu dialog.
  void _showNavigationMenu(LocalizationProvider localization) {
    final items = [
      localization.tr('main_screen'),
      localization.tr('style_generator'),
      localization.tr('settings'),
      localization.tr('about_title'),
    ];
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: AppContainer(
          label: localization.tr('navigation'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(items.length, (index) => ListTile(
                  title: Text(items[index]),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _handleNavigationSelection(index);
                  },
                )),
                const SizedBox(height: 8),
                const SizedBox(height: 16),
                AppButton(
                  type: AppButtonType.normal,
                  text: localization.tr('close'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handles navigation menu selection.
  void _handleNavigationSelection(int index) {
    final localization = context.read<LocalizationProvider>();
    switch (index) {
      case 0:
        // Already on main screen
        break;
      case 1:
        _openStyleGenerator();
        break;
      case 2:
        _openSettings();
        break;
      case 3:
        _showAboutDialog(localization);
        break;
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _addMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final localization = context.watch<LocalizationProvider>();
    final theme = context.watch<ThemeProvider>();
    final donationService = context.watch<DonationService?>();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with title and theme toggle
            _buildHeader(localization, theme),
            const SizedBox(height: 16),

            // Timer display
            _buildTimerDisplay(timer),
            const SizedBox(height: 16),

            // Timer controls
            _buildTimerControls(timer, localization),
            const SizedBox(height: 16),

            // Quick time buttons
            _buildQuickTimeButtons(timer, localization),
            const SizedBox(height: 16),

            // Set time section
            _buildSetTimeSection(timer, localization),
            const SizedBox(height: 16),

            // Statistics section
            if (donationService != null)
              _buildStatisticsSection(donationService, localization),
          ],
        ),
      ),
    );
  }

  /// Builds the header with app title and theme toggle.
  Widget _buildHeader(LocalizationProvider localization, ThemeProvider theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          localization.tr('app_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            // Copy OBS overlay URL button
            AppButton(
              type: AppButtonType.normal,
              icon: NesIcons.tv,
              onPressed: () => _copyObsUrl(localization),
            ),
            const SizedBox(width: 8),
            // About button - информация о программе
            AppButton(
              type: AppButtonType.normal,
              icon: NesIcons.questionMark,
              onPressed: () => _showAboutDialog(localization),
            ),
            const SizedBox(width: 8),
            // QR Code button for mobile control
            AppButton(
              type: AppButtonType.normal,
              icon: NesIcons.camera,
              onPressed: () => _showQrCodeDialog(localization),
            ),
            const SizedBox(width: 8),
            // CSS Generator button
            AppButton(
              type: AppButtonType.normal,
              icon: NesIcons.edit,
              onPressed: () => _openStyleGenerator(),
            ),
            const SizedBox(width: 8),
            // Settings button
            AppButton(
              type: AppButtonType.normal,
              icon: NesIcons.wrench,
              onPressed: () => _openSettings(),
            ),
            const SizedBox(width: 8),
            // Language toggle
            AppButton(
              type: AppButtonType.normal,
              icon: NesIcons.rename,
              onPressed: () => localization.toggleLanguage(),
            ),
            const SizedBox(width: 8),
            // Theme toggle
            AppButton(
              type: AppButtonType.normal,
              icon: theme.isDarkMode ? NesIcons.sun : NesIcons.moon,
              onPressed: () => theme.toggleTheme(),
            ),
            const SizedBox(width: 8),
            // Style toggle (Pixel / Material)
            Tooltip(
              message: theme.isPixelStyle ? 'Переключить на Material' : 'Переключить на Pixel',
              child: InkWell(
                onTap: () => theme.setAppStyle(
                  theme.isPixelStyle ? AppStyle.material : AppStyle.pixel,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    theme.isPixelStyle ? Icons.view_quilt : Icons.videogame_asset,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Shows the About dialog with app information.
  void _showAboutDialog(LocalizationProvider localization) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: AppContainer(
            label: localization.tr('about_title'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App icon/logo
                  AppIcon(iconData: NesIcons.gamepad, size: const Size(64, 64)),
                  const SizedBox(height: 16),

                  // App name and version
                  Text(
                    localization.tr('app_title'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    localization.tr('app_description'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Features section
                  AppContainer(
                    label: localization.tr('features'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureItem(
                            NesIcons.check,
                            localization.tr('feature_multi_service'),
                          ),
                          const SizedBox(height: 8),
                          _buildFeatureItem(
                            NesIcons.check,
                            localization.tr('feature_obs_overlay'),
                          ),
                          const SizedBox(height: 8),
                          _buildFeatureItem(
                            NesIcons.check,
                            localization.tr('feature_mobile_control'),
                          ),
                          const SizedBox(height: 8),
                          _buildFeatureItem(
                            NesIcons.check,
                            localization.tr('feature_sound_alerts'),
                          ),
                          const SizedBox(height: 8),
                          _buildFeatureItem(
                            NesIcons.check,
                            localization.tr('feature_auto_save'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Changelog section
                  AppContainer(
                    label: localization.tr('changelog'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        localization.tr('changelog_v3'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Author info
                  Text(
                    '${localization.tr('author')}: MjKey',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${localization.tr('version')}: 3.0.5',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  // Close button
                  AppButton(
                    type: AppButtonType.primary,
                    text: localization.tr('ok_understood'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a feature item with icon and text.
  Widget _buildFeatureItem(NesIconData icon, String text) {
    return Row(
      children: [
        AppIcon(iconData: icon, size: const Size(16, 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  /// Copies the OBS overlay URL to clipboard.
  void _copyObsUrl(LocalizationProvider localization) {
    final webServer = context.read<WebServerService?>();
    if (webServer == null) {
      AppSnackbar.show(
        context,
        text: localization.tr('error'),
        type: AppSnackbarType.error,
      );
      return;
    }

    final obsUrl = webServer.getTimerUrl();
    Clipboard.setData(ClipboardData(text: obsUrl));

    AppSnackbar.show(
      context,
      text: localization.tr('link_copied'),
      type: AppSnackbarType.success,
    );
  }

  /// Opens the settings screen.
  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  /// Opens the style generator screen.
  void _openStyleGenerator() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StyleGeneratorScreen()),
    );
  }

  /// Shows the QR code dialog for mobile control.
  void _showQrCodeDialog(LocalizationProvider localization) {
    final webServer = context.read<WebServerService?>();
    if (webServer == null) {
      AppSnackbar.show(
        context,
        text: localization.tr('error'),
        type: AppSnackbarType.error,
      );
      return;
    }

    final dashboardUrl = webServer.getDashboardUrl();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: AppContainer(
          label: localization.tr('qr_code_title'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: dashboardUrl,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  localization.tr('qr_code_description'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),

                // Network warning
                Text(
                  localization.tr('same_network_required'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                // URL display
                AppContainer(
                  label: localization.tr('dashboard_url'),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SelectableText(
                      dashboardUrl,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      type: AppButtonType.primary,
                      text: localization
                          .tr('link_copied')
                          .replaceAll(' copied', ''),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: dashboardUrl));
                        AppSnackbar.show(
                          context,
                          text: localization.tr('link_copied'),
                          type: AppSnackbarType.success,
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    AppButton(
                      type: AppButtonType.normal,
                      text: localization.tr('close'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main timer display.
  Widget _buildTimerDisplay(TimerProvider timer) {
    return AppContainer(
      label: 'Timer',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            timer.formatDuration(),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the main timer control buttons (start/pause, +/- minutes).
  Widget _buildTimerControls(
    TimerProvider timer,
    LocalizationProvider localization,
  ) {
    return AppContainer(
      label: localization.tr('controls'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // -1 minute button
            AppButton(
              type: AppButtonType.warning,
              text: '-1 ${localization.tr('min')}',
              onPressed: timer.subtractMinute,
            ),
            const SizedBox(width: 16),

            // Start/Pause button
            AppButton(
              type: timer.isRunning
                  ? AppButtonType.warning
                  : AppButtonType.success,
              text: timer.isRunning
                  ? localization.tr('pause')
                  : localization.tr('start'),
              onPressed: timer.toggle,
            ),
            const SizedBox(width: 16),

            // +1 minute button
            AppButton(
              type: AppButtonType.primary,
              text: '+1 ${localization.tr('min')}',
              onPressed: timer.addMinute,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds quick time adjustment buttons.
  Widget _buildQuickTimeButtons(
    TimerProvider timer,
    LocalizationProvider localization,
  ) {
    return AppContainer(
      label: localization.tr('quick_time'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            AppButton(
              type: AppButtonType.normal,
              text: '+5 ${localization.tr('min')}',
              onPressed: () => timer.addMinutes(5),
            ),
            AppButton(
              type: AppButtonType.normal,
              text: '+10 ${localization.tr('min')}',
              onPressed: () => timer.addMinutes(10),
            ),
            AppButton(
              type: AppButtonType.normal,
              text: '+30 ${localization.tr('min')}',
              onPressed: () => timer.addMinutes(30),
            ),
            AppButton(
              type: AppButtonType.normal,
              text: '+1 ${localization.tr('hour')}',
              onPressed: () => timer.addMinutes(60),
            ),
            AppButton(
              type: AppButtonType.error,
              text: localization.tr('reset'),
              onPressed: () => _confirmReset(timer, localization),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the set time section with input fields.
  Widget _buildSetTimeSection(
    TimerProvider timer,
    LocalizationProvider localization,
  ) {
    return AppContainer(
      label: localization.tr('set_time'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Time input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeInput(
                  controller: _hoursController,
                  label: localization.tr('hours'),
                  maxValue: 99,
                ),
                const SizedBox(width: 8),
                const Text(':', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                _buildTimeInput(
                  controller: _minutesController,
                  label: localization.tr('minutes'),
                  maxValue: 59,
                ),
                const SizedBox(width: 8),
                const Text(':', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                _buildTimeInput(
                  controller: _secondsController,
                  label: localization.tr('seconds'),
                  maxValue: 59,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              type: AppButtonType.primary,
              text: localization.tr('set_timer'),
              onPressed: () => _setTimerFromInputs(timer),
            ),
            const SizedBox(height: 16),
            // Add minutes input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _addMinutesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: localization.tr('min'),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  type: AppButtonType.success,
                  text: '+${localization.tr('add')}',
                  onPressed: () => _addMinutesFromInput(timer),
                ),
                const SizedBox(width: 8),
                AppButton(
                  type: AppButtonType.warning,
                  text: '-${localization.tr('subtract')}',
                  onPressed: () => _subtractMinutesFromInput(timer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a time input field.
  Widget _buildTimeInput({
    required TextEditingController controller,
    required String label,
    required int maxValue,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '00',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// Sets the timer from input fields.
  void _setTimerFromInputs(TimerProvider timer) {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;

    timer.setTime(hours, minutes, seconds);

    // Clear inputs
    _hoursController.clear();
    _minutesController.clear();
    _secondsController.clear();

    AppSnackbar.show(
      context,
      text: 'Timer set!',
      type: AppSnackbarType.success,
    );
  }

  /// Adds minutes from input field.
  void _addMinutesFromInput(TimerProvider timer) {
    final minutes = int.tryParse(_addMinutesController.text) ?? 0;
    if (minutes > 0) {
      timer.addMinutes(minutes);
      _addMinutesController.clear();
      AppSnackbar.show(
        context,
        text: '+$minutes min',
        type: AppSnackbarType.success,
      );
    }
  }

  /// Subtracts minutes from input field.
  void _subtractMinutesFromInput(TimerProvider timer) {
    final minutes = int.tryParse(_addMinutesController.text) ?? 0;
    if (minutes > 0) {
      timer.addMinutes(-minutes);
      _addMinutesController.clear();
      AppSnackbar.show(
        context,
        text: '-$minutes min',
        type: AppSnackbarType.warning,
      );
    }
  }

  /// Shows confirmation dialog before resetting timer.
  Future<void> _confirmReset(
    TimerProvider timer,
    LocalizationProvider localization,
  ) async {
    final result = await AppConfirmDialog.show(
      context: context,
      message: localization.tr('reset_confirm'),
    );

    if (result == true && mounted) {
      timer.reset();
      AppSnackbar.show(
        context,
        text: localization.tr('timer_reset'),
        type: AppSnackbarType.normal,
      );
    }
  }

  /// Builds the statistics section with recent donations and top donators.
  Widget _buildStatisticsSection(
    DonationService donationService,
    LocalizationProvider localization,
  ) {
    final stats = donationService.statistics;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent donations
        Expanded(
          child: AppContainer(
            label: localization.tr('recent_donations'),
            child: SizedBox(
              height: 200,
              child: stats.recentDonations.isEmpty
                  ? Center(
                      child: Text(
                        localization.tr('no_donations'),
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: stats.recentDonations.take(10).length,
                      itemBuilder: (context, index) {
                        final donation = stats.recentDonations[index];
                        return _buildDonationItem(donation);
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Top donators
        Expanded(
          child: AppContainer(
            label: localization.tr('top_donators'),
            child: SizedBox(
              height: 200,
              child: stats.topDonators.isEmpty
                  ? Center(
                      child: Text(
                        localization.tr('no_donators'),
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: stats.getSortedTopDonators(limit: 10).length,
                      itemBuilder: (context, index) {
                        final entry = stats.getSortedTopDonators(
                          limit: 10,
                        )[index];
                        return _buildTopDonatorItem(
                          index + 1,
                          entry.key,
                          entry.value,
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a single donation item in the list.
  Widget _buildDonationItem(DonationRecord donation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              donation.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '+${donation.minutesAdded} min',
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }

  /// Builds a single top donator item in the list.
  Widget _buildTopDonatorItem(int rank, String username, int totalMinutes) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = Colors.amber;
        break;
      case 2:
        rankColor = Colors.grey;
        break;
      case 3:
        rankColor = Colors.brown;
        break;
      default:
        rankColor = Colors.blueGrey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(username, overflow: TextOverflow.ellipsis)),
          Text(
            '$totalMinutes min',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
