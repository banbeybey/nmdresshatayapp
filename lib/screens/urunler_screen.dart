import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/urun_provider.dart';
import '../providers/kullanici_provider.dart';
import '../models/urun.dart';
import 'urun_detay_screen.dart';
import 'admin/admin_panel_screen.dart';

const _primary   = Color(0xFF8B1A4A);
const _primaryLt = Color(0xFFD05870);
const _bg        = Color(0xFFF8F2F5);

class UrunlerScreen extends StatefulWidget {
  const UrunlerScreen({super.key});
  @override
  State<UrunlerScreen> createState() => _UrunlerScreenState();
}

class _UrunlerScreenState extends State<UrunlerScreen>
    with SingleTickerProviderStateMixin {
  String _aramaMetni = '';
  final _scrollCtrl = ScrollController();
  bool _headerKucuk = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final kucuk = _scrollCtrl.offset > 80;
      if (kucuk != _headerKucuk) setState(() => _headerKucuk = kucuk);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<Urun> _filtrele(List<Urun> urunler) => urunler
      .where((u) => u.ad.toLowerCase().contains(_aramaMetni.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final urunProvider    = context.watch<UrunProvider>();
    final kullanici       = context.watch<KullaniciProvider>();
    final filtreliUrunler = _filtrele(urunProvider.urunler);
    final musaitSayisi    = filtreliUrunler.where((u) => !u.kiraldaMi && u.stokVar).length;
    final kiralandaSayisi = filtreliUrunler.where((u) => u.kiraldaMi).length;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HERO HEADER ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            collapsedHeight: 64,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _primaryLt,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeaderBackground(isAdmin: kullanici.isAdmin),
            ),
            title: AnimatedOpacity(
              opacity: _headerKucuk ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('NM',
                      style: TextStyle(
                          color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                const SizedBox(width: 10),
                const Text('DRESS',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w300, letterSpacing: 5)),
              ]),
            ),
            actions: [
              if (kullanici.isAdmin)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),

          // ── ARAMA ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _AramaAlani(
              aramaMetni: _aramaMetni,
              onArama: (v) => setState(() => _aramaMetni = v),
            ),
          ),

          // ── İSTATİSTİK BAR ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(children: [
                _StatChip(
                  label: '${filtreliUrunler.length} Ürün',
                  icon: Icons.checkroom_rounded,
                  color: _primary,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: '$musaitSayisi Müsait',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                if (kiralandaSayisi > 0)
                  _StatChip(
                    label: '$kiralandaSayisi Kirada',
                    icon: Icons.lock_clock_rounded,
                    color: const Color(0xFFD97706),
                  ),
              ]),
            ),
          ),

          // ── ÜRÜN GRID ────────────────────────────────────────────────────
          if (urunProvider.yukleniyor)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _primary)))
          else if (filtreliUrunler.isEmpty)
            SliverFillRemaining(child: _BosEkran())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _UrunKart(urun: filtreliUrunler[i]),
                  childCount: filtreliUrunler.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.47,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderBackground extends StatelessWidget {
  final bool isAdmin;
  const _HeaderBackground({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7B1040), Color(0xFFD05870), Color(0xFFF4A0B0)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Dekoratif daireler
          Positioned(top: -30, right: -30,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.07), width: 45)))),
          Positioned(bottom: 30, right: 50,
            child: Container(width: 70, height: 70,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05)))),
          Positioned(top: 60, left: -35,
            child: Container(width: 110, height: 110,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04)))),
          // Alt geçiş (header → arka plan)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_bg, _bg.withOpacity(0)],
                )))),
          // Logo — tam görünür, sağ alt köşe
          Positioned(
            right: 16, bottom: 24,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120, height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Koleksiyon rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFD700))),
                      const SizedBox(width: 6),
                      Text('KOLEKSİYON 2026',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  // Ana başlık
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text('NM',
                          style: TextStyle(
                              color: Colors.white, fontSize: 46,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4, height: 1)),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DRESS',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 20,
                                  fontWeight: FontWeight.w200, letterSpacing: 8)),
                          Container(width: 80, height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0),
                              ]),
                            )),
                        ]),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Abiye Kiralama Mağazası',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11, letterSpacing: 2,
                          fontWeight: FontWeight.w300)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARAMA ALANI
