import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/minute_taker_models.dart';

class MinuteSectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const MinuteSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class MinuteTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;

  const MinuteTag({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppTextStyles.tag.copyWith(color: textColor)),
        ],
      ),
    );
  }
}

class MinuteActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const MinuteActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: AppTextStyles.buttonSmall),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: AppColors.textSecondary),
      label: Text(label, style: AppTextStyles.buttonMuted),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class AttendanceList extends StatelessWidget {
  final List<Attendee> attendees;

  const AttendanceList({super.key, required this.attendees});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: attendees
          .map((Attendee attendee) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AttendanceTile(attendee: attendee),
              ))
          .toList(),
    );
  }
}

class AttendanceTile extends StatelessWidget {
  final Attendee attendee;

  const AttendanceTile({super.key, required this.attendee});

  @override
  Widget build(BuildContext context) {
    final Color avatarBg = attendee.isPresent
        ? AppColors.primaryTeal.withValues(alpha: 0.12)
        : AppColors.border.withValues(alpha: 0.4);
    final Color avatarText =
        attendee.isPresent ? AppColors.primaryTeal : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: attendee.isPresent
            ? AppColors.primaryTeal.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarBg,
            child: Text(attendee.initials,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: avatarText)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attendee.name, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(attendee.role, style: AppTextStyles.caption),
              ],
            ),
          ),
          Icon(
            attendee.isPresent
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            size: 18,
            color: attendee.isPresent
                ? AppColors.primaryTeal
                : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class AgendaList extends StatelessWidget {
  final List<AgendaItem> items;

  const AgendaList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((AgendaItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AgendaTile(item: item),
              ))
          .toList(),
    );
  }
}

class AgendaTile extends StatelessWidget {
  final AgendaItem item;

  const AgendaTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        item.isActive ? AppColors.primaryTeal : AppColors.border;
    final Color indexBg =
        item.isActive ? AppColors.primaryTeal : AppColors.border;
    final Color indexText = item.isActive ? Colors.white : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: item.isActive
            ? AppColors.primaryTeal.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: indexBg,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              item.index.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: indexText,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.title, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class HandoffStats extends StatelessWidget {
  final List<HandoffStat> stats;

  const HandoffStats({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: stats
            .map((HandoffStat stat) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(stat.label, style: AppTextStyles.caption),
                      ),
                      Text(
                        stat.value,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: stat.highlight
                              ? AppColors.primaryTeal
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class TranscriptEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const TranscriptEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.chat_bubble_outline,
              size: 22, color: AppColors.primaryTeal),
        ),
        const SizedBox(height: 12),
        Text(title, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class TranscriptInputBar extends StatelessWidget {
  final List<String> speakers;
  final String selectedSpeaker;

  const TranscriptInputBar({
    super.key,
    required this.speakers,
    required this.selectedSpeaker,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Speaker', style: AppTextStyles.caption),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSpeaker,
                  items: speakers
                      .map((String speaker) => DropdownMenuItem<String>(
                            value: speaker,
                            child: Text(speaker),
                          ))
                      .toList(),
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type what was said...',
                    hintStyle: AppTextStyles.bodySmall,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add', style: AppTextStyles.buttonSmall),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

