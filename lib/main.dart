import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'services/cache_manager.dart';
import 'services/cache_manager.dart';
import 'firebase_options.dart';
import 'providers/sepet_provider.dart';
import 'providers/kullanici_provider.dart';
import 'providers/kurumsal_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/magazalar_screen.dart' show magazalarRouteObserver;
import 'services/siparis_bildirim_servisi.dart';
import 'services/pasta_siparis_servisi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase hatası: $e');
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Flutter bellek cache — 150 görsel, 100MB
  PaintingBinding.instance.imageCache.maximumSize      = 150;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB

  // Disk cache başlat — singleton'lar ilk erişimde oluşturulur
  // Ürün görselleri: 7 gün | Mağaza logoları: 30 gün
  ProductImageCacheManager();
  StoreLogoCacheManager();

  runApp(const HataySepetimApp());

  try {
    await SiparisBildirimServisi.instance.init();
  } catch (e) {
    debugPrint('Bildirim servisi hatası: $e');
  }

  try {
    await PastaSiparisServisi.sessionYukle();
  } catch (e) {
    debugPrint('Pasta session yükleme hatası: $e');
  }
}

class HataySepetimApp extends StatelessWidget {
  const HataySepetimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SepetProvider()),
        ChangeNotifierProvider(create: (_) => KullaniciProvider()),
        ChangeNotifierProvider(create: (_) => KurumsalProvider()),
      ],
      child: MaterialApp(
        title: 'HataySepetim',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF8C00),
            primary: const Color(0xFFFF8C00),
          ),
          fontFamily: 'SF Pro Display',
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF8F8F8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Color(0xFF1D1D1F)),
            titleTextStyle: TextStyle(
              color: Color(0xFF1D1D1F),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        navigatorObservers: [magazalarRouteObserver],
        home: const SplashScreen(),
      ),
    );
  }
}
