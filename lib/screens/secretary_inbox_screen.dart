import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../models/meeting_note.dart';
import '../services/meeting_notes_service.dart';

class SecretaryInboxScreen extends StatefulWidget {
  const SecretaryInboxScreen({super.key});

  static const double _webMaxWidth = 1400;
  static const double _desktopBreakpoint = 1100;

  @override
  State<SecretaryInboxScreen> createState() => _SecretaryInboxScreenState();
}

class _SecretaryInboxScreenState extends State<SecretaryInboxScreen> {
  final MeetingNotesService _service = MeetingNotesService();
  final TextEditingController _searchController = TextEditingController();

  List<MeetingNote> _notes = <MeetingNote>[];
  MeetingNote? _selectedNote;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final List<MeetingNote> notes = await _service.getAllNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _isLoading = false;
      if (notes.isNotEmpty && _selectedNote == null) {
        _selectedNote = notes.first;
      }
    });
  }

  List<MeetingNote> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    final String q = _searchQuery.toLowerCase();
    return _notes.where((MeetingNote note) {
      final NoteContent? content = note.content;
      if (content != null) {
        return content.title.toLowerCase().contains(q) ||
            (content.titleAr?.toLowerCase().contains(q) ?? false);
      }
      return note.notes?.toLowerCase().contains(q) ?? false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop =
            constraints.maxWidth >= SecretaryInboxScreen._desktopBreakpoint;
        final EdgeInsets pagePadding = EdgeInsets.all(isDesktop ? 24 : 16);

        Widget body;

        if (_isLoading) {
          body = const Expanded(
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryTeal)),
          );
        } else if (_notes.isEmpty) {
          body = Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.inbox_outlined,
                        size: 32, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(height: 16),
                  const Text('No meeting notes yet',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  const Text(
                    'Notes from minute takers will appear here.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          );
        } else if (isDesktop) {
          body = Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 380,
                  child: _NoteListPanel(
                    notes: _filteredNotes,
                    selectedNote: _selectedNote,
                    searchController: _searchController,
                    onSearch: (String q) =>
                        setState(() => _searchQuery = q),
                    onSelectNote: (MeetingNote n) =>
                        setState(() => _selectedNote = n),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: _selectedNote != null
                      ? _DocumentPanel(note: _selectedNote!)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 300,
                  child: _selectedNote != null
                      ? _MetadataPanel(note: _selectedNote!)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        } else {
          body = Expanded(
            child: ScrollConfiguration(
              behavior: const _InboxScrollBehavior(),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _NoteListPanel(
                      notes: _filteredNotes,
                      selectedNote: _selectedNote,
                      searchController: _searchController,
                      onSearch: (String q) =>
                          setState(() => _searchQuery = q),
                      onSelectNote: (MeetingNote n) =>
                          setState(() => _selectedNote = n),
                      isMobile: true,
                    ),
                    if (_selectedNote != null) ...[
                      const SizedBox(height: 20),
                      _DocumentPanel(note: _selectedNote!),
                      const SizedBox(height: 20),
                      _MetadataPanel(note: _selectedNote!),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InboxHeader(
              noteCount: _notes.length,
            ),
            const SizedBox(height: 20),
            body,
          ],
        );

        if (kIsWeb) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: SecretaryInboxScreen._webMaxWidth),
              child: content,
            ),
          );
        }

        return Container(
          color: AppColors.pageBg,
          child: Padding(
            padding: pagePadding,
            child: content,
          ),
        );
      },
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _InboxHeader extends StatelessWidget {
  final int noteCount;

  const _InboxHeader({
    required this.noteCount,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget breadcrumbs = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: AppTextStyles.bodySmall,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tagBlueBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Secretary Inbox',
                style: AppTextStyles.tag
                    .copyWith(color: AppColors.primaryTeal),
              ),
            ),
            if (noteCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusDraft.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$noteCount new',
                  style: AppTextStyles.tag
                      .copyWith(color: AppColors.statusDraft),
                ),
              ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            breadcrumbs,
            const SizedBox(height: 10),
            const Text(
              'Meeting Notes from Minute Takers',
              style: AppTextStyles.pageTitle,
            ),
          ],
        );
      },
    );
  }
}

// ── Note list panel ────────────────────────────────────────────────────────

class _NoteListPanel extends StatelessWidget {
  final List<MeetingNote> notes;
  final MeetingNote? selectedNote;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<MeetingNote> onSelectNote;
  final bool isMobile;

