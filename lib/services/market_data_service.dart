import 'dart:convert';
import 'package:http/http.dart' as http;
import 'market_data_key_storage.dart';

/// Symboles disponibles pour l'analyse, avec leur équivalent au format
/// attendu par l'API Twelve Data (différent du format TradingView).
class TradedSymbol {
  final String label; // ex: XAUUSD
  final String twelveDataSymbol; // ex: XAU/USD

  const TradedSymbol(this.label, this.twelveDataSymbol);

  static const List<TradedSymbol> all = [
    TradedSymbol('XAUUSD', 'XAU/USD'),
    TradedSymbol('US30', 'DJI'),
    TradedSymbol('NAS100', 'NDX'),
    TradedSymbol('EURUSD', 'EUR/USD'),
    TradedSymbol('GBPUSD', 'GBP/USD'),
  ];
}

class MarketDataService {
  /// Timeframes récupérées pour une analyse multi-timeframe complète, du
  /// contexte général (H4) jusqu'au timing d'entrée précis (M5) — l'IA ne
  /// doit jamais se baser sur une seule unité de temps.
  /// Détecte si un message en texte libre fait référence à un marché connu
  /// (ex: "le marché de l'or", "US30", "nasdaq"...), pour pouvoir aller
  /// chercher automatiquement de vraies données même hors du bouton dédié
  /// "Prédire un signal".
  static TradedSymbol? matchKeyword(String text) {
    final lower = text.toLowerCase();
    const aliases = <String, String>{
      'xauusd': 'XAUUSD', 'or ': 'XAUUSD', "l'or": 'XAUUSD', 'gold': 'XAUUSD',
      'us30': 'US30', 'dow jones': 'US30', 'dow ': 'US30',
      'nas100': 'NAS100', 'nasdaq': 'NAS100',
      'eurusd': 'EURUSD', 'euro dollar': 'EURUSD', 'eur/usd': 'EURUSD',
      'gbpusd': 'GBPUSD', 'livre sterling': 'GBPUSD', 'gbp/usd': 'GBPUSD',
    };
    for (final entry in aliases.entries) {
      if (lower.contains(entry.key)) {
        return TradedSymbol.all.firstWhere((s) => s.label == entry.value);
      }
    }
    return null;
  }

  static const List<Map<String, String>> _timeframes = [
    {'interval': '4h', 'label': 'H4 (structure générale / biais)'},
    {'interval': '1h', 'label': 'H1 (structure intermédiaire)'},
    {'interval': '15min', 'label': 'M15 (zone de réaction)'},
    {'interval': '5min', 'label': 'M5 (timing d\'entrée précis)'},
  ];

  /// Recherche libre parmi TOUS les actifs proposés par Twelve Data (actions,
  /// forex, indices, crypto, ETF...) via leur endpoint symbol_search — plus
  /// aucune limite à une liste fixe de 5 marchés.
  static Future<List<TwelveDataSearchResult>> search(String query) async {
    final apiKey = await MarketDataKeyStorage.getApiKey();
    if (apiKey == null || query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        'https://api.twelvedata.com/symbol_search'
        '?symbol=${Uri.encodeComponent(query.trim())}&apikey=$apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final list = data['data'] as List?;
      if (list == null) return [];

      return list
          .map((e) => TwelveDataSearchResult(
                symbol: e['symbol']?.toString() ?? '',
                name: e['instrument_name']?.toString() ?? e['symbol']?.toString() ?? '',
                exchange: e['exchange']?.toString() ?? '',
                type: e['instrument_type']?.toString() ?? '',
              ))
          .where((r) => r.symbol.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Récupère les données sur PLUSIEURS unités de temps (H4/H1/M15/M5) pour
  /// permettre une vraie analyse descendante (top-down) : biais sur le
  /// temps long, confirmation sur le temps intermédiaire, timing d'entrée
  /// sur le temps court — jamais une décision basée sur une seule TF.
  static Future<String> fetchSummary(TradedSymbol symbol) async {
    final apiKey = await MarketDataKeyStorage.getApiKey();
    if (apiKey == null) {
      return "ERREUR: Aucune clé API Twelve Data configurée. "
          "Ouvre le menu (☰) → Modèles IA → section Données de marché.";
    }

    final results = await Future.wait(
      _timeframes.map((tf) => _fetchOneTimeframe(symbol, tf['interval']!, tf['label']!, apiKey)),
    );

    final successCount = results.where((r) => !r.contains('ERREUR')).length;
    if (successCount == 0) {
      return "ERREUR: impossible de récupérer les données pour ${symbol.label} sur toutes les "
          "timeframes.\n\n${results.join('\n')}";
    }

    final buffer = StringBuffer();
    buffer.writeln('Symbole: ${symbol.label} (source: Twelve Data, multi-timeframe)');
    buffer.writeln();
    for (final r in results) {
      buffer.writeln(r);
      buffer.writeln();
    }
    return buffer.toString();
  }

  static Future<String> _fetchOneTimeframe(
    TradedSymbol symbol,
    String interval,
    String label,
    String apiKey,
  ) async {
    try {
      final uri = Uri.parse(
        'https://api.twelvedata.com/time_series'
        '?symbol=${Uri.encodeComponent(symbol.twelveDataSymbol)}'
        '&interval=$interval&outputsize=20&apikey=$apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return "--- $label ---\nERREUR: code ${response.statusCode}";
      }

      final data = jsonDecode(response.body);
      if (data['status'] == 'error' || data['values'] == null) {
        return "--- $label ---\nERREUR: ${data['message'] ?? 'symbole ou clé invalide'}";
      }

      final values = data['values'] as List;
      if (values.isEmpty) {
        return "--- $label ---\nERREUR: aucune donnée reçue";
      }

      final latest = values.first;
      final highs = values.map((v) => double.tryParse(v['high'].toString()) ?? 0).toList();
      final lows = values.map((v) => double.tryParse(v['low'].toString()) ?? 0).toList();
      final highestRecent = highs.reduce((a, b) => a > b ? a : b);
      final lowestRecent = lows.reduce((a, b) => a < b ? a : b);

      final last3 = values.take(3).map((v) {
        final vol = v['volume'];
        return "  ${v['datetime']}: O=${v['open']} H=${v['high']} L=${v['low']} C=${v['close']}"
            "${vol != null ? ' Vol=$vol' : ''}";
      }).join('\n');

      return '''--- $label ---
Prix actuel (dernière clôture): ${latest['close']}
Plus haut récent (20 dernières bougies): $highestRecent
Plus bas récent (20 dernières bougies): $lowestRecent
3 dernières bougies:
$last3''';
    } catch (e) {
      return "--- $label ---\nERREUR: $e";
    }
  }
}

/// Un résultat de recherche Twelve Data (symbol_search).
class TwelveDataSearchResult {
  final String symbol;
  final String name;
  final String exchange;
  final String type;

  TwelveDataSearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.type,
  });

  TradedSymbol toTradedSymbol() => TradedSymbol('$symbol${exchange.isNotEmpty ? " ($exchange)" : ""}', symbol);
}
