import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class _UserData {
  final String initials;
  final String name;
  final String nameAr;
  final String email;
  final String role;
  final String department;
  final bool isActive;
  final bool canSign;
  final int meetingsSigned;
  final String lastLogin;
  final Color avatarColor;

  const _UserData({
    required this.initials,
    required this.name,
    required this.nameAr,
    required this.email,
    required this.role,
    required this.department,
    this.isActive = true,
    this.canSign = true,
    required this.meetingsSigned,
    required this.lastLogin,
    required this.avatarColor,
  });
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'All Roles';
  String _statusFilter = 'All Statuses';

  static const List<_UserData> _allUsers = [
    _UserData(
      initials: 'DQ',
      name: 'Dr. Abdulla Qusef',
      nameAr: 'د. عبدالله قصف',
      email: 'a.qusef@psut.edu.jo',
      role: 'Admin',
      department: 'Computer Science',
      meetingsSigned: 47,
      lastLogin: '2026-04-17 09:30',
      avatarColor: Color(0xFFE57373),
    ),
    _UserData(
      initials: 'DA',
      name: 'Dr. Ahmad Al-Ali',
      nameAr: 'د. أحمد العلي',
      email: 'a.alali@psut.edu.jo',
      role: 'Professor',
      department: 'Computer Science',
      meetingsSigned: 35,
      lastLogin: '2026-04-16 14:22',
      avatarColor: Color(0xFF2E7D9E),
    ),
    _UserData(
      initials: 'DA',
      name: 'Dr. Mohammad Al-Hassan',
      nameAr: 'د. محمد الحسن',
      email: 'm.alhassan@psut.edu.jo',
      role: 'Professor',
      department: 'Computer Science',
      meetingsSigned: 42,
      lastLogin: '2026-04-15 11:05',
      avatarColor: Color(0xFF2E7D9E),
    ),
    _UserData(
      initials: 'DA',
      name: 'Dr. Fatima Al-Khaldi',
      nameAr: 'د. فاطمة الخالدي',
      email: 'f.alkhaldi@psut.edu.jo',
      role: 'Professor',
      department: 'Computer Science',
      meetingsSigned: 28,
      lastLogin: '2026-04-17 08:10',
      avatarColor: Color(0xFF2E7D9E),
    ),
    _UserData(
      initials: 'DA',
      name: 'Dr. Khalid Al-Salem',
      nameAr: 'د. خالد السالم',
      email: 'k.alsalem@psut.edu.jo',
      role: 'Professor',
      department: 'Computer Science',
      meetingsSigned: 31,
      lastLogin: '2026-04-14 16:45',
      avatarColor: Color(0xFF2E7D9E),
    ),
    _UserData(
      initials: 'DA',
      name: 'Dr. Nora Al-Marri',
      nameAr: 'د. نورة المري',
      email: 'n.almarri@psut.edu.jo',
      role: 'Professor',
      department: 'Computer Science',
      meetingsSigned: 39,
      lastLogin: '2026-04-13 10:30',
      avatarColor: Color(0xFF2E7D9E),
    ),
    _UserData(
      initials: 'DA',
      name: 'Dr. Youssef Al-Nasser',
      nameAr: 'د. يوسف الناصر',
      email: 'y.alnasser@psut.edu.jo',
      role: 'Professor',
      department: 'Computer Science',
      isActive: false,
      canSign: false,
      meetingsSigned: 18,
      lastLogin: '2026-03-20 09:15',
      avatarColor: Color(0xFF2E7D9E),
    ),
    _UserData(
      initials: 'SA',
      name: 'Sara Al-Rashid',
      nameAr: 'سارة الراشد',
      email: 's.alrashid@psut.edu.jo',
      role: 'Secretary',
      department: 'Computer Science',
      meetingsSigned: 22,
      lastLogin: '2026-04-17 07:50',
      avatarColor: Color(0xFF8B5CF6),
    ),
    _UserData(
      initials: 'LK',
      name: 'Layla Al-Khatib',
      nameAr: 'ليلى الخطيب',
      email: 'l.alkhatib@psut.edu.jo',
      role: 'Minute Taker',
      department: 'Computer Science',
      meetingsSigned: 15,
      lastLogin: '2026-04-16 09:00',
      avatarColor: Color(0xFFF59E0B),
    ),
    _UserData(
      initials: 'OT',
      name: 'Omar Al-Tamimi',
      nameAr: 'عمر التميمي',
      email: 'o.altamimi@psut.edu.jo',
      role: 'Staff Member',
      department: 'Computer Science',
      meetingsSigned: 8,
      lastLogin: '2026-04-10 13:20',
      avatarColor: Color(0xFF10B981),
    ),
  ];

  List<_UserData> get _filteredUsers {
    return _allUsers.where((_UserData u) {
      final String query = _searchController.text.toLowerCase();
      if (query.isNotEmpty &&
          !u.name.toLowerCase().contains(query) &&
          !u.email.toLowerCase().contains(query) &&
          !u.department.toLowerCase().contains(query)) {
        return false;
      }
      if (_roleFilter != 'All Roles' && u.role != _roleFilter) return false;
      if (_statusFilter == 'Active' && !u.isActive) return false;
      if (_statusFilter == 'Inactive' && u.isActive) return false;
      return true;
    }).toList();
  }

  int get _activeCount => _allUsers.where((_UserData u) => u.isActive).length;
  int get _inactiveCount => _allUsers.where((_UserData u) => !u.isActive).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_UserData> users = _filteredUsers;

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
                  onPressed: () {},
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
                _buildStatCard('Total Users', '${_allUsers.length}',
                    AppColors.primaryBlue),
                const SizedBox(width: 14),
                _buildStatCard(
                    'Active', '$_activeCount', AppColors.statusApproved),
                const SizedBox(width: 14),
                _buildStatCard(
                    'Inactive', '$_inactiveCount', AppColors.textMuted),
                const SizedBox(width: 14),
                _buildStatCard('Pending', '1', AppColors.statusPending),
              ]
                  .map((Widget w) =>
                      w is SizedBox ? w : Expanded(child: w))
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
                        hint: 'Search by name, email, or department...',
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
                      'Professor',
                      'Secretary',
                      'Staff Member',
                      'Minute Taker',
                    ],
                    onChanged: (String? v) =>
                        setState(() => _roleFilter = v ?? 'All Roles'),
                  ),
                  const SizedBox(width: 10),
                  _buildDropdown(
                    value: _statusFilter,
                    items: const ['All Statuses', 'Active', 'Inactive'],
                    onChanged: (String? v) =>
                        setState(() => _statusFilter = v ?? 'All Statuses'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Count label
            Text(
              'Showing ${users.length} of ${_allUsers.length} users',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            // Table
            Container(
              decoration: AppDecorations.cardWithBorder,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Table header
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: const [
                        Expanded(flex: 5, child: _HeaderCell('User')),
                        Expanded(flex: 3, child: _HeaderCell('Role')),
                        Expanded(flex: 3, child: _HeaderCell('Department')),
                        Expanded(flex: 2, child: _HeaderCell('Status')),
                        Expanded(flex: 2, child: _HeaderCell('Can Sign')),
                        Expanded(
                            flex: 3,
                            child: _HeaderCell('Meetings Signed')),
                        Expanded(flex: 3, child: _HeaderCell('Last Login')),
                        Expanded(flex: 2, child: _HeaderCell('Actions')),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  // Table rows
                  ...users.map((_UserData user) => _buildUserRow(user)),
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

  Widget _buildUserRow(_UserData user) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // User cell
          Expanded(
            flex: 5,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: user.avatarColor,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
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
                          const SizedBox(width: 6),
                          Text(
                            user.nameAr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Role
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RoleBadge(role: user.role),
            ),
          ),
          // Department
          Expanded(
            flex: 3,
            child: Text(user.department, style: AppTextStyles.bodySmall),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.isActive
                        ? AppColors.statusApproved
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: user.isActive
                        ? AppColors.statusApproved
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Can Sign toggle
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Switch(
                value: user.canSign,
                onChanged: (_) {},
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.textPrimary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.border,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          // Meetings Signed
          Expanded(
            flex: 3,
            child: Text(
              '${user.meetingsSigned}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Last Login
          Expanded(
            flex: 3,
            child: Text(user.lastLogin, style: AppTextStyles.bodySmall),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _actionButton(Icons.edit_outlined, () {}),
                const SizedBox(width: 4),
                _actionButton(Icons.more_vert, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
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
      case 'Professor':
        color = AppColors.primaryTeal;
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
