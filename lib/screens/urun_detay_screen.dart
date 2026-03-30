import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/urun.dart';
import '../providers/kullanici_provider.dart';
import 'giris_screen.dart';
import 'kiralama/sartname_screen.dart';

const _primary = Color(0xFF8B1A4A);

class UrunDetayScreen extends StatefulWidget {
  final Urun urun;
  const UrunDetayScreen({super.key, required this.urun});

  @override
  State<UrunDetayScreen> createState() => _UrunDetayScreenState();
}

class _UrunDetayScreenState extends State<UrunDetayScreen> {
  String? _secilenBeden;
  int _aktifResim = 0;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _kirala() {
    final kullanici = context.read<KullaniciProvider>();
    if (!kullanici.girisYapildi) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GirisScreen()));
      return;
    }
    if (widget.urun.kiraldaMi) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bu ürün şu an kirada')));
      return;
    }
    if (widget.urun.bedenler.isNotEmpty && _secilenBeden == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Lütfen beden seçiniz')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SartnameScreen(
          urun: widget.urun,
          secilenBeden: _secilenBeden ?? 'Standart',
        ),
      ),
    );
  }

  /// Görsel tam ekran / zoom ekranı
  void _gorselZoom(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _GorselZoomScreen(
          urls: widget.urun.gorselUrls,
          baslangicIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urun = widget.urun;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Görsel Galeri (SliverAppBar ile tam genişlik) ──────────────
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.65,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1A1A1A),
            automaticallyImplyLeading: false,
            // Sabit kalan üst bar (scroll sonrası)
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Görsel PageView — tam dolu, padding yok
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: urun.gorselUrls.isEmpty ? 1 : urun.gorselUrls.length,
                    onPageChanged: (i) => setState(() => _aktifResim = i),
                    itemBuilder: (_, i) {
                      if (urun.gorselUrls.isEmpty) {
                        return Container(
                          color: const Color(0xFFF0E6EC),
                          child: const Center(
                              child: Icon(Icons.checkroom, size: 100, color: _primary)),
                        );
                      }
                      return GestureDetector(
                        onTap: () => _gorselZoom(context, _aktifResim),
                        child: CachedNetworkImage(
                          imageUrl: urun.gorselUrls[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.topCenter,
                          placeholder: (_, __) => Container(color: const Color(0xFFF0E6EC)),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFFF0E6EC),
                            child: const Center(child: Icon(Icons.broken_image, color: _primary)),
                          ),
                        ),
                      );
                    },
                  ),

                  // Stok/Kirada overlay
                  if (urun.kiraldaMi || !urun.stokVar)
                    Container(
                      color: Colors.black.withOpacity(0.35),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: urun.kiraldaMi ? Colors.red.shade700 : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                          ),
                          child: Text(
                            urun.kiraldaMi ? 'ŞU AN KİRADA' : 'STOK YOK',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w900,
                                fontSize: 16, letterSpacing: 3),
                          ),
                        ),
                      ),
                    ),

                  // Nokta indikatör (alt)
                  if (urun.gorselUrls.length > 1)
                    Positioned(
                      bottom: 16, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(urun.gorselUrls.length, (i) {
                          final secili = i == _aktifResim;
                          return GestureDetector(
                            onTap: () => _pageCtrl.animateToPage(i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: secili ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: secili ? _primary : Colors.white54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Zoom ikonu (sağ alt)
                  if (urun.gorselUrls.isNotEmpty)
                    Positioned(
                      bottom: 20, right: 20,
                      child: GestureDetector(
                        onTap: () => _gorselZoom(context, _aktifResim),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),

                  // Alt gradient (içerikle geçiş için)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.18), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scroll sonrası sabit kalan ince bar: sadece geri butonu
            leading: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF1A1A1A)),
                  ),
                ),
              ),
            ),
          ),

          // ── İçerik ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ürün adı
                  Text(urun.ad,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),

                  // Kira fiyatı
                  Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Kiralık (3 Gün)',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('₺${urun.kiraFiyati.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: _primary, fontSize: 28, fontWeight: FontWeight.w900)),
                    ]),
                  ]),

                  // Stok etiketi
                  const SizedBox(height: 12),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: urun.stokVar && !urun.kiraldaMi
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(
                          urun.stokVar && !urun.kiraldaMi
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: urun.stokVar && !urun.kiraldaMi ? Colors.green : Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          urun.kiraldaMi ? 'Şu An Kirada' : (urun.stokVar ? 'Stokta Var' : 'Stok Yok'),
                          style: TextStyle(
                            color: urun.stokVar && !urun.kiraldaMi ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w700, fontSize: 12,
                          ),
                        ),
                      ]),
                    ),
                  ]),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Beden seçimi
                  if (urun.bedenler.isNotEmpty) ...[
                    const Text('Beden Seç',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: urun.bedenler.map((beden) {
                        final secili = _secilenBeden == beden;
                        return GestureDetector(
                          onTap: () => setState(() => _secilenBeden = beden),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: secili ? _primary : Colors.white,
                              border: Border.all(
                                  color: secili ? _primary : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(beden,
                                style: TextStyle(
                                    color: secili ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  // Açıklama
                  if (urun.aciklama.isNotEmpty) ...[
                    const Text('Ürün Hakkında',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(urun.aciklama,
                        style: TextStyle(color: Colors.grey.shade600, height: 1.6)),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // Alt buton — sadece Kirala

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: urun.kiraldaMi || !urun.stokVar ? null : _kirala,
            icon: const Icon(Icons.event_available_outlined),
            label: Text(
              urun.kiraldaMi ? 'Şu An Kirada' : (!urun.stokVar ? 'Müsait Değil' : 'Kirala'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: urun.kiraldaMi || !urun.stokVar
                  ? Colors.grey.shade300
                  : _primary,
              foregroundColor: urun.kiraldaMi || !urun.stokVar
                  ? Colors.grey
                  : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tam Ekran Zoom Görüntüleyici ─────────────────────────────────────────────
class _GorselZoomScreen extends StatefulWidget {
  final List<String> urls;
  final int baslangicIndex;
  const _GorselZoomScreen({required this.urls, required this.baslangicIndex});

  @override
  State<_GorselZoomScreen> createState() => _GorselZoomScreenState();
}

class _GorselZoomScreenState extends State<_GorselZoomScreen> {
  late int _aktif;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _aktif = widget.baslangicIndex;
    _ctrl = PageController(initialPage: widget.baslangicIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${_aktif + 1} / ${widget.urls.length}',
            style: const TextStyle(color: Colors.white60, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _aktif = i),
        itemBuilder: (_, i) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 5.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: _primary)),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white54, size: 80),
              ),
            ),
          );
        },
      ),
    );
  }
}
