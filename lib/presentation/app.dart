import 'package:flutter/material.dart';

import '../domain/meeting_repository.dart';
import 'leaderboard_screen.dart';

const background = Color(0xFF101113);
const panel = Color(0xFF191A1E);
const muted = Color(0xFFACADB6);
const accent = Color(0xFFFF3B30);
const divider = Color(0xFF303137);

class InnoFormulaApp extends StatelessWidget {
  const InnoFormulaApp({super.key, required this.repository});
  final MeetingRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'InnoFormula — посещаемость клуба',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: panel,
        onSurface: Color(0xFFF5F5F7),
      ),
      fontFamily: 'GolosText',
      useMaterial3: true,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    ),
    home: LeaderboardScreen(repository: repository),
  );
}
