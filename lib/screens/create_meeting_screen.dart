import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/app_theme.dart';
import '../models/meeting.dart';
import '../services/meeting_service.dart';
import '../widgets/document_preview.dart';
import '../widgets/wave_scroll_button.dart';

class CreateMeetingScreen extends StatefulWidget {
  final Meeting? editMeeting;

  const CreateMeetingScreen({super.key, this.editMeeting});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final TextEditingController _meetingTitleController = TextEditingController();
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _issueDateController =
      TextEditingController(text: DateFormat('MM/dd/yyyy').format(DateTime.now()));
  final TextEditingController _sessionNumberController =
      TextEditingController();
  final TextEditingController _academicYearController =
      TextEditingController(text: '2025/2026');
  final TextEditingController _decisionNumberController =
      TextEditingController();
  final TextEditingController _meetingDateController =
      TextEditingController(text: DateFormat('MM/dd/yyyy').format(DateTime.now()));
  final TextEditingController _decisionTextController = TextEditingController();
  final TextEditingController _connectionIdController = TextEditingController();
  final TextEditingController _signatoryNameController =
      TextEditingController(text: 'أ.د. عبدالله');
  final TextEditingController _signatoryTitleController =
      TextEditingController(text: 'رئيس القسم');

  final MeetingService _meetingService = MeetingService();

  String _selectedCouncilType = 'مجلس القسم';
  final DateTime _selectedIssueDate = DateTime.now();
  DateTime? _selectedMeetingDate = DateTime.now();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _selectedRecipients = [];
  List<Map<String, dynamic>> _filteredRecipientUsers = [];
  bool _showRecipientResults = false;
  final TextEditingController _recipientSearchController = TextEditingController();

  // Connection manual-entry state
  String _selectedRelationshipType = 'Applies';
  final List<_AddedConnection> _addedConnections = [];

  // Copy-to list (user-based)
  final List<Map<String, dynamic>> _selectedCopyTo = [];
  List<Map<String, dynamic>> _filteredCopyToUsers = [];
  bool _showCopyToResults = false;
  final TextEditingController _copyToSearchController = TextEditingController();

  // Users for required signatures
  List<Map<String, dynamic>> _allUsers = [];
  final List<Map<String, dynamic>> _selectedSignatories = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _showUserResults = false;
  bool _loadingUsers = true;
  final TextEditingController _signatorySearchController =
      TextEditingController();

