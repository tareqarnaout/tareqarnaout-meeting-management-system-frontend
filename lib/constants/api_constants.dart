class ApiConstants {
  static const String baseUrl = 'http://localhost:5065/api';
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
