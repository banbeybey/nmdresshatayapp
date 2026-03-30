import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/kiralama.dart';
import '../models/siparis.dart';
import 'bildirim_servisi.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── GÖRSEL YÜKLEME ─────────────────────────────────────
  static Future<String> gorselYukle(File dosya, String klasor) async {
    final ref = _storage
        .ref()
        .child(klasor)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(dosya);
    return await ref.getDownloadURL();
  }

  static Future<void> gorselSil(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  // ── KİRALAMA ───────────────────────────────────────────
  static Future<void> kiralamaOlustur(Map<String, dynamic> veri) async {
    await _db.collection('kiralama_talepleri').add({
      ...veri,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Kiralama>> kiralamalariDinle(String kullaniciId) {
    return _db
        .collection('kiralama_talepleri')
        .where('kullaniciId', isEqualTo: kullaniciId)
        .snapshots()
        .map((s) {
          final liste = s.docs.map((d) => Kiralama.fromFirestore(d)).toList();
          liste.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return liste;
        });
  }

  static Stream<List<Kiralama>> tumKiralamalariDinle() {
    return _db
        .collection('kiralama_talepleri')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Kiralama.fromFirestore(d)).toList());
  }

  static Future<void> kiralamaDurumGuncelle(
      String id, String yeniDurum, {String? kullaniciId, String? urunId}) async {
    await _db.collection('kiralama_talepleri').doc(id).update({'durum': yeniDurum});

    // Ürün kiraldaMi / stokVar otomatik güncelle
    if (urunId != null && urunId.isNotEmpty) {
      if (yeniDurum == 'onaylandi' || yeniDurum == 'teslim_edildi') {
        await _db.collection('urunler').doc(urunId).update({
          'kiraldaMi': true,
          'stokVar': false,
        });
      } else if (yeniDurum == 'iade_edildi' || yeniDurum == 'reddedildi') {
        await _db.collection('urunler').doc(urunId).update({
          'kiraldaMi': false,
          'stokVar': true,
        });
      }
    }

    if (kullaniciId != null && kullaniciId.isNotEmpty) {
      final durumMetin = _kiralamaDurumMetni(yeniDurum);
      await bildirimGonder(
        kullaniciId: kullaniciId,
        tip: 'kiralamaDurum',
        baslik: 'Kiralama Talebiniz Güncellendi 👗',
        icerik: 'Kiralama talebiniz "$durumMetin" durumuna geçti.',
        ekstra: {'kiralamaId': id, 'durum': yeniDurum},
      );
    }
  }

  static String _kiralamaDurumMetni(String durum) {
    switch (durum) {
      case 'onaylandi':     return 'Onaylandı';
      case 'reddedildi':    return 'Reddedildi';
      case 'tamamlandi':    return 'Tamamlandı';
      case 'teslim_edildi': return 'Teslim Edildi';
      case 'iade_edildi':   return 'İade Edildi';
      default:              return 'Beklemede';
    }
  }

  // ── KAPORA ─────────────────────────────────────────────

  /// Admin kapora tutarı belirler ve müşteriye bildirir
  static Future<void> kaporaBelirle({
    required String kiralamaId,
    required String kullaniciId,
    required double tutar,
  }) async {
    await _db.collection('kiralama_talepleri').doc(kiralamaId).update({
      'kaporaTutar': tutar,
      'kaporaDurumu': 'bekliyor',
      'kaporaBelirlemeTarihi': FieldValue.serverTimestamp(),
    });

    await bildirimGonder(
      kullaniciId: kullaniciId,
      tip: 'kaporaBelirle',
      baslik: 'Kapora Tutarı Belirlendi 💰',
      icerik: '₺${tutar.toStringAsFixed(0)} kapora ödemeniz bekleniyor.',
      ekstra: {'kiralamaId': kiralamaId, 'tutar': tutar},
    );
  }

  /// Admin kapora durumunu günceller (odendi / iade_edildi / kesildi)
  static Future<void> kaporaDurumGuncelle({
    required String kiralamaId,
    required String kullaniciId,
    required String yeniDurum,
    String? odemeTipi,
    String? aciklama,
  }) async {
    final Map<String, dynamic> guncelleme = {
      'kaporaDurumu': yeniDurum,
      if (aciklama != null && aciklama.isNotEmpty) 'kaporaAciklama': aciklama,
    };

    if (yeniDurum == 'odendi') {
      guncelleme['kaporaOdenmeTarihi'] = FieldValue.serverTimestamp();
      if (odemeTipi != null) guncelleme['kaporaOdemeTipi'] = odemeTipi;
    }

    await _db
        .collection('kiralama_talepleri')
        .doc(kiralamaId)
        .update(guncelleme);

    String bildirimBaslik;
    String bildirimIcerik;
    switch (yeniDurum) {
      case 'odendi':
        bildirimBaslik = 'Kapora Onaylandı ✅';
        bildirimIcerik = 'Kapora ödemeniz onaylandı. Kiralama işleminiz başladı!';
        break;
      case 'iade_edildi':
        bildirimBaslik = 'Kapora İade Edildi 🔄';
        bildirimIcerik = aciklama != null && aciklama.isNotEmpty
            ? 'Kaporanız iade edildi. Not: $aciklama'
            : 'Kaporanız iade edildi.';
        break;
      case 'kesildi':
        bildirimBaslik = 'Kaporanızdan Kesinti Yapıldı ⚠️';
        bildirimIcerik = aciklama != null && aciklama.isNotEmpty
            ? 'Kesinti sebebi: $aciklama'
            : 'Kaporanızdan kesinti yapıldı.';
        break;
      default:
        return;
    }

    await bildirimGonder(
      kullaniciId: kullaniciId,
      tip: 'kaporaDurum',
      baslik: bildirimBaslik,
      icerik: bildirimIcerik,
      ekstra: {'kiralamaId': kiralamaId, 'kaporaDurumu': yeniDurum},
    );
  }

  /// Varsayılan kapora tutarını Firestore'dan oku
  static Future<double> varsayilanKaporaTutarGetir() async {
    final doc = await _db.collection('ayarlar').doc('genel').get();
    return (doc.data()?['kaporaTutar'] as num?)?.toDouble() ?? 500.0;
  }

  /// Varsayılan kapora tutarını güncelle (admin)
  static Future<void> varsayilanKaporaTutarGuncelle(double tutar) async {
    await _db.collection('ayarlar').doc('genel').set(
      {'kaporaTutar': tutar},
      SetOptions(merge: true),
    );
  }

  // ── SİPARİŞ ────────────────────────────────────────────
  static Future<void> siparisOlustur(Map<String, dynamic> veri) async {
    await _db.collection('siparisler').add({
      ...veri,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Siparis>> siparisleriDinle(String kullaniciId) {
    return _db
        .collection('siparisler')
        .where('kullaniciId', isEqualTo: kullaniciId)
        .snapshots()
        .map((s) {
          final liste = s.docs.map((d) => Siparis.fromFirestore(d)).toList();
          liste.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return liste;
        });
  }

  static Stream<List<Siparis>> tumSiparisleriDinle() {
    return _db
        .collection('siparisler')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Siparis.fromFirestore(d)).toList());
  }

  static Future<void> siparisDurumGuncelle(
      String id, String yeniDurum, {String? kullaniciId}) async {
    await _db.collection('siparisler').doc(id).update({'durum': yeniDurum});

    if (kullaniciId != null && kullaniciId.isNotEmpty) {
      final durumMetin = _siparisDurumMetni(yeniDurum);
      await bildirimGonder(
        kullaniciId: kullaniciId,
        tip: 'siparisDurum',
        baslik: 'Siparişin Güncellendi 📦',
        icerik: 'Sipariş durumun "$durumMetin" olarak değişti.',
        ekstra: {'siparisId': id, 'durum': yeniDurum},
      );
    }
  }

  static String _siparisDurumMetni(String durum) {
    switch (durum) {
      case 'hazirlaniyor': return 'Hazırlanıyor';
      case 'kargoda': return 'Kargoda';
      case 'tamamlandi': return 'Tamamlandı';
      default: return 'Beklemede';
    }
  }

  // ── MESAJLAR ───────────────────────────────────────────
  // Kullanıcı → Admin mesaj gönderir
  // Önce üst dokümanı (mesajlar/{uid}) yazar, sonra alt koleksiyona ekler.
  // Bu sayede admin paneli mesajlar koleksiyonunu listeleyebilir.
  static Future<void> kullaniciMesajGonder({
    required String kullaniciId,
    required String kullaniciAdi,
    required String metin,
  }) async {
    final docRef = _db.collection('mesajlar').doc(kullaniciId);

    // Üst dokümanı oluştur / güncelle (admin panelinin listesi için)
    await docRef.set({
      'kullaniciId': kullaniciId,
      'kullaniciAdi': kullaniciAdi,
      'sonMesaj': metin,
      'sonMesajZamani': FieldValue.serverTimestamp(),
      'guncellendi': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Alt koleksiyona mesajı ekle
    await docRef.collection('sohbet').add({
      'metin': metin,
      'gonderen': 'kullanici',
      'gonderenAdi': kullaniciAdi,
      'createdAt': FieldValue.serverTimestamp(),
      'okundu': false,
    });

    // Admin'e bildirim gönder
    await bildirimGonder(
      kullaniciId: 'admin',
      tip: 'musteriMesaj',
      baslik: 'Müşteri Şunu Yazdı 📩',
      icerik: '$kullaniciAdi: ${metin.length > 50 ? '${metin.substring(0, 50)}…' : metin}',
      ekstra: {'kullaniciId': kullaniciId, 'kullaniciAdi': kullaniciAdi},
    );
  }

  // Admin → Kullanıcı mesaj gönderir
  static Future<void> adminMesajGonder({
    required String kullaniciId,
    required String metin,
  }) async {
    await _db
        .collection('mesajlar')
        .doc(kullaniciId)
        .collection('sohbet')
        .add({
      'metin': metin,
      'gonderen': 'admin',
      'gonderenAdi': 'Mağaza',
      'createdAt': FieldValue.serverTimestamp(),
      'okundu': false,
    });

    // Kullanıcıya bildirim gönder
    await bildirimGonder(
      kullaniciId: kullaniciId,
      tip: 'mesajGeldi',
      baslik: 'Mağaza Cevap Verdi 💬',
      icerik: metin.length > 60 ? '${metin.substring(0, 60)}…' : metin,
      ekstra: {'tip': 'mesaj'},
    );
  }

  // Mesajları okundu işaretle
  static Future<void> mesajlariOkunduIsaretle(String kullaniciId) async {
    final snap = await _db
        .collection('mesajlar')
        .doc(kullaniciId)
        .collection('sohbet')
        .where('okundu', isEqualTo: false)
        .where('gonderen', isEqualTo: 'kullanici')
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'okundu': true});
    }
  }

  // ── BİLDİRİMLER ───────────────────────────────────────
  /// Kullanıcıya bildirim gönder (Firestore kaydı + FCM V1 push)
  static Future<void> bildirimGonder({
    required String kullaniciId,
    required String tip,
    required String baslik,
    required String icerik,
    Map<String, dynamic> ekstra = const {},
  }) async {
    // 1) Firestore'a kaydet (uygulama içi bildirim listesi)
    await _db.collection('bildirimler').add({
      'kullaniciId': kullaniciId,
      'tip': tip,
      'baslik': baslik,
      'icerik': icerik,
      'okundu': false,
      'ekstra': ekstra,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2) FCM token'ı al → Cloud Function üzerinden V1 push gönder
    try {
      String? fcmToken;
      if (kullaniciId == 'admin') {
        final doc = await _db.collection('ayarlar').doc('admin_token').get();
        fcmToken = doc.data()?['fcmToken'] as String?;
      } else {
        final doc = await _db.collection('kullanicilar').doc(kullaniciId).get();
        fcmToken = doc.data()?['fcmToken'] as String?;
      }
      if (fcmToken == null || fcmToken.isEmpty) return;

      await BildirimServisi.pushGonder(
        fcmToken: fcmToken,
        baslik: baslik,
        icerik: icerik,
        tip: tip,
        ekstra: ekstra,
      );
    } catch (e) {
      debugPrint('[FCM] Push gönderilemedi: $e');
    }
  }

  /// Tüm okunmamış bildirimleri okundu yap
  static Future<void> bildirimleriOkunduIsaretle(String kullaniciId) async {
    final snap = await _db
        .collection('bildirimler')
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('okundu', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'okundu': true});
    }
  }

  /// Okunmamış bildirim sayısını stream olarak dinle
  static Stream<int> okunmamisBildirimSayisi(String kullaniciId) {
    return _db
        .collection('bildirimler')
        .where('kullaniciId', isEqualTo: kullaniciId)
        .where('okundu', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ── KULLANICI ──────────────────────────────────────────
  static Future<void> kullaniciSil(String uid) async {
    await _db.collection('kullanicilar').doc(uid).delete();
  }

  static Stream<QuerySnapshot> tumKullanicilariDinle() {
    return _db
        .collection('kullanicilar')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── AYARLAR ────────────────────────────────────────────
  static Future<Map<String, dynamic>> ayarlariGetir() async {
    final doc = await _db.collection('ayarlar').doc('genel').get();
    return doc.data() ?? {'depozito': 500.0, 'kiraSuresiGun': 3};
  }

  static Future<void> ayarlariGuncelle(Map<String, dynamic> veri) async {
    await _db.collection('ayarlar').doc('genel').set(veri, SetOptions(merge: true));
  }

  // ── HAVALE / EFT BİLGİLERİ ─────────────────────────────
  static Stream<Map<String, dynamic>> havaleBilgileriDinle() {
    return _db
        .collection('ayarlar')
        .doc('havale_bilgileri')
        .snapshots()
        .map((doc) => doc.data() ?? {
              'bankaAdi': '',
              'aliciAdSoyad': '',
              'iban': '',
            });
  }

  static Future<void> havaleBilgileriGuncelle({
    required String bankaAdi,
    required String aliciAdSoyad,
    required String iban,
  }) async {
    await _db.collection('ayarlar').doc('havale_bilgileri').set({
      'bankaAdi': bankaAdi,
      'aliciAdSoyad': aliciAdSoyad,
      'iban': iban,
      'guncellendi': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
