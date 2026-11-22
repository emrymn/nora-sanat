// C3 kâhini: dersin adım ekranları (Gör, Öğren, Ayırt et) ve Gör'ün kamerası, canlı sitenin kendi modülleri ve
// ekranlarıyla (js/kamera.js, js/ekranlar/ders.js gorAdimi/ogrenAdimi/ayirtAdimi/adimSonu, js/tasarim.js roma @ a866b86).
// Geçici bir tarayıcı profilinde bütün konular işlenmiş sayılır; her dersin her adımı baştan sona gezilir ve ekranın
// yazıları, Gör kamerasının duruşu (webdriver'da site hareketi kapatır: duruş anında kurulur) ve adım sonları kaydedilir.
//
//   node Testler/kahin/ders_adimlari.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/ders_adimlari/cevaplar.json
import { createRequire } from 'node:module';

const gerektir = createRequire(import.meta.url);
const { chromium } = process.env.CALIS_CHROMIUM ? gerektir('playwright-core') : gerektir('playwright');

const tarayici = await chromium.launch({ executablePath: process.env.CALIS_CHROMIUM || undefined });
try {
  const sayfa = await tarayici.newPage({ viewport: { width: 393, height: 852 }, bypassCSP: true });
  await sayfa.goto(process.env.CALIS_SITE || 'https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
  await sayfa.waitForFunction(() => window.__atlas && window.__atlas.sanatcilar && window.__atlas.ilerleme, null, { timeout: 60000 });

  // 1) Kamera (js/kamera.js), belirlenimli örneklerle
  const kamera = await sayfa.evaluate(async () => {
    const k = await import('/js/kamera.js');
    const t = await import('/js/tasarim.js');
    let x = 20261122;
    const rng = () => ((x = (x * 1664525 + 1013904223) % 4294967296) / 4294967296);
    const durus = () => ({ tx: -rng() * 900 + 100, ty: -rng() * 700 + 120, s: 0.25 + rng() * 3 });
    const ciftler = [];
    for (let i = 0; i < 24; i++) ciftler.push([durus(), durus(), 393, 300 + Math.round(rng() * 200)]);
    // aynı noktada yalnız yakınlaşma
    const a = { tx: -100, ty: 50, s: 1 };
    const g = k.gorusAlani(a, 393, 400);
    ciftler.push([a, k.durusa({ ...g, w: g.w / 3 }, 393, 400), 393, 400]);
    ciftler.push([a, { ...a }, 393, 400]);
    const ornekT = [0, 0.13, 0.37, 0.5, 0.81, 1];
    const yollar = ciftler.map(([a, b, W, orta]) => {
      const y = k.kameraYolu(a, b, W, orta);
      return { a, b, W, orta, sure: y.sure, uzunluk: y.uzunluk, ornekler: ornekT.map((t) => ({ t, p: y.ornek(t) })) };
    });
    const egriX = Array.from({ length: 21 }, (_, i) => i / 20);
    const baska = k.egri(0.25, 0.1, 0.25, 1);
    const egriler = egriX.map((x) => ({ x, kamera: k.KAMERA_EGRI(x), ease: baska(x) }));
    const kareler = (() => {
      const y = k.kameraYolu(ciftler[0][0], ciftler[0][1], ciftler[0][2], ciftler[0][3]);
      return k.kameraKareleri(y, 8).map((kr) => ({ offset: kr.offset, transform: kr.transform }));
    })();
    const roma = Array.from({ length: 40 }, (_, i) => ({ n: i + 1, r: t.roma(i + 1) }));
    return { yollar, egriler, kareler, kareYolu: 0, roma };
  });

  // 2) Ekranlar: bütün konular işlenmiş, dersler boş
  await sayfa.evaluate(async () => {
    const o = await import('/js/ekranlar/ortak.js');
    o.d.ilerleme.islenen = [...new Set(o.d.konular.map((k) => k.no))].sort((a, b) => a - b);
    o.d.ilerleme.dersler = {};
    o.kaydet();
  });
  const git = async (hash, secici) => {
    await sayfa.evaluate((h) => {
      location.hash = h;
    }, hash);
    await sayfa.waitForSelector(secici, { timeout: 60000 });
    await sayfa.waitForTimeout(150);
  };
  const dersler = await sayfa.evaluate(async () => {
    const o = await import('/js/ekranlar/ortak.js');
    const kilit = await import('/js/kilit.js');
    const k = await (await fetch('data/ders_kaynaklari.json')).json();
    const acik = new Set(kilit.akimDurumlari(o.d.akimlar, o.d.sanatcilar, new Set(o.d.ilerleme.islenen)).filter((a) => a.acik).map((a) => a.ad));
    return k.dersler.map((x) => x.akim).filter((a) => acik.has(a));
  });
  const kayit = (akim) => sayfa.evaluate(async (akim) => {
    const o = await import('/js/ekranlar/ortak.js');
    return JSON.parse(JSON.stringify((o.d.ilerleme.dersler || {})[akim] || null));
  }, akim);
  const son = () =>
    sayfa.evaluate(() => {
      const s = document.querySelector('.ders-son');
      return {
        adim: s.dataset.adim || null,
        test: s.dataset.test,
        h2: s.querySelector('h2').textContent,
        p: [...s.querySelectorAll('p')].map((p) => p.textContent),
        dugmeler: [...s.querySelectorAll('.ders-son-dugmeler a')].map((a) => ({ test: a.dataset.test || null, yazi: a.textContent.trim(), adres: a.getAttribute('href') })),
        etiket: document.querySelector('.ders-ust .ders-etiket').textContent,
        baslik: document.querySelector('.ders-ust h1').textContent,
      };
    });

  const cevap = [];
  for (const akim of dersler) {
    const e = encodeURIComponent(akim);
    const ders = { akim, gor: null, ogren: [], ayirt: [], sonlar: {} };

    // Gör
    await git(`#/pekistir/ders/${e}/gor`, '.ders-gor, .ders-son');
    if (await sayfa.$('.ders-gor')) {
      ders.gor = { kareler: [] };
      for (let n = 0; n < 200; n++) {
        await sayfa.waitForSelector('.ders-gor.hazir [data-gor-resim].acik', { timeout: 60000 });
        await sayfa.waitForTimeout(60);
        const k = await sayfa.evaluate(() => {
          const kok = document.querySelector('.ders-gor');
          const img = kok.querySelector('[data-gor-resim]');
          const sahne = kok.querySelector('[data-gor-sahne]').getBoundingClientRect();
          const m = getComputedStyle(img).transform.match(/-?[\d.]+(?:e-?\d+)?/g).map(Number);
          const ileri = kok.querySelector('[data-gor-ileri]');
          return {
            kare: Number(kok.dataset.kare),
            nokta: Number(kok.dataset.nokta),
            eser: kok.querySelector('[data-gor-eser]').textContent,
            baslik: kok.querySelector('[data-gor-baslik]').textContent,
            metin: kok.querySelector('[data-gor-metin]').textContent,
            noktalar: kok.querySelector('[data-gor-noktalar]').getAttribute('aria-label'),
            noktaSiniflari: [...kok.querySelectorAll('[data-gor-noktalar] i')].map((i) => i.className),
            ileri: ileri.textContent,
            geriGizli: kok.querySelector('[data-gor-geri]').hidden,
            alt: img.alt,
            W: sahne.width,
            ust: kok.querySelector('.ders-ust').getBoundingClientRect().bottom - sahne.top + 8,
            altSinir: kok.querySelector('[data-gor-panel]').getBoundingClientRect().top - sahne.top - 8,
            IW: parseFloat(img.style.width),
            IH: parseFloat(img.style.height),
            durus: { s: m[0], tx: m[4], ty: m[5] },
            olcek: kok.dataset.olcek,
          };
        });
        ders.gor.kareler.push(k);
        await sayfa.click('[data-gor-ileri]');
        await sayfa.waitForTimeout(120);
        if (await sayfa.$('.ders-son')) break;
      }
      ders.sonlar.gor = { ...(await son()), kayit: await kayit(akim) };
    } else ders.sonlar.gorYok = await son();

    // Öğren
    await git(`#/pekistir/ders/${e}/ogren`, '.ders-ogren, .ders-son');
    for (let n = 0; n < 40 && (await sayfa.$('.ders-ogren')); n++) {
      ders.ogren.push(
        await sayfa.evaluate(() => {
          const a = document.querySelector('.ders-ogren');
          return {
            madde: Number(a.dataset.madde),
            baslik: document.querySelector('.ders-ust h1').textContent,
            etiket: document.querySelector('.ders-ust .ders-etiket').textContent,
            h2: a.querySelector('.ders-madde').textContent,
            kanit: a.querySelector('[data-kanit-id]')?.dataset.kanitId ?? null,
            kanitYok: a.querySelector('.ders-kanit-yok')?.textContent ?? null,
            kanitSayisi: Number(a.dataset.kanitSayisi),
            aciklamalar: [...a.querySelectorAll('[data-aciklama-id]')].map((p) => ({ id: p.dataset.aciklamaId, yazi: p.textContent })),
            altyazi: a.querySelector('figcaption')?.textContent ?? null,
            serit: [...a.querySelectorAll('[data-ogren-kanit] span')].map((s) => s.textContent),
            ileri: document.querySelector('[data-ogren-ileri]').textContent,
            geri: Boolean(document.querySelector('[data-ogren-geri]')),
          };
        }),
      );
      await sayfa.click('[data-ogren-ileri]');
      await sayfa.waitForSelector(`.ders-son, .ders-ogren[data-madde]:not([data-madde="${ders.ogren.at(-1).madde}"])`, { timeout: 60000 });
    }
    ders.sonlar.ogren = { ...(await son()), kayit: await kayit(akim) };

    // Ayırt et
    await git(`#/pekistir/ders/${e}/ayirt`, '.ders-ayirt, .ders-son');
    for (let n = 0; n < 20 && (await sayfa.$('.ders-ayirt')); n++) {
      const once = await sayfa.evaluate(() => ({
        komsu: document.querySelector('.ders-ayirt').dataset.komsu,
        baslik: document.querySelector('.ders-ust h1').textContent,
        soru: document.querySelector('.ders-soru').textContent,
        soruAlt: document.querySelector('.ders-soru-alt').textContent,
        bos: [...document.querySelectorAll('.ders-ikili-ad.bos')].map((x) => x.textContent),
      }));
      await sayfa.click('[data-ayirt-sec="0"]');
      await sayfa.waitForSelector('[data-test="ders-fark"]', { timeout: 30000 });
      const sonra = await sayfa.evaluate(() => ({
        sonuc: document.querySelector('[data-test="ayirt-sonuc"]').textContent,
        dogru: document.querySelector('[data-test="ayirt-sonuc"]').dataset.dogru === 'true',
        yanlar: [...document.querySelectorAll('.ders-ikili-eser')].map((b) => ({ akim: b.dataset.akim, sinif: b.className.replace('ders-ikili-eser', '').trim(), ad: b.querySelector('.ders-ikili-ad small')?.textContent ?? '' })),
        sutunlar: [...document.querySelectorAll('.ders-fark-sutunlar > div')].map((d) => ({ ad: d.querySelector('b').textContent, maddeler: [...d.querySelectorAll('li')].map((l) => l.textContent) })),
        cumleler: [...document.querySelectorAll('.ders-fark-cumle')].map((c) => ({ cumle: c.querySelector('p').textContent, kaynak: c.querySelector('small').textContent })),
        bag: document.querySelector('.ders-fark-bag').getAttribute('href'),
        ileri: document.querySelector('[data-ayirt-ileri]').textContent,
        geri: Boolean(document.querySelector('[data-ayirt-geri]')),
      }));
      ders.ayirt.push({ ...once, ...sonra });
      const komsu = once.komsu;
      await sayfa.click('[data-ayirt-ileri]');
      await sayfa.waitForSelector(`.ders-son, .ders-ayirt:not([data-komsu="${komsu.replace(/"/g, '\\"')}"]), .ders-ayirt .ders-ikili-ad.bos`, { timeout: 60000 });
    }
    ders.sonlar.ayirt = { ...(await son()), kayit: await kayit(akim) };
    cevap.push(ders);
  }

  // 3) Gör'ün kaldığı yerden açılması (ilk Gör'lü ders)
  const ilkGor = cevap.find((d) => d.gor);
  const baslangiclar = [];
  if (ilkGor) {
    for (const i of [0, 0.05, 0.2, 0.34, 0.5, 0.75, 0.94, 1]) {
      await sayfa.evaluate(
        async ([akim, i]) => {
          const o = await import('/js/ekranlar/ortak.js');
          o.d.ilerleme.dersler = { [akim]: { gor: { i, t: null }, ogren: { i: 0, t: null }, ayirt: { i: 0, t: null } } };
          o.kaydet();
          location.hash = '#/pekistir';
        },
        [ilkGor.akim, i],
      );
      await sayfa.waitForSelector('[data-test="bugunun-dersi"], .bos-kutu', { timeout: 60000 });
      await git(`#/pekistir/ders/${encodeURIComponent(ilkGor.akim)}/gor`, '.ders-gor');
      baslangiclar.push({ akim: ilkGor.akim, i, kare: await sayfa.evaluate(() => Number(document.querySelector('.ders-gor').dataset.kare)) });
    }
  }

  const surum = await sayfa.evaluate(() => (window.__atlas && window.__atlas.surum) || null);
  process.stdout.write(JSON.stringify({ surum, kamera, dersler: cevap, baslangiclar }, null, 1) + '\n');
} finally {
  await tarayici.close();
}
