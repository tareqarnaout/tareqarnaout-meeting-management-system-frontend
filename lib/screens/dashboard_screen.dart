import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/api_constants.dart';
import '../constants/app_theme.dart';
import '../models/meeting.dart';
import '../services/auth_service.dart';
import '../services/meeting_service.dart';
import '../widgets/meeting_card.dart';
import '../widgets/wave_scroll_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  static const int _sectionCount = 5;
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  final MeetingService _meetingService = MeetingService();
  final AuthService _authService = AuthService();

  List<Meeting> _pendingMeetings = [];
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimations = List<Animation<double>>.generate(_sectionCount, (int i) {
      final double start = i * 0.12;
      final double end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations =
        List<Animation<Offset>>.generate(_sectionCount, (int i) {
      final double start = i * 0.12;
      final double end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _loadData();
  }

  Future<void> _loadData() async {
    final List<Object?> results = await Future.wait([
      _meetingService.getPendingSignMeetings(),
      _authService.getUserName(),
    ]);

    if (!mounted) return;

    setState(() {
      _pendingMeetings = results[0] as List<Meeting>;
      _userName = (results[1] as String?) ?? 'User';
      _isLoading = false;
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final EdgeInsets padding = EdgeInsets.all(isMobile ? 16 : 28);

        return Container(
          color: AppColors.pageBg,
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animatedSection(
                  0,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $_userName',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Here's what's happening with your meeting processes today.",
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _animatedSection(1, _buildCtaBanner(context, isMobile)),
                const SizedBox(height: 24),

                _animatedSection(2, _buildStatsGrid(isMobile)),
                const SizedBox(height: 28),

                _animatedSection(
                  3,
                  _buildMeetingsSection(context, isMobile),
                ),
                const SizedBox(height: 28),

                _animatedSection(
                  4,
                  _buildArchivedSection(isMobile),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeetingsSection(BuildContext context, bool isMobile) {
    final List<Meeting> unsigned = _pendingMeetings
        .where((Meeting m) =>
            !m.signatories.any((Signatory s) => s.hasSigned))
        .toList();
    final List<Meeting> pendingOthers = _pendingMeetings
        .where((Meeting m) => m.status == MeetingStatus.pendingApproval)
        .toList();

    final Widget leftCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Meetings Awaiting Your Signature',
            style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text('Meetings that require your signature',
            style: AppTextStyles.bodySmall),
        const SizedBox(height: 14),
        if (unsigned.isEmpty)
          _buildEmptyState('No meetings awaiting your signature')
        else
          ...unsigned.map((Meeting m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MeetingCard(
                  title: m.title,
                  subtitle: m.councilType ?? m.meetingContent ?? '',
                  date: m.meetingDate,
                  status: m.status,
                  onTap: () => context.go('/review'),
                ),
              )),
      ],
    );

    final Widget rightCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pending Approval', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text('Tracking signature progress', style: AppTextStyles.bodySmall),
        const SizedBox(height: 14),
        if (pendingOthers.isEmpty)
          _buildEmptyState('No meetings pending approval')
        else
          ...pendingOthers.map((Meeting m) {
            final int signed =
                m.signatories.where((Signatory s) => s.hasSigned).length;
            final int total =
                m.signatureNeededCount > 0 ? m.signatureNeededCount : 1;
            final double progress = (signed / total).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MeetingCard(
                title: m.title,
                subtitle: m.councilType ?? m.meetingContent ?? '',
                date: m.meetingDate,
                status: m.status,
                progress: progress,
              ),
            );
          }),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leftCol,
          const SizedBox(height: 24),
          rightCol,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: leftCol),
        const SizedBox(width: 20),
        Expanded(child: rightCol),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: AppDecorations.cardWithBorder,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(message, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildArchivedSection(bool isMobile) {
    final List<Meeting> finalized = _pendingMeetings
        .where((Meeting m) => m.status == MeetingStatus.finalized)
        .toList();

    if (finalized.isEmpty) return const SizedBox.shrink();

    final List<Widget> cards = finalized
        .take(2)
        .map((Meeting m) => _buildArchivedCard(m.title, m.meetingDate))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recently Finalized', style: AppTextStyles.heading3),
        const SizedBox(height: 14),
        if (isMobile)
          Column(
            children: [
              cards[0],
              if (cards.length > 1) ...[
                const SizedBox(height: 12),
                cards[1],
              ],
            ],
          )
        else
          Row(
            children: [
              Expanded(child: cards[0]),
              if (cards.length > 1) ...[
                const SizedBox(width: 16),
                Expanded(child: cards[1]),
              ],
              const SizedBox(width: 16),
              if (cards.length < 2) const Expanded(child: SizedBox()),
              const Expanded(child: SizedBox()),
            ],
          ),
      ],
    );
  }

  Widget _buildCtaBanner(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 18 : 28, vertical: isMobile ? 16 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryTeal, const Color(0xFF1F6364)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a Meeting Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Draft and prepare meeting minutes for digital signatures',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 14),
                WaveScrollButton(
                  text: 'Get Started',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/create'),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryTeal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create a Meeting Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Draft and prepare meeting minutes for digital signatures',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                WaveScrollButton(
                  text: 'Get Started',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/create'),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryTeal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsGrid(bool isMobile) {
    final int pendingCount = _pendingMeetings
        .where((Meeting m) => m.status == MeetingStatus.pendingApproval)
        .length;
    final int draftCount = _pendingMeetings
        .where((Meeting m) => m.status == MeetingStatus.draft)
        .length;
    final int finalizedCount = _pendingMeetings
        .where((Meeting m) => m.status == MeetingStatus.finalized)
        .length;

    final List<Widget> cards = [
      _buildStatCard(Icons.description_outlined, 'Meeting Drafts',
          '$draftCount', AppColors.primaryTeal),
      _buildStatCard(Icons.draw_outlined, 'Pending Signatures',
          '$pendingCount', AppColors.statusPending),
      _buildStatCard(Icons.assignment_outlined, 'Total Meetings',
          '${_pendingMeetings.length}', AppColors.statusApproved),
      _buildStatCard(Icons.check_circle_outline, 'Finalized',
          '$finalizedCount', AppColors.statusFinalized),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ]),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 14),
        Expanded(child: cards[1]),
        const SizedBox(width: 14),
        Expanded(child: cards[2]),
        const SizedBox(width: 14),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.cardWithBorder,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedCard(String title, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text(
            '${date.month}/${date.day}/${date.year}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
