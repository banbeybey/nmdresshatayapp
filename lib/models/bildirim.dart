import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BildirimTipi {
  mesajGeldi,        // Mağaza mesaj gönderdi
  musteriMesaj,      // Müşteri mesaj gönderdi (admin için)
  siparisDurum,      // Sipariş durumu değişti
  kiralamaDurum,     // Kiralama durumu değişti
  kaporaBelirle,     // Admin kapora tutarı belirledi
  kaporaDurum,       // Kapora durumu değişti (ödendi/iade/kesildi)
}

class Bildirim {
  final String id;
  final String kullaniciId;  // hedef kullanıcı ('admin' veya uid)
  final BildirimTipi tip;
  final String baslik;
  final String icerik;
  final bool okundu;
  final DateTime createdAt;
  final Map<String, dynamic> ekstra; // referansId, vb.

  Bildirim({
    required this.id,
    required this.kullaniciId,
    required this.tip,
    required this.baslik,
    required this.icerik,
    required this.okundu,
    required this.createdAt,
    this.ekstra = const {},
  });

  factory Bildirim.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Bildirim(
      id: doc.id,
      kullaniciId: d['kullaniciId'] ?? '',
      tip: BildirimTipi.values.firstWhere(
        (e) => e.name == (d['tip'] ?? ''),
        orElse: () => BildirimTipi.mesajGeldi,
      ),
      baslik: d['baslik'] ?? '',
      icerik: d['icerik'] ?? '',
      okundu: d['okundu'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ekstra: Map<String, dynamic>.from(d['ekstra'] ?? {}),
    );
  }

  IconData get ikon {
    switch (tip) {
      case BildirimTipi.mesajGeldi:
        return Icons.chat_bubble_rounded;
      case BildirimTipi.musteriMesaj:
        return Icons.chat_bubble_rounded;
      case BildirimTipi.siparisDurum:
        return Icons.local_shipping;
      case BildirimTipi.kiralamaDurum:
        return Icons.checkroom;
      case BildirimTipi.kaporaBelirle:
        return Icons.account_balance_wallet_rounded;
      case BildirimTipi.kaporaDurum:
        return Icons.payments_rounded;
    }
  }
}
