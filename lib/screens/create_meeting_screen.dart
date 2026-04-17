import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../constants/app_theme.dart';
import '../models/meeting.dart';
import '../services/meeting_service.dart';
import '../widgets/document_preview.dart';
import '../widgets/wave_scroll_button.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final TextEditingController _meetingTitleController = TextEditingController();
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _sessionNumberController =
      TextEditingController();
  final TextEditingController _academicYearController =
      TextEditingController(text: '2025/2026');
  final TextEditingController _decisionNumberController =
      TextEditingController();
  final TextEditingController _meetingDateController = TextEditingController();
  final TextEditingController _decisionTextController = TextEditingController();
  final TextEditingController _connectionSearchController =
      TextEditingController();
  final TextEditingController _copyToController = TextEditingController();

  final MeetingService _meetingService = MeetingService();

  String _selectedCouncilType = 'مجلس القسم';
  DateTime? _selectedIssueDate;
  DateTime? _selectedMeetingDate;
  bool _isSubmitting = false;

  final List<String> _recipients = [
    'الأستاذ الدكتور عميد الكلية المحترم',
    'السادة أعضاء هيئة التدريس المحترمون',
  ];
  final TextEditingController _newRecipientController = TextEditingController();

  // Connection search state
  bool _showConnectionResults = false;
  List<_SearchableMeeting> _connectionSearchResults = [];
  final List<_AddedConnection> _addedConnections = [];

  final List<_SearchableMeeting> _allMeetings = [
    _SearchableMeeting(id: 1, title: 'Department Budget Review', date: DateTime(2025, 10, 15), status: 2, type: 'Department'),
    _SearchableMeeting(id: 2, title: 'Monthly Staff Meeting', date: DateTime(2025, 10, 1), status: 2, type: 'Administrative'),
    _SearchableMeeting(id: 3, title: 'Faculty Curriculum Update', date: DateTime(2025, 9, 20), status: 2, type: 'Faculty'),
    _SearchableMeeting(id: 4, title: 'Committee Review Q3', date: DateTime(2025, 9, 10), status: 1, type: 'Committee'),
    _SearchableMeeting(id: 5, title: 'IT Infrastructure Planning', date: DateTime(2025, 8, 28), status: 0, type: 'Department'),
    _SearchableMeeting(id: 6, title: 'Annual Performance Review', date: DateTime(2025, 8, 15), status: 2, type: 'Administrative'),
  ];

  // Copy-to list
  final List<String> _copyToList = [];

  // Users for required signatures
  List<Map<String, dynamic>> _allUsers = [];
  final List<Map<String, dynamic>> _selectedSignatories = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _showUserResults = false;
  bool _loadingUsers = true;
  final TextEditingController _signatorySearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final List<Map<String, dynamic>> users = await _meetingService.getUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _loadingUsers = false;
      });
    }
  }

  void _onSignatorySearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _showUserResults = false;
        _filteredUsers = [];
      });
      return;
    }
    final String lowerQuery = query.toLowerCase();
    final List<int> selectedIds = _selectedSignatories
        .map((Map<String, dynamic> u) => u['id'] as int)
        .toList();
    setState(() {
      _filteredUsers = _allUsers.where((Map<String, dynamic> u) {
        final int id = u['id'] as int;
        final String name =
            (u['fullName'] as String? ?? u['email'] as String? ?? '')
                .toLowerCase();
        return !selectedIds.contains(id) && name.contains(lowerQuery);
      }).toList();
      _showUserResults = true;
    });
  }

  void _addSignatory(Map<String, dynamic> user) {
    setState(() {
      _selectedSignatories.add(user);
      _signatorySearchController.clear();
      _showUserResults = false;
      _filteredUsers = [];
    });
  }

  void _removeSignatory(int userId) {
    setState(() {
      _selectedSignatories
          .removeWhere((Map<String, dynamic> u) => u['id'] == userId);
    });
  }

  void _onConnectionSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _showConnectionResults = false;
        _connectionSearchResults = [];
      });
      return;
    }
    final String lowerQuery = query.toLowerCase();
    final List<int> addedIds =
        _addedConnections.map((_AddedConnection c) => c.meeting.id).toList();
    setState(() {
      _connectionSearchResults = _allMeetings
          .where((_SearchableMeeting m) =>
              !addedIds.contains(m.id) &&
              (m.title.toLowerCase().contains(lowerQuery) ||
                  m.type.toLowerCase().contains(lowerQuery)))
          .toList();
      _showConnectionResults = true;
    });
  }

  void _addConnection(_SearchableMeeting meeting, String relationshipType) {
    setState(() {
      _addedConnections.add(
          _AddedConnection(meeting: meeting, relationshipType: relationshipType));
      _connectionSearchController.clear();
      _showConnectionResults = false;
      _connectionSearchResults = [];
    });
  }

  void _removeConnection(int meetingId) {
    setState(() {
      _addedConnections
          .removeWhere((_AddedConnection c) => c.meeting.id == meetingId);
    });
  }

  String _statusLabel(int status) {
    switch (status) {
      case 0:
        return 'Draft';
      case 1:
        return 'Pending';
      case 2:
        return 'Finalized';
      default:
        return 'Unknown';
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return AppColors.statusDraft;
      case 1:
        return AppColors.statusPending;
      case 2:
        return AppColors.statusFinalized;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  void dispose() {
    _meetingTitleController.dispose();
    _referenceNumberController.dispose();
    _issueDateController.dispose();
    _sessionNumberController.dispose();
    _academicYearController.dispose();
    _decisionNumberController.dispose();
    _meetingDateController.dispose();
    _decisionTextController.dispose();
    _connectionSearchController.dispose();
    _copyToController.dispose();
    _newRecipientController.dispose();
    _signatorySearchController.dispose();
    super.dispose();
  }

  Future<void> _pickIssueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedIssueDate = picked;
        _issueDateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickMeetingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedMeetingDate = picked;
        _meetingDateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit(int status) async {
    if (_isSubmitting) return;

    if (_selectedMeetingDate == null && _selectedIssueDate == null) {
      _showSnack('يرجى تحديد تاريخ الاجتماع.');
      return;
    }
    if (_decisionTextController.text.trim().isEmpty) {
      _showSnack('يرجى إدخال نص القرار.');
      return;
    }

    if (status == MeetingStatus.pendingApproval &&
        _selectedSignatories.isEmpty) {
      _showSnack('أضف موقعاً واحداً على الأقل قبل الإرسال.');
      return;
    }

    setState(() => _isSubmitting = true);

    final String meetingTitle = _meetingTitleController.text.trim().isNotEmpty
        ? _meetingTitleController.text.trim()
        : _selectedCouncilType;

    final Meeting meeting = Meeting(
      title: meetingTitle,
      meetingDate: _selectedMeetingDate ?? _selectedIssueDate ?? DateTime.now(),
      meetingContent: _decisionTextController.text.trim(),
      status: status,
      requiredSignatures: _selectedSignatories
          .map((Map<String, dynamic> u) => u['id'] as int)
          .toList(),
      recipients: List<String>.from(_recipients),
      sessionNumber: _sessionNumberController.text.trim(),
      decisionNumber: _decisionNumberController.text.trim(),
      councilType: _selectedCouncilType,
    );

    final bool ok = await _meetingService.createMeeting(meeting);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      _showSnack(status == MeetingStatus.draft
          ? 'تم حفظ المسودة.'
          : 'تم إرسال الملخص للتوقيع.');
      context.go('/');
    } else {
      _showSnack('فشل إنشاء الاجتماع. يرجى المحاولة مرة أخرى.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left panel — Form
                Expanded(
                  flex: 5,
                  child: _buildFormPanel(),
                ),
                // Right panel — Document preview
                Expanded(
                  flex: 4,
                  child: _buildDocumentPreview(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios,
                    size: 14, color: AppColors.textSecondary),
                SizedBox(width: 4),
              ],
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إنشاء ملخص اجتماع', style: AppTextStyles.heading2),
                SizedBox(height: 2),
                Text(
                  'قم بتحرير وإعداد محضر الاجتماع للتوقيع الرقمي',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : () => _submit(MeetingStatus.draft),
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('حفظ مسودة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 10),
          WaveScrollButton(
            text: 'إرسال',
            icon: Icons.send,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting
                ? null
                : () => _submit(MeetingStatus.pendingApproval),
            backgroundColor: AppColors.primaryTeal,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document Information
          _buildSectionCard(
            title: 'معلومات الوثيقة',
            child: Column(
              children: [
                _buildField(
                  label: 'عنوان الاجتماع',
                  child: TextField(
                    controller: _meetingTitleController,
                    onChanged: (_) => setState(() {}),
                    decoration: AppDecorations.inputDecoration(
                      '',
                      hint: 'أدخل عنوان الاجتماع',
                    ).copyWith(labelText: null),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'رقم المرجع',
                        child: TextField(
                          controller: _referenceNumberController,
                          textDirection: ui.TextDirection.ltr,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: '468/31/13/1082',
                          ).copyWith(labelText: null),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        label: 'تاريخ الإصدار',
                        child: TextField(
                          controller: _issueDateController,
                          readOnly: true,
                          onTap: _pickIssueDate,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: 'mm / dd / yyyy',
                            suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.textMuted),
                          ).copyWith(labelText: null),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'رقم الجلسة',
                        child: TextField(
                          controller: _sessionNumberController,
                          keyboardType: TextInputType.number,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: 'مثال: 19',
                          ).copyWith(labelText: null),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        label: 'العام الدراسي',
                        child: TextField(
                          controller: _academicYearController,
                          textDirection: ui.TextDirection.ltr,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: '2025/2026',
                          ).copyWith(labelText: null),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'رقم القرار',
                        child: TextField(
                          controller: _decisionNumberController,
                          keyboardType: TextInputType.number,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: 'مثل 1',
                          ).copyWith(labelText: null),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        label: 'تاريخ الاجتماع',
                        child: TextField(
                          controller: _meetingDateController,
                          readOnly: true,
                          onTap: _pickMeetingDate,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: 'mm / dd / yyyy',
                            suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.textMuted),
                          ).copyWith(labelText: null),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(
                  label: 'نوع المجلس',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCouncilType,
                    decoration:
                        AppDecorations.inputDecoration('', hint: '').copyWith(labelText: null),
                    items: const [
                      DropdownMenuItem(value: 'مجلس القسم', child: Text('مجلس القسم')),
                      DropdownMenuItem(value: 'مجلس الكلية', child: Text('مجلس الكلية')),
                      DropdownMenuItem(value: 'مجلس العمداء', child: Text('مجلس العمداء')),
                      DropdownMenuItem(value: 'مجلس الجامعة', child: Text('مجلس الجامعة')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) setState(() => _selectedCouncilType = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recipients
          _buildSectionCard(
            title: 'المستلمون',
            subtitle: 'قائمة الأشخاص المذكورين في ترويسة الوثيقة.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._recipients.asMap().entries.map((MapEntry<int, String> entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.pageBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _recipients.removeAt(entry.key)),
                          child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newRecipientController,
                        decoration: AppDecorations.inputDecoration(
                          '',
                          hint: 'أضف مستلماً جديداً',
                          prefixIcon: const Icon(Icons.person_add_outlined,
                              size: 18, color: AppColors.textMuted),
                        ).copyWith(labelText: null),
                        onSubmitted: (_) => _addRecipient(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _addRecipient,
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryTeal),
                      tooltip: 'إضافة',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Decision Text / Meeting Summary
          _buildSectionCard(
            title: 'نص القرار / ملخص الاجتماع',
            subtitle: 'قم بتعبئة محتوى القرار أو الملخص في هذه الوثيقة.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: TextField(
                    controller: _decisionTextController,
                    maxLines: null,
                    expands: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText:
                          'أدخل نص القرار أو ملخص الاجتماع والبنود التي تمت مناقشتها...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Meeting Connections
          _buildSectionCard(
            icon: Icons.link,
            title: 'ربط الاجتماعات',
            subtitle: 'اربط هذا الاجتماع بقرارات أو اجتماعات سابقة.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _connectionSearchController,
                  onChanged: _onConnectionSearchChanged,
                  decoration: AppDecorations.inputDecoration(
                    '',
                    hint: 'إضافة ارتباط باجتماع سابق',
                    prefixIcon: const Icon(Icons.add,
                        size: 18, color: AppColors.textMuted),
                  ).copyWith(labelText: null),
                ),
                if (_showConnectionResults)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _connectionSearchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'لم يتم العثور على اجتماعات مطابقة.',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _connectionSearchResults.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(
                                        height: 1, color: AppColors.divider),
                            itemBuilder: (BuildContext context, int index) {
                              final _SearchableMeeting meeting =
                                  _connectionSearchResults[index];
                              return _buildSearchResultTile(meeting);
                            },
                          ),
                  ),
                const SizedBox(height: 12),
                if (_addedConnections.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'لم يتم إضافة ارتباطات بعد.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted.withValues(alpha: 0.7)),
                      ),
                    ),
                  )
                else
                  Column(
                    children: _addedConnections
                        .map((_AddedConnection conn) =>
                            _buildConnectionCard(conn))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Copy To
          _buildSectionCard(
            title: 'نسخة → الإطلاع',
            subtitle: 'أضف الأشخاص الذين سيحصلون على نسخة من هذا القرار.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _copyToController,
                        decoration: AppDecorations.inputDecoration(
                          '',
                          hint: 'أضف بالاسم والمنصب',
                        ).copyWith(labelText: null),
                        onSubmitted: (_) => _addCopyTo(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _addCopyTo,
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppColors.primaryTeal),
                    ),
                  ],
                ),
                if (_copyToList.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _copyToList
                        .map((String name) => Chip(
                              label: Text(name,
                                  style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () =>
                                  setState(() => _copyToList.remove(name)),
                              backgroundColor:
                                  AppColors.primaryTeal.withValues(alpha: 0.08),
                              side: BorderSide(
                                  color: AppColors.primaryTeal
                                      .withValues(alpha: 0.3)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Required Signatures
          _buildSectionCard(
            icon: Icons.draw_outlined,
            title: 'الموقعون المطلوبون',
            subtitle: 'أضف الأشخاص الذين يجب عليهم التوقيع على هذا القرار.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _signatorySearchController,
                  onChanged: _onSignatorySearchChanged,
                  decoration: AppDecorations.inputDecoration(
                    '',
                    hint: 'ابحث بالاسم...',
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AppColors.textMuted),
                  ).copyWith(labelText: null),
                ),
                if (_showUserResults)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _filteredUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('لم يتم العثور على مستخدمين.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _filteredUsers.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(
                                        height: 1, color: AppColors.divider),
                            itemBuilder: (BuildContext context, int index) {
                              final Map<String, dynamic> user =
                                  _filteredUsers[index];
                              final String name = user['fullName'] as String? ??
                                  user['email'] as String? ??
                                  'User #${user['id']}';
                              final String email =
                                  user['email'] as String? ?? '';
                              return InkWell(
                                onTap: () => _addSignatory(user),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primaryTeal
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          name.isNotEmpty
                                              ? name.characters.first
                                              : '?',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryTeal),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(name,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColors.textPrimary)),
                                            if (email.isNotEmpty)
                                              Text(email,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.add_circle_outline,
                                          size: 18, color: AppColors.primaryTeal),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                if (_loadingUsers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_selectedSignatories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('لم تتم إضافة موقعين بعد.',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.7))),
                    ),
                  )
                else ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_selectedSignatories.length} موقع مضاف',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedSignatories
                      .map((Map<String, dynamic> user) {
                    final String name = user['fullName'] as String? ??
                        user['email'] as String? ??
                        'User #${user['id']}';
                    final String email = user['email'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pageBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                AppColors.primaryTeal.withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty
                                  ? name.characters.first
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryTeal),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary)),
                                if (email.isNotEmpty)
                                  Text(email,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _removeSignatory(user['id'] as int),
                            icon: const Icon(Icons.close,
                                size: 16, color: AppColors.textMuted),
                            splashRadius: 16,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bottom action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('إلغاء'),
              ),
              const SizedBox(width: 10),
              WaveScrollButton(
                text: 'محفظة القرارات',
                onPressed: _isSubmitting ? null : () => _submit(MeetingStatus.draft),
                backgroundColor: AppColors.primaryTeal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  DocumentPreviewData _buildPreviewData() {
    String issueDateFormatted = '';
    if (_selectedIssueDate != null) {
      issueDateFormatted =
          '${_selectedIssueDate!.day}/${_selectedIssueDate!.month}/${_selectedIssueDate!.year}';
    }
    String meetingDateFormatted = '';
    if (_selectedMeetingDate != null) {
      meetingDateFormatted =
          '${_selectedMeetingDate!.year}/${_selectedMeetingDate!.month}/${_selectedMeetingDate!.day}';
    }

    return DocumentPreviewData(
      meetingTitle: _meetingTitleController.text.trim(),
      referenceNumber: _referenceNumberController.text.trim(),
      issueDate: issueDateFormatted,
      recipients: List<String>.from(_recipients),
      councilType: _selectedCouncilType,
      sessionNumber: _sessionNumberController.text.trim(),
      academicYear: _academicYearController.text.trim(),
      meetingDate: meetingDateFormatted,
      decisionNumber: _decisionNumberController.text.trim(),
      decisionText: _decisionTextController.text.trim(),
      copyToList: List<String>.from(_copyToList),
    );
  }

  Widget _buildDocumentPreview() {
    return Container(
      margin: const EdgeInsets.only(right: 24, top: 24, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                  bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'معاينة الوثيقة الرسمية',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'تحديث فوري',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusPending),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: DocumentPreview(data: _buildPreviewData()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addRecipient() {
    final String text = _newRecipientController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _recipients.add(text);
      _newRecipientController.clear();
    });
  }

  void _addCopyTo() {
    final String text = _copyToController.text.trim();
    if (text.isEmpty) return;
    if (_copyToList.contains(text)) {
      _showSnack('تمت الإضافة مسبقاً.');
      return;
    }
    setState(() {
      _copyToList.add(text);
      _copyToController.clear();
    });
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildSearchResultTile(_SearchableMeeting meeting) {
    final String formattedDate =
        DateFormat('MMM dd, yyyy').format(meeting.date);
    final String status = _statusLabel(meeting.status);
    final Color statusClr = _statusColor(meeting.status);

    return InkWell(
      onTap: () => _showRelationshipPicker(meeting),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined,
                  size: 16, color: AppColors.primaryTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meeting.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.folder_outlined,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(meeting.type,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusClr.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusClr)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRelationshipPicker(_SearchableMeeting meeting) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('نوع الارتباط',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ما علاقة "${meeting.title}" بهذا الاجتماع؟',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              _relationshipOption(ctx, meeting, 'متابعة',
                  Icons.arrow_forward_rounded, 'هذا الاجتماع يكمل الاجتماع المحدد'),
              const SizedBox(height: 8),
              _relationshipOption(ctx, meeting, 'ذو صلة', Icons.link,
                  'يشترك في مواضيع أو قرارات مع هذا الاجتماع'),
              const SizedBox(height: 8),
              _relationshipOption(ctx, meeting, 'يحل محل',
                  Icons.swap_horiz_rounded, 'هذا الاجتماع يلغي أو يحل محل المحدد'),
            ],
          ),
        );
      },
    );
  }

  Widget _relationshipOption(BuildContext ctx, _SearchableMeeting meeting,
      String type, IconData icon, String description) {
    return InkWell(
      onTap: () {
        Navigator.of(ctx).pop();
        _addConnection(meeting, type);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(_AddedConnection conn) {
    final String formattedDate =
        DateFormat('MMM dd, yyyy').format(conn.meeting.date);
    final String status = _statusLabel(conn.meeting.status);
    final Color statusClr = _statusColor(conn.meeting.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined,
                size: 17, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conn.meeting.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(formattedDate,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusClr.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusClr)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(conn.relationshipType,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryTeal)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeConnection(conn.meeting.id),
            icon:
                const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.cardWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 8),
              ],
              Text(title, style: AppTextStyles.heading3),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SearchableMeeting {
  final int id;
  final String title;
  final DateTime date;
  final int status;
  final String type;

  const _SearchableMeeting({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.type,
  });
}

class _AddedConnection {
  final _SearchableMeeting meeting;
  final String relationshipType;

  const _AddedConnection({
    required this.meeting,
    required this.relationshipType,
  });
}
