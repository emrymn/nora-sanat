// Kabuk köprüleri (T3) canlı sitede: Swift dosyalarındaki betikler aynen eklenir, window.webkit.messageHandlers
// taklit edilir. Sınananlar:
//  - Gecis.adresBetigi: açılışta ve her adres değişiminde location.hash gelir
//  - Gecis.sekmeyeGecBetigi (Gezgin.sekmeyeGec): sitenin kendi sekme düğmesine basmak sekmenin kalınan yerini açar;
//    T4: sitenin hapı yerli çubuğun hapının yerinden (onceki) kayar; bas=false iken yalnız hap kayar
//
//   node Testler/kahin/kabuk_koprusu.mjs
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const { chromium } = createRequire(import.meta.url)('playwright');

const swift = (yol) => readFileSync(new URL(`../../${yol}`, import.meta.url), 'utf8');
const coksatir = (kaynak, bas) => {
  const i = kaynak.indexOf(bas);
  const a = kaynak.indexOf('"""', i) + 3;
  const b = kaynak.indexOf('"""', a);
  // Swift çok satırlı dizgesi: kapanıştaki girinti her satırdan atılır
  const satirlar = kaynak.slice(a, b).split('\n').slice(1);
  const girinti = satirlar[satirlar.length - 1].length;
  return satirlar.slice(0, -1).map((s) => s.slice(girinti)).join('\n');
};
const adresBetigi = coksatir(swift('NoraSanat/Kabuk/Gecis.swift'), 'static let adresBetigi');
const sekmeyeGecBetigi = coksatir(swift('NoraSanat/Kabuk/Gecis.swift'), 'static let sekmeyeGecBetigi');

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage({ viewport: { width: 393, height: 852 } });
await sayfa.addInitScript(() => {
  window.__ileti = [];
  const h = (ad) => ({ postMessage: (x) => window.__ileti.push([ad, JSON.parse(JSON.stringify(x))]) });
  window.webkit = { messageHandlers: { adres: h('adres') } };
});
await sayfa.addInitScript(adresBetigi);
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForFunction(() => window.__atlas && window.__atlas.ilerleme, null, { timeout: 60000 });
await sayfa.waitForTimeout(800);
const al = (ad) => sayfa.evaluate((ad) => window.__ileti.filter((x) => x[0] === ad).map((x) => x[1]), ad);

// Adres
let adresler = await al('adres');
assert.equal(adresler[0], '#/', 'açılışta adres');
await sayfa.evaluate(() => { location.hash = '#/gozat'; });
await sayfa.waitForTimeout(300);
await sayfa.evaluate(() => { location.hash = '#/sanatci/' + window.__atlas.sanatcilar[0].id; });
await sayfa.waitForTimeout(300);
adresler = await al('adres');
assert.deepEqual(adresler.slice(-2), ['#/gozat', '#/sanatci/' + (await sayfa.evaluate(() => window.__atlas.sanatcilar[0].id))]);
console.log('adres köprüsü:', adresler.join(' → '));

// Sekmeye geçiş: sitenin düğmesi kalınan yeri açar (Galeri'de bir sanatçıdaydık → Bugün → Galeri)
const kalinan = await sayfa.evaluate(() => location.hash);
await sayfa.evaluate(() => document.querySelector('#sekmeler a[data-sekme="bugun"]').click());
await sayfa.waitForTimeout(500);
assert.equal(await sayfa.evaluate(() => location.hash), '#/');
// T4: yerli çubukta Çalış (3) seçiliydi; site Galeri'ye geçerken hapı 3'ten kaydırır
const gec = (arg) =>
  sayfa.evaluate(([govde, arg]) => {
    const AsyncFunction = (async () => {}).constructor;
    return new AsyncFunction(...Object.keys(arg), govde)(...Object.values(arg)).then(async (s) => {
      // Geçişin başladığı ve bittiği yer: hapın hareketinin ilk ve son karesi (px). Site çubuğu yönlendirmeden sonra çizer.
      for (let i = 0; i < 60; i++) {
        const isaret = document.querySelector('#sekmeler .sekme-isaret');
        const h = isaret.getAnimations().find((x) => x.transitionProperty === 'transform');
        if (h) {
          const x = () => new DOMMatrix(getComputedStyle(isaret).transform).m41;
          h.pause();
          h.currentTime = 0;
          const ilk = x();
          h.finish();
          return { s, ilk, son: x() };
        }
        await new Promise((r) => setTimeout(r, 16));
      }
      return { s };
    });
  }, [sekmeyeGecBetigi, arg]);
const genislik = await sayfa.evaluate(() => document.querySelector('#sekmeler .sekme-isaret').getBoundingClientRect().width);
let g = await gec({ kimlik: 'gozat', adres: '#/gozat', onceki: 3, bas: true });
assert.equal(g.s, 'dugme');
assert.ok(Math.abs(g.ilk - 3 * genislik) < 0.5 && Math.abs(g.son - 2 * genislik) < 0.5, `hap 3'ten 2'ye kayar: ${JSON.stringify(g)}`);
const donus = await sayfa.evaluate(() => location.hash);
console.log('sekme düğmesi: Galeri →', donus, '(kalınan:', kalinan + ')');
assert.ok(donus === kalinan || donus === '#/gozat', 'Galeri sekmesine geçildi');
// Site zaten Galeri'de: yalnız hap 0'dan (yerli Bugün) Galeri'ye kayar, adres değişmez
await sayfa.waitForTimeout(600);
g = await gec({ kimlik: 'gozat', adres: '#/gozat', onceki: 0, bas: false });
assert.equal(g.s, 'hap');
assert.ok(Math.abs(g.ilk) < 0.5 && Math.abs(g.son - 2 * genislik) < 0.5, `hap 0'dan 2'ye kayar: ${JSON.stringify(g)}`);
await sayfa.waitForTimeout(300);
assert.equal(await sayfa.evaluate(() => location.hash), donus, 'bas=false adresi değiştirmez');
console.log('sekmeye geçiş: hap yerli çubuğun yerinden kayıyor');

console.log('kabuk köprüleri: hepsi geçti');
await tarayici.close();
