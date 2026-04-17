import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../widgets/document_preview.dart';
import '../widgets/wave_scroll_button.dart';

class ReviewSignScreen extends StatelessWidget {
  const ReviewSignScreen({super.key});

  static const DocumentPreviewData _mockData = DocumentPreviewData(
    referenceNumber: '468/31/13/1082',
    issueDate: '2025/10/22',
    recipients: [
      'الأستاذ الدكتور عميد الكلية المحترم',
      'السادة أعضاء هيئة التدريس المحترمون',
    ],
    councilType: 'مجلس القسم',
    sessionNumber: '19',
    academicYear: '2025/2026',
    meetingDate: '2025/10/20',
    decisionNumber: '4',
    decisionText:
        'بناءً على مناقشة مجلس القسم لموضوع تحديث بروتوكولات السلامة في المختبرات، تقرر ما يلي:\n\n'
        'أولاً: اعتماد متطلبات تخزين المواد الكيميائية الجديدة وتطبيقها فوراً في جميع المختبرات.\n\n'
        'ثانياً: إلزام جميع العاملين في المختبرات بإكمال تدريب السلامة المحدّث قبل تاريخ 2025/11/15.\n\n'
        'ثالثاً: تحديث خرائط مسارات الإخلاء الطارئ ونشرها في جميع المباني قبل 2025/11/1.\n\n'
        'رابعاً: تخصيص مبلغ 12,000 دينار لصيانة وإصلاح المعدات المُعلّقة في تقرير الفحص السنوي.\n\n'
        'خامساً: تكليف د. فاطمة الحسن بتنسيق جلسات التدريب على السلامة لطلبة الدراسات العليا الجدد.\n\n'
        'سادساً: اعتماد نظام الإبلاغ الرقمي عن الحوادث عبر بوابة القسم الإلكترونية، على أن يتم تدريب جميع أعضاء هيئة التدريس على النظام قبل 2025/11/20.',
    signatoryName: 'أ.د. عبدالله',
    signatoryTitle: 'رئيس القسم',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          // Document header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            color: const Color(0xFF3B5998),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_outlined,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'معاينة الوثيقة الرسمية — للمراجعة والتوقيع',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left — Document preview
                Expanded(
                  flex: 6,
                  child: Container(
                    color: const Color(0xFFE8EAF0),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: DocumentPreview(
                          data: _mockData,
                          showPlaceholders: false,
                        ),
                      ),
                    ),
                  ),
                ),

                // Right — Review sidebar
                SizedBox(
                  width: 340,
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSidebarHeader(context),
                          const SizedBox(height: 16),
                          _buildActionRequiredBanner(),
                          const SizedBox(height: 16),
                          _buildSignatureProgress(),
                          const SizedBox(height: 16),
                          _buildRequiredSignatories(),
                          const SizedBox(height: 16),
                          _buildSignatureActions(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            const Text('مراجعة وتوقيع',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'راجع الوثيقة ثم وقع أو اطلب تعديلاً',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionRequiredBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D9E).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF2E7D9E).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline,
                  size: 16, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'إجراء مطلوب: توقيعك مطلوب',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTeal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'يرجى مراجعة الوثيقة والتوقيع الرقمي للموافقة.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تقدم التوقيعات',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('2 من 5 وقعوا',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          const Text('40% مكتمل',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.4,
              minHeight: 8,
              backgroundColor: AppColors.border.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredSignatories() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الموقعون المطلوبون',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          _signatoryRow('د. محمد العلي', true, '2025/10/22'),
          _signatoryRow('د. فاطمة الحسن', true, '2025/10/23'),
          _signatoryRow('د. أحمد الخالدي', false, null),
          _signatoryRow('د. عبدالله قصف', false, null),
          _signatoryRow('د. ليلى السالم', false, null),
        ],
      ),
    );
  }

  Widget _signatoryRow(String name, bool signed, String? signedDate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (signed
                                ? AppColors.statusApproved
                                : AppColors.statusPending)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            signed
                                ? Icons.check_circle_outline
                                : Icons.schedule,
                            size: 12,
                            color: signed
                                ? AppColors.statusApproved
                                : AppColors.statusPending,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            signed ? 'تم التوقيع' : 'قيد الانتظار',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: signed
                                  ? AppColors.statusApproved
                                  : AppColors.statusPending,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ],
                ),
                if (signed && signedDate != null) ...[
                  const SizedBox(height: 2),
                  Text('وقع بتاريخ $signedDate',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إجراءات التوقيع',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          WaveScrollButton(
            text: 'توقيع رقمي والموافقة',
            icon: Icons.check_circle_outline,
            onPressed: () => _showSignDialog(context),
            backgroundColor: AppColors.statusApproved,
            expand: true,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          const SizedBox(height: 10),
          WaveScrollButton(
            text: 'طلب تعديل',
            icon: Icons.cancel_outlined,
            onPressed: () {},
            outlined: true,
            expand: true,
            foregroundColor: AppColors.statusDraft,
            borderColor: AppColors.statusDraft,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ],
      ),
    );
  }

  void _showSignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('تأكيد التوقيع',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: const Text(
              'هل أنت متأكد من الموافقة والتوقيع على هذا الملخص؟ لا يمكن التراجع عن هذا الإجراء.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            WaveScrollButton(
              text: 'تأكيد والتوقيع',
              backgroundColor: AppColors.statusApproved,
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم التوقيع بنجاح!'),
                    backgroundColor: AppColors.statusApproved,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ],
        );
      },
    );
  }
}
