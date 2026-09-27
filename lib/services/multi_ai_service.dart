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

MÉTHODE OBLIGATOIRE — ANALYSE MULTI-TIMEFRAME DESCENDANTE (TOP-DOWN) :
Ne JAMAIS baser une analyse sur une seule unité de temps. Quand plusieurs timeframes sont
fournies (H4, H1, M15, M5), procède TOUJOURS dans cet ordre :
1. H4 : détermine le biais directionnel de fond et la structure générale
2. H1 : confirme ou nuance ce biais, identifie la zone d'intérêt (order block, S/R, zone
   de liquidité) vers laquelle le prix se dirige probablement
3. M15 : repère la zone de réaction précise (SMC/MSNR) à l'intérieur de la zone H1
4. M5 : affine le timing d'entrée exact (confirmation par bougie, momentum)
Si les timeframes se contredisent (ex: H4 haussier mais M15 baissier), dis-le clairement
et explique comment tu résous ce conflit plutôt que de l'ignorer.

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

  /// Utilisé spécifiquement par le bouton "Cheatcodes" : active la recherche
  /// web côté API (quand le fournisseur le permet) pour une analyse macro
  /// basée sur des informations réelles et récentes, pas seulement sur la
  /// connaissance générale figée du modèle.
  static Future<String> askCheatcodes(String question) async {
    final providerId = await ApiKeyStorage.getActiveProvider();
    final apiKey = await ApiKeyStorage.getApiKey(providerId);

    if (apiKey == null) {
      return "Aucune clé API configurée pour ${AiProvider.byId(providerId).displayName}.\n"
          "Ouvre le menu (☰) → Modèles IA pour en ajouter une.";
    }

    try {
      switch (providerId) {
        case AiProviderId.claude:
          return await _askClaude(apiKey, question, null, enableWebSearch: true);
        case AiProviderId.gemini:
          return await _askGemini(apiKey, question, null, enableWebSearch: true);
        case AiProviderId.chatgpt:
          final answer = await _askChatGpt(apiKey, question, null);
          return "⚠️ Recherche web non disponible avec ChatGPT dans cette version — "
              "réponse basée sur les connaissances générales du modèle, pas sur "
              "des données économiques en temps réel.\n\n$answer";
      }
    } catch (e) {
      return "Erreur lors de l'appel à l'IA. Vérifie ta clé API et ta connexion.\n"
          "(Détail technique: $e)";
    }
  }

  /// Utilisé par le bouton "Prédire un signal" une fois qu'un symbole est
  /// choisi : combine les vraies données de marché (Twelve Data) avec le
  /// prompt d'analyse, pour que l'IA travaille sur des chiffres réels et
  /// non sur sa seule mémoire générale.
  static Future<String> askPredictSignal({
    required String symbolLabel,
    required String marketDataSummary,
  }) async {
    if (marketDataSummary.startsWith('ERREUR')) {
      return marketDataSummary;
    }
    final question =
        'Analyse le marché $symbolLabel en croisant plusieurs unités de temps (H4/H1/M15/M5).\n\n'
        'Données de marché réelles (Twelve Data):\n$marketDataSummary\n\n'
        'Base ton analyse UNIQUEMENT sur ces données réelles fournies ci-dessus, en suivant '
        'la méthode top-down obligatoire (H4 → H1 → M15 → M5).';
    return ask(question: question);
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

  static Future<String> _askClaude(String apiKey, String question, File? image, {bool enableWebSearch = false}) async {
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

    final body = <String, dynamic>{
      'model': 'claude-sonnet-5',
      'max_tokens': 1024,
      'messages': [
        {'role': 'user', 'content': content}
      ],
    };
    if (enableWebSearch) {
      body['tools'] = [
        {'type': 'web_search_20250305', 'name': 'web_search'}
      ];
    }

    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

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

  static Future<String> _askGemini(String apiKey, String question, File? image, {bool enableWebSearch = false}) async {
    final parts = <Map<String, dynamic>>[
      {'text': '${_buildPrompt()}\n\nDemande de l\'utilisateur: $question'},
    ];
    if (image != null) {
      final bytes = await image.readAsBytes();
      parts.add({
        'inline_data': {'mime_type': 'image/jpeg', 'data': base64Encode(bytes)},
      });
    }

    final body = <String, dynamic>{
      'contents': [
        {'parts': parts}
      ],
    };
    if (enableWebSearch) {
      body['tools'] = [
        {'google_search': {}}
      ];
    }

    final response = await http
        .post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['candidates'][0]['content']['parts'][0]['text'] ?? '').toString().trim();
    }
    return "Erreur Gemini (${response.statusCode}): ${response.body}";
  }
}

