import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/urun_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/siparis.dart';
import '../../models/kiralama.dart';
import 'urun_ekle_screen.dart';

// ── Renk Paleti ──────────────────────────────────────────────────────────────
const _primary    = Color(0xFF9B1F5C);   // Ana pembe
const _primaryDk  = Color(0xFF6D1240);   // Koyu pembe
const _primaryLt  = Color(0xFFE8A0C0);   // Açık pembe
const _accent     = Color(0xFFFF6B9D);   // Vurgu pembesi
const _bg         = Color(0xFFFDF5F9);   // Arka plan
const _surface    = Color(0xFFFFF0F6);   // Kart arka planı
const _rose50     = Color(0xFFFFF1F7);
const _rose100    = Color(0xFFFFE4EF);
const _rose200    = Color(0xFFFFBDD6);

// ── Admin Panel Ekranı ────────────────────────────────────────────────────────
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _seciliTab = 0;

  static const _tabs = [
    _TabInfo(icon: Icons.checkroom_rounded,    label: 'Ürünler'),
    _TabInfo(icon: Icons.event_available_rounded, label: 'Kiralamalar'),
    _TabInfo(icon: Icons.people_rounded,        label: 'Kullanıcılar'),
    _TabInfo(icon: Icons.chat_rounded,          label: 'Mesajlar'),
    _TabInfo(icon: Icons.settings_rounded,      label: 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Üst Başlık + Navigasyon ──────────────────────────────────
          _AdminHeader(
            seciliTab: _seciliTab,
            tabs: _tabs,
            onTabChanged: (i) => setState(() => _seciliTab = i),
          ),
          // ── İçerik ───────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _seciliTab,
              children: const [
                _UrunlerTab(),
                _KiralamalarTab(),
                _KullanicilarTab(),
                _MesajlarTab(),
                _AyarlarTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _seciliTab == 0
          ? _SikFAB(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UrunEkleScreen())),
              label: 'Ürün Ekle',
              icon: Icons.add_rounded,
            )
          : null,
    );
  }
}

class _TabInfo {
  final IconData icon;
  final String label;
  const _TabInfo({required this.icon, required this.label});
}

// ── Şık Header + Tab Navigasyon ───────────────────────────────────────────────
class _AdminHeader extends StatelessWidget {
  final int seciliTab;
  final List<_TabInfo> tabs;
  final ValueChanged<int> onTabChanged;

