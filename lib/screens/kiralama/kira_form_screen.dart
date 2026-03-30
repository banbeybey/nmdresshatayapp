import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/urun.dart';
import '../../providers/kullanici_provider.dart';
import '../../services/firebase_service.dart';
import 'kira_onay_screen.dart';

class KiraFormScreen extends StatefulWidget {
  final Urun urun;
  final String secilenBeden;
  const KiraFormScreen({
    super.key,
    required this.urun,
    required this.secilenBeden,
  });

  @override
  State<KiraFormScreen> createState() => _KiraFormScreenState();
}

class _KiraFormScreenState extends State<KiraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _tcCtrl = TextEditingController();
  final _adresCtrl = TextEditingController();

  String _odemeTipi = 'nakit';
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
    _tcCtrl.dispose();
    _adresCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _gonderiyor = true);

    try {
      final kullanici = context.read<KullaniciProvider>();
      final simdi = DateTime.now();
      final bitis = simdi.add(const Duration(days: 3));

      await FirebaseService.kiralamaOlustur({
        'urunId': widget.urun.id,
        'urunAdi': widget.urun.ad,
        'urunGorsel': widget.urun.gorselUrls.isNotEmpty
            ? widget.urun.gorselUrls.first
            : '',
        'kullaniciId': kullanici.uid,
        'adSoyad': _adCtrl.text.trim(),
        'telefon': _telCtrl.text.trim(),
        'tcKimlik': _tcCtrl.text.trim(),
        'teslimatAdresi': _adresCtrl.text.trim(),
        'odemeTipi': _odemeTipi,
        'kiraFiyati': widget.urun.kiraFiyati,
        'secilenBeden': widget.secilenBeden,
        'baslangicTarihi': simdi,
        'bitisTarihi': bitis,
        'durum': 'beklemede',
        'sartnameleriKabulEtti': true,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => KiraOnayScreen(
            urun: widget.urun,
            adSoyad: _adCtrl.text.trim(),
            bitisTarihi: bitis,
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
        title: const Text('Kiralama Bilgileri'),
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
                    // Ürün özeti
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E6EC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.checkroom,
                                color: Color(0xFF8B1A4A)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.urun.ad,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Beden: ${widget.secilenBeden}',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13),
                                ),
                                Text(
                                  '₺${widget.urun.kiraFiyati.toStringAsFixed(0)} / 3 Gün',
                                  style: const TextStyle(
                                    color: Color(0xFF8B1A4A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Kişisel Bilgiler',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
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
                      ctrl: _tcCtrl,
                      label: 'TC Kimlik No',
                      icon: Icons.badge_outlined,
                      keyboard: TextInputType.number,
                      maxLength: 11,
                      validator: (v) => v!.length != 11
                          ? 'TC Kimlik 11 haneli olmalı'
                          : null,
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
                    const Text(
                      'Ödeme Yöntemi',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _OdemeSecenegi(
                            icon: Icons.payments_outlined,
                            metin: 'Nakit',
                            secili: _odemeTipi == 'nakit',
                            onTap: () =>
                                setState(() => _odemeTipi = 'nakit'),
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

                    // Havale/EFT seçilince banka bilgileri — Firestore'dan canlı
                    if (_odemeTipi == 'havale_eft') ...[
                      const SizedBox(height: 12),
                      StreamBuilder<Map<String, dynamic>>(
                        stream: FirebaseService.havaleBilgileriDinle(),
                        builder: (context, snapshot) {
                          final veri = snapshot.data ?? {};
                          final banka = veri['bankaAdi'] as String? ?? '';
                          final alici = veri['aliciAdSoyad'] as String? ?? '';
                          final iban = veri['iban'] as String? ?? '';

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
                                    'Havale/EFT bilgileri henüz ayarlanmamış.',
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
                                  'Açıklama kısmına adınızı ve kira tutarını yazmayı unutmayın.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF8B1A4A), height: 1.4),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Özet kutusu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E6EC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF8B1A4A)
                                .withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _OzetSatir(
                            'Kira Ücreti (3 Gün)',
                            '₺${widget.urun.kiraFiyati.toStringAsFixed(0)}',
                          ),
                          const Divider(height: 16),
                          _OzetSatir(
                            'Toplam',
                            '₺${widget.urun.kiraFiyati.toStringAsFixed(0)}',
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Gönder butonu
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _gonderiyor ? null : _gonder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1A4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : const Text(
                          'Kiralama Talebini Gönder',
                          style: TextStyle(
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
  final int? maxLength;

  const _Alan({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      maxLength: maxLength,
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
          borderSide: const BorderSide(color: Color(0xFF8B1A4A)),
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

class _OzetSatir extends StatelessWidget {
  final String baslik;
  final String deger;
  final bool bold;

  const _OzetSatir(this.baslik, this.deger, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          baslik,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: bold ? 15 : 13,
          ),
        ),
        Text(
          deger,
          style: TextStyle(
            color: const Color(0xFF8B1A4A),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontSize: bold ? 16 : 13,
          ),
        ),
      ],
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