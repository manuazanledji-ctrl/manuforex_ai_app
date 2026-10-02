import 'package:flutter/material.dart';
import '../services/metaapi_key_storage.dart';
import '../services/metaapi_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class Mt5ConnectionScreen extends StatefulWidget {
  const Mt5ConnectionScreen({super.key});

  @override
  State<Mt5ConnectionScreen> createState() => _Mt5ConnectionScreenState();
}

class _Mt5ConnectionScreenState extends State<Mt5ConnectionScreen> {
  final _tokenController = TextEditingController();
  final _accountIdController = TextEditingController();
  bool _isTesting = false;
  MetaApiAccountInfo? _lastResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await MetaApiKeyStorage.getToken();
    final accountId = await MetaApiKeyStorage.getAccountId();
    if (token != null) _tokenController.text = token;
    if (accountId != null) _accountIdController.text = accountId;
  }

  Future<void> _saveAndTest() async {
    if (_tokenController.text.trim().isEmpty || _accountIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseigne le token ET l\'ID de compte avant de tester')),
      );
      return;
    }
    await MetaApiKeyStorage.saveToken(_tokenController.text);
    await MetaApiKeyStorage.saveAccountId(_accountIdController.text);

    setState(() {
      _isTesting = true;
      _lastResult = null;
    });

    final result = await MetaApiService.fetchAccountInfo();

    setState(() {
      _lastResult = result;
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Connexion MT4 / MT5'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Connecte ton compte MT4/MT5 via MetaApi. Récupère le token et l'ID de compte "
            "depuis app.metaapi.cloud.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text('Token MetaApi', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _tokenController,
            obscureText: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'eyJhbGciOi...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('ID du compte MetaApi', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _accountIdController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'a1db3a4d-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTesting ? null : _saveAndTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppSettings.instance.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isTesting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer et tester la connexion', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          if (_lastResult != null) _buildResult(_lastResult!),
        ],
      ),
    );
  }

  Widget _buildResult(MetaApiAccountInfo result) {
    if (!result.success) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEF9A9A)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFC62828)),
            const SizedBox(width: 10),
            Expanded(child: Text(result.error!, style: const TextStyle(color: Color(0xFFC62828)))),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Connecté avec succès', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Broker', result.broker ?? '-'),
          _infoRow('Solde', '${result.balance} ${result.currency ?? ''}'),
          _infoRow('Equity', '${result.equity} ${result.currency ?? ''}'),
          _infoRow('Levier', '1:${result.leverage}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Color(0xFF2E7D32)))),
          Text(value, style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
