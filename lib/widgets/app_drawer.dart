import 'package:flutter/material.dart';
import '../screens/ai_models_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/charts_screen.dart';
import '../theme/app_locale.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature : ${AppStrings.t('coming_soon')}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.t;
    return AnimatedBuilder(
      animation: AppLocale.instance,
      builder: (context, _) {
        return Drawer(
          backgroundColor: AppColors.bg,
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppColors.bg),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      t('app_title'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.link, color: AppColors.textSecondary),
                  title: Text(t('mt4_mt5_connection'), style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () => _showComingSoon(context, t('mt4_mt5_connection')),
                ),
                ListTile(
                  leading: const Icon(Icons.show_chart, color: AppColors.textSecondary),
                  title: Text(t('charts'), style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChartsScreen()));
                  },
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined, color: AppColors.textSecondary),
                  title: Text(t('ai_models'), style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiModelsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                  title: Text(t('settings'), style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
