import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../game/characters.dart';
import '../game/dino_painter.dart';
import '../game/entities.dart';
import '../game/skins.dart';
import '../game/world_style.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  static const double groundHeight = 90;
  static const double playerSize = 56;
  static const double playerX = 50;
  static const double gravity = 1800;
  static const double jumpVelocity = -700;
  static const double baseSpeed = 260;
  // ⚠️ Ajustado 2x já: dividia distância por 25 (ficava quase impossível já
  // na pontuação 2300), depois por 75 (o usuário testou de verdade no
  // celular e ainda achou impossível). Agora a rampa usa /150 — na
  // pontuação 2300 a velocidade fica só ~1,25x a inicial — e o teto
  // (`maxExtraSpeed`, abaixo) também caiu de 2000 pra 900, então o jogo tem
  // um limite de verdade em vez de ficar "praticamente ilimitado": no pico
  // a velocidade é 260+900=1160, bem menos que os 2260 de antes.
  static const double maxExtraSpeed = 900;
  static const double duckHeightFactor = 0.55;
  static const Duration swipeDuckDuration = Duration(milliseconds: 500);
  static const double jumpEffectDuration = 0.25;
  static const double landingEffectDuration = 0.35;

  final _storage = StorageService();
  final _random = Random();

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  Timer? _duckTimer;

  GameStatus _status = GameStatus.ready;
  Size _boardSize = Size.zero;

  double _playerY = 0;
  double _playerVelocity = 0;
  bool _isDucking = false;
  // Contagem regressiva (segundos) de cada efeito — poeira ao pular/aterrissar.
  // Zero = sem efeito; DinoPainter usa timer/duração pra saber o quão "novo"
  // o efeito é e desenhar ele desaparecendo aos poucos.
  double _jumpEffectTimer = 0;
  double _landingEffectTimer = 0;
  double _speed = baseSpeed;
  double _distance = 0;
  // Segundos reais de corrida (não afetados pela velocidade/distância) —
  // usado só pra decidir a fase do mundo (dia/noite/extinção), ver
  // `world_style.dart`.
  double _playSeconds = 0;
  int _score = 0;
  int _runCoins = 0;
  int _bestScore = 0;

  double _spawnTimer = 0;
  double _nextSpawnIn = 1.1;
  final List<Obstacle> _obstacles = [];
  final List<Bird> _birds = [];
  final List<Collectible> _collectibles = [];

  bool _isNewBest = false;
  Skin _skin = kSkins.first;
  CharacterShape _characterShape = CharacterShape.dino;
  String _controlScheme = 'swipe';

  WorldStyle get _currentStyle => resolveWorldStyle(score: _score);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _loadBestScore();
    _loadPreferences();
  }

  Future<void> _loadBestScore() async {
    final best = await _storage.getBestScore();
    if (!mounted) return;
    setState(() => _bestScore = best);
  }

  Future<void> _loadPreferences() async {
    final skinId = await _storage.getSelectedSkinId();
    final characterId = await _storage.getSelectedCharacterId();
    final scheme = await _storage.getControlScheme();
    if (!mounted) return;
    setState(() {
      _skin = skinForId(skinId);
      _characterShape = characterForId(characterId).shape;
      _controlScheme = scheme;
    });
    await _maybeShowTutorial();
  }

  Future<void> _maybeShowTutorial() async {
    final seen = await _storage.getHasSeenTutorial();
    if (seen || !mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TutorialDialog(controlScheme: _controlScheme),
    );
    await _storage.setHasSeenTutorial(true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _duckTimer?.cancel();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (_status != GameStatus.playing) return;
    if (dt <= 0 || dt > 0.05) return; // ignora saltos grandes (ex: app voltou do fundo)
    _update(dt);
  }

  void _update(double dt) {
    _playSeconds += dt;
    _distance += _speed * dt;
    _score = (_distance / 10).floor();
    _speed = baseSpeed + min(maxExtraSpeed, _distance / 150);

    final wasAirborne = _playerY < -0.5;
    _playerVelocity += gravity * dt;
    _playerY += _playerVelocity * dt;
    if (_playerY > 0) {
      _playerY = 0;
      _playerVelocity = 0;
      if (wasAirborne) _landingEffectTimer = landingEffectDuration;
    }
    _jumpEffectTimer = max(0, _jumpEffectTimer - dt);
    _landingEffectTimer = max(0, _landingEffectTimer - dt);

    _spawnTimer += dt;
    if (_spawnTimer >= _nextSpawnIn && _boardSize.width > 0) {
      _spawnTimer = 0;
      _nextSpawnIn = 0.9 + _random.nextDouble() * 1.0;
      _spawnEntity();
    }

    for (final o in _obstacles) {
      o.x -= _speed * dt;
    }
    _obstacles.removeWhere((o) => o.x < -100);

    for (final b in _birds) {
      b.x -= _speed * dt;
      b.wingPhase += dt * 10;
    }
    _birds.removeWhere((b) => b.x < -100);

    for (final c in _collectibles) {
      c.x -= _speed * dt;
      c.wobble += dt * 4;
    }
    _collectibles.removeWhere((c) => c.x < -100 || c.collected);

    final collided = _checkCollisions();
    setState(() {});

    if (collided) {
      _status = GameStatus.gameOver;
      AudioService.instance.playGameOver();
      _persistRunResult();
    }
  }

  void _spawnEntity() {
    final style = _currentStyle;
    final groundTop = _boardSize.height - groundHeight;
    final roll = _random.nextDouble();

    if (roll < 0.35) {
      final onGround = _random.nextBool();
      final y = onGround ? groundTop - 34 : groundTop - 120 - _random.nextDouble() * 60;
      _collectibles.add(Collectible(
        x: _boardSize.width + 30,
        y: y,
        radius: 14,
        value: 1,
      ));
      return;
    }

    if (roll < 0.6) {
      // Voa reto numa altura fixa, vindo em cima do personagem no eixo X.
      _birds.add(Bird(
        x: _boardSize.width + 30,
        y: groundTop - 46,
        width: 46,
        height: 22,
      ));
      return;
    }

    final height = 40.0 + _random.nextDouble() * 40;
    final width = 26.0 + _random.nextDouble() * 18;
    _obstacles.add(Obstacle(
      x: _boardSize.width + 30,
      width: width,
      height: height,
      color: style.groundObstacleColors[_random.nextInt(style.groundObstacleColors.length)],
      variant: _random.nextInt(3),
    ));
  }

  double get _effectivePlayerHeight {
    final isJumping = _playerY < -1;
    final duckFactor = (_isDucking && !isJumping) ? duckHeightFactor : 1.0;
    return playerSize * duckFactor;
  }

  Rect _playerRect() {
    final groundTop = _boardSize.height - groundHeight;
    final height = _effectivePlayerHeight;
    final top = groundTop - height + _playerY;
    return Rect.fromLTWH(playerX, top, playerSize, height);
  }

  bool _checkCollisions() {
    final hitRect = _playerRect().deflate(8);
    final groundTop = _boardSize.height - groundHeight;

    for (final o in _obstacles) {
      final rect = Rect.fromLTWH(o.x, groundTop - o.height, o.width, o.height);
      if (hitRect.overlaps(rect)) return true;
    }

    for (final b in _birds) {
      final rect = Rect.fromCenter(center: Offset(b.x, b.y), width: b.width * 0.6, height: b.height * 0.6);
      if (hitRect.overlaps(rect)) return true;
    }

    for (final c in _collectibles) {
      if (c.collected) continue;
      final rect = Rect.fromCircle(center: Offset(c.x, c.y), radius: c.radius);
      if (hitRect.overlaps(rect)) {
        c.collected = true;
        _runCoins += c.value;
        AudioService.instance.playCoin();
      }
    }
    return false;
  }

  Future<void> _persistRunResult() async {
    final isNewBest = await _storage.setBestScoreIfHigher(_score);
    await _storage.addCoins(_runCoins);
    if (!mounted) return;
    setState(() {
      _isNewBest = isNewBest;
      if (isNewBest) _bestScore = _score;
    });
  }

  void _startGame() {
    setState(() {
      _status = GameStatus.playing;
      _playerY = 0;
      _playerVelocity = 0;
      _isDucking = false;
      _jumpEffectTimer = 0;
      _landingEffectTimer = 0;
      _speed = baseSpeed;
      _distance = 0;
      _playSeconds = 0;
      _score = 0;
      _runCoins = 0;
      _isNewBest = false;
      _obstacles.clear();
      _birds.clear();
      _collectibles.clear();
      _spawnTimer = 0;
    });
    _duckTimer?.cancel();
    _lastElapsed = Duration.zero;
    _ticker.stop();
    _ticker.start();
  }

  void _jump() {
    if (_status == GameStatus.ready || _status == GameStatus.gameOver) {
      _startGame();
      return;
    }
    if (_playerY == 0 && !_isDucking) {
      setState(() {
        _playerVelocity = jumpVelocity;
        _jumpEffectTimer = jumpEffectDuration;
      });
      AudioService.instance.playJump();
    }
  }

  void _duckFor(Duration duration) {
    if (_status != GameStatus.playing || _playerY != 0) return;
    _duckTimer?.cancel();
    setState(() => _isDucking = true);
    _duckTimer = Timer(duration, () {
      if (!mounted) return;
      setState(() => _isDucking = false);
    });
  }

  void _setDucking(bool value) {
    if (_status != GameStatus.playing) return;
    if (value && _playerY != 0) return;
    _duckTimer?.cancel();
    setState(() => _isDucking = value);
  }

  void _onTap() => _jump();

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_status != GameStatus.playing) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -250) {
      _jump();
    } else if (velocity > 250) {
      _duckFor(swipeDuckDuration);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showButtons = _status == GameStatus.playing && _controlScheme == 'buttons';
    return Scaffold(
      backgroundColor: const Color(0xFF181C30),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _boardSize = constraints.biggest;
            return GestureDetector(
              onTap: _onTap,
              onVerticalDragEnd: _controlScheme == 'swipe' ? _onVerticalDragEnd : null,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: DinoPainter(
                      playerY: _playerY,
                      isDucking: _isDucking,
                      distance: _distance,
                      obstacles: _obstacles,
                      birds: _birds,
                      collectibles: _collectibles,
                      groundHeight: groundHeight,
                      playerSize: playerSize,
                      playerX: playerX,
                      bodyColor: _skin.bodyColor,
                      legColor: _skin.legColor,
                      characterShape: _characterShape,
                      style: _currentStyle,
                      elapsedSeconds: _playSeconds,
                      jumpEffect: _jumpEffectTimer / jumpEffectDuration,
                      landingEffect: _landingEffectTimer / landingEffectDuration,
                      hasCapAndChain: _skin.hasCapAndChain,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _HudChip(label: 'Pontos', value: '$_score'),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _HudChip(label: 'Moedas', value: '$_runCoins'),
                  ),
                  if (_status == GameStatus.ready) _ReadyOverlay(bestScore: _bestScore),
                  if (_status == GameStatus.gameOver)
                    _GameOverOverlay(
                      score: _score,
                      bestScore: _bestScore,
                      coinsEarned: _runCoins,
                      isNewBest: _isNewBest,
                    ),
                  if (showButtons) ...[
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: _ControlButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onPressDown: () => _setDucking(true),
                        onPressUp: () => _setDucking(false),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      bottom: 24,
                      child: _ControlButton(
                        icon: Icons.keyboard_arrow_up_rounded,
                        onTap: _jump,
                      ),
                    ),
                  ],
                  // Fica por último na pilha (acima dos overlays de ready/game over)
                  // pra continuar clicável mesmo quando eles estão visíveis — se ficasse
                  // antes, o Container cheio de tela dos overlays engolia o toque e
                  // sempre reiniciava o jogo em vez de fechar.
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    this.onTap,
    this.onPressDown,
    this.onPressUp,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onPressDown;
  final VoidCallback? onPressUp;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: onPressDown != null ? (_) => onPressDown!() : null,
      onTapUp: onPressUp != null ? (_) => onPressUp!() : null,
      onTapCancel: onPressUp,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}

class _ReadyOverlay extends StatelessWidget {
  const _ReadyOverlay({required this.bestScore});

  final int bestScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Toque pra começar',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Recorde: $bestScore',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.bestScore,
    required this.coinsEarned,
    required this.isNewBest,
  });

  final int score;
  final int bestScore;
  final int coinsEarned;
  final bool isNewBest;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Fim de jogo!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Pontuação: $score', style: const TextStyle(color: Colors.white, fontSize: 18)),
          if (isNewBest)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('🏆 Novo recorde!', style: TextStyle(color: Color(0xFFE5A63E), fontSize: 16, fontWeight: FontWeight.bold)),
            )
          else
            Text('Recorde: $bestScore', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text('+$coinsEarned moedas coletadas', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 20),
          const Text('Toque pra jogar de novo', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

class _TutorialDialog extends StatelessWidget {
  const _TutorialDialog({required this.controlScheme});

  final String controlScheme;

  @override
  Widget build(BuildContext context) {
    final isSwipe = controlScheme == 'swipe';
    return AlertDialog(
      backgroundColor: const Color(0xFF181C30),
      title: const Text('Como jogar', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwipe
                ? '⬆️ Toque ou deslize pra cima pra pular obstáculos no chão.\n\n⬇️ Deslize pra baixo pra abaixar e desviar de quem vem voando.'
                : '⬆️ Toque no botão da direita pra pular obstáculos no chão.\n\n⬇️ Segure o botão da esquerda pra abaixar e desviar de quem vem voando.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dá pra trocar a forma de controle a qualquer momento em Config, na tela inicial.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi!'),
        ),
      ],
    );
  }
}
