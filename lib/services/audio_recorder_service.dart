import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

enum AudioRecorderStartStatus {
  started,
  permissionDenied,
  unsupported,
  failed,
}

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _lastErrorMessage;

  String? get lastErrorMessage => _lastErrorMessage;

  Future<AudioRecorderStartStatus> start() async {
    _lastErrorMessage = null;
    // On web, MediaRecorder and SpeechRecognition both compete for the
    // microphone and Chrome raises an audio-capture error on the second one.
    // Since SpeechRecognition already captures audio for transcription, we
    // skip MediaRecorder on web entirely.
    if (kIsWeb) return AudioRecorderStartStatus.started;

    final bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _lastErrorMessage = 'Microphone permission denied.';
      return AudioRecorderStartStatus.permissionDenied;
    }

    try {
      await _recorder.start(
        const RecordConfig(),
        path: 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      return AudioRecorderStartStatus.started;
    } catch (error) {
      final String details = error.toString();
      debugPrint('AudioRecorderService.start failed: $details');
      _lastErrorMessage = details;
      return AudioRecorderStartStatus.failed;
    }
  }

  Future<void> pause() async {
    if (kIsWeb) return;
    if (await _recorder.isRecording()) await _recorder.pause();
  }

  Future<void> resume() async {
    if (kIsWeb) return;
    if (await _recorder.isPaused()) await _recorder.resume();
  }

  Future<String?> stop() async {
    if (kIsWeb) return null;
    return _recorder.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
