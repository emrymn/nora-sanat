// Kaynak: sanat-atlasi css/app.css, js/ekranlar/{harita,zaman}.js @ a866b86
import { createRequire } from 'node:module';
const { webkit, devices } = createRequire(import.meta.url)('playwright');
const browser = await webkit.launch();
try {
  const page = await browser.newPage({ ...devices['iPhone 15 Pro'], locale: 'tr-TR' });
  for (const [adres, seciciler] of Object.entries({
    harita: ['.harita', '.harita-ust', '.harita-ust h1', '.kurs-rozet', '.harita-vakit', '.harita-durak'],
    zaman: ['.zm-panel', '.zm-okur', '.zm-yil b', '.zm-adim', '.zm-cetvel', '.zm-ipucu', '.zm-akim', '.zm-kare', '.zm-satir'],
  })) {
    await page.goto('https://sanat-atlasi.pages.dev/#/' + adres, { waitUntil: 'domcontentloaded' });
    await page.locator(seciciler.at(-1)).first().waitFor({ state: 'attached' });
    await page.evaluate(() => document.fonts.ready);
    for (const secici of seciciler) {
      const deger = await page.locator(secici).first().evaluate(el => {
        const s = getComputedStyle(el);
        return [s.width, s.height, s.fontSize, s.lineHeight, s.padding, s.borderRadius];
      });
      console.log(secici, ...deger);
    }
  }
} finally { await browser.close(); }
