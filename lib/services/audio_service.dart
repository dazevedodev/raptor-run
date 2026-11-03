import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'storage_service.dart';

/// Efeitos sonoros e música de fundo do jogo — todos os arquivos em
/// assets/audio/ são sintetizados (tool/generate_audio.dart), sem nenhum
/// áudio de terceiros. Respeita as preferências de som/efeitos salvas em
/// [StorageService].
class AudioService {
  AudioService._internal();
  static final AudioService instance = AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final _storage = StorageService();

  bool _bgmStarted = false;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _initialized = false;

  /// Carrega as preferências salvas. Chamar uma vez, antes de tocar
  /// qualquer som (a tela inicial faz isso no início).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _musicEnabled = await _storage.getMusicEnabled();
    _sfxEnabled = await _storage.getSfxEnabled();
  }

  Future<void> _playSfx(String fileName) async {
    if (!_sfxEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      unawaited(player.play(AssetSource('audio/$fileName')));
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (_) {
      // Som é só um extra — se o áudio falhar (plataforma sem suporte etc.),
      // o jogo continua normalmente.
    }
  }

  Future<void> playJump() => _playSfx('jump.wav');
  Future<void> playCoin() => _playSfx('coin.wav');
  Future<void> playGameOver() => _playSfx('game_over.wav');

  Future<void> startBackgroundMusic() async {
    if (_bgmStarted) return;
    _bgmStarted = true;
    try {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(0.45);
      if (_musicEnabled) {
        await _bgmPlayer.play(AssetSource('audio/bgm.wav'));
      }
    } catch (_) {
      _bgmStarted = false;
    }
  }

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    await _storage.setMusicEnabled(value);
    try {
      if (value) {
        if (_bgmStarted) {
          await _bgmPlayer.resume();
        } else {
          await startBackgroundMusic();
        }
      } else {
        await _bgmPlayer.pause();
      }
    } catch (_) {
      // Ignora falha de plataforma — a preferência já foi salva.
    }
  }

  Future<void> setSfxEnabled(bool value) async {
    _sfxEnabled = value;
    await _storage.setSfxEnabled(value);
  }
}
