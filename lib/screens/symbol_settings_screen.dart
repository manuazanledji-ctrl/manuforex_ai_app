import 'package:flutter/material.dart';
import '../services/symbol_settings_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class SymbolSettingsScreen extends StatefulWidget {
  final String symbol;
  final SymbolTradeSettings? existing;

  const SymbolSettingsScreen({super.key, required this.symbol, this.existing});

  @override
  State<SymbolSettingsScreen> createState() => _SymbolSettingsScreenState();
}

class _SymbolSettingsScreenState extends State<SymbolSettingsScreen> {
  final _lotController = TextEditingController();
  final _tradesController = TextEditingController();
  String _platform = 'MT5';
  String _action = 'BOTH';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _lotController.text = (e?.lotSize ?? 0.01).toString();
    _tradesController.text = (e?.numberOfTrades ?? 1).toString();
    _platform = e?.platform ?? 'MT5';
    _action = e?.action ?? 'BOTH';
  }

  Future<void> _save() async {
    final lot = double.tryParse(_lotController.text.replaceAll(',', '.')) ?? 0.01;
    final trades = int.tryParse(_tradesController.text) ?? 1;
    await SymbolSettingsStorage.save(SymbolTradeSettings(
      symbol: widget.symbol,
      lotSize: lot,
      platform: _platform,
      action: _action,
      numberOfTrades: trades,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    await SymbolSettingsStorage.remove(widget.symbol);
    if (mounted) Navigator.pop(context, true);
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
        title: Text(widget.symbol),
        actions: [
          if (widget.existing != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.show_chart, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Réglages du symbole',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 4),
                      Text(
                        'Taille de lot, action autorisée et plateforme pour ce symbole.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _label('Taille de lot'),
          _field(_lotController, hint: '0.01', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _label('Plateforme'),
          _dropdown(_platform, const ['MT4', 'MT5'], (v) => setState(() => _platform = v!)),
          const SizedBox(height: 16),
          _label('Action autorisée'),
          _dropdown(_action, const ['BUY', 'SELL', 'BOTH'], (v) => setState(() => _action = v!)),
          const SizedBox(height: 16),
          _label("Nombre d'ordres"),
          _field(_tradesController, hint: '1', keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );

  Widget _field(TextEditingController c, {required String hint, TextInputType? keyboardType}) => TextField(
        controller: c,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      );

  Widget _dropdown(String value, List<String> items, void Function(String?) onChanged) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.textPrimary),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      );
}
