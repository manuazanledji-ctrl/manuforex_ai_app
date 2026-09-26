import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';
import '../theme/app_locale.dart';
import 'api_key_storage.dart';

/// Envoie directement la question (+ image éventuelle) à l'IA choisie par
/// l'utilisateur, en utilisant SA propre clé API stockée sur son téléphone.
/// Pas de serveur intermédiaire nécessaire pour cette partie.
class MultiAiService {
  static String _buildPrompt() {
    final lang = AppLocale.instance.language == AppLanguage.en ? 'Anglais' : 'Français';
    return '''
Tu es ManuForex AI, un copilot de trading institutionnel spécialisé dans les "entrées sniper".

BIBLIOTHÈQUE DE STRATÉGIES DISPONIBLES (choisis la plus pertinente selon le contexte, ou croise-en plusieurs) :
1. SMC/ICT : Liquidity Sweep, BOS, CHoCH, Order Block, Fair Value Gap, retracement OTE.
2. MSNR (Malaysian Support & Resistance) : Sniper Levels H4/H1 cassés avec force, réaction attendue en M5/M1.
3. Supply & Demand : zones vierges RBR/DBD (rally-base-rally / drop-base-drop).
4. Wyckoff : phases de piège (Spring en accumulation, Upthrust en distribution).
5. Price Action pur : structure de marché, mèches de rejet, pinbars, bougies englobantes.

RÈGLE DE L'ENTRÉE SNIPER :
La précision vise un drawdown minimal via une vraie réaction du prix — PAS un Stop Loss
artificiellement minuscule. Le SL doit être placé derrière la véritable zone d'invalidation
structurelle (high/low logique), pas un chiffre arbitraire.

LOGIQUE D'EXÉCUTION SELON LA POSITION DU PRIX :
1. Prix avant la zone (en attente de retest) → ordre différé BUY LIMIT / SELL LIMIT.
2. Prix dans la zone de réaction → ordre immédiat BUY MARKET / SELL MARKET.
3. Prix ayant quitté la zone → MARKET seulement si R:R reste ≥ 1:2.5, sinon propose un
   LIMIT sur micro-retest plutôt que de chasser le prix.

Si une image de graphique est fournie, analyse-la avec cette méthode. Si seule une question
texte est posée (ex: nom d'un marché), base ton analyse sur les éléments que l'utilisateur
te donne dans sa question.

FORMAT DE RÉPONSE ATTENDU (concis) :
- Biais & stratégie(s) activée(s)
- Type d'ordre (MARKET / LIMIT)
- Prix d'entrée sniper
- Stop Loss structurel
- Take Profit 1 & 2
- Ratio Risque/Rendement (R:R)
- Rappel qu'aucune analyse ne garantit un résultat sur le marché

Réponds en $lang.
''';
  }

  static Future<String> ask({required String question, File? image}) async {
    final providerId = await ApiKeyStorage.getActiveProvider();
    final apiKey = await ApiKeyStorage.getApiKey(providerId);

    if (apiKey == null) {
      return "Aucune clé API configurée pour ${AiProvider.byId(providerId).displayName}.\n"
          "Ouvre le menu (☰) → Modèles IA pour en ajouter une.";
    }

    try {
      switch (providerId) {
        case AiProviderId.claude:
          return await _askClaude(apiKey, question, image);
        case AiProviderId.chatgpt:
          return await _askChatGpt(apiKey, question, image);
        case AiProviderId.gemini:
          return await _askGemini(apiKey, question, image);
      }
    } catch (e) {
      return "Erreur lors de l'appel à l'IA. Vérifie ta clé API et ta connexion.\n"
          "(Détail technique: $e)";
    }
  }

  static Future<String> _askClaude(String apiKey, String question, File? image) async {
    final content = <Map<String, dynamic>>[];
    if (image != null) {
      final bytes = await image.readAsBytes();
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/jpeg',
          'data': base64Encode(bytes),
        },
      });
    }
    content.add({'type': 'text', 'text': '${_buildPrompt()}\n\nDemande de l\'utilisateur: $question'});

    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-3-5-sonnet-20241022',
            'max_tokens': 1024,
            'messages': [
              {'role': 'user', 'content': content}
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final blocks = data['content'] as List;
      return blocks.map((b) => b['text'] ?? '').join('\n').trim();
    }
    return "Erreur Claude (${response.statusCode}): ${response.body}";
  }

  static Future<String> _askChatGpt(String apiKey, String question, File? image) async {
    final content = <Map<String, dynamic>>[
      {'type': 'text', 'text': '${_buildPrompt()}\n\nDemande de l\'utilisateur: $question'},
    ];
    if (image != null) {
      final bytes = await image.readAsBytes();
      content.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,${base64Encode(bytes)}'},
      });
    }

    final response = await http
        .post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'max_tokens': 1024,
            'messages': [
              {'role': 'user', 'content': content}
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['choices'][0]['message']['content'] ?? '').toString().trim();
    }
    return "Erreur ChatGPT (${response.statusCode}): ${response.body}";
  }

  static Future<String> _askGemini(String apiKey, String question, File? image) async {
    final parts = <Map<String, dynamic>>[
      {'text': '${_buildPrompt()}\n\nDemande de l\'utilisateur: $question'},
    ];
    if (image != null) {
      final bytes = await image.readAsBytes();
      parts.add({
        'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(bytes)},
      });
    }

    final response = await http
        .post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': parts}
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['candidates'][0]['content']['parts'][0]['text'] ?? '').toString().trim();
    }
    return "Erreur Gemini (${response.statusCode}): ${response.body}";
  }
}

