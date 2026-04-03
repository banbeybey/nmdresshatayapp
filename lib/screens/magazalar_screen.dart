import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:provider/provider.dart';
import '../providers/sepet_provider.dart';
import '../providers/kullanici_provider.dart';
import '../services/api_service.dart';
import 'giris_screen.dart';
import 'urunler_screen.dart';
import 'urun_detay_screen.dart';
import 'sepet_screen.dart';
import 'profil_screen.dart';
import 'pasta_siparis_ekrani.dart';
import 'pasa_doner_siparis_ekrani.dart';
import 'ana_sayfa.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Slug → store_id önbelleği (uygulama ömrünce geçerli)
final Map<String, int> _slugIdCache = {};
final Map<String, String> _slugCategoryCache = {};
// Splash gösterilmiş kategoriler
final Set<String> _splashGosterildi = {};
// WebViewController cache — kategori başına bir controller
// dispose()'da o kategorinin slotu temizlenir, böylece geri dönüşte
// taze yüklenme garantilenir ve buton pasifleşme sorunu olmaz.
final Map<String, WebViewController> _controllerCache = {};

class MagazalarScreen extends StatefulWidget {
  final String kategoriSlug;
  final String kategoriAdi;
  final Color renk;

  const MagazalarScreen({
    super.key,
    required this.kategoriSlug,
    required this.kategoriAdi,
    required this.renk,
  });

  @override
  State<MagazalarScreen> createState() => _MagazalarScreenState();
}

// Uygulama genelinde tek RouteObserver — main.dart'ta MaterialApp.navigatorObservers'a eklenmelidir.
// Zaten ekliyse bu satırı silersiniz; sadece bir kez tanımlanmalı.
final RouteObserver<ModalRoute<void>> magazalarRouteObserver =
    RouteObserver<ModalRoute<void>>();

