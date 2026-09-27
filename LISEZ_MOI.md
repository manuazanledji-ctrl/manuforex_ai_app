# ManuForex AI — Version 0.2 (Menu, Réglages, IA multi-fournisseurs)

## Nouveautés de cette version
- Écran d'accueil avec 3 boutons rapides : Analyser un graphique / Demander un signal / Discuter avec [IA active]
- Menu latéral (☰) : Connexion MT4/MT5 (placeholder), Graphiques (placeholder), Modèles IA, Réglages
- Écran "Modèles IA" : ajoute ta propre clé API pour Claude, ChatGPT ou Gemini, choisis laquelle est active
- Écran "Réglages" : couleur d'accent + fond d'écran personnalisé
- L'app appelle maintenant l'IA CHOISIE DIRECTEMENT depuis le téléphone, avec TA clé API
  (plus besoin d'attendre un backend pour cette partie précise)

## Important : sécurité des clés API
Les clés sont stockées sur le téléphone via SharedPreferences (stockage simple, pas
un coffre-fort chiffré). Suffisant pour un usage personnel et les tests. On pourra
migrer vers flutter_secure_storage plus tard si besoin d'un niveau de sécurité supérieur.

## Comment mettre à jour ton projet sur GitHub
1. Ouvre ton dépôt GitHub `manuforex_ai_app`
2. Pour CHAQUE fichier modifié ou ajouté ci-dessous, ouvre-le sur GitHub (ou crée-le),
   clique sur le crayon ✏️ (ou "Add file" > "Create new file"), colle le nouveau contenu,
   puis "Commit changes"

Fichiers à mettre à jour/ajouter (tous fournis dans le zip) :
- pubspec.yaml (modifié — nouvelle dépendance shared_preferences)
- lib/main.dart (modifié)
- lib/screens/home_screen.dart (NOUVEAU — remplace chat_screen.dart)
- lib/screens/settings_screen.dart (NOUVEAU)
- lib/screens/ai_models_screen.dart (NOUVEAU)
- lib/widgets/app_drawer.dart (NOUVEAU)
- lib/theme/app_settings.dart (NOUVEAU)
- lib/models/ai_provider.dart (NOUVEAU)
- lib/services/api_key_storage.dart (NOUVEAU)
- lib/services/multi_ai_service.dart (NOUVEAU)

Fichier à SUPPRIMER sur GitHub :
- lib/screens/chat_screen.dart (remplacé par home_screen.dart — sinon ça ne casse
  rien de le laisser, mais autant nettoyer)

## Plus simple : tout re-uploader d'un coup
Plutôt que fichier par fichier, tu peux aussi :
1. Sur GitHub, supprime tout le contenu du dossier `lib` (sélectionne, "Delete")
2. Upload à nouveau le dossier `lib` complet depuis ce zip (glisser-déposer comme
   la première fois)
3. Fais pareil pour `pubspec.yaml` (le remplacer)
4. Commit changes

## Ensuite
Retourne sur Codemagic → "Start new build" → télécharge le nouvel APK une fois prêt.

## Après ce build : configure tes clés API dans l'app
1. Ouvre l'app → menu ☰ → "Modèles IA"
2. Colle ta clé API pour l'IA de ton choix (Claude, ChatGPT ou Gemini)
3. Clique "Enregistrer la clé" puis "Utiliser cette IA"
4. Retourne à l'accueil → tu peux maintenant discuter et envoyer des images de graphiques
