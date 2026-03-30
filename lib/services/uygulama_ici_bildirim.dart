import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/magazayla_yazisma_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Uygulama içi anlık bildirim servisi
// Ana kullanımı: UygulamaIciBildirim.baslat(context, uid, kullaniciAdi)
// ─────────────────────────────────────────────────────────────────────────────

class UygulamaIciBildirim {
  UygulamaIciBildirim._();

  static StreamSubscription? _abonelik;
  static DateTime? _sonBildirimZamani;
  static OverlayEntry? _aktifEntry;

  /// Kullanıcı giriş yaptıktan sonra bir kez çağır.
  static void baslat({
    required BuildContext context,
    required String kullaniciId,
    required String kullaniciAdi,
  }) {
    durdur(); // Önceki aboneliği temizle

    // Sadece son 30 saniyede oluşan 'mesajGeldi' bildirimlerini dinle
    _abonelik = FirebaseFirestore.instance
        .collection('bildirimler')
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('tip', isEqualTo: 'mesajGeldi')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isEmpty) return;

      final doc = snap.docs.first;
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      if (createdAt == null) return;

      // Daha önce gösterdikten sonra tekrar gösterme
      if (_sonBildirimZamani != null &&
          !createdAt.isAfter(_sonBildirimZamani!)) return;

      // 10 saniyeden eski bildirimleri gösterme (uygulama kapalıyken gelmiş olabilir)
      if (DateTime.now().difference(createdAt).inSeconds > 10) return;

      _sonBildirimZamani = createdAt;

      final baslik = data['baslik'] as String? ?? 'Yeni mesaj';
      final icerik = data['icerik'] as String? ?? '';

      _goster(
        context: context,
        baslik: baslik,
        icerik: icerik,
        kullaniciId: kullaniciId,
        kullaniciAdi: kullaniciAdi,
      );
    });
  }

  static void durdur() {
    _abonelik?.cancel();
    _abonelik = null;
    _aktifEntry?.remove();
    _aktifEntry = null;
  }

  static void _goster({
    required BuildContext context,
    required String baslik,
    required String icerik,
    required String kullaniciId,
    required String kullaniciAdi,
  }) {
    // Varsa eskisini kaldır
    _aktifEntry?.remove();
    _aktifEntry = null;

    // Ses çal
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _BildirimBanner(
        baslik: baslik,
        icerik: icerik,
        onTap: () {
          entry.remove();
          _aktifEntry = null;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MagazaylaYazismaScreen(
                kullaniciId: kullaniciId,
                kullaniciAdi: kullaniciAdi,
              ),
            ),
          );
        },
        onKapat: () {
          entry.remove();
          _aktifEntry = null;
        },
      ),
    );

    _aktifEntry = entry;
    overlay.insert(entry);

    // 5 saniye sonra otomatik kaldır
    Timer(const Duration(seconds: 5), () {
      if (_aktifEntry == entry) {
        entry.remove();
        _aktifEntry = null;
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Görsel banner widget'ı
// ─────────────────────────────────────────────────────────────────────────────
class _BildirimBanner extends StatefulWidget {
  final String baslik;
  final String icerik;
  final VoidCallback onTap;
  final VoidCallback onKapat;

  const _BildirimBanner({
    required this.baslik,
    required this.icerik,
    required this.onTap,
    required this.onKapat,
  });

  @override
  State<_BildirimBanner> createState() => _BildirimBannerState();
}

class _BildirimBannerState extends State<_BildirimBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // 4.5 saniye sonra yukarı çıkarak kaybol
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF8B1A4A).withOpacity(0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1A4A).withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // İkon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B1A4A), Color(0xFFB5478A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Metin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.baslik,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (widget.icerik.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.icerik,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Kapat butonu
                    GestureDetector(
                      onTap: widget.onKapat,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
