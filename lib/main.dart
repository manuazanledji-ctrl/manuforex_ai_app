import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_settings.dart';
import 'theme/app_locale.dart';
import 'theme/app_colors.dart';

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
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // On attend que TOUT soit chargé depuis le stockage local (prénom, langue,
    // couleur, fond d'écran) avant d'afficher le premier écran — sinon l'app
    // peut croire à tort qu'aucun prénom n'a été enregistré et le redemander.
    _initFuture = Future.wait([
      AppSettings.instance.load(),
      AppLocale.instance.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(backgroundColor: AppColors.bg),
          );
        }
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
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: AppColors.bg,
              ),
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
