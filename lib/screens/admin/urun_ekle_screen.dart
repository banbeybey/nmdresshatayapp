import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/urun.dart';
import '../../providers/urun_provider.dart';
import '../../services/firebase_service.dart';

// ── Renkler ───────────────────────────────────────────────────────────────────
const _primary   = Color(0xFF9B1F5C);
const _primaryDk = Color(0xFF6D1240);
const _accent    = Color(0xFFFF6B9D);
const _bg        = Color(0xFFFDF5F9);
const _rose50    = Color(0xFFFFF1F7);
const _rose100   = Color(0xFFFFE4EF);
const _rose200   = Color(0xFFFFBDD6);

class UrunEkleScreen extends StatefulWidget {
  final Urun? duzenlenecekUrun;
  const UrunEkleScreen({super.key, this.duzenlenecekUrun});

  @override
  State<UrunEkleScreen> createState() => _UrunEkleScreenState();
}

class _UrunEkleScreenState extends State<UrunEkleScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _adCtrl         = TextEditingController();
  final _aciklamaCtrl   = TextEditingController();
  final _kiraFiyatiCtrl = TextEditingController();
  final _bedenCtrl      = TextEditingController();
  final _stokAdediCtrl  = TextEditingController(text: '1');

  List<String> _bedenler         = [];
  List<String> _mevcutGorselUrls = [];
  List<File>   _yeniGorseller    = [];
  bool _stokVar    = true;
  bool _yukleniyor = false;

  bool get _duzenlemeModu => widget.duzenlenecekUrun != null;

  @override
  void initState() {
    super.initState();
    if (_duzenlemeModu) {
      final urun = widget.duzenlenecekUrun!;
      _adCtrl.text         = urun.ad;
      _aciklamaCtrl.text   = urun.aciklama;
      _kiraFiyatiCtrl.text = urun.kiraFiyati.toStringAsFixed(0);
      _stokAdediCtrl.text  = urun.stokAdedi.toString();
      _bedenler            = List.from(urun.bedenler);
      _mevcutGorselUrls    = List.from(urun.gorselUrls);
      _stokVar             = urun.stokVar;
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _aciklamaCtrl.dispose();
    _kiraFiyatiCtrl.dispose();
    _bedenCtrl.dispose();
    _stokAdediCtrl.dispose();
    super.dispose();
  }

  Future<void> _gorselSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() =>
          _yeniGorseller.addAll(picked.map((x) => File(x.path)).toList()));
    }
  }

  void _bedenEkle() {
    final beden = _bedenCtrl.text.trim().toUpperCase();
    if (beden.isEmpty || _bedenler.contains(beden)) return;
    setState(() {
      _bedenler.add(beden);
      _bedenCtrl.clear();
    });
  }

  void _stokArttir() {
    final mevcut = int.tryParse(_stokAdediCtrl.text) ?? 0;
    setState(() {
      _stokAdediCtrl.text = (mevcut + 1).toString();
      _stokVar = true;
    });
  }

  void _stokAzalt() {
    final mevcut = int.tryParse(_stokAdediCtrl.text) ?? 0;
    if (mevcut <= 0) return;
    setState(() {
      _stokAdediCtrl.text = (mevcut - 1).toString();
      if (mevcut - 1 == 0) _stokVar = false;
    });
  }

  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _yukleniyor = true);

    try {
      final yeniUrls = <String>[];
      for (final dosya in _yeniGorseller) {
        final url = await FirebaseService.gorselYukle(dosya, 'urunler');
        yeniUrls.add(url);
      }
      final tumGorselUrls = [..._mevcutGorselUrls, ...yeniUrls];
      final stokAdedi     = int.tryParse(_stokAdediCtrl.text) ?? 0;

      final veri = {
        'ad':          _adCtrl.text.trim(),
        'aciklama':    _aciklamaCtrl.text.trim(),
        'satisFiyati': 0.0,
        'kiraFiyati':  double.tryParse(_kiraFiyatiCtrl.text) ?? 0,
        'bedenler':    _bedenler,
        'gorselUrls':  tumGorselUrls,
        'stokVar':     stokAdedi > 0,
        'stokAdedi':   stokAdedi,
        'kiraldaMi':   _duzenlemeModu ? widget.duzenlenecekUrun!.kiraldaMi : false,
      };

      if (_duzenlemeModu) {
        await context.read<UrunProvider>().urunGuncelle(widget.duzenlenecekUrun!.id, veri);
      } else {
        await context.read<UrunProvider>().urunEkle(veri);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 8),
          Text(_duzenlemeModu ? 'Ürün güncellendi!' : 'Ürün eklendi!'),
        ]),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      setState(() => _yukleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stokAdet = int.tryParse(_stokAdediCtrl.text) ?? 0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          _duzenlemeModu ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _rose200.withOpacity(0.5)),
        ),
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
                    // ── Ürün Görselleri ──────────────────────────────────
                    _SeksiyonBaslik(
                        icon: Icons.photo_library_rounded,
                        baslik: 'Ürün Görselleri'),
                    const SizedBox(height: 14),

                    // Büyütülmüş görsel listesi — yükseklik 160 → 200
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Mevcut görseller
                          ..._mevcutGorselUrls.asMap().entries.map((e) =>
                              _GorselKutu(
                                child: Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(e.value,
                                        width: 130, height: 160, fit: BoxFit.cover),
                                  ),
                                  _SilButonu(onTap: () => setState(
                                      () => _mevcutGorselUrls.removeAt(e.key))),
                                ]),
                              )),
                          // Yeni görseller
                          ..._yeniGorseller.asMap().entries.map((e) =>
                              _GorselKutu(
                                child: Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(e.value,
                                        width: 130, height: 160, fit: BoxFit.cover),
                                  ),
                                  _SilButonu(onTap: () => setState(
                                      () => _yeniGorseller.removeAt(e.key))),
                                ]),
                              )),
                          // Görsel ekle butonu
                          _GorselKutu(
                            child: GestureDetector(
                              onTap: _gorselSec,
                              child: Container(
                                width: 130, height: 160,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [_rose50, _rose100]),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: _rose200, width: 1.5,
                                      style: BorderStyle.solid),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        color: _primary.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add_photo_alternate_rounded,
                                          color: _primary, size: 26),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text('Görsel Ekle',
                                        style: TextStyle(
                                            color: _primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text('Galerinizden seçin',
                                        style: TextStyle(
                                            color: _primary.withOpacity(0.55),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Ürün Bilgileri ───────────────────────────────────
                    _SeksiyonBaslik(
                        icon: Icons.info_outline_rounded,
                        baslik: 'Ürün Bilgileri'),
                    const SizedBox(height: 14),

                    _Alan(
                        ctrl: _adCtrl,
                        label: 'Ürün Adı',
                        icon: Icons.checkroom_outlined,
                        validator: (v) => v!.isEmpty ? 'Ürün adı gerekli' : null),
                    const SizedBox(height: 12),
                    _Alan(
                        ctrl: _aciklamaCtrl,
                        label: 'Açıklama',
                        icon: Icons.description_outlined,
                        maxLines: 3),
                    const SizedBox(height: 12),
                    _Alan(
                      ctrl: _kiraFiyatiCtrl,
                      label: 'Kira Fiyatı (₺) / 3 Gün',
                      icon: Icons.event_available_outlined,
                      keyboard: TextInputType.number,
                      validator: (v) =>
                          v!.isEmpty ? 'Kira fiyatı gerekli' : null,
                    ),

                    const SizedBox(height: 28),

                    // ── Stok Yönetimi ────────────────────────────────────
                    _SeksiyonBaslik(
                        icon: Icons.inventory_2_rounded,
                        baslik: 'Stok Yönetimi'),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _rose200.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                              color: _primary.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_rose100, _rose200]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: _primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: Text('Stok Adedi',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF1A1A1A))),
                            ),
                            const SizedBox(width: 8),
                            // Azalt
                            _StokBtn(
                                icon: Icons.remove_rounded,
                                onTap: _stokAzalt,
                                aktif: stokAdet > 0),
                            const SizedBox(width: 8),
                            // Sayı
                            SizedBox(
                              width: 56,
                              child: TextFormField(
                                controller: _stokAdediCtrl,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                onChanged: (v) {
                                  final adet = int.tryParse(v) ?? 0;
                                  setState(() => _stokVar = adet > 0);
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: _rose50,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: _primary, width: 2)),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Color(0xFF1A1A1A)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Arttır
                            _StokBtn(
                                icon: Icons.add_rounded,
                                onTap: _stokArttir,
                                aktif: true),
                          ]),
                          const SizedBox(height: 14),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 11, horizontal: 14),
                            decoration: BoxDecoration(
                              color: _stokVar
                                  ? const Color(0xFFF0FDF4)
                                  : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _stokVar
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(children: [
                              Icon(
                                _stokVar
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: _stokVar
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _stokVar
                                    ? 'Ürün kiralamaya açık görünüyor'
                                    : 'Ürün müsait değil görünüyor',
                                style: TextStyle(
                                  color: _stokVar
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Bedenler ─────────────────────────────────────────
                    _SeksiyonBaslik(
                        icon: Icons.straighten_rounded, baslik: 'Bedenler'),
                    const SizedBox(height: 14),

                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bedenCtrl,
                          decoration: InputDecoration(
                            hintText: 'Örn: 36, 38, XL',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.normal),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: _primary)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          onFieldSubmitted: (_) => _bedenEkle(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _bedenEkle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_primary, _accent]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: _primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: const Text('+ Ekle',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ),
                      ),
                    ]),

                    if (_bedenler.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _bedenler.map((b) => GestureDetector(
                          onTap: () => setState(() => _bedenler.remove(b)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_rose100, _rose200]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _rose200),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(b,
                                  style: const TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13)),
                              const SizedBox(width: 5),
                              const Icon(Icons.close_rounded,
                                  color: _primary, size: 14),
                            ]),
                          ),
                        )).toList(),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Kaydet Butonu ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, -4))
                ],
              ),
              child: GestureDetector(
                onTap: _yukleniyor ? null : _kaydet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: _yukleniyor
                        ? LinearGradient(
                            colors: [Colors.grey.shade300, Colors.grey.shade300])
                        : const LinearGradient(
                            colors: [_primaryDk, _primary, _accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _yukleniyor
                        ? []
                        : [
                            BoxShadow(
                                color: _primary.withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 5))
                          ],
                  ),
                  child: Center(
                    child: _yukleniyor
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              _duzenlemeModu
                                  ? Icons.save_rounded
                                  : Icons.add_circle_rounded,
                              color: Colors.white, size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _duzenlemeModu
                                  ? 'Değişiklikleri Kaydet'
                                  : 'Ürünü Ekle',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2),
                            ),
                          ]),
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

// ── Yardımcı Widgetler ────────────────────────────────────────────────────────

class _SeksiyonBaslik extends StatelessWidget {
  final IconData icon;
  final String baslik;
  const _SeksiyonBaslik({required this.icon, required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primary, _accent]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
      const SizedBox(width: 10),
      Text(baslik,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF1A1A1A))),
    ]);
  }
}

class _GorselKutu extends StatelessWidget {
  final Widget child;
  const _GorselKutu({required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(right: 12), child: child);
}

class _SilButonu extends StatelessWidget {
  final VoidCallback onTap;
  const _SilButonu({required this.onTap});

  @override
  Widget build(BuildContext context) => Positioned(
        top: 6, right: 6,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2), blurRadius: 4)
              ],
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
          ),
        ),
      );
}

class _StokBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool aktif;
  const _StokBtn({required this.icon, required this.onTap, required this.aktif});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aktif ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: aktif
              ? const LinearGradient(colors: [_primary, _accent])
              : null,
          color: aktif ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow: aktif
              ? [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Icon(icon,
            color: aktif ? Colors.white : Colors.grey.shade400, size: 20),
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
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary, size: 20),
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
