// lib/models/history_entry.dart
//
// Represents a single completed cycle: how long the lens was worn, how long
// the most recent cleaning took, and the turbidity reading recorded at that
// time. Persisted locally via HistoryService (backed by shared_preferences,
// stored as a JSON list).

class HistoryEntry {
  final String id;
  final DateTime date;
  final Duration wearDuration;
  final Duration cleaningDuration;
  final int turbidityValue;

  const HistoryEntry({
    required this.id,
    required this.date,
    required this.wearDuration,
    required this.cleaningDuration,
    required this.turbidityValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'wearSeconds': wearDuration.inSeconds,
        'cleaningSeconds': cleaningDuration.inSeconds,
        'turbidityValue': turbidityValue,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        wearDuration: Duration(seconds: json['wearSeconds'] as int),
        cleaningDuration: Duration(seconds: json['cleaningSeconds'] as int),
        turbidityValue: json['turbidityValue'] as int,
      );

  /// Formats wear duration as "07 hr 12 min" matching the spec's example.
  String get formattedWearDuration {
    final hours = wearDuration.inHours.toString().padLeft(2, '0');
    final minutes = (wearDuration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours hr $minutes min';
  }

  /// Formats cleaning duration as "30 sec" for short durations, or
  /// "1 min 05 sec" if it ever exceeds a minute.
  String get formattedCleaningDuration {
    if (cleaningDuration.inMinutes < 1) {
      return '${cleaningDuration.inSeconds} sec';
    }
    final minutes = cleaningDuration.inMinutes;
    final seconds = (cleaningDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes min $seconds sec';
  }
}
