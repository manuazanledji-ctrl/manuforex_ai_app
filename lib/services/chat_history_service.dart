import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// Sauvegarde et recharge l'historique de chaque fil de discussion sur le
/// téléphone, pour qu'il survive à la fermeture de l'app — comme WhatsApp
/// ou Telegram. Les images envoyées sont copiées dans un dossier permanent
/// de l'app (le fichier original choisi par l'utilisateur peut, lui,
/// disparaître du cache du téléphone après un moment).
class ChatHistoryService {
  static const _keyPrefix = 'chat_history_';

  /// Copie une image choisie par l'utilisateur vers un emplacement permanent
  /// propre à l'app, et retourne ce nouveau chemin. À appeler AVANT de créer
  /// le ChatMessage, pour que le chemin stocké reste valide après redémarrage.
  static Future<File> savePermanentCopy(File source) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final chatImagesDir = Directory('${docsDir.path}/chat_images');
    if (!await chatImagesDir.exists()) {
      await chatImagesDir.create(recursive: true);
    }
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final newPath = '${chatImagesDir.path}/$fileName';
    return source.copy(newPath);
  }

  /// Sauvegarde un fil de discussion. Les messages "en cours de chargement"
  /// ne sont jamais persistés (ils n'ont pas de sens après un redémarrage).
  static Future<void> saveThread(String key, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final serializable = messages
        .where((m) => !m.isLoading)
        .map((m) => {
              'text': m.text,
              'imagePath': m.image?.path,
              'sender': m.sender.name,
            })
        .toList();
    await prefs.setString('$_keyPrefix$key', jsonEncode(serializable));
  }

  /// Recharge un fil de discussion. Si une image référencée n'existe plus
  /// sur le disque (cas rare), le message texte est quand même conservé.
  static Future<List<ChatMessage>> loadThread(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$key');
    if (raw == null) return [];

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((entry) {
        final imagePath = entry['imagePath'] as String?;
        final image = (imagePath != null && File(imagePath).existsSync()) ? File(imagePath) : null;
        return ChatMessage(
          text: entry['text'] as String?,
          image: image,
          sender: entry['sender'] == 'user' ? Sender.user : Sender.ai,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
