import 'dart:math';

import 'package:flutter/material.dart';

import 'character_renderer.dart';
import 'characters.dart';
import 'entities.dart';
import 'world_style.dart';

/// Desenha tudo (céu, chão, obstáculos, pássaros, colecionáveis e o
/// personagem) num canvas, sem depender de nenhum asset de imagem.
class DinoPainter extends CustomPainter {
  DinoPainter({
    required this.playerY,
    required this.isDucking,
    required this.distance,
    required this.obstacles,
    required this.birds,
    required this.collectibles,
    required this.groundHeight,
    required this.playerSize,
    required this.playerX,
    required this.bodyColor,
    required this.legColor,
    required this.characterShape,
    required this.style,
    required this.elapsedSeconds,
    this.jumpEffect = 0,
    this.landingEffect = 0,
    this.hasCapAndChain = false,
  });

  final double playerY;
  final bool isDucking;
  final double distance;
  final List<Obstacle> obstacles;
  final List<Bird> birds;
  final List<Collectible> collectibles;
  final double groundHeight;
  final double playerSize;
  final double playerX;
  final Color bodyColor;
  final Color legColor;
  final CharacterShape characterShape;
  final WorldStyle style;
  // Segundos reais de corrida (não distância) — usado só nas animações que
  // não podem acelerar junto com a velocidade do jogo (meteoros, lava),
  // senão viram uma enxurrada conforme o jogo acelera. Ver comentário em
  // `_drawMeteors`.
  final double elapsedSeconds;
  // 1 = acabou de acontecer, 0 = já sumiu — controla a poeirinha nos pés do
  // personagem ao pular/aterrissar (ver `_drawDustBurst`).
  final double jumpEffect;
  final double landingEffect;
  final bool hasCapAndChain;

  @override
  void paint(Canvas canvas, Size size) {
    final groundTop = size.height - groundHeight;

    _drawSky(canvas, size, groundTop);
    if (style.showDestruction) _drawPlanets(canvas, size);
    if (style.isNight) _drawMoon(canvas, size);
    if (style.showClouds) _drawSun(canvas, size);
    if (style.showClouds) _drawClouds(canvas, size, groundTop);
    if (style.showSkyline) _drawSkyline(canvas, size, groundTop);
    if (style.showClouds) _drawAirplane(canvas, size);
    if (style.showClouds) _drawBlimp(canvas, size);
    if (style.showClouds) _drawAirplaneCollision(canvas, size);
    if (style.isNight) _drawSpaceship(canvas, size);
    if (style.showVolcanoes) _drawVolcanoes(canvas, size, groundTop);
    if (style.showDestruction) _drawMeteors(canvas, size, groundTop);
    _drawGround(canvas, size, groundTop);
    _drawGroundClutter(canvas, size, groundTop);
    if (style.showDestruction) _drawEmbers(canvas, size, groundTop);

    for (final o in obstacles) {
      _drawObstacle(canvas, o, groundTop);
    }

    for (final b in birds) {
      _drawBird(canvas, b);
    }

    for (final c in collectibles) {
      if (c.collected) continue;
      _drawCollectible(canvas, c);
    }

    _drawPlayer(canvas, groundTop);
  }

