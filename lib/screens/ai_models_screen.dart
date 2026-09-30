import 'package:flutter/material.dart';
import '../models/ai_provider.dart';
import '../services/api_key_storage.dart';
import '../services/market_data_key_storage.dart';
import '../theme/app_settings.dart';
import '../theme/app_locale.dart';
import '../theme/app_colors.dart';

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
  final TextEditingController _twelveDataController = TextEditingController();
  String? _savedTwelveDataKey;

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
    final twelveDataKey = await MarketDataKeyStorage.getApiKey();
    _savedTwelveDataKey = twelveDataKey;
    if (twelveDataKey != null) _twelveDataController.text = twelveDataKey;
    setState(() => _activeProvider = active);
  }

  Future<void> _saveTwelveDataKey() async {
    final value = _twelveDataController.text.trim();
    if (value.isEmpty) {
      await MarketDataKeyStorage.removeApiKey();
    } else {
      await MarketDataKeyStorage.saveApiKey(value);
    }
    setState(() => _savedTwelveDataKey = value.isEmpty ? null : value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Twelve Data - ${AppStrings.t('key_saved')}')),
      );
    }
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
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            foregroundColor: AppColors.textPrimary,
            title: Text(t('ai_models')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(t('ai_models_intro'), style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 20),
              for (final provider in AiProvider.all) _buildProviderCard(provider, t),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border),
              const SizedBox(height: 12),
              const Text(
                'Données de marché (Twelve Data)',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                "Nécessaire pour que le bouton \"Prédire un signal\" utilise des prix réels "
                "plutôt que la mémoire générale de l'IA. Clé gratuite sur twelvedata.com.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _twelveDataController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Clé API Twelve Data',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton(onPressed: _saveTwelveDataKey, child: Text(t('save_key'))),
                        const Spacer(),
                        if (_savedTwelveDataKey != null)
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActive ? AppSettings.instance.accentColor : AppColors.border, width: isActive ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  provider.displayName,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (isActive)
                Chip(
                  label: Text(t('active'), style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppSettings.instance.accentColor,
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
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: provider.hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bg,
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
