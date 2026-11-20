// Kabuk kâhini (T3): sitenin kendi çalışan hâliyle
//  1) sekmeler: bir adreste sekme çubuğunda hangi sekme seçili (yoksa çubuk gizli → null)
//  2) tema: <html>'nin hesaplanmış renk değişkenleri gece, nötr gündüz ve renkli gündüzde (hazır palet "lapis")
//
//   node Testler/kahin/kabuk.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/kabuk/cevaplar.json
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');

// {s}, {s2}: görünür sanatçılar; {a}, {a2}: akımlar; {k}: konu; {kg}: konu grubu; {b}: başyapıt; {d}: ders (sitenin verisinden)
const ADRESLER = [
  '', '#/', '#', '#/gozat', '#/ara', '#/zaman', '#/akim/{a}', '#/sanatci/{s}', '#/sanatci/{s}/eserler',
  '#/karsilastir/{s}/{s2}', '#/akim-karsilastir/{a}/{a2}', '#/basyapitlar', '#/konular', '#/konular/{kg}',
  '#/konu/{k}', '#/basyapit/{b}', '#/basyapit/{b}/ders', '#/pekistir', '#/pekistir/donem', '#/pekistir/ders/{d}',
  '#/pekistir/ders/{d}/sina', '#/ilerleme', '#/ayarlar', '#/koleksiyon', '#/harita', '#/gunun', '#/gunun/{s}',
  '#/olmayan-sayfa', '#/HARITA',
  // Sekmesiz sayfalar (pekiştirme kartı, ders adımları) en sona: oturum başlatırlar
  '#/pekistir/ders/{d}/gor', '#/pekistir/karisik', '#/pekistir/hatalar', '#/pekistir/konu/{k2}', '#/pekistir/bolum',
  '#/pekistir/ikonografi', '#/pekistir/bolum/3-1/kolay', '#/pekistir/donem/{a}',
];

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage({ viewport: { width: 393, height: 852 } });
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForFunction(() => window.__atlas && window.__atlas.ilerleme, null, { timeout: 60000 });

const yerine = await sayfa.evaluate(async () => {
  const o = await import('/js/ekranlar/ortak.js');
  const { d } = o;
  const ik = await (await fetch('/data/ikonografi.json')).json();
  // Yayımlanmış bir başyapıt: listenin kendi bağlantısından
  location.hash = '#/basyapitlar';
  let bag = null;
  for (let i = 0; i < 50 && !bag; i++) {
    await new Promise((r) => setTimeout(r, 100));
    bag = document.querySelector('a[href^="#/basyapit/"]');
  }
  const kon = ik.konular[0];
  return {
    s: d.sanatcilar[0].id, s2: d.sanatcilar[1].id, a: encodeURIComponent(d.akimlar[0].ad), a2: encodeURIComponent(d.akimlar[1].ad),
    k: kon.id, kg: kon.tur, k2: d.konular[0].no, d: d.konular[0].no, b: bag.getAttribute('href').slice('#/basyapit/'.length),
  };
});
console.error('yerine', JSON.stringify(yerine));

// Sitenin yönlendirmesinin seçtiği sekme: rotalar sekmeleriCiz'i eşzamanlı çağırır; hashchange'den hemen sonra okunur
const sekmeler = [];
for (const sablon of ADRESLER) {
  const a = sablon.replace(/\{(\w+)\}/g, (_, k) => yerine[k]);
  const s = await sayfa.evaluate(async (a) => {
    await new Promise((r) => {
      addEventListener('hashchange', () => setTimeout(r, 0), { once: true });
      location.hash = a === '' ? '#/x-gecici' : a;
      if (a === '') setTimeout(() => { location.hash = ''; }, 0);
    });
    if (a === '') await new Promise((r) => setTimeout(r, 50));
    const nav = document.getElementById('sekmeler');
    if (nav.hidden) return null;
    const secili = nav.querySelector('a[aria-current="page"]');
    return secili ? secili.dataset.sekme : null;
  }, a);
  sekmeler.push([a, s]);
}

const DEGISKENLER = [
  '--bg', '--surface', '--border', '--ink', '--ink-2', '--ink-3', '--ink-soluk', '--right', '--right-ikon', '--right-bg',
  '--wrong', '--wrong-ikon', '--wrong-bg', '--tab-bg', '--overlay-btn', '--vurgu', '--vurgu-yazi', '--vurgu-acik',
  '--vurgu-acik-yazi', '--vurgu-koyu', '--notr-kenar', '--notr-yuzey', '--pirinc', '--pirinc-yazi',
];
const tema = {};
for (const [ad, t, renk] of [['gece', 'gece', 'notr'], ['gunduz', 'gunduz', 'notr'], ['gunduzLapis', 'gunduz', 'lapis']]) {
  tema[ad] = await sayfa.evaluate(async ([t, renk, DEGISKENLER]) => {
    const o = await import('/js/ekranlar/ortak.js');
    o.d.ilerleme.ayarlar.tema = t;
    o.d.ilerleme.ayarlar.gunduzRenk = renk;
    o.temaUygula();
    await new Promise((r) => setTimeout(r, 300));
    const st = getComputedStyle(document.documentElement);
    return {
      dataTema: document.documentElement.getAttribute('data-tema'),
      themeColor: document.querySelector('meta[name="theme-color"]').getAttribute('content'),
      degiskenler: Object.fromEntries(DEGISKENLER.map((v) => [v, st.getPropertyValue(v).trim()])),
    };
  }, [t, renk, DEGISKENLER]);
}

console.log(JSON.stringify({ surum: (await sayfa.evaluate(() => import('/js/surum.js').then((m) => m.SURUM))), sekmeler, tema }, null, 1));
await tarayici.close();
