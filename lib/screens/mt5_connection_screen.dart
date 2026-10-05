import 'package:flutter/material.dart';
import '../services/mt5_backend_service.dart';
import 'symbol_settings_list_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_settings.dart';

class Mt5ConnectionScreen extends StatefulWidget {
  const Mt5ConnectionScreen({super.key});

  @override
  State<Mt5ConnectionScreen> createState() => _Mt5ConnectionScreenState();
}

class _Mt5ConnectionScreenState extends State<Mt5ConnectionScreen> {
  String _platform = 'mt5';
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _accountInfo;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final saved = await Mt5BackendService.loadLocal();
    if (saved['accountId'] != null) {
      _loginController.text = saved['login'] ?? '';
      _serverController.text = saved['server'] ?? '';
      _platform = saved['platform'] ?? 'mt5';
      setState(() {});
      _refreshAccountInfo(saved['accountId']!);
    }
  }

  Future<void> _refreshAccountInfo(String accountId) async {
    final info = await Mt5BackendService.fetchAccountInfo(accountId);
    if (mounted && info != null) {
      setState(() => _accountInfo = info);
    }
  }

  Future<void> _connect() async {
    if (_loginController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _serverController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Remplis Login, Mot de passe et Serveur.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _accountInfo = null;
    });

    final error = await Mt5BackendService.provisionAndSave(
      login: _loginController.text.trim(),
      password: _passwordController.text,
      server: _serverController.text.trim(),
      platform: _platform,
    );

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
      return;
    }

    final saved = await Mt5BackendService.loadLocal();
    await _refreshAccountInfo(saved['accountId']!);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppSettings.instance.accentColor;
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
          // Sélecteur MT5 / MT4
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                Expanded(child: _platformTab('mt5', 'MT5 ACCOUNT', accent)),
                Expanded(child: _platformTab('mt4', 'MT4 ACCOUNT', accent)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                CircleAvatar(radius: 36, backgroundColor: accent, child: const Icon(Icons.person, color: Colors.white, size: 36)),
                const SizedBox(height: 12),
                Text('${_platform.toUpperCase()} LOGIN DETAILS',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                _buildField(
                  controller: _loginController,
                  icon: Icons.person_outline,
                  hint: 'Login',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _passwordController,
                  icon: Icons.key_outlined,
                  hint: 'Password',
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 12),
                _buildField(controller: _serverController, icon: Icons.dns_outlined, hint: 'Server'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                    label: Text(_isLoading ? 'Connexion...' : 'Save $_platformLabel Login',
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) _buildBox(_errorMessage!, isError: true),
          if (_accountInfo != null) _buildAccountInfoBox(),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.tune, color: AppColors.textSecondary),
              title: const Text('Réglages par symbole', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Taille de lot, action, nombre d\'ordres par défaut',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SymbolSettingsListScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _platformLabel => _platform == 'mt5' ? 'MT5' : 'MT4';

  Widget _platformTab(String value, String label, Color accent) {
    final isSelected = _platform == value;
    return GestureDetector(
      onTap: () => setState(() => _platform = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBox(String text, {bool isError = false}) {
    final color = isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    final bg = isError ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);
    final border = isError ? const Color(0xFFEF9A9A) : const Color(0xFFA5D6A7);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  Widget _buildAccountInfoBox() {
    final info = _accountInfo!;
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
          const SizedBox(height: 10),
          Text('Broker: ${info['broker'] ?? '-'}', style: const TextStyle(color: Color(0xFF1B5E20))),
          Text('Solde: ${info['balance']} ${info['currency'] ?? ''}', style: const TextStyle(color: Color(0xFF1B5E20))),
          Text('Equity: ${info['equity']} ${info['currency'] ?? ''}', style: const TextStyle(color: Color(0xFF1B5E20))),
        ],
      ),
    );
  }
}
