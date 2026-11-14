import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'services/app_session.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    runApp(const SupabaseSetupApp());
    return;
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  await AppSession.instance.initialize();

  runApp(const MonochromeApp());
}

class MonochromeApp extends StatelessWidget {
  const MonochromeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MONOCHROME',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFFFFF),
          secondary: Color(0xFFDFFF00),
          surface: Color(0xFF171717),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class SupabaseSetupApp extends StatelessWidget {
  const SupabaseSetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'SUPABASE SETUP REQUIRED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFDFFF00),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Isi Project URL dan Publishable Key di '
                  'lib/config/supabase_config.dart, lalu jalankan ulang aplikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
