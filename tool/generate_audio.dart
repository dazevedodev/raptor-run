// Gera os efeitos sonoros e a musiquinha de fundo do jogo por síntese
// (ondas senoidais/quadradas/triangulares calculadas na mão) — 100% original,
// sem nenhum arquivo de terceiros, sem risco de direitos autorais.
//
// Rodar com: dart run tool/generate_audio.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;

double squareWave(double phase) => sin(phase) >= 0 ? 1.0 : -1.0;
double triangleWave(double phase) => (2 / pi) * asin(sin(phase));
double sineWave(double phase) => sin(phase);

typedef Waveform = double Function(double phase);

/// Envelope simples de ataque/decaimento pra evitar cliques no começo/fim.
double envelope(double t, double duration, {double attack = 0.01, double release = 0.05}) {
  if (t < attack) return t / attack;
  if (t > duration - release) return max(0, (duration - t) / release);
  return 1.0;
}

List<double> tone({
  required double startFreq,
  required double endFreq,
  required double duration,
  required Waveform wave,
  double volume = 0.5,
}) {
  final samples = <double>[];
  final n = (duration * sampleRate).round();
  double phase = 0;
  for (int i = 0; i < n; i++) {
    final t = i / sampleRate;
    final freq = startFreq + (endFreq - startFreq) * (t / duration);
    phase += 2 * pi * freq / sampleRate;
    final env = envelope(t, duration);
    samples.add(wave(phase) * volume * env);
  }
  return samples;
}

List<double> silence(double duration) => List.filled((duration * sampleRate).round(), 0.0);

List<double> mix(List<List<double>> tracks) {
  final length = tracks.map((t) => t.length).reduce(max);
  final result = List.filled(length, 0.0);
  for (final track in tracks) {
    for (int i = 0; i < track.length; i++) {
      result[i] += track[i];
    }
  }
  return result;
}

List<double> concat(List<List<double>> parts) => parts.expand((p) => p).toList();

void writeWav(String path, List<double> samples) {
  final data = Int16List(samples.length);
  for (int i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    data[i] = (clamped * 32767).round();
  }

  final dataBytes = data.buffer.asUint8List();
  final byteRate = sampleRate * 2;
  final builder = BytesBuilder();

  void writeString(String s) => builder.add(s.codeUnits);
  void writeUint32(int v) => builder.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
  void writeUint16(int v) => builder.add([v & 0xFF, (v >> 8) & 0xFF]);

  writeString('RIFF');
  writeUint32(36 + dataBytes.length);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(1); // mono
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(2); // block align
  writeUint16(16); // bits per sample
  writeString('data');
  writeUint32(dataBytes.length);
  builder.add(dataBytes);

  File(path).writeAsBytesSync(builder.toBytes());
  print('Escrito: $path (${samples.length} amostras, ${(samples.length / sampleRate).toStringAsFixed(2)}s)');
}

// Frequências das notas usadas na musiquinha (escala pentatônica de dó maior).
const g4 = 392.00, a4 = 440.00;
const c5 = 523.25, d5 = 587.33, e5 = 659.25, g5 = 783.99;
const c3 = 130.81, g3 = 196.00, a3 = 220.00, f3 = 174.61;

void main() {
  final dir = Directory('assets/audio');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Pulo: bipe curto subindo de grave pra agudo.
  writeWav(
    'assets/audio/jump.wav',
    tone(startFreq: 320, endFreq: 720, duration: 0.14, wave: sineWave, volume: 0.55),
  );

  // Moeda: dois bipes agudos em sequência (efeito "arcade" clássico).
  writeWav(
    'assets/audio/coin.wav',
    concat([
      tone(startFreq: 880, endFreq: 880, duration: 0.07, wave: squareWave, volume: 0.35),
      tone(startFreq: 1318, endFreq: 1318, duration: 0.12, wave: squareWave, volume: 0.35),
    ]),
  );

  // Fim de jogo: descida grave e "choraminga".
  writeWav(
    'assets/audio/game_over.wav',
    tone(startFreq: 420, endFreq: 100, duration: 0.55, wave: squareWave, volume: 0.4),
  );

  // Musiquinha de fundo: melodia alegre em loop + baixo, ~4s (repete via player em loop).
  final melodyNotes = [
    c5, e5, g5, e5, //
    a4, g4, a4, g4,
    e5, d5, c5, d5,
    e5, c5, d5, g4,
  ];
  final noteDuration = 0.25;
  final melody = concat([
    for (final freq in melodyNotes)
      tone(startFreq: freq, endFreq: freq, duration: noteDuration * 0.85, wave: squareWave, volume: 0.22)
        .followedBySilence(noteDuration * 0.15),
  ]);

  final bassNotes = [c3, c3, g3, g3, a3, a3, f3, f3];
  final bassNoteDuration = 0.5;
  final bass = concat([
    for (final freq in bassNotes)
      tone(startFreq: freq, endFreq: freq, duration: bassNoteDuration * 0.9, wave: triangleWave, volume: 0.18)
        .followedBySilence(bassNoteDuration * 0.1),
  ]);

  writeWav('assets/audio/bgm.wav', mix([melody, bass]));

  print('Pronto! ${dir.path} gerado.');
}

extension on List<double> {
  List<double> followedBySilence(double duration) => [...this, ...silence(duration)];
}
