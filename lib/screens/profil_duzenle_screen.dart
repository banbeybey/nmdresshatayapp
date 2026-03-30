import 'package:flutter/material.dart';
import '../providers/kullanici_provider.dart';

class ProfilDuzenleScreen extends StatefulWidget {
  final KullaniciProvider kullanici;
  const ProfilDuzenleScreen({super.key, required this.kullanici});

  @override
  State<ProfilDuzenleScreen> createState() => _ProfilDuzenleScreenState();
}

class _ProfilDuzenleScreenState extends State<ProfilDuzenleScreen> {
  late TextEditingController _telefonCtrl;
  late TextEditingController _adresCtrl;
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    final k = widget.kullanici.kullanici;
    _telefonCtrl = TextEditingController(text: k?['telefon'] ?? '');
    _adresCtrl = TextEditingController(text: k?['adres'] ?? '');
  }

  @override
  void dispose() {
    _telefonCtrl.dispose();
    _adresCtrl.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    final telefon = _telefonCtrl.text.trim();
    final adres = _adresCtrl.text.trim();

    if (telefon.isEmpty || adres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      await widget.kullanici.profilGuncelle({
        'telefon': telefon,
        'adres': adres,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilgileriniz güncellendi ✓'),
            backgroundColor: Color(0xFF8B1A4A),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kullanici.kullanici;
    final adSoyad = k?['adSoyad'] ?? '';
    final email = k?['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bilgileri Düzenle',
            style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w800,
                fontSize: 17)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _yukleniyor ? null : _kaydet,
            child: _yukleniyor
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Color(0xFF8B1A4A), strokeWidth: 2))
                : const Text('Kaydet',
                    style: TextStyle(
                        color: Color(0xFF8B1A4A),
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sabit bilgiler (değiştirilemez) ──────────────────────────
            _SectionBaslik(title: 'Hesap Bilgileri'),
            const SizedBox(height: 10),
            _SabitAlan(
              icon: Icons.person_outline,
              label: 'Ad Soyad',
              deger: adSoyad,
            ),
            const SizedBox(height: 10),
            _SabitAlan(
              icon: Icons.email_outlined,
              label: 'E-posta',
              deger: email,
            ),

            const SizedBox(height: 24),

            // ── Düzenlenebilir alanlar ─────────────────────────────────
            _SectionBaslik(title: 'İletişim Bilgileri'),
            const SizedBox(height: 10),
            _DuzenleAlani(
              controller: _telefonCtrl,
              label: 'Telefon Numarası',
              hint: '05XX XXX XX XX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _DuzenleAlani(
              controller: _adresCtrl,
              label: 'Teslimat Adresi',
              hint: 'Açık adresinizi girin',
              icon: Icons.location_on_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // ── Kaydet Butonu ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _kaydet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1A4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _yukleniyor
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Değişiklikleri Kaydet',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 16),

            // ── Bilgi notu ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ad soyad, e-posta ve TC kimlik numarası değiştirilemez. Değişiklik için mağazayla iletişime geçin.',
                      style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBaslik extends StatelessWidget {
  final String title;
  const _SectionBaslik({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
                color: const Color(0xFF8B1A4A),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF2D1021))),
      ],
    );
  }
}

class _SabitAlan extends StatelessWidget {
  final IconData icon;
  final String label;
  final String deger;
  const _SabitAlan(
      {required this.icon, required this.label, required this.deger});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(deger,
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}

class _DuzenleAlani extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _DuzenleAlani({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D1021))),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon:
                Icon(icon, color: const Color(0xFF8B1A4A), size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF8B1A4A), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
