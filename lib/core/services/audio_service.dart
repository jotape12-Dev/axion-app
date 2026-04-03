import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  StreamController<double>? _amplitudeController;
  Timer? _amplitudeTimer;
  String? _recordingPath;

  /// Called when TTS finishes speaking — set this before calling [speak].
  void Function()? onTtsComplete;

  Stream<double>? get amplitudeStream => _amplitudeController?.stream;

  Future<void> initTts() async {
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      onTtsComplete?.call();
    });

    _tts.setErrorHandler((message) {
      debugPrint('TTS error: $message');
      // Trigger completion anyway so interview doesn't stall
      onTtsComplete?.call();
    });
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/answer_${DateTime.now().millisecondsSinceEpoch}.m4a';

    _amplitudeController = StreamController<double>.broadcast();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _recordingPath!,
    );

    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (await _recorder.isRecording()) {
        final amp = await _recorder.getAmplitude();
        _amplitudeController?.add(amp.current);
      }
    });
  }

  Future<Uint8List?> stopRecording() async {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    await _amplitudeController?.close();
    _amplitudeController = null;

    if (!await _recorder.isRecording()) return null;

    final path = await _recorder.stop();
    if (path == null) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    await file.delete();
    return bytes;
  }

  void dispose() {
    _amplitudeTimer?.cancel();
    _amplitudeController?.close();
    _tts.stop();
    _recorder.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  service.initTts();
  ref.onDispose(service.dispose);
  return service;
});
