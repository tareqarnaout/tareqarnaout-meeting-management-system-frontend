class ApiConstants {
  static const String baseUrl = 'post-meeting-hheug7c7hqabhmbz.canadacentral-01.azurewebsites.net/api';
  // http://localhost:5065
// post-meeting-hheug7c7hqabhmbz.canadacentral-01.azurewebsites.net
}

class MeetingStatus {
  static const int draft = 0;
  static const int pendingApproval = 1;
  static const int finalized = 2;

  static String label(int status) {
    switch (status) {
      case draft:
        return 'Draft';
      case pendingApproval:
        return 'Pending Approval';
      case finalized:
        return 'Finalized';
      default:
        return 'Unknown';
    }
  }
}

class UserRole {
  static const int admin = 1;
  static const int secretary = 2;
  static const int departmentHead = 3;
  static const int staffMember = 4;
  static const int minuteTaker = 5;

  static String label(int roleId) {
    switch (roleId) {
      case admin:
        return 'Admin';
      case secretary:
        return 'Secretary';
      case departmentHead:
        return 'Department Head';
      case staffMember:
        return 'Staff Member';
      case minuteTaker:
        return 'Minute Taker';
      default:
        return 'Unknown';
    }
  }
}

class CouncilType {
  static const int department = 0;
  static const int faculty = 1;
  static const int deans = 2;
  static const int university = 3;

  static const Map<int, String> _labels = {
    department: 'مجلس القسم',
    faculty: 'مجلس الكلية',
    deans: 'مجلس العمداء',
    university: 'مجلس الجامعة',
  };

  static String label(int value) => _labels[value] ?? 'مجلس القسم';

  static int valueFromLabel(String label) {
    final MapEntry<int, String> match = _labels.entries.firstWhere(
      (MapEntry<int, String> entry) => entry.value == label,
      orElse: () => const MapEntry<int, String>(department, 'مجلس القسم'),
    );
    return match.key;
  }

  static String? fromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return label(value);
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }
}
