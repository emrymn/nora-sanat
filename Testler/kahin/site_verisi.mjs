// T1 kâhini: sitenin gördüğü veri ve görsel adresleri, sitenin kendi modülleriyle.
// Çıktı klasörü (varsayılan Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/site_verisi):
//   - cevaplar.json: kimlik listeleri, kurs konuları, kısa adlar, seçilmiş sanatçıların sanatciEserleri sonucu,
//     yerel kopyası olmayan (Commons/müze) görsellerin adresleri, ustKopya örnekleri
//   - sitenin o anki veri dosyaları (Swift testleri bunlarla çalışır; cevaplarla aynı anda alınır)
//
//   node Testler/kahin/site_verisi.mjs [klasör]
import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const { chromium } = createRequire(import.meta.url)('playwright');

const klasor = process.argv[2] || 'Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/site_verisi';
// Swift'in SiteVerisi.dosyalar listesiyle aynı (sanatcilar..duzeltmeler: js/app.js basla())
const DOSYALAR = [
  'sanatcilar.json', 'akimlar.json', 'konular.json', 'eser_turleri.json', 'eser_adlari_tr.json',
  'yerel_gorseller.json', 'gorsel_oranlari.json', 'gorsel_kaynagi.json', 'kopya_eserler.json',
  'cikarilan_gorseller.json', 'eser_duzeltmeleri.json', 'kisa_adlar.json', 'eserler_onbellek.json',
  'yuruyus.json', // widget testi için (günün tablosu)
];
// Elle seçilenler: kopya kaydı, düzeltme, ortak atıf, kurs eseri, Antik/heykel, birleşen akım olan sanatçılar
const OZEL = [
  'limbourg-kardesler', 'cimabue', 'leonardo-da-vinci', 'robert-campin', 'william-hogarth', 'giorgione',
  'titian', 'giotto-di-bondone', 'masaccio', 'gentile-da-fabriano', 'rembrandt-van-rijn', 'pablo-picasso',
];

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage();
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForFunction(() => window.__atlas && window.__atlas.sanatcilar, null, { timeout: 60000 });
const sonuc = await sayfa.evaluate(async ({ OZEL, DOSYALAR }) => {
  const o = await import('/js/ekranlar/ortak.js');
  const es = await import('/js/eserler.js');
  const gr = await import('/js/gorsel.js');
  const ad = await import('/js/adlar.js');
  const d = o.d;
  // göreli adresler (gorseller/k/…) site köküne göre; mutlak adresler olduğu gibi
  const tam = (u) => (u && !/^https?:\/\//.test(u) ? new URL(u, location.href).href : u || '');
  const dosyalar = {};
  for (const f of DOSYALAR) dosyalar[f] = await (await fetch('data/' + f, { cache: 'no-store' })).text();

  // 20 sanatçı: görünür listeden eşit aralıklı 8 + elle seçilen 12 (görünür olanlar)
  const ids = d.sanatcilar.map((s) => s.id);
  const secilen = [];
  for (let i = 0; i < 8; i++) secilen.push(ids[Math.floor((i * ids.length) / 8) + 3]);
  for (const id of OZEL) if (ids.includes(id) && !secilen.includes(id)) secilen.push(id);
  const sec = secilen.slice(0, 20);

  const eserler = {};
  for (const id of sec) {
    const l = await es.sanatciEserleri(d.harita.get(id), { canli: false });
    eserler[id] = l.map((e) => {
      const g = gr.secilenGorsel(e, {});
      return {
        anahtar: e.anahtar,
        baslik: e.baslik,
        ad: es.eserBaslik(e),
        tarih: e.tarih,
        yil: e.yil,
        muze: e.muze,
        kaynak: e.kaynak,
        kaynaklar: e.kaynaklar,
        kursKonu: e.kursKonu,
        qid: e.qid,
        sl: e.sl ?? 0,
        pekistirme: e.pekistirme,
        ortak: e.ortak || [],
        gorselSayisi: e.gorseller.length,
        g400: tam(gr.gorselUrl(g, 400)),
        g1280: tam(gr.gorselUrl(g, 1280)),
        devasa: gr.devasaUrl(g),
        ust: tam(gr.ustKopya(tam(gr.gorselUrl(g, 400)))),
        ustBuyuk: tam(gr.ustKopya(tam(gr.gorselUrl(g, 1280)), { buyuk: true })),
        oran: gr.gorselOrani(g) ?? null,
        uygun: gr.pekistirmeyeUygunMu(e, {}),
      };
    });
  }

  // Yerel kopyası olmayan görseller (Commons küçük resmi md5 yolu, müze IIIF): önbellekteki ilk 40
  const hazir = await es.hazirOnbellek();
  const uzaklar = [];
  outer: for (const v of Object.values(hazir.sanatcilar))
    for (const e of v.eserler)
      for (const g of e.gorseller)
        if (!gr.yerelUrl(g, 400) && uzaklar.filter((x) => x.g.k === g.k).length < 12) {
          uzaklar.push({ g, u330: gr.gorselUrl(g, 330), u400: gr.gorselUrl(g, 400), u800: gr.gorselUrl(g, 800), u1280: gr.gorselUrl(g, 1280), u2000: gr.gorselUrl(g, 2000), yedek: gr.gorselYedek(g) });
          if (uzaklar.length >= 40) break outer;
        }

  return {
    surum: (await import('/js/surum.js')).SURUM || '',
    tumSanatcilar: d.tumSanatcilar.map((s) => [s.id, s.akim, s.birlesen || null]),
    sanatcilar: ids,
    akimlar: d.akimlar.map((a) => ({ ad: a.ad, sira: a.sira, komsular: a.komsular, renk: a.renk })),
    kursKonulari: d.kursKonulari.map((k) => ({ no: k.no, kapak: k.kapak })),
    bilinenAdlar: Object.fromEntries(d.sanatcilar.map((s) => [s.id, ad.adParcala(s.ad, d.kisaAdlar[s.id])])),
    eserler,
    uzaklar,
    dosyalar,
  };
}, { OZEL, DOSYALAR });
await tarayici.close();

mkdirSync(klasor, { recursive: true });
for (const [f, metin] of Object.entries(sonuc.dosyalar)) writeFileSync(join(klasor, f), metin);
delete sonuc.dosyalar;
writeFileSync(join(klasor, 'cevaplar.json'), JSON.stringify(sonuc, null, 1) + '\n');
console.error(`${Object.keys(sonuc.eserler).length} sanatçı, ${Object.values(sonuc.eserler).flat().length} eser → ${klasor}`);
