// IlerlemeKoprusu betiklerini (Z2b: taşıma okuması ve ayna) canlı sitede sınar (NoraSanat/Kabuk/IlerlemeKoprusu.swift'teki metin aynen kullanılır).
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
const AYNA = ara('/* AYNA-BASI */', '/* AYNA-SONU */');

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

// Z2b ayna: Swift'teki kayıt sitenin belleğine ve deposuna yazılır; sitede olup Swift'te olmayan alan silinir
const yeni = { ...ilk, islenen: [...new Set([...ilk.islenen, 7, 8])].sort((a, b) => a - b) };
yeni.gecmis = { ...ilk.gecmis, '2026-11-20': { kart: 12, dogru: 9, akimlar: { Barok: 12 } } };
yeni.ayarlar = { ...ilk.ayarlar, tema: 'gunduz' };
delete yeni.sonSurum;
assert.equal(await calistir(AYNA, { metin: JSON.stringify(yeni) }), true);
const bellek = JSON.parse(await calistir(OKU));
assert.deepEqual(bellek.islenen, yeni.islenen);
assert.ok(!('sonSurum' in bellek), 'Swift\'te olmayan alan sitede kaldı');
console.log('ayna: bellek tamam');

// localStorage'a sitenin kendi kaydıyla gitti; yeniden açınca site Swift'in yazdığını okuyor
const ls = JSON.parse(await sayfa.evaluate(() => localStorage.getItem('sanat-atlasi:ilerleme')));
assert.deepEqual(ls.islenen, yeni.islenen);
await sayfa.waitForTimeout(800); // IndexedDB yansısı (300 ms)
await sayfa.goto('https://sanat-atlasi.pages.dev/#/ilerleme', { waitUntil: 'networkidle' });
const ikinci = JSON.parse(await calistir(OKU));
assert.ok(ikinci.islenen.includes(7) && ikinci.islenen.includes(8), 'yeniden açınca işlenen konular yok');
assert.equal(ikinci.gecmis['2026-11-20'].kart, 12);
assert.equal(ikinci.ayarlar.tema, 'gunduz');
console.log('yeniden açılış: site aynayı okudu, kayitNo', ikinci.kayitNo);
await sayfa.screenshot({ path: process.env.EKRAN || '/tmp/ilerleme_koprusu.png' });
await tarayici.close();
console.log('hepsi geçti');
