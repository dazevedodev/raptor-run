import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService();

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  String _controlScheme = 'swipe';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final music = await _storage.getMusicEnabled();
    final sfx = await _storage.getSfxEnabled();
    final scheme = await _storage.getControlScheme();
    if (!mounted) return;
    setState(() {
      _musicEnabled = music;
      _sfxEnabled = sfx;
      _controlScheme = scheme;
      _loading = false;
    });
  }

  Future<void> _setMusic(bool value) async {
    setState(() => _musicEnabled = value);
    await AudioService.instance.setMusicEnabled(value);
  }

  Future<void> _setSfx(bool value) async {
    setState(() => _sfxEnabled = value);
    await AudioService.instance.setSfxEnabled(value);
  }

  Future<void> _setControlScheme(String scheme) async {
    setState(() => _controlScheme = scheme);
    await _storage.setControlScheme(scheme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181C30),
        title: const Text('Configurações'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SettingsSectionTitle(title: '🔊 Som'),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _musicEnabled,
                        onChanged: _setMusic,
                        activeThumbColor: const Color(0xFFE5A63E),
                        title: const Text('Música de fundo', style: TextStyle(color: Colors.white)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      SwitchListTile(
                        value: _sfxEnabled,
                        onChanged: _setSfx,
                        activeThumbColor: const Color(0xFFE5A63E),
                        title: const Text('Efeitos sonoros', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Pulo, moeda, fim de jogo', style: TextStyle(color: Colors.white54)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SettingsSectionTitle(title: '🎮 Controle'),
                const SizedBox(height: 8),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Como pular e abaixar durante a corrida:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ControlOption(
                              label: 'Deslizar na tela',
                              description: 'Deslize pra cima pra pular, pra baixo pra abaixar',
                              selected: _controlScheme == 'swipe',
                              onTap: () => _setControlScheme('swipe'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ControlOption(
                              label: 'Botões na tela',
                              description: 'Botão de pular e botão de abaixar',
                              selected: _controlScheme == 'buttons',
                              onTap: () => _setControlScheme('buttons'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181C30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _ControlOption extends StatelessWidget {
  const _ControlOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE5A63E).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE5A63E) : Colors.white.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? const Color(0xFFE5A63E) : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
