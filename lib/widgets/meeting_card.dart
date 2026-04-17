import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import 'status_badge.dart';

class MeetingCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final DateTime? date;
  final int status;
  final double? progress;
  final VoidCallback? onTap;
  final bool animateProgress;

  const MeetingCard({
    super.key,
    required this.title,
    this.subtitle,
    this.date,
    this.status = 0,
    this.progress,
    this.onTap,
    this.animateProgress = true,
  });

  @override
  State<MeetingCard> createState() => _MeetingCardState();
}

class _MeetingCardState extends State<MeetingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress ?? 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    if (widget.progress != null && widget.animateProgress) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _progressController.forward();
      });
    } else if (widget.progress != null) {
      _progressController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.cardWithBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge.fromStatus(widget.status),
              ],
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(widget.subtitle!, style: AppTextStyles.bodySmall),
            ],
            if (widget.date != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(widget.date!),
                style: AppTextStyles.caption,
              ),
            ],
            if (widget.progress != null) ...[
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _progressController,
                builder: (BuildContext context, Widget? child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.progress! >= 1.0
                            ? AppColors.statusApproved
                            : AppColors.primaryBlue,
                      ),
                      minHeight: 6,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
