import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/kullanici_provider.dart';

const _p1 = Color(0xFF5A0F36);
const _p2 = Color(0xFF8B1A4A);
const _p3 = Color(0xFFB5478A);
const _bg = Color(0xFFF8F2F5);

class AyarlarScreen extends StatefulWidget {
  final KullaniciProvider kullanici;
  const AyarlarScreen({super.key, required this.kullanici});

  @override
  State<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends State<AyarlarScreen> {
  // Bildirim toggleları
  bool _siparisBildirim = true;
  bool _kiralamaBildirim = true;
  bool _kampanyaBildirim = false;

  // Şifre değiştirme
  final _mevcutSifreCtrl = TextEditingController();
  final _yeniSifreCtrl = TextEditingController();
  final _yeniSireOnayCtrl = TextEditingController();
  bool _sifreDegisiyorYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _prefferiYukle();
  }

  @override
  void dispose() {
    _mevcutSifreCtrl.dispose();
    _yeniSifreCtrl.dispose();
    _yeniSireOnayCtrl.dispose();
    super.dispose();
  }

  // ── SharedPreferences ─────────────────────────────────────────────────────
  Future<void> _prefferiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _siparisBildirim = prefs.getBool('bildirim_siparis') ?? true;
      _kiralamaBildirim = prefs.getBool('bildirim_kiralama') ?? true;
      _kampanyaBildirim = prefs.getBool('bildirim_kampanya') ?? false;
    });
  }

  Future<void> _bildirimKaydet(String anahtar, bool deger) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(anahtar, deger);
  }

  // ── Şifre Değiştir (Firebase Auth — Re-authenticate + update) ─────────────
  Future<void> _sifreDegistirSheet() async {
    _mevcutSifreCtrl.clear();
    _yeniSifreCtrl.clear();
    _yeniSireOnayCtrl.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SifreDegistirSheet(
        mevcutCtrl: _mevcutSifreCtrl,
        yeniCtrl: _yeniSifreCtrl,
        yeniOnayCtrl: _yeniSireOnayCtrl,
        onKaydet: _sifreDegistirIslem,
      ),
    );
  }

  Future<String?> _sifreDegistirIslem(String mevcut, String yeni) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return 'Oturum bulunamadı';

    try {
      // 1. Yeniden kimlik doğrula
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: mevcut,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Şifreyi güncelle
      await user.updatePassword(yeni);
      return null; // başarılı
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Mevcut şifre hatalı';
        case 'weak-password':
          return 'Yeni şifre çok zayıf (en az 6 karakter)';
        case 'requires-recent-login':
          return 'Lütfen çıkış yapıp tekrar giriş yapın';
        default:
          return e.message ?? 'Bir hata oluştu';
      }
    } catch (e) {
      return 'Bir hata oluştu: $e';
    }
  }

  // ── Hesap Sil Onay ────────────────────────────────────────────────────────
  Future<void> _hesabSilOnay() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFECEC), shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_rounded,
                  color: Colors.red, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Hesabı Sil',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.red)),
            const SizedBox(height: 8),
            const Text(
              'Hesabınız kalıcı olarak silinecek.\nSiparişler ve kiralamalar da silinir.\nBu işlem geri alınamaz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Vazgeç',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Hesap silme talebiniz iletildi. Ekibimiz sizinle iletişime geçecek.'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Evet, Sil',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
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

  // ── İçerik Sayfası Yardımcı ──────────────────────────────────────────────
  void _bilgiSayfasiAc({
    required BuildContext context,
    required String baslik,
    required IconData ikon,
    required Color ikonRenk,
    required List<Widget> maddeler,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: ikonRenk.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(ikon, color: ikonRenk, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(baslik,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF9CA3AF)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
              ),
              // İçerik
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: maddeler,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gizlilik Politikası ───────────────────────────────────────────────────
  void _gizlilikSheet(BuildContext context) {
    _bilgiSayfasiAc(
      context: context,
      baslik: 'Gizlilik Politikası',
      ikon: Icons.shield_outlined,
      ikonRenk: const Color(0xFF10B981),
      maddeler: [
        _BilgiMadde(
          no: '1',
          baslik: 'Toplanan Kişisel Veriler',
          metin:
              'NM Dress uygulaması, hizmet sunabilmek amacıyla aşağıdaki kişisel verilerinizi toplar:\n\n'
              '• Ad Soyad\n'
              '• E-posta adresi\n'
              '• Telefon numarası\n'
              '• Teslimat adresi\n'
              '• TC Kimlik Numarası (yalnızca kiralama işlemleri için)\n\n'
              'Bu veriler, sipariş ve kiralama süreçlerinin yönetimi, müşteri iletişimi ve yasal yükümlülüklerin yerine getirilmesi amacıyla kullanılır.',
        ),
        _BilgiMadde(
          no: '2',
          baslik: 'TC Kimlik Numarası Neden Alınıyor?',
          metin:
              'TC Kimlik Numarası yalnızca kiralama işlemlerinde talep edilmektedir. Bu bilgi;\n\n'
              '• Kiracının kimliğini doğrulamak,\n'
              '• Kiralanmış elbisein iade edilmemesi, hasar görmesi ya da kaybolması durumunda yasal sorumluluk oluşturabilmek,\n'
              '• İleride doğabilecek hukuki süreçlerde kiracıyı belgelemek\n\n'
              'amacıyla zorunlu tutulmaktadır. TC Kimlik Numaranız üçüncü kişilerle kesinlikle paylaşılmaz ve yalnızca şifreli sistemlerde saklanır.',
        ),
        _BilgiMadde(
          no: '3',
          baslik: 'Adres Bilgisi Neden Alınıyor?',
          metin:
              'Teslimat adresi bilgisi;\n\n'
              '• Satın alınan elbisein doğru adrese kargo ile gönderilmesi,\n'
              '• Kiralık elbisein müşteriye teslim ve iade lojistiğinin planlanması\n\n'
              'amacıyla toplanmaktadır. Adres bilginiz yalnızca kargo ve teslimat süreçlerinde kullanılır, reklam veya pazarlama amacıyla kullanılmaz.',
        ),
        _BilgiMadde(
          no: '4',
          baslik: 'Verilerin Saklanması ve Güvenliği',
          metin:
              'Kişisel verileriniz Firebase güvenlik altyapısı üzerinde şifrelenmiş biçimde saklanır. Verilerinize yalnızca yetkili personel erişebilir. Verileriniz, hizmet kapsamı dışında hiçbir üçüncü tarafla paylaşılmaz.',
        ),
        _BilgiMadde(
          no: '5',
          baslik: 'Haklarınız',
          metin:
              'KVKK kapsamında;\n\n'
              '• Verilerinizin işlenip işlenmediğini öğrenme,\n'
              '• Yanlış verilerin düzeltilmesini talep etme,\n'
              '• Verilerinizin silinmesini isteme\n\n'
              'haklarına sahipsiniz. Bu hakları kullanmak için nur8ozceliik@gmail.com adresine veya +90 541 181 25 09 numarasına ulaşabilirsiniz.',
        ),
        _IletisimKutusu(),
      ],
    );
  }

  // ── Kullanım Koşulları ────────────────────────────────────────────────────
  void _kullanimKosullariSheet(BuildContext context) {
    _bilgiSayfasiAc(
      context: context,
      baslik: 'Kullanım Koşulları',
      ikon: Icons.article_outlined,
      ikonRenk: const Color(0xFF6366F1),
      maddeler: [
        _BilgiMadde(
          no: '1',
          baslik: 'Hizmetin Kapsamı',
          metin:
              'NM Dress; abiye, gece elbisesi ve özel gün kıyafeti satışı ve kiralanması hizmeti sunan bir platformdur. Uygulama üzerinden ürünleri satın alabilir ya da belirlenen koşullar dahilinde kiralayabilirsiniz.',
        ),
        _BilgiMadde(
          no: '2',
          baslik: 'Satın Alma Koşulları ve İade Politikası',
          metin:
              'Satın alınan ürünlerde iade kabul edilmemektedir.\n\n'
              'Satın alma işlemini tamamlamadan önce ürün beden tablosunu ve açıklamasını dikkatlice incelemenizi tavsiye ederiz. Sipariş onaylandıktan sonra iptal ve iade talepları değerlendirmeye alınmaz.\n\n'
              'Ürün size teslim edildiğinde hasarlı ya da hatalı olduğunu düşünüyorsanız 24 saat içinde bizimle iletişime geçmeniz gerekmektedir.',
        ),
        _BilgiMadde(
          no: '3',
          baslik: 'Kiralama Koşulları',
          metin:
              'Kiralama süresi maksimum 3 gündür ve fiyatlandırma 3 gün üzerinden hesaplanır.\n\n'
              '• Kiralama ücreti, ürün sayfasında belirtilen "3 günlük kira bedeli" üzerindendir.\n'
              '• Ürün, anlaşılan tarihte eksiksiz ve temiz teslim edilir.\n'
              '• Kiracı, kira süresi sonunda (3. gün) elbiseyi orijinal haliyle iade etmekle yükümlüdür.\n'
              '• Elbise kir, yırtık, leke veya herhangi bir hasar içeriyorsa onarım/yenileme bedeli kiracıdan tahsil edilir.\n'
              '• Kiralama işlemi için TC Kimlik Numarası ve depozito alınmaktadır.',
        ),
        _BilgiMadde(
          no: '4',
          baslik: 'Depozito',
          metin:
              'Her kiralama işleminde iade güvencesi olarak depozito alınmaktadır. Elbise hasarsız iade edildiğinde depozito iade edilir. Hasar durumunda depozito, tamir bedelinden mahsup edilir; eksik kalan tutar ayrıca talep edilir.',
        ),
        _BilgiMadde(
          no: '5',
          baslik: 'Ödeme Koşulları',
          metin:
              'Ödeme nakit veya kredi kartı ile yapılabilir. Kiralama bedelinin tamamı, ürün teslimi sırasında veya öncesinde ödenmesi gerekmektedir. Ödeme gerçekleşmeden ürün teslim edilmez.',
        ),
        _BilgiMadde(
          no: '6',
          baslik: 'Ürün Kullanımı ve Bakım Sorumluluğu',
          metin:
              'Kiracı elbiseyi yalnızca kişisel kullanım amacıyla, sosyal etkinliklerde giyebilir. Elbiseyi üçüncü şahıslara kiraya vermek, satmak veya değiştirmek yasaktır.\n\n'
              'Kiralık elbise yıkanamaz, kimyasal temizliğe gönderilemez; bu gibi durumlar hasar sayılır.',
        ),
        _BilgiMadde(
          no: '7',
          baslik: 'Hesap Sorumluluğu',
          metin:
              'Uygulama hesabınız size özeldir. Hesap bilgilerinizi başkasıyla paylaşmayınız. Hesabınız üzerinden yapılan tüm işlemlerden siz sorumlusunuz.',
        ),
        _IletisimKutusu(),
      ],
    );
  }

  // ── Yardım ve Destek ─────────────────────────────────────────────────────
  void _yardimSheet(BuildContext context) {
    _bilgiSayfasiAc(
      context: context,
      baslik: 'Yardım ve Destek',
      ikon: Icons.help_outline_rounded,
      ikonRenk: const Color(0xFFF59E0B),
      maddeler: [
        // İletişim kartı
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A0F36), Color(0xFF9E2D6A), Color(0xFFCA6098)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('NM Dress', style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
              ]),
              const SizedBox(height: 6),
              Text('Bize ulaşmak için aşağıdaki kanalları kullanabilirsiniz.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 13,
                      height: 1.5)),
              const SizedBox(height: 16),
              _IletisimButonu(
                ikon: Icons.phone_rounded,
                etiket: 'Telefon',
                deger: '+90 541 181 25 09',
                renk: Colors.white,
              ),
              const SizedBox(height: 10),
              _IletisimButonu(
                ikon: Icons.email_outlined,
                etiket: 'E-posta',
                deger: 'nur8ozceliik@gmail.com',
                renk: Colors.white,
              ),
            ],
          ),
        ),

        _BilgiMadde(
          no: '?',
          baslik: 'Siparişim Hakkında Bilgi Almak İstiyorum',
          metin:
              'Sipariş durumunuzu "Hesabım → Siparişlerim" bölümünden anlık olarak takip edebilirsiniz. Ekranda göremediğiniz bir durum varsa telefon ya da e-posta ile bizimle iletişime geçin.',
        ),
        _BilgiMadde(
          no: '?',
          baslik: 'Kiralama İadesini Nasıl Yapacağım?',
          metin:
              'Kiralama süresi maksimum 3 gündür. Elbiseyi iade tarihinizde (3. gün) orijinal haliyle NM Dress ekibine teslim etmeniz gerekmektedir. İade tarihi ve teslim detayları için önceden bizimle iletişime geçiniz.',
        ),
        _BilgiMadde(
          no: '?',
          baslik: 'Satın Aldığım Ürünü İade Edebilir miyim?',
          metin:
              'Satın alınan ürünlerde iade kabul edilmemektedir. Ürün size ulaştığında hasar ya da hata tespit ederseniz 24 saat içinde fotoğraflı olarak iletişime geçiniz; durumunuz değerlendirilecektir.',
        ),
        _BilgiMadde(
          no: '?',
          baslik: 'Ödeme Yöntemleri',
          metin:
              'Nakit ve kredi kartı ile ödeme yapabilirsiniz. Online ödeme seçeneği için mağazamızla iletişime geçiniz.',
        ),
        _BilgiMadde(
          no: '?',
          baslik: 'Beden Seçimi Konusunda Yardım',
          metin:
              'Her ürün sayfasında beden bilgisi bulunmaktadır. Hangi bedenin size uyacağından emin olamıyorsanız +90 541 181 25 09 numarasını arayarak danışabilirsiniz.',
        ),
        _BilgiMadde(
          no: '?',
          baslik: 'Mağazayla Yazışma',
          metin:
              'Uygulama içindeki "Hesabım → Mağazayla İletişime Geç" bölümünden doğrudan bize mesaj atabilirsiniz. Mesajlarınıza en kısa sürede dönüş yapılır.',
        ),
      ],
    );
  }

  // ── Çıkış Onay ────────────────────────────────────────────────────────────
  Future<void> _cikisOnay() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: _p2.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.logout_rounded, color: _p2, size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Çıkış Yap',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('İptal',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // sheet'i kapat
                      await widget.kullanici.cikisYap();
                      if (mounted) {
                        // Ayarlar ekranını da kapat
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _p2,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Çıkış Yap',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
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
        title: const Text(
          'Ayarlar',
          style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bildirimler ──────────────────────────────────────────────
            _SectionLabel('Bildirimler'),
            _Kart(children: [
              _ToggleRow(
                icon: Icons.shopping_bag_outlined,
                iconRenk: _p2,
                label: 'Sipariş Güncellemeleri',
                aciklama: 'Sipariş durumu değiştiğinde bildir',
                deger: _siparisBildirim,
                onChanged: (v) {
                  setState(() => _siparisBildirim = v);
                  _bildirimKaydet('bildirim_siparis', v);
                },
              ),
              _KartAyirici(),
              _ToggleRow(
                icon: Icons.event_available_outlined,
                iconRenk: const Color(0xFF7B3FA0),
                label: 'Kiralama Güncellemeleri',
                aciklama: 'Kiralama durumu değiştiğinde bildir',
                deger: _kiralamaBildirim,
                onChanged: (v) {
                  setState(() => _kiralamaBildirim = v);
                  _bildirimKaydet('bildirim_kiralama', v);
                },
              ),
              _KartAyirici(),
              _ToggleRow(
                icon: Icons.local_offer_outlined,
                iconRenk: const Color(0xFFE67E22),
                label: 'Kampanya ve Fırsatlar',
                aciklama: 'Yeni koleksiyon ve indirimlerden haberdar ol',
                deger: _kampanyaBildirim,
                onChanged: (v) {
                  setState(() => _kampanyaBildirim = v);
                  _bildirimKaydet('bildirim_kampanya', v);
                },
              ),
            ]),

            const SizedBox(height: 28),

            // ── Güvenlik ─────────────────────────────────────────────────
            _SectionLabel('Güvenlik'),
            _Kart(children: [
              _MenuRow(
                icon: Icons.lock_outline_rounded,
                iconRenk: const Color(0xFF0EA5E9),
                label: 'Şifre Değiştir',
                onTap: _sifreDegistirSheet,
              ),
            ]),

            const SizedBox(height: 28),

            // ── Uygulama ─────────────────────────────────────────────────
            _SectionLabel('Uygulama'),
            _Kart(children: [
              _InfoRow(
                icon: Icons.info_outline_rounded,
                iconRenk: const Color(0xFF6B7280),
                label: 'Uygulama Sürümü',
                deger: '1.0.0',
              ),
              _KartAyirici(),
              _MenuRow(
                icon: Icons.shield_outlined,
                iconRenk: const Color(0xFF10B981),
                label: 'Gizlilik Politikası',
                onTap: () => _gizlilikSheet(context),
              ),
              _KartAyirici(),
              _MenuRow(
                icon: Icons.article_outlined,
                iconRenk: const Color(0xFF6366F1),
                label: 'Kullanım Koşulları',
                onTap: () => _kullanimKosullariSheet(context),
              ),
              _KartAyirici(),
              _MenuRow(
                icon: Icons.help_outline_rounded,
                iconRenk: const Color(0xFFF59E0B),
                label: 'Yardım ve Destek',
                onTap: () => _yardimSheet(context),
              ),
            ]),

            const SizedBox(height: 28),

            // ── Hesap İşlemleri ──────────────────────────────────────────
            _SectionLabel('Hesap İşlemleri'),
            _Kart(children: [
              _MenuRow(
                icon: Icons.logout_rounded,
                iconRenk: _p2,
                label: 'Çıkış Yap',
                onTap: _cikisOnay,
              ),
              _KartAyirici(),
              _MenuRow(
                icon: Icons.delete_forever_outlined,
                iconRenk: Colors.red,
                label: 'Hesabımı Sil',
                labelRenk: Colors.red,
                onTap: _hesabSilOnay,
              ),
            ]),

            const SizedBox(height: 36),

            // ── Alt bilgi ────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_p2, _p3],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.checkroom_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 10),
                  const Text('NM Dress',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF374151))),
                  const SizedBox(height: 4),
                  Text('Sürüm 1.0.0 • © 2026',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Şifre Değiştir Bottom Sheet ─────────────────────────────────────────────
class _SifreDegistirSheet extends StatefulWidget {
  final TextEditingController mevcutCtrl;
  final TextEditingController yeniCtrl;
  final TextEditingController yeniOnayCtrl;
  final Future<String?> Function(String mevcut, String yeni) onKaydet;

  const _SifreDegistirSheet({
    required this.mevcutCtrl,
    required this.yeniCtrl,
    required this.yeniOnayCtrl,
    required this.onKaydet,
  });

  @override
  State<_SifreDegistirSheet> createState() =>
      _SifreDegistirSheetState();
}

class _SifreDegistirSheetState extends State<_SifreDegistirSheet> {
  bool _mevcutGizli = true;
  bool _yeniGizli = true;
  bool _yukleniyor = false;
  String? _hata;

  Future<void> _kaydet() async {
    final mevcut = widget.mevcutCtrl.text.trim();
    final yeni = widget.yeniCtrl.text.trim();
    final yeniOnay = widget.yeniOnayCtrl.text.trim();

    setState(() => _hata = null);

    if (mevcut.isEmpty || yeni.isEmpty || yeniOnay.isEmpty) {
      setState(() => _hata = 'Tüm alanları doldurun');
      return;
    }
    if (yeni.length < 6) {
      setState(() => _hata = 'Yeni şifre en az 6 karakter olmalı');
      return;
    }
    if (yeni != yeniOnay) {
      setState(() => _hata = 'Yeni şifreler eşleşmiyor');
      return;
    }

    setState(() => _yukleniyor = true);
    final hata = await widget.onKaydet(mevcut, yeni);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      _hata = hata;
    });

    if (hata == null) {
      // Başarılı
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Şifreniz başarıyla değiştirildi'),
          ]),
          backgroundColor: const Color(0xFF8B1A4A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle çubuğu
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),

            // Başlık
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.lock_outline_rounded,
                    color: Color(0xFF0EA5E9), size: 22),
              ),
              const SizedBox(width: 14),
              const Text('Şifre Değiştir',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827))),
            ]),
            const SizedBox(height: 24),

            // Mevcut şifre
            _SifreAlani(
              ctrl: widget.mevcutCtrl,
              label: 'Mevcut Şifre',
              gizli: _mevcutGizli,
              onGizliToggle: () =>
                  setState(() => _mevcutGizli = !_mevcutGizli),
            ),
            const SizedBox(height: 12),

            // Yeni şifre
            _SifreAlani(
              ctrl: widget.yeniCtrl,
              label: 'Yeni Şifre',
              gizli: _yeniGizli,
              onGizliToggle: () =>
                  setState(() => _yeniGizli = !_yeniGizli),
              hint: 'En az 6 karakter',
            ),
            const SizedBox(height: 12),

            // Yeni şifre tekrar
            _SifreAlani(
              ctrl: widget.yeniOnayCtrl,
              label: 'Yeni Şifre (Tekrar)',
              gizli: _yeniGizli,
              onGizliToggle: () =>
                  setState(() => _yeniGizli = !_yeniGizli),
            ),

            // Hata mesajı
            if (_hata != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_hata!,
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 13)),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _kaydet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1A4A),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _yukleniyor
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Şifreyi Değiştir',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _SifreAlani extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool gizli;
  final VoidCallback onGizliToggle;
  final String? hint;

  const _SifreAlani({
    required this.ctrl,
    required this.label,
    required this.gizli,
    required this.onGizliToggle,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: gizli,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline, size: 19),
        suffixIcon: IconButton(
          icon: Icon(
              gizli
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19),
          onPressed: onGizliToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFF8B1A4A), width: 2)),
        labelStyle:
            const TextStyle(color: Color(0xFF9CA3AF)),
      ),
    );
  }
}

