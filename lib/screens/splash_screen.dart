import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ana_sayfa.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Logo
  late AnimationController _logoCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Loading bar
  late AnimationController _barCtrl;
  late Animation<double> _barProgress;

  // Shimmer (bar)
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerPos;

  // 3 nokta
  late AnimationController _dot1Ctrl;
  late AnimationController _dot2Ctrl;
  late AnimationController _dot3Ctrl;

  // Alt bölüm
  late AnimationController _bottomFadeCtrl;
  late Animation<double> _bottomFade;

  // Gold renk döngüsü (REYHANLI için)
  late AnimationController _goldCtrl;

  // REYHANLI fade+slide
  late AnimationController _reyhCtrl;
  late Animation<double> _reyhFade;
  late Animation<Offset> _reyhSlide;

  // Nur Özçelik fade+slide
  late AnimationController _nurCtrl;
  late Animation<double> _nurFade;
  late Animation<Offset> _nurSlide;

  // & fade
  late AnimationController _ampCtrl;
  late Animation<double> _ampFade;

  // Merve İkizer fade+slide
  late AnimationController _merveCtrl;
  late Animation<double> _merveFade;
  late Animation<Offset> _merveSlide;

  // İsim gold shimmer
  late AnimationController _nameGoldCtrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // ── Logo ──
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.80, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    // ── Alt bölüm ──
    _bottomFadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bottomFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _bottomFadeCtrl, curve: Curves.easeIn));

    // ── Bar ──
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500));
    _barProgress = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut));

    // ── Bar shimmer ──
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _shimmerPos  = Tween<double>(begin: -0.3, end: 1.3).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // ── 3 nokta ──
    _dot1Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _dot2Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _dot3Ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _dot2Ctrl.repeat(reverse: true); });
    Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _dot3Ctrl.repeat(reverse: true); });

    // ── Gold döngü (REYHANLI) ──
    _goldCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    // ── İsim gold döngü ──
    _nameGoldCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

    // ── REYHANLI — 200ms'de gelsin ──
    _reyhCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _reyhFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _reyhCtrl, curve: Curves.easeOut));
    _reyhSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _reyhCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _reyhCtrl.forward(); });

    // ── Logo — 300ms'de ──
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _logoCtrl.forward().then((_) {
        _bottomFadeCtrl.forward();
        _barCtrl.forward();
      });
    });

    // ── Nur Özçelik — 900ms'de ──
    _nurCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _nurFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _nurCtrl, curve: Curves.easeOut));
    _nurSlide = Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _nurCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 900), () { if (mounted) _nurCtrl.forward(); });

    // ── & — 1200ms'de ──
    _ampCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _ampFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ampCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1200), () { if (mounted) _ampCtrl.forward(); });

    // ── Merve İkizer — 1500ms'de ──
    _merveCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _merveFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _merveCtrl, curve: Curves.easeOut));
    _merveSlide = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _merveCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 1500), () { if (mounted) _merveCtrl.forward(); });

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 5500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AnaSayfa(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _barCtrl.dispose();
    _shimmerCtrl.dispose();
    _dot1Ctrl.dispose();
    _dot2Ctrl.dispose();
    _dot3Ctrl.dispose();
    _bottomFadeCtrl.dispose();
    _goldCtrl.dispose();
    _nameGoldCtrl.dispose();
    _reyhCtrl.dispose();
    _nurCtrl.dispose();
    _ampCtrl.dispose();
    _merveCtrl.dispose();
    super.dispose();
  }

  Widget _buildDot(AnimationController ctrl) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        return Container(
          width: 7 + t * 3,
          height: 7 + t * 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(const Color(0xFFD4748A), const Color(0xFFFFF0F3), t),
            boxShadow: [BoxShadow(color: const Color(0xFFC0526A).withOpacity(0.4 * t), blurRadius: 8, spreadRadius: 1)],
          ),
        );
      },
    );
  }

  // Gold shimmer metin — REYHANLI için
  Widget _goldText(String text, double fontSize, AnimationController ctrl) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Color.lerp(const Color(0xFFDAA060), const Color(0xFFFFEAD0), ctrl.value)!,
              Color.lerp(const Color(0xFFF5C2CE), const Color(0xFFFFFFFF), ctrl.value)!,
              Color.lerp(const Color(0xFFDAA060), const Color(0xFFF8D0A0), ctrl.value)!,
              Color.lerp(const Color(0xFFFFD6DC), const Color(0xFFFFFFFF), ctrl.value)!,
            ],
            stops: const [0.0, 0.35, 0.65, 1.0],
          ).createShader(bounds),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              shadows: [
                Shadow(color: const Color(0xFFAA3050).withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 2)),
                Shadow(color: const Color(0xFFDAA060).withOpacity(0.4 * ctrl.value), blurRadius: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Gold shimmer isim — Nur / Merve için (daha büyük, zarif)
  Widget _nameText(String text, AnimationController goldCtrl) {
    return AnimatedBuilder(
      animation: goldCtrl,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Color.lerp(const Color(0xFFC8860A), const Color(0xFFFFE4A0), goldCtrl.value)!,
              Color.lerp(const Color(0xFFFFD580), const Color(0xFFFFFFFF), goldCtrl.value)!,
              Color.lerp(const Color(0xFFC8860A), const Color(0xFFFFD060), goldCtrl.value)!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              shadows: [
                Shadow(color: const Color(0xFF7A3000).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
                Shadow(color: const Color(0xFFDAA060).withOpacity(0.5 * goldCtrl.value), blurRadius: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF08090),
      body: SafeArea(
        child: Column(
          children: [
            // ── Tüm merkez içerik ──
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // REYHANLI — yukarıdan süzülür
                    FadeTransition(
                      opacity: _reyhFade,
                      child: SlideTransition(
                        position: _reyhSlide,
                        child: _goldText('R E Y H A N L I', 13, _goldCtrl),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Logo
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: size.width * 0.65,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nur Özçelik — soldan gelir
                    FadeTransition(
                      opacity: _nurFade,
                      child: SlideTransition(
                        position: _nurSlide,
                        child: _nameText('Nur Özçelik', _nameGoldCtrl),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // &
                    FadeTransition(
                      opacity: _ampFade,
                      child: AnimatedBuilder(
                        animation: _nameGoldCtrl,
                        builder: (_, __) => Text(
                          '&',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            shadows: [
                              Shadow(color: const Color(0xFF7A3000).withOpacity(0.3), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Merve İkizer — sağdan gelir
                    FadeTransition(
                      opacity: _merveFade,
                      child: SlideTransition(
                        position: _merveSlide,
                        child: _nameText('Merve İkizer', _nameGoldCtrl),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Alt loading bölümü ──
            FadeTransition(
              opacity: _bottomFade,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(_dot1Ctrl),
                        const SizedBox(width: 8),
                        _buildDot(_dot2Ctrl),
                        const SizedBox(width: 8),
                        _buildDot(_dot3Ctrl),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'N M   D R E S S   A B İ Y E',
                      style: TextStyle(
                        color: Color(0xFFFFF0F3),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.5,
                        shadows: [Shadow(color: Color(0xFFAA3050), blurRadius: 10, offset: Offset(0, 1))],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_barProgress, _shimmerPos]),
                        builder: (_, __) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 4,
                              child: Stack(
                                children: [
                                  Container(color: const Color(0xFFE8929E).withOpacity(0.45)),
                                  FractionallySizedBox(
                                    widthFactor: _barProgress.value,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFC96070), Color(0xFFE8C4CB), Color(0xFFDAA060), Color(0xFFE8C4CB)],
                                          stops: [0.0, 0.4, 0.75, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_barProgress.value > 0.05)
                                    FractionallySizedBox(
                                      widthFactor: _barProgress.value,
                                      child: LayoutBuilder(
                                        builder: (ctx, constraints) => CustomPaint(
                                          painter: _ShimmerPainter(progress: _shimmerPos.value, barWidth: constraints.maxWidth),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final double barWidth;
  _ShimmerPainter({required this.progress, required this.barWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final x = progress * barWidth;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.0)],
      ).createShader(Rect.fromCenter(center: Offset(x, size.height / 2), width: size.height * 9, height: size.height * 2));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress || old.barWidth != barWidth;
}
