/// Представляет донат, полученный от любого донат-сервиса.
class Donation {
  final String id;
  final String serviceName;
  final String username;
  final double amount;
  final String currency;
  final String? message;
  final DateTime timestamp;

  const Donation({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.amount,
    required this.currency,
    this.message,
    required this.timestamp,
  });

  /// Calculates the number of seconds to add based on the donation amount and rate.
  /// Rate means: [rate] RUB = 60 minutes
  /// Formula: seconds = (amount / rate) * 60 minutes * 60 seconds = (amount / rate) * 3600
  int calculateSeconds(double rate) {
    if (rate <= 0) return 0;
    return ((amount / rate) * 3600).round();
  }

  /// Creates a Donation from a JSON map.
  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as String,
      serviceName: json['serviceName'] as String,
      username: json['username'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      message: json['message'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Converts the Donation to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceName': serviceName,
      'username': username,
      'amount': amount,
      'currency': currency,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Donation(id: $id, service: $serviceName, user: $username, amount: $amount $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Donation && other.id == id && other.serviceName == serviceName;
  }

  @override
  int get hashCode => id.hashCode ^ serviceName.hashCode;
}
