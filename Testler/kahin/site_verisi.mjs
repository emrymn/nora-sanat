// Site verisi kâhini (T1): sitenin kendi modülleriyle görünür sanatçılar, akımlar, kurs konuları, adlar ve her
// görünür sanatçının eser listesi (sanatciEserleri) + görsel adresleri. Aynı anda sitenin o an yüklediği veri
// dosyalarını da (aynı anlık görüntü) test örneği olarak yazar.
//
//   node Testler/kahin/site_verisi.mjs Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/siteVerisi
//
// Çıktı klasörü: data_*.json (sitenin dosyaları, küçültülmüş) ve cevaplar.json.
// Eser satırı biçimi (Swift testi aynısını kurar): alanlar \u001f ile, eserler \n ile birleşir; her sanatçının
// satırlarının MD5'i `ozet`'e, seçilen 20 sanatçının satırları açıkça `ayrinti`'ya yazılır.
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const { chromium } = createRequire(import.meta.url)('playwright');

const cikti = process.argv[2];
if (!cikti) throw new Error('çıktı klasörü ver');
mkdirSync(cikti, { recursive: true });

const DOSYALAR = [
  'sanatcilar', 'akimlar', 'konular', 'eser_turleri', 'eser_adlari_tr', 'yerel_gorseller', 'gorsel_oranlari',
  'gorsel_kaynagi', 'kopya_eserler', 'cikarilan_gorseller', 'eser_duzeltmeleri', 'eserler_onbellek', 'kisa_adlar', 'yuruyus',
];

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage();
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForFunction(() => window.__atlas && window.__atlas.sanatcilar, null, { timeout: 60000 });
await sayfa.waitForTimeout(2000);