  const _AdminHeader({
    required this.seciliTab,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryDk, _primary, Color(0xFFB5265E)],
        ),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Başlık satırı
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mağaza Yönetim',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            )),
                        Text('Admin Paneli',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(width: 7, height: 7,
                            decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab butonları
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tabs.length, (i) {
                    final tab = tabs[i];
                    final selected = i == seciliTab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onTabChanged(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: selected
                                ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tab.icon,
                                  size: 16,
                                  color: selected ? _primary : Colors.white.withOpacity(0.85)),
                              const SizedBox(width: 6),
                              Text(tab.label,
                                  style: TextStyle(
                                    color: selected ? _primary : Colors.white.withOpacity(0.85),
                                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Şık FAB ───────────────────────────────────────────────────────────────────
class _SikFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  const _SikFAB({required this.onPressed, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.2,
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ÜRÜNLER TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _UrunlerTab extends StatelessWidget {
  const _UrunlerTab();

  @override
  Widget build(BuildContext context) {
    final urunProvider = context.watch<UrunProvider>();
    if (urunProvider.yukleniyor) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (urunProvider.urunler.isEmpty) {
      return _BosEkran(
        icon: Icons.checkroom_outlined,
        metin: 'Henüz ürün eklenmedi',
        butonLabel: 'İlk Ürünü Ekle',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UrunEkleScreen())),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: urunProvider.urunler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final urun = urunProvider.urunler[i];
        return _UrunKart(
          urun: urun,
          onDuzenle: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => UrunEkleScreen(duzenlenecekUrun: urun))),
          onSil: () => _silOnayla(context, urun.ad,
              () => context.read<UrunProvider>().urunSil(urun.id)),
          onKiralamaDurumDegistir: () => _kiralamaDurumDegistir(context, urun),
        );
      },
    );
  }

  void _silOnayla(BuildContext context, String ad, VoidCallback onSil) {
    showDialog(
      context: context,
      builder: (_) => _SilDialog(
        baslik: 'Ürünü Sil',
        icerik: '"$ad" silinecek. Emin misiniz?',
        onOnayla: () {
          onSil();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _kiralamaDurumDegistir(BuildContext context, dynamic urun) {
    final bool simdikiDurum = urun.kiraldaMi;
    final String baslik = simdikiDurum
        ? 'Ürünü Müsait Yap'
        : 'Mağaza İçi Kiralama';
    final String icerik = simdikiDurum
        ? '${urun.ad} teslim alindi, tekrar musait yapilacak. Onayliyor musunuz?'
        : '${urun.ad} magaza ici kiralama olarak isaretlenecek. Onayliyor musunuz?';

    showDialog(
      context: context,
      builder: (_) => _KiralamaDurumDialog(
        baslik: baslik,
        icerik: icerik,
        onayLabel: simdikiDurum ? 'Müsait Yap' : 'Kiralandı İşaretle',
        onayRenk: simdikiDurum ? const Color(0xFF16A34A) : const Color(0xFFD97706),
        onOnayla: () async {
          Navigator.pop(context);
          try {
            final yeniKiraldaMi = !simdikiDurum;
            await FirebaseFirestore.instance
                .collection('urunler')
                .doc(urun.id)
                .update({
              'kiraldaMi': yeniKiraldaMi,
              'stokVar': !yeniKiraldaMi,
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    Icon(
                      yeniKiraldaMi ? Icons.storefront_rounded : Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Flexible(child: Text(
                      yeniKiraldaMi
                          ? '${urun.ad} kiralandı olarak işaretlendi'
                          : '${urun.ad} tekrar müsait yapıldı',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                  ]),
                  backgroundColor: yeniKiraldaMi
                      ? const Color(0xFFD97706)
                      : const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _UrunKart extends StatelessWidget {
  final dynamic urun;
  final VoidCallback onDuzenle;
  final VoidCallback onSil;
  final VoidCallback onKiralamaDurumDegistir;
  const _UrunKart({required this.urun, required this.onDuzenle, required this.onSil, required this.onKiralamaDurumDegistir});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          // Görsel — daha büyük
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            child: urun.gorselUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: urun.gorselUrls.first,
                    width: 115, height: 135, fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        width: 115, height: 135,
                        color: _rose100,
                        child: const Center(
                            child: CircularProgressIndicator(color: _primary, strokeWidth: 2))),
                    errorWidget: (_, __, ___) => Container(
                        width: 115, height: 135,
                        color: _rose100,
                        child: const Icon(Icons.checkroom, color: _primary, size: 38)),
                  )
                : Container(
                    width: 115, height: 135,
                    color: _rose100,
                    child: const Icon(Icons.checkroom, color: _primary, size: 38)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(urun.ad,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A0A12)),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  // Fiyat
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_rose50, _rose100]),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _rose200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available_rounded, size: 13, color: _primary),
                        const SizedBox(width: 4),
                        Text('₺${urun.kiraFiyati.toStringAsFixed(0)} / kira',
                            style: const TextStyle(
                                color: _primary, fontSize: 12, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _Rozet(
                      metin: urun.kiraldaMi ? 'Kirada' : 'Müsait',
                      renk: urun.kiraldaMi ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    _Rozet(
                      metin: urun.stokVar ? 'Stokta' : 'Tükendi',
                      renk: urun.stokVar ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          // Aksiyon butonları
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AksiyonBtn(
                  icon: Icons.edit_rounded,
                  renk: _primary,
                  onTap: onDuzenle,
                ),
                const SizedBox(height: 8),
                _AksiyonBtn(
                  icon: urun.kiraldaMi
                      ? Icons.lock_open_rounded
                      : Icons.storefront_rounded,
                  renk: urun.kiraldaMi
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                  tooltip: urun.kiraldaMi ? 'İade Edildi' : 'Mağaza Kiralama',
                  onTap: onKiralamaDurumDegistir,
                ),
                const SizedBox(height: 8),
                _AksiyonBtn(
                  icon: Icons.delete_rounded,
                  renk: const Color(0xFFEF4444),
                  onTap: onSil,
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
// KİRALAMALAR TAB — Silme özelliği ile
// ═══════════════════════════════════════════════════════════════════════════════
class _KiralamalarTab extends StatelessWidget {
  const _KiralamalarTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Kiralama>>(
      stream: FirebaseService.tumKiralamalariDinle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }
        final kiralamalar = snapshot.data ?? [];
        if (kiralamalar.isEmpty) {
          return const _BosEkran(
            icon: Icons.event_available_outlined,
            metin: 'Henüz kiralama talebi yok',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          itemCount: kiralamalar.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) => _AdminKiralamaKart(
            kiralama: kiralamalar[i],
            onSil: () => _silOnayla(context, kiralamalar[i]),
          ),
        );
      },
    );
  }

  void _silOnayla(BuildContext context, Kiralama kiralama) {
    showDialog(
      context: context,
      builder: (_) => _SilDialog(
        baslik: 'Kiralama İsteğini Sil',
        icerik: '"${kiralama.urunAdi}" kiralama isteği silinecek. Emin misiniz?',
        onOnayla: () async {
          Navigator.pop(context);
          try {
            await FirebaseFirestore.instance
                .collection('kiralama_talepleri')
                .doc(kiralama.id)
                .delete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Kiralama isteği silindi'),
                  ]),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e'), behavior: SnackBarBehavior.floating));
            }
          }
        },
      ),
    );
  }
}

class _AdminKiralamaKart extends StatefulWidget {
  final Kiralama kiralama;
  final VoidCallback onSil;
  const _AdminKiralamaKart({required this.kiralama, required this.onSil});

  @override
  State<_AdminKiralamaKart> createState() => _AdminKiralamaKartState();
}

class _AdminKiralamaKartState extends State<_AdminKiralamaKart> {
  Color _durumRenk(String d) {
    switch (d) {
      case 'onaylandi':     return const Color(0xFF2563EB);
      case 'teslim_edildi': return const Color(0xFF16A34A);
      case 'iade_edildi':   return const Color(0xFF7C3AED);
      default:              return const Color(0xFFF59E0B);
    }
  }

  String _durumMetin(String d) {
    switch (d) {
      case 'onaylandi':     return 'Onaylandı';
      case 'teslim_edildi': return 'Teslim Edildi';
      case 'iade_edildi':   return 'İade Edildi';
      default:              return 'Beklemede';
    }
  }

  IconData _durumIcon(String d) {
    switch (d) {
      case 'onaylandi':     return Icons.check_circle_outline;
      case 'teslim_edildi': return Icons.local_shipping_outlined;
      case 'iade_edildi':   return Icons.assignment_return_outlined;
      default:              return Icons.hourglass_empty_outlined;
    }
  }

  String _tarihFormat(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}  '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _odemeTipi(String t) {
    switch (t) {
      case 'havale_eft': return 'Havale / EFT';
      case 'nakit':      return 'Nakit';
      default:           return t.isNotEmpty ? t : 'Belirtilmedi';
    }
  }


  @override
  Widget build(BuildContext context) {
    final k = widget.kiralama;
    final renk = _durumRenk(k.durum);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Üst bant ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [renk.withOpacity(0.07), renk.withOpacity(0.02)],
              ),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: renk.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: renk.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(_durumIcon(k.durum), color: renk, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(k.urunAdi,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF111827)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: _rose100, borderRadius: BorderRadius.circular(10)),
                  child: Text('₺${k.kiraFiyati.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _primary,
                          fontSize: 14)),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.onSil,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444), size: 18),
                  ),
                ),
              ],
            ),
          ),

          // ── Bilgi satırları ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              children: [
                _ModernDetayRow(icon: Icons.person_outline,      metin: k.adSoyad),
                _ModernDetayRow(icon: Icons.phone_outlined,       metin: k.telefon),
                _ModernDetayRow(icon: Icons.badge_outlined,       metin: 'TC: ${k.tcKimlik}'),
                _ModernDetayRow(icon: Icons.location_on_outlined, metin: k.teslimatAdresi),
                _ModernDetayRow(icon: Icons.straighten_outlined,  metin: 'Beden: ${k.secilenBeden}'),
                _ModernDetayRow(icon: Icons.account_balance_outlined, metin: _odemeTipi(k.odemeTipi)),
                _ModernDetayRow(
                    icon: Icons.calendar_today_outlined,
                    metin: 'Talep: ${_tarihFormat(k.createdAt)}'),
                _ModernDetayRow(
                  icon: Icons.event_available_outlined,
                  metin:
                      'İade: ${k.bitisTarihi.day.toString().padLeft(2, '0')}.${k.bitisTarihi.month.toString().padLeft(2, '0')}.${k.bitisTarihi.year}',
                  vurgu: true,
                ),
              ],
            ),
          ),


