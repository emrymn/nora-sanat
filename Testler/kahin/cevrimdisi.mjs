// C5 kâhini: çevrimdışı görseller ("En büyük kopyaları telefona indir") canlı sitenin kendi modülleriyle.
// - İndirme listesi: js/eserler.js gosterilenGorseller → js/gorsel.js devasaSuz, telefonAdresleri (sıra = indirme sırası),
//   devasaAdresleri, tahminiBayt, telefonToplamBayt. Liste uzun (~15 bin adres): sayılar, sıralı listenin MD5'i ve
//   her 97. adres yazılır.
// - Parça planı: js/ekranlar/ayarlar.js devasaIndir'in parça seçimi (dışa açık değil; aşağıda aynen kopyalandı) çeşitli
//   "telefondakiler" kümeleriyle.
// - Ayarlar'ın yazıları sayfanın kendisinden: #devasa-bilgi (telefonda 0 ve 5 görsel varken) ve #devasa-mesaj
//   (d.devasaIndirme'nin her durumu için sayfa yeniden çizilip okunur).
// - Veri dosyaları Ornekler/site_verisi/'ndekilerle aynı olmalı (Swift testi listeyi oradan kurar): MD5'leri karşılaştırılır.
//
//   node Testler/kahin/cevrimdisi.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/cevrimdisi/cevaplar.json
import { createRequire } from 'node:module';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const SITE = process.env.SITE || 'https://sanat-atlasi.pages.dev/';
const md5 = (s) => createHash('md5').update(s).digest('hex');
const ornekler = new URL('../../Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/site_verisi/', import.meta.url);

