import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/bildirim.dart';
import '../providers/kullanici_provider.dart';
import '../services/firebase_service.dart';
import 'magazayla_yazisma_screen.dart';

const _primary    = Color(0xFF8B1A4A);
const _primaryLt  = Color(0xFFD05870);

class BildirimlerScreen extends StatefulWidget {
  const BildirimlerScreen({super.key});
  @override
  State<BildirimlerScreen> createState() => _BildirimlerScreenState();
}

class _BildirimlerScreenState extends State<BildirimlerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hepsiniOku());
  }

  Future<void> _hepsiniOku() async {
    final uid = context.read<KullaniciProvider>().uid;
    if (uid.isEmpty) return;
    await FirebaseService.bildirimleriOkunduIsaretle(uid);
  }

  Future<void> _hepsiniSil(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Bildirimleri Temizle',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          '${docs.length} bildirim silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('İptal',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (onay != true) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Tüm bildirimler temizlendi',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<KullaniciProvider>().uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bildirimler')
          .where('kullaniciId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF8F2F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.06),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1A1A1A), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Bildirimler',
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            actions: [
              if (docs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded,
                      color: Color(0xFFEF4444), size: 22),
                  tooltip: 'Tümünü temizle',
                  onPressed: () => _hepsiniSil(docs),
                ),
              TextButton.icon(
                onPressed: () async {
                  await FirebaseService.bildirimleriOkunduIsaretle(uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(children: [
                          Icon(Icons.done_all_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Tümü okundu işaretlendi',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                        backgroundColor: _primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.done_all_rounded, size: 16, color: _primary),
                label: const Text('Tümünü oku',
                    style: TextStyle(
                        color: _primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          body: Builder(builder: (context) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _primary));
            }

            if (snapshot.hasError) {
              return _HataEkrani(hata: snapshot.error.toString());
            }

            if (docs.isEmpty) {
              return const _BosEkran();
            }

            final bildirimler =
                docs.map((d) => Bildirim.fromFirestore(d)).toList();

            final okunmamislar =
                bildirimler.where((b) => !b.okundu).toList();
            final okunanlar =
                bildirimler.where((b) => b.okundu).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                if (okunmamislar.isNotEmpty) ...[
                  _GrupBaslik(
                    label: 'Yeni',
                    sayi: okunmamislar.length,
                    renk: _primary,
                  ),
                  const SizedBox(height: 8),
                  ...okunmamislar.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BildirimKart(
                      bildirim: b,
                      onTap: () => _bildirimeTikla(b),
                    ),
                  )),
                  if (okunanlar.isNotEmpty) const SizedBox(height: 16),
                ],
                if (okunanlar.isNotEmpty) ...[
                  _GrupBaslik(
                    label: 'Daha önce',
                    sayi: okunanlar.length,
                    renk: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 8),
                  ...okunanlar.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _BildirimKart(
                      bildirim: b,
                      onTap: () => _bildirimeTikla(b),
                    ),
                  )),
                ],
              ],
            );
          }),
        );
      },
    );
  }

  void _bildirimeTikla(Bildirim b) {
    final kullanici = context.read<KullaniciProvider>();
    if (b.tip == BildirimTipi.mesajGeldi ||
        b.tip == BildirimTipi.musteriMesaj) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MagazaylaYazismaScreen(
            kullaniciId: kullanici.uid,
            kullaniciAdi: kullanici.kullanici?['adSoyad'] ?? '',
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRUP BAŞLIK
// ─────────────────────────────────────────────────────────────────────────────
class _GrupBaslik extends StatelessWidget {
  final String label;
  final int sayi;
  final Color renk;
  const _GrupBaslik(
      {required this.label, required this.sayi, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: renk,
              letterSpacing: 0.3)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('$sayi',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: renk)),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BİLDİRİM KARTI
// ─────────────────────────────────────────────────────────────────────────────
class _BildirimKart extends StatelessWidget {
  final Bildirim bildirim;
  final VoidCallback onTap;
  const _BildirimKart({required this.bildirim, required this.onTap});

  // Tip'e göre ikon + renk
  _TipStyle get _stil {
    switch (bildirim.tip) {
      case BildirimTipi.mesajGeldi:
        return _TipStyle(
          ikon: Icons.chat_bubble_rounded,
          renk: _primary,
          arka: const Color(0xFFFCE4EC),
          etiket: 'Mesaj',
          etiketRenk: _primary,
        );
      case BildirimTipi.musteriMesaj:
        return _TipStyle(
          ikon: Icons.support_agent_rounded,
          renk: const Color(0xFF1D4ED8),
          arka: const Color(0xFFEFF6FF),
          etiket: 'Destek',
          etiketRenk: const Color(0xFF1D4ED8),
        );
      case BildirimTipi.siparisDurum:
        return _TipStyle(
          ikon: Icons.local_shipping_rounded,
          renk: const Color(0xFFD97706),
          arka: const Color(0xFFFFFBEB),
          etiket: 'Sipariş',
          etiketRenk: const Color(0xFFD97706),
        );
      case BildirimTipi.kiralamaDurum:
        return _TipStyle(
          ikon: Icons.checkroom_rounded,
          renk: const Color(0xFF0D9488),
          arka: const Color(0xFFF0FDFA),
          etiket: 'Kiralama',
          etiketRenk: const Color(0xFF0D9488),
        );
      case BildirimTipi.kaporaBelirle:
        return _TipStyle(
          ikon: Icons.account_balance_wallet_rounded,
          renk: const Color(0xFF7C3AED),
          arka: const Color(0xFFF5F3FF),
          etiket: 'Kapora',
          etiketRenk: const Color(0xFF7C3AED),
        );
      case BildirimTipi.kaporaDurum:
        return _TipStyle(
          ikon: Icons.payments_rounded,
          renk: const Color(0xFF059669),
          arka: const Color(0xFFF0FDF4),
          etiket: 'Ödeme',
          etiketRenk: const Color(0xFF059669),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _stil;
    final okunmamis = !bildirim.okundu;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: okunmamis ? const Color(0xFFFFF0F5) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: okunmamis
                ? _primary.withOpacity(0.22)
                : Colors.grey.withOpacity(0.08),
            width: okunmamis ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: okunmamis
                    ? _primary.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                blurRadius: okunmamis ? 14 : 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // İkon
          Stack(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: s.arka,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(s.ikon, color: s.renk, size: 22),
              ),
              if (okunmamis)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // İçerik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık + etiket
                Row(children: [
                  Expanded(
                    child: Text(
                      bildirim.baslik,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: okunmamis
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: const Color(0xFF111827)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: s.etiketRenk.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(s.etiket,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: s.etiketRenk,
                            letterSpacing: 0.3)),
                  ),
                ]),
                const SizedBox(height: 5),

                // İçerik metni
                Text(
                  bildirim.icerik,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Zaman
                Row(children: [
                  Icon(Icons.access_time_rounded,
                      size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    _saatMetni(bildirim.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400),
                  ),
                ]),
              ],
            ),
          ),

          // Ok ikonu
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade300, size: 18),
        ]),
      ),
    );
  }

  String _saatMetni(DateTime dt) {
    final now = DateTime.now();
    final fark = now.difference(dt);
    if (fark.inMinutes < 1) return 'Az önce';
    if (fark.inMinutes < 60) return '${fark.inMinutes} dk önce';
    if (fark.inHours < 24) return '${fark.inHours} saat önce';
    if (fark.inDays == 1) return 'Dün';
    if (fark.inDays < 7) return '${fark.inDays} gün önce';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YARDIMCi SINIFLAR
// ─────────────────────────────────────────────────────────────────────────────
class _TipStyle {
  final IconData ikon;
  final Color renk;
  final Color arka;
  final String etiket;
  final Color etiketRenk;
  const _TipStyle({
    required this.ikon,
    required this.renk,
    required this.arka,
    required this.etiket,
    required this.etiketRenk,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// BOŞ EKRAN
// ─────────────────────────────────────────────────────────────────────────────
class _BosEkran extends StatelessWidget {
  const _BosEkran();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_primary, _primaryLt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: _primary.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('Henüz bildirim yok',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF374151))),
        const SizedBox(height: 8),
        Text(
          'Sipariş, kiralama ve mesaj\nbildirimleriniz burada görünecek.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.grey.shade500, fontSize: 13, height: 1.6),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HATA EKRANI
// ─────────────────────────────────────────────────────────────────────────────
class _HataEkrani extends StatelessWidget {
  final String hata;
  const _HataEkrani({required this.hata});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Bildirimler yüklenemedi',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF374151))),
          const SizedBox(height: 8),
          Text(
            'Firestore index gerekebilir.\nLütfen konsol linkine tıklayın.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Text(
              hata,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF92400E),
                  fontFamily: 'monospace'),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}
