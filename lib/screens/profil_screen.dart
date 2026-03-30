import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/kullanici_provider.dart';
import '../services/firebase_service.dart';
import '../models/kiralama.dart';
import 'giris_screen.dart';
import 'magazayla_yazisma_screen.dart';
import 'bildirimler_screen.dart';
import 'ayarlar_screen.dart';

const _p1   = Color(0xFF5A0F36);
const _p2   = Color(0xFF8B1A4A);
const _p3   = Color(0xFFB5478A);
const _bg   = Color(0xFFF8F2F5);
const _kart = Colors.white;

// ─── Ana Widget ───────────────────────────────────────────────────────────────
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kullanici = context.watch<KullaniciProvider>();
    if (!kullanici.yuklendi) {
      return const Scaffold(
          backgroundColor: _bg,
          body: Center(child: CircularProgressIndicator(color: _p2)));
    }
    if (!kullanici.girisYapildi) return const _GirisYapScreen();
    return const _ProfilIcerigi();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANA PROFİL İÇERİĞİ
// ═══════════════════════════════════════════════════════════════════════════════
class _ProfilIcerigi extends StatefulWidget {
  const _ProfilIcerigi();
  @override
  State<_ProfilIcerigi> createState() => _ProfilIcerigiState();
}

class _ProfilIcerigiState extends State<_ProfilIcerigi> {
  File? _localAvatar;

  Future<void> _avatarSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _localAvatar = File(picked.path));
  }

  String _initials(String ad) {
    final parts = ad.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'K';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final k  = context.watch<KullaniciProvider>();
    final ad = k.kullanici?['adSoyad'] ?? '';
    final uid = k.uid;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: false,
            backgroundColor: _p1,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: false,
            actions: [
              // Bildirim çanı
              StreamBuilder<int>(
                stream: FirebaseService.okunmamisBildirimSayisi(uid),
                builder: (ctx, snap) {
                  final sayi = snap.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BildirimlerScreen()),
                        ),
                      ),
                      if (sayi > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              sayi > 9 ? '9+' : '$sayi',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => _cikisOnay(context, k),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [_p1, _p2, _p3]),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(top: -40, right: -40,
                      child: Container(width: 180, height: 180,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06)))),
                    Positioned(bottom: 30, left: -30,
                      child: Container(width: 110, height: 110,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04)))),
                    Positioned(bottom: 56, left: 24, right: 24,
                      child: Divider(color: Colors.white.withOpacity(0.1), thickness: 0.5)),
                    Positioned(
                      left: 24, right: 24, bottom: 24,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _avatarSec,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 76, height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: _localAvatar == null
                                        ? const LinearGradient(colors: [_p2, _p3],
                                            begin: Alignment.topLeft, end: Alignment.bottomRight)
                                        : null,
                                    boxShadow: [BoxShadow(color: _p1.withOpacity(0.5), blurRadius: 16, spreadRadius: 1)],
                                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 2.5),
                                  ),
                                  child: ClipOval(
                                    child: _localAvatar != null
                                        ? Image.file(_localAvatar!, fit: BoxFit.cover)
                                        : Center(child: Text(_initials(ad),
                                            style: const TextStyle(color: Colors.white, fontSize: 28,
                                                fontWeight: FontWeight.w900, letterSpacing: 1))),
                                  ),
                                ),
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 13, color: _p2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(ad,
                                    style: const TextStyle(color: Colors.white, fontSize: 20,
                                        fontWeight: FontWeight.w900, letterSpacing: 0.2),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                _InfoChip(icon: Icons.email_outlined, text: k.kullanici?['email'] ?? ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hızlı Eylemler ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  _HizliButon(
                    icon: Icons.event_available_outlined,
                    label: 'Kiralamalar',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => KiralamalarimScreen(uid: uid))),
                  ),
                  const SizedBox(width: 12),
                  _HizliButon(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'İletişim',
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => MagazaylaYazismaScreen(
                            kullaniciId: uid,
                            kullaniciAdi: k.kullanici?['adSoyad'] ?? ''))),
                  ),
                ],
              ),
            ),
          ),

          // ── Hesap Bölümü ─────────────────────────────────────────────────
          _SectionHeader('Hesap'),
          _MenuGrubu(
            children: [
              _MenuSatiri(
                icon: Icons.event_available_outlined,
                iconRenk: const Color(0xFF7B3FA0),
                baslik: 'Kiralamalarım',
                altyazi: 'Kiralık ürün geçmişi',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => KiralamalarimScreen(uid: uid))),
              ),
              _MenuAyirici(),
              _MenuSatiri(
                icon: Icons.person_outline_rounded,
                iconRenk: const Color(0xFF0EA5E9),
                baslik: 'Bilgileri Düzenle',
                altyazi: 'Ad, telefon, adres güncelle',
                onTap: () => _bilgiDuzenleSheet(context, k),
              ),
            ],
          ),

          // ── Mağaza Bölümü ─────────────────────────────────────────────────
          _SectionHeader('Mağaza'),
          _MenuGrubu(
            children: [
              _MenuSatiri(
                icon: Icons.chat_bubble_outline_rounded,
                iconRenk: const Color(0xFF10B981),
                baslik: 'Mağazayla İletişime Geç',
                altyazi: 'Mesaj gönder, cevap al',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MagazaylaYazismaScreen(
                        kullaniciId: uid,
                        kullaniciAdi: k.kullanici?['adSoyad'] ?? ''))),
              ),
            ],
          ),

          // ── Ayarlar Bölümü ───────────────────────────────────────────────
          _SectionHeader('Ayarlar'),
          _MenuGrubu(
            children: [
              _MenuSatiri(
                icon: Icons.settings_outlined,
                iconRenk: const Color(0xFF6B7280),
                baslik: 'Uygulama Ayarları',
                altyazi: 'Bildirimler, güvenlik, hesap',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AyarlarScreen(kullanici: k))),
              ),
            ],
          ),

          // ── Çıkış ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              child: GestureDetector(
                onTap: () => _cikisOnay(context, k),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Çıkış Yap',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bilgi Düzenle — TC hariç tüm alanlar değiştirilebilir ─────────────────
  void _bilgiDuzenleSheet(BuildContext context, KullaniciProvider k) {
    final adCtrl = TextEditingController(text: k.kullanici?['adSoyad'] ?? '');
    final telefonCtrl = TextEditingController(text: k.kullanici?['telefon'] ?? '');
    final adresCtrl = TextEditingController(text: k.kullanici?['adres'] ?? '');
    final emailCtrl = TextEditingController(text: k.kullanici?['email'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DuzenleSheet(
        baslik: 'Bilgileri Düzenle',
        icon: Icons.person_outline_rounded,
        iconRenk: const Color(0xFF0EA5E9),
        children: [
          _SheetAlan(ctrl: adCtrl, label: 'Ad Soyad', icon: Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _SheetAlan(ctrl: emailCtrl, label: 'E-posta', icon: Icons.email_outlined),
          const SizedBox(height: 12),
          _SheetAlan(ctrl: telefonCtrl, label: 'Telefon', icon: Icons.phone_outlined),
          const SizedBox(height: 12),
          _SheetAlan(ctrl: adresCtrl, label: 'Adres', icon: Icons.location_on_outlined, maxLines: 3),
          const SizedBox(height: 8),
          // TC değiştirilemez notu
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('TC Kimlik Numarası değiştirilemez.',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 12))),
              ],
            ),
          ),
        ],
        onKaydet: (setState, yukleniyor) async {
          final ad = adCtrl.text.trim();
          final telefon = telefonCtrl.text.trim();
          final adres = adresCtrl.text.trim();
          final email = emailCtrl.text.trim();
          if (ad.isEmpty || telefon.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Ad Soyad ve Telefon boş olamaz'),
                behavior: SnackBarBehavior.floating));
            return;
          }
          await k.profilGuncelle({
            'adSoyad': ad,
            'telefon': telefon,
            'adres': adres,
            'email': email,
          });
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('✓ Bilgileriniz güncellendi'),
              backgroundColor: _p2,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
      ),
    );
  }

  void _cikisOnay(BuildContext context, KullaniciProvider k) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 52, height: 52,
              decoration: const BoxDecoration(color: Color(0xFFFFECEC), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 26)),
            const SizedBox(height: 16),
            const Text('Çıkış Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('İptal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); k.cikisYap(); },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                    child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// KIRALAMALARIM TAM SAYFA