  void _drawSky(Canvas canvas, Size size, double groundTop) {
    final skyRect = Rect.fromLTWH(0, 0, size.width, groundTop);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [style.skyTop, style.skyBottom],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, paint);
  }

  void _drawClouds(Canvas canvas, Size size, double groundTop) {
    final wrapWidth = size.width + 260;
    final spacing = wrapWidth / 3;
    for (int i = 0; i < 3; i++) {
      final x = (i * spacing - distance * 0.18) % wrapWidth - 130;
      final y = 30.0 + (i * 37) % 60;
      final scale = 0.8 + (i % 3) * 0.22;
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.8 - (i % 2) * 0.15);
      // Aglomerado de círculos de tamanhos variados pra parecer mais uma
      // nuvem de verdade e menos "3 bolinhas coladas".
      canvas.drawCircle(Offset(x, y), 16 * scale, paint);
      canvas.drawCircle(Offset(x + 20 * scale, y - 6 * scale), 13 * scale, paint);
      canvas.drawCircle(Offset(x + 38 * scale, y + 2 * scale), 17 * scale, paint);
      canvas.drawCircle(Offset(x + 16 * scale, y + 8 * scale), 14 * scale, paint);
      canvas.drawCircle(Offset(x - 16 * scale, y + 6 * scale), 11 * scale, paint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 12 * scale, y + 7 * scale), width: 52 * scale, height: 18 * scale),
        paint,
      );
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    const center = Offset(670, 70);
    canvas.drawCircle(center, 34, Paint()..color = const Color(0xFFFFE29A).withValues(alpha: 0.25));
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD873).withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final inner = center + Offset(cos(angle), sin(angle)) * 22;
      final outer = center + Offset(cos(angle), sin(angle)) * 30;
      canvas.drawLine(inner, outer, rayPaint);
    }
    canvas.drawCircle(center, 20, Paint()..color = const Color(0xFFFFD873));
  }

  void _drawMoon(Canvas canvas, Size size) {
    const center = Offset(90, 66);
    canvas.drawCircle(center, 28, Paint()..color = Colors.white.withValues(alpha: 0.12));
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFFF4F1E3));
    canvas.drawCircle(center.translate(6, 3), 2.6, Paint()..color = const Color(0xFFDAD5C0));
    canvas.drawCircle(center.translate(-4, 6), 2, Paint()..color = const Color(0xFFDAD5C0));
    canvas.drawCircle(center.translate(-6, -5), 1.6, Paint()..color = const Color(0xFFDAD5C0));
  }

  /// Planetas distantes no céu da era da extinção — um pano de fundo calmo
  /// (deriva bem devagar, em `elapsedSeconds`, não acelera com o jogo) pra
  /// dar sensação de escala cósmica sem competir com os meteoros/lava.
  void _drawPlanets(Canvas canvas, Size size) {
    final planets = [
      (color: const Color(0xFFC0693B), radius: 20.0, yFrac: 0.14, speed: 1.1, ring: false),
      (color: const Color(0xFFE3C16F), radius: 28.0, yFrac: 0.24, speed: 0.55, ring: true),
      (color: const Color(0xFF6C87D6), radius: 14.0, yFrac: 0.34, speed: 1.6, ring: false),
    ];
    final wrapWidth = size.width + 400;
    for (var i = 0; i < planets.length; i++) {
      final planet = planets[i];
      final x = (size.width * (0.18 + i * 0.34) - elapsedSeconds * planet.speed) % wrapWidth - 100;
      final y = size.height * planet.yFrac;
      final center = Offset(x, y);

      if (planet.ring) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-0.35);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: planet.radius * 2.7, height: planet.radius * 0.9),
          Paint()
            ..color = planet.color.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
        canvas.restore();
      }

      canvas.drawCircle(center, planet.radius, Paint()..color = planet.color.withValues(alpha: 0.8));
      canvas.drawCircle(
        center.translate(-planet.radius * 0.3, -planet.radius * 0.3),
        planet.radius * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
    }
  }

  void _drawSkyline(Canvas canvas, Size size, double groundTop) {
    final wrapWidth = size.width + 400;
    const heights = [70.0, 110.0, 60.0, 130.0, 85.0, 100.0, 65.0, 118.0];
    const widths = [46.0, 58.0, 40.0, 50.0, 44.0, 62.0, 38.0, 54.0];
    const roofTypes = [0, 1, 2, 0, 2, 1, 0, 1];
    final baseColor = style.isNight ? const Color(0xFF1B2547) : const Color(0xFF8FA0E8);
    final litWinPaint = Paint()..color = const Color(0xFFFFD37A).withValues(alpha: 0.9);
    final dimWinPaint = Paint()..color = Colors.white.withValues(alpha: style.isNight ? 0.1 : 0.25);
    final detailPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.7)
      ..strokeWidth = 2;

    double x = -((distance * 0.12) % wrapWidth);
    int i = 0;
    while (x < size.width) {
      final bw = widths[i % widths.length];
      final bh = heights[i % heights.length];
      final shade = 0.32 + (i % 4) * 0.09;
      final buildingPaint = Paint()..color = baseColor.withValues(alpha: shade);
      final rect = Rect.fromLTWH(x, groundTop - bh, bw, bh);
      canvas.drawRect(rect, buildingPaint);

      switch (roofTypes[i % roofTypes.length]) {
        case 1:
          final topCenter = Offset(rect.center.dx, rect.top);
          canvas.drawLine(topCenter, topCenter.translate(0, -14), detailPaint);
          canvas.drawCircle(topCenter.translate(0, -14), 2.4, Paint()..color = style.isNight ? Colors.redAccent : buildingPaint.color);
        case 2:
          canvas.drawRect(Rect.fromLTWH(rect.center.dx - 7, rect.top - 10, 14, 10), buildingPaint);
      }

      int wi = 0;
      for (double wy = rect.top + 8; wy < rect.bottom - 6; wy += 14) {
        for (double wx = rect.left + 6; wx < rect.right - 6; wx += 12) {
          final lit = style.isNight && ((wi + i * 3) % 5 == 0 || (wi + i * 7) % 6 == 0);
          canvas.drawRect(Rect.fromLTWH(wx, wy, 5, 7), lit ? litWinPaint : dimWinPaint);
          wi++;
        }
      }

      x += bw + 14;
      i++;
    }
  }

  void _drawAirplane(Canvas canvas, Size size) {
    final wrapWidth = size.width * 1.6;
    final x = (size.width * 0.5 - distance * 0.3) % wrapWidth - size.width * 0.3;
    if (x < -60 || x > size.width + 60) return;
    _drawPlaneShape(canvas, x, 64, mirrored: false);
  }

  /// Dirigível com uma faixa de propaganda (fundo preto, texto branco) na
  /// lateral — anda bem devagar (dirigível de verdade é lento), numa altura
  /// diferente do avião/nave pra nunca sobrepor.
  void _drawBlimp(Canvas canvas, Size size) {
    final wrapWidth = size.width * 1.9;
    final x = (size.width * 0.5 - distance * 0.06) % wrapWidth - size.width * 0.45;
    if (x < -140 || x > size.width + 140) return;
    const y = 180.0;

    final envelope = Rect.fromCenter(center: Offset(x, y), width: 130, height: 46);
    canvas.drawOval(envelope, Paint()..color = const Color(0xFFE9E4D8));
    canvas.drawOval(
      envelope,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Faixa de propaganda: fundo preto, "ZANTTE" em branco, recortada pra
    // não passar do contorno oval do balão.
    canvas.save();
    canvas.clipPath(Path()..addOval(envelope));
    canvas.drawRect(Rect.fromCenter(center: Offset(x, y), width: 108, height: 20), Paint()..color = Colors.black);
    canvas.restore();

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'ZANTTE',
        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));

    final finPaint = Paint()..color = const Color(0xFFCFC8B8);
    canvas.drawPath(
      Path()
        ..moveTo(x - 58, y - 3)
        ..lineTo(x - 78, y - 20)
        ..lineTo(x - 66, y - 2)
        ..close(),
      finPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x - 58, y + 3)
        ..lineTo(x - 78, y + 18)
        ..lineTo(x - 66, y + 2)
        ..close(),
      finPaint,
    );

    final gondola = Rect.fromCenter(center: Offset(x + 4, y + 30), width: 26, height: 10);
    canvas.drawRRect(RRect.fromRectAndRadius(gondola, const Radius.circular(2)), Paint()..color = const Color(0xFF4A4136));
    final ropePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x - 8, y + 18), Offset(x - 4, y + 25), ropePaint);
    canvas.drawLine(Offset(x + 16, y + 18), Offset(x + 12, y + 25), ropePaint);
  }

  /// Forma compartilhada do aviãozinho — usada tanto no avião ambiente que
  /// sempre cruzou o céu quanto nos dois da colisão (`_drawAirplaneCollision`,
  /// um espelhado vindo do lado oposto).
  void _drawPlaneShape(Canvas canvas, double x, double y, {required bool mirrored}) {
    final dir = mirrored ? -1.0 : 1.0;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.8);

    final trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x - 70 * dir, y + 2), Offset(x - 14 * dir, y + 2), trailPaint);

    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 40, height: 8), paint);
    final wing = Path()
      ..moveTo(x - 4 * dir, y)
      ..lineTo(x - 14 * dir, y + 12)
      ..lineTo(x, y + 2)
      ..close();
    canvas.drawPath(wing, paint);
    final tail = Path()
      ..moveTo(x - 16 * dir, y - 2)
      ..lineTo(x - 22 * dir, y - 10)
      ..lineTo(x - 12 * dir, y - 2)
      ..close();
    canvas.drawPath(tail, paint);
  }

  /// De vez em quando (ciclo em `elapsedSeconds`, não acelera com o jogo),
  /// dois aviões se aproximam de direções opostas, se cruzam bem no meio do
  /// céu e explodem — um efeito extra além do avião ambiente de sempre.
  void _drawAirplaneCollision(Canvas canvas, Size size) {
    const cycleSeconds = 20.0;
    const approachSeconds = 6.0;
    const explosionSeconds = 1.4;
    final t = elapsedSeconds % cycleSeconds;
    final centerX = size.width * 0.55;
    const y = 104.0;

    if (t < approachSeconds) {
      final progress = t / approachSeconds;
      const startA = -60.0;
      final startB = size.width + 60;
      final xA = startA + (centerX - startA) * progress;
      final xB = startB + (centerX - startB) * progress;
      _drawPlaneShape(canvas, xA, y, mirrored: false);
      _drawPlaneShape(canvas, xB, y, mirrored: true);
      return;
    }

    final localT = t - approachSeconds;
    if (localT > explosionSeconds) return;

    final burst = (localT / explosionSeconds).clamp(0.0, 1.0);
    final fade = 1 - burst;
    final radius = 8 + burst * 40;

    canvas.drawCircle(Offset(centerX, y), radius, Paint()..color = const Color(0xFFFFC26B).withValues(alpha: 0.5 * fade));
    canvas.drawCircle(Offset(centerX, y), radius * 0.55, Paint()..color = const Color(0xFFFF7A3D).withValues(alpha: 0.75 * fade));
    canvas.drawCircle(Offset(centerX, y), radius * 0.25, Paint()..color = Colors.white.withValues(alpha: 0.9 * fade));

    final debrisPaint = Paint()..color = const Color(0xFF3A3F55).withValues(alpha: 0.5 * fade);
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + 0.3;
      final dist = 10 + burst * 44;
      final pos = Offset(centerX + cos(angle) * dist, y + sin(angle) * dist * 0.7);
      canvas.drawCircle(pos, 3 * fade + 1, debrisPaint);
    }
  }

  void _drawSpaceship(Canvas canvas, Size size) {
    final wrapWidth = size.width * 2.0;
    final x = (size.width * 0.5 - distance * 0.22) % wrapWidth - size.width * 0.5;
    if (x < -70 || x > size.width + 70) return;
    const y = 110.0;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 100, height: 34),
      Paint()..color = const Color(0xFF8FFFC0).withValues(alpha: 0.14),
    );

    final domePaint = Paint()..color = const Color(0xFF8FFFC0).withValues(alpha: 0.85);
    canvas.drawArc(Rect.fromCenter(center: Offset(x, y - 5), width: 32, height: 26), pi, pi, true, domePaint);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 66, height: 16),
      Paint()..color = const Color(0xFF3A3F55),
    );

    final blink = sin(distance * 0.25) > 0;
    final lightPaint = Paint()..color = blink ? Colors.amberAccent : Colors.redAccent;
    canvas.drawCircle(Offset(x - 18, y + 6), 2.6, lightPaint);
    canvas.drawCircle(Offset(x, y + 8), 2.6, lightPaint);
    canvas.drawCircle(Offset(x + 18, y + 6), 2.6, lightPaint);
  }

  void _drawGroundClutter(Canvas canvas, Size size, double groundTop) {
    final tuftColor = Color.lerp(style.groundColor, Colors.black, 0.22)!;
    final paint = Paint()
      ..color = tuftColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final offset = distance % 90;
    for (double x = -offset; x < size.width; x += 90) {
      final seed = ((x + distance) / 90).floor();
      final wobble = (seed % 3) * 6.0;
      final baseY = groundTop + 30 + wobble * 0.3;
      canvas.drawLine(Offset(x, baseY), Offset(x - 5, baseY - 10), paint);
      canvas.drawLine(Offset(x, baseY), Offset(x, baseY - 12), paint);
      canvas.drawLine(Offset(x, baseY), Offset(x + 5, baseY - 10), paint);
    }
  }

  void _drawVolcanoes(Canvas canvas, Size size, double groundTop) {
    final paint = Paint()..color = const Color(0xFF3A2420);
    final wrapWidth = size.width + 300;
    const positions = [0.1, 0.45, 0.78];
    for (var i = 0; i < positions.length; i++) {
      final x = (positions[i] * wrapWidth - distance * 0.15) % wrapWidth - 150;
      final peak = Offset(x, groundTop - 140);
      final baseLeft = Offset(x - 90, groundTop);
      final baseRight = Offset(x + 90, groundTop);
      final path = Path()
        ..moveTo(baseLeft.dx, baseLeft.dy)
        ..lineTo(peak.dx, peak.dy)
        ..lineTo(baseRight.dx, baseRight.dy)
        ..close();
      canvas.drawPath(path, paint);

      _drawLavaFlow(canvas, peak, baseLeft, i);
      _drawLavaFlow(canvas, peak, baseRight, i + 11);

      final pulse = 0.75 + sin(elapsedSeconds * 1.6 + i) * 0.2;
      canvas.drawCircle(peak.translate(0, 6), 13, Paint()..color = const Color(0xFFFF8A3D).withValues(alpha: 0.9 * pulse));
      canvas.drawCircle(peak.translate(0, 4), 7, Paint()..color = const Color(0xFFFFE29A).withValues(alpha: 0.85 * pulse));
      canvas.drawCircle(peak.translate(-6, -14), 9, Paint()..color = Colors.white.withValues(alpha: 0.12));

      _drawLavaBursts(canvas, peak, i);
    }
  }

  /// Um fio de lava escorrendo por uma das encostas do vulcão, com brilho na
  /// ponta. O ciclo usa `elapsedSeconds` (segundos reais), não `distance` —
  /// senão a lava "escorreria" cada vez mais rápido conforme o jogo
  /// acelera, junto com o mesmo problema que os meteoros tinham.
  void _drawLavaFlow(Canvas canvas, Offset peak, Offset base, int seed) {
    const cycleSeconds = 5.0;
    final t = ((elapsedSeconds + seed * 1.7) % cycleSeconds) / cycleSeconds;
    final end = Offset.lerp(peak, base, 0.25 + t * 0.7)!;
    final glow = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = Color.lerp(const Color(0xFFFFD166), const Color(0xFFB33A1E), t)!.withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(peak, end, paint);
    canvas.drawCircle(end, 3.5 + glow * 1.5, Paint()..color = const Color(0xFFFFE29A).withValues(alpha: 0.5 + glow * 0.4));
  }

  /// Pedaços de lava voando pra fora da cratera em arco, como se o vulcão
  /// estivesse em erupção — ritmo em `elapsedSeconds`, constante mesmo com o
  /// jogo acelerando.
  void _drawLavaBursts(Canvas canvas, Offset peak, int seed) {
    const burstsPerVolcano = 2;
    const cycleSeconds = 4.0;
    for (var i = 0; i < burstsPerVolcano; i++) {
      final localSeed = seed * 1.3 + i * 2.1;
      final progress = ((elapsedSeconds + localSeed) % cycleSeconds) / cycleSeconds;
      final dir = i.isEven ? 1.0 : -1.0;
      final spread = 0.6 + i * 0.35;
      final dx = dir * spread * 90 * progress;
      final dy = -90 * sin(progress * pi);
      final pos = peak.translate(dx, dy - 6);
      final alpha = sin(progress * pi).clamp(0.0, 1.0);
      canvas.drawCircle(pos, 3.6, Paint()..color = const Color(0xFFFF8A3D).withValues(alpha: alpha * 0.9));
      canvas.drawCircle(pos, 1.7, Paint()..color = const Color(0xFFFFEFC2).withValues(alpha: alpha));
    }
  }

  /// Meteoros caindo na diagonal (com rastro suave), poucos e num ritmo
  /// calmo — o ciclo usa `elapsedSeconds` (segundos reais de jogo), não
  /// `distance`: antes usava distância, e como a velocidade do jogo cresce
  /// com a distância, os meteoros iam ficando cada vez mais numerosos e
  /// rápidos junto — virava uma enxurrada. Com segundos reais, cada meteoro
  /// sempre leva o mesmo tempo pra cair, não importa a velocidade.
  void _drawMeteors(Canvas canvas, Size size, double groundTop) {
    const meteorCount = 2;
    const cycleSeconds = 7.0;
    final groundY = groundTop - 4;
    for (var i = 0; i < meteorCount; i++) {
      final seed = i * (cycleSeconds / meteorCount);
      final progress = ((elapsedSeconds + seed) % cycleSeconds) / cycleSeconds;
      final startX = size.width * (0.2 + i * 0.5) + 60;
      final x = startX - progress * 130;
      final y = -20 + progress * (groundY + 20);

      if (progress > 0.96) {
        final flash = 1 - (progress - 0.96) / 0.04;
        canvas.drawCircle(Offset(x, groundY), 20 * flash, Paint()..color = const Color(0xFFFFC26B).withValues(alpha: 0.55 * flash));
        canvas.drawCircle(Offset(x, groundY), 8 * flash, Paint()..color = Colors.white.withValues(alpha: 0.5 * flash));
        continue;
      }

      final tailEnd = Offset(x + 26, y - 66);
      final tailPaint = Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFFFE0A3).withValues(alpha: 0.85), const Color(0xFFFF6A3D).withValues(alpha: 0.0)],
        ).createShader(Rect.fromPoints(Offset(x, y), tailEnd))
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y), tailEnd, tailPaint);
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = const Color(0xFFFF8A3D).withValues(alpha: 0.3));
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = const Color(0xFFFFEFC2));
    }
  }

  /// Brasas subindo do chão — clima de fogo/destruição ambiente, sem
  /// atrapalhar a leitura dos obstáculos. Sobe num ritmo de `elapsedSeconds`
  /// (a deriva horizontal ainda usa `distance`, então acompanha o mundo
  /// rolando, mas a subida em si não acelera).
  void _drawEmbers(Canvas canvas, Size size, double groundTop) {
    const emberCount = 16;
    const cycleSeconds = 4.0;
    for (var i = 0; i < emberCount; i++) {
      final seed = i * 0.9;
      final progress = ((elapsedSeconds + seed) % cycleSeconds) / cycleSeconds;
      final baseX = (i * 53.0 + distance * 0.05) % size.width;
      final wobble = sin(progress * pi * 4 + i) * 6;
      final x = baseX + wobble;
      final y = groundTop - progress * 90;
      final alpha = (1 - progress).clamp(0.0, 1.0);
      final emberColor = Color.lerp(const Color(0xFFFF8A3D), const Color(0xFFFFD166), progress)!;
      canvas.drawCircle(Offset(x, y), 2.4 * (1 - progress * 0.5), Paint()..color = emberColor.withValues(alpha: alpha * 0.85));
    }
  }

  void _drawGround(Canvas canvas, Size size, double groundTop) {
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, groundHeight),
      Paint()..color = style.groundColor,
    );
    // Sombreado sutil pra dar profundidade sem parecer marcação de pista.
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, 3),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop + 3, size.width, 14),
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );
  }

  void _drawObstacle(Canvas canvas, Obstacle o, double groundTop) {
    switch (style.groundObstacleKind) {
      case GroundObstacleKind.cactus:
        _drawCactus(canvas, o, groundTop);
      case GroundObstacleKind.rock:
        _drawRock(canvas, o, groundTop);
    }
  }

  void _drawCactus(Canvas canvas, Obstacle o, double groundTop) {
    final baseX = o.x + o.width / 2;
    final sway = sin(distance / 90 + o.x * 0.05) * 0.06;

    canvas.save();
    canvas.translate(baseX, groundTop);
    canvas.rotate(sway);
    canvas.translate(-baseX, -groundTop);

    final paint = Paint()..color = o.color;
    final trunkWidth = o.width * 0.5;
    final trunkRect = Rect.fromLTWH(baseX - trunkWidth / 2, groundTop - o.height, trunkWidth, o.height);
    canvas.drawRRect(RRect.fromRectAndRadius(trunkRect, Radius.circular(trunkWidth / 2)), paint);

    final armWidth = o.width * 0.32;
    final armHeight = o.height * 0.38;
    final armY = groundTop - o.height * 0.55;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(trunkRect.left - armWidth * 0.7, armY, armWidth, armHeight),
        Radius.circular(armWidth / 2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(trunkRect.right - armWidth * 0.3, armY - armHeight * 0.3, armWidth, armHeight),
        Radius.circular(armWidth / 2),
      ),
      paint,
    );

    final spikePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (double y = trunkRect.top + 6; y < trunkRect.bottom - 6; y += 10) {
      canvas.drawLine(Offset(trunkRect.left + 2, y), Offset(trunkRect.left - 2, y + 4), spikePaint);
      canvas.drawLine(Offset(trunkRect.right - 2, y + 5), Offset(trunkRect.right + 2, y + 9), spikePaint);
    }

    canvas.restore();
  }

  /// Três silhuetas diferentes de rocha (não é mais sempre a mesma forma
  /// esticada) — cada obstáculo sorteia uma no spawn (`Obstacle.variant`,
  /// `game_screen.dart`) e mantém ela até sumir da tela.
  static const List<List<List<double>>> _rockVariants = [
    [[0.0, 1.0], [0.08, 0.4], [0.42, 0.0], [0.78, 0.22], [1.0, 1.0]],
    [[0.0, 1.0], [0.04, 0.5], [0.3, 0.12], [0.52, 0.34], [0.76, 0.02], [1.0, 0.48], [1.0, 1.0]],
    [[0.02, 1.0], [0.0, 0.55], [0.24, 0.08], [0.4, 0.3], [0.62, 0.0], [0.86, 0.36], [1.0, 0.6], [1.0, 1.0]],
  ];

  void _drawRock(Canvas canvas, Obstacle o, double groundTop) {
    final rect = Rect.fromLTWH(o.x, groundTop - o.height, o.width, o.height);
    final points = _rockVariants[o.variant % _rockVariants.length];
    Offset pt(List<double> f) => Offset(rect.left + f[0] * rect.width, rect.top + f[1] * rect.height);

    final path = Path()..moveTo(pt(points.first).dx, pt(points.first).dy);
    for (final f in points.skip(1)) {
      path.lineTo(pt(f).dx, pt(f).dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = o.color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Faceta clara perto do ponto mais alto, tipo luz batendo de cima — dá
    // volume, em vez de uma silhueta lisa e chapada.
    var apex = points.first;
    for (final f in points) {
      if (f[1] < apex[1]) apex = f;
    }
    final apexPt = pt(apex);
    final shadeBelowY = (apex[1] + 0.5).clamp(0.0, 1.0);
    final highlight = Path()
      ..moveTo(apexPt.dx, apexPt.dy)
      ..lineTo(apexPt.dx + rect.width * 0.14, apexPt.dy + rect.height * 0.18)
      ..lineTo(rect.left + rect.width * (apex[0] + 0.06).clamp(0.0, 1.0), rect.top + rect.height * shadeBelowY)
      ..lineTo(apexPt.dx - rect.width * 0.02, rect.top + rect.height * (shadeBelowY - 0.06).clamp(0.0, 1.0))
      ..close();
    canvas.drawPath(highlight, Paint()..color = Colors.white.withValues(alpha: 0.12));

    final crackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 1.5;
    final crackShift = (o.variant % 3) * 0.08;
    canvas.drawLine(
      Offset(rect.left + rect.width * (0.3 + crackShift), rect.top + rect.height * 0.42),
      Offset(rect.left + rect.width * (0.4 + crackShift), rect.bottom - rect.height * 0.1),
      crackPaint,
    );
  }

  void _drawBird(Canvas canvas, Bird b) {
    switch (style.flyerKind) {
      case FlyerKind.cuteBird:
        _drawCuteBird(canvas, b);
      case FlyerKind.pterodactyl:
        _drawPterodactyl(canvas, b);
    }
  }

  void _drawCuteBird(Canvas canvas, Bird b) {
    final flap = sin(b.wingPhase) * 0.7;
    final center = Offset(b.x, b.y);
    // De noite o azul escuro de sempre quase some no céu escuro — usa um
    // tom claro (como se pegasse luz de lua) só nessa fase, pra continuar
    // visível.
    final wingColor = style.isNight ? const Color(0xFFE7E4FF) : const Color(0xFF3F5CD1);
    final bodyColor = style.isNight ? const Color(0xFFF5F3FF) : const Color(0xFF6C8CFF);

    _drawRoundedWing(canvas, center, b.width, flap, mirrored: false, color: wingColor);
    _drawRoundedWing(canvas, center, b.width, flap, mirrored: true, color: wingColor);

    canvas.drawOval(
      Rect.fromCenter(center: center, width: b.width * 0.55, height: b.height * 0.5),
      Paint()..color = bodyColor,
    );

    final beakPath = Path()
      ..moveTo(center.dx + b.width * 0.24, center.dy)
      ..lineTo(center.dx + b.width * 0.4, center.dy - 3)
      ..lineTo(center.dx + b.width * 0.4, center.dy + 3)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFE5A63E));
  }

  void _drawPterodactyl(Canvas canvas, Bird b) {
    final flap = sin(b.wingPhase) * 0.6;
    final center = Offset(b.x, b.y);
    final wingWidth = b.width * 1.3;

    _drawAngularWing(canvas, center, wingWidth, flap, mirrored: false);
    _drawAngularWing(canvas, center, wingWidth, flap, mirrored: true);

    canvas.drawOval(
      Rect.fromCenter(center: center, width: b.width * 0.5, height: b.height * 0.55),
      Paint()..color = const Color(0xFF9C4A3A),
    );

    final crestPath = Path()
      ..moveTo(center.dx + b.width * 0.18, center.dy - b.height * 0.3)
      ..lineTo(center.dx + b.width * 0.4, center.dy - b.height * 0.6)
      ..lineTo(center.dx + b.width * 0.26, center.dy - b.height * 0.15)
      ..close();
    canvas.drawPath(crestPath, Paint()..color = const Color(0xFF6B2E22));

    final beakPath = Path()
      ..moveTo(center.dx + b.width * 0.22, center.dy)
      ..lineTo(center.dx + b.width * 0.58, center.dy - 2)
      ..lineTo(center.dx + b.width * 0.22, center.dy + 6)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFE5A63E));
  }

  void _drawRoundedWing(Canvas canvas, Offset center, double width, double angle, {required bool mirrored, required Color color}) {
    final dir = mirrored ? -1.0 : 1.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle * dir);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width * 0.32 * dir, -width * 0.28, width * 0.5 * dir, 2)
      ..quadraticBezierTo(width * 0.28 * dir, width * 0.06, 0, 0);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  void _drawAngularWing(Canvas canvas, Offset center, double width, double angle, {required bool mirrored}) {
    final dir = mirrored ? -1.0 : 1.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle * dir);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(width * 0.5 * dir, -width * 0.32)
      ..lineTo(width * 0.62 * dir, -width * 0.05)
      ..lineTo(width * 0.3 * dir, width * 0.08)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF7A362A));
    canvas.restore();
  }

  void _drawCollectible(Canvas canvas, Collectible c) {
    final bob = sin(c.wobble) * 6;
    final center = Offset(c.x, c.y + bob);
    final gradient = RadialGradient(
      colors: [Colors.yellow.shade200, Colors.orange.shade600],
    );
    canvas.drawCircle(
      center,
      c.radius,
      Paint()..shader = gradient.createShader(Rect.fromCircle(center: center, radius: c.radius)),
    );
    canvas.drawCircle(
      center,
      c.radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawPlayer(Canvas canvas, double groundTop) {
    final isJumping = playerY < -1;
    final duckFactor = (isDucking && !isJumping) ? 0.55 : 1.0;
    final squash = (!isJumping && !isDucking) ? sin(distance / 6).abs() * 0.06 : 0.0;
    final effectiveHeight = playerSize * duckFactor * (1 - squash);
    final top = groundTop - effectiveHeight + playerY;
    final bodyRect = Rect.fromLTWH(playerX, top, playerSize, effectiveHeight);

    CharacterRenderer.draw(
      canvas,
      bodyRect,
      shape: characterShape,
      bodyColor: bodyColor,
      legColor: legColor,
      isJumping: isJumping,
      legPhase: (distance / 8) % 2,
      hasCapAndChain: hasCapAndChain,
    );

    final feet = Offset(playerX + playerSize * 0.5, groundTop);
    if (jumpEffect > 0) _drawDustBurst(canvas, feet, jumpEffect, spread: 16);
    if (landingEffect > 0) _drawDustBurst(canvas, feet, landingEffect, spread: 26);
  }

  /// Poeirinha nos pés — usada tanto no impulso do pulo quanto na
  /// aterrissagem (`progress` vai de 1, recém-acontecido, até 0, sumindo).
  void _drawDustBurst(Canvas canvas, Offset feet, double progress, {required double spread}) {
    final grown = 1 - progress;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35 * progress);
    for (var i = 0; i < 4; i++) {
      final angle = pi + (i - 1.5) * 0.5;
      final dist = spread * grown;
      final pos = feet.translate(cos(angle) * dist, sin(angle) * dist * 0.4);
      canvas.drawCircle(pos, 3.5 * progress + 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DinoPainter oldDelegate) => true;
}
