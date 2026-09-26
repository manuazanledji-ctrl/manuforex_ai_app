import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider.dart';

/// Stocke localement sur le téléphone (SharedPreferences) :
/// - les clés API que l'utilisateur entre lui-même pour chaque IA
/// - quelle IA est actuellement "active" (utilisée pour le chat)
///
/// NOTE SÉCURITÉ : SharedPreferences n'est pas un stockage chiffré fort.
/// Pour une version plus avancée, on pourra migrer vers flutter_secure_storage
/// (Keystore Android / Keychain iOS) sans changer l'interface de cette classe.
class ApiKeyStorage {
  static const _keyPrefix = 'api_key_';
  static const _activeProviderKey = 'active_ai_provider';

  static Future<void> saveApiKey(AiProviderId provider, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${provider.name}', apiKey.trim());
  }

  static Future<String?> getApiKey(AiProviderId provider) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('$_keyPrefix${provider.name}');
    return (value == null || value.isEmpty) ? null : value;
  }

  static Future<void> removeApiKey(AiProviderId provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix${provider.name}');
  }

  static Future<void> setActiveProvider(AiProviderId provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProviderKey, provider.name);
  }

  static Future<AiProviderId> getActiveProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_activeProviderKey);
    return AiProviderId.values.firstWhere(
      (p) => p.name == value,
      orElse: () => AiProviderId.claude,
    );
  }

  static Future<bool> hasAnyKeyConfigured() async {
    for (final p in AiProviderId.values) {
      if (await getApiKey(p) != null) return true;
    }
    return false;
  }
}
