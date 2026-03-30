import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/kullanici_provider.dart';

class GirisScreen extends StatefulWidget {
  final bool kayitModu;
  const GirisScreen({super.key, this.kayitModu = false});

  @override
  State<GirisScreen> createState() => _GirisScreenState();
}

class _GirisScreenState extends State<GirisScreen> {
  late bool _kayitModu;
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _sifreCtrl = TextEditingController();
  final _adresCtrl = TextEditingController();
  bool _gizle = true;
  bool _yukleniyor = false;
  bool _beniHatirla = false;

  static const _prefEmail = 'saved_email';
  static const _prefSifre = 'saved_sifre';
  static const _prefHatirla = 'beni_hatirla';

  @override
  void initState() {
    super.initState();
    _kayitModu = widget.kayitModu;
    _kayitliGirisYukle();
  }

  Future<void> _kayitliGirisYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final hatirla = prefs.getBool(_prefHatirla) ?? false;
    if (hatirla) {
      setState(() {
        _beniHatirla = true;
        _emailCtrl.text = prefs.getString(_prefEmail) ?? '';
        _sifreCtrl.text = prefs.getString(_prefSifre) ?? '';
      });
    }
  }

  Future<void> _girisKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    if (_beniHatirla) {
      await prefs.setBool(_prefHatirla, true);
      await prefs.setString(_prefEmail, _emailCtrl.text.trim());
      await prefs.setString(_prefSifre, _sifreCtrl.text.trim());
    } else {
      await prefs.setBool(_prefHatirla, false);
      await prefs.remove(_prefEmail);
      await prefs.remove(_prefSifre);
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _sifreCtrl.dispose();
    _adresCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _yukleniyor = true);

    final provider = context.read<KullaniciProvider>();
    String? hata;

    if (_kayitModu) {
      hata = await provider.kayitOl(
        email: _emailCtrl.text.trim(),
        sifre: _sifreCtrl.text.trim(),
        adSoyad: _adCtrl.text.trim(),
        telefon: _telCtrl.text.trim(),
        adres: _adresCtrl.text.trim(),
      );
    } else {
      hata = await provider.girisYap(
        email: _emailCtrl.text.trim(),
        sifre: _sifreCtrl.text.trim(),
      );
      if (hata == null) await _girisKaydet();
    }

    if (!mounted) return;
    setState(() => _yukleniyor = false);

    if (hata != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hata), backgroundColor: Colors.red),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0F),
      body: Stack(
        children: [
          // Arka plan degrade topları
          Positioned(
            top: -100, right: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF8B1A4A).withOpacity(0.35),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -50,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFB5478A).withOpacity(0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Logo kutusu
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8B1A4A), Color(0xFFB5478A)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B1A4A).withOpacity(0.5),
                            blurRadius: 30, spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'NM',
                          style: TextStyle(
                            color: Colors.white, fontSize: 36,
                            fontWeight: FontWeight.w900, letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFB5478A), Color(0xFFE8A0C8)],
                      ).createShader(bounds),
                      child: const Text(
                        'NM DRESS',
                        style: TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w800, letterSpacing: 4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Kart
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30, offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kayitModu ? 'Hesap Oluştur' : 'Hoş Geldiniz',
                            style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _kayitModu
                                ? 'Bilgilerinizi doldurun'
                                : 'Hesabınıza giriş yapın',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                          const SizedBox(height: 24),

                          if (_kayitModu) ...[
                            _Alan(ctrl: _adCtrl, label: 'Ad Soyad',
                                icon: Icons.person_outline,
                                validator: (v) => v!.isEmpty ? 'Ad Soyad gerekli' : null),
                            const SizedBox(height: 12),
                            _Alan(ctrl: _telCtrl, label: 'Telefon',
                                icon: Icons.phone_outlined,
                                keyboard: TextInputType.phone,
                                validator: (v) => v!.isEmpty ? 'Telefon gerekli' : null),
                            const SizedBox(height: 12),
                            _Alan(ctrl: _adresCtrl, label: 'Adres',
                                icon: Icons.location_on_outlined, maxLines: 2,
                                validator: (v) => v!.isEmpty ? 'Adres gerekli' : null),
                            const SizedBox(height: 12),
                          ],

                          _Alan(
                            ctrl: _emailCtrl, label: 'E-posta',
                            icon: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) => !v!.contains('@') ? 'Geçerli e-posta girin' : null,
                          ),
                          const SizedBox(height: 12),

                          // Şifre alanı
                          TextFormField(
                            controller: _sifreCtrl,
                            obscureText: _gizle,
                            validator: (v) =>
                                (v?.length ?? 0) < 6 ? 'En az 6 karakter' : null,
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Color(0xFF8B1A4A), size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _gizle ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey.shade400, size: 20,
                                ),
                                onPressed: () => setState(() => _gizle = !_gizle),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF8B1A4A), width: 2),
                              ),
                              labelStyle: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),

                          // Beni Hatırla (sadece giriş modunda)
                          if (!_kayitModu) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() => _beniHatirla = !_beniHatirla),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      color: _beniHatirla
                                          ? const Color(0xFF8B1A4A)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _beniHatirla
                                            ? const Color(0xFF8B1A4A)
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: _beniHatirla
                                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Beni Hatırla',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Giriş / Kayıt butonu
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _yukleniyor ? null : _gonder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1A4A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _yukleniyor
                                  ? const SizedBox(height: 20, width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _kayitModu ? 'Kayıt Ol' : 'Giriş Yap',
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => _kayitModu = !_kayitModu),
                              child: Text(
                                _kayitModu
                                    ? 'Zaten hesabın var mı? Giriş yap'
                                    : 'Hesabın yok mu? Kayıt ol',
                                style: const TextStyle(
                                    color: Color(0xFF8B1A4A),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    required this.ctrl, required this.label, required this.icon,
    this.keyboard = TextInputType.text,
    this.validator, this.maxLines = 1,
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
        prefixIcon: Icon(icon, color: const Color(0xFF8B1A4A), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B1A4A), width: 2)),
        labelStyle: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }
}
