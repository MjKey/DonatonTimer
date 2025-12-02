import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';
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
  
  /// Shows navigation menu dialog with NesSelectionList.
  void _showNavigationMenu(LocalizationProvider localization) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: NesContainer(
          label: localization.tr('navigation'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NesSelectionList(
                  onSelect: (index) {
                    Navigator.of(dialogContext).pop();
                    _handleNavigationSelection(index);
                  },
                  children: [
                    Text(localization.tr('main_screen')),
                    Text(localization.tr('style_generator')),
                    Text(localization.tr('settings')),
                    Text(localization.tr('about_title')),
                  ],
                ),
                const SizedBox(height: 16),
                NesButton.text(
                  type: NesButtonType.normal,
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
            NesButton.icon(
              type: NesButtonType.normal,
              icon: NesIcons.tv,
              onPressed: () => _copyObsUrl(localization),
            ),
            const SizedBox(width: 8),
            // About button - информация о программе
            NesButton.icon(
              type: NesButtonType.normal,
              icon: NesIcons.questionMark,
              onPressed: () => _showAboutDialog(localization),
            ),
            const SizedBox(width: 8),
            // QR Code button for mobile control
            NesButton.icon(
              type: NesButtonType.normal,
              icon: NesIcons.camera,
              onPressed: () => _showQrCodeDialog(localization),
            ),
            const SizedBox(width: 8),
            // CSS Generator button
            NesButton.icon(
              type: NesButtonType.normal,
              icon: NesIcons.edit,
              onPressed: () => _openStyleGenerator(),
            ),
            const SizedBox(width: 8),
            // Settings button
            NesButton.icon(
              type: NesButtonType.normal,
              icon: NesIcons.wrench,
              onPressed: () => _openSettings(),
            ),
            const SizedBox(width: 8),
            // Language toggle
            NesButton.icon(
              type: NesButtonType.normal,
              icon: NesIcons.rename,
              onPressed: () => localization.toggleLanguage(),
            ),
            const SizedBox(width: 8),
            // Theme toggle
            NesButton.icon(
              type: NesButtonType.normal,
              icon: theme.isDarkMode 
                  ? NesIcons.sun 
                  : NesIcons.moon,
              onPressed: () => theme.toggleTheme(),
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
          child: NesContainer(
            label: localization.tr('about_title'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App icon/logo
                  NesIcon(
                    iconData: NesIcons.gamepad,
                    size: const Size(64, 64),
                  ),
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
                  NesContainer(
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
                  NesContainer(
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
                    '${localization.tr('version')}: 3.0.0',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  
                  // Close button
                  NesButton.text(
                    type: NesButtonType.primary,
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
        NesIcon(
          iconData: icon,
          size: const Size(16, 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Copies the OBS overlay URL to clipboard.
  void _copyObsUrl(LocalizationProvider localization) {
    final webServer = context.read<WebServerService?>();
    if (webServer == null) {
      NesSnackbar.show(
        context,
        text: localization.tr('error'),
        type: NesSnackbarType.error,
      );
      return;
    }

    final obsUrl = webServer.getTimerUrl();
    Clipboard.setData(ClipboardData(text: obsUrl));
    
    NesSnackbar.show(
      context,
      text: localization.tr('link_copied'),
      type: NesSnackbarType.success,
    );
  }

  /// Opens the settings screen.
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  /// Opens the style generator screen.
  void _openStyleGenerator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StyleGeneratorScreen(),
      ),
    );
  }

  /// Shows the QR code dialog for mobile control.
  void _showQrCodeDialog(LocalizationProvider localization) {
    final webServer = context.read<WebServerService?>();
    if (webServer == null) {
      NesSnackbar.show(
        context,
        text: localization.tr('error'),
        type: NesSnackbarType.error,
      );
      return;
    }

    final dashboardUrl = webServer.getDashboardUrl();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: NesContainer(
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
                NesContainer(
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
                    NesButton.text(
                      type: NesButtonType.primary,
                      text: localization.tr('link_copied').replaceAll(' copied', ''),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: dashboardUrl));
                        NesSnackbar.show(
                          context,
                          text: localization.tr('link_copied'),
                          type: NesSnackbarType.success,
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    NesButton.text(
                      type: NesButtonType.normal,
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
    return NesContainer(
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
  Widget _buildTimerControls(TimerProvider timer, LocalizationProvider localization) {
    return NesContainer(
      label: localization.tr('controls'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // -1 minute button
            NesButton.text(
              type: NesButtonType.warning,
              text: '-1 ${localization.tr('min')}',
              onPressed: timer.subtractMinute,
            ),
            const SizedBox(width: 16),
            
            // Start/Pause button
            NesButton.text(
              type: timer.isRunning 
                  ? NesButtonType.warning 
                  : NesButtonType.success,
              text: timer.isRunning 
                  ? localization.tr('pause') 
                  : localization.tr('start'),
              onPressed: timer.toggle,
            ),
            const SizedBox(width: 16),
            
            // +1 minute button
            NesButton.text(
              type: NesButtonType.primary,
              text: '+1 ${localization.tr('min')}',
              onPressed: timer.addMinute,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds quick time adjustment buttons.
  Widget _buildQuickTimeButtons(TimerProvider timer, LocalizationProvider localization) {
    return NesContainer(
      label: localization.tr('quick_time'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            NesButton.text(
              type: NesButtonType.normal,
              text: '+5 ${localization.tr('min')}',
              onPressed: () => timer.addMinutes(5),
            ),
            NesButton.text(
              type: NesButtonType.normal,
              text: '+10 ${localization.tr('min')}',
              onPressed: () => timer.addMinutes(10),
            ),
            NesButton.text(
              type: NesButtonType.normal,
              text: '+30 ${localization.tr('min')}',
              onPressed: () => timer.addMinutes(30),
            ),
            NesButton.text(
              type: NesButtonType.normal,
              text: '+1 ${localization.tr('hour')}',
              onPressed: () => timer.addMinutes(60),
            ),
            NesButton.text(
              type: NesButtonType.error,
              text: localization.tr('reset'),
              onPressed: () => _confirmReset(timer, localization),
            ),
          ],
        ),
      ),
    );
  }


  /// Builds the set time section with input fields.
  Widget _buildSetTimeSection(TimerProvider timer, LocalizationProvider localization) {
    return NesContainer(
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
            NesButton.text(
              type: NesButtonType.primary,
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
                NesButton.text(
                  type: NesButtonType.success,
                  text: '+${localization.tr('add')}',
                  onPressed: () => _addMinutesFromInput(timer),
                ),
                const SizedBox(width: 8),
                NesButton.text(
                  type: NesButtonType.warning,
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
    
    NesSnackbar.show(
      context,
      text: 'Timer set!',
      type: NesSnackbarType.success,
    );
  }

  /// Adds minutes from input field.
  void _addMinutesFromInput(TimerProvider timer) {
    final minutes = int.tryParse(_addMinutesController.text) ?? 0;
    if (minutes > 0) {
      timer.addMinutes(minutes);
      _addMinutesController.clear();
      NesSnackbar.show(
        context,
        text: '+$minutes min',
        type: NesSnackbarType.success,
      );
    }
  }

  /// Subtracts minutes from input field.
  void _subtractMinutesFromInput(TimerProvider timer) {
    final minutes = int.tryParse(_addMinutesController.text) ?? 0;
    if (minutes > 0) {
      timer.addMinutes(-minutes);
      _addMinutesController.clear();
      NesSnackbar.show(
        context,
        text: '-$minutes min',
        type: NesSnackbarType.warning,
      );
    }
  }

  /// Shows confirmation dialog before resetting timer.
  Future<void> _confirmReset(TimerProvider timer, LocalizationProvider localization) async {
    final result = await NesConfirmDialog.show(
      context: context,
      message: localization.tr('reset_confirm'),
    );
    
    if (result == true && mounted) {
      timer.reset();
      NesSnackbar.show(
        context,
        text: localization.tr('timer_reset'),
        type: NesSnackbarType.normal,
      );
    }
  }


  /// Builds the statistics section with recent donations and top donators.
  Widget _buildStatisticsSection(DonationService donationService, LocalizationProvider localization) {
    final stats = donationService.statistics;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent donations
        Expanded(
          child: NesContainer(
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
          child: NesContainer(
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
                        final entry = stats.getSortedTopDonators(limit: 10)[index];
                        return _buildTopDonatorItem(index + 1, entry.key, entry.value);
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
          Expanded(
            child: Text(
              username,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$totalMinutes min',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
