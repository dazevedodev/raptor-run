import 'dart:ui';

enum GameStatus { ready, playing, gameOver }

class Obstacle {
  Obstacle({
    required this.x,
    required this.width,
    required this.height,
    required this.color,
    this.variant = 0,
  });

  double x;
  final double width;
  final double height;
  final Color color;
  /// Sorteado uma vez no spawn (não recalculado do `x`, que muda a cada
  /// frame) — decide qual silhueta usar quando o obstáculo tem mais de um
  /// visual possível (hoje só a rocha, ver `_drawRock`).
  final int variant;
}

class Collectible {
  Collectible({
    required this.x,
    required this.y,
    required this.radius,
    required this.value,
  });

  double x;
  final double y;
  final double radius;
  final int value;
  double wobble = 0;
  bool collected = false;
}

/// Obstáculo voador (pássaro/pterodáctilo) — voa reto numa altura fixa (só
/// se move no eixo X, junto com o resto do cenário), igual ao jogo
/// original: precisa abaixar (ou, se bem cronometrado, pular) pra passar
/// por baixo, diferente do Obstacle (no chão), que precisa pular.
class Bird {
  Bird({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double x;
  final double y;
  final double width;
  final double height;
  double wingPhase = 0;
}
