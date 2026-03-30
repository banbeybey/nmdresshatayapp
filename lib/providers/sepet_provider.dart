import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/urun.dart';

class SepetUrun {
  final String urunId;
  final String urunAdi;
  final String urunGorsel;
  final double fiyat;
  final String secilenBeden;
  int adet;

  SepetUrun({
    required this.urunId,
    required this.urunAdi,
    required this.urunGorsel,
    required this.fiyat,
    required this.secilenBeden,
    this.adet = 1,
  });

  double get toplamFiyat => fiyat * adet;

  Map<String, dynamic> toJson() => {
    'urunId': urunId,
    'urunAdi': urunAdi,
    'urunGorsel': urunGorsel,
    'fiyat': fiyat,
    'secilenBeden': secilenBeden,
    'adet': adet,
  };

  factory SepetUrun.fromJson(Map<String, dynamic> json) => SepetUrun(
    urunId: json['urunId'],
    urunAdi: json['urunAdi'],
    urunGorsel: json['urunGorsel'] ?? '',
    fiyat: (json['fiyat'] as num).toDouble(),
    secilenBeden: json['secilenBeden'],
    adet: json['adet'] as int,
  );
}

class SepetProvider extends ChangeNotifier {
  static const String _prefsKey = 'nm_dress_sepet';
  final List<SepetUrun> _urunler = [];
  bool _yuklendi = false;

  SepetProvider() {
    _yukle();
  }

  List<SepetUrun> get urunler => _urunler;
  int get toplamAdet => _urunler.fold(0, (s, u) => s + u.adet);
  double get araToplam => _urunler.fold(0.0, (s, u) => s + u.toplamFiyat);
  double get kargoUcreti => _urunler.isEmpty ? 0 : 60.0;
  double get genelToplam => araToplam + kargoUcreti;

  Future<void> _yukle() async {
    if (_yuklendi) return;
    _yuklendi = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefsKey);
      if (json == null) return;
      final liste = (jsonDecode(json) as List)
          .map((e) => SepetUrun.fromJson(e as Map<String, dynamic>))
          .toList();
      _urunler.addAll(liste);
      notifyListeners();
    } catch (_) {
      _yuklendi = false;
    }
  }

  Future<void> _kaydet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKey, jsonEncode(_urunler.map((u) => u.toJson()).toList()));
    } catch (_) {}
  }

  // Urun detay ekranından çağrılır
  void ekle(Urun urun, String beden) {
    final index = _urunler.indexWhere(
        (u) => u.urunId == urun.id && u.secilenBeden == beden);
    if (index >= 0) {
      _urunler[index].adet++;
    } else {
      _urunler.add(SepetUrun(
        urunId: urun.id,
        urunAdi: urun.ad,
        urunGorsel: urun.gorselUrls.isNotEmpty ? urun.gorselUrls.first : '',
        fiyat: urun.satisFiyati,
        secilenBeden: beden,
      ));
    }
    notifyListeners();
    _kaydet();
  }

  // Sepet ekranındaki "+" butonundan çağrılır
  void artir(String urunId, String beden) {
    final index = _urunler.indexWhere(
        (u) => u.urunId == urunId && u.secilenBeden == beden);
    if (index < 0) return;
    _urunler[index].adet++;
    notifyListeners();
    _kaydet();
  }

  void azalt(String urunId, String beden) {
    final index = _urunler.indexWhere(
        (u) => u.urunId == urunId && u.secilenBeden == beden);
    if (index < 0) return;
    if (_urunler[index].adet > 1) {
      _urunler[index].adet--;
    } else {
      _urunler.removeAt(index);
    }
    notifyListeners();
    _kaydet();
  }

  void kaldir(String urunId, String beden) {
    _urunler.removeWhere(
        (u) => u.urunId == urunId && u.secilenBeden == beden);
    notifyListeners();
    _kaydet();
  }

  void temizle() {
    _urunler.clear();
    notifyListeners();
    _kaydet();
  }
}
