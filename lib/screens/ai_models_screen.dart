import 'package:flutter/material.dart';
import '../models/ai_provider.dart';
import '../services/api_key_storage.dart';
import '../theme/app_locale.dart';

class AiModelsScreen extends StatefulWidget {
  const AiModelsScreen({super.key});

  @override
  State<AiModelsScreen> createState() => _AiModelsScreenState();
}

class _AiModelsScreenState extends State<AiModelsScreen> {
  AiProviderId? _activeProvider;
  final Map<AiProviderId, String?> _savedKeys = {};
  final Map<AiProviderId, TextEditingController> _controllers = {
    for (final p in AiProviderId.values) p: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = await ApiKeyStorage.getActiveProvider();
    for (final p in AiProviderId.values) {
      final key = await ApiKeyStorage.getApiKey(p);
      _savedKeys[p] = key;
      if (key != null) _controllers[p]!.text = key;
    }
    setState(() => _activeProvider = active);
  }

  Future<void> _saveKey(AiProviderId provider) async {
    final value = _controllers[provider]!.text.trim();
    if (value.isEmpty) {
      await ApiKeyStorage.removeApiKey(provider);
    } else {
      await ApiKeyStorage.saveApiKey(provider, value);
    }
    setState(() => _savedKeys[provider] = value.isEmpty ? null : value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${provider.name} - ${AppStrings.t('key_saved')}')),
      );
    }
  }

  Future<void> _setActive(AiProviderId provider) async {
    if (_savedKeys[provider] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t('add_key_first'))),
      );
      return;
    }
    await ApiKeyStorage.setActiveProvider(provider);
    setState(() => _activeProvider = provider);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLocale.instance,
      builder: (context, _) {
        final t = AppStrings.t;
        return Scaffold(
          backgroundColor: const Color(0xFF0B0E14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B0E14),
            title: Text(t('ai_models')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(t('ai_models_intro'), style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 20),
              for (final provider in AiProvider.all) _buildProviderCard(provider, t),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderCard(AiProvider provider, String Function(String) t) {
    final isActive = _activeProvider == provider.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2A),
        borderRadius: BorderRadius.circular(14),
        border: isActive ? Border.all(color: const Color(0xFF2962FF), width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  provider.displayName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (isActive)
                Chip(
                  label: Text(t('active'), style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFF2962FF),
                  labelStyle: const TextStyle(color: Colors.white),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controllers[provider.id],
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: provider.hint,
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF0B0E14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () => _saveKey(provider.id),
                child: Text(t('save_key')),
              ),
              const Spacer(),
              if (!isActive)
                ElevatedButton(
                  onPressed: () => _setActive(provider.id),
                  child: Text(t('use_this_ai')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
