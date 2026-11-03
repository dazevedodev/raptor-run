import 'package:flutter/material.dart';

class Skin {
  const Skin({
    required this.id,
    required this.name,
    required this.bodyColor,
    required this.legColor,
    required this.price,
    this.hasCapAndChain = false,
  });

  final String id;
  final String name;
  final Color bodyColor;
  final Color legColor;
  final int price;

  /// Acessórios extras (boné + cordão de ouro) desenhados por cima do
  /// personagem — ver `CharacterRenderer._drawAccessories`.
  final bool hasCapAndChain;
}

/// A Carmesim (vermelha) é a padrão, grátis e já vem desbloqueada. As
/// outras são compradas na loja com as moedas do jogo — pra adicionar uma
/// nova, é só acrescentar mais uma entrada aqui.
const List<Skin> kSkins = [
  Skin(id: 'crimson', name: 'Carmesim', bodyColor: Color(0xFFE63946), legColor: Color(0xFFA32833), price: 0),
  Skin(id: 'classic', name: 'Clássico', bodyColor: Color(0xFF2E2E2E), legColor: Color(0xFF1A1A1A), price: 20),
  Skin(
    id: 'swag',
    name: 'Rapper',
    bodyColor: Color(0xFF3F4A9C),
    legColor: Color(0xFF2A3170),
    price: 120,
    hasCapAndChain: true,
  ),
];

Skin skinForId(String id) => kSkins.firstWhere((s) => s.id == id, orElse: () => kSkins.first);