// ─── Yardımcı Widget'lar ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(children: [
        Container(
          width: 3, height: 15,
          decoration: BoxDecoration(
              color: _p2, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.3),
        ),
      ]),
    );
  }
}

class _Kart extends StatelessWidget {
  final List<Widget> children;
  const _Kart({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _KartAyirici extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 62, endIndent: 16, thickness: 0.5);
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconRenk;
  final String label;
  final String aciklama;
  final bool deger;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconRenk,
    required this.label,
    required this.aciklama,
    required this.deger,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: iconRenk.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconRenk, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF111827))),
              Text(aciklama,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
        ),
        CupertinoSwitch(
          value: deger,
          activeColor: _p2,
          onChanged: onChanged,
        ),
      ]),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconRenk;
  final String label;
  final Color? labelRenk;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.iconRenk,
    required this.label,
    this.labelRenk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textRenk = labelRenk ?? const Color(0xFF111827);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconRenk.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconRenk, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: textRenk)),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey.shade300, size: 22),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconRenk;
  final String label;
  final String deger;

  const _InfoRow({
    required this.icon,
    required this.iconRenk,
    required this.label,
    required this.deger,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: iconRenk.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconRenk, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF111827))),
        ),
        Text(deger,
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── İçerik Sayfası Yardımcı Widget'ları ────────────────────────────────────

class _BilgiMadde extends StatelessWidget {
  final String no;
  final String baslik;
  final String metin;

  const _BilgiMadde({
    required this.no,
    required this.baslik,
    required this.metin,
  });

  @override
  Widget build(BuildContext context) {
    final isQuestion = no == '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_p2, _p3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isQuestion ? '?' : no,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(metin,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IletisimKutusu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A0F36), Color(0xFF9E2D6A), Color(0xFFCA6098)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bize Ulaşın',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14)),
          const SizedBox(height: 12),
          _IletisimButonu(
            ikon: Icons.phone_rounded,
            etiket: 'Telefon',
            deger: '+90 541 181 25 09',
            renk: Colors.white,
          ),
          const SizedBox(height: 8),
          _IletisimButonu(
            ikon: Icons.email_outlined,
            etiket: 'E-posta',
            deger: 'nur8ozceliik@gmail.com',
            renk: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _IletisimButonu extends StatelessWidget {
  final IconData ikon;
  final String etiket;
  final String deger;
  final Color renk;

  const _IletisimButonu({
    required this.ikon,
    required this.etiket,
    required this.deger,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(ikon, color: renk, size: 17),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket,
              style: TextStyle(
                  color: renk.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          Text(deger,
              style: TextStyle(
                  color: renk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    ]);
  }
}
