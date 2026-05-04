import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/minute_taker_models.dart';
import '../services/audio_recorder_service.dart';
import '../services/speech_to_text_service.dart';
import '../widgets/minute_taker_widgets.dart';

class MinuteTakerScreen extends StatefulWidget {
  const MinuteTakerScreen({super.key});

  static const double _webMaxWidth = 1200;
  static const double _desktopBreakpoint = 1100;

  @override
  State<MinuteTakerScreen> createState() => _MinuteTakerScreenState();
}

class _MinuteTakerScreenState extends State<MinuteTakerScreen> {
  static const List<String> _speakers = <String>[
    'Dr. Abdulla Qusef',
    'Dr. Mohammad Ali',
    'Dr. Fatima Hasan',
  ];

  final AudioRecorderService _recorder = AudioRecorderService();
  final SpeechToTextService _speechToTextService = SpeechToTextService();
  final TextEditingController _statementController = TextEditingController();
  final List<TranscriptEntry> _entries = <TranscriptEntry>[];
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  RecordingState _recordingState = RecordingState.idle;
  String _selectedSpeaker = _speakers.first;
  String _liveTranscript = '';
  bool _sttAvailable = false;
  bool _sttListening = false;
  bool _sttInitializing = false;
  final String _localeId = 'ar';

  @override
  void initState() {
    super.initState();
    _initializeSpeechToText();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statementController.dispose();
    _recorder.dispose();
    _speechToTextService.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeechToText() async {
    setState(() => _sttInitializing = true);
    try {
      final bool available =
          await _speechToTextService.initialize(localeId: _localeId);
      if (!mounted) return;
      setState(() {
        _sttAvailable = available;
        _sttInitializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sttAvailable = false;
        _sttInitializing = false;
      });
    }
  }

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
        _showError('Microphone permission is required to record audio.');
        return;
      }
      if (status == AudioRecorderStartStatus.unsupported) {
        _showError(
          'Recording on the web requires HTTPS or localhost in a supported browser.',
        );
        return;
      }
      if (status == AudioRecorderStartStatus.failed) {
        _showError('Unable to start recording.');
        return;
      }
      _stopwatch.start();
      _startTimer();
      setState(() => _recordingState = RecordingState.recording);
      await _startTranscription();
    } catch (_) {
      _showError('Unable to start recording.');
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
      final String? path = await _recorder.stop();
      _stopwatch.reset();
      _timer?.cancel();
      setState(() => _recordingState = RecordingState.idle);
      await _stopTranscription();
      if (path == null) return;
      _showInfo('Recording saved.');
    } catch (_) {
      _showError('Unable to stop recording.');
    }
  }

  Future<void> _startTranscription() async {
    if (_sttInitializing || !_sttAvailable || _sttListening) {
      return;
    }
    final bool started = await _speechToTextService.startListening(
      localeId: _localeId,
      onResult: (String text, bool isFinal) {
        if (!mounted) return;
        if (text.isEmpty) return;
        setState(() {
          _liveTranscript = text;
        });
        if (isFinal) {
          _addTranscriptFromSpeech(text);
        }
      },
    );
    if (!started && mounted) {
      _showError('Arabic transcription is unavailable on this device.');
      return;
    }
    if (mounted) {
      setState(() => _sttListening = true);
    }
  }

  Future<void> _stopTranscription() async {
    if (!_sttListening) return;
    await _speechToTextService.stop();
    if (!mounted) return;
    setState(() {
      _sttListening = false;
      _liveTranscript = '';
    });
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

  void _addStatement() {
    final String text = _statementController.text.trim();
    if (text.isEmpty) return;
    final TranscriptEntry entry = TranscriptEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      speaker: _selectedSpeaker,
      timestamp: DateTime.now(),
    );
    setState(() {
      _entries.insert(0, entry);
    });
    _statementController.clear();
  }

  void _addTranscriptFromSpeech(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final TranscriptEntry entry = TranscriptEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmed,
      speaker: _selectedSpeaker,
      timestamp: DateTime.now(),
    );
    setState(() {
      _entries.insert(0, entry);
      _liveTranscript = '';
    });
  }

  void _showSpeakerPicker(TranscriptEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tag speaker', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              ..._speakers.map((String speaker) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(speaker, style: AppTextStyles.body),
                  trailing: entry.speaker == speaker
                      ? const Icon(Icons.check, color: AppColors.primaryTeal)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _updateEntrySpeaker(entry, speaker);
                  },
                );
              }),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Unassigned', style: AppTextStyles.bodySmall),
                onTap: () {
                  Navigator.pop(context);
                  _updateEntrySpeaker(entry, '');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _updateEntrySpeaker(TranscriptEntry entry, String speaker) {
    final int index = _entries.indexWhere((TranscriptEntry e) => e.id == entry.id);
    if (index == -1) return;
    setState(() {
      _entries[index] = _entries[index].copyWith(speaker: speaker);
    });
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

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final double textScale = textScaler.scale(1.0);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop =
            constraints.maxWidth >= MinuteTakerScreen._desktopBreakpoint;
        final EdgeInsets pagePadding = EdgeInsets.all(isDesktop ? 24 : 16);
        final double sectionGap = textScale > 1.1 ? 18 : 22;

        final List<HandoffStat> stats = <HandoffStat>[
          HandoffStat(label: 'Statements', value: _entries.length.toString()),
          const HandoffStat(label: 'Action items', value: '0', highlight: true),
          const HandoffStat(label: 'Attendees', value: '5'),
          HandoffStat(label: 'Duration', value: _formatDuration(_stopwatch.elapsed)),
        ];

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
            ),
            SizedBox(height: sectionGap),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _LeftColumn(sectionGap: sectionGap)),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: _CenterColumn(
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
                      liveTranscript: _liveTranscript,
                      controller: _statementController,
                      onAdd: _addStatement,
                      onEntryTap: _showSpeakerPicker,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _RightColumn(sectionGap: sectionGap, stats: stats),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _LeftColumn(sectionGap: sectionGap),
                  SizedBox(height: sectionGap),
                  _CenterColumn(
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
                    liveTranscript: _liveTranscript,
                    controller: _statementController,
                    onAdd: _addStatement,
                    onEntryTap: _showSpeakerPicker,
                  ),
                  SizedBox(height: sectionGap),
                  _RightColumn(sectionGap: sectionGap, stats: stats),
                ],
              ),
          ],
        );

        if (kIsWeb) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: MinuteTakerScreen._webMaxWidth),
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
}

