import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../constants/app_theme.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();

  String _roleFilter = 'All Roles';
  List<AppUser> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final List<AppUser> users = await _userService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users';
        _isLoading = false;
      });
    }
  }

  List<AppUser> get _filteredUsers {
    return _users.where((AppUser u) {
      final String query = _searchController.text.toLowerCase();
      if (query.isNotEmpty &&
          !u.name.toLowerCase().contains(query) &&
          !u.email.toLowerCase().contains(query)) {
        return false;
      }
      if (_roleFilter != 'All Roles' &&
          UserRole.label(u.roleId) != _roleFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showAddUserDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    int selectedRoleId = UserRole.staffMember;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Text('Add New User', style: AppTextStyles.heading2),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: AppDecorations.inputDecoration(
                          'Full Name',
                          hint: 'Enter full name',
                        ),
                        validator: (String? v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: AppDecorations.inputDecoration(
                          'Email',
                          hint: 'Enter email address',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (String? v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: selectedRoleId,
                        decoration: AppDecorations.inputDecoration('Role'),
                        items: const [
                          DropdownMenuItem(
                              value: UserRole.admin, child: Text('Admin')),
                          DropdownMenuItem(
                              value: UserRole.secretary,
                              child: Text('Secretary')),
                          DropdownMenuItem(
                              value: UserRole.departmentHead,
                              child: Text('Department Head / Dean')),
                          DropdownMenuItem(
                              value: UserRole.staffMember,
                              child: Text('Staff Member')),
                          DropdownMenuItem(
                              value: UserRole.minuteTaker,
                              child: Text('Minute Taker')),
                        ],
                        onChanged: (int? v) {
                          if (v != null) {
                            setDialogState(() => selectedRoleId = v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    await _addUser(
                      nameController.text.trim(),
                      emailController.text.trim(),
                      selectedRoleId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addUser(String name, String email, int roleId) async {
    try {
      final bool success = await _userService.addUser(
        fullName: name,
        email: email,
        roleId: roleId,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User added successfully'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while adding the user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> users = _filteredUsers;

    return Container(
      color: AppColors.pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('User Management', style: AppTextStyles.heading1),
                      SizedBox(height: 4),
                      Text(
                        'Manage faculty members, staff, and system access permissions',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats cards
            Row(
              children: [
                _buildStatCard(
                    'Total Users', '${_users.length}', AppColors.primaryBlue),
                const SizedBox(width: 14),
                _buildStatCard(
                    'Roles',
                    '${_users.map((AppUser u) => u.roleId).toSet().length}',
                    AppColors.statusApproved),
              ]
                  .map((Widget w) => w is SizedBox ? w : Expanded(child: w))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Search + filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.cardWithBorder,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: AppDecorations.inputDecoration(
                        '',
                        hint: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColors.textMuted),
                      ).copyWith(labelText: null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildDropdown(
                    value: _roleFilter,
                    items: const [
                      'All Roles',
                      'Admin',
                      'Secretary',
                      'Department Head / Dean',
                      'Staff Member',
                      'Minute Taker',
                    ],
                    onChanged: (String? v) =>
                        setState(() => _roleFilter = v ?? 'All Roles'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Count label
            Text(
              'Showing ${users.length} of ${_users.length} users',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            // Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Table
              Container(
                decoration: AppDecorations.cardWithBorder,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: const [
                          Expanded(flex: 5, child: _HeaderCell('User')),
                          Expanded(flex: 3, child: _HeaderCell('Role')),
                          Expanded(flex: 3, child: _HeaderCell('Email')),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    if (users.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No users found',
                            style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      ...users.map((AppUser user) => _buildUserRow(user)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.textMuted),
          items: items
              .map((String s) =>
                  DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUserRow(AppUser user) {
    final String initials = user.name.isNotEmpty
        ? user.name
            .split(' ')
            .where((String s) => s.isNotEmpty)
            .take(2)
            .map((String s) => s[0].toUpperCase())
            .join()
        : '?';
    final String roleName = UserRole.label(user.roleId);

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _avatarColor(user.roleId),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RoleBadge(role: roleName),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.email,
              style: AppTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _avatarColor(int roleId) {
    switch (roleId) {
      case UserRole.admin:
        return const Color(0xFFE57373);
      case UserRole.secretary:
        return const Color(0xFF8B5CF6);
      case UserRole.minuteTaker:
        return const Color(0xFFF59E0B);
      case UserRole.staffMember:
        return const Color(0xFF10B981);
      case UserRole.departmentHead:
        return const Color(0xFF2E7D9E);
      default:
        return AppColors.textMuted;
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (role) {
      case 'Admin':
        color = const Color(0xFFEF4444);
        icon = Icons.shield_outlined;
        break;
      case 'Department Head / Dean':
        color = const Color(0xFF2E7D9E);
        icon = Icons.person_outline;
        break;
      case 'Secretary':
        color = const Color(0xFF8B5CF6);
        icon = Icons.edit_note;
        break;
      case 'Minute Taker':
        color = const Color(0xFFF59E0B);
        icon = Icons.note_alt_outlined;
        break;
      case 'Staff Member':
        color = const Color(0xFF10B981);
        icon = Icons.badge_outlined;
        break;
      default:
        color = AppColors.textMuted;
        icon = Icons.person_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
