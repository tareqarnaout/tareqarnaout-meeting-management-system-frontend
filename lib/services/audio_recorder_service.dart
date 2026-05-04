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

  Future<AudioRecorderStartStatus> start() async {
    if (kIsWeb && !_isSecureContext()) {
      // Web recording requires a secure context (HTTPS or localhost).
      return AudioRecorderStartStatus.unsupported;
    }
    final bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      return AudioRecorderStartStatus.permissionDenied;
    }

    final RecordConfig config = kIsWeb
        ? const RecordConfig(encoder: AudioEncoder.opus)
        : const RecordConfig();
    final String fileName = kIsWeb
        ? 'recording_${DateTime.now().millisecondsSinceEpoch}.webm'
        : 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _recorder.start(config, path: fileName);
      return AudioRecorderStartStatus.started;
    } catch (error) {
      debugPrint('AudioRecorderService.start failed: $error');
      return AudioRecorderStartStatus.failed;
    }
  }

  Future<void> pause() async {
    if (await _recorder.isRecording()) {
      await _recorder.pause();
    }
  }

  Future<void> resume() async {
    if (await _recorder.isPaused()) {
      await _recorder.resume();
    }
  }

  Future<String?> stop() async {
    return _recorder.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  bool _isSecureContext() {
    final Uri base = Uri.base;
    if (base.scheme == 'https') return true;
    final String host = base.host;
    return host == 'localhost' || host == '127.0.0.1';
  }
}
