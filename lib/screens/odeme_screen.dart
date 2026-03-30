import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sepet_provider.dart';
import '../providers/kullanici_provider.dart';
import '../services/firebase_service.dart';
import 'ana_sayfa.dart';

class OdemeScreen extends StatefulWidget {
  final List<SepetUrun> urunler;
  final double araToplam;
  final double kargoUcreti;
  final double genelToplam;

  const OdemeScreen({
    super.key,
    required this.urunler,
    required this.araToplam,
    required this.kargoUcreti,
    required this.genelToplam,
  });

  @override
  State<OdemeScreen> createState() => _OdemeScreenState();
}

class _OdemeScreenState extends State<OdemeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _adresCtrl = TextEditingController();
  String _odemeTipi = 'havale_eft';
  bool _gonderiyor = false;

  @override
  void initState() {
    super.initState();
    final kullanici = context.read<KullaniciProvider>().kullanici;
    if (kullanici != null) {
      _adCtrl.text = kullanici['adSoyad'] ?? '';
      _telCtrl.text = kullanici['telefon'] ?? '';
      _adresCtrl.text = kullanici['adres'] ?? '';
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _telCtrl.dispose();
    _adresCtrl.dispose();
    super.dispose();
  }

  String _fmt(double f) => f
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Future<void> _siparisVer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _gonderiyor = true);

    try {
      final kullanici = context.read<KullaniciProvider>();

      for (final urun in widget.urunler) {
        await FirebaseService.siparisOlustur({
          'urunId': urun.urunId,
          'urunAdi': urun.urunAdi,
          'urunGorsel': urun.urunGorsel,
          'kullaniciId': kullanici.uid,
          'adSoyad': _adCtrl.text.trim(),
          'telefon': _telCtrl.text.trim(),
          'teslimatAdresi': _adresCtrl.text.trim(),
          'secilenBeden': urun.secilenBeden,
          'tutar': urun.toplamFiyat,
          'odemeTipi': _odemeTipi,
          'durum': 'beklemede',
        });
      }

      context.read<SepetProvider>().temizle();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B1A4A), Color(0xFFB5478A)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B1A4A).withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Siparişiniz Alındı!',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'En kısa sürede hazırlanıp\nkargoya verilecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade500, height: 1.5),
              ),
              const SizedBox(height: 24),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ana Sayfaya Dön',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      setState(() => _gonderiyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F6),
      appBar: AppBar(
        title: const Text('Sipariş Ver'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sipariş özeti
                    const Text('Sipariş Özeti',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ...widget.urunler.map((u) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(u.urunAdi,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 13)),
                                          Text(
                                              'Beden: ${u.secilenBeden} · ${u.adet} adet',
                                              style: TextStyle(
                                                  color: Colors
                                                      .grey.shade500,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${_fmt(u.toplamFiyat)} ₺',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF8B1A4A)),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Ara Toplam',
                                        style: TextStyle(
                                            color:
                                                Colors.grey.shade500,
                                            fontSize: 13)),
                                    Text('${_fmt(widget.araToplam)} ₺',
                                        style: TextStyle(
                                            color:
                                                Colors.grey.shade500,
                                            fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Kargo',
                                        style: TextStyle(
                                            color:
                                                Colors.grey.shade500,
                                            fontSize: 13)),
                                    Text(
                                        '${_fmt(widget.kargoUcreti)} ₺',
                                        style: TextStyle(
                                            color:
                                                Colors.grey.shade500,
                                            fontSize: 13)),
                                  ],
                                ),
                                const Divider(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Genel Toplam',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w800,
                                            fontSize: 15)),
                                    Text(
                                        '${_fmt(widget.genelToplam)} ₺',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w800,
                                            fontSize: 15,
                                            color:
                                                Color(0xFF8B1A4A))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text('Teslimat Bilgileri',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 12),

                    _Alan(
                      ctrl: _adCtrl,
                      label: 'Ad Soyad',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v!.isEmpty ? 'Ad Soyad gerekli' : null,
                    ),
                    const SizedBox(height: 12),
                    _Alan(
                      ctrl: _telCtrl,
                      label: 'Telefon',
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                      validator: (v) =>
                          v!.isEmpty ? 'Telefon gerekli' : null,
                    ),
                    const SizedBox(height: 12),
                    _Alan(
                      ctrl: _adresCtrl,
                      label: 'Teslimat Adresi',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                      validator: (v) =>
                          v!.isEmpty ? 'Adres gerekli' : null,
                    ),

                    const SizedBox(height: 24),
                    const Text('Ödeme Yöntemi',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _OdemeSecenegi(
                            icon: Icons.payments_outlined,
                            metin: 'Nakit',
                            secili: _odemeTipi == 'nakit',
                            onTap: () => setState(
                                () => _odemeTipi = 'nakit'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OdemeSecenegi(
                            icon: Icons.account_balance_outlined,
                            metin: 'Havale/EFT',
                            secili: _odemeTipi == 'havale_eft',
                            onTap: () =>
                                setState(() => _odemeTipi = 'havale_eft'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Havale/EFT seçilince banka bilgileri — Firestore'dan canlı
                    if (_odemeTipi == 'havale_eft')
                      StreamBuilder<Map<String, dynamic>>(
                        stream: FirebaseService.havaleBilgileriDinle(),
                        builder: (context, snapshot) {
                          final veri = snapshot.data ?? {};
                          final banka = veri['bankaAdi'] as String? ?? '';
                          final alici = veri['aliciAdSoyad'] as String? ?? '';
                          final iban = veri['iban'] as String? ?? '';

                          // IBAN gruplu format: TR00 0000 0000 ...
                          String ibanFormat(String raw) {
                            final temiz = raw.replaceAll(' ', '').toUpperCase();
                            final buf = StringBuffer();
                            for (int i = 0; i < temiz.length; i++) {
                              if (i > 0 && i % 4 == 0) buf.write(' ');
                              buf.write(temiz[i]);
                            }
                            return buf.toString();
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0E6EC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF8B1A4A).withOpacity(0.3)),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Color(0xFF8B1A4A), strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          if (banka.isEmpty && alici.isEmpty && iban.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(children: [
                                Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Havale/EFT bilgileri henüz ayarlanmamış. Admin panelden ekleyiniz.',
                                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12, height: 1.4),
                                  ),
                                ),
                              ]),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E6EC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF8B1A4A).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [
                                  Icon(Icons.account_balance_outlined, color: Color(0xFF8B1A4A), size: 16),
                                  SizedBox(width: 6),
                                  Text('Banka Bilgileri',
                                      style: TextStyle(fontWeight: FontWeight.w800,
                                          fontSize: 13, color: Color(0xFF8B1A4A))),
                                ]),
                                const SizedBox(height: 10),
                                if (banka.isNotEmpty) _BankaRow(baslik: 'Banka', deger: banka),
                                if (alici.isNotEmpty) _BankaRow(baslik: 'Ad Soyad', deger: alici),
                                if (iban.isNotEmpty) _BankaRow(baslik: 'IBAN', deger: ibanFormat(iban)),
                                const SizedBox(height: 6),
                                const Text(
                                  'Açıklama kısmına adınızı ve sipariş tutarını yazmayı unutmayın.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF8B1A4A), height: 1.4),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Sipariş ver butonu
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _gonderiyor ? null : _siparisVer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1A4A),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _gonderiyor
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Siparişi Onayla • ${_fmt(widget.genelToplam)} ₺',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Alan extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final int maxLines;

  const _Alan({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8B1A4A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF8B1A4A)),
        ),
      ),
    );
  }
}

class _OdemeSecenegi extends StatelessWidget {
  final IconData icon;
  final String metin;
  final bool secili;
  final VoidCallback onTap;

  const _OdemeSecenegi({
    required this.icon,
    required this.metin,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: secili ? const Color(0xFF8B1A4A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: secili
                ? const Color(0xFF8B1A4A)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: secili ? Colors.white : Colors.grey,
                size: 20),
            const SizedBox(width: 8),
            Text(
              metin,
              style: TextStyle(
                color: secili ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankaRow extends StatelessWidget {
  final String baslik;
  final String deger;
  const _BankaRow({required this.baslik, required this.deger});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(baslik,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B1A4A),
                    fontWeight: FontWeight.w600)),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF8B1A4A))),
          Expanded(
            child: Text(deger,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3A0A20),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}