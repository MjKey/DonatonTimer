import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_ui_style.dart';
import '../providers/localization_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_widgets.dart';

class AppearanceSettingsTab extends StatelessWidget {
  const AppearanceSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final localization = context.watch<LocalizationProvider>();
    return SingleChildScrollView(
      child: AppPanel(
        label: localization.tr('appearance'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<AppUiStyle>(
                key: const ValueKey('app-ui-style'),
                initialValue: theme.uiStyle,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: localization.tr('app_ui_style'),
                ),
                items: [
                  for (final style in AppUiStyle.values)
                    DropdownMenuItem(
                      value: style,
                      child: Text(
                        localization.tr('app_ui_style_${style.name}'),
                      ),
                    ),
                ],
                onChanged: (style) {
                  if (style != null) theme.setUiStyle(style);
                },
              ),
              const SizedBox(height: 16),
              Text(localization.tr('app_ui_style_description')),
              const SizedBox(height: 24),
              DropdownButtonFormField<ThemeMode>(
                key: const ValueKey('app-theme-mode'),
                initialValue: theme.themeMode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: localization.tr('app_theme_mode'),
                ),
                items: [
                  for (final mode in ThemeMode.values)
                    DropdownMenuItem(
                      value: mode,
                      child: Text(localization.tr('app_theme_${mode.name}')),
                    ),
                ],
                onChanged: (mode) {
                  if (mode != null) theme.setThemeMode(mode);
                },
              ),
              const SizedBox(height: 16),
              Text(localization.tr('appearance_saved_hint')),
            ],
          ),
        ),
      ),
    );
  }
}
