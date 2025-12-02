/// Конфигурация подключения к донат-сервису.
class ServiceConfig {
  final String serviceName;
  final bool enabled;
  final Map<String, String> credentials;

  const ServiceConfig({
    required this.serviceName,
    this.enabled = false,
    this.credentials = const {},
  });

  /// Creates a copy with updated values.
  ServiceConfig copyWith({
    String? serviceName,
    bool? enabled,
    Map<String, String>? credentials,
  }) {
    return ServiceConfig(
      serviceName: serviceName ?? this.serviceName,
      enabled: enabled ?? this.enabled,
      credentials: credentials ?? this.credentials,
    );
  }

  /// Creates a ServiceConfig from a JSON map.
  factory ServiceConfig.fromJson(Map<String, dynamic> json) {
    return ServiceConfig(
      serviceName: json['serviceName'] as String,
      enabled: json['enabled'] as bool? ?? false,
      credentials: Map<String, String>.from(json['credentials'] as Map? ?? {}),
    );
  }

  /// Converts the ServiceConfig to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'serviceName': serviceName,
      'enabled': enabled,
      'credentials': credentials,
    };
  }

  /// Gets a credential value by key.
  String? getCredential(String key) => credentials[key];

  /// Checks if all required credentials are present.
  bool hasCredentials(List<String> requiredKeys) {
    return requiredKeys.every(
      (key) => credentials.containsKey(key) && credentials[key]!.isNotEmpty,
    );
  }

  @override
  String toString() {
    return 'ServiceConfig(service: $serviceName, enabled: $enabled)';
  }
}
