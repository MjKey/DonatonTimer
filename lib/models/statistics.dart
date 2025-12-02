import 'donation_record.dart';

/// Статистика донатов и топ донатеров.
class Statistics {
  final List<DonationRecord> recentDonations;
  final Map<String, int> topDonators;

  const Statistics({
    this.recentDonations = const [],
    this.topDonators = const {},
  });

  /// Creates a copy with updated values.
  Statistics copyWith({
    List<DonationRecord>? recentDonations,
    Map<String, int>? topDonators,
  }) {
    return Statistics(
      recentDonations: recentDonations ?? this.recentDonations,
      topDonators: topDonators ?? this.topDonators,
    );
  }

  /// Adds a new donation record and updates top donators.
  Statistics addDonation(DonationRecord record, {int maxRecent = 50}) {
    final newRecent = [record, ...recentDonations];
    if (newRecent.length > maxRecent) {
      newRecent.removeRange(maxRecent, newRecent.length);
    }

    final newTopDonators = Map<String, int>.from(topDonators);
    newTopDonators[record.username] =
        (newTopDonators[record.username] ?? 0) + record.minutesAdded;

    return Statistics(
      recentDonations: newRecent,
      topDonators: newTopDonators,
    );
  }

  /// Gets sorted top donators list.
  List<MapEntry<String, int>> getSortedTopDonators({int limit = 10}) {
    final sorted = topDonators.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Creates Statistics from a JSON map.
  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      recentDonations: (json['recentDonations'] as List?)
              ?.map((e) => DonationRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topDonators: Map<String, int>.from(json['topDonators'] as Map? ?? {}),
    );
  }

  /// Converts the Statistics to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'recentDonations': recentDonations.map((e) => e.toJson()).toList(),
      'topDonators': topDonators,
    };
  }

  /// Clears all statistics.
  Statistics clear() {
    return const Statistics();
  }

  @override
  String toString() {
    return 'Statistics(recent: ${recentDonations.length}, topDonators: ${topDonators.length})';
  }
}