  static const String _draftKey = 'meeting_draft';
  Timer? _draftDebounce;
  bool _draftLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    if (widget.editMeeting != null) {
      _prefillFromMeeting();
    } else {
      _loadDraft();
    }
    _addAutoSaveListeners();
  }

  void _addAutoSaveListeners() {
    for (final TextEditingController c in [
      _meetingTitleController,
      _referenceNumberController,
      _sessionNumberController,
      _academicYearController,
      _decisionNumberController,
      _meetingDateController,
      _decisionTextController,
      _signatoryNameController,
      _signatoryTitleController,
    ]) {
      c.addListener(_scheduleDraftSave);
    }
  }

  void _scheduleDraftSave() {
    if (!_draftLoaded || widget.editMeeting != null) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), () {
      _saveDraft();
    });
  }

  void _prefillFromMeeting() {
    final Meeting? m = widget.editMeeting;
    if (m == null) return;
    _meetingTitleController.text = m.title;
    _decisionTextController.text = m.meetingContent ?? '';
    _sessionNumberController.text = m.sessionNumber ?? '';
    _decisionNumberController.text = m.decisionNumber ?? '';
    if (m.councilType != null) _selectedCouncilType = m.councilType!;
    _selectedMeetingDate = m.meetingDate;
    _meetingDateController.text = DateFormat('MM/dd/yyyy').format(m.meetingDate);
    if (m.signatoryName != null) _signatoryNameController.text = m.signatoryName!;
    if (m.signatoryTitle != null) _signatoryTitleController.text = m.signatoryTitle!;
  }

  Future<void> _saveDraft() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> draft = {
      'title': _meetingTitleController.text,
      'referenceNumber': _referenceNumberController.text,
      'issueDate': _issueDateController.text,
      'sessionNumber': _sessionNumberController.text,
      'academicYear': _academicYearController.text,
      'decisionNumber': _decisionNumberController.text,
      'meetingDate': _meetingDateController.text,
      'decisionText': _decisionTextController.text,
      'councilType': _selectedCouncilType,
      'signatoryName': _signatoryNameController.text,
      'signatoryTitle': _signatoryTitleController.text,
      'copyToUsers': _selectedCopyTo,
      'recipients': _selectedRecipients,
      'signatories': _selectedSignatories,
      'connections': _addedConnections
          .map((_AddedConnection c) => {
                'meetingId': c.meetingId,
                'relationshipType': c.relationshipType,
              })
          .toList(),
    };
    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  Future<void> _loadDraft() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_draftKey);
    if (raw == null) {
      _draftLoaded = true;
      return;
    }
    try {
      final Map<String, dynamic> draft =
          jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _meetingTitleController.text = draft['title'] as String? ?? '';
        _referenceNumberController.text = draft['referenceNumber'] as String? ?? '';
        _sessionNumberController.text = draft['sessionNumber'] as String? ?? '';
        _academicYearController.text = draft['academicYear'] as String? ?? '2025/2026';
        _decisionNumberController.text = draft['decisionNumber'] as String? ?? '';
        _meetingDateController.text = draft['meetingDate'] as String? ?? '';
        _decisionTextController.text = draft['decisionText'] as String? ?? '';
        _selectedCouncilType = draft['councilType'] as String? ?? 'مجلس القسم';
        _signatoryNameController.text = draft['signatoryName'] as String? ?? 'أ.د. عبدالله';
        _signatoryTitleController.text = draft['signatoryTitle'] as String? ?? 'رئيس القسم';
        final List<dynamic>? copyTo = draft['copyToUsers'] as List<dynamic>?;
        if (copyTo != null) {
          _selectedCopyTo
            ..clear()
            ..addAll(copyTo.map((dynamic e) => Map<String, dynamic>.from(e as Map)));
        }
        final List<dynamic>? recipients = draft['recipients'] as List<dynamic>?;
        if (recipients != null) {
          _selectedRecipients
            ..clear()
            ..addAll(recipients.map((dynamic e) => Map<String, dynamic>.from(e as Map)));
        }
        final List<dynamic>? signatories = draft['signatories'] as List<dynamic>?;
        if (signatories != null) {
          _selectedSignatories
            ..clear()
            ..addAll(signatories.map((dynamic e) => Map<String, dynamic>.from(e as Map)));
        }
        final List<dynamic>? connections = draft['connections'] as List<dynamic>?;
        if (connections != null) {
          _addedConnections
            ..clear()
            ..addAll(connections.map((dynamic e) {
              final Map<String, dynamic> c = Map<String, dynamic>.from(e as Map);
              return _AddedConnection(
                meetingId: c['meetingId'] as int,
                relationshipType: c['relationshipType'] as String,
              );
            }));
        }
        if (_meetingDateController.text.isNotEmpty) {
          try {
            _selectedMeetingDate =
                DateFormat('MM/dd/yyyy').parse(_meetingDateController.text);
          } catch (_) {}
        }
      });
    } catch (_) {}
    _draftLoaded = true;
  }

  Future<void> _clearDraft() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
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
    _scheduleDraftSave();
  }

  void _removeSignatory(int userId) {
    setState(() {
      _selectedSignatories
          .removeWhere((Map<String, dynamic> u) => u['id'] == userId);
    });
    _scheduleDraftSave();
  }

  void _onRecipientSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _showRecipientResults = false;
        _filteredRecipientUsers = [];
      });
      return;
    }
    final String lowerQuery = query.toLowerCase();
    final List<int> selectedIds = _selectedRecipients
        .map((Map<String, dynamic> u) => u['id'] as int)
        .toList();
    setState(() {
      _filteredRecipientUsers = _allUsers.where((Map<String, dynamic> u) {
        final int id = u['id'] as int;
        final String name =
            (u['fullName'] as String? ?? u['email'] as String? ?? '')
                .toLowerCase();
        return !selectedIds.contains(id) && name.contains(lowerQuery);
      }).toList();
      _showRecipientResults = true;
    });
  }

  void _addRecipient(Map<String, dynamic> user) {
    setState(() {
      _selectedRecipients.add(user);
      _recipientSearchController.clear();
      _showRecipientResults = false;
      _filteredRecipientUsers = [];
    });
    _scheduleDraftSave();
  }

  void _removeRecipient(int userId) {
    setState(() {
      _selectedRecipients
          .removeWhere((Map<String, dynamic> u) => u['id'] == userId);
    });
    _scheduleDraftSave();
  }

  void _onCopyToSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _showCopyToResults = false;
        _filteredCopyToUsers = [];
      });
      return;
    }
    final String lowerQuery = query.toLowerCase();
    final List<int> selectedIds = _selectedCopyTo
        .map((Map<String, dynamic> u) => u['id'] as int)
        .toList();
    setState(() {
      _filteredCopyToUsers = _allUsers.where((Map<String, dynamic> u) {
        final int id = u['id'] as int;
        final String name =
            (u['fullName'] as String? ?? u['email'] as String? ?? '')
                .toLowerCase();
        return !selectedIds.contains(id) && name.contains(lowerQuery);
      }).toList();
      _showCopyToResults = true;
    });
  }

  void _addCopyToUser(Map<String, dynamic> user) {
    setState(() {
      _selectedCopyTo.add(user);
      _copyToSearchController.clear();
      _showCopyToResults = false;
      _filteredCopyToUsers = [];
    });
    _scheduleDraftSave();
  }

  void _removeCopyToUser(int userId) {
    setState(() {
      _selectedCopyTo
          .removeWhere((Map<String, dynamic> u) => u['id'] == userId);
    });
    _scheduleDraftSave();
  }

  void _addConnectionById() {
    final String raw = _connectionIdController.text.trim();
    final int? id = int.tryParse(raw);
    if (id == null || id <= 0) {
      _showSnack('يرجى إدخال رقم اجتماع صحيح.');
      return;
    }
    if (_addedConnections.any((_AddedConnection c) => c.meetingId == id)) {
      _showSnack('هذا الاجتماع مضاف بالفعل.');
      return;
    }
    setState(() {
      _addedConnections.add(_AddedConnection(
          meetingId: id, relationshipType: _selectedRelationshipType));
      _connectionIdController.clear();
    });
    _scheduleDraftSave();
  }

  void _removeConnection(int meetingId) {
    setState(() {
      _addedConnections
          .removeWhere((_AddedConnection c) => c.meetingId == meetingId);
    });
    _scheduleDraftSave();
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _meetingTitleController.dispose();
    _referenceNumberController.dispose();
    _issueDateController.dispose();
    _sessionNumberController.dispose();
    _academicYearController.dispose();
    _decisionNumberController.dispose();
    _meetingDateController.dispose();
    _decisionTextController.dispose();
    _connectionIdController.dispose();
    _copyToSearchController.dispose();
    _signatoryNameController.dispose();
    _signatoryTitleController.dispose();
    _recipientSearchController.dispose();
    _signatorySearchController.dispose();
    super.dispose();
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
      _scheduleDraftSave();
    }
  }

  Future<void> _confirmAndSend() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('إرسال الاجتماع للتوقيع',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'هل أنت متأكد من إرسال هذا الاجتماع للتوقيع؟ لن تتمكن من تعديله بعد الإرسال.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _submit(MeetingStatus.pendingApproval);
    }
  }

  Future<void> _confirmAndSaveDraft() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('حفظ المسودة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'هل تريد حفظ هذا الاجتماع كمسودة محلية؟',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _saveDraft();
      if (mounted) _showSnack('تم حفظ المسودة محلياً.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit(int status) async {
    if (_isSubmitting) return;

    if (_selectedMeetingDate == null) {
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

    const Map<String, int> _typeToInt = {
      'Applies': 0,
      'Change': 1,
      'Continue': 2,
    };

    final Meeting meeting = Meeting(
      title: meetingTitle,
      meetingDate: _selectedMeetingDate ?? DateTime.now(),
      meetingContent: _decisionTextController.text.trim(),
      status: status,
      requiredSignatures: _selectedSignatories
          .map((Map<String, dynamic> u) => u['id'] as int)
          .toList(),
      recipients: _selectedRecipients
          .map((Map<String, dynamic> u) => u['id'] as int)
          .toList(),
      sessionNumber: _sessionNumberController.text.trim(),
      decisionNumber: _decisionNumberController.text.trim(),
      councilType: _selectedCouncilType,
      relationships: _addedConnections
          .map((_AddedConnection c) => <String, dynamic>{
                'relatedMeetingId': c.meetingId,
                'type': _typeToInt[c.relationshipType] ?? 0,
              })
          .toList(),
      signatoryName: _signatoryNameController.text.trim(),
      signatoryTitle: _signatoryTitleController.text.trim(),
    );

    final bool ok = await _meetingService.createMeeting(
      meeting,
      editedMeetingId: widget.editMeeting?.id,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      await _clearDraft();
      _showSnack('تم إرسال الملخص للتوقيع.');
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
          WaveScrollButton(
            text: 'Send',
            icon: Icons.send,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting
                ? null
                : () => _confirmAndSend(),
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
                          enabled: false,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: 'mm / dd / yyyy',
                            suffixIcon: const Icon(
                                Icons.lock_outline,
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
                      if (value != null) {
                        setState(() => _selectedCouncilType = value);
                        _scheduleDraftSave();
                      }
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
            subtitle: 'ابحث وأضف الأشخاص الذين سيستلمون هذه الوثيقة.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _recipientSearchController,
                  onChanged: _onRecipientSearchChanged,
                  decoration: AppDecorations.inputDecoration(
                    '',
                    hint: 'ابحث بالاسم...',
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AppColors.textMuted),
                  ).copyWith(labelText: null),
                ),
                if (_showRecipientResults)
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
                    child: _filteredRecipientUsers.isEmpty
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
                            itemCount: _filteredRecipientUsers.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(
                                        height: 1, color: AppColors.divider),
                            itemBuilder: (BuildContext context, int index) {
                              final Map<String, dynamic> user =
                                  _filteredRecipientUsers[index];
                              final String name = user['fullName'] as String? ??
                                  user['email'] as String? ??
                                  'User #${user['id']}';
                              final String email =
                                  user['email'] as String? ?? '';
                              return InkWell(
                                onTap: () => _addRecipient(user),
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
                if (_selectedRecipients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('لم تتم إضافة مستلمين بعد.',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.7))),
                    ),
                  )
                else ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_selectedRecipients.length} مستلم مضاف',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedRecipients
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
                              name.isNotEmpty ? name.characters.first : '?',
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
                          InkWell(
                            onTap: () => _removeRecipient(user['id'] as int),
                            child: const Icon(Icons.close,
                                size: 16, color: AppColors.textMuted),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _connectionIdController,
                        keyboardType: TextInputType.number,
                        decoration: AppDecorations.inputDecoration(
                          '',
                          hint: 'رقم الاجتماع (ID)',
                          prefixIcon: const Icon(Icons.tag,
                              size: 16, color: AppColors.textMuted),
                        ).copyWith(labelText: null),
                        onSubmitted: (_) => _addConnectionById(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRelationshipType,
                            isExpanded: true,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                size: 18, color: AppColors.textMuted),
                            items: const [
                              DropdownMenuItem(
                                value: 'Applies',
                                child: Text('Applies — يطبق'),
                              ),
                              DropdownMenuItem(
                                value: 'Change',
                                child: Text('Change — يعدل'),
                              ),
                              DropdownMenuItem(
                                value: 'Continue',
                                child: Text('Continue — يكمل'),
                              ),
                            ],
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(
                                    () => _selectedRelationshipType = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _addConnectionById,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('إضافة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
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
            subtitle: 'ابحث وأضف الأشخاص الذين سيحصلون على نسخة من هذا القرار.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _copyToSearchController,
                  onChanged: _onCopyToSearchChanged,
                  decoration: AppDecorations.inputDecoration(
                    '',
                    hint: 'ابحث بالاسم...',
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AppColors.textMuted),
                  ).copyWith(labelText: null),
                ),
                if (_showCopyToResults)
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
                    child: _filteredCopyToUsers.isEmpty
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
                            itemCount: _filteredCopyToUsers.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(
                                        height: 1, color: AppColors.divider),
                            itemBuilder: (BuildContext context, int index) {
                              final Map<String, dynamic> user =
                                  _filteredCopyToUsers[index];
                              final String name = user['fullName'] as String? ??
                                  user['email'] as String? ??
                                  'User #${user['id']}';
                              final String email =
                                  user['email'] as String? ?? '';
                              return InkWell(
                                onTap: () => _addCopyToUser(user),
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
                if (_selectedCopyTo.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('لم تتم إضافة أشخاص بعد.',
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.7))),
                    ),
                  )
                else ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_selectedCopyTo.length} شخص مضاف',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedCopyTo.map((Map<String, dynamic> user) {
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
                              name.isNotEmpty ? name.characters.first : '?',
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
                          InkWell(
                            onTap: () => _removeCopyToUser(user['id'] as int),
                            child: const Icon(Icons.close,
                                size: 16, color: AppColors.textMuted),
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

          // Signatory Info
          _buildSectionCard(
            icon: Icons.person_outline,
            title: 'معلومات الموقع',
            subtitle: 'بيانات الموقع التي ستظهر في أسفل الوثيقة.',
            child: Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'المسمى الوظيفي',
                    child: TextField(
                      controller: _signatoryTitleController,
                      onChanged: (_) => setState(() {}),
                      decoration: AppDecorations.inputDecoration(
                        '',
                        hint: 'مثال: رئيس القسم',
                      ).copyWith(labelText: null),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label: 'اسم الموقع',
                    child: TextField(
                      controller: _signatoryNameController,
                      onChanged: (_) => setState(() {}),
                      decoration: AppDecorations.inputDecoration(
                        '',
                        hint: 'مثال: أ.د. عبدالله',
                      ).copyWith(labelText: null),
                    ),
                  ),
                ),
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
                text: 'Save Draft',
                onPressed: _isSubmitting ? null : () => _confirmAndSaveDraft(),
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
    final String issueDateFormatted =
        '${_selectedIssueDate.day}/${_selectedIssueDate.month}/${_selectedIssueDate.year}';
    String meetingDateFormatted = '';
    if (_selectedMeetingDate != null) {
      meetingDateFormatted =
          '${_selectedMeetingDate!.year}/${_selectedMeetingDate!.month}/${_selectedMeetingDate!.day}';
    }

    return DocumentPreviewData(
      meetingTitle: _meetingTitleController.text.trim(),
      referenceNumber: _referenceNumberController.text.trim(),
      issueDate: issueDateFormatted,
      recipients: _selectedRecipients
          .map((Map<String, dynamic> u) =>
              u['fullName'] as String? ?? u['email'] as String? ?? 'User #${u['id']}')
          .toList(),
      councilType: _selectedCouncilType,
      sessionNumber: _sessionNumberController.text.trim(),
      academicYear: _academicYearController.text.trim(),
      meetingDate: meetingDateFormatted,
      decisionNumber: _decisionNumberController.text.trim(),
      decisionText: _decisionTextController.text.trim(),
      copyToList: _selectedCopyTo
          .map((Map<String, dynamic> u) =>
              u['fullName'] as String? ?? u['email'] as String? ?? 'User #${u['id']}')
          .toList(),
      signatoryName: _signatoryNameController.text.trim(),
      signatoryTitle: _signatoryTitleController.text.trim(),
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

  Widget _buildConnectionCard(_AddedConnection conn) {
    final Color typeColor = _relationshipTypeColor(conn.relationshipType);

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
                Text('Meeting #${conn.meetingId}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(conn.relationshipType,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: typeColor)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeConnection(conn.meetingId),
            icon:
                const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Color _relationshipTypeColor(String type) {
    switch (type) {
      case 'Applies':
        return const Color(0xFF10B981);
      case 'Change':
        return const Color(0xFFF59E0B);
      case 'Continue':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.primaryTeal;
    }
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

class _AddedConnection {
  final int meetingId;
  final String relationshipType;

  const _AddedConnection({
    required this.meetingId,
    required this.relationshipType,
  });
}
