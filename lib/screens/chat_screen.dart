import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';
import '../services/ai_analysis_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _pendingImage;
  bool _isSending = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _pendingImage = File(picked.path));
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    if (_isSending) return;

    final image = _pendingImage;
    setState(() {
      _messages.add(ChatMessage(text: text.isEmpty ? null : text, image: image, sender: Sender.user));
      _messages.add(ChatMessage(sender: Sender.ai, isLoading: true));
      _pendingImage = null;
      _textController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    String response;
    if (image != null) {
      response = await AiAnalysisService.analyzeChartImage(image, userQuestion: text);
    } else {
      response = await AiAnalysisService.askMarketQuestion(text);
    }

    setState(() {
      _messages.removeLast(); // retire la bulle "loading"
      _messages.add(ChatMessage(text: response, sender: Sender.ai));
      _isSending = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        title: const Text('ManuForex AI'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
                  ),
          ),
          if (_pendingImage != null) _buildImagePreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          "Envoie une image de graphique ou pose une question sur un marché\n"
          "(ex: \"Analyse-moi US30\").",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_pendingImage!, width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Image prête à envoyer', style: TextStyle(color: Colors.white70))),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => setState(() => _pendingImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Color(0xFF0B0E14),
          border: Border(top: BorderSide(color: Color(0xFF1B1F2A))),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: () => _pickImage(ImageSource.camera),
              tooltip: 'Prendre une photo',
            ),
            IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => _pickImage(ImageSource.gallery),
              tooltip: 'Choisir depuis la galerie',
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Écris à ton assistant...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Color(0xFF2962FF)),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
