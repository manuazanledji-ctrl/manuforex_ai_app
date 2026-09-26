import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ai_provider.dart';
import '../models/chat_message.dart';
import '../services/api_key_storage.dart';
import '../services/multi_ai_service.dart';
import '../theme/app_settings.dart';
import '../theme/app_locale.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _pendingImage;
  bool _isSending = false;
  AiProviderId _activeProvider = AiProviderId.claude;

  @override
  void initState() {
    super.initState();
    _loadActiveProvider();
  }

  Future<void> _loadActiveProvider() async {
    final active = await ApiKeyStorage.getActiveProvider();
    setState(() => _activeProvider = active);
  }

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

  Future<void> _sendMessage({String? presetText}) async {
    final text = presetText ?? _textController.text.trim();
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

    final response = await MultiAiService.ask(question: text, image: image);

    setState(() {
      _messages.removeLast();
      _messages.add(ChatMessage(text: response, sender: Sender.ai));
      _isSending = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppSettings.instance, AppLocale.instance]),
      builder: (context, _) {
        final settings = AppSettings.instance;
        final t = AppStrings.t;
        return Scaffold(
          drawer: const AppDrawer(),
          backgroundColor: const Color(0xFF0B0E14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B0E14),
            title: Text(t('app_title')),
          ),
          body: Stack(
            children: [
              if (settings.hasValidWallpaper)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.25,
                    child: Image.file(File(settings.wallpaperPath!), fit: BoxFit.cover),
                  ),
                ),
              Column(
                children: [
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState(t)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
                          ),
                  ),
                  if (_pendingImage != null) _buildImagePreview(t),
                  _buildInputBar(settings.accentColor, t),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String Function(String) t) {
    final providerName = AiProvider.byId(_activeProvider).displayName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('where_to_start'),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _quickButton(
              icon: Icons.smart_toy_outlined,
              label: t('create_robot'),
              onTap: () {
                _textController.text = t('create_robot_prompt');
                _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
                _inputFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 12),
            _quickButton(
              icon: Icons.show_chart,
              label: t('predict_signal'),
              onTap: () {
                _textController.text = t('predict_signal_prompt');
                _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
                _inputFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 12),
            _quickButton(
              icon: Icons.school_outlined,
              label: t('cheatcodes'),
              onTap: () => _sendMessage(presetText: t('cheatcodes_prompt')),
            ),
            const SizedBox(height: 12),
            _quickButton(
              icon: Icons.chat_bubble_outline,
              label: '${t('chat_with')} $providerName',
              onTap: () => _inputFocusNode.requestFocus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFF1B1F2A),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String Function(String) t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF1B1F2A), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_pendingImage!, width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(t('image_ready'), style: const TextStyle(color: Colors.white70))),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => setState(() => _pendingImage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(Color accentColor, String Function(String) t) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1F2A),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_camera_outlined),
              onPressed: () => _pickImage(ImageSource.camera),
              tooltip: t('take_photo'),
            ),
            IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () => _pickImage(ImageSource.gallery),
              tooltip: t('choose_gallery'),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: t('write_to_assistant'),
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.send_rounded, color: accentColor),
              onPressed: _isSending ? null : () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}
