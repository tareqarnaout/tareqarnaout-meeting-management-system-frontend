import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
  });

  factory StatusBadge.draft() =>
      const StatusBadge(label: 'Draft', color: AppColors.statusDraft);

  factory StatusBadge.pending() =>
      const StatusBadge(label: 'Pending', color: AppColors.statusPending);

  factory StatusBadge.approved() =>
      const StatusBadge(label: 'Approved', color: AppColors.statusApproved);

  factory StatusBadge.finalized() =>
      const StatusBadge(label: 'Finalized', color: AppColors.statusFinalized);

  factory StatusBadge.fromStatus(int status) {
    switch (status) {
      case 0:
        return StatusBadge.draft();
      case 1:
        return StatusBadge.pending();
      case 2:
        return StatusBadge.finalized();
      default:
        return const StatusBadge(label: 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}
