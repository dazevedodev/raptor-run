import 'dart:math';

import 'package:flutter/material.dart';

import 'characters.dart';

/// Desenha a forma de um personagem num [Rect] qualquer — usado tanto no
/// jogo em si (DinoPainter) quanto no preview da loja, pra nunca duplicar o
/// desenho de cada bicho em dois lugares.
class CharacterRenderer {
  const CharacterRenderer._();

  static void draw(
    Canvas canvas,
    Rect bodyRect, {
    required CharacterShape shape,
    required Color bodyColor,
    required Color legColor,
    bool isJumping = false,
    double legPhase = 0,
    bool hasCapAndChain = false,
  }) {
    switch (shape) {
      case CharacterShape.dino:
        _drawDino(canvas, bodyRect, bodyColor, legColor, isJumping, legPhase, hasCapAndChain);
    }
  }

  static void _drawEye(Canvas canvas, Offset center, double size) {
    canvas.drawCircle(center, size, Paint()..color = Colors.white);
    canvas.drawCircle(center.translate(size * 0.32, 0), size * 0.45, Paint()..color = Colors.black);
  }

  /// Dino em pé, de lado, olhando pra direita — atarracado, cantos retos,
  /// boca aberta de verdade (o contorno faz um vão pra dentro, não é só uma
  /// linha em cima), no espírito do dino clássico do Chrome.
  static void _drawDino(
    Canvas canvas,
    Rect r,
    Color bodyColor,
    Color legColor,
    bool isJumping,
    double legPhase,
    bool hasCapAndChain,
  ) {
    final w = r.width;
    final h = r.height;
    Offset p(double fx, double fy) => Offset(r.left + fx * w, r.top + fy * h);
    Rect rect(double fx, double fy, double fw, double fh) => Rect.fromLTWH(r.left + fx * w, r.top + fy * h, fw * w, fh * h);
    final bodyPaint = Paint()..color = bodyColor;

    _drawLegs(canvas, r, bodyColor, legColor, isJumping, legPhase);
    _drawTail(canvas, r, bodyPaint, legPhase);

    // Tronco atarracado.
    canvas.drawRect(rect(0.13, 0.24, 0.42, 0.44), bodyPaint);

    // Bracinho curto perto do peito.
    canvas.drawRect(rect(0.34, 0.44, 0.12, 0.08), bodyPaint);

    // Cabeça em degraus retos (só horizontal/vertical, tipo pixel art) —
    // igual o dino do Chrome de verdade é construído, em vez da silhueta de
    // diagonais suaves de antes (lia como bico de pássaro em vez de T-Rex).
    // Boca fechada com uma pequena "mordida" no queixo (o degrau da
    // mandíbula), não mais um vão aberto.
    final head = Path()
      ..moveTo(p(0.38, 0.32).dx, p(0.38, 0.32).dy) // base do pescoço, atrás
      ..lineTo(p(0.38, 0.06).dx, p(0.38, 0.06).dy) // sobe a nuca
      ..lineTo(p(0.5, 0.06).dx, p(0.5, 0.06).dy) // degrau da nuca pro topo
      ..lineTo(p(0.5, -0.06).dx, p(0.5, -0.06).dy) // sobe pro topo da cabeça
      ..lineTo(p(0.78, -0.06).dx, p(0.78, -0.06).dy) // topo da cabeça, reto
      ..lineTo(p(0.78, 0.04).dx, p(0.78, 0.04).dy) // degrau da testa
      ..lineTo(p(0.98, 0.04).dx, p(0.98, 0.04).dy) // topo do focinho, reto
      ..lineTo(p(0.98, 0.16).dx, p(0.98, 0.16).dy) // ponta do focinho
      ..lineTo(p(0.86, 0.16).dx, p(0.86, 0.16).dy) // lábio de cima
      ..lineTo(p(0.86, 0.22).dx, p(0.86, 0.22).dy) // degrau da boca (fechada)
      ..lineTo(p(0.96, 0.22).dx, p(0.96, 0.22).dy) // queixo pra frente
      ..lineTo(p(0.96, 0.3).dx, p(0.96, 0.3).dy) // frente do queixo
      ..lineTo(p(0.66, 0.3).dx, p(0.66, 0.3).dy) // embaixo da mandíbula
      ..lineTo(p(0.66, 0.24).dx, p(0.66, 0.24).dy) // degrau da garganta
      ..lineTo(p(0.56, 0.24).dx, p(0.56, 0.24).dy)
      ..lineTo(p(0.56, 0.32).dx, p(0.56, 0.32).dy) // garganta desce
      ..lineTo(p(0.38, 0.32).dx, p(0.38, 0.32).dy) // fecha no pescoço
      ..close();
    canvas.drawPath(head, bodyPaint);

    _drawEye(canvas, p(0.6, 0.0), w * 0.055);

    if (hasCapAndChain) _drawAccessories(canvas, r);
  }

