import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/sepet_provider.dart';
import 'providers/kullanici_provider.dart';
import 'providers/urun_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // BildirimServisi artık splash_screen.dart içinde çağrılıyor
  runApp(const NMDressApp());
}

class NMDressApp extends StatelessWidget {
  const NMDressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KullaniciProvider()),
        ChangeNotifierProvider(create: (_) => SepetProvider()),
        ChangeNotifierProvider(create: (_) => UrunProvider()),
      ],
      child: MaterialApp(
        title: 'NM Dress',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B1A4A),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F4F6),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1A1A1A),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
