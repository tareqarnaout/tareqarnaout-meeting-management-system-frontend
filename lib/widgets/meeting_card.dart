import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import 'status_badge.dart';

class MeetingCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final DateTime? date;
  final int status;
  final double? progress;
  final VoidCallback? onTap;

  const MeetingCard({
    super.key,
    required this.title,
    this.subtitle,
    this.date,
    this.status = 0,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                    title,
                    style: AppTextStyles.heading3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge.fromStatus(status),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: AppTextStyles.bodySmall),
            ],
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(date!),
                style: AppTextStyles.caption,
              ),
            ],
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress!,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress! >= 1.0
                        ? AppColors.statusApproved
                        : AppColors.primaryBlue,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
