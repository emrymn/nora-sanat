// IlerlemeKoprusu betiklerini canlı sitede sınar (NoraSanat/Kabuk/IlerlemeKoprusu.swift'teki metin aynen kullanılır).
// WKWebView'in callAsyncJavaScript'i gövdeyi argümanlı bir async fonksiyon olarak çalıştırır; burada da öyle.
//
//   node Testler/kahin/ilerleme_koprusu.mjs   (Playwright gerekir; hata varsa çıkış kodu 1)
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const { chromium } = createRequire(import.meta.url)('playwright');

const kaynak = readFileSync(new URL('../../NoraSanat/Kabuk/IlerlemeKoprusu.swift', import.meta.url), 'utf8');
const ara = (bas, son) => kaynak.split(bas)[1].split(son)[0];
const OKU = ara('/* OKU-BASI */', '/* OKU-SONU */');
const YAZ = ara('/* YAZ-BASI */', '/* YAZ-SONU */');

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage();
const calistir = (govde, arg = {}) =>
  sayfa.evaluate(
    ([g, a]) => {
      const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
      return new AsyncFunction(...Object.keys(a), g)(...Object.values(a));
    },
    [govde, arg],
  );

// Site daha yüklenmeden çağrı: betik ilerleme gelene kadar bekler
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'commit', timeout: 90000 });
await sayfa.waitForFunction(() => document.readyState !== 'loading');
const ilk = JSON.parse(await calistir(OKU));
assert.ok(Array.isArray(ilk.islenen), 'okuma: islenen yok');
console.log('oku: tamam, kayitNo', ilk.kayitNo);

// Yazma: bilinmeyen alan da gider; site kaydeder, kayitNo artar
const yeni = { ...ilk, islenen: [...new Set([...ilk.islenen, 7, 8])].sort((a, b) => a - b), noraDeneme: { swift: true } };
yeni.gecmis = { ...ilk.gecmis, '2026-11-20': { kart: 12, dogru: 9, akimlar: { Barok: 12 } } };
const y = await calistir(YAZ, { metin: JSON.stringify(yeni), beklenen: ilk.kayitNo });
assert.match(y, /^tamam:\d+$/);
const no = Number(y.slice(6));
assert.ok(no > ilk.kayitNo, 'kayitNo artmadı');
console.log('yaz:', y);

// Eski kayıt numarasıyla yazma reddedilir
assert.equal(await calistir(YAZ, { metin: JSON.stringify(ilk), beklenen: ilk.kayitNo }), 'cakisma');
console.log('çakışma: reddedildi');

// localStorage'a sitenin kendi kaydıyla gitti; yeniden açınca site okuyor
const ls = JSON.parse(await sayfa.evaluate(() => localStorage.getItem('sanat-atlasi:ilerleme')));
assert.equal(ls.kayitNo, no);
assert.deepEqual(ls.noraDeneme, { swift: true });
await sayfa.waitForTimeout(800); // IndexedDB yansısı (300 ms)
await sayfa.goto('https://sanat-atlasi.pages.dev/#/ilerleme', { waitUntil: 'networkidle' });
const ikinci = JSON.parse(await calistir(OKU));
assert.ok(ikinci.islenen.includes(7) && ikinci.islenen.includes(8), 'yeniden açınca işlenen konular yok');
assert.equal(ikinci.gecmis['2026-11-20'].kart, 12);
assert.deepEqual(ikinci.noraDeneme, { swift: true });
console.log('yeniden açılış: site Swift\'in yazdığını okudu, kayitNo', ikinci.kayitNo);
await sayfa.screenshot({ path: process.env.EKRAN || '/tmp/ilerleme_koprusu.png' });
await tarayici.close();
console.log('hepsi geçti');
