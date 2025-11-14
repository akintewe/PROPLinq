import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/onesignal_service.dart';
import 'features/splash/views/second_splash_view.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize OneSignal
  await OneSignalService().initialize();
  
  runApp(const PropLinqApp());
}

class PropLinqApp extends StatelessWidget {
  const PropLinqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const SecondSplashView(),
    );
  }
}
