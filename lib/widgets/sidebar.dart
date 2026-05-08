import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_theme.dart';
import '../constants/api_constants.dart';
import '../services/auth_service.dart';

class SidebarItem {
  final String label;
  final IconData icon;
  final String route;
  final List<int>? allowedRoles;

  const SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    this.allowedRoles,
  });
}

class Sidebar extends StatefulWidget {
  final String currentRoute;

  const Sidebar({super.key, required this.currentRoute});

  static const List<SidebarItem> items = [
    SidebarItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/'),
    SidebarItem(
        label: 'Create Meeting', icon: Icons.add_circle_outline, route: '/create'),
    SidebarItem(
        label: 'Review & Sign', icon: Icons.draw_outlined, route: '/review'),
    SidebarItem(
        label: 'Meetings Archive',
        icon: Icons.archive_outlined,
        route: '/archive'),
    SidebarItem(
        label: 'User Management',
        icon: Icons.admin_panel_settings_outlined,
        route: '/users',
        allowedRoles: [UserRole.admin]),
    SidebarItem(
        label: 'Minute Taker',
        icon: Icons.edit_note_outlined,
        route: '/minute',
        allowedRoles: [UserRole.minuteTaker]),
    SidebarItem(
        label: 'Secretary Inbox',
        icon: Icons.inbox_outlined,
        route: '/secretary',
        allowedRoles: [UserRole.secretary]),
  ];

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int? _roleId;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final int? role = await AuthService().getRoleId();
    if (mounted) setState(() => _roleId = role);
  }

  @override
  Widget build(BuildContext context) {
    final List<SidebarItem> visibleItems = Sidebar.items
        .where((SidebarItem item) {
          if (_roleId == UserRole.admin) return true;
          return item.allowedRoles == null ||
              (_roleId != null && item.allowedRoles!.contains(_roleId));
        })
        .toList();

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          // Logo area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Image.asset(
                  'assets/psutLogo.png',
                  width: 36,
                  height: 36,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post-Meeting',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Management System',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.border.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 12),
          // Nav items
          ...visibleItems.map((SidebarItem item) {
            final bool isActive = widget.currentRoute == item.route;
            return _NavItem(item: item, isActive: isActive);
          }),
          const Spacer(),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final SidebarItem item;
  final bool isActive;

  const _NavItem({required this.item, required this.isActive});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.isActive;
    final double offset = _isHovered && !isActive ? 6.0 : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(widget.item.route),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: 14 + offset,
                right: 14,
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                color: isActive ? AppColors.sidebarActiveItem : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.item.icon,
                    size: 18,
                    color: isActive
                        ? AppColors.sidebarActiveText
                        : AppColors.sidebarText,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.sidebarActiveText
                          : AppColors.sidebarText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
