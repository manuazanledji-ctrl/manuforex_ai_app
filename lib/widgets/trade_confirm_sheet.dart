import 'package:flutter/material.dart';
import '../services/mt5_backend_service.dart';
import '../services/symbol_settings_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

/// Tente d'extraire entrée/SL/TP/type d'ordre depuis le texte Markdown
/// renvoyé par l'IA, pour pré-remplir le formulaire — l'utilisateur garde
/// toujours la main pour vérifier/corriger avant confirmation.
class ExtractedSetup {
  String? orderType; // BUY LIMIT, SELL MARKET, etc.
  double? entry;
  double? stopLoss;
  double? takeProfit1;

  static ExtractedSetup fromText(String text) {
    final s = ExtractedSetup();
    final orderMatch = RegExp(r'(BUY|SELL)\s*(LIMIT|MARKET|STOP)?', caseSensitive: false).firstMatch(text);
    if (orderMatch != null) s.orderType = orderMatch.group(0)?.toUpperCase().trim();

    double? extractNumber(String label) {
      final m = RegExp('$label[^0-9]*([0-9]+[.,]?[0-9]*)', caseSensitive: false).firstMatch(text);
      if (m == null) return null;
      return double.tryParse(m.group(1)!.replaceAll(',', '.'));
    }

    s.entry = extractNumber("Prix d'entrée") ?? extractNumber('Entrée sniper') ?? extractNumber('Entry');
    s.stopLoss = extractNumber('Stop Loss');
    s.takeProfit1 = extractNumber('Take Profit 1') ?? extractNumber('Take Profit');
    return s;
  }
}

Future<void> showTradeConfirmSheet(
  BuildContext context, {
  required String accountId,
  required String symbolLabel,
  required String metaApiSymbol,
  required String aiResponseText,
}) async {
  final extracted = ExtractedSetup.fromText(aiResponseText);
  final symbolSettings = await SymbolSettingsStorage.loadFor(symbolLabel);
  final symbolController = TextEditingController(text: metaApiSymbol);
  final volumeController = TextEditingController(text: (symbolSettings?.lotSize ?? 0.01).toString());
  final entryController = TextEditingController(text: extracted.entry?.toString() ?? '');
  final slController = TextEditingController(text: extracted.stopLoss?.toString() ?? '');
  final tpController = TextEditingController(text: extracted.takeProfit1?.toString() ?? '');
  String direction = (extracted.orderType?.contains('SELL') ?? false) ? 'SELL' : 'BUY';
  String orderKind = (extracted.orderType?.contains('LIMIT') ?? false) ? 'LIMIT' : 'MARKET';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    builder: (context) {
      bool isSending = false;
      String? error;
      String? success;

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> confirm() async {
            setState(() {
              isSending = true;
              error = null;
            });

            final actionType = orderKind == 'MARKET'
                ? (direction == 'BUY' ? 'ORDER_TYPE_BUY' : 'ORDER_TYPE_SELL')
                : (direction == 'BUY' ? 'ORDER_TYPE_BUY_LIMIT' : 'ORDER_TYPE_SELL_LIMIT');

            final volume = double.tryParse(volumeController.text.replaceAll(',', '.'));
            final sl = double.tryParse(slController.text.replaceAll(',', '.'));
            final tp = double.tryParse(tpController.text.replaceAll(',', '.'));
            final entry = double.tryParse(entryController.text.replaceAll(',', '.'));

            if (volume == null || volume <= 0) {
              setState(() {
                error = 'Volume invalide.';
                isSending = false;
              });
              return;
            }
            if (orderKind == 'LIMIT' && entry == null) {
              setState(() {
                error = "Prix d'entrée requis pour un ordre LIMIT.";
                isSending = false;
              });
              return;
            }

            final result = await Mt5BackendService.executeTrade(
              accountId: accountId,
              actionType: actionType,
              symbol: symbolController.text.trim(),
              volume: volume,
              stopLoss: sl,
              takeProfit: tp,
              openPrice: orderKind == 'LIMIT' ? entry : null,
            );

            setState(() {
              isSending = false;
              if (result == null) {
                success = 'Ordre envoyé avec succès.';
              } else {
                error = result;
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Confirmer le setup avant envoi',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 4),
                    const Text(
                      'Vérifie chaque valeur — un ordre envoyé est réel et irréversible.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (symbolSettings != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Réglage ${symbolSettings.symbol} appliqué : lot ${symbolSettings.lotSize} · '
                        'action autorisée ${symbolSettings.action}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown(
                            value: direction,
                            items: const ['BUY', 'SELL'],
                            onChanged: (v) => setState(() => direction = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dropdown(
                            value: orderKind,
                            items: const ['MARKET', 'LIMIT'],
                            onChanged: (v) => setState(() => orderKind = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(symbolController, 'Symbole (format MetaApi, ex: XAUUSD)'),
                    const SizedBox(height: 10),
                    _field(volumeController, 'Volume (lots)', keyboardType: TextInputType.number),
                    if (orderKind == 'LIMIT') ...[
                      const SizedBox(height: 10),
                      _field(entryController, "Prix d'entrée", keyboardType: TextInputType.number),
                    ],
                    const SizedBox(height: 10),
                    _field(slController, 'Stop Loss (optionnel)', keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    _field(tpController, 'Take Profit (optionnel)', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(error!, style: const TextStyle(color: Color(0xFFC62828))),
                      ),
                    if (success != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(success!, style: const TextStyle(color: Color(0xFF2E7D32))),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSending || success != null ? null : confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppSettings.instance.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isSending
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(success != null ? 'Envoyé ✓' : "Confirmer et envoyer l'ordre",
                                style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Widget _dropdown({required String value, required List<String> items, required void Function(String?) onChanged}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10)),
    child: DropdownButton<String>(
      value: value,
      isExpanded: true,
      underline: const SizedBox(),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    ),
  );
}
