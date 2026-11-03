import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jogo_dinossauro/main.dart';

void main() {
  testWidgets('Tela inicial mostra o título e o botão de jogar', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const DinoApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('RAPTOR RUN'), findsOneWidget);
    expect(find.text('JOGAR'), findsOneWidget);
  });
}
