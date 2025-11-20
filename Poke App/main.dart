import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scanner_screen.dart';
import 'supabase_service.dart';
import 'auth_screen.dart';
import 'collection_screen.dart';

// ⚠️ WICHTIG: Ersetze diese Werte mit deinen echten Supabase Credentials
const String SUPABASE_URL = 'https://DEIN-PROJECT.supabase.co';
const String SUPABASE_ANON_KEY = 'DEIN-ANON-KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase initialisieren
  await SupabaseService.initialize(
    supabaseUrl: SUPABASE_URL,
    supabaseAnonKey: SUPABASE_ANON_KEY,
  );
  
  // Portrait-Modus erzwingen
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Status-Bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const PokemonCardScannerApp());
}

class PokemonCardScannerApp extends StatelessWidget {
  const PokemonCardScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Card Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4A90E2),
          secondary: const Color(0xFF9B59B6),
          background: const Color(0xFF0A0E1A),
          surface: const Color(0xFF1A1F3A),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1F3A),
              const Color(0xFF0A0E1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo / Titel
                const SizedBox(height: 40),
                const Text(
                  'Pokémon Card',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'Scanner',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4A90E2),
                    letterSpacing: -1,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Erkenne und bewerte deine Karten sofort',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                
                const Spacer(),
                
                // Features
                _FeatureItem(
                  icon: Icons.camera_alt,
                  title: 'Schnelles Scannen',
                  description: 'OCR-basierte Erkennung in Echtzeit',
                ),
                
                const SizedBox(height: 20),
                
                _FeatureItem(
                  icon: Icons.collections,
                  title: 'Riesige Datenbank',
                  description: 'Zugriff auf über 15.000 Karten',
                ),
                
                const SizedBox(height: 20),
                
                _FeatureItem(
                  icon: Icons.offline_bolt,
                  title: 'Offline-fähig',
                  description: 'Text-Erkennung funktioniert ohne Internet',
                ),
                
                const Spacer(),
                
                // Scan-Button
                SizedBox(
                  width: double.infinity,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannerScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF4A90E2).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Karte scannen',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4A90E2),
            size: 30,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}