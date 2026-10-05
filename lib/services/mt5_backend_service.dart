import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Appelle TON backend (voir /manuforex_backend) au lieu de MetaApi
/// directement — le token maître MetaApi reste caché côté serveur, jamais
/// dans l'app. Le client ne voit que Login/Mot de passe/Serveur.
class Mt5BackendService {
  static const String backendBaseUrl = 'https://manuforexai.onrender.com';

  static const _accountIdKey = 'mt5_backend_account_id';
  static const _loginKey = 'mt5_backend_login';
  static const _serverKey = 'mt5_backend_server';
  static const _platformKey = 'mt5_backend_platform';

  static Future<void> _saveLocal(String accountId, String login, String server, String platform) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountIdKey, accountId);
    await prefs.setString(_loginKey, login);
    await prefs.setString(_serverKey, server);
    await prefs.setString(_platformKey, platform);
  }

  static Future<Map<String, String?>> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'accountId': prefs.getString(_accountIdKey),
      'login': prefs.getString(_loginKey),
      'server': prefs.getString(_serverKey),
      'platform': prefs.getString(_platformKey),
    };
  }

  /// Crée (ou retrouve) le compte MetaApi du client à partir de ses
  /// identifiants MT4/MT5, via ton backend. Retourne un message d'erreur
  /// clair en cas d'échec, jamais une exception brute.
  static Future<String?> provisionAndSave({
    required String login,
    required String password,
    required String server,
    required String platform, // 'mt4' ou 'mt5'
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$backendBaseUrl/provision'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'login': login,
              'password': password,
              'server': server,
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        return data['error']?.toString() ?? 'Erreur du serveur (${response.statusCode}).';
      }

      final accountId = data['accountId'] as String?;
      if (accountId == null) {
        return "Réponse inattendue du serveur (pas d'ID de compte reçu).";
      }
      await _saveLocal(accountId, login, server, platform);
      return null; // succès
    } catch (e) {
      return "Impossible de contacter le serveur de connexion. "
          "Vérifie ta connexion internet, ou réessaie plus tard.\n(Détail: $e)";
    }
  }

  /// Exécute un ordre réel. Retourne null en cas de succès, ou un message
  /// d'erreur clair sinon. À n'appeler qu'après confirmation explicite de
  /// l'utilisateur — ceci déplace de l'argent réel.
  static Future<String?> executeTrade({
    required String accountId,
    required String actionType, // ORDER_TYPE_BUY, ORDER_TYPE_SELL, ORDER_TYPE_BUY_LIMIT, ORDER_TYPE_SELL_LIMIT...
    required String symbol,
    required double volume,
    double? stopLoss,
    double? takeProfit,
    double? openPrice,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$backendBaseUrl/trade/$accountId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'actionType': actionType,
              'symbol': symbol,
              'volume': volume,
              if (stopLoss != null) 'stopLoss': stopLoss,
              if (takeProfit != null) 'takeProfit': takeProfit,
              if (openPrice != null) 'openPrice': openPrice,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        return data['error']?.toString() ?? 'Erreur du serveur (${response.statusCode}).';
      }
      return null; // succès
    } catch (e) {
      return "Impossible de contacter le serveur de trading.\n(Détail: $e)";
    }
  }

  static Future<Map<String, dynamic>?> fetchAccountInfo(String accountId) async {
    try {
      final response = await http
          .get(Uri.parse('$backendBaseUrl/account-info/$accountId'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
