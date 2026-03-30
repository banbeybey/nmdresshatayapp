import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/urun.dart';

class UrunProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Urun> _urunler = [];
  bool _yukleniyor = false;
  String? _hata;

  List<Urun> get urunler => _urunler;
  bool get yukleniyor => _yukleniyor;
  String? get hata => _hata;

  List<Urun> get musaitUrunler =>
      _urunler.where((u) => u.stokVar && !u.kiraldaMi).toList();

  UrunProvider() {
    dinle();
  }

  void dinle() {
    _yukleniyor = true;
    notifyListeners();

    _db
        .collection('urunler')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _urunler = snapshot.docs.map((d) => Urun.fromFirestore(d)).toList();
        _yukleniyor = false;
        _hata = null;
        notifyListeners();
      },
      onError: (e) {
        _hata = e.toString();
        _yukleniyor = false;
        notifyListeners();
      },
    );
  }

  Future<void> urunEkle(Map<String, dynamic> veri) async {
    await _db.collection('urunler').add({
      ...veri,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> urunGuncelle(String id, Map<String, dynamic> veri) async {
    await _db.collection('urunler').doc(id).update(veri);
  }

  Future<void> urunSil(String id) async {
    await _db.collection('urunler').doc(id).delete();
  }

  Future<void> kiraDurumGuncelle(
      String urunId, bool kiraldaMi,
      {DateTime? baslangic, DateTime? bitis}) async {
    await _db.collection('urunler').doc(urunId).update({
      'kiraldaMi': kiraldaMi,
      'kiraBaslangic': baslangic != null
          ? Timestamp.fromDate(baslangic)
          : null,
      'kiraBitis': bitis != null
          ? Timestamp.fromDate(bitis)
          : null,
    });
  }
}