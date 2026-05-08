import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/minute_taker_models.dart';
import '../services/meeting_notes_service.dart';

// Shared timestamp formatter used by tiles and the preview dialog.
String _formatTimestamp(DateTime t) {
  final String hh = t.hour.toString().padLeft(2, '0');
  final String mm = t.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

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
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: trailing ?? const SizedBox.shrink(),
                ),
              ),
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

// ---------------------------------------------------------------------------
// Attendance
// ---------------------------------------------------------------------------

class AttendanceList extends StatelessWidget {
  final List<Attendee> attendees;
  final ValueChanged<Attendee>? onAttendeeToggle;

  const AttendanceList({
    super.key,
    required this.attendees,
    this.onAttendeeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: attendees
          .map((Attendee attendee) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AttendanceTile(
                  attendee: attendee,
                  onTap: onAttendeeToggle != null
                      ? () => onAttendeeToggle!(attendee)
                      : null,
                ),
              ))
          .toList(),
    );
  }
}

class AttendanceTile extends StatelessWidget {
  final Attendee attendee;
  final VoidCallback? onTap;

  const AttendanceTile({
    super.key,
    required this.attendee,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color avatarBg = attendee.isPresent
        ? AppColors.primaryTeal.withValues(alpha: 0.12)
        : AppColors.border.withValues(alpha: 0.4);
    final Color avatarText =
        attendee.isPresent ? AppColors.primaryTeal : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Agenda
// ---------------------------------------------------------------------------

class AgendaList extends StatelessWidget {
  final List<AgendaItem> items;
  final ValueChanged<int>? onRemove;

  const AgendaList({super.key, required this.items, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(items.length, (int i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AgendaTile(
          item: items[i],
          onRemove: onRemove != null ? () => onRemove!(i) : null,
        ),
      )),
    );
  }
}

class AgendaTile extends StatelessWidget {
  final AgendaItem item;
  final VoidCallback? onRemove;

  const AgendaTile({super.key, required this.item, this.onRemove});

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
          if (onRemove != null)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Handoff stats
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Transcript
// ---------------------------------------------------------------------------

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

class TranscriptEntryTile extends StatelessWidget {
  final TranscriptEntry entry;
  final VoidCallback onTap;

  const TranscriptEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTagged = entry.speaker.isNotEmpty;
    final Color tagBg =
        isTagged ? AppColors.tagBlueBg : AppColors.surfaceMuted;
    final Color tagText =
        isTagged ? AppColors.primaryTeal : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MinuteTag(
                  label: isTagged ? entry.speaker : 'Unassigned',
                  backgroundColor: tagBg,
                  textColor: tagText,
                ),
                const Spacer(),
                Text(_formatTimestamp(entry.timestamp),
                    style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.text, style: AppTextStyles.bodySmall),
            if (entry.take.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tagGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_outlined,
                        size: 14, color: AppColors.primaryTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(entry.take, style: AppTextStyles.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TranscriptInputBar extends StatelessWidget {
  final List<String> speakers;
  final String selectedSpeaker;
  final ValueChanged<String?> onSpeakerChanged;
  final TextEditingController controller;
  final VoidCallback onAdd;

  const TranscriptInputBar({
    super.key,
    required this.speakers,
    required this.selectedSpeaker,
    required this.onSpeakerChanged,
    required this.controller,
    required this.onAdd,
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
                  initialValue: speakers.contains(selectedSpeaker)
                      ? selectedSpeaker
                      : (speakers.isNotEmpty ? speakers.first : null),
                  items: speakers
                      .map((String s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s,
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                          ))
                      .toList(),
                  onChanged: onSpeakerChanged,
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
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
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
                onPressed: onAdd,
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

// ---------------------------------------------------------------------------
// Attendee search sheet
// ---------------------------------------------------------------------------

class AttendeeSearchSheet extends StatefulWidget {
  final Set<String> existingNames;
  final ValueChanged<Attendee> onAdd;

  const AttendeeSearchSheet({
    super.key,
    required this.existingNames,
    required this.onAdd,
  });

  @override
  State<AttendeeSearchSheet> createState() => _AttendeeSearchSheetState();
}

class _AttendeeSearchSheetState extends State<AttendeeSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final MeetingNotesService _notesService = MeetingNotesService();
  String _query = '';
  List<Attendee> _users = <Attendee>[];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final List<Attendee> users = await _notesService.fetchUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
      _error = users.isEmpty ? 'Could not load users.' : null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Attendee> get _filtered {
    final String q = _query.toLowerCase();
    return _users
        .where((Attendee a) =>
            !widget.existingNames.contains(a.name) &&
            (q.isEmpty || a.name.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;
    final List<Attendee> results = _filtered;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Attendee', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (String v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by name...',
              hintStyle: AppTextStyles.bodySmall,
              prefixIcon:
                  const Icon(Icons.search, size: 18, color: AppColors.textMuted),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _users.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = null;
                        });
                        _loadUsers();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _query.isEmpty
                      ? 'All users are already added.'
                      : 'No results for "$_query".',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (BuildContext context, int index) {
                  final Attendee a = results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primaryTeal.withValues(alpha: 0.12),
                      child: Text(
                        a.initials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    title: Text(a.name, style: AppTextStyles.bodyMedium),
                    subtitle: Text(a.role, style: AppTextStyles.caption),
                    trailing: const Icon(Icons.person_add_outlined,
                        size: 18, color: AppColors.primaryTeal),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAdd(a);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Entry editor sheet (speaker + take)
// ---------------------------------------------------------------------------

class EntryEditorSheet extends StatefulWidget {
  final TranscriptEntry entry;
  final List<String> speakers;
  final void Function(String speaker, String take) onSave;

  const EntryEditorSheet({
    super.key,
    required this.entry,
    required this.speakers,
    required this.onSave,
  });

  @override
  State<EntryEditorSheet> createState() => _EntryEditorSheetState();
}

class _EntryEditorSheetState extends State<EntryEditorSheet> {
  late String _speaker;
  late final TextEditingController _takeController;

  @override
  void initState() {
    super.initState();
    _speaker = widget.speakers.contains(widget.entry.speaker)
        ? widget.entry.speaker
        : (widget.speakers.isNotEmpty ? widget.speakers.first : '');
    _takeController = TextEditingController(text: widget.entry.take);
  }

  @override
  void dispose() {
    _takeController.dispose();
    super.dispose();
  }

  static InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryTeal),
      ),
      filled: true,
      fillColor: AppColors.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Entry', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          // Read-only transcript preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Text(
              widget.entry.text,
              style: AppTextStyles.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Text('Speaker', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _speaker.isNotEmpty ? _speaker : null,
            isExpanded: true,
            hint: Text('Select speaker', style: AppTextStyles.bodySmall),
            items: [
              ...widget.speakers.map((String s) => DropdownMenuItem<String>(
                    value: s,
                    child: Text(s,
                        overflow: TextOverflow.ellipsis, maxLines: 1),
                  )),
              DropdownMenuItem<String>(
                value: '',
                child: Text('Unassigned',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
            onChanged: (String? v) => setState(() => _speaker = v ?? ''),
            decoration: _fieldDecoration('').copyWith(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
          const SizedBox(height: 16),
          Text("Minute Taker's Note", style: AppTextStyles.caption),
          const SizedBox(height: 6),
          TextField(
            controller: _takeController,
            maxLines: 4,
            minLines: 2,
            decoration: _fieldDecoration(
                'Add your observation, summary, or clarification...'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.body),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.onSave(_speaker, _takeController.text.trim());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save', style: AppTextStyles.buttonSmall),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Handoff preview dialog
// ---------------------------------------------------------------------------

class HandoffPreviewDialog extends StatelessWidget {
  final String meetingTitle;
  final String meetingDate;
  final List<Attendee> attendees;
  final List<AgendaItem> agenda;
  final List<TranscriptEntry> entries;

  const HandoffPreviewDialog({
    super.key,
    required this.meetingTitle,
    required this.meetingDate,
    required this.attendees,
    required this.agenda,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final List<Attendee> present =
        attendees.where((Attendee a) => a.isPresent).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text('Minutes Preview',
                        style: AppTextStyles.heading3),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'This is what the secretary will receive.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Divider(height: 24),

              // Scrollable document body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + date
                      Text(meetingTitle,
                          style: AppTextStyles.pageTitle
                              .copyWith(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(meetingDate,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),

                      // Attendees
                      _SectionHeader(
                          label: 'ATTENDEES (${present.length} present)'),
                      const SizedBox(height: 8),
                      ...present.map((Attendee a) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: AppColors.primaryTeal
                                      .withValues(alpha: 0.12),
                                  child: Text(a.initials,
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryTeal)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(a.name,
                                        style: AppTextStyles.bodySmall)),
                                Text(a.role,
                                    style: AppTextStyles.caption
                                        .copyWith(
                                            color: AppColors.textSecondary)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 20),

                      // Agenda
                      const _SectionHeader(label: 'AGENDA'),
                      const SizedBox(height: 8),
                      ...agenda.map((AgendaItem item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${item.index}.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Expanded(
                                    child: Text(item.title,
                                        style: AppTextStyles.bodySmall)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 20),

                      // Transcript
                      _SectionHeader(
                          label:
                              'TRANSCRIPT (${entries.length} entries)'),
                      const SizedBox(height: 8),

                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('No statements captured yet.',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary)),
                        )
                      else
                        ...entries.reversed.map((TranscriptEntry e) =>
                            _PreviewEntryTile(entry: e)),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Footer
              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: AppTextStyles.body),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _PreviewEntryTile extends StatelessWidget {
  final TranscriptEntry entry;
  const _PreviewEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final bool isTagged = entry.speaker.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MinuteTag(
                label: isTagged ? entry.speaker : 'Unassigned',
                backgroundColor:
                    isTagged ? AppColors.tagBlueBg : AppColors.surfaceMuted,
                textColor: isTagged
                    ? AppColors.primaryTeal
                    : AppColors.textSecondary,
              ),
              const Spacer(),
              Text(_formatTimestamp(entry.timestamp),
                  style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          Text(entry.text, style: AppTextStyles.body),
          if (entry.take.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tagGreenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_outlined,
                      size: 14, color: AppColors.primaryTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.take,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