// ═══════════════════════════════════════════════════════════════════════════════
class KiralamalarimScreen extends StatelessWidget {
  final String uid;
  const KiralamalarimScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFF7B3FA0).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.event_available_outlined, color: Color(0xFF7B3FA0), size: 20)),
            const SizedBox(width: 12),
            const Text('Kiralamalarım',
                style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
      ),
      body: StreamBuilder<List<Kiralama>>(
        stream: FirebaseService.kiralamalariDinle(uid),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _p2));
          }
          final liste = snapshot.data ?? [];
          if (liste.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Henüz kiralamanız yok',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: liste.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _KiralamaKart(kiralama: liste[i]),
          );
        },
      ),
    );
  }
}

class _KiralamaKart extends StatelessWidget {
  final Kiralama kiralama;
  const _KiralamaKart({required this.kiralama});

  Color _durumRenk(String d) {
    switch (d) {
      case 'onaylandi': return const Color(0xFF2980B9);
      case 'teslim_edildi': return Colors.green;
      case 'iade_edildi': return const Color(0xFF8E44AD);
      default: return const Color(0xFFE67E22);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baslangic = kiralama.createdAt;
    final bitis = kiralama.bitisTarihi;
    final basStr = '${baslangic.day.toString().padLeft(2,'0')}.${baslangic.month.toString().padLeft(2,'0')}.${baslangic.year}';
    final bitStr = '${bitis.day.toString().padLeft(2,'0')}.${bitis.month.toString().padLeft(2,'0')}.${bitis.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _durumRenk(kiralama.durum),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64, height: 72,
                    child: kiralama.urunGorsel.isNotEmpty
                        ? CachedNetworkImage(imageUrl: kiralama.urunGorsel, fit: BoxFit.cover,
                            alignment: Alignment.topCenter)
                        : Container(color: const Color(0xFFF5DCE9),
                            child: const Icon(Icons.event_available, color: _p2, size: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kiralama.urunAdi,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Beden: ${kiralama.secilenBeden}',
                          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text('$basStr → İade: $bitStr',
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₺${kiralama.kiraFiyati.toStringAsFixed(0)}',
                                  style: const TextStyle(color: _p2, fontWeight: FontWeight.w900, fontSize: 16)),
                              Text('+ ₺${kiralama.depozito.toStringAsFixed(0)} depozito',
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _durumRenk(kiralama.durum).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(kiralama.durumMetin,
                                style: TextStyle(color: _durumRenk(kiralama.durum),
                                    fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      // ── Kapora durumu (tutar belirlenmiş ise göster) ──
                      if (kiralama.kaporaTutar > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: kiralama.kaporaDurumuRengi.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kiralama.kaporaDurumuRengi.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            Icon(Icons.monetization_on_outlined,
                                size: 14, color: kiralama.kaporaDurumuRengi),
                            const SizedBox(width: 6),
                            Text(
                              'Kapora: ₺${kiralama.kaporaTutar.toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: kiralama.kaporaDurumuRengi),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: kiralama.kaporaDurumuRengi.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                kiralama.kaporaDurumuMetin,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: kiralama.kaporaDurumuRengi),
                              ),
                            ),
                          ]),
                        ),
                        if (kiralama.kaporaAciklama != null && kiralama.kaporaAciklama!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Not: ${kiralama.kaporaAciklama}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GİRİŞ YAPILMAMIŞSA
// ═══════════════════════════════════════════════════════════════════════════════
class _GirisYapScreen extends StatelessWidget {
  const _GirisYapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Hesabım'),
        backgroundColor: _p2,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _kart,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16)],
            ),
            child: Column(
              children: [
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_p2, _p3],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: _p2.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.person_outline, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 18),
                const Text('Hesabınıza Giriş Yapın',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Siparişlerinizi takip etmek için giriş yapın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GirisScreen())),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: _p2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                  child: const Text('Giriş Yap',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GirisScreen(kayitModu: true))),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: _p2, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('Kayıt Ol',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _p2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// YARDIMCI WİDGETLER
// ═══════════════════════════════════════════════════════════════════════════════
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 11),
          const SizedBox(width: 4),
          Flexible(child: Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _HizliButon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HizliButon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _kart,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_p2, _p3],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(color: _p2.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String baslik;
  const _SectionHeader(this.baslik);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
        child: Text(baslik.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: Color(0xFF9CA3AF), letterSpacing: 1.4)),
      ),
    );
  }
}

