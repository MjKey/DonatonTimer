/// Запись обработанного доната для статистики.
class DonationRecord {
  final String username;
  final int minutesAdded;
  final DateTime timestamp;
  final String serviceName;
  final double amount;
  final String currency;

  const DonationRecord({
    required this.username,
    required this.minutesAdded,
    required this.timestamp,
    required this.serviceName,
    required this.amount,
    required this.currency,
  });

  /// Creates a DonationRecord from a JSON map.
  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    return DonationRecord(
      username: json['username'] as String,
      minutesAdded: json['minutesAdded'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      serviceName: json['serviceName'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'RUB',
    );
  }

  /// Converts the DonationRecord to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'minutesAdded': minutesAdded,
      'timestamp': timestamp.toIso8601String(),
      'serviceName': serviceName,
      'amount': amount,
      'currency': currency,
    };
  }

  @override
  String toString() {
    return 'DonationRecord(user: $username, minutes: $minutesAdded, service: $serviceName)';
  }
}
