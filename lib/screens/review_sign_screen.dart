import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ReviewSignScreen extends StatelessWidget {
  const ReviewSignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review & Sign Meeting Summary',
                style: AppTextStyles.heading2),
            const SizedBox(height: 4),
            Text('Review the meeting details and provide your digital signature.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // Alert banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        size: 16, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Action Required: Your Signature Needed',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E))),
                        Text(
                            'Please review the meeting summary and provide your digital approval or rejection.',
                            style: TextStyle(
                                fontSize: 12, color: const Color(0xFFB45309))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left - Meeting content
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meeting header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppDecorations.cardWithBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Department Safety Review',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Submitted for Approval',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF59E0B))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _infoChip(Icons.calendar_today_outlined,
                                    'October 15, 2025'),
                                const SizedBox(width: 16),
                                _infoChip(
                                    Icons.category_outlined, 'Department'),
                                const SizedBox(width: 16),
                                _infoChip(
                                    Icons.people_outline, '5 Attendees'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Meeting Minutes
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppDecorations.cardWithBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Meeting Minutes',
                                style: AppTextStyles.heading3),
                            const SizedBox(height: 16),
                            _minutesSection(
                              'Meeting Summary - Department Safety Review',
                              [
                                'Date: October 15, 2025 | Time: 2:00 PM - 4:30 PM',
                                'Location: Conference Room B, Science Building',
                              ],
                            ),
                            const Divider(height: 28),
                            _minutesSection('Attendees:', [
                              '1. Dr. Abdulla Guest (Chair) - Department Head',
                              '2. Dr. Hassan Ali - Safety Officer',
                              '3. Dr. Fatima Al-Rashid - Lab Director',
                              '4. Dr. Mohammed Hassan - Research Lead',
                              '5. Prof. Sarah Ahmed - Faculty Representative',
                            ]),
                            const Divider(height: 28),
                            _minutesSection('Agenda Items:', []),
                            const SizedBox(height: 8),
                            _numberedItem('1', 'Laboratory Safety Protocol Updates', [
                              'Current safety protocols were reviewed and identified areas for improvement.',
                              'New chemical handling procedures to be implemented by November 2025.',
                              'All lab personnel must complete updated safety training.',
                            ]),
                            const SizedBox(height: 12),
                            _numberedItem('2', 'Emergency Response Procedures', [
                              'Emergency evacuation routes have been updated, pending approval.',
                              'New first-aid stations to be installed in all research labs.',
                              'Emergency contact list to be updated by November 1, 2025.',
                            ]),
                            const SizedBox(height: 12),
                            _numberedItem('3', 'Equipment Safety Inspections', [
                              'Annual inspection completed for all major laboratory equipment.',
                              'Replacement schedule approved for outdated safety equipment.',
                              'Budget allocation of \$25,000 approved for necessary replacements.',
                            ]),
                            const SizedBox(height: 12),
                            _numberedItem('4', 'Student Safety Training Program', [
                              'Mandatory safety orientation for all new graduate students approved.',
                              'Monthly safety audit to be implemented starting Q1 2026.',
                              'Online safety training module development authorized.',
                            ]),
                            const Divider(height: 28),
                            _minutesSection('Action Items:', [
                              'Dr. Ali to update safety protocols by November 15, 2025.',
                              'Dr. Al-Rashid to coordinate equipment replacements.',
                              'Dr. Hassan to develop online training module.',
                              'Dr. Ahmed to schedule student orientation sessions.',
                            ]),
                            const Divider(height: 28),
                            const Text('Next Meeting: November 15, 2025 at 2:00 PM',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Minutes Prepared: October 15, 2025',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Signature Actions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppDecorations.cardWithBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Signature Actions',
                                style: AppTextStyles.heading3),
                            const SizedBox(height: 4),
                            Text(
                                'Review the meeting summary above and provide your decision.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showSignDialog(context);
                                    },
                                    icon: const Icon(Icons.check_circle_outline,
                                        size: 18),
                                    label: const Text('Approve & Sign'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.statusApproved,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.cancel_outlined,
                                        size: 18),
                                    label: const Text('Request Revision'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.statusDraft,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Right - Approval status
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Approval Progress
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppDecorations.cardWithBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Approval Progress',
                                style: AppTextStyles.heading3),
                            const SizedBox(height: 16),
                            Center(
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: 0.4,
                                      strokeWidth: 6,
                                      backgroundColor: AppColors.border,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              AppColors.statusApproved),
                                    ),
                                    const Text('2/5',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text('2 of 5 signatures collected',
                                  style: AppTextStyles.caption),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Required Signatories
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppDecorations.cardWithBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Required Signatories',
                                style: AppTextStyles.heading3),
                            const SizedBox(height: 14),
                            _signatoryRow('Dr. Abdulla Guest', true),
                            _signatoryRow('Dr. Mohammed Al Ali', true),
                            _signatoryRow('Dr. Fatima Al Hargan', false),
                            _signatoryRow('Dr. Hassan Ahmed', false),
                            _signatoryRow('Prof. Layla Al Salem', false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Meeting Status
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppDecorations.cardWithBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Meeting Status',
                                style: AppTextStyles.heading3),
                            const SizedBox(height: 14),
                            _statusRow('Created',
                                'Oct 15, 25, at 4:30 PM'),
                            const SizedBox(height: 8),
                            _statusRow('Submitted',
                                'Oct 15, 25, at 4:45 PM'),
                            const SizedBox(height: 8),
                            _statusRow(
                                'Status', 'Pending Approval'),
                            const SizedBox(height: 8),
                            _statusRow(
                                'Last Updated', 'Oct 15, 25'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _minutesSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...items.map((String item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(item,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5)),
              )),
        ],
      ],
    );
  }

  Widget _numberedItem(
      String number, String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$number. $title',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        ...points.map((String point) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('\u2022 ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(point,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5)),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _signatoryRow(String name, bool signed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: (signed
                    ? AppColors.statusApproved
                    : AppColors.textMuted)
                .withValues(alpha: 0.1),
            child: Text(
              name.split(' ').map((String w) => w[0]).take(2).join(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: signed
                    ? AppColors.statusApproved
                    : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (signed
                      ? AppColors.statusApproved
                      : AppColors.statusPending)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              signed ? 'Signed' : 'Pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: signed
                    ? AppColors.statusApproved
                    : AppColors.statusPending,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.end),
        ),
      ],
    );
  }

  void _showSignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Confirm Signature'),
          content: const Text(
              'Are you sure you want to approve and sign this meeting summary? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meeting signed successfully!'),
                    backgroundColor: AppColors.statusApproved,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusApproved,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Sign'),
            ),
          ],
        );
      },
    );
  }
}
