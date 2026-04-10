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
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roleId: json['roleId'] as int? ?? 4,
      department: json['department'] as String?,
    );
  }
}
