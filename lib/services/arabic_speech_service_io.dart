// Native (iOS / Android) implementation using the speech_to_text package.
import 'dart:async';
import 'package:speech_to_text/speech_recognition_error.dart' as stt_error;
import 'package:speech_to_text/speech_recognition_result.dart' as stt_result;
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef SpeechResultCallback = void Function(String text, bool isFinal);
typedef SpeechStatusCallback = void Function(bool isListening);
typedef SpeechErrorCallback = void Function(String error);

class ArabicSpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  bool _wantListening = false;
  String? _localeId;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;

  SpeechResultCallback? _onResult;
  SpeechStatusCallback? _onStatus;
  SpeechErrorCallback? _onError;

  // Ordered by preference — most widely supported Arabic locales first.
  static const List<String> _arabicPrefixes = <String>[
    'ar-SA', 'ar-EG', 'ar-AE', 'ar-JO', 'ar-KW', 'ar-QA', 'ar',
  ];

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
      if (!_isAvailable) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _isAvailable = await _speech.initialize(
          onStatus: _handleStatus,
          onError: _handleError,
        );
      }
      if (_isAvailable) {
        final List<stt.LocaleName> locales = await _speech.locales();
        _localeId = _findArabicLocale(locales);
        if (_localeId == null) {
          _isAvailable = false;
        }
      }
    } catch (_) {
      _isAvailable = false;
    }
    return _isAvailable;
  }

  static String _normalizeLocaleId(String id) =>
      id.toLowerCase().replaceAll('_', '-');

  String? _findArabicLocale(List<stt.LocaleName> locales) {
    for (final String prefix in _arabicPrefixes) {
      final String normalizedPrefix = _normalizeLocaleId(prefix);
      final stt.LocaleName? match = locales.cast<stt.LocaleName?>().firstWhere(
        (stt.LocaleName? l) =>
            l != null &&
            _normalizeLocaleId(l.localeId).startsWith(normalizedPrefix),
        orElse: () => null,
      );
      if (match != null) return match.localeId;
    }
    return null;
  }

  void _handleStatus(String status) {
    final bool listening = status == 'listening';
    _isListening = listening;
    _onStatus?.call(listening);
    // Restart if the session ended naturally while we still want to listen.
    if (!listening && _wantListening) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_wantListening && !_speech.isListening) _startSession();
      });
    }
  }

  void _handleError(stt_error.SpeechRecognitionError error) {
    // Timeouts and no-match are normal in dictation mode — ignore them.
    if (error.errorMsg != 'error_speech_timeout' &&
        error.errorMsg != 'error_no_match') {
      _onError?.call(error.errorMsg);
    }
  }

  Future<void> startListening({
    required SpeechResultCallback onResult,
    SpeechStatusCallback? onStatus,
    SpeechErrorCallback? onError,
  }) async {
    if (!_isAvailable) {
      onError?.call(
        'Arabic speech recognition is not available on this device. '
        'Install an Arabic language pack in your device settings.',
      );
      return;
    }
    _onResult = onResult;
    _onStatus = onStatus;
    _onError = onError;
    _wantListening = true;
    await _startSession();
  }

  Future<void> _startSession() async {
    if (!_wantListening || !_isAvailable || _speech.isListening) return;

    final bool started = await _speech.listen(
      localeId: _localeId,
      listenFor: const Duration(minutes: 10),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
      ),
      onResult: (stt_result.SpeechRecognitionResult result) {
        if (result.recognizedWords.isNotEmpty) {
          _onResult?.call(result.recognizedWords, result.finalResult);
        }
      },
    );

    _isListening = started;
    _onStatus?.call(started);
  }

  Future<void> stopListening() async {
    _wantListening = false;
    _onResult = null;
    _onStatus = null;
    _onError = null;
    if (_speech.isListening) {
      await _speech.stop();
    }
    _isListening = false;
  }

  void dispose() {
    _wantListening = false;
    _isListening = false;
    _onResult = null;
    _onStatus = null;
    _onError = null;
    _speech.cancel();
  }
}
