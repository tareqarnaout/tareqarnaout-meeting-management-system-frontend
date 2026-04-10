import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/meeting.dart';
import '../services/meeting_service.dart';
import '../widgets/status_badge.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MeetingService _meetingService = MeetingService();

  List<ArchivedMeeting> _meetings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final List<ArchivedMeeting> meetings =
        await _meetingService.getArchivedMeetings();

    if (!mounted) return;

    setState(() {
      _meetings = meetings;
      _isLoading = false;
      if (meetings.isEmpty) {
        _errorMessage = 'No archived meetings found.';
      }
    });
  }

  List<ArchivedMeeting> get _filteredMeetings {
    final String query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _meetings;
    return _meetings.where((ArchivedMeeting m) {
      return m.createdBy.toLowerCase().contains(query) ||
          DateFormat('MMM dd, yyyy').format(m.date).toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBg,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Archived Meetings', style: AppTextStyles.heading1),
            const SizedBox(height: 4),
            Text(
              'Browse and search all finalized meeting documents.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Search and filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.cardWithBorder,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: AppDecorations.inputDecoration(
                        '',
                        hint: 'Search by creator or date...',
                        suffixIcon: const Icon(Icons.search,
                            size: 18, color: AppColors.textMuted),
                      ).copyWith(labelText: null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _loadMeetings,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data table
            Expanded(
              child: Container(
                decoration: AppDecorations.cardWithBorder,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null && _meetings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.archive_outlined,
                                    size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(_errorMessage!,
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Table header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.pageBg,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _tableHeader('ID', flex: 1),
                                    _tableHeader('Date', flex: 3),
                                    _tableHeader('Signatures Needed', flex: 2),
                                    _tableHeader('Status', flex: 2),
                                    _tableHeader('Created By', flex: 3),
                                    _tableHeader('Actions', flex: 2),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: AppColors.border),
                              // Table rows
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _filteredMeetings.length,
                                  separatorBuilder: (_, _) => const Divider(
                                      height: 1, color: AppColors.border),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final ArchivedMeeting m =
                                        _filteredMeetings[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          // ID
                                          Expanded(
                                            flex: 1,
                                            child: Text('${m.id}',
                                                style:
                                                    AppTextStyles.bodySmall),
                                          ),
                                          // Date
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                                DateFormat('MMM dd, yyyy')
                                                    .format(m.date),
                                                style:
                                                    AppTextStyles.bodySmall),
                                          ),
                                          // Signatures Needed
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                                '${m.signatureNeededCount}',
                                                style:
                                                    AppTextStyles.bodySmall),
                                          ),
                                          // Status
                                          Expanded(
                                            flex: 2,
                                            child: StatusBadge.fromStatus(
                                                m.status),
                                          ),
                                          // Created By
                                          Expanded(
                                            flex: 3,
                                            child: Text(m.createdBy,
                                                style:
                                                    AppTextStyles.bodySmall),
                                          ),
                                          // Actions
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons
                                                          .visibility_outlined,
                                                      size: 16,
                                                      color: AppColors
                                                          .primaryBlue),
                                                  onPressed: () {},
                                                  tooltip: 'View',
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 28,
                                                          minHeight: 28),
                                                  padding: EdgeInsets.zero,
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.hub_outlined,
                                                      size: 16,
                                                      color: AppColors
                                                          .primaryTeal),
                                                  onPressed: () {
                                                    context.go(
                                                        '/graph?meeting=${m.id}');
                                                  },
                                                  tooltip:
                                                      'View in Decision Graph',
                                                  constraints:
                                                      const BoxConstraints(
                                                          minWidth: 28,
                                                          minHeight: 28),
                                                  padding: EdgeInsets.zero,
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
                              // Pagination
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                      top:
                                          BorderSide(color: AppColors.border)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        'Showing ${_filteredMeetings.length} of ${_meetings.length} meetings',
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
