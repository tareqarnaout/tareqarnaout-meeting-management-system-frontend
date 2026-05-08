class AppUser {
  final int? id;
  final String name;
  final String email;
  final int roleId;
  final String? department;

  AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.roleId,
    this.department,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int?,
      name: (json['fullName'] ?? json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      roleId: (json['roleID'] ?? json['RoleID'] ?? json['roleId'] ?? 4) as int,
      department: json['department'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': name,
      'email': email,
      'RoleID': roleId,
    };
  }
}
