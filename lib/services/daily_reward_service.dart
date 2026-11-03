import 'storage_service.dart';

/// Recompensas em moedas por dia seguido de resgate (dia 1 ao dia 7).
/// Depois do dia 7 o ciclo recomeça no dia 1.
const List<int> dailyRewardTable = [10, 15, 20, 25, 30, 40, 50];

class DailyRewardResult {
  final bool alreadyClaimedToday;
  final int coinsAwarded;
  final int streak;

  const DailyRewardResult({
    required this.alreadyClaimedToday,
    required this.coinsAwarded,
    required this.streak,
  });
}

class DailyRewardService {
  DailyRewardService(this._storage);

  final StorageService _storage;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<bool> isAvailableToday() async {
    final last = await _storage.getLastRewardDate();
    if (last == null) return true;
    return !_isSameDay(last, DateTime.now());
  }

  int rewardForStreak(int streak) {
    final index = (streak - 1).clamp(0, dailyRewardTable.length - 1);
    return dailyRewardTable[index];
  }

  /// Em qual dia do ciclo (1 a 7) o resgate de hoje cairia, sem resgatar de
  /// verdade — usado pra mostrar o calendário antes da pessoa confirmar.
  Future<int> previewDayForToday() async {
    final now = DateTime.now();
    final last = await _storage.getLastRewardDate();
    final currentStreak = await _storage.getStreak();

    if (last != null && _isSameDay(last, now)) {
      return currentStreak > dailyRewardTable.length ? 1 : currentStreak;
    }
    if (last != null && _isSameDay(last, now.subtract(const Duration(days: 1)))) {
      final next = currentStreak + 1;
      return next > dailyRewardTable.length ? 1 : next;
    }
    return 1;
  }

  /// Resgata a recompensa do dia, se ainda não resgatada hoje. Se o último
  /// resgate foi ontem, a ofensiva (streak) aumenta; se pulou um dia, reseta.
  Future<DailyRewardResult> claim() async {
    final now = DateTime.now();
    final last = await _storage.getLastRewardDate();

    if (last != null && _isSameDay(last, now)) {
      final streak = await _storage.getStreak();
      return DailyRewardResult(
        alreadyClaimedToday: true,
        coinsAwarded: 0,
        streak: streak,
      );
    }

    int streak = await _storage.getStreak();
    if (last != null && _isSameDay(last, now.subtract(const Duration(days: 1)))) {
      streak += 1;
    } else {
      streak = 1;
    }
    if (streak > dailyRewardTable.length) streak = 1;

    final coins = rewardForStreak(streak);
    await _storage.addCoins(coins);
    await _storage.setLastRewardDate(now);
    await _storage.setStreak(streak);

    return DailyRewardResult(
      alreadyClaimedToday: false,
      coinsAwarded: coins,
      streak: streak,
    );
  }
}
