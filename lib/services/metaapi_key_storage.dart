import 'package:shared_preferences/shared_preferences.dart';

/// Stocke localement le token MetaApi et l'ID du compte de trading connecté.
class MetaApiKeyStorage {
  static const _tokenKey = 'metaapi_token';
  static const _accountIdKey = 'metaapi_account_id';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.trim());
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_tokenKey);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> saveAccountId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountIdKey, id.trim());
  }

  static Future<String?> getAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_accountIdKey);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<bool> isConfigured() async {
    return await getToken() != null && await getAccountId() != null;
  }
}
