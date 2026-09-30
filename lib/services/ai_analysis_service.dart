import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service responsable d'envoyer une image de graphique (et/ou une question)
/// à un serveur intermédiaire, qui lui-même interroge l'IA vision.
///
/// IMPORTANT (sécurité) :
/// On n'appelle JAMAIS une API IA directement depuis l'app avec une clé API
/// en dur dans le code — une clé embarquée dans un APK peut être extraite.
/// Ce service appelle donc TON serveur intermédiaire (backend), qui lui,
/// détient la clé API en sécurité et la transmet à l'IA.
///
/// Pour l'instant, [backendBaseUrl] pointe vers un serveur que nous
/// n'avons pas encore construit — remplace-le dès qu'il existe.
class AiAnalysisService {
  // TODO: remplacer par l'URL réelle du backend une fois déployé
  // (ex: Render, Railway...). Exemple: https://manuforex-backend.onrender.com
  static const String backendBaseUrl = 'https://TON-BACKEND-A-DEPLOYER.example.com';

  /// Prompt d'analyse encadré par les méthodologies validées avec ManuForex :
  /// structure de marché / SMC, Fibonacci (OTE), EMA200, RSI14, MSNR,
  /// et price action générale. L'IA doit croiser ces angles plutôt que
  /// d'improviser librement.
  static const String analysisPrompt = '''
Tu es un assistant d'analyse technique de marchés financiers (forex, indices, synthétiques).
Analyse l'image de graphique fournie en croisant plusieurs méthodologies reconnues :
1. Structure de marché / Smart Money Concepts (order blocks, zones de liquidité, BOS/CHoCH)
2. Fibonacci (retracements, zone OTE)
3. Tendance via EMA200
4. Momentum via RSI14
5. MSNR (Malaysian SNR) : support/résistance en timeframe supérieur, zone de réaction,
   confirmation par bougie englobante, momentum de continuation
6. Price action générale (patterns de bougies, supports/résistances horizontaux)

Réponds de façon structurée et concise :
- Direction suggérée (ACHAT / VENTE / AUCUNE OPPORTUNITÉ CLAIRE)
- Les éléments techniques qui appuient cette conclusion
- Niveau d'entrée, stop loss et take profit approximatifs si identifiables
- Un rappel qu'aucune analyse ne garantit un résultat sur le marché
''';

  /// Envoie une image au backend pour analyse par l'IA.
  /// Retourne le texte de la réponse de l'IA.
  static Future<String> analyzeChartImage(File image, {String? userQuestion}) async {
    try {
      final uri = Uri.parse('$backendBaseUrl/analyze');
      final request = http.MultipartRequest('POST', uri);
      request.fields['prompt'] = analysisPrompt;
      if (userQuestion != null && userQuestion.trim().isNotEmpty) {
        request.fields['question'] = userQuestion.trim();
      }
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 45),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analysis'] ?? "Réponse reçue mais vide.";
      } else {
        return "Erreur du serveur (${response.statusCode}). Réessaie dans un instant.";
      }
    } catch (e) {
      return "Impossible de contacter le serveur d'analyse. "
          "Vérifie ta connexion ou réessaie plus tard.\n\n(Détail technique: $e)";
    }
  }

  /// Envoie une question texte seule (sans image) au backend, par exemple
  /// "Analyse-moi US30" — le backend ira alors chercher les données de
  /// marché via Twelve Data avant d'interroger l'IA.
  static Future<String> askMarketQuestion(String question) async {
    try {
      final uri = Uri.parse('$backendBaseUrl/ask');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'question': question, 'prompt': analysisPrompt}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analysis'] ?? "Réponse reçue mais vide.";
      } else {
        return "Erreur du serveur (${response.statusCode}). Réessaie dans un instant.";
      }
    } catch (e) {
      return "Impossible de contacter le serveur d'analyse. "
          "Vérifie ta connexion ou réessaie plus tard.\n\n(Détail technique: $e)";
    }
  }
}