class _MagazalarScreenState extends State<MagazalarScreen>
    with RouteAware {
  WebViewController? _controller;
  bool _yukleniyor = true;
  bool _ilkYukleme = true;
  int _geriyeSayim = 10;


  static const _baseHost = 'reyhanli.hataysepetim.com.tr';
  static const _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 12; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  // pasa-doner ve manav her zaman taze yüklenir (fiyat/stok değişken)
  bool get _cacheKullan =>
      widget.kategoriSlug != 'pasa-doner' &&
      widget.kategoriSlug != 'manav-taze-meyve-sebze';

  static const _hideCSS = '''
    (function() {
      var style = document.createElement('style');
      style.textContent = `
        .btn-admin-panel,
        .floating-stats,
        .leaves-container,
        .action-buttons-grid,
        .top-bar {
          display: none !important;
        }
      `;
      document.head.appendChild(style);
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteObserver'a abone ol — didPopNext için gerekli
    final route = ModalRoute.of(this.context);
    if (route != null) {
      magazalarRouteObserver.subscribe(this, route);
    }
  }

  /// Alt ekrandan (UrunDetay, GirisScreen, vb.) geri dönüldüğünde tetiklenir.
  /// Bu sayede WebView butonları her zaman sıfırlanır.
  @override
  void didPopNext() {
    _resetWebViewState();
  }

  @override
  void dispose() {
    magazalarRouteObserver.unsubscribe(this);
    // Bu kategori ekrandan çıkarken cache slotunu temizle.
    // Bir sonraki girişte sayfa taze yüklenir — buton pasifleşme olmaz.
    _controllerCache.remove(widget.kategoriSlug);
    super.dispose();
  }

  // WebView cache'den gelince onPageFinished tetiklenmez.
  // Bu yüzden her Navigator.push.then() ve didPopNext()'te çağırıyoruz.
  void _resetWebViewState() {
    if (_controller == null) return;
    _controller!.runJavaScript('''
      (function() {
        document.body.style.overflow = '';
        document.documentElement.style.overflow = '';
        ['siparisModalOverlay','donerModalOverlay'].forEach(function(id) {
          var el = document.getElementById(id);
          if (el) el.classList.remove('open');
        });
        ['loginRequiredOverlay','errorModalOverlay','misafirSorguOverlay'].forEach(function(id) {
          var el = document.getElementById(id);
          if (el) el.style.display = 'none';
        });
        // Butonları tamamen sıfırla
        document.querySelectorAll(
          '.product-add-btn, .doner-add-btn, .btn-manav-sepet, .btn-pasta-siparis-mini, .btn-doner-siparis'
        ).forEach(function(btn) {
          btn.style.pointerEvents = '';
          btn.removeAttribute('disabled');
          btn.dataset.loading = '0';
          btn.classList.remove('disabled', 'loading');
        });
        // Listener flag'ini sifirla ki yeniden kurulsun
        window.__flutterListenerInstalled = false;
        if (typeof _resetPageState === 'function') _resetPageState();
      })();
    ''');
    // Listener'i hemen yeniden kur — onPageFinished bekleme
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted || _controller == null) return;
      _controller!.runJavaScript('''
        (function() {
          if (window.__flutterListenerInstalled) return;
          window.__flutterListenerInstalled = true;
          document.addEventListener('click', function(e) {
            var sepetBtn = e.target.closest('.product-add-btn:not(.disabled)');
            if (sepetBtn) {
              e.preventDefault(); e.stopPropagation();
              var wrapper  = sepetBtn.closest('.card-wrapper');
              if (!wrapper) return;
              var link     = wrapper.querySelector('a.store-card');
              var href     = link ? link.getAttribute('href') : '';
              var urunId   = href ? (href.split('/urun/')[1] || '0') : '0';
              var nameEl   = wrapper.querySelector('.product-name');
              var priceEl  = wrapper.querySelector('.product-price');
              var imgEl    = wrapper.querySelector('.product-img-wrap img');
              var storeEl  = wrapper.querySelector('.product-store');
              var urunAdi  = nameEl  ? nameEl.textContent.trim()  : '';
              var fiyatStr = priceEl ? priceEl.textContent.replace(/[^0-9]/g, '') : '0';
              var imageUrl = imgEl   ? imgEl.src : '';
              var storeId   = wrapper.dataset.storeId   || '0';
              var storeName = storeEl ? storeEl.textContent.trim() : '';
              var storeSlug = wrapper.dataset.storeSlug || '';
              FlutterSepet.postMessage(urunId+'|'+urunAdi+'|'+fiyatStr+'|'+imageUrl+'|'+storeId+'|'+storeName+'|'+storeSlug);
              return;
            }
            var pastaBtn = e.target.closest('.btn-pasta-siparis-mini');
            if (pastaBtn) {
              e.preventDefault(); e.stopPropagation();
              var wrapper     = pastaBtn.closest('.card-wrapper');
              if (!wrapper) return;
              var productId   = pastaBtn.getAttribute('data-product-id') || '0';
              var productName = pastaBtn.getAttribute('data-product-name') || '';
              var price       = pastaBtn.getAttribute('data-price') || '0';
              var storeId     = wrapper.dataset.storeId || pastaBtn.getAttribute('data-store-id') || '0';
              var hasPorsiyon = pastaBtn.getAttribute('data-type') === 'porsiyon' ? '1' : '0';
              var minVal      = pastaBtn.getAttribute('data-min') || '1';
              var imgEl       = wrapper.querySelector('.product-img-wrap img');
              var imageUrl    = imgEl ? imgEl.src : '';
              var storeCategory = wrapper.dataset.storeCategory || '';
              var qtyInput    = wrapper.querySelector('.pasta-qty-input');
              var qty = qtyInput ? (parseFloat(qtyInput.value) || parseFloat(minVal)) : parseFloat(minVal);
              var storeName2  = (wrapper.querySelector('.product-store') || {}).textContent || '';
              var storeSlug2  = wrapper.dataset.storeSlug || '';
              FlutterPasta.postMessage(productId+'|'+productName+'|'+price+'|'+imageUrl+'|'+storeId+'|'+hasPorsiyon+'|'+qty+'|'+storeCategory+'|'+storeName2.trim()+'|'+storeSlug2);
              return;
            }
            var card = e.target.closest('a.store-card');
            if (!card) return;
            var href = card.getAttribute('href') || '';
            if (href.includes('/magaza/')) {
              e.preventDefault(); e.stopPropagation();
              var slug = href.split('/magaza/')[1].split('?')[0].split('#')[0];
              var nameEl = card.querySelector('.store-title');
              var storeName = nameEl ? nameEl.textContent.trim() : slug;
              if (slug) FlutterMagaza.postMessage(slug + '|' + storeName);
              return;
            }
            if (href.includes('/urun/')) {
              e.preventDefault(); e.stopPropagation();
              var urunId = href.split('/urun/')[1].split('?')[0].split('#')[0];
              var wrapper = card.closest('.card-wrapper') || card.parentElement;
              var storeEl = card.querySelector('.product-store');
              var storeName = storeEl ? storeEl.textContent.trim() : '';
              var storeId       = wrapper ? (wrapper.dataset.storeId || '0') : '0';
              var storeSlug     = wrapper ? (wrapper.dataset.storeSlug || '') : '';
              var storeCategory = wrapper ? (wrapper.dataset.storeCategory || '') : '';
              FlutterUrun.postMessage(urunId + '|' + storeId + '|' + storeName + '|' + storeSlug + '|' + storeCategory);
              return;
            }
          }, true);
        })();
      ''');
    });
  }

  Future<void> _baslat() async {
    if (_splashGosterildi.contains(widget.kategoriSlug)) {
      _ilkYukleme = false;
      _yukle();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final gosterildi = prefs.getStringList('splash_gosterildi') ?? [];
    if (gosterildi.contains(widget.kategoriSlug)) {
      _splashGosterildi.add(widget.kategoriSlug);
      if (mounted) setState(() => _ilkYukleme = false);
      _yukle();
      return;
    }
    _yukle();
    if (mounted && _ilkYukleme) _geriyeSayimBaslat();
  }

  void _geriyeSayimBaslat() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (!_ilkYukleme) return false;
      setState(() => _geriyeSayim--);
      if (_geriyeSayim <= 0) {
        _splashGosterildi.add(widget.kategoriSlug);
        setState(() => _ilkYukleme = false);
        SharedPreferences.getInstance().then((prefs) {
          final list = prefs.getStringList('splash_gosterildi') ?? [];
          if (!list.contains(widget.kategoriSlug)) {
            list.add(widget.kategoriSlug);
            prefs.setStringList('splash_gosterildi', list);
          }
        });
        return false;
      }
      return true;
    });
  }

  Future<void> _yukle() async {
    final token = await ApiService.getToken();
    final url = 'https://$_baseHost/${widget.kategoriSlug}-magazalari';
    final uri = token != null
        ? Uri.parse('$url?token=${Uri.encodeComponent(token)}')
        : Uri.parse(url);

    // Cache'den oku — sadece FlutterPasta kanalı kayıtlıysa kullan
    if (_cacheKullan && _controllerCache.containsKey(widget.kategoriSlug)) {
      _controller = _controllerCache[widget.kategoriSlug];
      try {
        final hasChannel = await _controller!.runJavaScriptReturningResult(
          'typeof FlutterPasta !== "undefined" ? "ok" : "missing"',
        );
        if (hasChannel.toString().contains('ok')) {
          if (token != null) await _controller!.loadRequest(uri);
          if (mounted) setState(() => _yukleniyor = false);
          return;
        }
      } catch (_) {}
      // Kanal eksik — cache geçersiz, sil ve yeniden oluştur
      _controllerCache.remove(widget.kategoriSlug);
      _controller = null;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setUserAgent(_mobileUserAgent)
      ..enableZoom(false)
      // Eski mağaza tıklama kanalı (geriye dönük uyumluluk)
      ..addJavaScriptChannel(
        'FlutterMagaza',
        onMessageReceived: (msg) async {
          final parts = msg.message.split('|');
          if (parts.length >= 2) {
            final slug      = parts[0];
            final storeName = parts[1];

            int storeId = _slugIdCache[slug] ?? 0;

            if (storeId == 0) {
              try {
                final magazalar = await ApiService.getMagazalar(
                  category: widget.kategoriSlug,
                );
                for (final m in magazalar) {
                  final mSlug = m['slug']?.toString() ?? '';
                  final mId   = int.tryParse('${m['id']}') ?? 0;
                  if (mId > 0 && mSlug.isNotEmpty) {
                    _slugIdCache[mSlug] = mId;
                    _slugCategoryCache[mSlug] = m['category']?.toString() ?? '';
                  }
                  if (mSlug == slug) storeId = mId;
                }
                if (storeId == 0) {
                  for (final m in magazalar) {
                    final mId = int.tryParse('${m['id']}') ?? 0;
                    if (mId > 0) { storeId = mId; break; }
                  }
                }
              } catch (_) {}
            }

            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UrunlerScreen(
                  magazaSlug:    slug,
                  magazaAdi:     storeName,
                  renk:          widget.renk,
                  storeId:       storeId,
                  storeCategory: _slugCategoryCache[slug] ?? '',
                ),
              ),
            ).then((_) => _resetWebViewState());
          }
        },
      )
      // Splash kapatma kanalı
      ..addJavaScriptChannel(
        'FlutterSplash',
        onMessageReceived: (_) async {
          if (mounted && _ilkYukleme) {
            _splashGosterildi.add(widget.kategoriSlug);
            setState(() => _ilkYukleme = false);
            final prefs = await SharedPreferences.getInstance();
            final list = prefs.getStringList('splash_gosterildi') ?? [];
            if (!list.contains(widget.kategoriSlug)) {
              list.add(widget.kategoriSlug);
              await prefs.setStringList('splash_gosterildi', list);
            }
          }
        },
      )
      // Sepete ekle kanalı
      ..addJavaScriptChannel(
        'FlutterSepet',
        onMessageReceived: (msg) async {
          if (!mounted) return;

          // Giriş kontrolü
          final kullanici = context.read<KullaniciProvider>().kullanici;
          if (kullanici == null) {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => const GirisScreen(),
            )).then((_) => _resetWebViewState());
            return;
          }

          // msg: "urunId|urunAdi|fiyat|imageUrl|storeId|storeName|storeSlug"
          final parts = msg.message.split('|');
          if (parts.length < 7) return;
          final urunId    = int.tryParse(parts[0]) ?? 0;
          final urunAdi   = parts[1];
          final fiyat     = double.tryParse(parts[2]) ?? 0.0;
          final imageUrl  = parts[3];
          final storeId   = int.tryParse(parts[4]) ?? 0;
          final storeName = parts[5];
          final storeSlug = parts[6];
          if (urunId == 0) return;

          final sepet = context.read<SepetProvider>();
          final yeniUrun = SepetUrun(
            urunId:    urunId,
            storeId:   storeId,
            storeName: storeName,
            storeSlug: storeSlug,
            urunAdi:   urunAdi,
            fiyat:     fiyat,
            imageUrl:  imageUrl.isNotEmpty ? imageUrl : null,
          );

          // Farklı mağazadan ürün eklenebilir — sepet_screen her mağaza için ayrı sipariş butonu gösterir
          sepet.ekle(yeniUrun);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$urunAdi sepete eklendi ✓'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF10b981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        },
      )
      // YENİ: Pasta/KG sipariş kanalı
      ..addJavaScriptChannel(
        'FlutterPasta',
        onMessageReceived: (msg) async {
          // msg: "productId|productName|price|imageUrl|storeId|hasPorsiyon|baslangicMiktar|storeCategory|storeName|storeSlug"
          final parts = msg.message.split('|');
          if (parts.length < 7) return;
          final productId       = int.tryParse(parts[0]) ?? 0;
          final productName     = parts[1];
          final price           = double.tryParse(parts[2]) ?? 0.0;
          final imageUrl        = parts[3];
          final storeId         = int.tryParse(parts[4]) ?? 0;
          final hasPorsiyon     = parts[5] == '1';
          final baslangicMiktar = double.tryParse(parts[6]) ?? 1.0;
          final storeCategory   = parts.length > 7 ? parts[7] : '';
          final storeName2      = parts.length > 8 ? parts[8] : '';
          final storeSlug2      = parts.length > 9 ? parts[9] : '';
          if (productId == 0 || !mounted) return;

          // Giriş kontrolü
          final kullanici = context.read<KullaniciProvider>().kullanici;
          if (kullanici == null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GirisScreen()))
                .then((_) => _resetWebViewState());
            return;
          }

          // Paşa Döner: native sipariş ekranına git
          if (storeCategory == 'pasa-doner') {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => PasaDonerSiparisEkrani(
                  productId: productId,
                  productName: productName,
                  unitPrice: price,
                  productImage: imageUrl,
                  storeId: storeId,
                ),
                transitionsBuilder: (_, anim, __, child) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ).then((_) => _resetWebViewState());
            return;
          }

          // Manav kategorisi: sepete ekle (Flutter provider)
          if (storeCategory == 'manav-taze-meyve-sebze') {
            final sepet = context.read<SepetProvider>();
            sepet.ekle(SepetUrun(
              urunId:    productId,
              storeId:   storeId,
              storeName: storeName2,
              storeSlug: storeSlug2,
              urunAdi:   productName,
              fiyat:     price * baslangicMiktar,
              imageUrl:  imageUrl,
              kgMiktar:  baslangicMiktar,
              kgFiyat:   price,
            ));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$productName — ${baslangicMiktar.toStringAsFixed(1)} kg sepete eklendi ✓'),
                backgroundColor: const Color(0xFF2BDC6B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ));
            }
            return;
          }

          // Pasta: sipariş ekranına git
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => PastaSiparisEkrani(
                productId:       productId,
                productName:     productName,
                kgPrice:         price,
                productImage:    imageUrl,
                storeId:         storeId,
                baslangicMiktar: baslangicMiktar,
                hasPorsiyon:     hasPorsiyon,
              ),
              transitionsBuilder: (_, anim, __, child) =>
                  SlideTransition(
                    position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
              transitionDuration: const Duration(milliseconds: 280),
            ),
          ).then((_) => _resetWebViewState());
        },
      )
      // YENİ: Ürün detay kanalı
      ..addJavaScriptChannel(
        'FlutterUrun',
        onMessageReceived: (msg) async {
          // msg: "urunId|storeId|storeName|storeSlug|storeCategory"
          final parts = msg.message.split('|');
          if (parts.length < 5) return;

          final urunId        = int.tryParse(parts[0]) ?? 0;
          final storeId       = int.tryParse(parts[1]) ?? 0;
          final storeName     = parts[2];
          final storeSlug     = parts[3];
          final storeCategory = parts[4];

          if (urunId == 0 || !mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UrunDetayScreen(
                urunId:        urunId,
                storeId:       storeId,
                storeName:     storeName,
                storeSlug:     storeSlug,
                renk:          widget.renk,
                storeCategory: storeCategory,
              ),
            ),
          ).then((_) => _resetWebViewState());
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          setState(() => _yukleniyor = true);
          _controller?.runJavaScript(_hideCSS);
          // Her yeni sayfa yüklemesinde guard'ı sıfırla;
          // onPageFinished'da listener yeniden kurulacak.
          _controller?.runJavaScript('window.__flutterListenerInstalled = false;');
        },
        onPageFinished: (_) {
          // İlk yükleme splash'ini 3 saniye göster
          if (_ilkYukleme) {
            _controller?.runJavaScript("""
              (function() {
                // Kartlar DOM'a girince splash kapat — AJAX'ı bekle
                function closeSplash() {
                  if (typeof FlutterSplash !== 'undefined') {
                    FlutterSplash.postMessage('done');
                  }
                }
                // Kartlar zaten varsa hemen kapat
                if (document.querySelector('.card-wrapper, .product-card, .store-card')) {
                  closeSplash();
                  return;
                }
                // AJAX bekliyoruz
                var obs = new MutationObserver(function(muts) {
                  for (var i = 0; i < muts.length; i++) {
                    var nodes = muts[i].addedNodes;
                    for (var j = 0; j < nodes.length; j++) {
                      var n = nodes[j];
                      if (n.nodeType === 1 && (
                        n.classList.contains('card-wrapper') ||
                        n.classList.contains('product-card') ||
                        n.classList.contains('store-card') ||
                        n.querySelector && n.querySelector('.card-wrapper, .product-card')
                      )) {
                        obs.disconnect();
                        closeSplash();
                        return;
                      }
                    }
                  }
                });
                obs.observe(document.body, { childList: true, subtree: true });
                // En fazla 6 saniye bekle, sonra yine de aç
                setTimeout(function() { obs.disconnect(); closeSplash(); }, 6000);
              })();
            """);
          }
          _controller?.runJavaScript('''
            (function() {
              var style = document.createElement('style');
              style.textContent = '.btn-admin-panel,.floating-stats,.leaves-container,.action-buttons-grid,.top-bar{display:none!important}';
              document.head.appendChild(style);
            })();


            var zone = document.getElementById('leafZone');
            if (zone) zone.innerHTML = '';

            // TEK delegation listener — guard ile korunur, birden fazla kez eklenmez.
            // forEach+addEventListener yaklaşımı kaldırıldı: geri dönüşlerde
            // listener birikimi yaşanıyor ve tıklamalar çalışmıyordu.
            if (!window.__flutterListenerInstalled) {
              window.__flutterListenerInstalled = true;
              document.addEventListener('click', function(e) {

                // --- Sepete Ekle butonu ---
                var sepetBtn = e.target.closest('.product-add-btn:not(.disabled)');
                if (sepetBtn) {
                  e.preventDefault(); e.stopPropagation();
                  var wrapper  = sepetBtn.closest('.card-wrapper');
                  if (!wrapper) return;
                  var link     = wrapper.querySelector('a.store-card');
                  var href     = link ? link.getAttribute('href') : '';
                  var urunId   = href ? (href.split('/urun/')[1] || '0') : '0';
                  var nameEl   = wrapper.querySelector('.product-name');
                  var priceEl  = wrapper.querySelector('.product-price');
                  var imgEl    = wrapper.querySelector('.product-img-wrap img');
                  var storeEl  = wrapper.querySelector('.product-store');
                  var urunAdi  = nameEl  ? nameEl.textContent.trim()  : '';
                  var fiyatStr = priceEl ? priceEl.textContent.replace(/[^0-9]/g, '') : '0';
                  var imageUrl = imgEl   ? imgEl.src : '';
                  var storeId   = wrapper.dataset.storeId   || '0';
                  var storeName = storeEl ? storeEl.textContent.trim() : '';
                  var storeSlug = wrapper.dataset.storeSlug || '';
                  FlutterSepet.postMessage(urunId+'|'+urunAdi+'|'+fiyatStr+'|'+imageUrl+'|'+storeId+'|'+storeName+'|'+storeSlug);
                  return;
                }

                // --- Pasta/KG butonu ---
                var pastaBtn = e.target.closest('.btn-pasta-siparis-mini');
                if (pastaBtn) {
                  e.preventDefault(); e.stopPropagation();
                  var wrapper     = pastaBtn.closest('.card-wrapper');
                  if (!wrapper) return;
                  var productId   = pastaBtn.getAttribute('data-product-id') || '0';
                  var productName = pastaBtn.getAttribute('data-product-name') || '';
                  var price       = pastaBtn.getAttribute('data-price') || '0';
                  var storeId     = wrapper.dataset.storeId || pastaBtn.getAttribute('data-store-id') || '0';
                  var hasPorsiyon = pastaBtn.getAttribute('data-type') === 'porsiyon' ? '1' : '0';
                  var minVal      = pastaBtn.getAttribute('data-min') || '1';
                  var imgEl       = wrapper.querySelector('.product-img-wrap img');
                  var imageUrl    = imgEl ? imgEl.src : '';
                  var storeCategory = wrapper.dataset.storeCategory || '';
                  var qtyInput    = wrapper.querySelector('.pasta-qty-input');
                  var qty = qtyInput ? (parseFloat(qtyInput.value) || parseFloat(minVal)) : parseFloat(minVal);
                  var storeName2  = (wrapper.querySelector('.product-store') || {}).textContent || '';
                  var storeSlug2  = wrapper.dataset.storeSlug || '';
                  FlutterPasta.postMessage(productId+'|'+productName+'|'+price+'|'+imageUrl+'|'+storeId+'|'+hasPorsiyon+'|'+qty+'|'+storeCategory+'|'+storeName2.trim()+'|'+storeSlug2);
                  return;
                }

                // --- Mağaza / Ürün kartı linki ---
                var card = e.target.closest('a.store-card');
                if (!card) return;
                var href = card.getAttribute('href') || '';

                if (href.includes('/magaza/')) {
                  e.preventDefault(); e.stopPropagation();
                  var slug = href.split('/magaza/')[1].split('?')[0].split('#')[0];
                  var nameEl = card.querySelector('.store-title');
                  var storeName = nameEl ? nameEl.textContent.trim() : slug;
                  if (slug) FlutterMagaza.postMessage(slug + '|' + storeName);
                  return;
                }

                if (href.includes('/urun/')) {
                  e.preventDefault(); e.stopPropagation();
                  var urunId = href.split('/urun/')[1].split('?')[0].split('#')[0];
                  var wrapper = card.closest('.card-wrapper') || card.parentElement;
                  var storeEl = card.querySelector('.product-store');
                  var storeName = storeEl ? storeEl.textContent.trim() : '';
                  var storeId       = wrapper ? (wrapper.dataset.storeId || '0') : '0';
                  var storeSlug     = wrapper ? (wrapper.dataset.storeSlug || '') : '';
                  var storeCategory = wrapper ? (wrapper.dataset.storeCategory || '') : '';
                  FlutterUrun.postMessage(urunId + '|' + storeId + '|' + storeName + '|' + storeSlug + '|' + storeCategory);
                  return;
                }
              }, true);
            }
          ''');

          // Flutter platform seviyesinde scroll → Android Surface invalide olur
          // JS window.scrollTo değil, WebViewController.scrollTo — fark bu
          Future.delayed(const Duration(milliseconds: 400), () async {
            if (!mounted) return;
            await _controller?.scrollTo(0, 1);
            await Future.delayed(const Duration(milliseconds: 80));
            if (mounted) await _controller?.scrollTo(0, 0);
          });

          setState(() => _yukleniyor = false);

          // Flutter TextureLayer hiç frame almıyor — resize event ile
          // browser'ı yeniden çizmeye zorla, TextureView yeni frame üretir
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            _controller?.runJavaScript(
              "window.dispatchEvent(new Event('resize'));"
            );
          });
        },
        onWebResourceError: (_) => setState(() => _yukleniyor = false),
        onNavigationRequest: (request) {
          final url = request.url;

          if (url.startsWith('javascript:') || url.startsWith('about:')) {
            return NavigationDecision.navigate;
          }

          // WebView içinden özel şema ile veya başarı sayfasına gidildiğinde
          // Flutter içindeki Hesabım > Siparişlerim ekranını aç.
          if (url.startsWith('hataysepetim://siparislerim')) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => AnaSayfa(
                  initialTab: 2,
                  autoOpenSiparislerim: true,
                ),
              ),
              (route) => false,
            );
            return NavigationDecision.prevent;
          }

          final uri = Uri.parse(url);

          if (uri.path == '/app/siparis-basarili.php' ||
              uri.path == '/app/havaleeftbilgileri.php') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => AnaSayfa(
                  initialTab: 2,
                  autoOpenSiparislerim: true,
                ),
              ),
              (route) => false,
            );
            return NavigationDecision.prevent;
          }

          // Farklı domain — izin ver (CDN, font vb.)
          if (uri.host.isNotEmpty && uri.host != _baseHost) {
            return NavigationDecision.navigate;
          }
          // /urun/ sayfası — Flutter handle eder (FlutterUrun kanalı)
          if (uri.path.startsWith('/urun/')) {
            return NavigationDecision.prevent;
          }
          // Diğer her şey (filtreler, kategori sayfaları, sort vb.) — navigate et
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(uri);

    // Android WebView HTTP cache etkinleştir
    final platform = _controller!.platform;
    if (platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    // Cache'e kaydet — dispose()'da bu slot silineceği için
    // bir sonraki açılışta sayfa daima taze yüklenir.
    if (_cacheKullan) {
      _controllerCache[widget.kategoriSlug] = _controller!;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.kategoriAdi,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: const [],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Consumer<SepetProvider>(
              builder: (_, sepet, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AnaSayfa(initialTab: 0)),
                      (route) => false,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.grid_view_rounded, color: Color(0xFF86868B), size: 24),
                          SizedBox(height: 4),
                          Text('Kategoriler', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF86868B))),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AnaSayfa(initialTab: 1)),
                      (route) => false,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/hataysepetim_cart_icon_colorful.svg',
                                width: 24,
                                height: 24,
                              ),
                              if (sepet.toplamAdet > 0)
                                Positioned(
                                  top: -6, right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Color(0xFFFF3B30), shape: BoxShape.circle),
                                    child: Text('${sepet.toplamAdet}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Sepetim', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF86868B))),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AnaSayfa(initialTab: 2)),
                      (route) => false,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.person_outline_rounded, color: Color(0xFF86868B), size: 24),
                          SizedBox(height: 4),
                          Text('Hesabım', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF86868B))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _controller == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
            )
          : Stack(
              children: [
                // Opacity(1.0) kendi compositing layer'ını zorla açar
                // WebView texture bu layer'da ayrı işlenir → görünür olur
                Opacity(
                  opacity: 1.0,
                  child: RefreshIndicator(
                    color: widget.renk,
                    onRefresh: () async {
                      await _controller!.reload();
                      await Future.delayed(const Duration(milliseconds: 800));
                    },
                    child: WebViewWidget(
                      controller: _controller!,
                      layoutDirection: TextDirection.ltr,
                    ),
                  ),
                ),
                if (_ilkYukleme)
                  _LoadingSplash(kategoriAdi: widget.kategoriAdi, renk: widget.renk, geriyeSayim: _geriyeSayim),
              ],
            ),
    );
  }
}

class _LoadingSplash extends StatefulWidget {
  final String kategoriAdi;
  final Color renk;
  final int geriyeSayim;
  const _LoadingSplash({required this.kategoriAdi, required this.renk, required this.geriyeSayim});

  @override
  State<_LoadingSplash> createState() => _LoadingSplashState();
}

class _LoadingSplashState extends State<_LoadingSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: const Color(0xFFF0F2F5),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dönen halka
                SizedBox(
                  width: 72, height: 72,
                  child: CircularProgressIndicator(
                    color: widget.renk,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 28),
                // Reyhanlı yazısı
                const Text(
                  'REYHANLI',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 10),
                // Kategori adı
                Text(
                  widget.kategoriAdi,
                  style: TextStyle(
                    color: widget.renk,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Alt yazı
                Text(
                  'Yükleniyor...',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                // Geri sayım
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.renk.withOpacity(0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.geriyeSayim}',
                      style: TextStyle(
                        color: widget.renk,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
