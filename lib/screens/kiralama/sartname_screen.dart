import 'package:flutter/material.dart';
import '../../models/urun.dart';
import 'kira_form_screen.dart';

class SartnameScreen extends StatefulWidget {
  final Urun urun;
  final String secilenBeden;
  const SartnameScreen({
    super.key,
    required this.urun,
    required this.secilenBeden,
  });

  @override
  State<SartnameScreen> createState() => _SartnameScreenState();
}

class _SartnameScreenState extends State<SartnameScreen> {
  bool _kabul1 = false;
  bool _kabul2 = false;
  bool _kabul3 = false;
  bool _kabul4 = false;
  bool _kabul5 = false;

  bool get _hepsiKabul =>
      _kabul1 && _kabul2 && _kabul3 && _kabul4 && _kabul5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F6),
      appBar: AppBar(
        title: const Text('Kiralama Sözleşmesi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık kutusu
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B1A4A), Color(0xFFB5478A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NM DRESS KİRALAMA SÖZLEŞMESİ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lütfen tüm maddeleri okuyun ve onaylayın',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sözleşme maddeleri
                  _SartnameMaddesi(
                    numara: '1',
                    baslik: 'Sözleşmenin Konusu',
                    icerik:
                        'Kiraya Veren, kiralanan elbiseyi belirtilen özellikler ve süre için Kiracıya kiralar. Kiracı, elbiseyi bu sözleşme süresince özenle kullanmayı kabul eder.',
                  ),
                  _SartnameMaddesi(
                    numara: '2',
                    baslik: 'Teslim ve İade',
                    icerik:
                        'Elbise teslim tarihinde Kiracıya eksiksiz ve temiz olarak teslim edilir. Kiracı, kira süresi sonunda elbiseyi aynı durumda iade etmekle yükümlüdür.',
                  ),
                  _SartnameMaddesi(
                    numara: '3',
                    baslik: 'Kiralama Bedeli ve Ödeme',
                    icerik:
                        'Kiracı, belirtilen bedeli sözleşme öncesinde veya teslim anında ödemeyi kabul eder. Ödeme yapılmadığı takdirde sözleşme geçersiz sayılır.',
                  ),
                  _SartnameMaddesi(
                    numara: '4',
                    baslik: 'Hasar ve Kayıp',
                    icerik:
                        'Kiracı, elbisenin teslim süresince oluşan zarar, kayıp ve tahribattan sorumludur. Bu tür durumlarda, tamir veya yenileme bedeli Kiracıdan talep edilir.',
                  ),
                  _SartnameMaddesi(
                    numara: '5',
                    baslik: 'Sözleşmenin Feshi',
                    icerik:
                        'Taraflardan biri sözleşme şartlarına uymazsa diğeri sözleşmeyi tek taraflı feshedebilir. Fesih halinde bedel iadesi taraflarca kararlaştırılır.',
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Onay kutuları
                  const Text(
                    'Yukarıdaki sözleşme maddelerini okudum ve kabul ediyorum:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _OnayKutusu(
                    deger: _kabul1,
                    metin: 'Sözleşmenin konusunu ve kapsamını kabul ediyorum',
                    onChanged: (v) => setState(() => _kabul1 = v!),
                  ),
                  _OnayKutusu(
                    deger: _kabul2,
                    metin: 'Teslim ve iade koşullarını kabul ediyorum',
                    onChanged: (v) => setState(() => _kabul2 = v!),
                  ),
                  _OnayKutusu(
                    deger: _kabul3,
                    metin: 'Kiralama bedeli ve ödeme koşullarını kabul ediyorum',
                    onChanged: (v) => setState(() => _kabul3 = v!),
                  ),
                  _OnayKutusu(
                    deger: _kabul4,
                    metin: 'Hasar ve kayıp sorumluluğunu kabul ediyorum',
                    onChanged: (v) => setState(() => _kabul4 = v!),
                  ),
                  _OnayKutusu(
                    deger: _kabul5,
                    metin: 'Sözleşmenin feshi koşullarını kabul ediyorum',
                    onChanged: (v) => setState(() => _kabul5 = v!),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Devam butonu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hepsiKabul
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KiraFormScreen(
                              urun: widget.urun,
                              secilenBeden: widget.secilenBeden,
                            ),
                          ),
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1A4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sözleşmeyi Kabul Et ve Devam Et',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SartnameMaddesi extends StatelessWidget {
  final String numara;
  final String baslik;
  final String icerik;

  const _SartnameMaddesi({
    required this.numara,
    required this.baslik,
    required this.icerik,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF8B1A4A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numara,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  icerik,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
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

class _OnayKutusu extends StatelessWidget {
  final bool deger;
  final String metin;
  final ValueChanged<bool?> onChanged;

  const _OnayKutusu({
    required this.deger,
    required this.metin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: deger,
      onChanged: onChanged,
      activeColor: const Color(0xFF8B1A4A),
      title: Text(metin, style: const TextStyle(fontSize: 13)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
