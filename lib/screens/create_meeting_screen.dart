import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_theme.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _attendeesController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _signatorySearchController =
      TextEditingController();
  final TextEditingController _connectionSearchController =
      TextEditingController();
  String _selectedType = 'Select meeting type';
  final List<String> _uploadedFiles = [];

  // Connection search state
  bool _showConnectionResults = false;
  List<_SearchableMeeting> _connectionSearchResults = [];
  final List<_AddedConnection> _addedConnections = [];

  // Mock data — replace with actual API call
  final List<_SearchableMeeting> _allMeetings = [
    _SearchableMeeting(id: 1, title: 'Department Budget Review', date: DateTime(2025, 10, 15), status: 2, type: 'Department'),
    _SearchableMeeting(id: 2, title: 'Monthly Staff Meeting', date: DateTime(2025, 10, 1), status: 2, type: 'Administrative'),
    _SearchableMeeting(id: 3, title: 'Faculty Curriculum Update', date: DateTime(2025, 9, 20), status: 2, type: 'Faculty'),
    _SearchableMeeting(id: 4, title: 'Committee Review Q3', date: DateTime(2025, 9, 10), status: 1, type: 'Committee'),
    _SearchableMeeting(id: 5, title: 'IT Infrastructure Planning', date: DateTime(2025, 8, 28), status: 0, type: 'Department'),
    _SearchableMeeting(id: 6, title: 'Annual Performance Review', date: DateTime(2025, 8, 15), status: 2, type: 'Administrative'),
  ];

  void _onConnectionSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _showConnectionResults = false;
        _connectionSearchResults = [];
      });
      return;
    }
    final String lowerQuery = query.toLowerCase();
    final List<int> addedIds = _addedConnections.map((_AddedConnection c) => c.meeting.id).toList();
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
      _addedConnections.add(_AddedConnection(meeting: meeting, relationshipType: relationshipType));
      _connectionSearchController.clear();
      _showConnectionResults = false;
      _connectionSearchResults = [];
    });
  }

  void _removeConnection(int meetingId) {
    setState(() {
      _addedConnections.removeWhere((_AddedConnection c) => c.meeting.id == meetingId);
    });
  }

  String _statusLabel(int status) {
    switch (status) {
      case 0: return 'Draft';
      case 1: return 'Pending';
      case 2: return 'Finalized';
      default: return 'Unknown';
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0: return AppColors.statusDraft;
      case 1: return AppColors.statusPending;
      case 2: return AppColors.statusFinalized;
      default: return AppColors.textMuted;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _attendeesController.dispose();
    _minutesController.dispose();
    _signatorySearchController.dispose();
    _connectionSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickFiles() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _uploadedFiles
            .addAll(result.files.map((PlatformFile f) => f.name));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          // Sticky header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_back_ios,
                              size: 14, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text('Create Meeting Summary',
                              style: AppTextStyles.heading2),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Draft and prepare meeting minutes for digital signatures',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/graph'),
                  icon: const Icon(Icons.hub_outlined, size: 16),
                  label: const Text('View Decision Graph'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meeting Information section
                  _buildSectionCard(
                    title: 'Meeting Information',
                    subtitle: 'Enter the basic details of the meeting.',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Meeting Title'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _titleController,
                                    decoration: AppDecorations.inputDecoration(
                                      '',
                                      hint:
                                          'e.g., Department Budget Review 2025',
                                    ).copyWith(labelText: null),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Meeting Date'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _dateController,
                                    readOnly: true,
                                    onTap: _pickDate,
                                    decoration: AppDecorations.inputDecoration(
                                      '',
                                      hint: 'MM / DD / YYYY',
                                      suffixIcon: const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: AppColors.textMuted),
                                    ).copyWith(labelText: null),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Meeting Type'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: null,
                                    hint: Text(_selectedType,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textMuted)),
                                    decoration: AppDecorations.inputDecoration(
                                            '', hint: '')
                                        .copyWith(labelText: null),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'Department',
                                          child: Text('Department')),
                                      DropdownMenuItem(
                                          value: 'Committee',
                                          child: Text('Committee')),
                                      DropdownMenuItem(
                                          value: 'Faculty',
                                          child: Text('Faculty')),
                                      DropdownMenuItem(
                                          value: 'Administrative',
                                          child: Text('Administrative')),
                                    ],
                                    onChanged: (String? value) {
                                      if (value != null) {
                                        setState(
                                            () => _selectedType = value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Attendees'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _attendeesController,
                                    decoration: AppDecorations.inputDecoration(
                                      '',
                                      hint:
                                          'e.g., Dr. Ali, Dr. Hassan, Dr. Al Ahmed',
                                    ).copyWith(labelText: null),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Meeting Summary section
                  _buildSectionCard(
                    title: 'Meeting Summary',
                    subtitle:
                        'Write or paste the meeting minutes and summary.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Meeting Minutes'),
                        const SizedBox(height: 6),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: _minutesController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              hintText:
                                  'Enter the meeting summary, discussion points, decisions made, and action items...',
                              hintStyle: TextStyle(
                                  fontSize: 13, color: AppColors.textMuted),
                              contentPadding: EdgeInsets.all(16),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Upload area
                        InkWell(
                          onTap: _pickFiles,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.border,
                                  style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined,
                                    size: 36, color: AppColors.textMuted),
                                const SizedBox(height: 8),
                                const Text(
                                  'Upload Meeting Document',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PDF, DOCX, or TXT files up to 10MB',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Browse Files',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Uploaded files list
                        if (_uploadedFiles.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ..._uploadedFiles.map(
                            (String file) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_outlined,
                                      size: 16, color: AppColors.primaryBlue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(file,
                                          style: AppTextStyles.bodySmall)),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 14),
                                    onPressed: () {
                                      setState(
                                          () => _uploadedFiles.remove(file));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Meeting Connections
                  _buildSectionCard(
                    icon: Icons.link,
                    title: 'Meeting Connections',
                    subtitle:
                        'Link this meeting to previous decisions, rules, or related meetings.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Search Previous Meetings'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _connectionSearchController,
                          onChanged: _onConnectionSearchChanged,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: 'Search by meeting title or type...',
                            prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                          ).copyWith(labelText: null),
                        ),
                        // Search results dropdown
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
                                      'No meetings found matching your search.',
                                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    itemCount: _connectionSearchResults.length,
                                    separatorBuilder: (BuildContext context, int index) =>
                                        const Divider(height: 1, color: AppColors.divider),
                                    itemBuilder: (BuildContext context, int index) {
                                      final _SearchableMeeting meeting = _connectionSearchResults[index];
                                      return _buildSearchResultTile(meeting);
                                    },
                                  ),
                          ),
                        const SizedBox(height: 16),
                        // Added connections list
                        if (_addedConnections.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  Icon(Icons.link_off, size: 28, color: AppColors.textMuted.withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No connections added yet. Use the search above to link related meetings.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_addedConnections.length} connection${_addedConnections.length > 1 ? 's' : ''} added',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ..._addedConnections.map((_AddedConnection conn) =>
                                  _buildConnectionCard(conn)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Required Signatures
                  _buildSectionCard(
                    title: 'Required Signatures',
                    subtitle:
                        'Select professors who need to review and sign this summary.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Search and Add Signatories'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _signatorySearchController,
                          decoration: AppDecorations.inputDecoration(
                            '',
                            hint: 'Search by name or department...',
                            suffixIcon: const Icon(Icons.search,
                                size: 18, color: AppColors.textMuted),
                          ).copyWith(labelText: null),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No signatories selected yet. Use the search above to add signatories.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Save Draft'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Send for Signatures'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 4),
          Text(subtitle,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
