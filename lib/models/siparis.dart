import 'package:cloud_firestore/cloud_firestore.dart';

class Siparis {
  final String id;
  final String urunId;
  final String urunAdi;
  final String urunGorsel;
  final String kullaniciId;
  final String adSoyad;
  final String telefon;
  final String teslimatAdresi;
  final String secilenBeden;
  final double tutar;
  final String durum; // 'beklemede' | 'hazirlaniyor' | 'kargoda' | 'tamamlandi'
  final String odemeTipi; // 'kapida_odeme' | 'havale_eft' | 'kart'
  final DateTime createdAt;

  Siparis({
    required this.id,
    required this.urunId,
    required this.urunAdi,
    required this.urunGorsel,
    required this.kullaniciId,
    required this.adSoyad,
    required this.telefon,
    required this.teslimatAdresi,
    required this.secilenBeden,
    required this.tutar,
    required this.durum,
    required this.odemeTipi,
    required this.createdAt,
  });

  factory Siparis.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Siparis(
      id: doc.id,
      urunId: d['urunId'] ?? '',
      urunAdi: d['urunAdi'] ?? '',
      urunGorsel: d['urunGorsel'] ?? '',
      kullaniciId: d['kullaniciId'] ?? '',
      adSoyad: d['adSoyad'] ?? '',
      telefon: d['telefon'] ?? '',
      teslimatAdresi: d['teslimatAdresi'] ?? '',
      secilenBeden: d['secilenBeden'] ?? '',
      tutar: (d['tutar'] as num?)?.toDouble() ?? 0,
      durum: d['durum'] ?? 'beklemede',
      odemeTipi: d['odemeTipi'] ?? 'kapida_odeme',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'urunId': urunId,
    'urunAdi': urunAdi,
    'urunGorsel': urunGorsel,
    'kullaniciId': kullaniciId,
    'adSoyad': adSoyad,
    'telefon': telefon,
    'teslimatAdresi': teslimatAdresi,
    'secilenBeden': secilenBeden,
    'tutar': tutar,
    'durum': durum,
    'odemeTipi': odemeTipi,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  String get durumMetin {
    switch (durum) {
      case 'hazirlaniyor': return 'Hazırlanıyor';
      case 'kargoda': return 'Kargoda';
      case 'tamamlandi': return 'Tamamlandı';
      default: return 'Beklemede';
    }
  }
}