  const _NoteListPanel({
    required this.notes,
    required this.selectedNote,
    required this.searchController,
    required this.onSearch,
    required this.onSelectNote,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget searchBar = Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search notes...',
              hintStyle: AppTextStyles.bodySmall,
              prefixIcon: const Icon(Icons.search,
                  size: 18, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('All',
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchBar,
          const SizedBox(height: 12),
          ...notes.map((MeetingNote note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _NoteCard(
                  note: note,
                  isSelected: selectedNote?.id == note.id,
                  onTap: () => onSelectNote(note),
                ),
              )),
        ],
      );
    }

    return Column(
      children: [
        searchBar,
        const SizedBox(height: 12),
        Expanded(
          child: ScrollConfiguration(
            behavior: const _InboxScrollBehavior(),
            child: ListView.separated(
              itemCount: notes.length,
              separatorBuilder: (BuildContext _, int _a) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final MeetingNote note = notes[index];
                return _NoteCard(
                  note: note,
                  isSelected: selectedNote?.id == note.id,
                  onTap: () => onSelectNote(note),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Note card ──────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final MeetingNote note;
  final bool isSelected;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final NoteContent? content = note.content;
    final String title = content?.title ?? 'Untitled Note';
    final String titleAr = content?.titleAr ?? '';
    final int attendeeCount =
        content?.attendees.length ?? note.attendeeIds.length;
    final int duration = content?.durationMinutes ?? 0;
    final String recorderName =
        content?.recorderName ?? 'Recorder #${note.recorderId}';
    final String dateStr = DateFormat('yyyy-MM-dd').format(note.date);
    final String timeStr = DateFormat('HH:mm').format(note.date);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryTeal
                : AppColors.border.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        AppColors.primaryTeal.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppColors.statusDraft.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'New',
                    style: AppTextStyles.tag
                        .copyWith(color: AppColors.statusDraft),
                  ),
                ),
                const Spacer(),
                Text(timeStr, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            if (titleAr.isNotEmpty)
              Text(
                titleAr,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: ui.TextDirection.rtl,
              ),
            if (titleAr.isNotEmpty) const SizedBox(height: 2),
            Text(
              title,
              style: titleAr.isEmpty
                  ? AppTextStyles.bodyMedium
                  : AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(dateStr, style: AppTextStyles.caption),
                if (duration > 0) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${duration}m',
                      style: AppTextStyles.caption),
                ],
                const SizedBox(width: 12),
                const Icon(Icons.people_outline,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('$attendeeCount',
                    style: AppTextStyles.caption),
              ],
            ),
            if (content?.meetingType != null && content!.meetingType!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.tagBlueBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      content.meetingType!,
                      style: AppTextStyles.tag
                          .copyWith(color: AppColors.primaryTeal),
                      textDirection: ui.TextDirection.rtl,
                    ),
                  ),
                  if (content.department != null && content.department!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        content.department!,
                        style: AppTextStyles.caption,
                        textDirection: ui.TextDirection.rtl,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'من $recorderName',
              style: AppTextStyles.caption,
              textDirection: ui.TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Document panel ─────────────────────────────────────────────────────────

class _DocumentPanel extends StatelessWidget {
  final MeetingNote note;

  const _DocumentPanel({required this.note});

  @override
  Widget build(BuildContext context) {
    final NoteContent? content = note.content;

    if (content == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.card,
        child: SelectableText(
          note.notes ?? 'No content available.',
          style: AppTextStyles.body,
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const _InboxScrollBehavior(),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppDecorations.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildUniversityHeader(),
              const SizedBox(height: 16),
              Container(height: 2, color: AppColors.primaryTeal),
              const SizedBox(height: 20),
              Text(
                'MEETING NOTES — MINUTE TAKER SUBMISSION',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'محضر ملاحظات الاجتماع',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
                textAlign: TextAlign.center,
                textDirection: ui.TextDirection.rtl,
              ),
              const SizedBox(height: 6),
              Text(
                content.titleAr ?? content.title,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                textDirection: ui.TextDirection.rtl,
              ),
              const SizedBox(height: 24),
              _buildMetadataTable(content),
              const SizedBox(height: 28),
              _buildAttendeesSection(content),
              const SizedBox(height: 28),
              _buildDiscussionSection(content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityHeader() {
    final NoteContent? content = note.content;
    final String department = content?.department ?? 'هندسة البرمجيات';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRINCESS SUMAYA UNIVERSITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'FOR TECHNOLOGY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryTeal.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/psutLogo.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
              errorBuilder: (BuildContext _c, Object _e, StackTrace? _s) => const Icon(
                Icons.school,
                size: 28,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'الأميرة سمية للتكنولوجيا',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textDirection: ui.TextDirection.rtl,
              ),
              Text(
                'قسم $department',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                textDirection: ui.TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataTable(NoteContent content) {
    final List<NoteAttendee> present =
        content.attendees.where((NoteAttendee a) => a.isPresent).toList();
    final String dateStr = DateFormat('d/M/yyyy').format(note.date);
    final String meetingType = content.meetingType ?? '—';
    final String department = content.department ?? '—';

    return Table(
      border: TableBorder.all(color: AppColors.border, width: 1),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceMuted),
          children: [
            _tableCell('التاريخ',
                isHeader: true),
            _tableCell('المدة',
                isHeader: true),
            _tableCell(
                'الحاضرون',
                isHeader: true),
            _tableCell(
                'مسؤول المحاضر',
                isHeader: true),
          ],
        ),
        TableRow(
          children: [
            _tableCell(dateStr),
            _tableCell(content.durationMinutes > 0
                ? '${content.durationMinutes} دقيقة'
                : '—'),
            _tableCell('${present.length}'),
            _tableCell(content.recorderName ?? '—'),
          ],
        ),
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceMuted),
          children: [
            _tableCell('نوع المجلس',
                isHeader: true),
            _tableCell('القسم',
                isHeader: true),
            _tableCell('', isHeader: true),
            _tableCell('', isHeader: true),
          ],
        ),
        TableRow(
          children: [
            _tableCell(meetingType),
            _tableCell(department),
            _tableCell(''),
            _tableCell(''),
          ],
        ),
      ],
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: isHeader
            ? AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              )
            : AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.rtl,
      ),
    );
  }

  Widget _buildAttendeesSection(NoteContent content) {
    final List<NoteAttendee> present =
        content.attendees.where((NoteAttendee a) => a.isPresent).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          1,
          'ATTENDEES',
          'الحاضرون',
        ),
        const SizedBox(height: 14),
        if (present.isEmpty)
          Text('No attendees recorded.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary))
        else
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(present.length, (int i) {
              final NoteAttendee a = present[i];
              return SizedBox(
                width: 280,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${a.name}  —  ${a.role}',
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildDiscussionSection(NoteContent content) {
    if (content.transcript.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            2,
            'DISCUSSION',
            'مجريات النقاش',
          ),
          const SizedBox(height: 14),
          Text(
            'No discussion entries recorded.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          2,
          'DISCUSSION',
          'مجريات النقاش',
        ),
        const SizedBox(height: 14),
        if (content.agenda.isNotEmpty)
          ...content.agenda.asMap().entries.map(
              (MapEntry<int, NoteAgendaItem> entry) {
            final int idx = entry.key;
            final NoteAgendaItem item = entry.value;
            final int entriesPerItem =
                content.transcript.length ~/ content.agenda.length;
            final int start = idx * entriesPerItem;
            final int end = idx == content.agenda.length - 1
                ? content.transcript.length
                : start + entriesPerItem;
            final List<NoteTranscriptEntry> itemEntries =
                content.transcript.sublist(
              start.clamp(0, content.transcript.length),
              end.clamp(0, content.transcript.length),
            );
            return _buildAgendaSubSection(
              '${item.index}',
              item.title,
              itemEntries,
            );
          })
        else
          ...content.transcript.map(
              (NoteTranscriptEntry entry) =>
                  _buildTranscriptRow(entry)),
      ],
    );
  }

  Widget _buildAgendaSubSection(
    String number,
    String title,
    List<NoteTranscriptEntry> entries,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '2.$number',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.primaryTeal),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entries.length} statements',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.map((NoteTranscriptEntry entry) =>
              _buildTranscriptRow(entry)),
        ],
      ),
    );
  }

