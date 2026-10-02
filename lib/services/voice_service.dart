import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../theme/app_locale.dart';

/// Lecture audio des réponses (text-to-speech) et saisie vocale (speech-to-text),
/// façon Gemini/ChatGPT.
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();
  bool _speechInitialized = false;

  Future<void> speak(String text) async {
    final locale = AppLocale.instance.language == AppLanguage.en ? 'en-US' : 'fr-FR';
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();

  void onSpeakComplete(void Function() callback) {
    _tts.setCompletionHandler(callback);
  }

  Future<bool> _ensureInitialized() async {
    if (_speechInitialized) return true;
    _speechInitialized = await _speech.initialize();
    return _speechInitialized;
  }

  /// Démarre l'écoute. [onResult] est appelé avec le texte reconnu à chaque
  /// mise à jour (résultats partiels puis final). [onDone] est appelé quand
  /// l'écoute s'arrête (silence détecté ou arrêt manuel).
  Future<bool> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
  }) async {
    final ok = await _ensureInitialized();
    if (!ok) return false;
    final locale = AppLocale.instance.language == AppLanguage.en ? 'en_US' : 'fr_FR';
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: locale,
      listenOptions: SpeechListenOptions(partialResults: true),
    );
    return true;
  }

  Future<void> stopListening() => _speech.stop();

  bool get isListening => _speech.isListening;
}
