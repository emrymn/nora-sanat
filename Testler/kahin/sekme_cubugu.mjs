// Sekme çubuğu kâhini (T4): sitenin kendi çalışan çubuğu
//  1) simgeler: js/tasarim.js YOLLAR'ın kendisi ve tarayıcının ölçtüğü sınır kutusu (getBBox)
//  2) yerleşim: birkaç ekran boyunda çubuğun, sekmelerin, simgenin, hızlı ayar dilinin ve Çalış rozetinin yeri
//  3) hızlı ayarlar: seçenekler ve günlük kart sınırları (yaprağın kendi düğmeleriyle)
//  4) köprü: NoraSanat/Kabuk/SekmeCubuguKoprusu.swift betikleri sitenin içinde çalıştırılır (rozet sitenin rozetiyle
//     aynı mı; yazma betiği sitenin yaprağı gibi mi yazıyor)
//
//   node Testler/kahin/sekme_cubugu.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/sekme_cubugu/cevaplar.json
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const { chromium } = createRequire(import.meta.url)('playwright');

const swift = (yol) => readFileSync(new URL(`../../${yol}`, import.meta.url), 'utf8');
const coksatir = (kaynak, bas) => {
  const i = kaynak.indexOf(bas);
  assert.ok(i >= 0, bas);
  const a = kaynak.indexOf('"""', i) + 3;
  const b = kaynak.indexOf('"""', a);
  const satirlar = kaynak.slice(a, b).split('\n').slice(1);
  const girinti = satirlar[satirlar.length - 1].length;
  return satirlar.slice(0, -1).map((s) => s.slice(girinti)).join('\n');
};
const kopru = swift('NoraSanat/Kabuk/SekmeCubuguKoprusu.swift');
const rozetBetigi = coksatir(kopru, 'static let rozetBetigi');
const okumaBetigi = coksatir(kopru, 'static let okumaBetigi');
const yazmaBetigi = coksatir(kopru, 'static let yazmaBetigi');
const SIMGELER = ['sekme-bugun', 'sekme-harita', 'sekme-gozat', 'firca', 'ayarlar', 'eksi', 'arti', 'ileri'];
const EKRANLAR = [[393, 852], [320, 568], [430, 932], [820, 1180]];

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage({ viewport: { width: 393, height: 852 }, isMobile: true, hasTouch: true });
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForFunction(() => window.__atlas && window.__atlas.ilerleme, null, { timeout: 60000 });
await sayfa.waitForTimeout(1000);
const surum = await sayfa.evaluate(() => import('/js/surum.js').then((m) => m.SURUM));

// 1) Simgeler
const simgeler = await sayfa.evaluate(async (adlar) => {
  const { ikon } = await import('/js/tasarim.js');
  const kap = document.createElement('div');
  document.body.append(kap);
  const o = {};
  for (const ad of adlar) {
    kap.innerHTML = ikon(ad, 24, 1.5);
    const svg = kap.querySelector('svg');
    const b = svg.getBBox();
    // tarayıcı <rect/>'i <rect></rect> yazar; kaynaktaki biçime döndürülür
    o[ad] = { isaretleme: svg.innerHTML.replace(/><\/(path|rect|circle)>/g, '/>'), kutu: [b.x, b.y, b.width, b.height] };
  }
  kap.remove();
  return o;
}, SIMGELER);

// 2) Yerleşim (çubuk hareketleri bitince)
const yerlesim = [];
for (const [g, h] of EKRANLAR) {
  await sayfa.setViewportSize({ width: g, height: h });
  await sayfa.evaluate(() => { location.hash = '#/gozat'; });
  await sayfa.waitForTimeout(1200);
  yerlesim.push(await sayfa.evaluate(([g, h]) => {
    const r = (el) => { const b = el?.getBoundingClientRect(); return b ? [b.x, b.y, b.width, b.height] : null; };
    const nav = document.getElementById('sekmeler');
    const a = [...nav.querySelectorAll('a')];
    return {
      ekran: [g, h],
      cubuk: r(nav),
      sekmeler: a.map(r),
      isaret: r(nav.querySelector('.sekme-isaret')),
      secili: a.findIndex((x) => x.getAttribute('aria-current') === 'page'),
      simge: r(a[0].querySelector('.ikon')),
      dil: r(document.querySelector('.hizli-dil')),
      rozet: r(nav.querySelector('.sekme-rozet')),
    };
  }, [g, h]));
}
await sayfa.setViewportSize({ width: 393, height: 852 });

