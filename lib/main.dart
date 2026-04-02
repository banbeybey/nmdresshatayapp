import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/sepet_provider.dart';
import 'providers/kullanici_provider.dart';
import 'providers/urun_provider.dart';
import 'screens/splash_screen.dart';
import 'services/bildirim_servisi.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('🔴 FLUTTER HATA: ${details.exception}');
    debugPrint('🔴 STACK: ${details.stack}');
    FlutterError.presentError(details);
  };

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint('✅ Firebase başlatıldı');
    } catch (e) {
      debugPrint('🔴 Firebase başlatma hatası: $e');
    }

    try {
      await BildirimServisi.baslat();
      debugPrint('✅ BildirimServisi başlatıldı');
    } catch (e) {
      debugPrint('🔴 BildirimServisi hatası: $e');
    }

    runApp(const NMDressApp());
  }, (error, stack) {
    debugPrint('🔴 ZONE HATA: $error');
    debugPrint('🔴 STACK: $stack');
  });
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
