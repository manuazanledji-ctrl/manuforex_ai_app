import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_settings.dart';
import '../theme/app_locale.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickWallpaper() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      await AppSettings.instance.setWallpaper(picked.path);
      setState(() {});
    }
  }

  Future<void> _removeWallpaper() async {
    await AppSettings.instance.setWallpaper(null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppSettings.instance, AppLocale.instance]),
      builder: (context, _) {
        final settings = AppSettings.instance;
        final t = AppStrings.t;
        return Scaffold(
          backgroundColor: const Color(0xFF0B0E14),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B0E14),
            title: Text(t('settings')),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(t('accent_color'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: AppSettings.availableColors.map((color) {
                  final isSelected = settings.accentColor.value == color.value;
                  return GestureDetector(
                    onTap: () => settings.setAccentColor(color),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Text(t('wallpaper'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (settings.hasValidWallpaper) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(settings.wallpaperPath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickWallpaper,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(settings.hasValidWallpaper ? t('change') : t('choose_image')),
                  ),
                  if (settings.hasValidWallpaper) ...[
                    const SizedBox(width: 12),
                    TextButton(onPressed: _removeWallpaper, child: Text(t('remove'))),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(t('wallpaper_hint'), style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 32),
              Text(t('language'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _languageOption(AppLanguage.fr, t('french')),
              const SizedBox(height: 8),
              _languageOption(AppLanguage.en, t('english')),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(AppLanguage lang, String label) {
    final isSelected = AppLocale.instance.language == lang;
    return GestureDetector(
      onTap: () => AppLocale.instance.setLanguage(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1F2A),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppSettings.instance.accentColor, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppSettings.instance.accentColor : Colors.white38,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
