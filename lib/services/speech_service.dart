import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) {},
        onStatus: (val) {},
      );
      return _isAvailable;
    } catch (_) {
      _isAvailable = false;
      return false;
    }
  }

  void startListening(Function(String text) onResult) async {
    if (!_isAvailable) {
      await initialize();
    }
    if (_isAvailable) {
      _speech.listen(
        localeId: 'nb_NO', // Norsk Bokmål
        onResult: (val) {
          onResult(val.recognizedWords);
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
  }
}