const { chromium } = createRequire(import.meta.url)('playwright');
const tarayici = await chromium.launch();
try {
  const sayfa = await tarayici.newPage({ viewport: { width: 393, height: 852 } });
  // Testte parça yenilemesi olmasın
  await sayfa.addInitScript(() => (window.__atlasYenilemeYok = true));
  await sayfa.goto(SITE, { waitUntil: 'domcontentloaded' });
  await sayfa.waitForFunction(() => window.__atlas?.ilerleme && window.__atlas?.sanatcilar, null, { timeout: 90000 });

  // Veri dosyaları örneklerle aynı mı
  const farkli = [];
  for (const ad of ['eserler_onbellek.json', 'gorsel_kaynagi.json', 'yerel_gorseller.json', 'cikarilan_gorseller.json', 'eser_duzeltmeleri.json', 'kopya_eserler.json']) {
    const canli = await (await fetch(new URL(`data/${ad}`, SITE))).text();
    if (md5(canli) !== md5(readFileSync(new URL(ad, ornekler), 'utf8'))) farkli.push(ad);
  }
  assert.deepEqual(farkli, [], `site verisi değişmiş, önce site_verisi.mjs ile örnekleri yenile: ${farkli}`);

  const liste = await sayfa.evaluate(async () => {
    const Es = await import('/js/eserler.js');
    const G = await import('/js/gorsel.js');
    G.devasaSuz(await Es.gosterilenGorseller());
    const tel = G.telefonAdresleri();
    const dev = G.devasaAdresleri();
    const bayt = (l) => l.reduce((t, u) => t + G.tahminiBayt(u), 0);
    // devasaIndir'in parça seçimi (js/ekranlar/ayarlar.js, İş 124/131), aynen
    const PARCA = 200;
    const parcaPlani = (var_) => {
      const hepsi = tel;
      const PARCA_ADET = 1000;
      const kalan = hepsi.filter((u) => !var_.has(u));
      const ort = G.tahminiBayt('/d/0');
      const boy = PARCA * ort;
      const urller = [];
      let parcaBayt = 0;
      for (const u of kalan) {
        if (urller.length && (parcaBayt + G.tahminiBayt(u) > boy + 1 || urller.length >= PARCA_ADET)) break;
        urller.push(u);
        parcaBayt += G.tahminiBayt(u);
      }
      const hepsiBayt = bayt(hepsi);
      const kalanBayt = bayt(kalan);
      const parca = Math.floor((hepsiBayt - kalanBayt + 1) / boy) + 1;
      const parcaSayisi = Math.max(parca + Math.ceil((kalanBayt - parcaBayt - 1) / boy), parca, Math.ceil((hepsiBayt - 1) / boy));
      return { adet: urller.length, ilk: urller[0] || null, son: urller[urller.length - 1] || null, parca, parcaSayisi,
        onceden: hepsi.length - kalan.length, oncedenBayt: hepsiBayt - kalanBayt, sonParca: urller.length >= kalan.length };
    };
    const kumeler = {
      bos: new Set(),
      ilk150: new Set(tel.slice(0, 150)),
      ilk200: new Set(tel.slice(0, 200)),
      ilk1234: new Set(tel.slice(0, 1234)),
      ucteBir: new Set(tel.filter((_, i) => i % 3 === 0)),
      devasalar: new Set(dev),
      sonBesHaric: new Set(tel.slice(0, tel.length - 5)),
      hepsi: new Set(tel),
    };
    const parcalar = Object.fromEntries(Object.entries(kumeler).map(([ad, k]) => [ad, parcaPlani(k)]));
    const ornekBayt = ['/d/0', 'https://x/d/ab12.jpg', 'https://x/k/ab12.jpg', 'https://x/b/ab12.jpg', 'https://x/d/zz.jpg', 'gorseller/k/0a.jpg'];
    return {
      suzuldu: G.suzulduMu(),
      sayilar: { telefon: tel.length, devasa: dev.length, toplamBayt: G.telefonToplamBayt() },
      md5Metni: tel.join('\n'),
      ornekler: tel.map((u, i) => [i, u]).filter(([i]) => i % 97 === 0 || i === tel.length - 1),
      tahmini: ornekBayt.map((u) => [u, G.tahminiBayt(u)]),
      parcalar,
      ilkBes: tel.slice(0, 5),
    };
  });
  liste.md5 = md5(liste.md5Metni);
  delete liste.md5Metni;
  assert.ok(liste.suzuldu && liste.sayilar.telefon > 1000, 'liste');

  // Ayarlar'ın yazıları
  const ayarlaraGit = async () => {
    await sayfa.evaluate(() => (location.hash = '#/'));
    await sayfa.waitForTimeout(400);
    await sayfa.evaluate(() => (location.hash = '#/ayarlar'));
    await sayfa.waitForFunction(() => {
      const b = document.querySelector('#devasa-bilgi');
      return b && b.textContent !== 'Hesaplanıyor…';
    }, null, { timeout: 60000 });
    await sayfa.waitForTimeout(300);
  };
  const oku = () => sayfa.evaluate(() => {
    const kok = document.querySelector('[data-test="devasa-indir"]');
    const g = (s) => kok.querySelector(s);
    const cubuk = g('#devasa-cubuk');
    return {
      bilgi: g('#devasa-bilgi').textContent,
      mesaj: g('#devasa-mesaj').textContent,
      mesajSinif: g('#devasa-mesaj').className,
      indir: !g('[data-devasa-indir]').hidden, indirKapali: g('[data-devasa-indir]').disabled,
      durdur: !g('[data-devasa-durdur]').hidden, sil: !g('[data-devasa-sil]').hidden,
      cubuk: cubuk.hidden ? null : [cubuk.value, cubuk.max],
    };
  });
  await ayarlaraGit();
  const bos = await oku();

  // telefonda 5 görsel: sitenin deposuna (IndexedDB atlas-devasa · g) sahte kayıt
  await sayfa.evaluate(async (adresler) => {
    const D = await import('/js/devasaOnbellek.js');
    for (const u of adresler) await D.kaliciYaz(u, new Blob([new Uint8Array([1, 2, 3])], { type: 'image/jpeg' }));
  }, liste.ilkBes);
  await ayarlaraGit();
  const bes = await oku();

  // İndirme durumları: d.devasaIndirme verilip sayfa yeniden çizilir (devasaBilgisi → devasaGoster)
  const N = liste.sayilar.telefon;
  const taban = { toplam: 200, hepsi: N, onceden: 5, oncedenBayt: 5 * 3.3e6, bitenBayt: 37 * 3.4e6, biten: 37, hata: 2, yazilamadi: 0, bitti: false, parca: 2, parcaSayisi: 9 };
  const durumlar = {
    suruyor: {},
    suruyorBos: { biten: 0, hata: 0, bitenBayt: 0, onceden: 0, oncedenBayt: 0, parca: 1 },
    yerYok: { yerYok: true, bitti: true },
    durduruldu: { bitti: true, durduruldu: true },
    yazilamadi: { bitti: true, inemedi: true, yazilamadi: 37, biten: 37, hata: 37, sonHata: 'UnknownError: disk' },
    inemedi: { bitti: true, inemedi: true, biten: 37, hata: 37 },
    parcaBitti: { bitti: true, parcaBitti: true, yenileniyor: true, biten: 200, hata: 3 },
    bittiHatali: { bitti: true, biten: 200, hata: 4 },
    bitti: { bitti: true, biten: 200, hata: 0 },
    bittiBos: { bitti: true, toplam: 0, biten: 0, hata: 0 },
  };
  const mesajlar = {};
  for (const [ad, ek] of Object.entries(durumlar)) {
    const i = { ...taban, ...ek };
    await sayfa.evaluate(async (i) => {
      const o = await import('/js/ekranlar/ortak.js');
      o.d.devasaIndirme = { ...i, iptaller: new Set() };
    }, i);
    await ayarlaraGit();
    mesajlar[ad] = { durum: i, ...(await oku()) };
  }
  await sayfa.evaluate(async () => ((await import('/js/ekranlar/ortak.js')).d.devasaIndirme = null));

  console.log(JSON.stringify({ liste, ayarlar: { bos, bes }, mesajlar }, null, 1));
} finally {
  await tarayici.close();
}
