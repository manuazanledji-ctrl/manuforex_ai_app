import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ai_provider.dart';
import '../models/chat_message.dart';
import '../services/api_key_storage.dart';
import '../services/multi_ai_service.dart';
import '../services/market_data_service.dart';
import '../services/chat_history_service.dart';
import '../theme/app_settings.dart';
import '../theme/app_locale.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Un fil de discussion distinct par bouton d'accueil, pour que l'historique
  // de chacun soit conservé séparément tant que l'app reste ouverte.
  final Map<String, List<ChatMessage>> _threads = {
    'robot': [],
    'signal': [],
    'cheatcodes': [],
    'chat': [],
  };
  String? _currentThread; // null = écran d'accueil (boutons)

  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  File? _pendingImage;
  bool _isSending = false;
  AiProviderId _activeProvider = AiProviderId.claude;

  List<ChatMessage> get _activeMessages => _currentThread == null ? const [] : _threads[_currentThread]!;

  @override
  void initState() {
    super.initState();
    _loadActiveProvider();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskName());
  }

  Future<void> _loadHistory() async {
    for (final key in _threads.keys) {
      final saved = await ChatHistoryService.loadThread(key);
      if (saved.isNotEmpty && mounted) {
        setState(() => _threads[key] = saved);
      }
    }
  }

  Future<void> _loadActiveProvider() async {
    final active = await ApiKeyStorage.getActiveProvider();
    setState(() => _activeProvider = active);
  }

  Future<void> _maybeAskName() async {
    if (AppSettings.instance.userName != null) return;
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(AppStrings.t('name_prompt_title'), style: const TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: AppStrings.t('name_prompt_hint'),
              hintStyle: const TextStyle(color: AppColors.textMuted),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            ),
            onSubmitted: (_) => _confirmName(controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () => _confirmName(controller.text),
              child: Text(AppStrings.t('name_prompt_confirm')),
            ),
          ],
        );
      },
    );
  }

  void _confirmName(String value) {
    if (value.trim().isEmpty) return;
    AppSettings.instance.setUserName(value.trim());
    Navigator.of(context).pop();
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

  void _openThread(String thread) {
    setState(() => _currentThread = thread);
  }

  Future<void> _showSymbolPickerAndPredict() async {
    final symbol = await showModalBottomSheet<TradedSymbol>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      builder: (context) => const _SymbolSearchSheet(),
    );
    if (symbol == null) return;
    _openThread('signal');
    await _sendPredictSignal(symbol);
  }

  Future<void> _sendPredictSignal(TradedSymbol symbol, {String? displayText, String? userQuestion}) async {
    if (_isSending) return;
    final thread = _threads['signal']!;

    setState(() {
      thread.add(ChatMessage(text: displayText ?? 'Analyse-moi ${symbol.label}', sender: Sender.user));
      thread.add(ChatMessage(
        text: 'Récupération des données H4/H1/M15/M5 (Twelve Data)...',
        sender: Sender.ai,
        isLoading: true,
      ));
      _isSending = true;
    });
    ChatHistoryService.saveThread('signal', thread);
    _scrollToBottom();

    final dataSummary = await MarketDataService.fetchSummary(symbol);

    if (mounted) {
      setState(() {
        thread[thread.length - 1] = ChatMessage(
          text: 'Données reçues. Analyse en cours par l\'IA...',
          sender: Sender.ai,
          isLoading: true,
        );
      });
      _scrollToBottom();
    }

    final response = await MultiAiService.askPredictSignal(
      symbolLabel: symbol.label,
      marketDataSummary: dataSummary,
      userQuestion: userQuestion,
    );

    setState(() {
      thread.removeLast();
      thread.add(ChatMessage(text: response, sender: Sender.ai));
      _isSending = false;
    });
    ChatHistoryService.saveThread('signal', thread);
    _scrollToBottom();
  }

  Future<void> _sendMessage({String? presetText, bool useWebSearch = false, String? forceThread}) async {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty && _pendingImage == null) return;
    if (_isSending) return;

    // Détection d'un marché connu en texte libre -> route vers le fil
    // "Prédire un signal" avec de vraies données, peu importe d'où on tape.
    if (_pendingImage == null && !useWebSearch) {
      final matchedSymbol = MarketDataService.matchKeyword(text);
      if (matchedSymbol != null) {
        _textController.clear();
        _openThread('signal');
        await _sendPredictSignal(matchedSymbol, displayText: text, userQuestion: text);
        return;
      }
    }

    final threadKey = forceThread ?? _currentThread ?? 'chat';
    if (_currentThread != threadKey) {
      setState(() => _currentThread = threadKey);
    }
    final thread = _threads[threadKey]!;
    // Dans le fil Cheatcodes, chaque message bénéficie automatiquement de la
    // recherche web réelle — plus besoin d'un prompt pré-écrit pour ça.
    final effectiveWebSearch = useWebSearch || threadKey == 'cheatcodes';

    // Copie l'image vers un emplacement permanent AVANT de l'attacher au
    // message, pour qu'elle reste accessible après redémarrage de l'app.
    File? image = _pendingImage;
    if (image != null) {
      image = await ChatHistoryService.savePermanentCopy(image);
    }

    setState(() {
      thread.add(ChatMessage(text: text.isEmpty ? null : text, image: image, sender: Sender.user));
      thread.add(ChatMessage(sender: Sender.ai, isLoading: true));
      _pendingImage = null;
      _textController.clear();
      _isSending = true;
    });
    ChatHistoryService.saveThread(threadKey, thread);
    _scrollToBottom();

    final response = effectiveWebSearch
        ? await MultiAiService.askCheatcodes(text)
        : await MultiAiService.ask(question: text, image: image);

    setState(() {
      thread.removeLast();
      thread.add(ChatMessage(text: response, sender: Sender.ai));
      _isSending = false;
    });
    ChatHistoryService.saveThread(threadKey, thread);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppSettings.instance, AppLocale.instance]),
      builder: (context, _) {
        final settings = AppSettings.instance;
        final t = AppStrings.t;
        // Le bouton retour ne ferme l'app QUE depuis l'écran d'accueil. Depuis
        // un fil de discussion, il ramène à l'accueil SANS effacer l'historique
        // de ce fil — il sera toujours là si on rouvre le même bouton.
        return PopScope(
          canPop: _currentThread == null,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            setState(() => _currentThread = null);
          },
          child: Scaffold(
            drawer: const AppDrawer(),
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.bg,
              elevation: 0,
              foregroundColor: AppColors.textPrimary,
              leading: _currentThread != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _currentThread = null),
                    )
                  : null,
              title: Text(t('app_title'), style: const TextStyle(fontSize: 16)),
              actions: [
                if (_currentThread == 'signal')
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Rechercher un autre actif',
                    onPressed: _showSymbolPickerAndPredict,
                  ),
              ],
            ),
            body: Stack(
              children: [
                if (settings.hasValidWallpaper)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.15,
                      child: Image.file(File(settings.wallpaperPath!), fit: BoxFit.cover),
                    ),
                  ),
                Column(
                  children: [
                    Expanded(
                      child: _currentThread == null
                          ? _buildEmptyState(t)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              itemCount: _activeMessages.length,
                              itemBuilder: (context, index) => ChatBubble(message: _activeMessages[index]),
                            ),
                    ),
                    if (_pendingImage != null) _buildImagePreview(t),
                    _buildInputBar(settings.accentColor, t),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String Function(String) t) {
    final providerName = AiProvider.byId(_activeProvider).displayName;
    final name = AppSettings.instance.userName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (name != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${t('greeting_hi')} $name',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
            Text(
              t('where_to_start'),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            _quickButton(
              icon: Icons.smart_toy_outlined,
              label: t('create_robot'),
              onTap: () {
                _openThread('robot');
                _inputFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 12),
            _quickButton(
              icon: Icons.show_chart,
              label: t('predict_signal'),
              onTap: () {
                _openThread('signal');
                _inputFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 12),
            _quickButton(
              icon: Icons.school_outlined,
              label: t('cheatcodes'),
              onTap: () {
                _openThread('cheatcodes');
                _inputFocusNode.requestFocus();
              },
            ),
            const SizedBox(height: 12),
            _quickButton(
              icon: Icons.chat_bubble_outline,
              label: '${t('chat_with')} $providerName',
              onTap: () {
                _openThread('chat');
                _inputFocusNode.requestFocus();
              },
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppSettings.instance.accentColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
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
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_pendingImage!, width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(t('image_ready'), style: const TextStyle(color: AppColors.textSecondary))),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMuted),
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.photo_camera_outlined, color: AppColors.textSecondary),
              onPressed: () => _pickImage(ImageSource.camera),
              tooltip: t('take_photo'),
            ),
            IconButton(
              icon: Icon(Icons.photo_library_outlined, color: AppColors.textSecondary),
              onPressed: () => _pickImage(ImageSource.gallery),
              tooltip: t('choose_gallery'),
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: t('write_to_assistant'),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                onPressed: _isSending ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Feuille de recherche libre parmi tous les actifs Twelve Data (actions,
/// forex, indices, crypto...) — plus de liste fixe limitée.
class _SymbolSearchSheet extends StatefulWidget {
  const _SymbolSearchSheet();

  @override
  State<_SymbolSearchSheet> createState() => _SymbolSearchSheetState();
}

class _SymbolSearchSheetState extends State<_SymbolSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<TwelveDataSearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _runSearch(query));
    setState(() {});
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await MarketDataService.search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Choisis un marché',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Rechercher (ex: AAPL, XAUUSD, BTC/USD)',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                  onChanged: _onChanged,
                ),
              ),
              const SizedBox(height: 8),
              if (_isSearching) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
              Expanded(
                child: _controller.text.isEmpty
                    ? ListView(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Text('Raccourcis', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ),
                          for (final s in TradedSymbol.all)
                            ListTile(
                              title: Text(s.label, style: const TextStyle(color: AppColors.textPrimary)),
                              onTap: () => Navigator.pop(context, s),
                            ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          return ListTile(
                            title: Text(r.symbol, style: const TextStyle(color: AppColors.textPrimary)),
                            subtitle: Text(
                              '${r.name}${r.exchange.isNotEmpty ? " · ${r.exchange}" : ""}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            onTap: () => Navigator.pop(context, r.toTradedSymbol()),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
