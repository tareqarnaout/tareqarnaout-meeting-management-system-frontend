import 'dart:convert';

class MeetingNote {
  final int id;
  final String? notes;
  final List<int> attendeeIds;
  final int recorderId;
  final DateTime date;

  const MeetingNote({
    required this.id,
    this.notes,
    required this.attendeeIds,
    required this.recorderId,
    required this.date,
  });

  factory MeetingNote.fromJson(Map<String, dynamic> json) {
    return MeetingNote(
      id: json['id'] as int,
      notes: json['notes'] as String?,
      attendeeIds: (json['attendes'] as List<dynamic>?)
              ?.map((dynamic e) => e as int)
              .toList() ??
          <int>[],
      recorderId: json['recorderId'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }

  NoteContent? get content {
    if (notes == null || notes!.isEmpty) return null;
    try {
      final Map<String, dynamic> data =
          jsonDecode(notes!) as Map<String, dynamic>;
      return NoteContent.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}

class NoteContent {
  final String title;
  final String? titleAr;
  final String? recorderName;
  final String? department;
  final String? meetingType;
  final List<NoteAttendee> attendees;
  final List<NoteAgendaItem> agenda;
  final List<NoteTranscriptEntry> transcript;
  final int durationMinutes;

  const NoteContent({
    required this.title,
    this.titleAr,
    this.recorderName,
    this.department,
    this.meetingType,
    required this.attendees,
    required this.agenda,
    required this.transcript,
    required this.durationMinutes,
  });

  factory NoteContent.fromJson(Map<String, dynamic> json) {
    return NoteContent(
      title: json['title'] as String? ?? '',
      titleAr: json['titleAr'] as String?,
      recorderName: json['recorderName'] as String?,
      department: json['department'] as String?,
      meetingType: json['meetingType'] as String?,
      attendees: (json['attendees'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  NoteAttendee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <NoteAttendee>[],
      agenda: (json['agenda'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  NoteAgendaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <NoteAgendaItem>[],
      transcript: (json['transcript'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  NoteTranscriptEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <NoteTranscriptEntry>[],
      durationMinutes: json['durationMinutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        if (titleAr != null) 'titleAr': titleAr,
        if (recorderName != null) 'recorderName': recorderName,
        if (department != null) 'department': department,
        if (meetingType != null) 'meetingType': meetingType,
        'attendees': attendees.map((NoteAttendee a) => a.toJson()).toList(),
        'agenda': agenda.map((NoteAgendaItem a) => a.toJson()).toList(),
        'transcript':
            transcript.map((NoteTranscriptEntry e) => e.toJson()).toList(),
        'durationMinutes': durationMinutes,
      };
}

class NoteAttendee {
  final String initials;
  final String name;
  final String role;
  final bool isPresent;

  const NoteAttendee({
    required this.initials,
    required this.name,
    required this.role,
    this.isPresent = true,
  });

  factory NoteAttendee.fromJson(Map<String, dynamic> json) {
    return NoteAttendee(
      initials: json['initials'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isPresent: json['isPresent'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'initials': initials,
        'name': name,
        'role': role,
        'isPresent': isPresent,
      };
}

class NoteAgendaItem {
  final int index;
  final String title;

  const NoteAgendaItem({required this.index, required this.title});

  factory NoteAgendaItem.fromJson(Map<String, dynamic> json) {
    return NoteAgendaItem(
      index: json['index'] as int? ?? 0,
      title: json['title'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'index': index,
        'title': title,
      };
}

class NoteTranscriptEntry {
  final String speaker;
  final String text;
  final String timestamp;
  final String? take;

  const NoteTranscriptEntry({
    required this.speaker,
    required this.text,
    required this.timestamp,
    this.take,
  });

  factory NoteTranscriptEntry.fromJson(Map<String, dynamic> json) {
    return NoteTranscriptEntry(
      speaker: json['speaker'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      take: json['take'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'speaker': speaker,
        'text': text,
        'timestamp': timestamp,
        if (take != null && take!.isNotEmpty) 'take': take,
      };
}
