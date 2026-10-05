import 'package:shared_preferences/shared_preferences.dart';

/// Stocke localement la clé API Twelve Data, utilisée pour récupérer des
/// données de marché réelles (prix, bougies OHLC) à donner à l'IA.
class MarketDataKeyStorage {
  static const _key = 'twelve_data_api_key';

  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, apiKey.trim());
  }

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    return (value == null || value.isEmpty) ? null : value;
  }

  static Future<void> removeApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
