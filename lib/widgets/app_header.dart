import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../constants/app_theme.dart';
import '../models/meeting.dart';
import '../services/auth_service.dart';
import '../services/meeting_service.dart';

class AppHeader extends StatefulWidget {
  final bool showMenuButton;

  const AppHeader({super.key, this.showMenuButton = false});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String _userName = '';
  String _roleName = '';
  List<Meeting> _unsignedMeetings = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadUnsignedMeetings();
  }

  Future<void> _loadUserInfo() async {
    final AuthService auth = AuthService();
    final String? name = await auth.getUserName();
    final int? roleId = await auth.getRoleId();
    if (mounted) {
      setState(() {
        _userName = name ?? 'User';
        _roleName = _roleLabel(roleId);
      });
    }
  }

  Future<void> _loadUnsignedMeetings() async {
    final List<Meeting> pending = await MeetingService().getPendingSignMeetings();
    if (mounted) {
      setState(() {
        _unsignedMeetings = pending
            .where((Meeting m) =>
                m.signatureStatus == MeetingStatus.pendingApproval)
            .toList();
      });
    }
  }

  String _roleLabel(int? roleId) {
    switch (roleId) {
      case 1:
        return 'Admin';
      case 2:
        return 'Secretary';
      case 3:
        return 'Department Head';
      case 4:
        return 'Staff Member';
      case 5:
        return 'Minute Taker';
      default:
        return '';
    }
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          if (widget.showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open menu',
            )
          else ...[
            Image.asset(
              'assets/psutLogo.png',
              width: 32,
              height: 32,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 10),
            const Text(
              'Post-Meeting Management System',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const Spacer(),
          // Notification bell
          PopupMenuButton<int>(
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            constraints: const BoxConstraints(maxWidth: 320),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 20, color: AppColors.textSecondary),
                if (_unsignedMeetings.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.statusDraft,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_unsignedMeetings.length}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            itemBuilder: (BuildContext context) {
              if (_unsignedMeetings.isEmpty) {
                return [
                  const PopupMenuItem<int>(
                    enabled: false,
                    child: Text('No meetings awaiting your signature',
                        style: TextStyle(fontSize: 13)),
                  ),
                ];
              }
              return [
                const PopupMenuItem<int>(
                  enabled: false,
                  child: Text(
                    'Awaiting Your Signature',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ..._unsignedMeetings.map((Meeting m) {
                  return PopupMenuItem<int>(
                    value: m.id,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.statusPending
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.draw_outlined,
                              size: 16, color: AppColors.statusPending),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(m.meetingDate),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ];
            },
            onSelected: (int meetingId) {
              context.go('/review');
            },
          ),
          const SizedBox(width: 8),
          // User avatar & name
          PopupMenuButton<String>(
            offset: const Offset(0, 44),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 16, color: AppColors.statusDraft),
                    SizedBox(width: 8),
                    Text('Logout',
                        style: TextStyle(color: AppColors.statusDraft)),
                  ],
                ),
              ),
            ],
            onSelected: (String value) async {
              if (value == 'logout') {
                final GoRouter router = GoRouter.of(context);
                await AuthService().logout();
                router.go('/login');
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    _initials(_userName),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_roleName.isNotEmpty)
                      Text(
                        _roleName,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
