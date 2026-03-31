import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { playing, stopped, paused }

class VoiceNavigationService {
  static final FlutterTts _flutterTts = FlutterTts();
  static TtsState _state = TtsState.stopped;
  static bool _isEnabled = true;
  static double _speechRate = 0.5;
  static final double _volume = 1.0;
  static final double _pitch = 1.0;

  static Future<void> initialize() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);

    _flutterTts.setStartHandler(() {
      _state = TtsState.playing;
    });

    _flutterTts.setCompletionHandler(() {
      _state = TtsState.stopped;
    });

    _flutterTts.setCancelHandler(() {
      _state = TtsState.stopped;
    });

    _flutterTts.setErrorHandler((msg) {
      _state = TtsState.stopped;
    });

    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('voice_navigation_enabled') ?? true;
    _speechRate = prefs.getDouble('voice_speech_rate') ?? 0.5;
    await _flutterTts.setSpeechRate(_speechRate);
  }

  static bool get isEnabled => _isEnabled;
  static TtsState get state => _state;

  static Future<void> speak(String text) async {
    if (!_isEnabled || text.isEmpty) return;
    if (_state == TtsState.playing) {
      await stop();
    }
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
    _state = TtsState.stopped;
  }

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice_navigation_enabled', enabled);
    if (!enabled) {
      await stop();
    }
  }

  static Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voice_speech_rate', rate);
  }

  static Future<void> speakTurnInstruction(
      String instruction, String distance) async {
    if (!_isEnabled) return;

    String text = '';
    if (distance.isNotEmpty) {
      text = '$distance. $instruction';
    } else {
      text = instruction;
    }
    await speak(text);
  }

  static Future<void> speakArrival(String destination) async {
    if (!_isEnabled) return;
    await speak('You have arrived at $destination');
  }

  static Future<void> speakRerouting() async {
    if (!_isEnabled) return;
    await speak('Recalculating route');
  }

  static Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
