import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Kiralama {
  final String id;
  final String urunId;
  final String urunAdi;
  final String urunGorsel;
  final String kullaniciId;
  final String adSoyad;
  final String telefon;
  final String tcKimlik;
  final String teslimatAdresi;
  final String odemeTipi;
  final double depozito;
  final double kiraFiyati;
  final String secilenBeden;
  final DateTime baslangicTarihi;
  final DateTime bitisTarihi;
  final String durum;
  final bool sartnameleriKabulEtti;
  final DateTime createdAt;

  // ── Kapora alanları ──────────────────────────────────────────────────────
  final double kaporaTutar;        // Admin'in belirlediği kapora miktarı
  final String kaporaDurumu;       // 'bekliyor' | 'odendi' | 'iade_edildi' | 'kesildi'
  final String? kaporaOdemeTipi;   // 'nakit' | 'havale_eft'
  final DateTime? kaporaOdenmeTarihi;
  final String? kaporaAciklama;    // Admin notu (kesinti sebebi vb.)

  Kiralama({
    required this.id,
    required this.urunId,
    required this.urunAdi,
    required this.urunGorsel,
    required this.kullaniciId,
    required this.adSoyad,
    required this.telefon,
    required this.tcKimlik,
    required this.teslimatAdresi,
    required this.odemeTipi,
    required this.depozito,
    required this.kiraFiyati,
    required this.secilenBeden,
    required this.baslangicTarihi,
    required this.bitisTarihi,
    required this.durum,
    required this.sartnameleriKabulEtti,
    required this.createdAt,
    this.kaporaTutar = 0,
    this.kaporaDurumu = 'bekliyor',
    this.kaporaOdemeTipi,
    this.kaporaOdenmeTarihi,
    this.kaporaAciklama,
  });

  factory Kiralama.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Kiralama(
      id: doc.id,
      urunId: d['urunId'] ?? '',
      urunAdi: d['urunAdi'] ?? '',
      urunGorsel: d['urunGorsel'] ?? '',
      kullaniciId: d['kullaniciId'] ?? '',
      adSoyad: d['adSoyad'] ?? '',
      telefon: d['telefon'] ?? '',
      tcKimlik: d['tcKimlik'] ?? '',
      teslimatAdresi: d['teslimatAdresi'] ?? '',
      odemeTipi: d['odemeTipi'] ?? 'nakit',
      depozito: (d['depozito'] as num?)?.toDouble() ?? 0,
      kiraFiyati: (d['kiraFiyati'] as num?)?.toDouble() ?? 0,
      secilenBeden: d['secilenBeden'] ?? '',
      baslangicTarihi: (d['baslangicTarihi'] as Timestamp).toDate(),
      bitisTarihi: (d['bitisTarihi'] as Timestamp).toDate(),
      durum: d['durum'] ?? 'beklemede',
      sartnameleriKabulEtti: d['sartnameleriKabulEtti'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      kaporaTutar: (d['kaporaTutar'] as num?)?.toDouble() ?? 0,
      kaporaDurumu: d['kaporaDurumu'] ?? 'bekliyor',
      kaporaOdemeTipi: d['kaporaOdemeTipi'] as String?,
      kaporaOdenmeTarihi: (d['kaporaOdenmeTarihi'] as Timestamp?)?.toDate(),
      kaporaAciklama: d['kaporaAciklama'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'urunId': urunId,
    'urunAdi': urunAdi,
    'urunGorsel': urunGorsel,
    'kullaniciId': kullaniciId,
    'adSoyad': adSoyad,
    'telefon': telefon,
    'tcKimlik': tcKimlik,
    'teslimatAdresi': teslimatAdresi,
    'odemeTipi': odemeTipi,
    'depozito': depozito,
    'kiraFiyati': kiraFiyati,
    'secilenBeden': secilenBeden,
    'baslangicTarihi': Timestamp.fromDate(baslangicTarihi),
    'bitisTarihi': Timestamp.fromDate(bitisTarihi),
    'durum': durum,
    'sartnameleriKabulEtti': sartnameleriKabulEtti,
    'createdAt': Timestamp.fromDate(createdAt),
    'kaporaTutar': kaporaTutar,
    'kaporaDurumu': kaporaDurumu,
    if (kaporaOdemeTipi != null) 'kaporaOdemeTipi': kaporaOdemeTipi,
    if (kaporaOdenmeTarihi != null)
      'kaporaOdenmeTarihi': Timestamp.fromDate(kaporaOdenmeTarihi!),
    if (kaporaAciklama != null) 'kaporaAciklama': kaporaAciklama,
  };

  String get durumMetin {
    switch (durum) {
      case 'beklemede':     return 'Beklemede';
      case 'onaylandi':     return 'Onaylandı';
      case 'teslim_edildi': return 'Teslim Edildi';
      case 'iade_edildi':   return 'İade Edildi';
      default:              return durum;
    }
  }

  Color get durumRengi {
    switch (durum) {
      case 'beklemede':     return const Color(0xFFF59E0B);
      case 'onaylandi':     return const Color(0xFF3B82F6);
      case 'teslim_edildi': return const Color(0xFF10B981);
      case 'iade_edildi':   return const Color(0xFF6B7280);
      default:              return const Color(0xFF6B7280);
    }
  }

  String get kaporaDurumuMetin {
    switch (kaporaDurumu) {
      case 'bekliyor':     return 'Ödeme Bekleniyor';
      case 'odendi':       return 'Ödendi';
      case 'iade_edildi':  return 'İade Edildi';
      case 'kesildi':      return 'Kesinti Yapıldı';
      default:             return kaporaDurumu;
    }
  }

  Color get kaporaDurumuRengi {
    switch (kaporaDurumu) {
      case 'bekliyor':    return const Color(0xFFF59E0B);
      case 'odendi':      return const Color(0xFF10B981);
      case 'iade_edildi': return const Color(0xFF3B82F6);
      case 'kesildi':     return const Color(0xFFEF4444);
      default:            return const Color(0xFF6B7280);
    }
  }
}
