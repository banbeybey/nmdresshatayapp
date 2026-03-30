import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

const _p2 = Color(0xFF8B1A4A);
const _p3 = Color(0xFFB5478A);

class MagazaylaYazismaScreen extends StatefulWidget {
  final String kullaniciId;
  final String kullaniciAdi;

  const MagazaylaYazismaScreen({
    super.key,
    required this.kullaniciId,
    required this.kullaniciAdi,
  });

  @override
  State<MagazaylaYazismaScreen> createState() =>
      _MagazaylaYazismaScreenState();
}

class _MagazaylaYazismaScreenState extends State<MagazaylaYazismaScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _db = FirebaseFirestore.instance;
  bool _gonderiliyor = false;

  CollectionReference get _mesajlar =>
      _db.collection('mesajlar').doc(widget.kullaniciId).collection('sohbet');

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında admin'in mesajlarını okundu say
    _mesajlariOkunduIsaretle();
  }

  Future<void> _mesajlariOkunduIsaretle() async {
    try {
      final snap = await _mesajlar
          .where('okundu', isEqualTo: false)
          .where('gonderen', isEqualTo: 'admin')
          .get();
      for (final doc in snap.docs) {
        await doc.reference.update({'okundu': true});
      }
    } catch (_) {}
  }

  Future<void> _gonder() async {
    final metin = _textCtrl.text.trim();
    if (metin.isEmpty) return;
    _textCtrl.clear();
    setState(() => _gonderiliyor = true);
    try {
      // FirebaseService üzerinden gönder → üst doküman da oluşturulur
      await FirebaseService.kullaniciMesajGonder(
        kullaniciId: widget.kullaniciId,
        kullaniciAdi: widget.kullaniciAdi,
        metin: metin,
      );
      await Future.delayed(const Duration(milliseconds: 150));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mesaj gönderilemedi')));
      }
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_p2, _p3]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('NM Dress Mağazası',
                    style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w800, fontSize: 14)),
                Text('Genellikle birkaç saat içinde yanıt verir',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mesajlar listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _mesajlar.orderBy('createdAt').snapshots(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _p2));
                }
                final mesajlar = snapshot.data?.docs ?? [];

                if (mesajlar.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_p2, _p3],
                                begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text('Mağazayla sohbet başlatın',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                                color: Color(0xFF374151))),
                        const SizedBox(height: 6),
                        Text('Sorularınızı, taleplerinizi yazın.\nEkibimiz en kısa sürede yanıtlar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.5)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: mesajlar.length,
                  itemBuilder: (_, i) {
                    final m = mesajlar[i].data() as Map<String, dynamic>;
                    final isKullanici = m['gonderen'] == 'kullanici';
                    final createdAt = m['createdAt'] as Timestamp?;
                    return _MesajBalonu(
                      metin: m['metin'] ?? '',
                      isKullanici: isKullanici,
                      createdAt: createdAt,
                    );
                  },
                );
              },
            ),
          ),

          // Yazma alanı
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 16, right: 12, top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _gonder(),
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _gonderiliyor ? null : _gonder,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _gonderiliyor ? Colors.grey.shade300 : _p2,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!_gonderiliyor)
                          BoxShadow(color: _p2.withOpacity(0.35),
                              blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: _gonderiliyor
                        ? const SizedBox(width: 20, height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

class _MesajBalonu extends StatelessWidget {
  final String metin;
  final bool isKullanici;
  final Timestamp? createdAt;

  const _MesajBalonu({
    required this.metin,
    required this.isKullanici,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    final saat = createdAt != null
        ? '${createdAt!.toDate().hour.toString().padLeft(2, '0')}:${createdAt!.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isKullanici ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isKullanici ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isKullanici) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_p2, _p3]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 14),
            ),
          ],
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isKullanici ? _p2 : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isKullanici ? 18 : 4),
                bottomRight: Radius.circular(isKullanici ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: isKullanici
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isKullanici)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('Mağaza',
                        style: TextStyle(color: _p2, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                Text(
                  metin,
                  style: TextStyle(
                    color: isKullanici ? Colors.white : const Color(0xFF111827),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(saat,
                    style: TextStyle(
                        color: isKullanici ? Colors.white60 : Colors.grey.shade400,
                        fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
