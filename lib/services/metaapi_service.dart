import 'dart:convert';
import 'package:http/http.dart' as http;
import 'metaapi_key_storage.dart';

/// Résultat d'une tentative de lecture du compte MetaApi.
class MetaApiAccountInfo {
  final bool success;
  final String? error;
  final double? balance;
  final double? equity;
  final String? currency;
  final String? broker;
  final int? leverage;

  MetaApiAccountInfo.success({
    required this.balance,
    required this.equity,
    required this.currency,
    required this.broker,
    required this.leverage,
  })  : success = true,
        error = null;

  MetaApiAccountInfo.failure(this.error)
      : success = false,
        balance = null,
        equity = null,
        currency = null,
        broker = null,
        leverage = null;
}

/// Connexion en lecture au compte MT4/MT5 via MetaApi.
///
/// MetaApi héberge chaque compte dans une région précise (london, new-york...).
/// On récupère d'abord cette région via l'API de provisioning, puis on
/// interroge le bon serveur régional pour les données du compte — sinon la
/// requête échoue avec une erreur 404 si on suppose la mauvaise région.
class MetaApiService {
  static Future<String?> _fetchRegion(String accountId, String token) async {
    final uri = Uri.parse('https://mt-provisioning-api-v1.agiliumtrade.agiliumtrade.ai/users/current/accounts/$accountId');
    final response = await http.get(uri, headers: {'auth-token': token}).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data['region'] as String?;
  }

  static Future<MetaApiAccountInfo> fetchAccountInfo() async {
    final token = await MetaApiKeyStorage.getToken();
    final accountId = await MetaApiKeyStorage.getAccountId();

    if (token == null || accountId == null) {
      return MetaApiAccountInfo.failure(
          "Token ou ID de compte manquant. Renseigne-les dans Connexion MT4/MT5.");
    }

    try {
      final region = await _fetchRegion(accountId, token);
      if (region == null) {
        return MetaApiAccountInfo.failure(
            "Impossible de localiser ce compte chez MetaApi. Vérifie l'ID de compte et le token.");
      }

      final uri = Uri.parse(
          'https://mt-client-api-v1.$region.agiliumtrade.ai/users/current/accounts/$accountId/account-information');
      final response = await http.get(uri, headers: {'auth-token': token}).timeout(const Duration(seconds: 25));

      if (response.statusCode == 401) {
        return MetaApiAccountInfo.failure("Token invalide ou expiré.");
      }
      if (response.statusCode == 404) {
        return MetaApiAccountInfo.failure(
            "Compte non trouvé ou pas encore déployé côté MetaApi.");
      }
      if (response.statusCode != 200) {
        return MetaApiAccountInfo.failure("Erreur MetaApi (${response.statusCode}): ${response.body}");
      }

      final data = jsonDecode(response.body);
      return MetaApiAccountInfo.success(
        balance: (data['balance'] as num?)?.toDouble(),
        equity: (data['equity'] as num?)?.toDouble(),
        currency: data['currency'] as String?,
        broker: data['broker'] as String?,
        leverage: data['leverage'] as int?,
      );
    } catch (e) {
      return MetaApiAccountInfo.failure("Erreur de connexion: $e");
    }
  }
}
