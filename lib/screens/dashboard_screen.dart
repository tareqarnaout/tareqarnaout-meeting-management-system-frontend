import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_theme.dart';
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
    return Container(
      color: AppColors.pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _animatedSection(
              0,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back, Dr. Abdulla Guest',
                    style: TextStyle(
                      fontSize: 22,
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

            // CTA banner
            _animatedSection(1, _buildCtaBanner(context)),
            const SizedBox(height: 24),

            // Quick stats row
            _animatedSection(2, _buildStatsRow()),
            const SizedBox(height: 28),

            // Two-column meetings sections
            _animatedSection(
              3,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Meetings by Signature',
                            style: AppTextStyles.heading3),
                        const SizedBox(height: 4),
                        Text('Meetings awaiting your signature',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: 14),
                        MeetingCard(
                          title: 'Department Safety Review',
                          subtitle: 'Review safety protocols and compliance',
                          date: DateTime(2025, 10, 15),
                          status: 0,
                          onTap: () => context.go('/review'),
                        ),
                        const SizedBox(height: 10),
                        MeetingCard(
                          title: 'Research Collaboration Proposal',
                          subtitle: 'Cross-department research initiative',
                          date: DateTime(2025, 11, 3),
                          status: 0,
                          onTap: () => context.go('/review'),
                        ),
                        const SizedBox(height: 10),
                        MeetingCard(
                          title: 'Student Affairs Committee Meeting',
                          subtitle: 'Student welfare and academic support',
                          date: DateTime(2025, 9, 28),
                          status: 0,
                          onTap: () => context.go('/review'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Meetings Needing Others' Signatures",
                            style: AppTextStyles.heading3),
                        const SizedBox(height: 4),
                        Text('Tracking signature progress',
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: 14),
                        MeetingCard(
                          title: 'Curriculum Review Committee Meeting',
                          subtitle: 'Annual curriculum assessment',
                          date: DateTime(2025, 10, 20),
                          status: 1,
                          progress: 0.75,
                        ),
                        const SizedBox(height: 10),
                        MeetingCard(
                          title: 'Annual Budget Planning Session',
                          subtitle: 'FY2026 budget allocation',
                          date: DateTime(2025, 11, 8),
                          status: 1,
                          progress: 0.4,
                        ),
                        const SizedBox(height: 10),
                        MeetingCard(
                          title: 'Faculty Hiring Committee Update',
                          subtitle: 'New faculty recruitment',
                          date: DateTime(2025, 10, 5),
                          status: 1,
                          progress: 0.6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Recently Archived
            _animatedSection(
              4,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recently Archived Meetings',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildArchivedCard(
                          'Q3 Department Review',
                          DateTime(2025, 9, 15),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildArchivedCard(
                          'Lab Equipment Procurement',
                          DateTime(2025, 8, 22),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryTeal, const Color(0xFF1F6364)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(Icons.description_outlined, 'Meeting Drafts', '3',
            AppColors.primaryTeal),
        const SizedBox(width: 14),
        _buildStatCard(Icons.draw_outlined, 'My Signatures', '5',
            AppColors.statusPending),
        const SizedBox(width: 14),
        _buildStatCard(Icons.access_time, 'Recently Active', '8',
            AppColors.statusApproved),
        const SizedBox(width: 14),
        _buildStatCard(Icons.history, 'Past Meetings', '24',
            AppColors.statusFinalized),
      ].map((Widget w) => w is SizedBox ? w : Expanded(child: w)).toList(),
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
