import 'package:speech_to_text/speech_recognition_error.dart' as stt_error;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as stt_result;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  List<stt.LocaleName> _locales = <stt.LocaleName>[];
  String? _lastErrorMessage;
  String? _lastStatus;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    _available = await _speech.initialize(
      onStatus: (String status) {
        _lastStatus = status;
        onStatus?.call(status);
      },
      onError: (stt_error.SpeechRecognitionError error) {
        _lastErrorMessage = error.errorMsg;
        onError?.call(error.errorMsg);
      },
    );
    if (_available) {
      _locales = await _speech.locales();
    }
    return _available;
  }

  bool get isAvailable => _available;

  bool get isListening => _speech.isListening;

  String? get lastErrorMessage => _lastErrorMessage;

  String? get lastStatus => _lastStatus;

  List<stt.LocaleName> get locales => List<stt.LocaleName>.unmodifiable(_locales);

  bool get hasLocales => _locales.isNotEmpty;

  bool supportsLocaleId(String localeId) {
    return _locales.any((stt.LocaleName locale) => locale.localeId == localeId);
  }

  Future<String?> getSystemLocaleId() async {
    if (!_available) return null;
    final stt.LocaleName? systemLocale = await _speech.systemLocale();
    return systemLocale?.localeId;
  }

  String? findBestLocaleId(List<String> preferredPrefixes) {
    if (_locales.isEmpty) return null;
    for (final String prefix in preferredPrefixes) {
      final String normalized = prefix.toLowerCase();
      final stt.LocaleName? match = _locales.cast<stt.LocaleName?>().firstWhere(
            (stt.LocaleName? locale) =>
                locale != null &&
                locale.localeId.toLowerCase().startsWith(normalized),
            orElse: () => null,
          );
      if (match != null) return match.localeId;
    }
    return null;
  }

  Future<bool> startListening({
    required String? localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_available) {
      return false;
    }

    final String? resolvedLocaleId =
        localeId == null || localeId.isEmpty ? null : localeId;
    final bool started = await _speech.listen(
      localeId: resolvedLocaleId,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(minutes: 10),
      cancelOnError: false,
      onResult: (stt_result.SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
    return started;
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> dispose() async {
    await _speech.cancel();
  }
}
