import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const ManuForexApp());
}

class ManuForexApp extends StatelessWidget {
  const ManuForexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ManuForex AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2962FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
      ),
      home: const ChatScreen(),
    );
  }
}
