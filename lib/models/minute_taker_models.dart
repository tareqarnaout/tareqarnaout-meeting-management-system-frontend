class Attendee {
  final int? id;
  final String initials;
  final String name;
  final String role;
  final bool isPresent;

  const Attendee({
    this.id,
    required this.initials,
    required this.name,
    required this.role,
    required this.isPresent,
  });

  Attendee copyWith({
    int? id,
    String? initials,
    String? name,
    String? role,
    bool? isPresent,
  }) {
    return Attendee(
      id: id ?? this.id,
      initials: initials ?? this.initials,
      name: name ?? this.name,
      role: role ?? this.role,
      isPresent: isPresent ?? this.isPresent,
    );
  }

  static String initialsFrom(String fullName) {
    final List<String> parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory Attendee.fromJson(Map<String, dynamic> json) {
    final String name = (json['fullName'] ?? json['name'] ?? json['userName'] ?? 'Unknown').toString();
    final dynamic roleValue = json['roleId'] ?? json['role'];
    String role;
    if (roleValue is int) {
      role = _roleLabelFromId(roleValue);
    } else {
      role = roleValue?.toString() ?? 'Staff Member';
    }

    return Attendee(
      id: json['id'] as int?,
      initials: initialsFrom(name),
      name: name,
      role: role,
      isPresent: false,
    );
  }

  static String _roleLabelFromId(int roleId) {
    switch (roleId) {
      case 1: return 'Admin';
      case 2: return 'Secretary';
      case 3: return 'Department Head / Dean';
      case 4: return 'Staff Member';
      case 5: return 'Minute Taker';
      default: return 'Staff Member';
    }
  }
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
  final String take;

  const TranscriptEntry({
    required this.id,
    required this.text,
    required this.speaker,
    required this.timestamp,
    this.take = '',
  });

  TranscriptEntry copyWith({
    String? text,
    String? speaker,
    DateTime? timestamp,
    String? take,
  }) {
    return TranscriptEntry(
      id: id,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      timestamp: timestamp ?? this.timestamp,
      take: take ?? this.take,
    );
  }
}
