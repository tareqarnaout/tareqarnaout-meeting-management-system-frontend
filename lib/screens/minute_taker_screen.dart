import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../constants/app_theme.dart';
import '../models/minute_taker_models.dart';
import '../models/meeting_note.dart';
import '../services/audio_recorder_service.dart';
import '../services/arabic_speech_service.dart';
import '../services/auth_service.dart';
import '../services/meeting_notes_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../widgets/minute_taker_widgets.dart';

class MinuteTakerScreen extends StatefulWidget {
  const MinuteTakerScreen({super.key});

  static const double _webMaxWidth = 1200;
  static const double _desktopBreakpoint = 1100;

  @override
  State<MinuteTakerScreen> createState() => _MinuteTakerScreenState();
}

class _MinuteTakerScreenState extends State<MinuteTakerScreen> {
  // ── Services ──────────────────────────────────────────────────────────────
  final AudioRecorderService _recorder = AudioRecorderService();
  final ArabicSpeechService _speechService = ArabicSpeechService();
  final MeetingNotesService _notesService = MeetingNotesService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final TextEditingController _statementController = TextEditingController();

  // ── Meeting state ─────────────────────────────────────────────────────────
  final List<Attendee> _attendees = <Attendee>[];

  final List<AgendaItem> _agenda = <AgendaItem>[];

  final List<TranscriptEntry> _entries = <TranscriptEntry>[];
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  // ── Recording & STT state ─────────────────────────────────────────────────
  RecordingState _recordingState = RecordingState.idle;
  String _liveTranscript = '';
  bool _sttAvailable = false;
  bool _sttListening = false;
  bool _sttInitializing = false;
  bool _isSending = false;

  // ── Derived ───────────────────────────────────────────────────────────────
  /// All attendee names, used as the speaker dropdown options.
  List<String> get _speakers => _attendees.map((Attendee a) => a.name).toList();

  String _selectedSpeaker = '';
  String _selectedDepartment = 'هندسة البرمجيات';
  String _selectedMeetingType = 'مجلس القسم';
  List<Attendee> _allUsers = <Attendee>[];
  List<AppUser> _secretaries = <AppUser>[];
  int? _selectedSecretaryId;

  static const List<String> _departments = <String>[
    'هندسة البرمجيات',
    'علوم الحاسوب',
    'هندسة الحاسوب',
    'علم البيانات والذكاء الاصطناعي',
    'الأمن السيبراني',
    'الرسوم الحاسوبية والرسوم المتحركة',
    'تكنولوجيا معلومات الأعمال',
    'هندسة الشبكات',
    'هندسة إنترنت الأشياء',
  ];

  static const List<String> _meetingTypes = <String>[
    'مجلس القسم',
    'مجلس الكلية',
    'مجلس العمداء',
    'مجلس الجامعة',
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _loadUsers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statementController.dispose();
    _recorder.dispose();
    // Don't dispose the singleton speech service — just stop listening so the
    // loaded model survives screen navigation and won't be re-downloaded.
    _speechService.stopListening();
    super.dispose();
  }

  // ── STT ───────────────────────────────────────────────────────────────────

  Future<void> _loadUsers() async {
    try {
      final List<AppUser> users = await _userService.getUsers();
      if (!mounted) return;
      final List<Attendee> allUsers = users
          .map((AppUser u) => Attendee(
                id: u.id,
                initials: Attendee.initialsFrom(u.name),
                name: u.name,
                role: UserRole.label(u.roleId),
                isPresent: false,
              ))
          .toList();
      final List<AppUser> secretaries = users
          .where((AppUser u) => u.roleId == UserRole.secretary)
          .toList();
      setState(() {
        _allUsers = allUsers;
        _secretaries = secretaries;
      });
    } catch (_) {}
  }

  Future<void> _initializeSpeech() async {
    setState(() => _sttInitializing = true);
    try {
      final bool available = await _speechService.initialize();
      if (!mounted) return;
      setState(() {
        _sttAvailable = available;
        _sttInitializing = false;
      });
      if (!available && mounted) {
        _showError('Failed to initialize Arabic speech model.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sttAvailable = false;
        _sttInitializing = false;
      });
    }
  }

