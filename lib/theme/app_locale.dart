import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { fr, en }

/// Langue active de l'app, persistée sur le téléphone. Le français est
/// la langue par défaut ; l'anglais peut être choisi dans Réglages.
class AppLocale extends ChangeNotifier {
  AppLocale._();
  static final AppLocale instance = AppLocale._();

  AppLanguage language = AppLanguage.fr;

  static const _key = 'settings_language';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    language = value == 'en' ? AppLanguage.en : AppLanguage.fr;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    language = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang == AppLanguage.en ? 'en' : 'fr');
  }
}

/// Petit dictionnaire de traduction : ajoute une clé ici, avec sa valeur
/// FR et EN, puis utilise t('ma_cle') n'importe où dans l'app.
class AppStrings {
  static final Map<String, Map<AppLanguage, String>> _dict = {
    'app_title': {AppLanguage.fr: 'No_Loss AI by ManuForex', AppLanguage.en: 'No_Loss AI by ManuForex'},
    'where_to_start': {AppLanguage.fr: 'Où veux-tu commencer ?', AppLanguage.en: 'Where should we start?'},
    'analyze_chart': {AppLanguage.fr: 'Analyser un graphique', AppLanguage.en: 'Analyze a chart'},
    'ask_signal': {AppLanguage.fr: 'Demander un signal', AppLanguage.en: 'Ask for a signal'},
    'chat_with': {AppLanguage.fr: 'Discuter avec', AppLanguage.en: 'Chat with'},
    'write_to_assistant': {AppLanguage.fr: 'Demande à No_Loss AI...', AppLanguage.en: 'Ask No_Loss AI...'},
    'image_ready': {AppLanguage.fr: 'Image prête à envoyer', AppLanguage.en: 'Image ready to send'},
    'take_photo': {AppLanguage.fr: 'Prendre une photo', AppLanguage.en: 'Take a photo'},
    'choose_gallery': {AppLanguage.fr: 'Choisir depuis la galerie', AppLanguage.en: 'Choose from gallery'},
    'mt4_mt5_connection': {AppLanguage.fr: 'Connexion MT4 / MT5', AppLanguage.en: 'MT4 / MT5 Connection'},
    'charts': {AppLanguage.fr: 'Graphiques', AppLanguage.en: 'Charts'},
    'ai_models': {AppLanguage.fr: 'Modèles IA', AppLanguage.en: 'AI Models'},
    'settings': {AppLanguage.fr: 'Réglages', AppLanguage.en: 'Settings'},
    'coming_soon': {AppLanguage.fr: 'bientôt disponible', AppLanguage.en: 'coming soon'},
    'accent_color': {AppLanguage.fr: "Couleur d'accent", AppLanguage.en: 'Accent color'},
    'wallpaper': {AppLanguage.fr: "Fond d'écran", AppLanguage.en: 'Wallpaper'},
    'change': {AppLanguage.fr: 'Changer', AppLanguage.en: 'Change'},
    'choose_image': {AppLanguage.fr: 'Choisir une image', AppLanguage.en: 'Choose an image'},
    'remove': {AppLanguage.fr: 'Retirer', AppLanguage.en: 'Remove'},
    'wallpaper_hint': {
      AppLanguage.fr: "Le fond d'écran s'affichera derrière la conversation.",
      AppLanguage.en: 'The wallpaper will show behind the conversation.',
    },
    'language': {AppLanguage.fr: 'Langue', AppLanguage.en: 'Language'},
    'french': {AppLanguage.fr: 'Français', AppLanguage.en: 'French'},
    'english': {AppLanguage.fr: 'Anglais', AppLanguage.en: 'English'},
    'ai_models_intro': {
      AppLanguage.fr: "Ajoute ta clé API pour chaque IA, puis sélectionne celle qui sera utilisée dans le chat.",
      AppLanguage.en: 'Add your API key for each AI, then select which one will be used in chat.',
    },
    'save_key': {AppLanguage.fr: 'Enregistrer la clé', AppLanguage.en: 'Save key'},
    'use_this_ai': {AppLanguage.fr: 'Utiliser cette IA', AppLanguage.en: 'Use this AI'},
    'active': {AppLanguage.fr: 'Active', AppLanguage.en: 'Active'},
    'key_saved': {AppLanguage.fr: 'enregistrée', AppLanguage.en: 'saved'},
    'add_key_first': {
      AppLanguage.fr: 'Ajoute une clé API avant de sélectionner cette IA',
      AppLanguage.en: 'Add an API key before selecting this AI',
    },
    'create_robot': {AppLanguage.fr: 'Créer un robot', AppLanguage.en: 'Create a Robot'},
    'create_robot_prompt': {
      AppLanguage.fr: 'Écris-moi un Expert Advisor MQL5 qui ',
      AppLanguage.en: 'Write me an MQL5 Expert Advisor that ',
    },
    'predict_signal': {AppLanguage.fr: 'Prédire un signal', AppLanguage.en: 'Predict signal'},
    'predict_signal_prompt': {AppLanguage.fr: 'Analyse-moi ', AppLanguage.en: 'Analyze '},
    'cheatcodes': {AppLanguage.fr: 'Cheatcodes', AppLanguage.en: 'Cheatcodes'},
    'cheatcodes_prompt': {
      AppLanguage.fr:
          'Fais-moi une analyse fondamentale macroéconomique globale des devises majeures et indique quelle devise acheter contre quelle devise vendre actuellement.',
      AppLanguage.en:
          'Give me a global macroeconomic fundamental analysis of major currencies and tell me which currency to buy against which to sell right now.',
    },
  };

  static String t(String key) {
    final entry = _dict[key];
    if (entry == null) return key;
    return entry[AppLocale.instance.language] ?? entry[AppLanguage.fr]!;
  }
}
