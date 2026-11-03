import 'package:flutter/material.dart';

import '../game/character_renderer.dart';
import '../game/characters.dart';
import '../game/skins.dart';
import '../services/audio_service.dart';
import '../services/daily_reward_service.dart';
import '../services/storage_service.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

const _kBackgroundTop = Color(0xFF17332B);
const _kBackgroundBottom = Color(0xFF0A1712);
const _kAmber = Color(0xFFF2A93B);
const _kAmberDeep = Color(0xFFD9812A);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService();
  late final DailyRewardService _rewardService = DailyRewardService(_storage);

  int _coins = 0;
  int _bestScore = 0;
  bool _rewardAvailable = false;
  bool _loading = true;
  Skin _skin = kSkins.first;

  @override
  void initState() {
    super.initState();
    _load();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await AudioService.instance.init();
    await AudioService.instance.startBackgroundMusic();
  }

  Future<void> _load() async {
    final coins = await _storage.getCoins();
    final best = await _storage.getBestScore();
    final available = await _rewardService.isAvailableToday();
    final skinId = await _storage.getSelectedSkinId();
    if (!mounted) return;
    setState(() {
      _coins = coins;
      _bestScore = best;
      _rewardAvailable = available;
      _skin = skinForId(skinId);
      _loading = false;
    });
  }

  Future<void> _openDailyReward() async {
    final day = await _rewardService.previewDayForToday();
    if (!mounted) return;
    final coinsWon = await showDialog<int>(
      context: context,
      builder: (context) => _DailyRewardDialog(
        currentDay: day,
        alreadyClaimedToday: !_rewardAvailable,
        rewardService: _rewardService,
      ),
    );
    if (coinsWon != null) {
      setState(() {
        _coins += coinsWon;
        _rewardAvailable = false;
      });
    }
  }

  Future<void> _openGame() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameScreen()));
    _load();
  }

  Future<void> _openShop() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen()));
    _load();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kBackgroundTop, _kBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kAmber))
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CoinBadge(coins: _coins),
                          _RewardButton(available: _rewardAvailable, onTap: _openDailyReward),
                        ],
                      ),
                      const Spacer(),
                      _CharacterShowcase(skin: _skin),
                      const SizedBox(height: 16),
                      const Text(
                        'RAPTOR RUN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [Shadow(color: Colors.black45, offset: Offset(0, 3), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recorde: $_bestScore',
                        style: const TextStyle(fontSize: 16, color: Colors.white60, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      _PlayButton(onTap: _openGame),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GhostButton(label: '🛍️ Loja', onTap: _openShop),
                          const SizedBox(width: 12),
                          _GhostButton(label: '⚙️ Config', onTap: _openSettings),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CharacterShowcase extends StatelessWidget {
  const _CharacterShowcase({required this.skin});

  final Skin skin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_kAmber.withValues(alpha: 0.35), _kAmber.withValues(alpha: 0.0)],
              ),
            ),
          ),
          SizedBox(
            width: 150,
            height: 130,
            child: CustomPaint(painter: _HomeCharacterPainter(skin)),
          ),
        ],
      ),
    );
  }
}

class _HomeCharacterPainter extends CustomPainter {
  _HomeCharacterPainter(this.skin);

  final Skin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = Rect.fromLTWH(size.width * 0.08, size.height * 0.1, size.width * 0.7, size.height * 0.78);
    CharacterRenderer.draw(
      canvas,
      bodyRect,
      shape: CharacterShape.dino,
      bodyColor: skin.bodyColor,
      legColor: skin.legColor,
      hasCapAndChain: skin.hasCapAndChain,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeCharacterPainter oldDelegate) => oldDelegate.skin != skin;
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kAmber, _kAmberDeep]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: _kAmberDeep.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Text(
          'JOGAR',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1B1204), letterSpacing: 1),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Text('🪙', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text('$coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class _RewardButton extends StatelessWidget {
  const _RewardButton({required this.available, required this.onTap});

  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: available ? _kAmber : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: available ? null : Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: available
              ? [BoxShadow(color: _kAmber.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              available ? 'Resgatar' : 'Resgatado',
              style: TextStyle(
                color: available ? const Color(0xFF1B1204) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendário do resgate diário — mostra os 7 dias do ciclo e a moeda de
/// cada um, com o dia de hoje em destaque, os já resgatados marcados e os
/// futuros bloqueados. Substitui o popup antigo que só dizia "+X moedas"
/// sem mostrar o que vinha pela frente.
class _DailyRewardDialog extends StatefulWidget {
  const _DailyRewardDialog({
    required this.currentDay,
    required this.alreadyClaimedToday,
    required this.rewardService,
  });

  final int currentDay;
  final bool alreadyClaimedToday;
  final DailyRewardService rewardService;

  @override
  State<_DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<_DailyRewardDialog> {
  late bool _claimedToday = widget.alreadyClaimedToday;
  bool _claiming = false;
  int? _coinsJustWon;

  Future<void> _claim() async {
    setState(() => _claiming = true);
    final result = await widget.rewardService.claim();
    if (!mounted) return;
    setState(() {
      _claiming = false;
      _claimedToday = true;
      _coinsJustWon = result.alreadyClaimedToday ? null : result.coinsAwarded;
    });
    AudioService.instance.playCoin();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1D3A31),
      title: const Text('🎁 Resgate diário', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_coinsJustWon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '+$_coinsJustWon moedas! 🎉',
                  style: const TextStyle(color: _kAmber, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dailyRewardTable.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final day = index + 1;
                final coins = dailyRewardTable[index];
                final isToday = day == widget.currentDay;
                final isPast = day < widget.currentDay;
                final claimed = isPast || (isToday && _claimedToday);
                return _DayCard(
                  day: day,
                  coins: coins,
                  claimed: claimed,
                  isToday: isToday && !_claimedToday,
                  locked: day > widget.currentDay,
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              _claimedToday
                  ? 'Você já resgatou hoje. Volte amanhã pra continuar a sequência!'
                  : 'Toque em "Resgatar" pra receber a recompensa de hoje.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        if (!_claimedToday)
          ElevatedButton(
            onPressed: _claiming ? null : _claim,
            style: ElevatedButton.styleFrom(backgroundColor: _kAmber),
            child: Text(
              _claiming ? '...' : 'Resgatar',
              style: const TextStyle(color: Color(0xFF1B1204), fontWeight: FontWeight.bold),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_coinsJustWon),
          child: const Text('Fechar', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.coins,
    required this.claimed,
    required this.isToday,
    required this.locked,
  });

  final int day;
  final int coins;
  final bool claimed;
  final bool isToday;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final background = claimed
        ? const Color(0xFF2C6B4A)
        : isToday
            ? _kAmber.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.04);
    final borderColor = isToday ? _kAmber : Colors.white.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isToday ? 2 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Dia $day',
            style: TextStyle(
              color: locked ? Colors.white30 : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (claimed)
            const Icon(Icons.check_circle, color: _kAmber, size: 20)
          else if (locked)
            Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.25), size: 16)
          else
            const Text('🪙', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            '$coins',
            style: TextStyle(
              color: locked ? Colors.white30 : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
