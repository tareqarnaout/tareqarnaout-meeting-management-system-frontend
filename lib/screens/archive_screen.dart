import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/meeting.dart';
import '../services/meeting_service.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MeetingService _meetingService = MeetingService();

  List<ArchivedMeeting> _meetings = [];
  List<int>? _rankedIds;
  bool _isLoading = true;
  bool _isSearching = false;
  Timer? _debounce;

  String _typeFilter = 'All Types';
  String _departmentFilter = 'All Departments';

  // Fallback sample data when backend is unavailable
  static final List<ArchivedMeeting> _sampleMeetings = [
    ArchivedMeeting(id: 1, title: 'Q3 Department Review', department: 'Computer Science', date: DateTime(2025, 10, 10), type: 'Departmental', signedCount: 8, archivedDate: DateTime(2025, 10, 12), signatureNeededCount: 8, status: 2, createdBy: 'Dr. Abdulla Qusef'),
    ArchivedMeeting(id: 2, title: 'Lab Equipment Procurement', department: 'Computer Science', date: DateTime(2025, 10, 5), type: 'Committee', signedCount: 5, archivedDate: DateTime(2025, 10, 7), signatureNeededCount: 5, status: 2, createdBy: 'Dr. Ahmad Al-Ali'),
    ArchivedMeeting(id: 3, title: 'Curriculum Committee Meeting', department: 'Computer Science', date: DateTime(2025, 9, 28), type: 'Committee', signedCount: 4, archivedDate: DateTime(2025, 9, 30), signatureNeededCount: 4, status: 2, createdBy: 'Dr. Mohammad Al-Hassan'),
    ArchivedMeeting(id: 4, title: 'Faculty Hiring Committee', department: 'Computer Science', date: DateTime(2025, 9, 20), type: 'Hiring', signedCount: 6, archivedDate: DateTime(2025, 9, 22), signatureNeededCount: 6, status: 2, createdBy: 'Dr. Abdulla Qusef'),
    ArchivedMeeting(id: 5, title: 'Budget Planning Session', department: 'Computer Science', date: DateTime(2025, 9, 15), type: 'Budget', signedCount: 4, archivedDate: DateTime(2025, 9, 17), signatureNeededCount: 4, status: 2, createdBy: 'Dr. Fatima Al-Khaldi'),
    ArchivedMeeting(id: 6, title: 'Graduate Program Review', department: 'Computer Science', date: DateTime(2025, 9, 8), type: 'Departmental', signedCount: 4, archivedDate: DateTime(2025, 9, 10), signatureNeededCount: 4, status: 2, createdBy: 'Dr. Khalid Al-Salem'),
    ArchivedMeeting(id: 7, title: 'Research Collaboration Planning', department: 'Computer Science', date: DateTime(2025, 8, 30), type: 'Faculty', signedCount: 3, archivedDate: DateTime(2025, 9, 1), signatureNeededCount: 3, status: 2, createdBy: 'Dr. Nora Al-Marri'),
    ArchivedMeeting(id: 8, title: 'Safety Committee Annual Review', department: 'Computer Science', date: DateTime(2025, 8, 25), type: 'Committee', signedCount: 5, archivedDate: DateTime(2025, 8, 27), signatureNeededCount: 5, status: 2, createdBy: 'Dr. Youssef Al-Nasser'),
  ];

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
    });

    final List<ArchivedMeeting> meetings =
        await _meetingService.getArchivedMeetings();

    if (!mounted) return;

    setState(() {
      _meetings = meetings.isNotEmpty ? meetings : _sampleMeetings;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final String query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _rankedIds = null;
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() => _isSearching = true);
    final List<int>? ids = await _meetingService.searchMeetings(query);
    if (!mounted) return;
    if (_searchController.text.trim() != query) return;

    setState(() {
      _rankedIds = ids ?? <int>[];
      _isSearching = false;
    });
  }

  List<ArchivedMeeting> get _filteredMeetings {
    List<ArchivedMeeting> result;

    if (_rankedIds != null) {
      final Map<int, ArchivedMeeting> byId = <int, ArchivedMeeting>{
        for (final ArchivedMeeting m in _meetings) m.id: m,
      };
      result = <ArchivedMeeting>[
        for (final int id in _rankedIds!)
          if (byId[id] != null) byId[id]!,
      ];
    } else {
      final String query = _searchController.text.trim().toLowerCase();
      result = _meetings.where((ArchivedMeeting m) {
        if (query.isNotEmpty &&
            !m.title.toLowerCase().contains(query) &&
            !m.department.toLowerCase().contains(query) &&
            !m.type.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }).toList();
    }

    if (_typeFilter != 'All Types') {
      result = result
          .where((ArchivedMeeting m) => m.type == _typeFilter)
          .toList();
    }
    if (_departmentFilter != 'All Departments') {
      result = result
          .where((ArchivedMeeting m) => m.department == _departmentFilter)
          .toList();
    }

    return result;
  }

  List<String> get _availableTypes {
    final Set<String> types =
        _meetings.map((ArchivedMeeting m) => m.type).where((String t) => t.isNotEmpty).toSet();
    return ['All Types', ...types];
  }

  List<String> get _availableDepartments {
    final Set<String> depts =
        _meetings.map((ArchivedMeeting m) => m.department).where((String d) => d.isNotEmpty).toSet();
    return ['All Departments', ...depts];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ArchivedMeeting> meetings = _filteredMeetings;
    final DateFormat dateFmt = DateFormat('MMM dd, yyyy');

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        return Container(
          color: AppColors.pageBg,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Archived Meetings', style: AppTextStyles.heading1),
                const SizedBox(height: 4),
                const Text(
                  'Browse and search all finalized meeting summaries',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Search & Filter card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.cardWithBorder,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Search & Filter',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      const Text(
                        'Find specific meeting summaries using search and filters',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: AppDecorations.inputDecoration(
                          '',
                          hint: 'Search by title, keywords, or topics...',
                          prefixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.search,
                                  size: 18, color: AppColors.textMuted),
                        ).copyWith(labelText: null),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: _typeFilter,
                              items: _availableTypes,
                              onChanged: (String? v) => setState(
                                  () => _typeFilter = v ?? 'All Types'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdown(
                              value: _departmentFilter,
                              items: _availableDepartments,
                              onChanged: (String? v) => setState(() =>
                                  _departmentFilter = v ?? 'All Departments'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Count + Export
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Showing ${meetings.length} of ${_meetings.length} archived meetings',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Export All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Table (desktop) or Cards (mobile)
                Expanded(
                  child: Container(
                    decoration: AppDecorations.cardWithBorder,
                    clipBehavior: Clip.antiAlias,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : meetings.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.archive_outlined,
                                        size: 48,
                                        color: AppColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text(
                                      _rankedIds != null
                                          ? 'No meetings match your search.'
                                          : 'No archived meetings found.',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                  ],
                                ),
                              )
                            : isMobile
                                ? ListView.separated(
                                    itemCount: meetings.length,
                                    separatorBuilder: (BuildContext c, int i) =>
                                        const Divider(
                                            height: 1,
                                            color: AppColors.divider),
                                    itemBuilder:
                                        (BuildContext ctx, int index) =>
                                            _buildMobileCard(
                                                meetings[index], dateFmt, ctx),
                                  )
                                : _buildDesktopTable(meetings, dateFmt,
                                    context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCard(
      ArchivedMeeting m, DateFormat dateFmt, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (m.department.isNotEmpty)
                      Text(
                        m.department,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.primaryTeal),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TypeBadge(type: m.type),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(dateFmt.format(m.date), style: AppTextStyles.bodySmall),
              const SizedBox(width: 14),
              Icon(Icons.check_circle_outline,
                  size: 13, color: AppColors.statusApproved),
              const SizedBox(width: 4),
              Text('${m.signedCount} signed', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      AppColors.statusApproved.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Archived',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusApproved,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () =>
                    context.go('/graph?meeting=${m.id}'),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined,
                          size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text('View',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.download_outlined,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<ArchivedMeeting> meetings,
      DateFormat dateFmt, BuildContext context) {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: const Row(
            children: [
              Expanded(flex: 5, child: _HeaderCell('Meeting Title')),
              Expanded(flex: 3, child: _HeaderCell('Date')),
              Expanded(flex: 3, child: _HeaderCell('Type')),
              Expanded(flex: 3, child: _HeaderCell('Signatories')),
              Expanded(flex: 3, child: _HeaderCell('Archived')),
              Expanded(flex: 2, child: _HeaderCell('Status')),
              Expanded(flex: 2, child: _HeaderCell('Actions')),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: ListView.separated(
            itemCount: meetings.length,
            separatorBuilder: (BuildContext c, int i) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (BuildContext ctx, int index) {
              final ArchivedMeeting m = meetings[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (m.department.isNotEmpty)
                            Text(m.department,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primaryTeal)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(dateFmt.format(m.date),
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: _TypeBadge(type: m.type)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.statusApproved),
                          const SizedBox(width: 5),
                          Text('${m.signedCount} signed',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(dateFmt.format(m.archivedDate),
                          style: AppTextStyles.bodySmall),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.statusApproved
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Archived',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusApproved,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => ctx
                                .go('/graph?meeting=${m.id}'),
                            borderRadius: BorderRadius.circular(4),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary),
                                SizedBox(width: 4),
                                Text('View',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(4),
                            child: const Icon(Icons.download_outlined,
                                size: 16,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.textMuted),
          items: items
              .map((String s) =>
                  DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Text(
        type,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
