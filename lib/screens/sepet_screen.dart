import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/sepet_provider.dart';
import '../providers/kullanici_provider.dart';
import 'odeme_screen.dart';
import 'giris_screen.dart';

class SepetScreen extends StatelessWidget {
  const SepetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sepet = context.watch<SepetProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F6),
      appBar: AppBar(
        title: const Text('Sepetim'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          if (sepet.urunler.isNotEmpty)
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sepeti Temizle'),
                  content: const Text('Tüm ürünler sepetten kaldırılacak.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<SepetProvider>().temizle();
                        Navigator.pop(context);
                      },
                      child: const Text('Temizle',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
              child: const Text('Temizle',
                  style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: sepet.urunler.isEmpty
          ? _BosSepet()
          : _DoluSepet(sepet: sepet),
    );
  }
}

class _BosSepet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E6EC),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: Icon(Icons.shopping_bag_outlined,
                  size: 56, color: Color(0xFF8B1A4A)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sepetiniz Boş',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 8),
          Text(
            'Koleksiyonu keşfedin ve alışverişe başlayın',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DoluSepet extends StatelessWidget {
  final SepetProvider sepet;
  const _DoluSepet({required this.sepet});

  String _fmt(double f) => f
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final kullanici = context.watch<KullaniciProvider>();

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sepet.urunler.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                _SepetKalem(urun: sepet.urunler[i]),
          ),
        ),

        // Alt özet + buton
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sepet.urunler.length} ürün',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                  Text(
                    '${_fmt(sepet.araToplam)} ₺',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kargo',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                  Text('${_fmt(sepet.kargoUcreti)} ₺',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Genel Toplam',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${_fmt(sepet.genelToplam)} ₺',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8B1A4A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!kullanici.girisYapildi) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GirisScreen()));
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OdemeScreen(
                          urunler: sepet.urunler,
                          araToplam: sepet.araToplam,
                          kargoUcreti: sepet.kargoUcreti,
                          genelToplam: sepet.genelToplam,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1A4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Siparişi Tamamla • ${_fmt(sepet.genelToplam)} ₺',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SepetKalem extends StatelessWidget {
  final SepetUrun urun;
  const _SepetKalem({required this.urun});

  String _fmt(double f) => f
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final sepet = context.read<SepetProvider>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Görsel
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: urun.urunGorsel.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: urun.urunGorsel,
                    width: 72,
                    height: 84,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 72,
                      height: 84,
                      color: const Color(0xFFF0E6EC),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 72,
                      height: 84,
                      color: const Color(0xFFF0E6EC),
                      child: const Icon(Icons.checkroom,
                          color: Color(0xFF8B1A4A)),
                    ),
                  )
                : Container(
                    width: 72,
                    height: 84,
                    color: const Color(0xFFF0E6EC),
                    child: const Icon(Icons.checkroom,
                        color: Color(0xFF8B1A4A)),
                  ),
          ),
          const SizedBox(width: 12),

          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urun.urunAdi,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Beden: ${urun.secilenBeden}',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_fmt(urun.toplamFiyat)} ₺',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8B1A4A),
                      ),
                    ),
                    const Spacer(),
                    // Adet kontrolü
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E6EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => sepet.azalt(
                                urun.urunId, urun.secilenBeden),
                            icon: const Icon(Icons.remove, size: 16),
                            color: const Color(0xFF8B1A4A),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                          Text(
                            '${urun.adet}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8B1A4A),
                            ),
                          ),
                          IconButton(
                            onPressed: () => sepet.artir(
                              urun.urunId,
                              urun.secilenBeden,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            color: const Color(0xFF8B1A4A),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sil butonu
          IconButton(
            onPressed: () =>
                sepet.kaldir(urun.urunId, urun.secilenBeden),
            icon: const Icon(Icons.close_rounded,
                color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }
}