          // ── Kiralama durum güncelleme ──────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _rose50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _rose200),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: renk.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_durumMetin(k.durum),
                    style: TextStyle(
                        color: renk, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              const Text('Güncelle:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: k.durum,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                  style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  borderRadius: BorderRadius.circular(14),
                  items: ['beklemede', 'onaylandi', 'teslim_edildi', 'iade_edildi']
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(_durumMetin(d)),
                          ))
                      .toList(),
                  onChanged: (yeni) {
                    if (yeni != null) {
                      FirebaseService.kiralamaDurumGuncelle(
                          k.id, yeni,
                          kullaniciId: k.kullaniciId,
                          urunId: k.urunId);
                    }
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// KULLANICILAR TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _KullanicilarTab extends StatelessWidget {
  const _KullanicilarTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kullanicilar')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _BosEkran(icon: Icons.people_outline, metin: 'Henüz kullanıcı yok');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _KullaniciKart(uid: doc.id, data: data);
          },
        );
      },
    );
  }
}

class _KullaniciKart extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  const _KullaniciKart({required this.uid, required this.data});

  String _initials(String ad) {
    final parts = ad.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'K';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final adSoyad  = data['adSoyad'] ?? 'Bilinmiyor';
    final email    = data['email'] ?? '';
    final telefon  = data['telefon'] ?? '';
    final adres    = data['adres'] ?? '';
    final tcKimlik = data['tcKimlik'] ?? '';
    final isAdmin  = data['isAdmin'] == true;
    final avatarUrl = data['avatarUrl'] as String?;
    final createdAt = data['createdAt'];
    String kayitTarihi = '-';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      kayitTarihi =
          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: isAdmin ? Border.all(color: _primaryLt, width: 1.5) : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: isAdmin
                  ? const LinearGradient(colors: [_primary, _accent])
                  : LinearGradient(colors: [_rose100, _rose200]),
              shape: BoxShape.circle,
            ),
            child: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover))
                : Center(
                    child: Text(_initials(adSoyad),
                        style: TextStyle(
                            color: isAdmin ? Colors.white : _primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                  ),
          ),
          title: Row(children: [
            Expanded(
                child: Text(adSoyad,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF111827)))),
            if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_primary, _accent]),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('Admin',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(email,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: _rose200),
                  const SizedBox(height: 12),
                  _DetayRow(icon: Icons.phone_outlined,
                      metin: telefon.isEmpty ? 'Telefon girilmemiş' : telefon),
                  const SizedBox(height: 6),
                  if (tcKimlik.isNotEmpty) ...[
                    _DetayRow(icon: Icons.badge_outlined, metin: 'TC: $tcKimlik'),
                    const SizedBox(height: 6),
                  ],
                  _DetayRow(icon: Icons.location_on_outlined,
                      metin: adres.isEmpty ? 'Adres girilmemiş' : adres),
                  const SizedBox(height: 6),
                  _DetayRow(icon: Icons.calendar_today_outlined,
                      metin: 'Kayıt: $kayitTarihi'),
                  const SizedBox(height: 6),
                  _DetayRow(icon: Icons.fingerprint, metin: 'UID: $uid'),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: _OutlineBtn(
                        icon: Icons.chat_bubble_outline,
                        label: 'Mesaj',
                        renk: _primary,
                        onTap: () => _mesajaGit(context, uid, adSoyad),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OutlineBtn(
                        icon: Icons.delete_outline,
                        label: 'Hesabı Sil',
                        renk: const Color(0xFFEF4444),
                        onTap: () => _hesapSilOnay(context, uid, adSoyad),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mesajaGit(BuildContext context, String uid, String adSoyad) {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) =>
            _AdminKullaniciSohbetScreen(kullaniciId: uid, kullaniciAdi: adSoyad)));
  }

  void _hesapSilOnay(BuildContext context, String uid, String adSoyad) {
    showDialog(
      context: context,
      builder: (_) => _SilDialog(
        baslik: 'Hesabı Sil',
        icerik: '$adSoyad adlı kullanıcının hesabı kalıcı olarak silinecek. Bu işlem geri alınamaz.',
        onOnayla: () async {
          Navigator.pop(context);
          try {
            await FirebaseFirestore.instance.collection('kullanicilar').doc(uid).delete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$adSoyad hesabı silindi'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e'), behavior: SnackBarBehavior.floating));
            }
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MESAJLAR TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _MesajlarTab extends StatelessWidget {
  const _MesajlarTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('mesajlar').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primary));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _BosEkran(
            icon: Icons.chat_bubble_outline,
            metin: 'Henüz mesaj yok',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _SohbetListeItem(kullaniciId: docs[i].id),
        );
      },
    );
  }
}

