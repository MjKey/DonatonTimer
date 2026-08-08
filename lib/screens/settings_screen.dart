import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

import '../providers/localization_provider.dart';
import '../providers/timer_provider.dart';
import '../services/donation_service.dart';
import '../services/donation_service_adapter.dart';
import '../services/sound_service.dart';
import '../services/log_manager.dart';
import '../services/web_server_service.dart';
import '../models/service_config.dart';
import '../models/app_settings.dart';

/// Экран настроек с вкладками для сервисов, таймера и звуков.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                NesButton.icon(
                  type: NesButtonType.normal,
                  icon: NesIcons.leftArrowIndicator,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 16),
                Text(
                  localization.tr('settings'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab buttons
            _buildTabButtons(localization),
            const SizedBox(height: 16),

            // Tab content
            Expanded(child: _buildTabContent(localization)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButtons(LocalizationProvider localization) {
    return Row(
      children: [
        Expanded(
          child: NesButton.text(
            type: _selectedTabIndex == 0
                ? NesButtonType.primary
                : NesButtonType.normal,
            text: localization.tr('services'),
            onPressed: () => setState(() => _selectedTabIndex = 0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: NesButton.text(
            type: _selectedTabIndex == 1
                ? NesButtonType.primary
                : NesButtonType.normal,
            text: localization.tr('timer'),
            onPressed: () => setState(() => _selectedTabIndex = 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: NesButton.text(
            type: _selectedTabIndex == 2
                ? NesButtonType.primary
                : NesButtonType.normal,
            text: localization.tr('sounds'),
            onPressed: () => setState(() => _selectedTabIndex = 2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: NesButton.text(
            type: _selectedTabIndex == 3
                ? NesButtonType.primary
                : NesButtonType.normal,
            text: localization.tr('data'),
            onPressed: () => setState(() => _selectedTabIndex = 3),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(LocalizationProvider localization) {
    switch (_selectedTabIndex) {
      case 0:
        return const ServicesSettingsTab();
      case 1:
        return const TimerSettingsTab();
      case 2:
        return const SoundsSettingsTab();
      case 3:
        return const DataSettingsTab();
      default:
        return const ServicesSettingsTab();
    }
  }
}

/// Вкладка настройки донат-сервисов.
class ServicesSettingsTab extends StatefulWidget {
  const ServicesSettingsTab({super.key});

  @override
  State<ServicesSettingsTab> createState() => _ServicesSettingsTabState();
}

class _ServicesSettingsTabState extends State<ServicesSettingsTab> {
  // DonationAlerts controllers
  final _daTokenController = TextEditingController();
  bool _daEnabled = false;
  String _daSocketServer = 'socket5';
  String _daDomain = 'com';
  bool _daTokenVisible = false;

  // DonatePay controllers
  final _dpApiKeyController = TextEditingController();
  bool _dpEnabled = false;
  bool _dpKeyVisible = false;

  // Donate.Stream controllers
  final _dsTokenController = TextEditingController();
  bool _dsEnabled = false;
  bool _dsTokenVisible = false;

  // DonateX controllers
  final _dxWidgetUrlController = TextEditingController();
  final _dxGroupUrlController = TextEditingController();
  bool _dxEnabled = false;
  bool _dxTokenVisible = false;

  // Donatty controllers
  final _donattyTokenController = TextEditingController();
  bool _donattyEnabled = false;
  bool _donattyTokenVisible = false;
  String _donattyApiServer = 'api-014';
  
  static const List<String> _donattyApiServers = [
    'api-014',
    'api',
    'api-015',
    'api-013',
    'api-010',
    'api-011',
    'api-012',
    'api-007',
    'api-009',
    'api-006',
    'api-001',
    'api-002',
    'api-003',
    'api-004',
    'api-005',
    'api-008',
  ];

  // CloudTips controllers
  final _ctTokenController = TextEditingController();
  bool _ctEnabled = false;
  bool _ctTokenVisible = false;

  // StreamerBot controllers
  final _sbWsUrlController = TextEditingController();
  bool _sbEnabled = false;
  
  List<Map<String, dynamic>> _sbMappings = [];
  bool _sbIsAddingMapping = false;
  final _sbSourceController = TextEditingController();
  final _sbTypeController = TextEditingController();
  final _sbAmountController = TextEditingController();

  // Available socket servers and domains for DonationAlerts
  static const List<String> _socketServers = [
    'socket5',
    'socket',
    'socket1',
    'socket2',
    'socket3',
    'socket4',
  ];
  static const List<String> _daDomains = [
    'com',
    'ru',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final donationService = context.read<DonationService?>();
    if (donationService == null) return;

    final settings = donationService.settings;

    // DonationAlerts
    final daConfig = settings.getServiceConfig('DonationAlerts');
    if (daConfig != null) {
      _daEnabled = daConfig.enabled;
      _daTokenController.text = daConfig.getCredential('token') ?? '';
      _daSocketServer = daConfig.getCredential('socketServer') ?? 'socket5';
      _daDomain = daConfig.getCredential('domain') ?? 'com';
    }

    // DonatePay
    final dpConfig = settings.getServiceConfig('DonatePay');
    if (dpConfig != null) {
      _dpEnabled = dpConfig.enabled;
      _dpApiKeyController.text = dpConfig.getCredential('apiKey') ?? '';
    }

    // Donate.Stream
    final dsConfig = settings.getServiceConfig('DonateStream');
    if (dsConfig != null) {
      _dsEnabled = dsConfig.enabled;
      _dsTokenController.text = dsConfig.getCredential('token') ?? '';
    }

    // DonateX
    final dxConfig = settings.getServiceConfig('DonateX');
    if (dxConfig != null) {
      _dxEnabled = dxConfig.enabled;
      _dxWidgetUrlController.text = dxConfig.getCredential('widgetUrl') ?? '';
      _dxGroupUrlController.text = dxConfig.getCredential('groupUrl') ?? '';
    }

    // Donatty
    final donattyConfig = settings.getServiceConfig('Donatty');
    if (donattyConfig != null) {
      _donattyEnabled = donattyConfig.enabled;
      _donattyTokenController.text = donattyConfig.getCredential('token') ?? '';
      _donattyApiServer = donattyConfig.getCredential('apiServer') ?? 'api-014';
    }

    // CloudTips
    final ctConfig = settings.getServiceConfig('CloudTips');
    if (ctConfig != null) {
      _ctEnabled = ctConfig.enabled;
      _ctTokenController.text = ctConfig.getCredential('token') ?? '';
    }

    // StreamerBot
    final sbConfig = settings.getServiceConfig('StreamerBot');
    if (sbConfig != null) {
      _sbEnabled = sbConfig.enabled;
      _sbWsUrlController.text = sbConfig.getCredential('wsUrl') ?? 'ws://127.0.0.1:8080/';
      final mappingsStr = sbConfig.getCredential('mappings');
      if (mappingsStr != null && mappingsStr.isNotEmpty) {
        try {
          final parsed = json.decode(mappingsStr) as List;
          _sbMappings = parsed.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (_) {
          _sbMappings = [];
        }
      } else {
        _sbMappings = [];
      }
    } else {
      _sbWsUrlController.text = 'ws://127.0.0.1:8080/';
      _sbMappings = [];
    }

    setState(() {});
  }

  @override
  void dispose() {
    _daTokenController.dispose();
    _dpApiKeyController.dispose();
    _dsTokenController.dispose();
    _dxWidgetUrlController.dispose();
    _dxGroupUrlController.dispose();
    _donattyTokenController.dispose();
    _ctTokenController.dispose();
    _sbWsUrlController.dispose();
    _sbSourceController.dispose();
    _sbTypeController.dispose();
    _sbAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveServiceConfig(
    String serviceName,
    bool enabled,
    Map<String, String> credentials,
  ) async {
    final donationService = context.read<DonationService?>();
    if (donationService == null) return;

    final config = ServiceConfig(
      serviceName: serviceName,
      enabled: enabled,
      credentials: credentials,
    );

    await donationService.updateServiceConfig(config);

    if (mounted) {
      NesSnackbar.show(
        context,
        text: '$serviceName OK!',
        type: NesSnackbarType.success,
      );
    }
  }

  ConnectionStatus _getAdapterStatus(String serviceName) {
    final donationService = context.read<DonationService?>();
    if (donationService == null) return ConnectionStatus.disconnected;
    final adapter = donationService.getAdapter(serviceName);
    return adapter?.status ?? ConnectionStatus.disconnected;
  }

  Widget _buildStatusIndicator(ConnectionStatus status) {
    Color color;
    String tooltip;

    switch (status) {
      case ConnectionStatus.connected:
        color = Colors.green;
        tooltip = 'Подключено';
        break;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
        color = Colors.orange;
        tooltip = 'Подключение...';
        break;
      case ConnectionStatus.error:
        color = Colors.red;
        tooltip = 'Ошибка';
        break;
      case ConnectionStatus.disconnected:
      default:
        color = Colors.grey;
        tooltip = 'Отключено';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: status == ConnectionStatus.connected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();
    // Watch donation service for status updates
    context.watch<DonationService?>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // DonationAlerts
          _buildDonationAlertsSection(localization),
          const SizedBox(height: 16),

          // DonatePay
          _buildDonatePaySection(localization),
          const SizedBox(height: 16),

          // Donate.Stream
          _buildDonateStreamSection(localization),
          const SizedBox(height: 16),

          // DonateX
          _buildDonateXSection(localization),
          const SizedBox(height: 16),

          // Donatty
          _buildDonattySection(localization),
          const SizedBox(height: 16),

          // CloudTips
          _buildCloudTipsSection(localization),
          const SizedBox(height: 16),

          // StreamerBot
          _buildStreamerBotSection(localization),
        ],
      ),
    );
  }

  Widget _buildDonationAlertsSection(LocalizationProvider localization) {
    final status = _getAdapterStatus('DonationAlerts');
    return NesContainer(
      label: localization.tr('donation_alerts'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable checkbox + status indicator
            Row(
              children: [
                NesCheckBox(
                  value: _daEnabled,
                  onChange: (value) => setState(() => _daEnabled = value),
                ),
                const SizedBox(width: 12),
                Text(
                  _daEnabled
                      ? localization.tr('enabled')
                      : localization.tr('disabled'),
                ),
                const Spacer(),
                _buildStatusIndicator(status),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),

            // Token field
            Text(
              '${localization.tr('token')} (${localization.tr('or_widget_url')}):',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _daTokenController,
              obscureText: !_daTokenVisible,
              decoration: InputDecoration(
                hintText: 'Token or widget URL',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _daTokenVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _daTokenVisible = !_daTokenVisible),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Можно вставить ссылку виджета или только токен',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Domain dropdown
            Text('${localization.tr('domain')}:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _daDomain,
              isExpanded: true,
              items: _daDomains.map((domain) {
                return DropdownMenuItem(
                  value: domain,
                  child: Text('donationalerts.$domain'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _daDomain = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Socket server dropdown
            Text('${localization.tr('socket_server')}:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _daSocketServer,
              isExpanded: true,
              items: _socketServers.map((socket) {
                return DropdownMenuItem(
                  value: socket,
                  child: Text('$socket.donationalerts.$_daDomain'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _daSocketServer = value);
                }
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Если донаты не приходят - попробуйте другой сокет',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Save button
            NesButton.text(
              type: NesButtonType.success,
              text: localization.tr('save'),
              onPressed: () =>
                  _saveServiceConfig('DonationAlerts', _daEnabled, {
                    'token': _daTokenController.text,
                    'socketServer': _daSocketServer,
                    'domain': _daDomain,
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonatePaySection(LocalizationProvider localization) {
    final status = _getAdapterStatus('DonatePay');
    return NesContainer(
      label: localization.tr('donate_pay'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable checkbox + status indicator
            Row(
              children: [
                NesCheckBox(
                  value: _dpEnabled,
                  onChange: (value) => setState(() => _dpEnabled = value),
                ),
                const SizedBox(width: 12),
                Text(
                  _dpEnabled
                      ? localization.tr('enabled')
                      : localization.tr('disabled'),
                ),
                const Spacer(),
                _buildStatusIndicator(status),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),

            // API Key field
            Text('API Key:'),
            const SizedBox(height: 8),
            TextField(
              controller: _dpApiKeyController,
              obscureText: !_dpKeyVisible,
              decoration: InputDecoration(
                hintText: 'API key from DonatePay',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _dpKeyVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _dpKeyVisible = !_dpKeyVisible),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            NesButton.text(
              type: NesButtonType.success,
              text: localization.tr('save'),
              onPressed: () => _saveServiceConfig('DonatePay', _dpEnabled, {
                'apiKey': _dpApiKeyController.text,
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonateStreamSection(LocalizationProvider localization) {
    final status = _getAdapterStatus('DonateStream');
    return NesContainer(
      label: localization.tr('donate_stream'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable checkbox + status indicator
            Row(
              children: [
                NesCheckBox(
                  value: _dsEnabled,
                  onChange: (value) => setState(() => _dsEnabled = value),
                ),
                const SizedBox(width: 12),
                Text(
                  _dsEnabled
                      ? localization.tr('enabled')
                      : localization.tr('disabled'),
                ),
                const Spacer(),
                _buildStatusIndicator(status),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),

            // Token field
            Text(
              '${localization.tr('token')} (${localization.tr('or_widget_url')}):',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dsTokenController,
              obscureText: !_dsTokenVisible,
              decoration: InputDecoration(
                hintText: 'Token or widget URL',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _dsTokenVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _dsTokenVisible = !_dsTokenVisible),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Можно вставить ссылку виджета или только токен',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Save button
            NesButton.text(
              type: NesButtonType.success,
              text: localization.tr('save'),
              onPressed: () => _saveServiceConfig('DonateStream', _dsEnabled, {
                'token': _dsTokenController.text,
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonateXSection(LocalizationProvider localization) {
    final status = _getAdapterStatus('DonateX');
    return NesContainer(
      label: localization.tr('donatex'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enable checkbox + status indicator
            Row(
              children: [
                NesCheckBox(
                  value: _dxEnabled,
                  onChange: (value) => setState(() => _dxEnabled = value),
                ),
                const SizedBox(width: 12),
                Text(
                  _dxEnabled
                      ? localization.tr('enabled')
                      : localization.tr('disabled'),
                ),
                const Spacer(),
                _buildStatusIndicator(status),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              localization.tr('donatex_setup_note'),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Widget URL field (for token extraction)
            Text('${localization.tr('donatex_recent_url_label')}:'),
            const SizedBox(height: 8),
            TextField(
              controller: _dxWidgetUrlController,
              obscureText: !_dxTokenVisible,
              decoration: InputDecoration(
                hintText: localization.tr('donatex_recent_url_hint'),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _dxTokenVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _dxTokenVisible = !_dxTokenVisible),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localization.tr('donatex_recent_url_help'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Group URL field (for widget_id extraction)
            Text('${localization.tr('donatex_group_url_label')}:'),
            const SizedBox(height: 8),
            TextField(
              controller: _dxGroupUrlController,
              decoration: InputDecoration(
                hintText: localization.tr('donatex_group_url_hint'),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Offstage(
              offstage: true,
              child: Text(
                'Виджет последних сообщений → токен, Группа оповещалки → widget_id',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
            Text(
              localization.tr('donatex_group_url_help'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Save button
            NesButton.text(
              type: NesButtonType.success,
              text: localization.tr('save'),
              onPressed: () => _saveDonateXConfig(),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDonateXConfig() {
    // Extract token from widget URL
    String? token;
    final widgetUrl = _dxWidgetUrlController.text;
    if (widgetUrl.contains('token=')) {
      final uri = Uri.tryParse(widgetUrl);
      token = uri?.queryParameters['token'];
    } else {
      token = widgetUrl; // Assume it's just the token
    }

    // Extract widget_id from group URL
    String? widgetId;
    final groupUrl = _dxGroupUrlController.text;
    final donationsMatch = RegExp(
      r'/widgets/donations/([a-f0-9-]+)',
    ).firstMatch(groupUrl);
    if (donationsMatch != null) {
      widgetId = donationsMatch.group(1);
    } else {
      widgetId = groupUrl; // Assume it's just the widget_id
    }

    _saveServiceConfig('DonateX', _dxEnabled, {
      'token': token ?? '',
      'widgetId': widgetId ?? '',
      'widgetUrl': _dxWidgetUrlController.text,
      'groupUrl': _dxGroupUrlController.text,
    });
  }

  Widget _buildDonattySection(LocalizationProvider localization) {
    final status = _getAdapterStatus('Donatty');
    return NesContainer(
      label: 'Donatty',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NesCheckBox(
                  value: _donattyEnabled,
                  onChange: (value) => setState(() => _donattyEnabled = value),
                ),
                const SizedBox(width: 12),
                Text(
                  _donattyEnabled
                      ? localization.tr('enabled')
                      : localization.tr('disabled'),
                ),
                const Spacer(),
                _buildStatusIndicator(status),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),
            Text('${localization.tr('donatty_link_label')}:'),
            const SizedBox(height: 8),
            TextField(
              controller: _donattyTokenController,
              obscureText: !_donattyTokenVisible,
              decoration: InputDecoration(
                hintText: 'https://widgets.donatty.com/group/?ref=...&token=...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _donattyTokenVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _donattyTokenVisible = !_donattyTokenVisible),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // API server dropdown
            Text('${localization.tr('api_server')}:'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _donattyApiServer,
              isExpanded: true,
              items: _donattyApiServers.map((server) {
                return DropdownMenuItem(
                  value: server,
                  child: Text('$server.donatty.com'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _donattyApiServer = value);
                }
              },
            ),
            const SizedBox(height: 4),
            Text(
              'По умолчанию api-014. Измените, если донаты не приходят.',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            NesButton.text(
              type: NesButtonType.success,
              text: localization.tr('save'),
              onPressed: () => _saveServiceConfig('Donatty', _donattyEnabled, {
                'token': _donattyTokenController.text,
                'apiServer': _donattyApiServer,
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudTipsSection(LocalizationProvider localization) {
    final status = _getAdapterStatus('CloudTips');
    return NesContainer(
      label: 'CloudTips',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NesCheckBox(
                  value: _ctEnabled,
                  onChange: (value) => setState(() => _ctEnabled = value),
                ),
                const SizedBox(width: 12),
                Text(
                  _ctEnabled
                      ? localization.tr('enabled')
                      : localization.tr('disabled'),
                ),
                const Spacer(),
                _buildStatusIndicator(status),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),
            Text('${localization.tr('cloudtips_link_label')}:'),
            const SizedBox(height: 8),
            TextField(
              controller: _ctTokenController,
              obscureText: !_ctTokenVisible,
              decoration: InputDecoration(
                hintText: 'https://stream.cloudtips.ru/n/...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _ctTokenVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _ctTokenVisible = !_ctTokenVisible),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localization.tr('cloudtips_link_hint'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            NesButton.text(
              type: NesButtonType.success,
              text: localization.tr('save'),
              onPressed: () => _saveServiceConfig('CloudTips', _ctEnabled, {
                'token': _ctTokenController.text.trim(),
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamerBotSection(LocalizationProvider localization) {
    final status = _getAdapterStatus('StreamerBot');
    return NesContainer(
      label: 'Streamer.bot',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NesCheckBox(
                  value: _sbEnabled,
                  onChange: (value) => setState(() => _sbEnabled = value),
                ),
                const SizedBox(width: 12),
                Text(
                  _sbEnabled
                      ? localization.tr('enabled')
                      : localization.tr('disabled'),
                ),
                const Spacer(),
                _buildStatusIndicator(status),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 16),
            Text('${localization.tr('sb_ws_url_label')}:'),
            const SizedBox(height: 8),
            TextField(
              controller: _sbWsUrlController,
              decoration: InputDecoration(
                hintText: localization.tr('sb_ws_url_hint'),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              localization.tr('sb_ws_ensure_running'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            NesButton.text(
              type: NesButtonType.success,
              text: localization.tr('save'),
              onPressed: () => _saveServiceConfig('StreamerBot', _sbEnabled, {
                'wsUrl': _sbWsUrlController.text,
                'mappings': json.encode(_sbMappings),
              }),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(localization.tr('sb_event_mappings')),
            const SizedBox(height: 8),
            ..._sbMappings.asMap().entries.map((entry) {
              final index = entry.key;
              final mapping = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${mapping['source']} / ${mapping['type']} → ${mapping['amount']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _sbMappings.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            if (_sbIsAddingMapping) ...[
              const SizedBox(height: 8),
              NesContainer(
                label: localization.tr('sb_new_event'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _sbSourceController,
                      decoration: InputDecoration(
                        hintText: localization.tr('sb_source_hint'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sbTypeController,
                      decoration: InputDecoration(
                        hintText: localization.tr('sb_type_hint'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sbAmountController,
                      decoration: InputDecoration(
                        hintText: localization.tr('sb_amount_hint'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        NesButton.text(
                          type: NesButtonType.normal,
                          text: localization.tr('sb_cancel'),
                          onPressed: () => setState(() => _sbIsAddingMapping = false),
                        ),
                        const SizedBox(width: 8),
                        NesButton.text(
                          type: NesButtonType.success,
                          text: 'ОК',
                          onPressed: () {
                            final amount = double.tryParse(_sbAmountController.text) ?? 0.0;
                            if (_sbSourceController.text.isNotEmpty && _sbTypeController.text.isNotEmpty) {
                              setState(() {
                                _sbMappings.add({
                                  'source': _sbSourceController.text.trim(),
                                  'type': _sbTypeController.text.trim(),
                                  'amount': amount,
                                });
                                _sbIsAddingMapping = false;
                                _sbSourceController.clear();
                                _sbTypeController.clear();
                                _sbAmountController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              NesButton.text(
                type: NesButtonType.normal,
                text: localization.tr('sb_add_event'),
                onPressed: () => setState(() => _sbIsAddingMapping = true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Вкладка настройки таймера.
class TimerSettingsTab extends StatefulWidget {
  const TimerSettingsTab({super.key});

  @override
  State<TimerSettingsTab> createState() => _TimerSettingsTabState();
}

class _TimerSettingsTabState extends State<TimerSettingsTab> {
  final _rateController = TextEditingController();
  final _timePerAmountMinutesController = TextEditingController();
  final _fixedTimeMinutesController = TextEditingController();
  final _httpPortController = TextEditingController();
  final _wsPortController = TextEditingController();
  bool _isFixedTimeMode = false;
  bool _isSubtractionMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final donationService = context.read<DonationService?>();
    if (donationService == null) return;

    final settings = donationService.settings;
    _rateController.text = settings.minutesPerAmount.toString();
    _timePerAmountMinutesController.text = settings.timePerAmountMinutes
        .toString();
    _fixedTimeMinutesController.text = settings.fixedTimeMinutes.toString();
    _httpPortController.text = settings.httpPort.toString();
    _wsPortController.text = settings.wsPort.toString();
    _isFixedTimeMode = settings.isFixedTimeMode;
    _isSubtractionMode = settings.isSubtractionMode;
  }

  @override
  void dispose() {
    _rateController.dispose();
    _timePerAmountMinutesController.dispose();
    _fixedTimeMinutesController.dispose();
    _httpPortController.dispose();
    _wsPortController.dispose();
    super.dispose();
  }

  Future<void> _saveTimerSettings() async {
    final donationService = context.read<DonationService?>();
    if (donationService == null) return;

    final rate = double.tryParse(_rateController.text);
    final timePerAmountMinutes = int.tryParse(
      _timePerAmountMinutesController.text,
    );
    final fixedTimeMinutes = int.tryParse(_fixedTimeMinutesController.text);
    final httpPort = int.tryParse(_httpPortController.text);
    final wsPort = int.tryParse(_wsPortController.text);

    if (rate == null || rate <= 0) {
      NesSnackbar.show(
        context,
        text: 'Invalid rate value',
        type: NesSnackbarType.error,
      );
      return;
    }

    if (timePerAmountMinutes == null || timePerAmountMinutes <= 0) {
      NesSnackbar.show(
        context,
        text: 'Invalid time value',
        type: NesSnackbarType.error,
      );
      return;
    }

    if (fixedTimeMinutes == null || fixedTimeMinutes <= 0) {
      NesSnackbar.show(
        context,
        text: 'Invalid fixed time value',
        type: NesSnackbarType.error,
      );
      return;
    }

    if (httpPort == null || httpPort < 1 || httpPort > 65535) {
      NesSnackbar.show(
        context,
        text: context.read<LocalizationProvider>().tr('invalid_port'),
        type: NesSnackbarType.error,
      );
      return;
    }

    if (wsPort == null || wsPort < 1 || wsPort > 65535) {
      NesSnackbar.show(
        context,
        text: context.read<LocalizationProvider>().tr('invalid_port'),
        type: NesSnackbarType.error,
      );
      return;
    }

    final newSettings = donationService.settings.copyWith(
      minutesPerAmount: rate,
      timePerAmountMinutes: timePerAmountMinutes,
      httpPort: httpPort,
      wsPort: wsPort,
      isFixedTimeMode: _isFixedTimeMode,
      fixedTimeMinutes: fixedTimeMinutes,
      isSubtractionMode: _isSubtractionMode,
    );

    await donationService.updateSettings(newSettings);

    final webServerService = context.read<WebServerService?>();
    if (webServerService != null) {
      try {
        await webServerService.restartServers(
          httpPort: httpPort,
          wsPort: wsPort,
        );
      } catch (e) {
        if (mounted) {
          NesSnackbar.show(
            context,
            text: 'Ошибка запуска сервера: $e',
            type: NesSnackbarType.error,
          );
        }
      }
    }

    if (mounted) {
      NesSnackbar.show(
        context,
        text: context.read<LocalizationProvider>().tr('settings_saved'),
        type: NesSnackbarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rate settings
          NesContainer(
            label: localization.tr('minutes_per_amount'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'По умолчанию 600 RUB = 60 минут',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '600',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            suffixText: 'RUB',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('='),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _timePerAmountMinutesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '60',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            suffixText: localization.tr('min'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Пример: 600 RUB = 60 мин → донат 1200₽ = 120 мин',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fixed time & subtraction settings
          NesContainer(
            label: localization.tr('fixed_time_mode'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NesCheckBox(
                        value: _isFixedTimeMode,
                        onChange: (value) =>
                            setState(() => _isFixedTimeMode = value),
                      ),
                      const SizedBox(width: 12),
                      Text(localization.tr('fixed_time_mode')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('${localization.tr('fixed_time_minutes')}:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fixedTimeMinutesController,
                    keyboardType: TextInputType.number,
                    enabled: _isFixedTimeMode,
                    decoration: InputDecoration(
                      hintText: '1',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      NesCheckBox(
                        value: _isSubtractionMode,
                        onChange: (value) =>
                            setState(() => _isSubtractionMode = value),
                      ),
                      const SizedBox(width: 12),
                      Text(localization.tr('subtraction_mode')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Port settings
          NesContainer(
            label: localization.tr('port_settings'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HTTP Port
                  Text('${localization.tr('http_port')}:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _httpPortController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '8080',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // WebSocket Port
                  Text('${localization.tr('ws_port')}:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _wsPortController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '4040',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          NesButton.text(
            type: NesButtonType.success,
            text: localization.tr('save'),
            onPressed: _saveTimerSettings,
          ),
        ],
      ),
    );
  }
}

/// Вкладка настройки звуков.
class SoundsSettingsTab extends StatefulWidget {
  const SoundsSettingsTab({super.key});

  @override
  State<SoundsSettingsTab> createState() => _SoundsSettingsTabState();
}

class _SoundsSettingsTabState extends State<SoundsSettingsTab> {
  bool _soundEnabled = true;
  bool _randomSoundEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final donationService = context.read<DonationService?>();
    final soundService = context.read<SoundService?>();
    if (donationService == null) return;

    final settings = donationService.settings;
    _soundEnabled = settings.soundEnabled;
    _randomSoundEnabled = settings.randomSoundEnabled;

    // Sync with sound service if available
    if (soundService != null) {
      _soundEnabled = soundService.soundEnabled;
      _randomSoundEnabled = soundService.randomSoundEnabled;
    }

    setState(() {});
  }

  Future<void> _saveSoundSettings() async {
    final donationService = context.read<DonationService?>();
    final soundService = context.read<SoundService?>();
    if (donationService == null) return;

    final newSettings = donationService.settings.copyWith(
      soundEnabled: _soundEnabled,
      randomSoundEnabled: _randomSoundEnabled,
    );

    await donationService.updateSettings(newSettings);

    // Update sound service settings
    if (soundService != null) {
      soundService.soundEnabled = _soundEnabled;
      soundService.randomSoundEnabled = _randomSoundEnabled;
    }

    if (mounted) {
      NesSnackbar.show(
        context,
        text: context.read<LocalizationProvider>().tr('settings_saved'),
        type: NesSnackbarType.success,
      );
    }
  }

  Future<void> _refreshSounds() async {
    final soundService = context.read<SoundService?>();
    if (soundService != null) {
      await soundService.refreshSounds();
    }

    if (mounted) {
      final soundService = context.read<SoundService?>();
      final count = soundService?.soundCount ?? 0;
      NesSnackbar.show(
        context,
        text:
            '${context.read<LocalizationProvider>().tr('sounds_loaded')} ($count)',
        type: NesSnackbarType.success,
      );
    }
  }

  Future<void> _openSoundFolder() async {
    final soundService = context.read<SoundService?>();
    if (soundService != null) {
      await soundService.openSoundFolder();
    }
  }

  Future<void> _testSound() async {
    final soundService = context.read<SoundService?>();
    if (soundService != null) {
      await soundService.playSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();
    final soundService = context.watch<SoundService?>();
    final soundCount = soundService?.soundCount ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NesContainer(
            label: localization.tr('sounds'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sound enabled checkbox
                  Row(
                    children: [
                      NesCheckBox(
                        value: _soundEnabled,
                        onChange: (value) {
                          setState(() => _soundEnabled = value);
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(localization.tr('sound_notification')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Random sound checkbox
                  Row(
                    children: [
                      NesCheckBox(
                        value: _randomSoundEnabled,
                        onChange: _soundEnabled
                            ? (value) {
                                setState(() => _randomSoundEnabled = value);
                              }
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        localization.tr('random_sound'),
                        style: TextStyle(
                          color: _soundEnabled ? null : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sound files info
                  Text(
                    '${localization.tr('sound_files')}: $soundCount',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Buttons row
                  Row(
                    children: [
                      // Refresh sounds button
                      Expanded(
                        child: NesButton.text(
                          type: NesButtonType.normal,
                          text: localization.tr('refresh_sounds'),
                          onPressed: _soundEnabled ? _refreshSounds : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Open folder button
                      Expanded(
                        child: NesButton.text(
                          type: NesButtonType.normal,
                          text: localization.tr('open_folder'),
                          onPressed: _openSoundFolder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Test sound button
                  NesButton.text(
                    type: NesButtonType.normal,
                    text: localization.tr('test_sound'),
                    onPressed: _soundEnabled && soundCount > 0
                        ? _testSound
                        : null,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Place .mp3, .wav, .ogg files in the "sound" folder',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          NesButton.text(
            type: NesButtonType.success,
            text: localization.tr('save'),
            onPressed: _saveSoundSettings,
          ),
        ],
      ),
    );
  }
}

/// Вкладка управления данными (сброс статистики, настроек, логирование).
class DataSettingsTab extends StatefulWidget {
  const DataSettingsTab({super.key});

  @override
  State<DataSettingsTab> createState() => _DataSettingsTabState();
}

class _DataSettingsTabState extends State<DataSettingsTab> {
  bool _loggingEnabled = true;
  bool _enableCurrencyConversion = false;
  String _currencyConverterSource = 'er-api';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final donationService = context.read<DonationService?>();
    if (donationService != null) {
      _loggingEnabled = donationService.settings.loggingEnabled;
      _enableCurrencyConversion = donationService.settings.enableCurrencyConversion;
      _currencyConverterSource = donationService.settings.currencyConverterSource;
    }
    // Also sync with LogManager
    _loggingEnabled = LogManager.enabled;
    setState(() {});
  }

  Future<void> _saveDataSettings() async {
    final donationService = context.read<DonationService?>();
    if (donationService == null) return;

    final newSettings = donationService.settings.copyWith(
      loggingEnabled: _loggingEnabled,
      enableCurrencyConversion: _enableCurrencyConversion,
      currencyConverterSource: _currencyConverterSource,
    );

    await donationService.updateSettings(newSettings);
    LogManager.enabled = _loggingEnabled;

    if (mounted) {
      NesSnackbar.show(
        context,
        text: context.read<LocalizationProvider>().tr('saved'),
        type: NesSnackbarType.success,
      );
    }
  }

  Future<void> _resetStatistics(BuildContext context) async {
    final localization = context.read<LocalizationProvider>();

    final confirmed = await NesConfirmDialog.show(
      context: context,
      message: localization.tr('reset_statistics_confirm'),
      confirmLabel: localization.tr('reset'),
      cancelLabel: localization.tr('cancel'),
    );

    if (confirmed == true && context.mounted) {
      final donationService = context.read<DonationService?>();
      donationService?.clearStatistics();

      NesSnackbar.show(
        context,
        text: localization.tr('statistics_reset'),
        type: NesSnackbarType.success,
      );
    }
  }

  Future<void> _resetAllSettings(BuildContext context) async {
    final localization = context.read<LocalizationProvider>();

    final confirmed = await NesConfirmDialog.show(
      context: context,
      message: localization.tr('reset_all_confirm'),
      confirmLabel: localization.tr('reset'),
      cancelLabel: localization.tr('cancel'),
    );

    if (confirmed == true && context.mounted) {
      final donationService = context.read<DonationService?>();
      final timerProvider = context.read<TimerProvider?>();

      // Reset to default settings
      if (donationService != null) {
        await donationService.updateSettings(const AppSettings());
        donationService.clearStatistics();
      }

      // Reset timer
      timerProvider?.reset();

      NesSnackbar.show(
        context,
        text: localization.tr('all_reset'),
        type: NesSnackbarType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = context.watch<LocalizationProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Currency Converter settings
          NesContainer(
            label: localization.tr('currency_converter'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NesCheckBox(
                        value: _enableCurrencyConversion,
                        onChange: (value) => setState(() => _enableCurrencyConversion = value),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(localization.tr('enable_currency_conversion'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localization.tr('currency_converter_desc'),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text('${localization.tr('converter_source')}:'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _currencyConverterSource,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'cbr-xml', child: Text('ЦБ РФ (XML, по умолчанию)')),
                      DropdownMenuItem(value: 'cbr-json', child: Text('ЦБ РФ (JSON)')),
                      DropdownMenuItem(value: 'ratata', child: Text('Ratata Money (ratata.money)')),
                      DropdownMenuItem(value: 'er-api', child: Text('ER-API (open.er-api.com)')),
                      DropdownMenuItem(value: 'frankfurter', child: Text('Frankfurter (api.frankfurter.app)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _currencyConverterSource = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  NesButton.text(
                    type: NesButtonType.normal,
                    text: localization.tr('save'),
                    onPressed: _saveDataSettings,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Logging settings
          NesContainer(
            label: localization.tr('logging'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NesCheckBox(
                        value: _loggingEnabled,
                        onChange: (value) {
                          setState(() => _loggingEnabled = value);
                          LogManager.enabled = value;
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(localization.tr('logging_enabled')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localization.tr('logging_desc'),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  NesButton.text(
                    type: NesButtonType.normal,
                    text: localization.tr('save'),
                    onPressed: _saveDataSettings,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistics reset
          NesContainer(
            label: localization.tr('statistics'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.tr('reset_statistics_desc'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  NesButton.text(
                    type: NesButtonType.warning,
                    text: localization.tr('reset_statistics'),
                    onPressed: () => _resetStatistics(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Full reset
          NesContainer(
            label: localization.tr('danger_zone'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.tr('reset_all_desc'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  NesButton.text(
                    type: NesButtonType.error,
                    text: localization.tr('reset_all'),
                    onPressed: () => _resetAllSettings(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
