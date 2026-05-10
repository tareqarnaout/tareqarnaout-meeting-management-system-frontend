import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../constants/api_constants.dart';
import '../models/meeting.dart';
import '../services/meeting_service.dart';

class ReviewSignScreen extends StatefulWidget {
  const ReviewSignScreen({super.key});

  @override
  State<ReviewSignScreen> createState() => _ReviewSignScreenState();
}

class _ReviewSignScreenState extends State<ReviewSignScreen> {
  final MeetingService _meetingService = MeetingService();
  List<Meeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Meeting> meetings =
        await _meetingService.getPendingSignMeetings();
    if (!mounted) return;
    setState(() {
      _meetings = meetings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        return Container(
          color: AppColors.pageBg,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Review & Sign', style: AppTextStyles.heading1),
                const SizedBox(height: 4),
                const Text(
                  'Meetings requiring your signature',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56,
                color: AppColors.statusApproved.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No pending signatures',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'You have no meetings waiting for your signature.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _meetings.length,
        separatorBuilder: (BuildContext c, int i) =>
            const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) =>
            _MeetingPendingCard(
          meeting: _meetings[index],
          onTap: () =>
              context.go('/review/${_meetings[index].id}', extra: _meetings[index]),
        ),
      ),
    );
  }
}

class _MeetingPendingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;

  const _MeetingPendingCard({
    required this.meeting,
    required this.onTap,
  });

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('MMM dd, yyyy').format(meeting.meetingDate);
    final bool isDraft = meeting.status == MeetingStatus.draft;
    final bool hasSigned = meeting.signatureStatus == MeetingStatus.finalized;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppDecorations.cardWithBorder,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (hasSigned
                        ? AppColors.textMuted
                        : AppColors.statusPending)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasSigned ? Icons.check_circle_outline : Icons.draw_outlined,
                size: 20,
                color: hasSigned
                    ? AppColors.textMuted
                    : AppColors.statusPending,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: AppTextStyles.caption),
                      if ((meeting.councilType ?? '').isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.group_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(meeting.councilType!,
                            style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasSigned)
                  _buildTag('تم التوقيع', AppColors.textMuted)
                else ...[
                  _buildTag('Sign', AppColors.statusPending),
                  if (isDraft) ...[
                    const SizedBox(width: 8),
                    _buildTag('Approve', AppColors.statusApproved),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