  Widget _buildTranscriptRow(NoteTranscriptEntry entry) {
    String timeStr = entry.timestamp;
    try {
      final DateTime dt = DateTime.parse(entry.timestamp);
      timeStr = DateFormat('HH:mm:ss').format(dt);
    } catch (_) {}

    final List<String> parts = entry.speaker.split(' ');
    String initials = '';
    if (parts.length >= 2) {
      initials =
          '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      initials = parts[0]
          .substring(0, parts[0].length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              timeStr,
              style: AppTextStyles.caption
                  .copyWith(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 14,
            backgroundColor:
                AppColors.primaryTeal.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.speaker}:',
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.text,
                  style: AppTextStyles.body,
                  textDirection: ui.TextDirection.rtl,
                ),
                if (entry.take != null &&
                    entry.take!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tagGreenBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.note_outlined,
                            size: 14,
                            color: AppColors.primaryTeal),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(entry.take!,
                              style: AppTextStyles.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      int number, String labelEn, String labelAr) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primaryTeal,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          labelEn,
          style: AppTextStyles.caption.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          labelAr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textDirection: ui.TextDirection.rtl,
        ),
      ],
    );
  }
}

// ── Metadata panel ─────────────────────────────────────────────────────────

class _MetadataPanel extends StatelessWidget {
  final MeetingNote note;

