import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sepet_provider.dart';
import '../providers/kullanici_provider.dart';
import '../services/uygulama_ici_bildirim.dart';
import 'urunler_screen.dart';
import 'sepet_screen.dart';
import 'profil_screen.dart';

class AnaSayfa extends StatefulWidget {
  final int initialTab;
  const AnaSayfa({super.key, this.initialTab = 0});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  late int _aktifTab;

  @override
  void initState() {
    super.initState();
    _aktifTab = widget.initialTab;
    // Uygulama içi anlık bildirim dinleyicisini başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kullanici = context.read<KullaniciProvider>();
      if (kullanici.uid.isNotEmpty && !(kullanici.isAdmin)) {
        UygulamaIciBildirim.baslat(
          context: context,
          kullaniciId: kullanici.uid,
          kullaniciAdi: kullanici.kullanici?['adSoyad'] ?? '',
        );
      }
    });
  }

  @override
  void dispose() {
    UygulamaIciBildirim.durdur();
    super.dispose();
  }

  final List<Widget> _sayfalar = const [
    UrunlerScreen(),
    SepetScreen(),
    ProfilScreen(),
  ];

  void _degistir(int index) => setState(() => _aktifTab = index);

  @override
  Widget build(BuildContext context) {
    final sepet = context.watch<SepetProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _aktifTab,
        children: _sayfalar,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD05870), Color(0xFFF08090)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF08090).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TabItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Koleksiyon',
                  index: 0,
                  aktif: _aktifTab,
                  onTap: _degistir,
                ),
                _SepetTab(
                  adet: sepet.toplamAdet,
                  aktif: _aktifTab == 1,
                  onTap: () => _degistir(1),
                ),
                _TabItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Hesabım',
                  index: 2,
                  aktif: _aktifTab,
                  onTap: _degistir,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int aktif;
  final Function(int) onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final secili = index == aktif;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: secili ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: secili ? Colors.white : Colors.white.withOpacity(0.55),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: secili ? FontWeight.w700 : FontWeight.w400,
                color: secili ? Colors.white : Colors.white.withOpacity(0.55),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SepetTab extends StatelessWidget {
  final int adet;
  final bool aktif;
  final VoidCallback onTap;

  const _SepetTab({
    required this.adet,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: aktif ? Colors.white.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: aktif ? Colors.white : Colors.white.withOpacity(0.55),
                  size: 24,
                ),
                if (adet > 0)
                  Positioned(
                    top: -5,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$adet',
                        style: const TextStyle(
                          color: Color(0xFFD05870),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Sepet',
              style: TextStyle(
                fontSize: 11,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w400,
                color: aktif ? Colors.white : Colors.white.withOpacity(0.55),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
