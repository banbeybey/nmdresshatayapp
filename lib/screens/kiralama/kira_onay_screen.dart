import 'package:flutter/material.dart';
import '../../models/urun.dart';
import '../ana_sayfa.dart';

class KiraOnayScreen extends StatelessWidget {
  final Urun urun;
  final String adSoyad;
  final DateTime bitisTarihi;

  const KiraOnayScreen({
    super.key,
    required this.urun,
    required this.adSoyad,
    required this.bitisTarihi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Onay animasyonu
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B1A4A), Color(0xFFB5478A)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1A4A).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Talebiniz Alındı!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Sayın $adSoyad,\nkiralama talebiniz başarıyla iletildi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Bilgi kutusu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _BilgiSatir(
                      icon: Icons.checkroom_outlined,
                      baslik: 'Ürün',
                      deger: urun.ad,
                    ),
                    const Divider(height: 20),
                    _BilgiSatir(
                      icon: Icons.attach_money_rounded,
                      baslik: 'Kira Ücreti',
                      deger:
                          '₺${urun.kiraFiyati.toStringAsFixed(0)} (3 Gün)',
                    ),
                    const Divider(height: 20),
                    _BilgiSatir(
                      icon: Icons.event_outlined,
                      baslik: 'İade Tarihi',
                      deger:
                          '${bitisTarihi.day}.${bitisTarihi.month}.${bitisTarihi.year}',
                    ),
                    const Divider(height: 20),
                    const _BilgiSatir(
                      icon: Icons.pending_outlined,
                      baslik: 'Durum',
                      deger: 'Onay Bekleniyor',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bilgilendirme
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'NM Dress ekibi en kısa sürede sizinle iletişime geçecektir.',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Ana sayfaya dön butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AnaSayfa()),
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1A4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ana Sayfaya Dön',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BilgiSatir extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String deger;

  const _BilgiSatir({
    required this.icon,
    required this.baslik,
    required this.deger,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B1A4A), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baslik,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              Text(
                deger,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}