class _SohbetListeItem extends StatelessWidget {
  final String kullaniciId;
  const _SohbetListeItem({required this.kullaniciId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('kullanicilar').doc(kullaniciId).get(),
      builder: (context, snap) {
        final data     = snap.data?.data() as Map<String, dynamic>?;
        final adSoyad  = data?['adSoyad'] ?? 'Kullanıcı';
        final email    = data?['email'] ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('mesajlar')
              .doc(kullaniciId)
              .collection('sohbet')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, mesajSnap) {
            final sonMesajDoc = mesajSnap.data?.docs.firstOrNull;
            final sonMesaj   = sonMesajDoc?.get('metin') as String? ?? '';
            final okunmadi   = sonMesajDoc?.get('okundu') == false &&
                sonMesajDoc?.get('gonderen') == 'kullanici';

            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => _AdminKullaniciSohbetScreen(
                          kullaniciId: kullaniciId, kullaniciAdi: adSoyad))),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: okunmadi ? Border.all(color: _primary.withOpacity(0.4), width: 1.5) : null,
                  boxShadow: [
                    BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_rose100, _rose200]),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          adSoyad.isNotEmpty ? adSoyad[0].toUpperCase() : 'K',
                          style: const TextStyle(
                              color: _primary, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(adSoyad,
                              style: TextStyle(
                                  fontWeight: okunmadi ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 14,
                                  color: const Color(0xFF111827))),
                          const SizedBox(height: 2),
                          Text(email,
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                          if (sonMesaj.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(sonMesaj,
                                style: TextStyle(
                                    color: okunmadi ? _primary : const Color(0xFF9CA3AF),
                                    fontSize: 12,
                                    fontWeight:
                                        okunmadi ? FontWeight.w600 : FontWeight.normal),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                    if (okunmadi)
                      Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADMİN — Müşteriyle Sohbet
// ═══════════════════════════════════════════════════════════════════════════════
class _AdminKullaniciSohbetScreen extends StatefulWidget {
  final String kullaniciId;
  final String kullaniciAdi;
  const _AdminKullaniciSohbetScreen(
      {required this.kullaniciId, required this.kullaniciAdi});

  @override
  State<_AdminKullaniciSohbetScreen> createState() =>
      _AdminKullaniciSohbetScreenState();
}

class _AdminKullaniciSohbetScreenState
    extends State<_AdminKullaniciSohbetScreen> {
  final _textCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _db        = FirebaseFirestore.instance;

  CollectionReference get _mesajlar =>
      _db.collection('mesajlar').doc(widget.kullaniciId).collection('sohbet');

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final metin = _textCtrl.text.trim();
    if (metin.isEmpty) return;
    _textCtrl.clear();
    await _mesajlar.add({
      'metin': metin,
      'gonderen': 'admin',
      'gonderenAdi': 'Mağaza',
      'createdAt': FieldValue.serverTimestamp(),
      'okundu': false,
    });

    // Müşteriye bildirimler ekranında görünsün
    await FirebaseService.bildirimGonder(
      kullaniciId: widget.kullaniciId,
      tip: 'mesajGeldi',
      baslik: 'Mağazadan yeni mesaj 💬',
      icerik: metin.length > 80 ? '${metin.substring(0, 80)}...' : metin,
    );

    await Future.delayed(const Duration(milliseconds: 150));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_rose100, _rose200]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.kullaniciAdi.isNotEmpty
                    ? widget.kullaniciAdi[0].toUpperCase()
                    : 'K',
                style: const TextStyle(color: _primary, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.kullaniciAdi,
                style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
            const Text('Müşteri',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _mesajlar.orderBy('createdAt').snapshots(),
              builder: (ctx, snapshot) {
                final mesajlar = snapshot.data?.docs ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: mesajlar.length,
                  itemBuilder: (_, i) {
                    final m = mesajlar[i].data() as Map<String, dynamic>;
                    final isAdmin = m['gonderen'] == 'admin';
                    return _MesajBulon(
                        metin: m['metin'] ?? '',
                        isAdmin: isAdmin,
                        createdAt: m['createdAt'] as Timestamp?);
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
                left: 16,
                right: 12,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _gonder(),
                  decoration: InputDecoration(
                    hintText: 'Müşteriye mesaj yaz...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    filled: true,
                    fillColor: _rose50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _gonder,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_primary, _accent]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: _primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MesajBulon extends StatelessWidget {
  final String metin;
  final bool isAdmin;
  final Timestamp? createdAt;
  const _MesajBulon({required this.metin, required this.isAdmin, this.createdAt});

  @override
  Widget build(BuildContext context) {
    final saat = createdAt != null
        ? '${createdAt!.toDate().hour.toString().padLeft(2, '0')}:${createdAt!.toDate().minute.toString().padLeft(2, '0')}'
        : '';
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isAdmin
              ? const LinearGradient(colors: [_primary, _accent])
              : null,
          color: isAdmin ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isAdmin ? 18 : 4),
            bottomRight: Radius.circular(isAdmin ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(metin,
                style: TextStyle(
                    color: isAdmin ? Colors.white : const Color(0xFF111827),
                    fontSize: 14,
                    height: 1.4)),
            const SizedBox(height: 4),
            Text(saat,
                style: TextStyle(
                    color: isAdmin ? Colors.white60 : Colors.grey.shade400,
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AYARLAR TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _AyarlarTab extends StatefulWidget {
  const _AyarlarTab();

  @override
  State<_AyarlarTab> createState() => _AyarlarTabState();
}

class _AyarlarTabState extends State<_AyarlarTab> {
  final _formKey   = GlobalKey<FormState>();
  final _bankaCtrl = TextEditingController();
  final _aliciCtrl = TextEditingController();
  final _ibanCtrl  = TextEditingController();
  bool _yukluyor   = true;
  bool _kaydediyor = false;
  bool _kaydedildi = false;

  @override
  void initState() {
    super.initState();
    FirebaseService.havaleBilgileriDinle().first.then((data) {
      if (!mounted) return;
      setState(() {
        _bankaCtrl.text = data['bankaAdi'] ?? '';
        _aliciCtrl.text = data['aliciAdSoyad'] ?? '';
        _ibanCtrl.text  = data['iban'] ?? '';
        _yukluyor       = false;
      });
    });
  }

  @override
  void dispose() {
    _bankaCtrl.dispose();
    _aliciCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }

  String _ibanFormat(String raw) {
    final temiz  = raw.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < temiz.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(temiz[i]);
    }
    return buffer.toString();
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _kaydediyor = true;
      _kaydedildi = false;
    });
    try {
      await FirebaseService.havaleBilgileriGuncelle(
        bankaAdi: _bankaCtrl.text.trim(),
        aliciAdSoyad: _aliciCtrl.text.trim(),
        iban: _ibanCtrl.text.replaceAll(' ', '').trim(),
      );
      if (!mounted) return;
      setState(() => _kaydedildi = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white),
          SizedBox(width: 8),
          Text('Bilgiler güncellendi'),
        ]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _kaydediyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukluyor) return const Center(child: CircularProgressIndicator(color: _primary));

    return StreamBuilder<Map<String, dynamic>>(
      stream: FirebaseService.havaleBilgileriDinle(),
      builder: (context, snapshot) {
        final canli      = snapshot.data ?? {};
        final canliIban  = canli['iban'] as String? ?? '';
        final canliAlici = canli['aliciAdSoyad'] as String? ?? '';
        final canliBanka = canli['bankaAdi'] as String? ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // ── Havale/EFT Formu ─────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Başlık
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_primary, _accent]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Havale / EFT Bilgileri',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Color(0xFF111827))),
                    Text('Müşterilere gösterilecek banka bilgileri',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ]),
                const SizedBox(height: 24),

                // Canlı önizleme
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_rose50, _rose100],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _rose200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.visibility_outlined, color: _primary, size: 15),
                        SizedBox(width: 6),
                        Text('Müşteride Anlık Görünüm',
                            style: TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ]),
                      const SizedBox(height: 12),
                      _OnizlemeRow(baslik: 'Banka', deger: canliBanka.isEmpty ? '—' : canliBanka),
                      _OnizlemeRow(baslik: 'Ad Soyad', deger: canliAlici.isEmpty ? '—' : canliAlici),
                      _OnizlemeRow(baslik: 'IBAN', deger: canliIban.isEmpty ? '—' : _ibanFormat(canliIban)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Düzenle',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF374151))),
                const SizedBox(height: 14),

                _AdminAlan(ctrl: _bankaCtrl, label: 'Banka Adı',
                    icon: Icons.account_balance_outlined, hint: 'Örn: Ziraat Bankası',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null),
                const SizedBox(height: 14),
                _AdminAlan(ctrl: _aliciCtrl, label: 'Alıcı Ad Soyad',
                    icon: Icons.person_outline, hint: 'Örn: Ayşe Kaya',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null),
                const SizedBox(height: 14),
                _AdminAlan(
                  ctrl: _ibanCtrl, label: 'IBAN',
                  icon: Icons.credit_card_outlined, hint: 'TR00 0000 0000 0000 0000 0000 00',
                  maxLength: 32,
                  validator: (v) {
                    final temiz = (v ?? '').replaceAll(' ', '');
                    if (temiz.isEmpty) return 'IBAN gerekli';
                    if (!temiz.startsWith('TR')) return 'TR ile başlamalı';
                    if (temiz.length != 26) return 'Geçersiz uzunluk';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _kaydediyor ? null : _kaydet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _kaydedildi
                              ? [Colors.green.shade500, Colors.green.shade400]
                              : [_primaryDk, _primary, _accent],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_kaydedildi ? Colors.green : _primary).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: _kaydediyor
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(
                                    _kaydedildi
                                        ? Icons.check_rounded
                                        : Icons.save_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _kaydediyor
                                      ? 'Kaydediliyor...'
                                      : (_kaydedildi ? 'Kaydedildi ✓' : 'Kaydet'),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                              ]),
                      ),
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BosEkran extends StatelessWidget {
  final IconData icon;
  final String metin;
  final String? butonLabel;
  final VoidCallback? onTap;
  const _BosEkran({required this.icon, required this.metin, this.butonLabel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_rose100, _rose200]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: _primary),
          ),
          const SizedBox(height: 16),
          Text(metin,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15, fontWeight: FontWeight.w500)),
          if (butonLabel != null && onTap != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_primary, _accent]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(butonLabel!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AksiyonBtn extends StatelessWidget {
  final IconData icon;
  final Color renk;
  final VoidCallback onTap;
  final String? tooltip;
  const _AksiyonBtn({required this.icon, required this.renk, required this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: renk.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: renk.withOpacity(0.2)),
        ),
        child: Icon(icon, color: renk, size: 17),
      ),
    ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color renk;
  final VoidCallback onTap;
  const _OutlineBtn({required this.icon, required this.label, required this.renk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: renk.withOpacity(0.25)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: renk),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: renk, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _SilDialog extends StatelessWidget {
  final String baslik;
  final String icerik;
  final VoidCallback onOnayla;
  const _SilDialog({required this.baslik, required this.icerik, required this.onOnayla});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: const BoxDecoration(color: Color(0xFFFFECEC), shape: BoxShape.circle),
          child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
        ),
        const SizedBox(width: 10),
        Text(baslik,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFFEF4444), fontSize: 16)),
      ]),
      content: Text(icerik,
          style: const TextStyle(color: Color(0xFF374151), fontSize: 14, height: 1.5)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      actions: [
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('İptal',
                      style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onOnayla,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Sil',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _Rozet extends StatelessWidget {
  final String metin;
  final Color renk;
  const _Rozet({required this.metin, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: renk.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: renk.withOpacity(0.25))),
      child: Text(metin,
          style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _DetayRow extends StatelessWidget {
  final IconData icon;
  final String metin;
  const _DetayRow({required this.icon, required this.metin});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(metin,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
        ),
      ],
    );
  }
}

class _ModernDetayRow extends StatelessWidget {
  final IconData icon;
  final String metin;
  final bool vurgu;
  const _ModernDetayRow(
      {required this.icon, required this.metin, this.vurgu = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: vurgu ? _rose100 : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: vurgu ? _primary : const Color(0xFF9CA3AF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(metin,
                  style: TextStyle(
                    color: vurgu ? _primary : const Color(0xFF374151),
                    fontSize: 13,
                    fontWeight: vurgu ? FontWeight.w700 : FontWeight.w500,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnizlemeRow extends StatelessWidget {
  final String baslik;
  final String deger;
  const _OnizlemeRow({required this.baslik, required this.deger});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        SizedBox(
          width: 72,
          child: Text(baslik,
              style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w600)),
        ),
        const Text(': ', style: TextStyle(color: _primary)),
        Expanded(
          child: Text(deger,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF3A0A20), fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _AdminAlan extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType keyboard;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _AdminAlan({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboard = TextInputType.text,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: _primary, size: 20),
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KIRALAMA DURUM DEĞİŞTİR DİALOG (Mağaza içi manuel kiralama)
// ─────────────────────────────────────────────────────────────────────────────
class _KiralamaDurumDialog extends StatelessWidget {
  final String baslik;
  final String icerik;
  final String onayLabel;
  final Color onayRenk;
  final VoidCallback onOnayla;
  const _KiralamaDurumDialog({
    required this.baslik,
    required this.icerik,
    required this.onayLabel,
    required this.onayRenk,
    required this.onOnayla,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      title: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: onayRenk.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            onayLabel.contains('Müsait')
                ? Icons.lock_open_rounded
                : Icons.storefront_rounded,
            color: onayRenk, size: 22),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(baslik,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: onayRenk,
                  fontSize: 16)),
        ),
      ]),
      content: Text(icerik,
          style: const TextStyle(
              color: Color(0xFF374151), fontSize: 14, height: 1.6)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      actions: [
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('İptal',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280))),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onOnayla,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: onayRenk,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: onayRenk.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Center(
                  child: Text(onayLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 13)),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}
