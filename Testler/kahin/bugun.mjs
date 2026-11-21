// Kaynak: sanat-atlasi js/yuruyus.js, js/egim.js @ a866b86
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

async function cevaplar(kok) {
  const { noktaAdimi } = await import(kok + '/js/yuruyus.js');
  const { donusIzle, donustenEgim } = await import(kok + '/js/egim.js');
  const noktalar = [];
  for (const IW of [1800, 4000]) {
    const IH = IW === 1800 ? 4000 : 2000;
    for (const y of [0, 0.48, 0.84]) {
      for (const kartH of [104, 318]) {
        const n = { x: 0.28, y, w: 0.32, h: 0.16 };
        const kirp = [0.03, 0.04, 0.94, 0.92];
        const W = 393, H = 852, ust = 68, alt = 112;
        const kapla = Math.max(W / (IW * kirp[2]), H / (IH * kirp[3]));
        const sonuc = noktaAdimi(n, { W, H, IW, IH, kirp, kartH, ust, alt, kapla });
        noktalar.push({ IW, IH, n, kartH, sonuc });
      }
    }
  }
  let durum = { x: 0, y: 0 };
  const egim = [0, 240, -160, 0, 50].map(hiz => {
    durum = donusIzle(durum, { beta: -hiz, gamma: hiz }, 0.2);
    const { x, y } = donustenEgim(durum);
    return { hiz, x, y };
  });
  return { noktalar, egim };
}

if (process.argv[2]) {
  console.log(JSON.stringify(await cevaplar(pathToFileURL(resolve(process.argv[2])).href)));
} else {
  const { webkit, devices } = createRequire(import.meta.url)('playwright');
  const b = await webkit.launch();
  try {
    const p = await b.newPage({ ...devices['iPhone 15 Pro'], viewport: { width: 393, height: 852 } });
    await p.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'domcontentloaded' });
    await p.waitForSelector('.yur-kapak .ad-son');
    await p.evaluate(() => document.fonts.ready);
    const olculer = await p.evaluate(() => Object.fromEntries(
      ['.bugun-alt', '.ad-son', '.ad-ilk', '.bugun-eser', '.bugun-dugme', '.bugun-ben', '.yur-kart', '.yur-kart h2', '.yur-kart p', '.yur-hayat', '.yur-tur'].flatMap(s => {
        const el = document.querySelector(s);
        if (!el) return [];
        const st = getComputedStyle(el);
        return [[s, Object.fromEntries(['font-size','line-height','margin','padding','border-radius','height','left','bottom'].map(k => [k, st.getPropertyValue(k)]))]];
      })));
    console.error('G4 iPhone 15 Pro', JSON.stringify(olculer));
    console.log(JSON.stringify(await p.evaluate(cevaplar, locationKoku())));
  } finally { await b.close(); }
}

function locationKoku() { return 'https://sanat-atlasi.pages.dev'; }
