// Gera os PNGs de origem do ícone do app reaproveitando o mesmo
// CharacterRenderer usado no jogo (garante que o ícone bate exatamente com
// o visual do Dino Carmesim que já aparece em todo o app). `dart run` puro
// não tem os bindings do engine, por isso isso roda via `flutter test` —
// usando o mecanismo de golden-file do próprio Flutter (`matchesGoldenFile`
// + `--update-goldens`), que é o jeito confiável de rasterizar pra PNG
// nesse ambiente (chamar `toImage()` direto travou aqui).
//
// Rodar com: flutter test --update-goldens test/generate_icon_test.dart
// Gera: assets/icon/icon.png (fundo + dino, pra iOS/ícone legado — sem
// transparência) e assets/icon/icon_foreground.png (só o dino, fundo
// transparente, pro adaptive icon do Android).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jogo_dinossauro/game/character_renderer.dart';
import 'package:jogo_dinossauro/game/characters.dart';

const _bgTop = Color(0xFF17332B);
const _bgBottom = Color(0xFF0A1712);
const _amber = Color(0xFFF2A93B);
const _bodyColor = Color(0xFFE63946);
const _legColor = Color(0xFFA32833);

class _IconPainter extends CustomPainter {
  const _IconPainter({required this.withBackground});
  final bool withBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (withBackground) {
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, bgPaint);

      final glowCenter = Offset(size.width * 0.5, size.height * 0.48);
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [_amber.withValues(alpha: 0.5), _amber.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: size.width * 0.46));
      canvas.drawCircle(glowCenter, size.width * 0.46, glowPaint);
    }

    final bodyRect = Rect.fromLTWH(size.width * 0.33, size.height * 0.34, size.width * 0.4, size.height * 0.4);
    CharacterRenderer.draw(
      canvas,
      bodyRect,
      shape: CharacterShape.dino,
      bodyColor: _bodyColor,
      legColor: _legColor,
    );
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) => false;
}

Future<void> _renderPng(WidgetTester tester, {required bool withBackground, required String goldenPath}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 1024));
  await tester.pumpWidget(
    RepaintBoundary(
      child: SizedBox(
        width: 1024,
        height: 1024,
        child: CustomPaint(painter: _IconPainter(withBackground: withBackground)),
      ),
    ),
  );
  await expectLater(find.byType(RepaintBoundary), matchesGoldenFile(goldenPath));
}

void main() {
  testWidgets('gera o ícone completo (fundo + dino)', (tester) async {
    await _renderPng(tester, withBackground: true, goldenPath: '../assets/icon/icon.png');
  });

  testWidgets('gera só o dino, fundo transparente (adaptive icon)', (tester) async {
    await _renderPng(tester, withBackground: false, goldenPath: '../assets/icon/icon_foreground.png');
  });
}
