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
  /// Récupère les dernières bougies M15 pour le symbole donné et retourne
  /// un résumé texte compact (prix actuel, plus haut/bas récents) à insérer
  /// dans le prompt envoyé à l'IA. Retourne un message d'erreur clair si la
  /// clé API manque ou si la requête échoue — jamais de données inventées.
  static Future<String> fetchSummary(TradedSymbol symbol) async {
    final apiKey = await MarketDataKeyStorage.getApiKey();
    if (apiKey == null) {
      return "ERREUR: Aucune clé API Twelve Data configurée. "
          "Ouvre le menu (☰) → Modèles IA → section Données de marché.";
    }

    try {
      final uri = Uri.parse(
        'https://api.twelvedata.com/time_series'
        '?symbol=${Uri.encodeComponent(symbol.twelveDataSymbol)}'
        '&interval=15min&outputsize=30&apikey=$apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return "ERREUR: Twelve Data a répondu avec le code ${response.statusCode}.";
      }

      final data = jsonDecode(response.body);
      if (data['status'] == 'error' || data['values'] == null) {
        return "ERREUR Twelve Data: ${data['message'] ?? 'symbole ou clé invalide'}.";
      }

      final values = data['values'] as List;
      if (values.isEmpty) {
        return "ERREUR: aucune donnée reçue pour ${symbol.label}.";
      }

      final latest = values.first;
      final closes = values.map((v) => double.tryParse(v['close'].toString()) ?? 0).toList();
      final highs = values.map((v) => double.tryParse(v['high'].toString()) ?? 0).toList();
      final lows = values.map((v) => double.tryParse(v['low'].toString()) ?? 0).toList();
      final highestRecent = highs.reduce((a, b) => a > b ? a : b);
      final lowestRecent = lows.reduce((a, b) => a < b ? a : b);

      final last5 = values.take(5).map((v) {
        return "  ${v['datetime']}: O=${v['open']} H=${v['high']} L=${v['low']} C=${v['close']}";
      }).join('\n');

      return '''
Symbole: ${symbol.label} (source: Twelve Data, M15)
Prix actuel (dernière clôture): ${latest['close']}
Plus haut sur les 30 dernières bougies M15: $highestRecent
Plus bas sur les 30 dernières bougies M15: $lowestRecent
5 dernières bougies:
$last5
''';
    } catch (e) {
      return "ERREUR lors de la récupération des données de marché: $e";
    }
  }
}
