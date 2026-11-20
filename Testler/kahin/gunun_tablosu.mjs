// Günün tablosu kâhini: sitenin gununSanatcisi(gununHavuzu()) seçimi (2026-01-01'den 800 gün, 3 günde bir)
// ve havuzdaki her tablonun adı, yılı, görsel adresi. Çıktı: stdout JSON.
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage();
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForTimeout(4000);
const sonuc = await sayfa.evaluate(async () => {
  const o = await import('/js/ekranlar/ortak.js');
  const g = await import('/js/gunun.js');
  const gr = await import('/js/gorsel.js');
  const es = await import('/js/eserler.js');
  const havuz = o.gununHavuzu();
  const tablo = {};
  for (const id of havuz) {
    const k = o.d.yuruyus[id];
    const s = o.d.harita.get(id);
    tablo[id] = { ad: s.ad, eser: o.yuruyusEserAdi(id, k), yil: k && !es.yilSupheliMi(k.yil, s) ? k.yil : null, gorsel: gr.yuruyusAdresleri(k.gorsel, k.buyuk).kucuk };
  }
  const iki = (n) => String(n).padStart(2, '0');
  const secim = [];
  for (let i = 0; i < 800; i += 3) {
    const t = new Date(2026, 0, 1 + i, 12);
    const s = `${t.getFullYear()}-${iki(t.getMonth() + 1)}-${iki(t.getDate())}`;
    secim.push([s, g.gununSanatcisi(havuz, s)]);
  }
  return { tablo, secim };
});
console.log(JSON.stringify(sonuc));
await tarayici.close();
