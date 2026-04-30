import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart' as stt_result;

class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;

  Future<bool> initialize({String? localeId}) async {
    _available = await _speech.initialize();
    return _available;
  }

  bool get isAvailable => _available;

  bool get isListening => _speech.isListening;

  Future<bool> startListening({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_available) {
      return false;
    }

    await _speech.listen(
      localeId: localeId,
      partialResults: true,
      onResult: (stt_result.SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
    return true;
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