  static void _drawAccessories(Canvas canvas, Rect r) {
    final w = r.width;
    final h = r.height;
    Offset p(double fx, double fy) => Offset(r.left + fx * w, r.top + fy * h);
    const gold = Color(0xFFF2C14E);
    const goldLight = Color(0xFFFFE9A8);
    const cap = Color(0xFFE63946);

    // Boné, na cabeça.
    final capPaint = Paint()..color = cap;
    final capTop = Path()
      ..moveTo(p(0.4, 0.02).dx, p(0.4, 0.02).dy)
      ..lineTo(p(0.4, -0.06).dx, p(0.4, -0.06).dy)
      ..quadraticBezierTo(p(0.56, -0.17).dx, p(0.56, -0.17).dy, p(0.7, -0.06).dx, p(0.7, -0.06).dy)
      ..lineTo(p(0.7, 0.0).dx, p(0.7, 0.0).dy)
      ..close();
    canvas.drawPath(capTop, capPaint);
    final brim = Path()
      ..moveTo(p(0.66, -0.05).dx, p(0.66, -0.05).dy)
      ..lineTo(p(0.9, -0.01).dx, p(0.9, -0.01).dy)
      ..lineTo(p(0.82, 0.03).dx, p(0.82, 0.03).dy)
      ..lineTo(p(0.66, 0.0).dx, p(0.66, 0.0).dy)
      ..close();
    canvas.drawPath(brim, capPaint);
    canvas.drawCircle(p(0.55, -0.1), w * 0.022, Paint()..color = gold);

    // Cordão de ouro no pescoço.
    final chainPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    final chainPath = Path()
      ..moveTo(p(0.4, 0.28).dx, p(0.4, 0.28).dy)
      ..quadraticBezierTo(p(0.5, 0.4).dx, p(0.5, 0.4).dy, p(0.6, 0.28).dx, p(0.6, 0.28).dy);
    canvas.drawPath(chainPath, chainPaint);
    canvas.drawCircle(p(0.5, 0.39), w * 0.04, Paint()..color = gold);
    canvas.drawCircle(p(0.5, 0.39), w * 0.02, Paint()..color = goldLight);
  }

  /// Cauda fina e afunilada, balançando em sincronia com a passada das pernas
  /// (mesmo `legPhase` que anima os pés) — em vez de um bloco rígido parado.
  static void _drawTail(Canvas canvas, Rect r, Paint bodyPaint, double legPhase) {
    final w = r.width;
    final h = r.height;
    Offset p(double fx, double fy) => Offset(r.left + fx * w, r.top + fy * h);
    final wag = sin(legPhase * pi) * 0.045;

    final baseTop = p(0.15, 0.32);
    final baseBottom = p(0.15, 0.46);
    final tip = p(-0.2, 0.36 + wag);
    final controlTop = p(-0.03, 0.3 + wag * 0.5);
    final controlBottom = p(-0.03, 0.44 + wag * 0.5);

    final tail = Path()
      ..moveTo(baseTop.dx, baseTop.dy)
      ..quadraticBezierTo(controlTop.dx, controlTop.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(controlBottom.dx, controlBottom.dy, baseBottom.dx, baseBottom.dy)
      ..close();
    canvas.drawPath(tail, bodyPaint);
  }

  static void _drawLegs(Canvas canvas, Rect r, Color bodyColor, Color legColor, bool isJumping, double legPhase) {
    final w = r.width;
    final h = r.height;
    final thighPaint = Paint()..color = bodyColor;
    final footPaint = Paint()..color = legColor;
    final legWidth = w * 0.13;

    void drawLeg(double hipXFrac, double bottomFrac) {
      final left = r.left + hipXFrac * w;
      final top = r.top + h * 0.6;
      final bottom = r.top + h * bottomFrac;
      final kneeY = top + (bottom - top) * 0.5;

      // Coxa na cor do corpo, pra conectar visualmente com o tronco.
      canvas.drawRect(Rect.fromLTWH(left, top, legWidth, kneeY - top), thighPaint);
      // Canela/pé numa cor de destaque.
      canvas.drawRect(Rect.fromLTWH(left, kneeY, legWidth, bottom - kneeY), footPaint);

      final footRect = Rect.fromLTWH(left + legWidth * 0.2, bottom - h * 0.025, legWidth * 1.1, h * 0.05);
      canvas.drawRect(footRect, footPaint);
    }

    if (isJumping) {
      drawLeg(0.22, 0.84);
      drawLeg(0.38, 0.84);
      return;
    }

    const shift = 0.035;
    final backShift = legPhase < 1 ? -shift : shift;
    final frontShift = legPhase < 1 ? shift : -shift;
    drawLeg(0.22 + backShift, 1.0);
    drawLeg(0.38 + frontShift, 1.0);
  }
}
