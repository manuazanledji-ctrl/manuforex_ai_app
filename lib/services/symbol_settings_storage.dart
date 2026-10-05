import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SymbolTradeSettings {
  final String symbol;
  final double lotSize;
  final String platform; // 'MT4' ou 'MT5'
  final String action; // 'BUY', 'SELL', 'BOTH'
  final int numberOfTrades;

  SymbolTradeSettings({
    required this.symbol,
    required this.lotSize,
    required this.platform,
    required this.action,
    required this.numberOfTrades,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'lotSize': lotSize,
        'platform': platform,
        'action': action,
        'numberOfTrades': numberOfTrades,
      };

  static SymbolTradeSettings fromJson(Map<String, dynamic> j) => SymbolTradeSettings(
        symbol: j['symbol'],
        lotSize: (j['lotSize'] as num).toDouble(),
        platform: j['platform'],
        action: j['action'],
        numberOfTrades: j['numberOfTrades'],
      );
}

/// Réglages de trading configurables par symbole (taille de lot, plateforme,
/// action autorisée, nombre d'ordres) — utilisés pour pré-remplir le
/// formulaire d'exécution d'ordre.
class SymbolSettingsStorage {
  static const _key = 'symbol_trade_settings';

  static Future<List<SymbolTradeSettings>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => SymbolTradeSettings.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<SymbolTradeSettings?> loadFor(String symbol) async {
    final all = await loadAll();
    try {
      return all.firstWhere((s) => s.symbol.toUpperCase() == symbol.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(SymbolTradeSettings settings) async {
    final all = await loadAll();
    all.removeWhere((s) => s.symbol.toUpperCase() == settings.symbol.toUpperCase());
    all.add(settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all.map((s) => s.toJson()).toList()));
  }

  static Future<void> remove(String symbol) async {
    final all = await loadAll();
    all.removeWhere((s) => s.symbol.toUpperCase() == symbol.toUpperCase());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all.map((s) => s.toJson()).toList()));
  }
}
