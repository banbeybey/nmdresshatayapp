import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bildirim_servisi.dart';

class KullaniciProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _firebaseUser;
  Map<String, dynamic>? _kullanici;
  bool _yuklendi = false;

  User? get firebaseUser => _firebaseUser;
  Map<String, dynamic>? get kullanici => _kullanici;
  bool get girisYapildi => _firebaseUser != null;
  bool get yuklendi => _yuklendi;
  bool get isAdmin => _kullanici?['isAdmin'] == true;
  String get uid => _firebaseUser?.uid ?? '';

  KullaniciProvider() {
    _auth.authStateChanges().listen(_authDegisti);
  }

  Future<void> _authDegisti(User? user) async {
    if (user != null) {
      _firebaseUser = user;
      await _kullaniciBilgisiYukle(user.uid);
      // Giriş yapıldı → FCM token'ı Firestore'a kaydet
      await BildirimServisi.tokenKaydet(user.uid);
    } else {
      // Çıkış yapıldı → token'ı temizle
      if (_firebaseUser != null) {
        await BildirimServisi.tokenTemizle(_firebaseUser!.uid);
      }
      _firebaseUser = null;
      _kullanici = null;
    }
    _yuklendi = true;
    notifyListeners();
  }

  Future<void> _kullaniciBilgisiYukle(String uid) async {
    try {
      final doc = await _db.collection('kullanicilar').doc(uid).get();
      if (doc.exists) {
        _kullanici = doc.data();
        _kullanici!['id'] = uid;
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgisi yüklenemedi: $e');
    }
  }

  Future<String?> kayitOl({
    required String email,
    required String sifre,
    required String adSoyad,
    required String telefon,
    required String adres,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: sifre,
      );
      await _db.collection('kullanicilar').doc(cred.user!.uid).set({
        'adSoyad': adSoyad,
        'telefon': telefon,
        'email': email,
        'adres': adres,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null; // başarılı
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Bu e-posta zaten kayıtlı';
      if (e.code == 'weak-password') return 'Şifre çok zayıf';
      return e.message;
    }
  }

  Future<String?> girisYap({
    required String email,
    required String sifre,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: sifre);
      return null; // başarılı
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Kullanıcı bulunamadı';
      if (e.code == 'wrong-password') return 'Şifre hatalı';
      if (e.code == 'invalid-credential') return 'E-posta veya şifre hatalı';
      return e.message;
    }
  }

  Future<void> cikisYap() async {
    await _auth.signOut();
    _kullanici = null;
    notifyListeners();
  }

  Future<void> profilGuncelle(Map<String, dynamic> veri) async {
    if (_firebaseUser == null) return;
    await _db.collection('kullanicilar').doc(_firebaseUser!.uid).update(veri);
    _kullanici = {...?_kullanici, ...veri};
    notifyListeners();
  }
}