class _MinuteHeader extends StatelessWidget {
  final double textScale;
  final String recordingLabel;
  final IconData recordingIcon;
  final String recordLabel;
  final IconData recordIcon;
  final RecordingState recordingState;
  final VoidCallback onRecordToggle;
  final VoidCallback onStop;

  const _MinuteHeader({
    required this.textScale,
    required this.recordingLabel,
    required this.recordingIcon,
    required this.recordLabel,
    required this.recordIcon,
    required this.recordingState,
    required this.onRecordToggle,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final double titleSize = textScale > 1.1 ? 22 : 20;
    final bool isIdle = recordingState == RecordingState.idle;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 980;

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
          spacing: 10,
          runSpacing: 8,
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
              label: 'Save Draft',
              icon: Icons.save_outlined,
              onPressed: () {},
            ),
            MinuteActionButton(
              label: 'Send to Secretary',
              icon: Icons.send_outlined,
              onPressed: () {},
              isPrimary: true,
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  metaRow,
                  const SizedBox(height: 10),
                  actions,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: metaRow),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: actions,
                    ),
                  ),
                ],
              ),
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

class _LeftColumn extends StatelessWidget {
  final double sectionGap;

  const _LeftColumn({required this.sectionGap});

  static const List<Attendee> _attendees = <Attendee>[
    Attendee(
      initials: 'AQ',
      name: 'Dr. Abdulla Qusef',
      role: 'Department Head',
      isPresent: true,
    ),
    Attendee(
      initials: 'MA',
      name: 'Dr. Mohammad Ali',
      role: 'Faculty Member',
      isPresent: true,
    ),
    Attendee(
      initials: 'FH',
      name: 'Dr. Fatima Hasan',
      role: 'Faculty Member',
      isPresent: true,
    ),
    Attendee(
      initials: 'AK',
      name: 'Dr. Ahmed Khaled',
      role: 'Faculty Member',
      isPresent: true,
    ),
    Attendee(
      initials: 'LS',
      name: 'Dr. Laila Salem',
      role: 'Faculty Member',
      isPresent: false,
    ),
    Attendee(
      initials: 'KM',
      name: 'Dr. Khaled Mansi',
      role: 'Faculty Member',
      isPresent: true,
    ),
  ];

