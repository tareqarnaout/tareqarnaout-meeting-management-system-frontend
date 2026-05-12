// Web implementation using dart:js_interop (Dart 3 / Flutter 3.13+).
// Uses the browser's built-in Web Speech API directly.
// Works on Chrome and Edge on both HTTP (localhost) and HTTPS (Azure).
// Safari has limited/no support — an error message is shown automatically.
import 'dart:async';
import 'dart:js_interop';

// ---------- Web Speech API bindings ----------

// Base extension type with all members shared between both variants.
extension type _SpeechRecognition._(JSObject _) implements JSObject {
  external set lang(String value);
  external set continuous(bool value);
  external set interimResults(bool value);
  external set maxAlternatives(int value);
  external set onstart(JSFunction? value);
  external set onresult(JSFunction? value);
  external set onerror(JSFunction? value);
  external set onend(JSFunction? value);
  external void start();
  external void abort();
}

// Standard variant (Chrome 33+, Edge 79+).
@JS('SpeechRecognition')
extension type _StdRecognition._(JSObject _) implements _SpeechRecognition {
  external factory _StdRecognition();
}

// Webkit-prefixed variant (older Chrome builds).
@JS('webkitSpeechRecognition')
extension type _WkRecognition._(JSObject _) implements _SpeechRecognition {
  external factory _WkRecognition();
}

extension type _SpeechRecognitionEvent._(JSObject _) implements JSObject {
  external int get resultIndex;
  external _SpeechRecognitionResultList get results;
}

extension type _SpeechRecognitionResultList._(JSObject _) implements JSObject {
  external int get length;
  external _SpeechRecognitionResult item(int index);
}

extension type _SpeechRecognitionResult._(JSObject _) implements JSObject {
  external bool get isFinal;
  external _SpeechRecognitionAlternative item(int index);
}

extension type _SpeechRecognitionAlternative._(JSObject _) implements JSObject {
  external String get transcript;
}

extension type _SpeechRecognitionErrorEvent._(JSObject _) implements JSObject {
  external String get error;
}

// ---------- Service ----------

typedef SpeechResultCallback = void Function(String text, bool isFinal);
typedef SpeechStatusCallback = void Function(bool isListening);
typedef SpeechErrorCallback = void Function(String error);

class ArabicSpeechService {
  bool _isAvailable = false;
  bool _isListening = false;
  bool _wantListening = false;
  _SpeechRecognition? _recognition;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  bool get isDownloadingModel => false;

  SpeechResultCallback? _onResult;
  SpeechStatusCallback? _onStatus;
  SpeechErrorCallback? _onError;

  Future<bool> initialize() async {
    _isAvailable = _tryCreateRecognition() != null;
    return _isAvailable;
  }

  /// Tries the standard constructor first, then the webkit-prefixed fallback.
  _SpeechRecognition? _tryCreateRecognition() {
    try {
      return _StdRecognition();
    } catch (_) {
      try {
        return _WkRecognition();
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> startListening({
    required SpeechResultCallback onResult,
    SpeechStatusCallback? onStatus,
    SpeechErrorCallback? onError,
  }) async {
    if (!_isAvailable) {
      onError?.call(
        'Arabic speech recognition requires Chrome or Edge. '
        'Please switch browsers and try again.',
      );
      return;
    }
    _onResult = onResult;
    _onStatus = onStatus;
    _onError = onError;
    _wantListening = true;
    _startSession();
  }

  void _startSession() {
    if (!_wantListening) return;

    final _SpeechRecognition? rec = _tryCreateRecognition();
    if (rec == null) return;
    _recognition = rec;

    rec.lang = 'ar-SA';
    // continuous = true keeps one live session running across phrases.
    // onend only fires on an unexpected stop (error / timeout), at which
    // point we restart below — no 250ms gaps between words.
    rec.continuous = true;
    rec.interimResults = true;
    rec.maxAlternatives = 1;

    rec.onstart = ((JSAny? _) {
      _isListening = true;
      _onStatus?.call(true);
    }).toJS;

    rec.onresult = ((JSAny? event) {
      if (event == null) return;
      try {
        final _SpeechRecognitionEvent ev =
            event as _SpeechRecognitionEvent;
        final _SpeechRecognitionResultList results = ev.results;
        final int start = ev.resultIndex;
        final int len = results.length;
        for (int i = start; i < len; i++) {
          final _SpeechRecognitionResult result = results.item(i);
          final String text = result.item(0).transcript;
          if (text.isNotEmpty) {
            _onResult?.call(text, result.isFinal);
          }
        }
      } catch (_) {
        // Silently ignore malformed events; the next phrase will retry.
      }
    }).toJS;

    rec.onerror = ((JSAny? event) {
      if (event == null) return;
      try {
        final String error =
            (event as _SpeechRecognitionErrorEvent).error;
        // 'no-speech' fires after a silent pause — normal, not a failure.
        // 'aborted' fires when we call abort() ourselves — also expected.
        if (error != 'no-speech' && error != 'aborted') {
          _onError?.call('Speech recognition error: $error');
        }
      } catch (_) {}
    }).toJS;

    rec.onend = ((JSAny? _) {
      _isListening = false;
      _recognition = null;
      _onStatus?.call(false);
      // Session ended unexpectedly (network drop, timeout) — restart.
      if (_wantListening) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_wantListening) _startSession();
        });
      }
    }).toJS;

    try {
      rec.start();
    } catch (e) {
      _isListening = false;
      _recognition = null;
      _onError?.call('Failed to start Arabic speech recognition: $e');
    }
  }

  Future<void> stopListening() async {
    _wantListening = false;
    // Null callbacks first so onend doesn't fire status updates after stop.
    _onResult = null;
    _onStatus = null;
    _onError = null;
    if (_isListening) {
      try {
        _recognition?.abort();
      } catch (_) {}
    }
    _isListening = false;
    _recognition = null;
  }

  void dispose() {
    _wantListening = false;
    try {
      _recognition?.abort();
    } catch (_) {}
    _recognition = null;
    _isListening = false;
    _onResult = null;
    _onStatus = null;
    _onError = null;
  }
}
