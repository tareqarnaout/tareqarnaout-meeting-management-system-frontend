import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../constants/app_theme.dart';
import '../models/meeting.dart';
import '../models/user.dart';
import '../services/meeting_service.dart';
import '../services/pdf_service.dart';
import '../services/user_service.dart';
import '../widgets/document_preview.dart';
import '../widgets/wave_scroll_button.dart';

class MeetingSignDetailScreen extends StatefulWidget {
  final int meetingId;
  final Meeting? meeting;

  const MeetingSignDetailScreen({super.key, required this.meetingId, this.meeting});

  @override
  State<MeetingSignDetailScreen> createState() =>
      _MeetingSignDetailScreenState();
}

class _MeetingSignDetailScreenState extends State<MeetingSignDetailScreen> {
  final MeetingService _meetingService = MeetingService();
  final UserService _userService = UserService();
  final PdfService _pdfService = PdfService();
  Meeting? _meeting;
  Map<int, AppUser> _usersMap = {};
  bool _isLoading = true;
  bool _isSigning = false;
  bool _isRequestingEdit = false;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _fetchMeeting();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMeeting() async {
    final List<Meeting> pending = await _meetingService.getPendingSignMeetings();
    final Meeting? fromPending = pending
        .where((Meeting m) => m.id == widget.meetingId)
        .firstOrNull;

    if (fromPending != null) {
      _meeting = fromPending;
    } else if (widget.meeting != null) {
      _meeting = widget.meeting;
    } else {
      _meeting = await _meetingService.getMeeting(widget.meetingId);
    }

    if (_meeting != null && _meeting!.signersNeededId.isNotEmpty) {
      try {
        final List<AppUser> users = await _userService.getUsers();
        _usersMap = {for (final AppUser u in users) u.id!: u};
      } catch (_) {}
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      final DocumentPreviewData previewData = _buildPreviewData();
      final String fileName = _meeting!.title.replaceAll(RegExp(r'[^\w؀-ۿ\s]'), '_');
      await _pdfService.downloadPdf(previewData, fileName);
    } catch (e, st) {
      debugPrint('PDF generation error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while generating the file. Please try again.'),
          backgroundColor: AppColors.statusDraft,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  Future<void> _sign() async {
    setState(() => _isSigning = true);
    final int statusCode = await _meetingService.verifySignature(_meeting!.id!);
    if (!mounted) return;
    setState(() => _isSigning = false);

    if (statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم التوقيع بنجاح!'),
          backgroundColor: AppColors.statusApproved,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchMeeting();
      if (mounted) setState(() {});
    } else if (statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لقد وقّعت على هذا الاجتماع مسبقاً.'),
          backgroundColor: AppColors.statusPending,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchMeeting();
      if (mounted) setState(() {});
    } else if (statusCode == 401) {
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ. يرجى المحاولة مرة أخرى.'),
          backgroundColor: AppColors.statusDraft,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_meeting == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.statusDraft),
              const SizedBox(height: 12),
              const Text('Meeting not found.',
                  style: TextStyle(
                      fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/review'),
                child: const Text('Back to list'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isMobile = constraints.maxWidth < 700;
        return isMobile
            ? _buildMobileLayout()
            : _buildDesktopLayout();
      },
    );
  }

  DocumentPreviewData _buildPreviewData() {
    final DateFormat fmt = DateFormat('yyyy/MM/dd');
    final DateTime date = _meeting!.meetingDate;
    final int startYear = date.month >= 9 ? date.year : date.year - 1;
    final String academicYear = '$startYear/${startYear + 1}';

    return DocumentPreviewData(
      meetingTitle: _meeting!.title,
      councilType: _meeting!.councilType ?? '',
      sessionNumber: _meeting!.sessionNumber ?? '',
      meetingDate: fmt.format(date),
      issueDate: fmt.format(date),
      academicYear: academicYear,
      decisionNumber: _meeting!.decisionNumber ?? '',
      decisionText: _meeting!.meetingContent ?? '',
      signatoryName: _meeting!.signatoryName ?? 'أ.د. عبدالله',
      signatoryTitle: _meeting!.signatoryTitle ?? 'رئيس القسم',
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    color: const Color(0xFFE8EAF0),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: DocumentPreview(
                          data: _buildPreviewData(),
                          showPlaceholders: false,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 340,
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildSidebar(),
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

  Widget _buildMobileLayout() {
    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFE8EAF0),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: DocumentPreview(
                        data: _buildPreviewData(),
                        showPlaceholders: false,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: _buildSidebar(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF3B5998),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/review'),
            child: const Icon(Icons.arrow_back,
                size: 18, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'معاينة الوثيقة الرسمية — للمراجعة والتوقيع',
              style: TextStyle(fontSize: 13, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_meeting != null)
            _isDownloadingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : InkWell(
                    onTap: _downloadPdf,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf,
                              size: 18, color: Colors.white70),
                          SizedBox(width: 6),
                          Text(
                            'تحميل PDF',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  List<_SignerInfo> _buildSignerList() {
    final List<int> neededIds = _meeting!.signersNeededId;
    final List<MeetingSignature> signatures = _meeting!.alreadySigned;

    if (neededIds.isEmpty) {
      return _meeting!.signatories.map(_toSignerInfo).toList();
    }

    final Map<int, MeetingSignature> signedMap = {
      for (final MeetingSignature sig in signatures)
        if (sig.hasSigned) sig.userId: sig
    };

    return neededIds.map((int uid) {
      final MeetingSignature? sig = signedMap[uid];
      final String name = _usersMap[uid]?.name ?? 'مستخدم #$uid';
      return _SignerInfo(
        userId: uid,
        name: name,
        hasSigned: sig != null,
        signedAt: sig?.timestamp,
      );
    }).toList();
  }

  static _SignerInfo _toSignerInfo(Signatory s) {
    return _SignerInfo(
      userId: s.userId,
      name: s.name,
      hasSigned: s.hasSigned,
      signedAt: s.signedAt,
    );
  }

  Widget _buildSidebar() {
    final List<_SignerInfo> signers = _buildSignerList();
    final int signedCount = signers.where((_SignerInfo s) => s.hasSigned).length;
    final int totalCount = signers.length;
    final double progress =
        totalCount > 0 ? signedCount / totalCount : 0;
    final bool hasSigned =
        _meeting!.signatureStatus == MeetingStatus.finalized;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => context.go('/review'),
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
        Text(
          hasSigned
              ? 'لقد وقّعت على هذه الوثيقة'
              : 'راجع الوثيقة ثم وقع أو اطلب تعديلاً',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Status banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasSigned
                ? AppColors.statusApproved.withValues(alpha: 0.08)
                : const Color(0xFF2E7D9E).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: hasSigned
                    ? AppColors.statusApproved.withValues(alpha: 0.3)
                    : const Color(0xFF2E7D9E).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasSigned
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 16,
                    color: hasSigned
                        ? AppColors.statusApproved
                        : AppColors.primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasSigned ? 'تم التوقيع' : 'إجراء مطلوب: توقيعك مطلوب',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: hasSigned
                              ? AppColors.statusApproved
                              : AppColors.primaryTeal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hasSigned
                    ? 'وقّعت رقمياً على هذه الوثيقة.'
                    : 'يرجى مراجعة الوثيقة والتوقيع الرقمي للموافقة.',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Signature progress
        if (totalCount > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5)),
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
                Text('$signedCount من $totalCount وقعوا',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Text('${(progress * 100).toStringAsFixed(0)}% مكتمل',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        AppColors.border.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryTeal),
                  ),
                ),
              ],
            ),
          ),
        if (totalCount > 0) const SizedBox(height: 16),

        // Signatories list
        if (signers.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5)),
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
                ...signers.map((_SignerInfo s) => _signerRow(s)),
              ],
            ),
          ),
        if (signers.isNotEmpty) const SizedBox(height: 16),

        // Sign actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
              if (hasSigned)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('تم التوقيع',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textMuted.withValues(alpha: 0.15),
                      foregroundColor: AppColors.textMuted,
                      disabledBackgroundColor:
                          AppColors.textMuted.withValues(alpha: 0.15),
                      disabledForegroundColor: AppColors.textMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                )
              else ...[
                WaveScrollButton(
                  text: 'توقيع رقمي والموافقة',
                  icon: Icons.check_circle_outline,
                  onPressed: _isSigning ? null : () => _showSignDialog(),
                  isLoading: _isSigning,
                  backgroundColor: AppColors.statusApproved,
                  expand: true,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                ),
                const SizedBox(height: 10),
                WaveScrollButton(
                  text: 'طلب تعديل',
                  icon: Icons.cancel_outlined,
                  onPressed:
                      _isRequestingEdit ? null : () => _showEditRequestDialog(),
                  isLoading: _isRequestingEdit,
                  outlined: true,
                  expand: true,
                  foregroundColor: AppColors.statusDraft,
                  borderColor: AppColors.statusDraft,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _signerRow(_SignerInfo s) {
    final bool signed = s.hasSigned;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
                    Text(s.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                  ],
                ),
                if (signed && s.signedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'وقع بتاريخ ${DateFormat('yyyy/MM/dd').format(s.signedAt!)}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestEdit(String note) async {
    setState(() => _isRequestingEdit = true);
    final int statusCode = await _meetingService.requestEdit(_meeting!.id!, note);
    if (!mounted) return;
    setState(() => _isRequestingEdit = false);

    if (statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب التعديل بنجاح'),
          backgroundColor: AppColors.statusApproved,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/review');
    } else if (statusCode == 401) {
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ. يرجى المحاولة مرة أخرى.'),
          backgroundColor: AppColors.statusDraft,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditRequestDialog() {
    final TextEditingController noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: const Text('طلب تعديل',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('يرجى كتابة ملاحظة توضح التعديل المطلوب.'),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظتك هنا...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            WaveScrollButton(
              text: 'إرسال طلب التعديل',
              backgroundColor: AppColors.statusDraft,
              onPressed: () {
                final String note = noteController.text.trim();
                if (note.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى كتابة ملاحظة قبل الإرسال'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                _requestEdit(note);
              },
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
          ],
        );
      },
    );
  }

  void _showSignDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: const Text('تأكيد التوقيع',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                _sign();
              },
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
          ],
        );
      },
    );
  }
}

class _SignerInfo {
  final int? userId;
  final String name;
  final bool hasSigned;
  final DateTime? signedAt;

  _SignerInfo({
    this.userId,
    required this.name,
    this.hasSigned = false,
    this.signedAt,
  });
}