  static const List<AgendaItem> _agenda = <AgendaItem>[
    AgendaItem(index: 1, title: 'Meeting opening and welcome', isActive: true),
    AgendaItem(index: 2, title: 'Review previous minutes', isActive: false),
    AgendaItem(index: 3, title: 'Discuss research initiatives', isActive: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MinuteSectionCard(
          title: 'Attendance',
          trailing: MinuteTag(
            label: '5/6',
            backgroundColor: AppColors.surfaceMuted,
            textColor: AppColors.textPrimary,
          ),
          child: AttendanceList(attendees: _attendees),
        ),
        SizedBox(height: sectionGap),
        MinuteSectionCard(
          title: 'Agenda',
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline, size: 18),
            color: AppColors.primaryTeal,
            padding: EdgeInsets.zero,
          ),
          child: Column(
            children: [
              AgendaList(items: _agenda),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Add new item', style: AppTextStyles.bodySmall),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.add, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenterColumn extends StatelessWidget {
  final double sectionGap;
  final List<TranscriptEntry> entries;
  final List<String> speakers;
  final String selectedSpeaker;
  final ValueChanged<String?> onSpeakerChanged;
  final bool sttAvailable;
  final bool sttListening;
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
    required this.liveTranscript,
    required this.controller,
    required this.onAdd,
    required this.onEntryTap,
  });

  static const List<String> _tags = <String>[
    'Meeting opening and welcome',
  ];

  @override
  Widget build(BuildContext context) {
    final double viewportHeight = MediaQuery.sizeOf(context).height;
    final double transcriptHeight =
        (viewportHeight * 0.55).clamp(320.0, 520.0);

    return Column(
      children: [
        MinuteSectionCard(
          title: 'Live Transcript',
          trailing: Wrap(
            spacing: 8,
            children: [
              MinuteTag(
                label: _tags.first,
                backgroundColor: AppColors.tagGreenBg,
                textColor: AppColors.primaryTeal,
              ),
              MinuteTag(
                label: sttAvailable
                    ? (sttListening ? 'Arabic STT On' : 'Arabic STT Off')
                    : 'Arabic STT Unavailable',
                backgroundColor: AppColors.surfaceMuted,
                textColor: AppColors.textSecondary,
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
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          if (liveTranscript.isNotEmpty && index == 0) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        AppColors.border.withValues(alpha: 0.7)),
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
                          final int entryIndex =
                              liveTranscript.isEmpty ? index : index - 1;
                          final TranscriptEntry entry = entries[entryIndex];
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
        SizedBox(height: sectionGap),
        MinuteSectionCard(
          title: 'Session Notes',
          trailing: MinuteTag(
            label: 'Live preview loading',
            backgroundColor: AppColors.surfaceMuted,
            textColor: AppColors.textSecondary,
          ),
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Notes will appear here as you capture statements, actions, and decisions.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  final double sectionGap;
  final List<HandoffStat> stats;

  const _RightColumn({required this.sectionGap, required this.stats});

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
              HandoffStats(stats: stats),
              const SizedBox(height: 14),
              Text('Secretary', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: 'Abeer Amri',
                items: const [
                  DropdownMenuItem(value: 'Abeer Amri', child: Text('Abeer Amri')),
                  DropdownMenuItem(value: 'Salma Rashid', child: Text('Salma Rashid')),
                ],
                onChanged: (String? value) {},
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: Text('Send Notes', style: AppTextStyles.buttonSmall),
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
        SizedBox(height: sectionGap),
        MinuteSectionCard(
          title: 'Action Items',
          trailing: const Icon(Icons.checklist_outlined, size: 18),
          child: Container(
            height: 120,
            alignment: Alignment.centerLeft,
            child: Text(
              'No action items captured yet.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}

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
