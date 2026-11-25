// G1 kâhini: görüntüleyici kuralları (js/goruntuleyici.js, js/ayrinti.js, js/hikaye.js, js/koleksiyon.js,
// js/bildirim.js, js/karsilastir.js, js/keskin.js, js/ikonografi.js) canlı sitenin kendi modülleriyle.
//
// Çıktı klasörü (varsayılan Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/goruntuleyici):
//   - cevaplar.json: canlı siteden alınan beklenen sonuçlar
//   - eser_ayrintilari.json, eser_hikayeleri.json, eser_notlari.json, tanima_notlari.json, ikonografi.json
//
//   node Testler/kahin/goruntuleyici.mjs [klasör]
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const { chromium } = createRequire(import.meta.url)('playwright');

const klasor = process.argv[2] || 'Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/goruntuleyici';
const DOSYALAR = [
  'eser_ayrintilari.json',
  'eser_hikayeleri.json',
  'eser_notlari.json',
  'tanima_notlari.json',
  'ikonografi.json',
];

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage();
const adres = process.env.SITE || 'https://sanat-atlasi.pages.dev/';
await sayfa.goto(adres, { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForFunction(() => window.__atlas && window.__atlas.sanatcilar && window.__atlas.eserNotlariHazir, null, { timeout: 60000 });

const sonuc = await sayfa.evaluate(async ({ DOSYALAR }) => {
  const o = await import('/js/ekranlar/ortak.js');
  const A = await import('/js/ayrinti.js');
  const H = await import('/js/hikaye.js');
  const K = await import('/js/koleksiyon.js');
  const B = await import('/js/bildirim.js');
  const Kr = await import('/js/karsilastir.js');
  const G = await import('/js/goruntuleyici.js');
  const Gr = await import('/js/gorsel.js');
  const Ik = await import('/js/ikonografi.js');
  const Es = await import('/js/eserler.js');
  const d = o.d;

  const dosyalar = {};
  for (const f of DOSYALAR) {
    dosyalar[f] = await (await fetch('data/' + f, { cache: 'no-store' })).text();
  }

  const ayrintiJson = JSON.parse(dosyalar['eser_ayrintilari.json']);
  const hikayeJson = JSON.parse(dosyalar['eser_hikayeleri.json']);
  const notlarJson = JSON.parse(dosyalar['eser_notlari.json']);
  const tanimaJson = JSON.parse(dosyalar['tanima_notlari.json']);
  const ikonoJson = JSON.parse(dosyalar['ikonografi.json']);

  // 1) Ayrıntılar: ayrintilariAl, noktaYeri, noktaOdagi, yakinlasmaSiniri
  const ayrintilar = A.ayrintilariAl(ayrintiJson);
  const sahneler = [
    { taban: { w: 390, h: 520 }, sahne: { w: 390, h: 640 }, enCok: 6 },
    { taban: { w: 360, h: 270 }, sahne: { w: 390, h: 720 }, enCok: 5.25 },
    { taban: { w: 320, h: 480 }, sahne: { w: 375, h: 600 }, enCok: 2.4 },
  ];
  // Z3p (İş 180): yazı kartının ve düğmelerin kapladığı pay (alan). Telefondaki tipik paylar: kart altta (üst çubuk
  // 66, kart + düğmeler 300), kart üstte (üstte 300, altta düğmeler 120), kısa yatay tablo ve küçük sahne.
  const alanliSahneler = [
    { taban: { w: 390, h: 520 }, sahne: { w: 390, h: 640 }, enCok: 6, alan: { ust: 66, alt: 300 } },
    { taban: { w: 390, h: 520 }, sahne: { w: 390, h: 640 }, enCok: 6, alan: { ust: 300, alt: 120 } },
    { taban: { w: 360, h: 270 }, sahne: { w: 390, h: 720 }, enCok: 5.25, alan: { ust: 66, alt: 240 } },
    { taban: { w: 320, h: 480 }, sahne: { w: 375, h: 600 }, enCok: 2.4, alan: { ust: 66, alt: 520 } },
  ];
  const ayrintiVakalar = ayrintilar.map((k) => ({
    anahtar: k.anahtar,
    sanatci: k.sanatci,
    baslik: k.baslik,
    gorsel: k.gorsel,
    noktalar: k.noktalar.map((n) => ({
      nokta: n,
      yeri: A.noktaYeri(n),
      odaklar: sahneler.map((s) => A.noktaOdagi(n, s.taban, s.sahne, { enCok: s.enCok })),
      alanliOdaklar: alanliSahneler.map((s) => A.noktaOdagi(n, s.taban, s.sahne, { enCok: s.enCok, alan: s.alan })),
    })),
  }));

  const yakinlasmaGirdileri = [
    [4096, 390, 3],
    [1280, 390, 3],
    [471, 390, 3],
    [8000, 300, 2],
    [0, 390, 3],
    [1280, 390, 1],
    [2048, 414, 3],
    [960, 375, 2],
  ];
  const yakinlasmaSinirlari = yakinlasmaGirdileri.map(([kaynak, taban, dpr]) => ({
    kaynak,
    taban,
    dpr,
    sinir: A.yakinlasmaSiniri(kaynak, taban, dpr),
  }));

  // 2) Hikâyeler: hikayeleriAl, karakterKaydi
  const hikayeler = H.hikayeleriAl(hikayeJson);
  const hikayeVakalar = hikayeler.map((h) => ({
    kayit: h,
    karakterKaydi: H.karakterKaydi(h),
  }));

  // 3) İkonografi konu haritası
  const ikonoKonular = Ik.konulariAl(ikonoJson, (id) => d.harita.has(id));
  Ik.konuHaritasiniAyarla(ikonoKonular);

  // 4) Eser notları, künye kaynakYazisi, ayrinti/hikaye/konu eşleşmeleri (25 sanatçının eserleri)
  const eserNotlari = Kr.notlariAl(notlarJson);
  const tanimaNotlari = Kr.notlariAl(tanimaJson);
  const taninmaListesi = d.sanatcilar.map((s) => [s.id, Kr.taninmaMetni(s, tanimaNotlari)]);

  // Başyapıt ve hikâyesi olan sanatçılar + genel sanatçılar
  const ozelSanatcilar = [
    ...new Set([
      ...ayrintilar.map((a) => a.sanatci),
      'caravaggio',
      'diego-velazquez',
      'jan-van-eyck',
      'hans-holbein-genc',
      'raphael',
      'leonardo-da-vinci',
      'rembrandt-van-rijn',
      'william-hogarth',
      'cimabue',
      'giotto-di-bondone',
    ]),
  ].filter((id) => d.harita.has(id)).slice(0, 25);

  const eserKunyeVakalar = [];
  for (const sid of ozelSanatcilar) {
    const l = await Es.sanatciEserleri(d.harita.get(sid), { canli: false });
    for (const e of l.slice(0, 12)) {
      const g = Gr.secilenGorsel(e, {}) || e.gorseller[0];
      eserKunyeVakalar.push({
        sid,
        anahtar: e.anahtar,
        ayrintiAnahtari: A.ayrintiAnahtari(e),
        kaynakYazisi: G.kaynakYazisi(e, g),
        devasaKaynagi: Gr.devasaKaynagi(g),
        sayfa: Gr.gorselSayfasi(g),
        not: Kr.eserNotu(sid, e, eserNotlari),
        ayrinti: A.eserinAyrintisi(ayrintilar, e)?.anahtar ?? null,
        hikaye: H.eserinHikayesi(hikayeler, e)?.anahtar ?? null,
        konu: Ik.eserKonusu(e) ?? null,
      });
    }
  }

  // 5) Benzer sanatçılar (bütün görünür sanatçılar için) ve karşılaştırma rotaları
  const benzerVakalar = d.sanatcilar.map((s) => ({
    id: s.id,
    benzerler: Kr.benzerSanatcilar(s, d.sanatcilar, d.akimlar).map((x) => x.id),
  }));
  const rotaTestleri = [
    ['j-m-w-turner', 'john-constable'],
    ['claude-monet', 'pierre-auguste-renoir'],
    ['pablo-picasso', 'georges-braque'],
  ].map(([a, b]) => {
    const adr = Kr.karsilastirmaAdresi(a, b);
    return { a, b, adres: adr, cozulen: Kr.karsilastirmaRotasi(adr) };
  });

  // 6) Koleksiyon ve Bildirim senaryoları (gerçek eserler üstünde adım adım)
  const ornekEserler = [];
  for (const sid of ['jan-van-eyck', 'leonardo-da-vinci', 'rembrandt-van-rijn']) {
    const l = await Es.sanatciEserleri(d.harita.get(sid), { canli: false });
    ornekEserler.push(...l.slice(0, 3));
  }

  // Denetim: eski, eksik alanlı bir kayıt. Site listeyi süzmeden değiştirir; kayıt olduğu gibi kalmalı
  const baslangicKoleksiyon = [{ a: 'eski-kayit', s: 'eski-sanatci' }];
  const il = { koleksiyon: JSON.parse(JSON.stringify(baslangicKoleksiyon)), kotuGorseller: {}, bildirimler: [] };
  const koleksiyonAdimlari = [];
  const tarihler = ['2026-11-18', '2026-11-19', '2026-11-20', '2026-11-21'];
  for (const [idx, e] of [ornekEserler[0], ornekEserler[1], ornekEserler[2], ornekEserler[0], ornekEserler[3], ornekEserler[1]].entries()) {
    const t = tarihler[idx % tarihler.length];
    const sonucDurum = K.koleksiyonDegistir(il, e, t);
    koleksiyonAdimlari.push({
      sid: e.sid,
      anahtar: e.anahtar,
      tarih: t,
      sonuc: sonucDurum,
      varMi: K.koleksiyondaMi(il, e),
      liste: JSON.parse(JSON.stringify(il.koleksiyon)),
    });
  }

  const bildirimAdimlari = [];
  const bildirimSekansi = [
    { e: ornekEserler[0], neden: 'Kötü görsel', t: '2026-11-19' },
    { e: ornekEserler[1], neden: 'Yanlış sanatçı', t: '2026-11-19' },
    { e: ornekEserler[2], neden: 'Heykel/mimari', t: '2026-11-20' },
    { e: ornekEserler[3], neden: 'Yanlış ad', t: '2026-11-20' },
    { e: ornekEserler[1], neden: 'Yanlış sanatçı', t: '2026-11-21' }, // tekrar bildirim: tarih güncellenir, başa gelir
    { e: ornekEserler[0], neden: 'Kötü görsel', t: '2026-11-21' },
  ];
  for (const adim of bildirimSekansi) {
    const g = Gr.secilenGorsel(adim.e, il.kotuGorseller);
    const sonraki = B.eseriBildir(il, adim.e, g, adim.neden, adim.t);
    bildirimAdimlari.push({
      sid: adim.e.sid,
      anahtar: adim.e.anahtar,
      neden: adim.neden,
      tarih: adim.t,
      sonrakiAnahtar: sonraki ? Gr.gorselAnahtari(sonraki) : null,
      uygunMu: Gr.pekistirmeyeUygunMu(adim.e, il.kotuGorseller),
      kotuGorseller: JSON.parse(JSON.stringify(il.kotuGorseller)),
      bildirimler: JSON.parse(JSON.stringify(il.bildirimler)),
    });
  }

  return {
    surum: (await import('/js/surum.js')).SURUM || '',
    nedenler: B.NEDENLER,
    koleksiyonSiniri: K.KOLEKSIYON_SINIRI,
    sahneler,
    alanliSahneler,
    ayrintiVakalar,
    yakinlasmaSinirlari,
    hikayeVakalar,
    taninmaListesi,
    eserKunyeVakalar,
    benzerVakalar,
    rotaTestleri,
    baslangicKoleksiyon,
    koleksiyonAdimlari,
    bildirimAdimlari,
    dosyalar,
  };
}, { DOSYALAR });

await tarayici.close();

mkdirSync(klasor, { recursive: true });
for (const [f, metin] of Object.entries(sonuc.dosyalar)) {
  writeFileSync(join(klasor, f), metin);
}
delete sonuc.dosyalar;
writeFileSync(join(klasor, 'cevaplar.json'), JSON.stringify(sonuc, null, 1) + '\n');
console.error(
  `${sonuc.ayrintiVakalar.length} ayrıntı, ${sonuc.hikayeVakalar.length} hikâye, ${sonuc.eserKunyeVakalar.length} eser künyesi → ${klasor}`
);
