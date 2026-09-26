import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglages d'apparence partagés dans toute l'app : couleur d'accent et
/// fond d'écran personnalisé. Persistés sur le téléphone via SharedPreferences.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const List<Color> availableColors = [
    Color(0xFF2962FF), // bleu (par défaut)
    Color(0xFF00C853), // vert
    Color(0xFFFF6D00), // orange
    Color(0xFFD500F9), // violet
    Color(0xFFFF1744), // rouge
    Color(0xFF00B8D4), // cyan
  ];

  Color accentColor = availableColors.first;
  String? wallpaperPath; // chemin local de l'image choisie par l'utilisateur

  static const _colorKey = 'settings_accent_color';
  static const _wallpaperKey = 'settings_wallpaper_path';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_colorKey);
    if (colorValue != null) {
      accentColor = Color(colorValue);
    }
    wallpaperPath = prefs.getString(_wallpaperKey);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
  }

  Future<void> setWallpaper(String? path) async {
    wallpaperPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_wallpaperKey);
    } else {
      await prefs.setString(_wallpaperKey, path);
    }
  }

  bool get hasValidWallpaper => wallpaperPath != null && File(wallpaperPath!).existsSync();
}