  Future<void> _startTranscription() async {
    if (_sttInitializing || !_sttAvailable || _sttListening) return;
    await _speechService.startListening(
      onResult: (String text, bool isFinal) {
        if (!mounted) return;
        setState(() => _liveTranscript = text);
        if (isFinal) _addTranscriptFromSpeech(text);
      },
      onStatus: (bool listening) {
        if (!mounted) return;
        setState(() => _sttListening = listening);
      },
      onError: (String error) {
        if (!mounted) return;
        _showError(error);
      },
    );
  }

  Future<void> _stopTranscription() async {
    await _speechService.stopListening();
    if (!mounted) return;
    setState(() {
      _sttListening = false;
      _liveTranscript = '';
    });
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _startRecording() async {
    try {
      final AudioRecorderStartStatus status = await _recorder.start();
      if (status == AudioRecorderStartStatus.permissionDenied) {
        final String d = _recorder.lastErrorMessage ?? '';
        _showError(d.isEmpty
            ? 'Microphone permission is required to record audio.'
            : 'Microphone permission is required. ($d)');
        return;
      }
      if (status == AudioRecorderStartStatus.unsupported) {
        final String d = _recorder.lastErrorMessage ?? '';
        _showError(d.isEmpty
            ? 'Recording on the web requires HTTPS or localhost in a supported browser.'
            : 'Recording on the web requires HTTPS or localhost. ($d)');
        return;
      }
      if (status == AudioRecorderStartStatus.failed) {
        final String d = _recorder.lastErrorMessage ?? '';
        _showError(
            d.isEmpty ? 'Unable to start recording.' : 'Unable to start recording. ($d)');
        return;
      }
      _stopwatch.start();
      _startTimer();
      setState(() => _recordingState = RecordingState.recording);
      await _startTranscription();
    } catch (error) {
      _showError('Unable to start recording. (${error.toString()})');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();
      _stopwatch.stop();
      _timer?.cancel();
      setState(() => _recordingState = RecordingState.paused);
      await _stopTranscription();
    } catch (_) {
      _showError('Unable to pause recording.');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resume();
      _stopwatch.start();
      _startTimer();
      setState(() => _recordingState = RecordingState.recording);
      await _startTranscription();
    } catch (_) {
      _showError('Unable to resume recording.');
    }
  }

  Future<void> _stopRecording() async {
    if (_recordingState == RecordingState.idle) return;
    try {
      await _recorder.stop();
      _stopwatch.reset();
      _timer?.cancel();
      setState(() => _recordingState = RecordingState.idle);
      await _stopTranscription();
    } catch (_) {
      _showError('Unable to stop recording.');
    }
  }

  void _handleRecordToggle() {
    if (_recordingState == RecordingState.recording) {
      _pauseRecording();
    } else if (_recordingState == RecordingState.paused) {
      _resumeRecording();
    } else {
      _startRecording();
    }
  }

  // ── Transcript entries ────────────────────────────────────────────────────

  void _addStatement() {
    final String text = _statementController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _entries.insert(
        0,
        TranscriptEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          speaker: _selectedSpeaker,
          timestamp: DateTime.now(),
        ),
      );
    });
    _statementController.clear();
  }

  void _addTranscriptFromSpeech(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _entries.insert(
        0,
        TranscriptEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: trimmed,
          speaker: _selectedSpeaker,
          timestamp: DateTime.now(),
        ),
      );
      _liveTranscript = '';
    });
  }

  void _showEntryEditor(TranscriptEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EntryEditorSheet(
        entry: entry,
        speakers: _speakers,
        onSave: (String speaker, String take) {
          final int index = _entries.indexWhere((TranscriptEntry e) => e.id == entry.id);
          if (index == -1) return;
          setState(() {
            _entries[index] = _entries[index].copyWith(speaker: speaker, take: take);
          });
        },
      ),
    );
  }

  // ── Attendees ─────────────────────────────────────────────────────────────

  void _toggleAttendeePresence(Attendee attendee) {
    final int idx = _attendees.indexWhere((Attendee a) => a.name == attendee.name);
    if (idx == -1) return;
    setState(() {
      _attendees[idx] = _attendees[idx].copyWith(isPresent: !_attendees[idx].isPresent);
    });
  }

  void _addAttendee(Attendee attendee) {
    final int existing = _attendees.indexWhere((Attendee a) => a.name == attendee.name);
    if (existing != -1) {
      setState(() {
        _attendees[existing] = _attendees[existing].copyWith(isPresent: true);
      });
      return;
    }
    setState(() {
      _attendees.add(attendee.copyWith(isPresent: true));
      if (_speakers.isNotEmpty) _selectedSpeaker = _attendees.last.name;
    });
  }

  void _showAttendeeSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AttendeeSearchSheet(
        existingNames: _attendees.map((Attendee a) => a.name).toSet(),
        onAdd: _addAttendee,
      ),
    );
  }

  // ── Agenda ────────────────────────────────────────────────────────────────

  void _addAgendaItem(String title) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      final int nextIndex = _agenda.isEmpty ? 1 : _agenda.last.index + 1;
      _agenda.add(AgendaItem(index: nextIndex, title: trimmed, isActive: _agenda.isEmpty));
    });
  }

  void _removeAgendaItem(int index) {
    setState(() {
      _agenda.removeAt(index);
      for (int i = 0; i < _agenda.length; i++) {
        _agenda[i] = AgendaItem(index: i + 1, title: _agenda[i].title, isActive: _agenda[i].isActive);
      }
    });
  }

  // ── Handoff preview ───────────────────────────────────────────────────────

  void _showHandoffPreview() {
    showDialog<void>(
      context: context,
      builder: (_) => HandoffPreviewDialog(
        meetingTitle: 'Faculty Council Meeting - Term 2',
        meetingDate: '2026-04-30',
        attendees: _attendees,
        agenda: _agenda,
        entries: _entries,
      ),
    );
  }

  // ── Send notes to secretary ────────────────────────────────────────────

  Future<void> _sendNotes() async {
    if (_isSending) return;
    if (_entries.isEmpty) {
      _showError('No statements captured yet.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final int? userId = await _authService.getUserId();
      final String? userName = await _authService.getUserName();
      final int? roleId = await _authService.getRoleId();
      if (userId == null) {
        _showError('Unable to identify user. Please log in again.');
        setState(() => _isSending = false);
        return;
      }

      final String roleName = roleId != null
          ? UserRole.label(roleId)
          : 'Minute Taker';
      final String recorderDisplay = userName != null
          ? '$userName — $roleName'
          : 'User #$userId — $roleName';

      final List<NoteAttendee> noteAttendees = _attendees
          .map((Attendee a) => NoteAttendee(
                initials: a.initials,
                name: a.name,
                role: a.role,
                isPresent: a.isPresent,
              ))
          .toList();

      final List<NoteAgendaItem> noteAgenda = _agenda
          .map((AgendaItem a) =>
              NoteAgendaItem(index: a.index, title: a.title))
          .toList();

      final List<NoteTranscriptEntry> noteTranscript = _entries
          .map((TranscriptEntry e) => NoteTranscriptEntry(
                speaker: e.speaker,
                text: e.text,
                timestamp: e.timestamp.toIso8601String(),
                take: e.take.isNotEmpty ? e.take : null,
              ))
          .toList();

      final NoteContent content = NoteContent(
        title: 'Faculty Council Meeting - Term 2',
        titleAr: 'اجتماع هيئة التدريس',
        recorderName: recorderDisplay,
        department: _selectedDepartment,
        meetingType: _selectedMeetingType,
        attendees: noteAttendees,
        agenda: noteAgenda,
        transcript: noteTranscript,
        durationMinutes: _stopwatch.elapsed.inMinutes,
      );

      final String notesJson = jsonEncode(content.toJson());

      final bool success = await _notesService.createNote(
        notes: notesJson,
        attendeeIds: <int>[],
        recorderId: userId,
        date: DateTime.now(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes sent to secretary successfully.'),
            backgroundColor: AppColors.statusApproved,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Failed to send notes. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Network error. Please check your connection.');
    }

    if (mounted) setState(() => _isSending = false);
  }

  // ── Save to archive ────────────────────────────────────────────────────

  Future<void> _saveToArchive() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save to Archive'),
        content: const Text(
          'Are you sure you want to save these meeting minutes to the archive? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meeting minutes saved to archive successfully.'),
        backgroundColor: AppColors.statusApproved,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _sttLabel() {
    if (_sttInitializing) {
      return _speechService.isDownloadingModel
          ? 'Downloading Arabic Model...'
          : 'Initializing STT...';
    }
    if (_sttAvailable) {
      return _sttListening ? 'Arabic STT On' : 'Arabic STT Off';
    }
    return 'Arabic STT Unavailable';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.statusDraft,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final double textScale = textScaler.scale(1.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop =
            constraints.maxWidth >= MinuteTakerScreen._desktopBreakpoint;

        if (!isDesktop) {
          return _buildMobileLayout(context);
        }

        final EdgeInsets pagePadding = const EdgeInsets.all(24);
        final double sectionGap = textScale > 1.1 ? 18 : 22;

        final int presentCount = _attendees.where((Attendee a) => a.isPresent).length;
        final List<HandoffStat> stats = <HandoffStat>[
          HandoffStat(label: 'Statements', value: _entries.length.toString()),
          HandoffStat(label: 'Attendees', value: '$presentCount/${_attendees.length}'),
          HandoffStat(label: 'Duration', value: _formatDuration(_stopwatch.elapsed)),
        ];

        final _LeftColumn leftCol = _LeftColumn(
          sectionGap: sectionGap,
          attendees: _attendees,
          allUsers: _allUsers,
          agenda: _agenda,
          onAttendeeToggle: _toggleAttendeePresence,
          onAddAttendee: _addAttendee,
          onAddAgenda: _addAgendaItem,
          onRemoveAgenda: _removeAgendaItem,
        );

        final _CenterColumn centerCol = _CenterColumn(
          sectionGap: sectionGap,
          entries: _entries,
          speakers: _speakers,
          selectedSpeaker: _selectedSpeaker,
          onSpeakerChanged: (String? value) {
            if (value == null) return;
            setState(() => _selectedSpeaker = value);
          },
          sttAvailable: _sttAvailable,
          sttListening: _sttListening,
          sttLabel: _sttLabel(),
          liveTranscript: _liveTranscript,
          controller: _statementController,
          onAdd: _addStatement,
          onEntryTap: _showEntryEditor,
        );

        final _RightColumn rightCol = _RightColumn(
          sectionGap: sectionGap,
          stats: stats,
          onPreview: _showHandoffPreview,
          onSendNotes: _sendNotes,
          isSending: _isSending,
          departments: _departments,
          selectedDepartment: _selectedDepartment,
          onDepartmentChanged: (String? value) {
            if (value != null) setState(() => _selectedDepartment = value);
          },
          meetingTypes: _meetingTypes,
          selectedMeetingType: _selectedMeetingType,
          onMeetingTypeChanged: (String? value) {
            if (value != null) setState(() => _selectedMeetingType = value);
          },
          secretaries: _secretaries,
          selectedSecretaryId: _selectedSecretaryId,
          onSecretaryChanged: (AppUser? s) {
            setState(() => _selectedSecretaryId = s?.id);
          },
        );

        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MinuteHeader(
              textScale: textScale,
              recordingLabel: _recordingLabel(),
              recordingIcon: _recordingIcon(),
              recordLabel: _recordButtonLabel(),
              recordIcon: _recordButtonIcon(),
              recordingState: _recordingState,
              onRecordToggle: _handleRecordToggle,
              onStop: _stopRecording,
              onSaveToArchive: _saveToArchive,
            ),
            SizedBox(height: sectionGap),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftCol),
                  const SizedBox(width: 18),
                  Expanded(flex: 2, child: centerCol),
                  const SizedBox(width: 18),
                  Expanded(child: rightCol),
                ],
              )
            else
              Column(
                children: [
                  leftCol,
                  SizedBox(height: sectionGap),
                  centerCol,
                  SizedBox(height: sectionGap),
                  rightCol,
                ],
              ),
          ],
        );

        if (kIsWeb) {
          content = Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: MinuteTakerScreen._webMaxWidth),
              child: content,
            ),
          );
        }

        return Container(
          color: AppColors.pageBg,
          child: ScrollConfiguration(
            behavior: const _MinuteScrollBehavior(),
            child: SingleChildScrollView(
              padding: pagePadding,
              child: content,
            ),
          ),
        );
      },
    );
  }

  String _recordingLabel() {
    final String elapsed = _formatDuration(_stopwatch.elapsed);
    switch (_recordingState) {
      case RecordingState.recording:
        return 'Recording $elapsed';
      case RecordingState.paused:
        return 'Paused $elapsed';
      case RecordingState.idle:
        return 'Ready';
    }
  }

  IconData _recordingIcon() {
    switch (_recordingState) {
      case RecordingState.recording:
        return Icons.mic;
      case RecordingState.paused:
        return Icons.pause_circle_outline;
      case RecordingState.idle:
        return Icons.mic_none;
    }
  }

  String _recordButtonLabel() {
    switch (_recordingState) {
      case RecordingState.recording:
        return 'Pause';
      case RecordingState.paused:
        return 'Resume';
      case RecordingState.idle:
        return 'Record';
    }
  }

  IconData _recordButtonIcon() {
    switch (_recordingState) {
      case RecordingState.recording:
        return Icons.pause_circle_outline;
      case RecordingState.paused:
        return Icons.play_circle_outline;
      case RecordingState.idle:
        return Icons.mic_none;
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: AppColors.pageBg,
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: AppDecorations.cardWithBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Transcript',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            MinuteTag(
                              label: 'Meeting opening and welcome',
                              backgroundColor: AppColors.tagGreenBg,
                              textColor: AppColors.primaryTeal,
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _sttAvailable || _sttInitializing
                                  ? null
                                  : () {
                                      _initializeSpeech();
                                    },
                              child: MinuteTag(
                                label: _sttLabel(),
                                backgroundColor: _sttAvailable
                                    ? AppColors.surfaceMuted
                                    : AppColors.statusDraft
                                        .withValues(alpha: 0.1),
                                textColor: _sttAvailable
                                    ? AppColors.textSecondary
                                    : AppColors.statusDraft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _entries.isEmpty && _liveTranscript.isEmpty
                        ? const TranscriptEmptyState(
                            title: "Start capturing what's said",
                            subtitle:
                                'Pick a speaker, type the statement, and it will be timestamped under the active agenda item.',
                          )
                        : ListView.separated(
                            itemCount: _entries.length +
                                (_liveTranscript.isEmpty ? 0 : 1),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (BuildContext context, int index) {
                              if (_liveTranscript.isNotEmpty && index == 0) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.border
                                            .withValues(alpha: 0.7)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.mic,
                                          size: 16,
                                          color: AppColors.primaryTeal),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_liveTranscript,
                                            style: AppTextStyles.bodySmall),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final int ei = _liveTranscript.isEmpty
                                  ? index
                                  : index - 1;
                              final TranscriptEntry entry = _entries[ei];
                              return TranscriptEntryTile(
                                entry: entry,
                                onTap: () => _showEntryEditor(entry),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _speakers.contains(_selectedSpeaker)
                            ? _selectedSpeaker
                            : (_speakers.isNotEmpty ? _speakers.first : null),
                        isExpanded: true,
                        hint: Text('Speaker', style: AppTextStyles.bodySmall),
                        items: _speakers
                            .map((String s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          if (value == null) return;
                          setState(() => _selectedSpeaker = value);
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _showAttendeeSearch,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_add_outlined,
                            size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _statementController,
                        onSubmitted: (_) => _addStatement(),
                        decoration: InputDecoration(
                          hintText: 'Type what was said...',
                          hintStyle: AppTextStyles.bodySmall,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _addStatement,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('Add', style: AppTextStyles.buttonSmall),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMobileAction(
                  icon: _recordButtonIcon(),
                  label: _recordButtonLabel(),
                  onTap: _handleRecordToggle,
                ),
                _buildMobileAction(
                  icon: Icons.stop_circle_outlined,
                  label: 'Stop',
                  onTap: _recordingState == RecordingState.idle
                      ? null
                      : _stopRecording,
                ),
                _buildMobileAction(
                  icon: Icons.add_box_outlined,
                  label: 'Save',
                  onTap: _saveToArchive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAction({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;
    final Color color =
        enabled ? AppColors.textSecondary : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _MinuteHeader extends StatelessWidget {
  final double textScale;
  final String recordingLabel;
  final IconData recordingIcon;
  final String recordLabel;
  final IconData recordIcon;
  final RecordingState recordingState;
  final VoidCallback onRecordToggle;
  final VoidCallback onStop;
  final VoidCallback onSaveToArchive;

  const _MinuteHeader({
    required this.textScale,
    required this.recordingLabel,
    required this.recordingIcon,
    required this.recordLabel,
    required this.recordIcon,
    required this.recordingState,
    required this.onRecordToggle,
    required this.onStop,
    required this.onSaveToArchive,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = textScale > 1.1 ? 22 : 20;
    final bool isIdle = recordingState == RecordingState.idle;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isWide = constraints.maxWidth >= 700;

        final Widget metaRow = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: AppTextStyles.bodySmall,
              ),
            ),
            MinuteTag(
              label: 'Minute Taker',
              backgroundColor: AppColors.tagBlueBg,
              textColor: AppColors.primaryTeal,
            ),
            Text('2026-04-30', style: AppTextStyles.bodySmall),
          ],
        );

        final Widget actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isWide ? WrapAlignment.end : WrapAlignment.start,
          children: [
            MinuteTag(
              label: recordingLabel,
              icon: recordingIcon,
              backgroundColor: AppColors.surfaceMuted,
              textColor: AppColors.textSecondary,
            ),
            MinuteActionButton(
              label: recordLabel,
              icon: recordIcon,
              onPressed: onRecordToggle,
            ),
            MinuteActionButton(
              label: 'Stop',
              icon: Icons.stop_circle_outlined,
              onPressed: isIdle ? null : onStop,
            ),
            MinuteActionButton(
              label: 'Save to Archive',
              icon: Icons.archive_outlined,
              onPressed: onSaveToArchive,
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  metaRow,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: actions,
                    ),
                  ),
                ],
              )
            else ...[
              metaRow,
              const SizedBox(height: 10),
              actions,
            ],
            const SizedBox(height: 10),
            Text(
              'Faculty Council Meeting - Term 2',
              style: AppTextStyles.pageTitle.copyWith(fontSize: titleSize),
            ),
          ],
        );
      },
    );
  }
}

// ── Left column ────────────────────────────────────────────────────────────

class _LeftColumn extends StatefulWidget {
  final double sectionGap;
  final List<Attendee> attendees;
  final List<Attendee> allUsers;
  final List<AgendaItem> agenda;
  final ValueChanged<Attendee> onAttendeeToggle;
  final ValueChanged<Attendee> onAddAttendee;
  final ValueChanged<String> onAddAgenda;
  final ValueChanged<int> onRemoveAgenda;

  const _LeftColumn({
    required this.sectionGap,
    required this.attendees,
    required this.allUsers,
    required this.agenda,
    required this.onAttendeeToggle,
    required this.onAddAttendee,
    required this.onAddAgenda,
    required this.onRemoveAgenda,
  });

  @override
  State<_LeftColumn> createState() => _LeftColumnState();
}

class _LeftColumnState extends State<_LeftColumn> {
  final TextEditingController _agendaController = TextEditingController();
  final TextEditingController _attendeeSearchController = TextEditingController();
  String _attendeeQuery = '';

  List<Attendee> get _filteredUsers {
    final String q = _attendeeQuery.toLowerCase();
    if (q.isEmpty) return <Attendee>[];
    final Set<String> existing =
        widget.attendees.map((Attendee a) => a.name).toSet();
    return widget.allUsers
        .where((Attendee a) =>
            !existing.contains(a.name) &&
            a.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _agendaController.dispose();
    _attendeeSearchController.dispose();
    super.dispose();
  }

  void _submitAgenda() {
    final String text = _agendaController.text.trim();
    if (text.isEmpty) return;
    widget.onAddAgenda(text);
    _agendaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final int presentCount = widget.attendees.where((Attendee a) => a.isPresent).length;

    return Column(
      children: [
        MinuteSectionCard(
          title: 'Attendance',
          trailing: MinuteTag(
            label: '$presentCount/${widget.attendees.length}',
            backgroundColor: AppColors.surfaceMuted,
            textColor: AppColors.textPrimary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AttendanceList(
                attendees: widget.attendees,
                onAttendeeToggle: widget.onAttendeeToggle,
              ),
              TextField(
                controller: _attendeeSearchController,
                onChanged: (String v) => setState(() => _attendeeQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search to add attendee...',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.textMuted),
                  suffixIcon: _attendeeQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() {
                            _attendeeQuery = '';
                            _attendeeSearchController.clear();
                          }),
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              if (_filteredUsers.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (BuildContext context, int index) {
                      final Attendee a = _filteredUsers[index];
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              AppColors.primaryTeal.withValues(alpha: 0.12),
                          child: Text(
                            a.initials,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                        title: Text(a.name, style: AppTextStyles.bodySmall),
                        subtitle: Text(a.role, style: AppTextStyles.caption),
                        trailing: const Icon(Icons.person_add_outlined,
                            size: 16, color: AppColors.primaryTeal),
                        onTap: () {
                          widget.onAddAttendee(a);
                          setState(() {
                            _attendeeQuery = '';
                            _attendeeSearchController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: widget.sectionGap),
        MinuteSectionCard(
          title: 'Agenda',
          trailing: MinuteTag(
            label: '${widget.agenda.length}',
            backgroundColor: AppColors.surfaceMuted,
            textColor: AppColors.textPrimary,
          ),
          child: Column(
            children: [
              AgendaList(
                items: widget.agenda,
                onRemove: widget.onRemoveAgenda,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _agendaController,
                      onSubmitted: (_) => _submitAgenda(),
                      decoration: InputDecoration(
                        hintText: 'Add agenda item...',
                        hintStyle: AppTextStyles.bodySmall,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _submitAgenda,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Center column ──────────────────────────────────────────────────────────

class _CenterColumn extends StatelessWidget {
  final double sectionGap;
  final List<TranscriptEntry> entries;
  final List<String> speakers;
  final String selectedSpeaker;
  final ValueChanged<String?> onSpeakerChanged;
  final bool sttAvailable;
  final bool sttListening;
  final String sttLabel;
  final String liveTranscript;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<TranscriptEntry> onEntryTap;

  const _CenterColumn({
    required this.sectionGap,
    required this.entries,
    required this.speakers,
    required this.selectedSpeaker,
    required this.onSpeakerChanged,
    required this.sttAvailable,
    required this.sttListening,
    required this.sttLabel,
    required this.liveTranscript,
    required this.controller,
    required this.onAdd,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final double viewportHeight = MediaQuery.sizeOf(context).height;
    final double transcriptHeight = (viewportHeight * 0.55).clamp(320.0, 520.0);

    return Column(
      children: [
        MinuteSectionCard(
          title: 'Live Transcript',
          trailing: Wrap(
            spacing: 8,
            children: [
              MinuteTag(
                label: 'Meeting opening and welcome',
                backgroundColor: AppColors.tagGreenBg,
                textColor: AppColors.primaryTeal,
              ),
              MinuteTag(
                label: sttLabel,
                backgroundColor: sttAvailable
                    ? AppColors.surfaceMuted
                    : AppColors.statusDraft.withValues(alpha: 0.1),
                textColor: sttAvailable
                    ? AppColors.textSecondary
                    : AppColors.statusDraft,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: transcriptHeight,
                child: entries.isEmpty && liveTranscript.isEmpty
                    ? const TranscriptEmptyState(
                        title: "Start capturing what's said",
                        subtitle:
                            'Pick a speaker, type the statement, and it will be timestamped under the active agenda item.',
                      )
                    : ListView.separated(
                        primary: false,
                        itemCount:
                            entries.length + (liveTranscript.isEmpty ? 0 : 1),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          if (liveTranscript.isNotEmpty && index == 0) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.border
                                        .withValues(alpha: 0.7)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.mic,
                                      size: 16, color: AppColors.primaryTeal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(liveTranscript,
                                        style: AppTextStyles.bodySmall),
                                  ),
                                ],
                              ),
                            );
                          }
                          final int ei =
                              liveTranscript.isEmpty ? index : index - 1;
                          final TranscriptEntry entry = entries[ei];
                          return TranscriptEntryTile(
                            entry: entry,
                            onTap: () => onEntryTap(entry),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              TranscriptInputBar(
                speakers: speakers,
                selectedSpeaker: selectedSpeaker,
                onSpeakerChanged: onSpeakerChanged,
                controller: controller,
                onAdd: onAdd,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Right column ───────────────────────────────────────────────────────────

class _RightColumn extends StatefulWidget {
  final double sectionGap;
  final List<HandoffStat> stats;
  final VoidCallback onPreview;
  final VoidCallback onSendNotes;
  final bool isSending;
  final List<String> departments;
  final String selectedDepartment;
  final ValueChanged<String?> onDepartmentChanged;
  final List<String> meetingTypes;
  final String selectedMeetingType;
  final ValueChanged<String?> onMeetingTypeChanged;
  final List<AppUser> secretaries;
  final int? selectedSecretaryId;
  final ValueChanged<AppUser?> onSecretaryChanged;

  const _RightColumn({
    required this.sectionGap,
    required this.stats,
    required this.onPreview,
    required this.onSendNotes,
    required this.departments,
    required this.selectedDepartment,
    required this.onDepartmentChanged,
    required this.meetingTypes,
    required this.selectedMeetingType,
    required this.onMeetingTypeChanged,
    required this.secretaries,
    required this.onSecretaryChanged,
    this.selectedSecretaryId,
    this.isSending = false,
  });

  @override
  State<_RightColumn> createState() => _RightColumnState();
}

class _RightColumnState extends State<_RightColumn> {
  final TextEditingController _secretaryController = TextEditingController();
  final FocusNode _secretaryFocus = FocusNode();
  bool _showSecretaryResults = false;

  List<AppUser> get _filteredSecretaries {
    final String q = _secretaryController.text.toLowerCase();
    if (q.isEmpty) return widget.secretaries;
    return widget.secretaries
        .where((AppUser s) => s.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _secretaryFocus.addListener(() {
      if (mounted) setState(() => _showSecretaryResults = _secretaryFocus.hasFocus);
    });
  }

  @override
  void didUpdateWidget(_RightColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the secretaries list first loads, pre-fill with the first entry.
    // Defer the parent setState call to after the current build frame.
    if (oldWidget.secretaries.isEmpty &&
        widget.secretaries.isNotEmpty &&
        _secretaryController.text.isEmpty) {
      final AppUser first = widget.secretaries.first;
      _secretaryController.text = first.name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSecretaryChanged(first);
      });
    }
  }

  @override
  void dispose() {
    _secretaryController.dispose();
    _secretaryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MinuteSectionCard(
          title: 'Handoff to Secretary',
          trailing: const Icon(Icons.send_outlined, size: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'When the meeting ends, send these notes to the secretary. They will use them to draft the official decision document.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 14),
              HandoffStats(stats: widget.stats),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onPreview,
                  icon: const Icon(Icons.preview_outlined, size: 16),
                  label: Text('Preview Minutes', style: AppTextStyles.buttonMuted),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('القسم', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: widget.selectedDepartment,
                isExpanded: true,
                items: widget.departments
                    .map((String d) => DropdownMenuItem<String>(
                          value: d,
                          child: Text(d,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textDirection: TextDirection.rtl),
                        ))
                    .toList(),
                onChanged: widget.onDepartmentChanged,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              const SizedBox(height: 14),
              Text('نوع المجلس', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: widget.selectedMeetingType,
                isExpanded: true,
                items: widget.meetingTypes
                    .map((String t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textDirection: TextDirection.rtl),
                        ))
                    .toList(),
                onChanged: widget.onMeetingTypeChanged,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              const SizedBox(height: 14),
              Text('Secretary', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              TextField(
                controller: _secretaryController,
                focusNode: _secretaryFocus,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.secretaries.isEmpty
                      ? 'Loading secretaries...'
                      : 'Search secretary...',
                  hintStyle: AppTextStyles.bodySmall,
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.textMuted),
                  suffixIcon: _secretaryController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() => _secretaryController.clear());
                            widget.onSecretaryChanged(null);
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              if (_showSecretaryResults && _filteredSecretaries.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _filteredSecretaries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (BuildContext context, int index) {
                      final AppUser s = _filteredSecretaries[index];
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(s.name, style: AppTextStyles.bodySmall),
                        onTap: () {
                          widget.onSecretaryChanged(s);
                          setState(() {
                            _secretaryController.text = s.name;
                            _showSecretaryResults = false;
                            _secretaryFocus.unfocus();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.isSending ? null : widget.onSendNotes,
                  icon: widget.isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 16),
                  label: Text(
                      widget.isSending ? 'Sending...' : 'Send Notes',
                      style: AppTextStyles.buttonSmall),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Scroll behaviour ───────────────────────────────────────────────────────

class _MinuteScrollBehavior extends MaterialScrollBehavior {
  const _MinuteScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