  const _MetadataPanel({required this.note});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _InboxScrollBehavior(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _SpeakerActivityCard(note: note),
            const SizedBox(height: 16),
            _ActionItemsCard(note: note),
            const SizedBox(height: 16),
            const _NextStepCard(),
          ],
        ),
      ),
    );
  }
}

// ── Speaker activity ───────────────────────────────────────────────────────

class _SpeakerActivityCard extends StatelessWidget {
  final MeetingNote note;

  const _SpeakerActivityCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final NoteContent? content = note.content;

    final Map<String, int> speakerCounts = <String, int>{};
    if (content != null) {
      for (final NoteTranscriptEntry entry in content.transcript) {
        if (entry.speaker.isNotEmpty) {
          speakerCounts[entry.speaker] =
              (speakerCounts[entry.speaker] ?? 0) + 1;
        }
      }
    }

    final List<MapEntry<String, int>> sorted =
        speakerCounts.entries.toList()
          ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
              b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_outlined,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text('Speaker Activity',
                  style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 14),
          if (sorted.isEmpty)
            const Text('No speaker data available.',
                style: AppTextStyles.bodySmall)
          else
            ...sorted.map((MapEntry<String, int> entry) {
              final List<String> nameParts = entry.key.split(' ');
              String initials = '';
              if (nameParts.length >= 2) {
                initials =
                    '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'
                        .toUpperCase();
              } else if (nameParts.isNotEmpty &&
                  nameParts[0].isNotEmpty) {
                initials = nameParts[0]
                    .substring(
                        0, nameParts[0].length >= 2 ? 2 : 1)
                    .toUpperCase();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryTeal
                          .withValues(alpha: 0.12),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(entry.key,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Action items ───────────────────────────────────────────────────────────

class _ActionItemsCard extends StatelessWidget {
  final MeetingNote note;

  const _ActionItemsCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final NoteContent? content = note.content;
    final List<NoteTranscriptEntry> actions = content?.transcript
            .where((NoteTranscriptEntry e) =>
                e.take != null && e.take!.isNotEmpty)
            .toList() ??
        <NoteTranscriptEntry>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_outlined,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Text('Action Items',
                  style: AppTextStyles.sectionTitle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${actions.length}',
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (actions.isEmpty)
            const Text('No action items identified.',
                style: AppTextStyles.bodySmall)
          else
            ...actions
                .map((NoteTranscriptEntry action) {
              String timeStr = '';
              try {
                final DateTime dt =
                    DateTime.parse(action.timestamp);
                timeStr = DateFormat('HH:mm:ss').format(dt);
              } catch (_) {
                timeStr = action.timestamp;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFFD4B8)),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.take!,
                      style: AppTextStyles.bodySmall,
                      textDirection: ui.TextDirection.rtl,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: AppTextStyles.caption
                              .copyWith(
                                  color:
                                      AppColors.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          action.speaker,
                          style: AppTextStyles.caption
                              .copyWith(
                                  color: AppColors
                                      .primaryTeal),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Next step ──────────────────────────────────────────────────────────────

class _NextStepCard extends StatelessWidget {
  const _NextStepCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tagBlueBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primaryTeal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 18, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Text(
                'NEXT STEP',
                style: AppTextStyles.sectionTitle
                    .copyWith(color: AppColors.primaryTeal),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Use these notes to draft the official decision document. Action items and tagged statements will pre-fill the editor.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Scroll behaviour ───────────────────────────────────────────────────────

class _InboxScrollBehavior extends MaterialScrollBehavior {
  const _InboxScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
