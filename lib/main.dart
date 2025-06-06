import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'features/splash/views/splash_view.dart';

void main() {
  runApp(const PropLinqApp());
}

class PropLinqApp extends StatelessWidget {
  const PropLinqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      home: const SplashView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