class _MenuGrubu extends StatelessWidget {
  final List<Widget> children;
  const _MenuGrubu({required this.children});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _kart,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _MenuAyirici extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 60, endIndent: 16, thickness: 0.5);
}

class _MenuSatiri extends StatelessWidget {
  final IconData icon;
  final Color iconRenk;
  final String baslik;
  final String? altyazi;
  final VoidCallback onTap;

  const _MenuSatiri({
    required this.icon, required this.iconRenk,
    required this.baslik, required this.onTap, this.altyazi,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconRenk.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconRenk, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827))),
                  if (altyazi != null)
                    Text(altyazi!, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Düzenle Bottom Sheet ──────────────────────────────────────────────────────
class _DuzenleSheet extends StatefulWidget {
  final String baslik;
  final IconData icon;
  final Color iconRenk;
  final List<Widget> children;
  final Future<void> Function(StateSetter setState, bool yukleniyor) onKaydet;

  const _DuzenleSheet({
    required this.baslik, required this.icon, required this.iconRenk,
    required this.children, required this.onKaydet,
  });

  @override
  State<_DuzenleSheet> createState() => _DuzenleSheetState();
}

class _DuzenleSheetState extends State<_DuzenleSheet> {
  bool _yukleniyor = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: widget.iconRenk.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                    child: Icon(widget.icon, color: widget.iconRenk, size: 22)),
                  const SizedBox(width: 14),
                  Text(widget.baslik,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                ],
              ),
              const SizedBox(height: 24),
              ...widget.children,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _yukleniyor
                      ? null
                      : () => widget.onKaydet(setState, _yukleniyor),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _p2,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0),
                  child: _yukleniyor
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Kaydet',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAlan extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;
  final bool gizle;

  const _SheetAlan({
    required this.ctrl, required this.label, required this.icon,
    this.maxLines = 1, this.gizle = false,
  });

  @override
  State<_SheetAlan> createState() => _SheetAlanState();
}

class _SheetAlanState extends State<_SheetAlan> {
  late bool _gizleniyor;

  @override
  void initState() {
    super.initState();
    _gizleniyor = widget.gizle;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.ctrl,
      maxLines: widget.gizle ? 1 : widget.maxLines,
      obscureText: _gizleniyor,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon, size: 20),
        suffixIcon: widget.gizle
            ? IconButton(
                icon: Icon(_gizleniyor ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setState(() => _gizleniyor = !_gizleniyor))
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _p2, width: 2)),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
    );
  }
}
