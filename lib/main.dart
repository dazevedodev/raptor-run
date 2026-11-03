import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const DinoApp());
}

class DinoApp extends StatelessWidget {
  const DinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raptor Run',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFF6B6B),
        // O app inteiro é escuro (fundos navy, texto branco) mas o tema
        // padrão do Material 3 assume claro — sem isso, a setinha de voltar
        // e outros ícones/textos "de sistema" (não estilizados à mão em
        // cada tela) saem escuros e quase somem em cima do fundo escuro.
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
