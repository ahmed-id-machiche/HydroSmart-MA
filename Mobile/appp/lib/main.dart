import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'constants/app_colors.dart';
import 'language/app_language.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const HydroSmartApp());
}

class HydroSmartApp extends StatelessWidget {
  const HydroSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLanguageController,
      builder: (context, _) {
        return MaterialApp(
          title: 'HydroSmart-MA',
          debugShowCheckedModeBanner: false,
          locale: appLanguageController.locale,
          builder: (context, child) {
            return Directionality(
              textDirection: appLanguageController.textDirection,
              child: child ?? const SizedBox(),
            );
          },
          theme: ThemeData(
            scaffoldBackgroundColor: lightBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryGreen,
              primary: primaryGreen,
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}