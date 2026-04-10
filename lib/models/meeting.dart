class Meeting {
  final int? id;
  final String title;
  final DateTime meetingDate;
  final String? type;
  final String? agenda;
  final String? meetingContent;
  final int status;
  final String? createdBy;
  final DateTime? lastModified;
  final List<String> attendees;
  final List<Signatory> signatories;
  final List<MeetingConnection> connections;

  Meeting({
    this.id,
    required this.title,
    required this.meetingDate,
    this.type,
    this.agenda,
    this.meetingContent,
    this.status = 0,
    this.createdBy,
    this.lastModified,
    this.attendees = const [],
    this.signatories = const [],
    this.connections = const [],
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      meetingDate: DateTime.parse(json['meetingDate'] as String),
      type: json['type'] as String?,
      agenda: json['agenda'] as String?,
      meetingContent: json['meetingContent'] as String?,
      status: json['status'] as int? ?? 0,
      createdBy: json['createdBy'] as String?,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      attendees: (json['attendees'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          [],
      signatories: (json['signatories'] as List<dynamic>?)
              ?.map((dynamic e) => Signatory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      connections: (json['connections'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  MeetingConnection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'meetingDate': meetingDate.toIso8601String(),
      if (type != null) 'type': type,
      'agenda': agenda ?? '',
      'meetingContent': meetingContent ?? '',
      'status': status,
      if (attendees.isNotEmpty) 'attendees': attendees,
    };
  }
}

class Signatory {
  final int? userId;
  final String name;
  final String? department;
  final bool hasSigned;
  final DateTime? signedAt;

  Signatory({
    this.userId,
    required this.name,
    this.department,
    this.hasSigned = false,
    this.signedAt,
  });

  factory Signatory.fromJson(Map<String, dynamic> json) {
    return Signatory(
      userId: json['userId'] as int?,
      name: json['name'] as String? ?? '',
      department: json['department'] as String?,
      hasSigned: json['hasSigned'] as bool? ?? false,
      signedAt: json['signedAt'] != null
          ? DateTime.parse(json['signedAt'] as String)
          : null,
    );
  }
}

class ArchivedMeeting {
  final int id;
  final DateTime date;
  final int signatureNeededCount;
  final int status;
  final String createdBy;

  ArchivedMeeting({
    required this.id,
    required this.date,
    required this.signatureNeededCount,
    required this.status,
    required this.createdBy,
  });

  factory ArchivedMeeting.fromJson(Map<String, dynamic> json) {
    return ArchivedMeeting(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      signatureNeededCount: json['signatureNeededCount'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
      createdBy: json['createdBy'] as String? ?? '',
    );
  }
}

class MeetingConnection {
  final int? meetingId;
  final String? meetingTitle;
  final String relationshipType;

  MeetingConnection({
    this.meetingId,
    this.meetingTitle,
    required this.relationshipType,
  });

  factory MeetingConnection.fromJson(Map<String, dynamic> json) {
    return MeetingConnection(
      meetingId: json['meetingId'] as int?,
      meetingTitle: json['meetingTitle'] as String?,
      relationshipType: json['relationshipType'] as String? ?? '',
    );
  }
}
