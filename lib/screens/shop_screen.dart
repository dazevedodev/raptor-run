import 'package:flutter/material.dart';

import '../game/character_renderer.dart';
import '../game/characters.dart';
import '../game/skins.dart';
import '../services/storage_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _storage = StorageService();

  int _coins = 0;
  Set<String> _ownedSkins = {'classic'};
  String _selectedSkin = 'classic';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final coins = await _storage.getCoins();
    final ownedSkins = await _storage.getOwnedSkinIds();
    final selectedSkin = await _storage.getSelectedSkinId();
    if (!mounted) return;
    setState(() {
      _coins = coins;
      _ownedSkins = ownedSkins;
      _selectedSkin = selectedSkin;
      _loading = false;
    });
  }

  Future<void> _buySkin(Skin skin) async {
    final success = await _storage.spendCoins(skin.price);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faltam ${skin.price - _coins} moedas pra comprar ${skin.name}')),
      );
      return;
    }
    await _storage.addOwnedSkin(skin.id);
    await _storage.setSelectedSkinId(skin.id);
    await _load();
  }

  Future<void> _selectSkin(Skin skin) async {
    await _storage.setSelectedSkinId(skin.id);
    if (!mounted) return;
    setState(() => _selectedSkin = skin.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181C30),
        title: const Text('Loja'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text('$_coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('🎨 Skins', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kSkins.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final skin = kSkins[index];
                    final owned = _ownedSkins.contains(skin.id);
                    final selected = _selectedSkin == skin.id;
                    return _SkinCard(
                      skin: skin,
                      owned: owned,
                      selected: selected,
                      canAfford: _coins >= skin.price,
                      onTap: () => owned ? _selectSkin(skin) : _buySkin(skin),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const _ComingSoonSection(
                  title: '🦖 Personagens',
                  text: 'Em breve: mais personagens pra escolher e comprar com as moedas do jogo.',
                ),
                const SizedBox(height: 16),
                const _ComingSoonSection(
                  title: '✨ Especiais',
                  text: 'Em breve: power-ups e itens especiais pra usar durante a corrida.',
                ),
              ],
            ),
    );
  }
}

class _ComingSoonSection extends StatelessWidget {
  const _ComingSoonSection({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.owned,
    required this.selected,
    required this.canAfford,
    required this.onTap,
  });

  final Skin skin;
  final bool owned;
  final bool selected;
  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !owned && !canAfford;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181C30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFFF2A93B) : Colors.white.withValues(alpha: 0.1),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(child: Center(child: _CharacterPreview(shape: CharacterShape.dino, skin: skin))),
          const SizedBox(height: 8),
          Text(skin.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: disabled ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: selected
                    ? const Color(0xFFF2A93B)
                    : owned
                        ? const Color(0xFF4FAE7C)
                        : const Color(0xFF6C8CFF),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                selected ? 'Selecionado' : (owned ? 'Selecionar' : (skin.price == 0 ? 'Grátis' : '🪙 ${skin.price}')),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({required this.shape, required this.skin});

  final CharacterShape shape;
  final Skin skin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(painter: _CharacterPreviewPainter(shape: shape, skin: skin)),
    );
  }
}

class _CharacterPreviewPainter extends CustomPainter {
  _CharacterPreviewPainter({required this.shape, required this.skin});

  final CharacterShape shape;
  final Skin skin;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = Rect.fromLTWH(6, 12, size.width - 18, size.height - 22);
    CharacterRenderer.draw(
      canvas,
      bodyRect,
      shape: shape,
      bodyColor: skin.bodyColor,
      legColor: skin.legColor,
      hasCapAndChain: skin.hasCapAndChain,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterPreviewPainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.skin != skin;
}
