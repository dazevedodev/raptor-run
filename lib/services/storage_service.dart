import 'package:shared_preferences/shared_preferences.dart';

import '../game/characters.dart';
import '../game/skins.dart';

/// Guarda o progresso do jogador (moedas, recorde, resgate diário) no
/// armazenamento local do aparelho.
class StorageService {
  static const _keyCoins = 'coins';
  static const _keyBestScore = 'best_score';
  static const _keyLastRewardDate = 'last_reward_date';
  static const _keyStreak = 'streak';
  static const _keyOwnedSkins = 'owned_skins';
  static const _keySelectedSkin = 'selected_skin';
  static const _keyOwnedCharacters = 'owned_characters';
  static const _keySelectedCharacter = 'selected_character';
  static const _keyMusicEnabled = 'music_enabled';
  static const _keySfxEnabled = 'sfx_enabled';
  static const _keyControlScheme = 'control_scheme';
  static const _keyHasSeenTutorial = 'has_seen_tutorial';
  static const _defaultSkinId = 'crimson';
  static const _defaultCharacterId = 'dino';
  static const _defaultControlScheme = 'swipe';

  Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCoins) ?? 0;
  }

  Future<int> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(_keyCoins) ?? 0) + amount;
    await prefs.setInt(_keyCoins, total);
    return total;
  }

  Future<int> getBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBestScore) ?? 0;
  }

  /// Atualiza o recorde se [score] for maior que o salvo. Retorna true se
  /// bateu recorde novo.
  Future<bool> setBestScoreIfHigher(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_keyBestScore) ?? 0;
    if (score > best) {
      await prefs.setInt(_keyBestScore, score);
      return true;
    }
    return false;
  }

  Future<DateTime?> getLastRewardDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLastRewardDate);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastRewardDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastRewardDate, date.toIso8601String());
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }

  Future<void> setStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStreak, streak);
  }

  /// Tenta gastar [amount] moedas. Retorna true e desconta se havia saldo
  /// suficiente; retorna false e não mexe no saldo caso contrário.
  Future<bool> spendCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyCoins) ?? 0;
    if (current < amount) return false;
    await prefs.setInt(_keyCoins, current - amount);
    return true;
  }

  /// Skins gratuitas (price == 0) já vêm desbloqueadas pra todo mundo —
  /// hoje só a Carmesim.
  Future<Set<String>> getOwnedSkinIds() async {
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList(_keyOwnedSkins);
    final freeIds = kSkins.where((s) => s.price == 0).map((s) => s.id);
    return {...freeIds, ...?owned};
  }

  Future<void> addOwnedSkin(String skinId) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = <String>{...prefs.getStringList(_keyOwnedSkins) ?? [], skinId};
    await prefs.setStringList(_keyOwnedSkins, owned.toList());
  }

  Future<String> getSelectedSkinId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedSkin) ?? _defaultSkinId;
  }

  Future<void> setSelectedSkinId(String skinId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedSkin, skinId);
  }

  /// Personagens gratuitos (price == 0) já vêm desbloqueados pra todo
  /// mundo, sem precisar comprar — hoje são Dino e Rato.
  Future<Set<String>> getOwnedCharacterIds() async {
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList(_keyOwnedCharacters);
    final freeIds = kCharacters.where((c) => c.price == 0).map((c) => c.id);
    return {...freeIds, ...?owned};
  }

  Future<void> addOwnedCharacter(String characterId) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = <String>{...prefs.getStringList(_keyOwnedCharacters) ?? [], characterId};
    await prefs.setStringList(_keyOwnedCharacters, owned.toList());
  }

  Future<String> getSelectedCharacterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedCharacter) ?? _defaultCharacterId;
  }

  Future<void> setSelectedCharacterId(String characterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedCharacter, characterId);
  }

  Future<bool> getMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMusicEnabled) ?? true;
  }

  Future<void> setMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMusicEnabled, value);
  }

  Future<bool> getSfxEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySfxEnabled) ?? true;
  }

  Future<void> setSfxEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySfxEnabled, value);
  }

  /// 'swipe' (deslizar na tela) ou 'buttons' (botões na tela).
  Future<String> getControlScheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyControlScheme) ?? _defaultControlScheme;
  }

  Future<void> setControlScheme(String scheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyControlScheme, scheme);
  }

  Future<bool> getHasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenTutorial) ?? false;
  }

  Future<void> setHasSeenTutorial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenTutorial, value);
  }
}
