import 'service_config.dart';

/// Настройки приложения включая конфигурации сервисов.
class AppSettings {
  final double minutesPerAmount;
  final int httpPort;
  final int wsPort;
  final bool soundEnabled;
  final bool randomSoundEnabled;
  final bool loggingEnabled;
  final String theme;
  final String language;
  final Map<String, ServiceConfig> serviceConfigs;

  const AppSettings({
    this.minutesPerAmount = 600.0,
    this.httpPort = 8080,
    this.wsPort = 4040,
    this.soundEnabled = true,
    this.randomSoundEnabled = false,
    this.loggingEnabled = true,
    this.theme = 'system',
    this.language = 'ru',
    this.serviceConfigs = const {},
  });

  /// Creates a copy with updated values.
  AppSettings copyWith({
    double? minutesPerAmount,
    int? httpPort,
    int? wsPort,
    bool? soundEnabled,
    bool? randomSoundEnabled,
    bool? loggingEnabled,
    String? theme,
    String? language,
    Map<String, ServiceConfig>? serviceConfigs,
  }) {
    return AppSettings(
      minutesPerAmount: minutesPerAmount ?? this.minutesPerAmount,
      httpPort: httpPort ?? this.httpPort,
      wsPort: wsPort ?? this.wsPort,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      randomSoundEnabled: randomSoundEnabled ?? this.randomSoundEnabled,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      serviceConfigs: serviceConfigs ?? this.serviceConfigs,
    );
  }

  /// Gets a service configuration by name.
  ServiceConfig? getServiceConfig(String serviceName) {
    return serviceConfigs[serviceName];
  }

  /// Updates a service configuration.
  AppSettings updateServiceConfig(ServiceConfig config) {
    final newConfigs = Map<String, ServiceConfig>.from(serviceConfigs);
    newConfigs[config.serviceName] = config;
    return copyWith(serviceConfigs: newConfigs);
  }

  /// Creates AppSettings from a JSON map.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final serviceConfigsJson = json['serviceConfigs'] as Map<String, dynamic>?;
    final serviceConfigs = <String, ServiceConfig>{};
    
    if (serviceConfigsJson != null) {
      for (final entry in serviceConfigsJson.entries) {
        serviceConfigs[entry.key] = ServiceConfig.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return AppSettings(
      minutesPerAmount: (json['minutesPerAmount'] as num?)?.toDouble() ?? 600.0,
      httpPort: json['httpPort'] as int? ?? 8080,
      wsPort: json['wsPort'] as int? ?? 4040,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      randomSoundEnabled: json['randomSoundEnabled'] as bool? ?? false,
      loggingEnabled: json['loggingEnabled'] as bool? ?? true,
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'ru',
      serviceConfigs: serviceConfigs,
    );
  }

  /// Converts the AppSettings to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'minutesPerAmount': minutesPerAmount,
      'httpPort': httpPort,
      'wsPort': wsPort,
      'soundEnabled': soundEnabled,
      'randomSoundEnabled': randomSoundEnabled,
      'loggingEnabled': loggingEnabled,
      'theme': theme,
      'language': language,
      'serviceConfigs': serviceConfigs.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  /// Default settings.
  static const AppSettings defaults = AppSettings();

  @override
  String toString() {
    return 'AppSettings(rate: $minutesPerAmount, http: $httpPort, ws: $wsPort, lang: $language)';
  }
}
