// Conditional export: web uses the Web Speech API directly via JS interop;
// native (iOS/Android) uses the speech_to_text package.
export 'arabic_speech_service_io.dart'
    if (dart.library.html) 'arabic_speech_service_web.dart';
