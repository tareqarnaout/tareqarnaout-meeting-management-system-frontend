import 'dart:async';
import 'dart:convert';
import 'package:vosk_flutter_service/vosk_flutter.dart';

typedef SpeechResultCallback = void Function(String text, bool isFinal);
typedef SpeechStatusCallback = void Function(bool isListening);
typedef SpeechErrorCallback = void Function(String error);

class ArabicSpeechService {
  static const String _modelUrl =
      'https://alphacephei.com/vosk/models/vosk-model-ar-mgb2-0.4.zip';
  static const int _sampleRate = 16000;

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  final ModelLoader _modelLoader = ModelLoader();

  bool _isAvailable = false;
  bool _isListening = false;
  bool _isDownloadingModel = false;

  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  StreamSubscription<String>? _partialSub;
  StreamSubscription<String>? _resultSub;

  SpeechResultCallback? _onResult;
  SpeechStatusCallback? _onStatus;
  SpeechErrorCallback? _onError;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  bool get isDownloadingModel => _isDownloadingModel;

  Future<bool> initialize() async {
    try {
      _isDownloadingModel = true;
      final String modelPath = await _modelLoader.loadFromNetwork(_modelUrl);
      _isDownloadingModel = false;

      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: _sampleRate,
      );
      _speechService = await _vosk.initSpeechService(_recognizer!);
      _isAvailable = true;
    } catch (_) {
      _isDownloadingModel = false;
      _isAvailable = false;
    }
    return _isAvailable;
  }

  Future<void> startListening({
    required SpeechResultCallback onResult,
    SpeechStatusCallback? onStatus,
    SpeechErrorCallback? onError,
  }) async {
    if (!_isAvailable || _speechService == null) {
      onError?.call(
        'Arabic speech recognition is not available. '
        'Please check your internet connection and try again.',
      );
      return;
    }

    _onResult = onResult;
    _onStatus = onStatus;
    _onError = onError;

    _partialSub?.cancel();
    _resultSub?.cancel();

    _partialSub = _speechService!.onPartial().listen((String json) {
      final String text = _extractText(json, key: 'partial');
      if (text.isNotEmpty) {
        _onResult?.call(text, false);
      }
    });

    _resultSub = _speechService!.onResult().listen((String json) {
      final String text = _extractText(json, key: 'text');
      if (text.isNotEmpty) {
        _onResult?.call(text, true);
      }
    });

    try {
      await _speechService!.start();
      _isListening = true;
      _onStatus?.call(true);
    } catch (e) {
      _isListening = false;
      _onError?.call('Failed to start speech recognition: $e');
    }
  }

  static String _extractText(String json, {required String key}) {
    try {
      final Map<String, dynamic> map =
          jsonDecode(json) as Map<String, dynamic>;
      return (map[key] as String?)?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> stopListening() async {
    _onResult = null;
    _onStatus = null;
    _onError = null;
    await _partialSub?.cancel();
    await _resultSub?.cancel();
    _partialSub = null;
    _resultSub = null;
    if (_isListening) {
      try {
        await _speechService?.stop();
      } catch (_) {}
    }
    _isListening = false;
  }

  void dispose() {
    _onResult = null;
    _onStatus = null;
    _onError = null;
    _partialSub?.cancel();
    _resultSub?.cancel();
    _partialSub = null;
    _resultSub = null;
    _isListening = false;
    try {
      _speechService?.stop();
    } catch (_) {}
  }
}