// 3) Hızlı ayarlar: seçenekler ve günlük kart sınırları (yaprağın + / − düğmeleri)
const secenekler = await sayfa.evaluate(async () => {
  const depo = await import('/js/depo.js');
  const o = await import('/js/ekranlar/ortak.js');
  return {
    temalar: depo.TEMALAR.map((t) => [t, o.TEMA_AD[t]]),
    hareketler: depo.HAREKETLER.map((t) => [t, depo.HAREKET_AD[t]]),
  };
});
const kartDene = async (bas, dugme) => {
  await sayfa.evaluate(async (bas) => {
    const o = await import('/js/ekranlar/ortak.js');
    o.d.ilerleme.ayarlar.gunlukKart = bas;
    o.kaydet();
  }, bas);
  await sayfa.click('.hizli-dil');
  await sayfa.waitForTimeout(600);
  await sayfa.click(`[data-hizli-kart="${dugme}"]`);
  const son = await sayfa.evaluate(async () => (await import('/js/ekranlar/ortak.js')).d.ilerleme.ayarlar.gunlukKart);
  await sayfa.click('[data-hizli-kapat]', { position: { x: 20, y: 20 } });
  await sayfa.waitForTimeout(600);
  return [bas, Number(dugme), son];
};
const kart = [await kartDene(20, '5'), await kartDene(98, '5'), await kartDene(100, '5'), await kartDene(7, '-5'), await kartDene(5, '-5')];
await sayfa.evaluate(() => { location.hash = '#/ayarlar'; });
await sayfa.waitForTimeout(500);
const dilAyarlarda = await sayfa.evaluate(() => !document.querySelector('.hizli-dil').hidden);
await sayfa.evaluate(() => { location.hash = '#/gozat'; });
await sayfa.waitForTimeout(500);

// 4) Köprü betikleri
const calistir = (govde, arg = {}) =>
  sayfa.evaluate(async ([govde, arg]) => {
    const AsyncFunction = (async () => {}).constructor;
    return new AsyncFunction(...Object.keys(arg), govde)(...Object.values(arg));
  }, [govde, arg]);
await sayfa.evaluate(async () => {
  const o = await import('/js/ekranlar/ortak.js');
  o.d.ilerleme.ayarlar.gunlukKart = 20;
  o.kaydet();
  location.hash = '#/harita';
});
await sayfa.waitForTimeout(800);
const siteRozeti = await sayfa.evaluate(() => Number(document.querySelector('#sekmeler .sekme-rozet')?.textContent || 0));
const kopruRozeti = await calistir(rozetBetigi);
assert.equal(kopruRozeti, siteRozeti, 'rozet betiği sitenin rozetiyle aynı');
assert.ok(siteRozeti > 0, 'yeni profilde Çalış rozeti var');
const once = await calistir(okumaBetigi);
assert.deepEqual(once, { tema: 'gece', hareket: 'tam', gunlukKart: 20 });
let sonra = await calistir(yazmaBetigi, { alan: 'tema', deger: 'gunduz' });
assert.equal(sonra.tema, 'gunduz');
assert.equal(await sayfa.evaluate(() => document.documentElement.dataset.tema), 'gunduz', 'temaUygula çalıştı');
sonra = await calistir(yazmaBetigi, { alan: 'hareket', deger: 'kapali' });
assert.equal(await sayfa.evaluate(() => document.documentElement.dataset.hareket), 'kapali');
assert.equal(await calistir(yazmaBetigi, { alan: 'tema', deger: 'mor' }), null, 'geçersiz tema yazılmaz');
sonra = await calistir(yazmaBetigi, { alan: 'kart', deger: 5 });
assert.equal(sonra.gunlukKart, 25);
const kayitli = await sayfa.evaluate(() => JSON.parse(localStorage.getItem('sanat-atlasi:ilerleme')).ayarlar);
assert.equal(kayitli.gunlukKart, 25, 'localStorage\'a yazıldı');
assert.equal(kayitli.tema, 'gunduz');
console.error(`köprü: rozet ${kopruRozeti} = site ${siteRozeti}; tema, hareket, kart yazıldı`);

await tarayici.close();
console.log(JSON.stringify({ surum, simgeler, yerlesim, hizli: { ...secenekler, kart, dilAyarlarda } }, null, 1));
