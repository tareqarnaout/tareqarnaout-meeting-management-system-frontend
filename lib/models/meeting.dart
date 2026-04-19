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
  final List<int> requiredSignatures;
  final List<int> recipients;
  final String? sessionNumber;
  final String? decisionNumber;
  final String? councilType;
  final List<Map<String, dynamic>> relationships;

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
    this.requiredSignatures = const [],
    this.recipients = const [],
    this.sessionNumber,
    this.decisionNumber,
    this.councilType,
    this.relationships = const [],
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
      recipients: (json['recipients'] as List<dynamic>?)
              ?.map((dynamic e) => e as int)
              .toList() ??
          [],
      sessionNumber: json['sessionNumber'] as String?,
      decisionNumber: json['decisionNumber'] as String?,
      councilType: json['councilType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'meetingDate': meetingDate.toIso8601String(),
      'meetingContent': meetingContent ?? '',
      'status': status,
      'signatureNeededCount': requiredSignatures.length,
      'requiredSignatures': requiredSignatures,
      'recipients': recipients,
      if (sessionNumber != null)
        'sessionNumber': int.tryParse(sessionNumber!) ?? 0,
      if (decisionNumber != null)
        'decisionNumber': int.tryParse(decisionNumber!) ?? 0,
      if (councilType != null) 'councilType': councilType,
      if (relationships.isNotEmpty) 'relationships': relationships,
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
  final String title;
  final DateTime date;
  final String type;
  final int signatureNeededCount;
  final int status;

  ArchivedMeeting({
    required this.id,
    this.title = '',
    required this.date,
    this.type = '',
    required this.signatureNeededCount,
    required this.status,
  });

  factory ArchivedMeeting.fromJson(Map<String, dynamic> json) {
    return ArchivedMeeting(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      date: DateTime.parse(json['meetingDate'] as String),
      type: json['councilType'] as String? ?? '',
      signatureNeededCount: json['signatureNeededCount'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
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

class MeetingRelationship {
  final int meetingId;
  final String title;
  final DateTime meetingDate;
  final String type; // 'Applies', 'Change', 'Continue'

  MeetingRelationship({
    required this.meetingId,
    required this.title,
    required this.meetingDate,
    required this.type,
  });

  static const Map<int, String> _typeNames = {
    0: 'Applies',
    1: 'Change',
    2: 'Continue',
  };

  factory MeetingRelationship.fromJson(Map<String, dynamic> json) {
    final dynamic rawType = json['type'];
    final String typeName = rawType is int
        ? (_typeNames[rawType] ?? 'Applies')
        : (rawType as String? ?? 'Applies');
    return MeetingRelationship(
      meetingId: (json['relatedMeetingId'] ?? json['meetingId']) as int,
      title: json['title'] as String? ?? '',
      meetingDate: DateTime.parse(json['meetingDate'] as String),
      type: typeName,
    );
  }
}
