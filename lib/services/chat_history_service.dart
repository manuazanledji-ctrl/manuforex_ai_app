import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

/// Sauvegarde et recharge l'historique de chaque fil de discussion sur le
/// téléphone, pour qu'il survive à la fermeture de l'app — comme WhatsApp
/// ou Telegram. Les images envoyées sont copiées dans un dossier permanent
/// de l'app.
class ChatHistoryService {
  static const _keyPrefix = 'chat_history_';

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

  static Future<void> saveThread(String key, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final serializable = messages
        .where((m) => !m.isLoading)
        .map((m) => {
              'text': m.text,
              'imagePath': m.image?.path,
              'sender': m.sender.name,
              'timestamp': m.timestamp.toIso8601String(),
            })
        .toList();
    await prefs.setString('$_keyPrefix$key', jsonEncode(serializable));
  }

  static Future<List<ChatMessage>> loadThread(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$key');
    if (raw == null) return [];

    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((entry) {
        final imagePath = entry['imagePath'] as String?;
        final image = (imagePath != null && File(imagePath).existsSync()) ? File(imagePath) : null;
        final timestampRaw = entry['timestamp'] as String?;
        return ChatMessage(
          text: entry['text'] as String?,
          image: image,
          sender: entry['sender'] == 'user' ? Sender.user : Sender.ai,
          timestamp: timestampRaw != null ? DateTime.tryParse(timestampRaw) : null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
