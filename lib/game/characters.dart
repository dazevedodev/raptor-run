enum CharacterShape { dino }

class CharacterDef {
  const CharacterDef({
    required this.id,
    required this.name,
    required this.shape,
    required this.price,
  });

  final String id;
  final String name;
  final CharacterShape shape;
  final int price;
}

/// Por enquanto só o Dino existe (grátis, já desbloqueado). O campo `price`
/// continua existindo pra quando decidirmos quais e quantos personagens
/// novos entram — a loja já está preparada pra vender personagens pagos
/// quando chegar a hora.
const List<CharacterDef> kCharacters = [
  CharacterDef(id: 'dino', name: 'Dino', shape: CharacterShape.dino, price: 0),
];

CharacterDef characterForId(String id) => kCharacters.firstWhere((c) => c.id == id, orElse: () => kCharacters.first);
