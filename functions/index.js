const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
// YARDIMCI: FCM token al ve push gönder
// ─────────────────────────────────────────────────────────────────────────────
async function fcmGonder({ kullaniciId, baslik, icerik, tip = "", ekstra = {} }) {
  const db = getFirestore();

  let fcmToken = null;

  if (kullaniciId === "admin") {
    const doc = await db.collection("ayarlar").doc("admin_token").get();
    fcmToken = doc.data()?.fcmToken;
  } else {
    const doc = await db.collection("kullanicilar").doc(kullaniciId).get();
    fcmToken = doc.data()?.fcmToken;
  }

  if (!fcmToken) {
    console.log(`[FCM] Token yok: ${kullaniciId}`);
    return;
  }

  const message = {
    token: fcmToken,
    notification: { title: baslik, body: icerik },
    data: {
      tip,
      ...Object.fromEntries(
        Object.entries(ekstra).map(([k, v]) => [k, String(v)])
      ),
    },
    android: {
      priority: "high",
      notification: { channelId: "yuksek_oncelik", sound: "default" },
    },
    apns: {
      payload: { aps: { sound: "default" } },
    },
  };

  try {
    const res = await getMessaging().send(message);
    console.log(`[FCM] Gönderildi (${kullaniciId}):`, res);
  } catch (e) {
    console.error(`[FCM] Hata (${kullaniciId}):`, e.message);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1) CALLABLE — Flutter'dan manuel push (mevcut, değişmedi)
// ─────────────────────────────────────────────────────────────────────────────
exports.pushGonder = onCall(async (request) => {
  const { fcmToken, baslik, icerik, tip, ekstra } = request.data;

  if (!fcmToken || !baslik || !icerik) {
    throw new HttpsError("invalid-argument", "Eksik parametre");
  }

  const message = {
    token: fcmToken,
    notification: { title: baslik, body: icerik },
    data: {
      tip: tip ?? "",
      ...Object.fromEntries(
        Object.entries(ekstra ?? {}).map(([k, v]) => [k, String(v)])
      ),
    },
    android: {
      priority: "high",
      notification: { channelId: "yuksek_oncelik", sound: "default" },
    },
    apns: {
      payload: { aps: { sound: "default" } },
    },
  };

  try {
    const response = await getMessaging().send(message);
    console.log("[FCM V1] Gönderildi:", response);
    return { success: true };
  } catch (e) {
    console.error("[FCM V1] Hata:", e);
    throw new HttpsError("internal", e.message);
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// 2) TRIGGER — bildirimler koleksiyonuna yeni kayıt → push gönder
//    Tüm bildirim tipleri buradan geçer:
//    mesajGeldi, musteriMesaj, siparisDurum, kiralamaDurum, kaporaBelirle, kaporaDurum
// ─────────────────────────────────────────────────────────────────────────────
exports.bildirimPushGonder = onDocumentCreated(
  "bildirimler/{bildirimId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const { kullaniciId, baslik, icerik, tip, ekstra } = data;

    if (!kullaniciId || !baslik || !icerik) {
      console.log("[Trigger] Eksik alan, push atlanıyor.");
      return;
    }

    await fcmGonder({
      kullaniciId,
      baslik,
      icerik,
      tip: tip ?? "",
      ekstra: ekstra ?? {},
    });
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// 3) TRIGGER — siparisler durumu değişince müşteriye push
// ─────────────────────────────────────────────────────────────────────────────
const SIPARIS_DURUM_MESAJ = {
  hazirlaniyor:  "🔄 Siparişiniz hazırlanıyor.",
  kargoda:       "🚚 Siparişiniz kargoya verildi!",
  teslim_edildi: "✅ Siparişiniz teslim edildi.",
  iptal:         "❌ Siparişiniz iptal edildi.",
};

exports.siparisDurumPush = onDocumentUpdated(
  "siparisler/{siparisId}",
  async (event) => {
    const onceki = event.data?.before?.data();
    const sonraki = event.data?.after?.data();
    if (!onceki || !sonraki) return;

    // Durum değişmemişse çık
    if (onceki.durum === sonraki.durum) return;

    const { kullaniciId, urunAdi } = sonraki;
    const yeniDurum = sonraki.durum;
    const mesaj = SIPARIS_DURUM_MESAJ[yeniDurum];

    if (!mesaj || !kullaniciId) return;

    const db = getFirestore();

    // Firestore'a bildirim kaydet
    await db.collection("bildirimler").add({
      kullaniciId,
      tip: "siparisDurum",
      baslik: "Sipariş Güncellendi 📦",
      icerik: `${urunAdi ?? "Ürün"}: ${mesaj}`,
      okundu: false,
      ekstra: { siparisId: event.params.siparisId },
      createdAt: new Date(),
    });

    // Push gönder (bildirimPushGonder trigger'ı zaten tetiklenecek ama
    // doğrudan göndermek daha hızlı)
    await fcmGonder({
      kullaniciId,
      baslik: "Sipariş Güncellendi 📦",
      icerik: `${urunAdi ?? "Ürün"}: ${mesaj}`,
      tip: "siparisDurum",
      ekstra: { siparisId: event.params.siparisId },
    });
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// 4) TRIGGER — kiralamalar durumu değişince müşteriye push
// ─────────────────────────────────────────────────────────────────────────────
const KIRALAMA_DURUM_MESAJ = {
  onaylandi:        "✅ Kiralamanız onaylandı!",
  hazirlaniyor:     "🔄 Kıyafetiniz hazırlanıyor.",
  teslim_edildi:    "📦 Kıyafetiniz teslim edildi.",
  iade_alindi:      "🔁 İade alındı, teşekkürler!",
  iptal:            "❌ Kiralamanız iptal edildi.",
  kapora_bekleniyor:"💳 Kapora ödemenizi bekliyoruz.",
};

exports.kiralamaDurumPush = onDocumentUpdated(
  "kiralamalar/{kiralamaId}",
  async (event) => {
    const onceki = event.data?.before?.data();
    const sonraki = event.data?.after?.data();
    if (!onceki || !sonraki) return;

    if (onceki.durum === sonraki.durum) return;

    const { kullaniciId, urunAdi } = sonraki;
    const yeniDurum = sonraki.durum;
    const mesaj = KIRALAMA_DURUM_MESAJ[yeniDurum];

    if (!mesaj || !kullaniciId) return;

    const db = getFirestore();

    await db.collection("bildirimler").add({
      kullaniciId,
      tip: "kiralamaDurum",
      baslik: "Kiralama Güncellendi 👗",
      icerik: `${urunAdi ?? "Kıyafet"}: ${mesaj}`,
      okundu: false,
      ekstra: { kiralamaId: event.params.kiralamaId },
      createdAt: new Date(),
    });

    await fcmGonder({
      kullaniciId,
      baslik: "Kiralama Güncellendi 👗",
      icerik: `${urunAdi ?? "Kıyafet"}: ${mesaj}`,
      tip: "kiralamaDurum",
      ekstra: { kiralamaId: event.params.kiralamaId },
    });
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// 5) TRIGGER — mesajlar koleksiyonuna admin mesaj yazınca müşteriye push
//    mesajlar/{kullaniciId}/sohbet/{mesajId}
// ─────────────────────────────────────────────────────────────────────────────
exports.adminMesajPush = onDocumentCreated(
  "mesajlar/{kullaniciId}/sohbet/{mesajId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    // Sadece admin'in yazdığı mesajlar
    if (data.gonderen !== "admin") return;

    const kullaniciId = event.params.kullaniciId;
    const metin = data.metin ?? "";

    const db = getFirestore();

    // Aynı mesaj için tekrar bildirim oluşturma (bildirimler zaten admin_panel'den yazılıyor)
    // Burada sadece push gönder, Firestore kaydı admin_panel'de yapılıyor
    await fcmGonder({
      kullaniciId,
      baslik: "Mağazadan yeni mesaj 💬",
      icerik: metin.length > 80 ? metin.substring(0, 80) + "..." : metin,
      tip: "mesajGeldi",
    });
  }
);
