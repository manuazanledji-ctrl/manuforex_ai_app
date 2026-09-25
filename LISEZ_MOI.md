# ManuForex AI — Version 0.1 (Étape 1 : Interface + Chat)

## Ce que fait cette version
- Interface de chat façon "Ask ALGO"
- Bouton caméra + bouton galerie pour envoyer une image de graphique
- Envoi de texte/image vers un backend (PAS ENCORE CONSTRUIT — voir plus bas)

## Ce qui manque encore (prochaines étapes)
1. Le **backend** (serveur intermédiaire) qui reçoit l'image/question et interroge l'IA
   → tant qu'il n'existe pas, l'app affichera un message d'erreur de connexion, c'est normal
2. La connexion Twelve Data (données de marché)
3. La connexion MetaApi (exécution des ordres MT4/MT5)

## Comment compiler l'APK avec Codemagic

1. Va sur https://codemagic.io et crée un compte gratuit
2. Choisis "Upload files" (pas besoin de GitHub pour commencer) et uploade
   ce dossier entier en .zip
3. Codemagic détectera automatiquement le fichier `codemagic.yaml` inclus
4. Lance le build ("Start new build") avec le workflow "android-apk"
5. Une fois terminé, télécharge le fichier `.apk` généré et installe-le sur ton téléphone
   (il faudra peut-être autoriser "sources inconnues" dans les paramètres Android)

## Fichier clé à modifier plus tard
`lib/services/ai_analysis_service.dart` — la ligne `backendBaseUrl` devra être
remplacée par l'adresse réelle de ton serveur une fois qu'on l'aura construit ensemble.
