import 'package:cloud_firestore/cloud_firestore.dart';

class Urun {
  final String id;
  final String ad;
  final String aciklama;
  final double satisFiyati;
  final double kiraFiyati;
  final List<String> bedenler;
  final List<String> gorselUrls;
  final bool stokVar;
  final int stokAdedi;          // YENİ: Stok adedi
  final bool kiraldaMi;
  final DateTime? kiraBaslangic;
  final DateTime? kiraBitis;
  final DateTime createdAt;

  Urun({
    required this.id,
    required this.ad,
    required this.aciklama,
    required this.satisFiyati,
    required this.kiraFiyati,
    required this.bedenler,
    required this.gorselUrls,
    required this.stokVar,
    this.stokAdedi = 0,
    required this.kiraldaMi,
    this.kiraBaslangic,
    this.kiraBitis,
    required this.createdAt,
  });

  factory Urun.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Urun(
      id: doc.id,
      ad: d['ad'] ?? '',
      aciklama: d['aciklama'] ?? '',
      satisFiyati: (d['satisFiyati'] as num?)?.toDouble() ?? 0,
      kiraFiyati: (d['kiraFiyati'] as num?)?.toDouble() ?? 0,
      bedenler: List<String>.from(d['bedenler'] ?? []),
      gorselUrls: List<String>.from(d['gorselUrls'] ?? []),
      stokVar: d['stokVar'] ?? true,
      stokAdedi: (d['stokAdedi'] as num?)?.toInt() ?? 0,
      kiraldaMi: d['kiraldaMi'] ?? false,
      kiraBaslangic: (d['kiraBaslangic'] as Timestamp?)?.toDate(),
      kiraBitis: (d['kiraBitis'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ad': ad,
    'aciklama': aciklama,
    'satisFiyati': satisFiyati,
    'kiraFiyati': kiraFiyati,
    'bedenler': bedenler,
    'gorselUrls': gorselUrls,
    'stokVar': stokVar,
    'stokAdedi': stokAdedi,
    'kiraldaMi': kiraldaMi,
    'kiraBaslangic': kiraBaslangic != null ? Timestamp.fromDate(kiraBaslangic!) : null,
    'kiraBitis': kiraBitis != null ? Timestamp.fromDate(kiraBitis!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
