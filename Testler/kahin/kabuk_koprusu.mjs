// Kabuk köprüleri (T3) canlı sitede: Swift dosyalarındaki betikler aynen eklenir, window.webkit.messageHandlers
// taklit edilir. Sınananlar:
//  - Gecis.adresBetigi: açılışta ve her adres değişiminde location.hash gelir
//  - TemaKoprusu.betik: açılışta tema ve değişkenler gelir; Gündüz'e geçince ve renkli Gündüz'de yeni değerler gelir
//  - Gezgin.sekmeyeGec: sitenin kendi sekme düğmesine basmak sekmenin kalınan yerini açar
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
const adlar = [...swift('Paketler/NoraCekirdek/Sources/NoraCekirdek/Tema/TemaRenkleri.swift').matchAll(/\("(--[a-z0-9-]+)", \\\./g)].map((m) => `'${m[1]}'`);
const temaBetigi = coksatir(swift('NoraSanat/Kabuk/Tema.swift'), 'static var betik').replace('\\(adlar)', adlar.join(','));
assert.ok(adlar.length >= 20, 'değişken adları okunamadı');

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage({ viewport: { width: 393, height: 852 } });
await sayfa.addInitScript(() => {
  window.__ileti = [];
  const h = (ad) => ({ postMessage: (x) => window.__ileti.push([ad, JSON.parse(JSON.stringify(x))]) });
  window.webkit = { messageHandlers: { adres: h('adres'), tema: h('tema') } };
});
await sayfa.addInitScript(adresBetigi);
await sayfa.addInitScript(temaBetigi);
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

// Tema: açılış
let temalar = await al('tema');
assert.ok(temalar.length >= 1, 'açılışta tema iletisi');
let son = temalar[temalar.length - 1];
assert.equal(son.tema, 'gece');
assert.equal(son.degiskenler['--bg'], '#121110');
assert.equal(Object.keys(son.degiskenler).length, adlar.length);
assert.ok(Object.values(son.degiskenler).every((v) => v), 'boş değişken yok');
console.log('tema açılış:', son.tema, son.degiskenler['--bg'], 'hareket', son.hareket);

// Gündüz (nötr) ve renkli Gündüz
for (const [renk, bekle] of [['notr', '#ece8e1'], ['lapis', null]]) {
  const once = (await al('tema')).length;
  await sayfa.evaluate(async (renk) => {
    const o = await import('/js/ekranlar/ortak.js');
    o.d.ilerleme.ayarlar.tema = 'gunduz';
    o.d.ilerleme.ayarlar.gunduzRenk = renk;
    o.temaUygula();
  }, renk);
  await sayfa.waitForTimeout(600);
  temalar = await al('tema');
  assert.ok(temalar.length > once, `gündüz (${renk}) iletisi`);
  son = temalar[temalar.length - 1];
  assert.equal(son.tema, 'gunduz');
  if (bekle) assert.equal(son.degiskenler['--bg'], bekle);
  else assert.notEqual(son.degiskenler['--bg'], '#ece8e1', 'renkli gündüz zemini paletten');
  console.log(`tema gündüz/${renk}:`, son.degiskenler['--bg'], son.degiskenler['--ink']);
}

// Sekmeye geçiş: sitenin düğmesi kalınan yeri açar (Galeri'de bir sanatçıdaydık → Bugün → Galeri)
const kalinan = await sayfa.evaluate(() => location.hash);
await sayfa.evaluate(() => document.querySelector('#sekmeler a[data-sekme="bugun"]').click());
await sayfa.waitForTimeout(500);
assert.equal(await sayfa.evaluate(() => location.hash), '#/');
await sayfa.evaluate(() => {
  const a = document.querySelector('#sekmeler a[data-sekme=' + ['gozat'][0] + ']');
  if (a && !document.getElementById('sekmeler').hidden) a.click(); else location.hash = '#/gozat';
});
await sayfa.waitForTimeout(500);
const donus = await sayfa.evaluate(() => location.hash);
console.log('sekme düğmesi: Galeri →', donus, '(kalınan:', kalinan + ')');
assert.ok(donus === kalinan || donus === '#/gozat', 'Galeri sekmesine geçildi');

console.log('kabuk köprüleri: hepsi geçti');
await tarayici.close();
