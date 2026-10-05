import 'package:flutter/material.dart';
import '../services/symbol_settings_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';
import 'symbol_settings_screen.dart';

class SymbolSettingsListScreen extends StatefulWidget {
  const SymbolSettingsListScreen({super.key});

  @override
  State<SymbolSettingsListScreen> createState() => _SymbolSettingsListScreenState();
}

class _SymbolSettingsListScreenState extends State<SymbolSettingsListScreen> {
  List<SymbolTradeSettings> _settings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await SymbolSettingsStorage.loadAll();
    if (mounted) setState(() => _settings = all);
  }

  Future<void> _addNew() async {
    final controller = TextEditingController();
    final symbol = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Nouveau symbole', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Ex: XAUUSD, US30, EURUSD'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Continuer')),
        ],
      ),
    );
    if (symbol == null || symbol.isEmpty) return;
    if (!mounted) return;
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SymbolSettingsScreen(symbol: symbol.toUpperCase())),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppSettings.instance.accentColor;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Réglages par symbole'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accent,
        onPressed: _addNew,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _settings.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "Aucun symbole configuré. Appuie sur + pour définir une taille de lot, "
                  "une action et un nombre d'ordres par défaut pour un symbole.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _settings.length,
              itemBuilder: (context, index) {
                final s = _settings[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(s.symbol, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Lot ${s.lotSize} · ${s.platform} · ${s.action} · ${s.numberOfTrades} ordre(s)',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SymbolSettingsScreen(symbol: s.symbol, existing: s)),
                      );
                      if (changed == true) _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}