// ─────────────────────────────────────────────────────────────────────────────
class _AramaAlani extends StatelessWidget {
  final String aramaMetni;
  final ValueChanged<String> onArama;
  const _AramaAlani({required this.aramaMetni, required this.onArama});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.10),
                blurRadius: 24, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: TextField(
          onChanged: onArama,
          style: const TextStyle(fontSize: 14, color: Color(0xFF2D1021)),
          decoration: InputDecoration(
            hintText: 'Abiye ara...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE8B4C8), Color(0xFFF0D0DE)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded, color: _primary, size: 18),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// İSTATİSTİK CHİP
// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _StatChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ÜRÜN KARTI
// ─────────────────────────────────────────────────────────────────────────────
class _UrunKart extends StatelessWidget {
  final Urun urun;
  const _UrunKart({required this.urun});

  bool get _kiralandi => urun.kiraldaMi;
  bool get _stokYok   => !urun.stokVar && !urun.kiraldaMi;
  bool get _musait    => !_kiralandi && !_stokYok;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => UrunDetayScreen(urun: urun))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(_kiralandi ? 0.04 : 0.09),
                blurRadius: 20, offset: const Offset(0, 7)),
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── GÖRSEL ──────────────────────────────────────
            Expanded(
              flex: 66,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(22)),
                    child: urun.gorselUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: urun.gorselUrls.first,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            placeholder: (_, __) => _Placeholder(),
                            errorWidget: (_, __, ___) => _Placeholder())
                        : _Placeholder(),
                  ),

                  // Karartma overlay
                  if (_kiralandi || _stokYok)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22)),
                      child: Container(
                          color: Colors.black
                              .withOpacity(_kiralandi ? 0.52 : 0.38)),
                    ),

                  // KİRALANDI rozeti
                  if (_kiralandi)
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB71C1C),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 16, offset: const Offset(0, 6))
                            ],
                          ),
                          child: const Text('KİRALANDI',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.lock_rounded,
                                color: Colors.white70, size: 10),
                            const SizedBox(width: 4),
                            Text('Teslim bekleniyor',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3)),
                          ]),
                        ),
                      ]),
                    ),

                  // STOK YOK rozeti
                  if (_stokYok)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: const Text('STOK YOK',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2)),
                      ),
                    ),

                  // Alt gradient + fiyat rozeti (sadece müsait ürünlerde)
                  if (_musait) ...[
                    Positioned(
                      bottom: 0, left: 0, right: 0, height: 64,
                      child: ClipRRect(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: _primary.withOpacity(0.4),
                                blurRadius: 8, offset: const Offset(0, 3))
                          ],
                        ),
                        child: Text(
                            '₺${urun.kiraFiyati.toStringAsFixed(0)} / 3 GÜN',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3)),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── BİLGİ ALANI ─────────────────────────────────
            Expanded(
              flex: 34,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ürün adı
                    Text(urun.ad,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Color(0xFF1A0A12),
                            height: 1.3,
                            letterSpacing: 0.1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),

                    // Fiyat (kirada/stok yok durumunda alt bilgi)
                    if (!_musait)
                      Row(children: [
                        Icon(Icons.event_available_rounded,
                            size: 11,
                            color: _kiralandi
                                ? const Color(0xFFD97706)
                                : Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                              '₺${urun.kiraFiyati.toStringAsFixed(0)} / 3 GÜN',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: _kiralandi
                                      ? const Color(0xFFD97706)
                                      : Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ),
                      ]),

                    // Aksiyon butonu
                    SizedBox(
                      width: double.infinity,
                      child: _KiralaButon(urun: urun),
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

// ─────────────────────────────────────────────────────────────────────────────
// KİRALA BUTONU
// ─────────────────────────────────────────────────────────────────────────────
class _KiralaButon extends StatelessWidget {
  final Urun urun;
  const _KiralaButon({required this.urun});

  @override
  Widget build(BuildContext context) {
    // KİRALANDI
    if (urun.kiraldaMi) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_rounded, size: 11, color: Color(0xFFB71C1C)),
          const SizedBox(width: 5),
          const Text('KİRALANDI',
              style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5)),
        ]),
      );
    }

    // STOK YOK
    if (!urun.stokVar) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: const Center(
          child: Text('Müsait Değil',
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      );
    }

    // KIRALA (aktif)
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => UrunDetayScreen(urun: urun))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF8B1A4A), Color(0xFFD05870)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(0.35),
                blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 12, color: Colors.white),
          const SizedBox(width: 5),
          const Text('Kirala',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER
// ─────────────────────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5DCE9), Color(0xFFE8C4D8)],
        ),
      ),
      child: const Center(
          child: Icon(Icons.checkroom_rounded,
              color: Color(0xFF8B1A4A), size: 44)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOŞ EKRAN
// ─────────────────────────────────────────────────────────────────────────────
class _BosEkran extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _primary.withOpacity(0.08),
              _primary.withOpacity(0.04)
            ]),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.checkroom_outlined,
              size: 46, color: _primary.withOpacity(0.5)),
        ),
        const SizedBox(height: 18),
        const Text('Ürün bulunamadı',
            style: TextStyle(
                color: Color(0xFF7A4D63),
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 6),
        Text('Arama kriterini değiştirin',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    );
  }
}
