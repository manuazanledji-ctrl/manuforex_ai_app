import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_settings.dart';
import 'theme/app_locale.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ManuForexApp());
}

class ManuForexApp extends StatefulWidget {
  const ManuForexApp({super.key});

  @override
  State<ManuForexApp> createState() => _ManuForexAppState();
}

class _ManuForexAppState extends State<ManuForexApp> {
  @override
  void initState() {
    super.initState();
    AppSettings.instance.load();
    AppLocale.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppSettings.instance, AppLocale.instance]),
      builder: (context, _) {
        return MaterialApp(
          title: 'No_Loss AI by ManuForex',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppSettings.instance.accentColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0B0E14),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
