class Attendee {
  final String initials;
  final String name;
  final String role;
  final bool isPresent;

  const Attendee({
    required this.initials,
    required this.name,
    required this.role,
    required this.isPresent,
  });
}

class AgendaItem {
  final int index;
  final String title;
  final bool isActive;

  const AgendaItem({
    required this.index,
    required this.title,
    required this.isActive,
  });
}

class HandoffStat {
  final String label;
  final String value;
  final bool highlight;

  const HandoffStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

enum RecordingState {
  idle,
  recording,
  paused,
}

class TranscriptEntry {
  final String id;
  final String text;
  final String speaker;
  final DateTime timestamp;

  const TranscriptEntry({
    required this.id,
    required this.text,
    required this.speaker,
    required this.timestamp,
  });

  TranscriptEntry copyWith({
    String? text,
    String? speaker,
    DateTime? timestamp,
  }) {
    return TranscriptEntry(
      id: id,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