const sonuc = await sayfa.evaluate(async (DOSYALAR) => {
  const o = await import('/js/ekranlar/ortak.js');
  const es = await import('/js/eserler.js');
  const gr = await import('/js/gorsel.js');
  const ad = await import('/js/adlar.js');
  const { md5 } = await import('/js/md5.js');
  const { d } = o;

  // Sitenin bu oturumda gördüğü dosyalar (aynı anlık görüntü). Sırayı korumak için JSON.parse → stringify.
  const dosyalar = {};
  for (const f of DOSYALAR) dosyalar[f] = JSON.stringify(JSON.parse(await (await fetch(`/data/${f}.json`)).text()));

  const mutlak = (u) => (!u ? '' : /^https?:/i.test(u) ? u : new URL(u, location.origin + '/').href);
  const bos = (x) => (x === null || x === undefined ? '' : String(x));
  const satir = (e) => {
    const g = gr.secilenGorsel(e);
    const u400 = gr.gorselUrl(g, 400);
    const u1280 = gr.gorselUrl(g, 1280);
    return [
      e.anahtar, e.kaynak, (e.kaynaklar || []).join(','), e.baslik, e.ad || '', es.eserBaslik(e), e.tarih, bos(e.yil), e.muze,
      bos(e.kursKonu), e.qid || '', e.pekistirme ? 1 : 0, e.sl || 0, (e.ortak || []).join(','), (e.ortakAdlar || []).join(','),
      e.gorseller.map(gr.gorselAnahtari).join(','), mutlak(u400), mutlak(u1280), mutlak(gr.devasaUrl(g)), gr.devasaKaynagi(g),
      bos(gr.gorselOrani(g)), gr.pekistirmeyeUygunMu(e) ? 1 : 0, gr.gorselSayfasi(g), gr.gorselKaynakYazisi(g),
      mutlak(gr.ustKopya(u400)), mutlak(gr.ustKopya(u1280, { buyuk: true })), mutlak(gr.gorselYedek(g)),
    ].join('\u001f');
  };

  const eserler = {};
  for (const s of d.sanatcilar) eserler[s.id] = (await es.sanatciEserleri(s, { canli: false })).map(satir);
  const ozet = Object.fromEntries(Object.entries(eserler).map(([id, l]) => [id, [l.length, md5(l.join('\n'))]]));

  // Ayrıntı: kuralların değdiği sanatçılar önce (kopya, düzeltme, çıkarılan, ortak atıf, kurs), sonra en kalabalıklar
  const ozel = (id) =>
    eserler[id].some((x) => {
      const p = x.split('\u001f');
      return p[1] === 'kurs' || p[13] || p[0].startsWith('c:') || !p[16].includes('noracloud');
    });
  const secilen = [];
  const ekle = (id) => id && eserler[id] && !secilen.includes(id) && secilen.length < 20 && secilen.push(id);
  for (const id of ['limbourg-kardesler', 'domenico-di-michelino', 'cimabue', 'leonardo-da-vinci', 'robert-campin', 'william-hogarth', 'giorgione', 'tiziano', 'phidias', 'gentile-da-fabriano']) ekle(id);
  for (const s of d.sanatcilar) if (ozel(s.id)) ekle(s.id);
  const ayrinti = Object.fromEntries(secilen.map((id) => [id, eserler[id]]));

  // Yapay örnekler: canlı veride yerel kopyası olmayan görseller hep Commons; öteki kaynakların ve yardımcıların dalları
  const yapayGorseller = [
    { k: 'commons', d: 'Some_painting_(détail),_1500.tif', l: 'CC BY-SA 4.0' },
    { k: 'commons', d: 'File:a%C3%A7ık hava %25 rapor.svg', l: '' },
    { k: 'commons', d: 'Book_of_hours.pdf' },
    { k: 'commons', d: 'çizim_Ç.djvu' },
    { k: 'commons', d: "L'Été_*_(1).JPEG" },
    { k: 'commons', d: '%E0%A4%A' },
    { k: 'aic', i: '0a1b2c3d-1111-2222-3333-444455556666', l: 'CC0', s: 'https://www.artic.edu/artworks/1' },
    { k: 'nga', i: 'https://api.nga.gov/iiif/abc-def', s: 'javascript:alert(1)' },
    { k: 'wikiart', u: 'https://uploads.wikiart.org/images/x/y.jpg!HalfHD.jpg', s: 'https://www.wikiart.org/en/x/y' },
    { k: 'wikiart', u: 'https://uploads.wikiart.org/images/x/z.jpg' },
    { k: 'met', u: 'https://images.metmuseum.org/CRDImages/ep/original/DT1.jpg', l: 'CC0' },
    { k: 'cma', u: 'https://openaccess-cdn.clevelandart.org/1.jpg', s: 'http://clevelandart.org/1' },
    { k: 'met' },
    { k: 'bilinmez', u: 'https://ornek.org/a.jpg', l: 'X' },
  ];
  const gorselSatiri = (g) =>
    [gr.gorselAnahtari(g), gr.yerelAnahtar(g), mutlak(gr.gorselUrl(g, 400)), mutlak(gr.gorselUrl(g, 960)), mutlak(gr.gorselUrl(g, 2000)), gr.gorselSayfasi(g), gr.gorselKaynakYazisi(g), mutlak(gr.gorselYedek(g))].join('\u001f');
  const yardimci = await import('/js/yardimci.js');
  const notlar = [
    '1401 (slayt yazısı)', 'slaytta c1308–11', 'Slayta göre Uffizi', "metinde 1520'ler; slaytta c1500", 'Uffizi, Floransa',
    'yaklaşık MÖ 450', 'Louvre (metinde ikisi de geçer); Paris', 'Slayt künyesi: 1503–1519', 'Metne göre: Floransa', 'Altyazıda 1500',
    'Metin', '', 'Ulusal Galeri (Londra)', 'slayt yazısına göre c. 1435; metinde 1434',
  ];
  const yapay = {
    gorseller: yapayGorseller.map(gorselSatiri),
    notTemizle: notlar.map((n) => [n, yardimci.notTemizle(n)]),
    dosyaNormal: ['a b.jpg', 'File:x%20y.JPG', 'file:çanak.png', '%zz.jpg', '  ılık_su.jpg ', 'ß_test.jpg'].map((x) => [x, yardimci.dosyaNormal(x)]),
    yilYaz: [-450, 0, 1503, null].map((y) => [y, yardimci.yilYaz(y)]),
    ustKopya: [
      'gorseller/k/0123456789abcdef.jpg', 'https://gorsel.noracloud.ai/b/66b1d9b4a6aaac49-c6418800.jpg', 'https://x/b/66b1d9b4a6aaac49.jpg?v=1', 'gorseller/k/abc.jpg', '',
    ].map((u) => [u, mutlak(gr.ustKopya(u)), mutlak(gr.ustKopya(u, { buyuk: true }))]),
  };

  // R2 kaynağı yokken (data/gorsel_kaynagi.json inmedi): yerel kopyalar depodan, 1280'lik ya b/ ya eski 800'lük.
  // Listeler önce alınır; kaynak kapalıyken satırlar eşzamanlı üretilir, sonra kaynak geri konur.
  const kaynakVeri = JSON.parse(dosyalar.gorsel_kaynagi);
  const kaynaksizIdler = ['masaccio', 'cimabue', 'sandro-botticelli'].filter((id) => d.harita.has(id));
  const kaynaksizListe = [];
  for (const id of kaynaksizIdler) kaynaksizListe.push([id, (await es.sanatciEserleri(d.harita.get(id), { canli: false })).slice(0, 15)]);
  gr.uzakGorselleriAyarla(null);
  const kaynaksiz = {
    eserler: Object.fromEntries(kaynaksizListe.map(([id, l]) => [id, l.map(satir)])),
    yuruyus: Object.entries(d.yuruyus || {}).slice(0, 10).map(([id, k]) => {
      const a = gr.yuruyusAdresleri(k.gorsel, k.buyuk);
      return [id, mutlak(a.kucuk), mutlak(a.buyuk)];
    }),
    ustKopya: yapay.ustKopya.map(([u]) => [u, mutlak(gr.ustKopya(u)), mutlak(gr.ustKopya(u, { buyuk: true }))]),
  };
  gr.uzakGorselleriAyarla(kaynakVeri);

  return {
    dosyalar,
    cevap: {
      surum: (await import('/js/surum.js')).SURUM,
      tumSanatcilar: d.tumSanatcilar.map((s) => [s.id, s.akim, s.birlesen || '']),
      sanatcilar: d.sanatcilar.map((s) => s.id),
      akimlar: d.akimlar.map((a) => [a.ad, a.sira, a.renk, a.komsular.join(',')]),
      kursKonulari: d.kursKonulari.map((k) => [k.no, JSON.stringify(k.kapak)]),
      adlar: d.sanatcilar.map((s) => {
        const p = ad.adParcala(s.ad, d.kisaAdlar[s.id]);
        return [s.id, p.ilk, p.son, p.tam || ''];
      }),
      yuruyus: Object.entries(d.yuruyus || {}).map(([id, k]) => {
        const a = gr.yuruyusAdresleri(k.gorsel, k.buyuk);
        return [id, mutlak(a.kucuk), mutlak(a.buyuk)];
      }),
      ozet,
      ayrinti,
      yapay,
      kaynaksiz,
    },
  };
}, DOSYALAR);

for (const [f, metin] of Object.entries(sonuc.dosyalar)) writeFileSync(join(cikti, `data_${f}.json`), metin);
writeFileSync(join(cikti, 'cevaplar.json'), JSON.stringify(sonuc.cevap));
console.error(`site ${sonuc.cevap.surum}: ${sonuc.cevap.sanatcilar.length} sanatçı, ${sonuc.cevap.akimlar.length} akım, ayrıntı: ${Object.keys(sonuc.cevap.ayrinti).join(' ')}`);
await tarayici.close();
