// Sekme çubuğu kâhini (T4): sitenin kendi çalışan çubuğu
//  1) simgeler: js/tasarim.js YOLLAR'ın kendisi ve tarayıcının ölçtüğü sınır kutusu (getBBox)
//  2) yerleşim: birkaç ekran boyunda çubuğun, sekmelerin, simgenin, hızlı ayar dilinin ve Çalış rozetinin yeri
//  3) hızlı ayarlar: seçenekler ve günlük kart sınırları (yaprağın kendi düğmeleriyle)
// (Köprü bölümü Z2c'de kalktı: rozet ve hızlı ayarlar Swift'te; rozet hesabı calis.mjs ile sınanır.)
//
//   node Testler/kahin/sekme_cubugu.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/sekme_cubugu/cevaplar.json
import { createRequire } from 'node:module';
import assert from 'node:assert/strict';
const { chromium } = createRequire(import.meta.url)('playwright');

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

await tarayici.close();
console.log(JSON.stringify({ surum, simgeler, yerlesim, hizli: { ...secenekler, kart, dilAyarlarda } }, null, 1));
