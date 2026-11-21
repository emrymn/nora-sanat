// Kaynak: sanat-atlasi js/yuruyus.js, js/egim.js @ a866b86
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { readFile } from 'node:fs/promises';
import { runInNewContext } from 'node:vm';

async function cevaplar(site) {
  const { noktaAdimi, yuruyusBaslat } = await import(site + '/js/yuruyus.js');
  const { donusIzle, donustenEgim } = await import(site + '/js/egim.js');
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
  // Siteye ekran, görsel ve kart ölçülerini ver; ürettiği gerçek CSS dönüşümlerini oku.
  const sinif = { add() {}, remove() {}, toggle() {} };
  const kutu = () => ({ style:{setProperty() {}}, classList:sinif, dataset:{} });
  const resim = { ...kutu(), naturalWidth:4000, naturalHeight:2000, complete:true, addEventListener() {} };
  const bolumler = Array.from({length:4}, () => ({ ...kutu(), offsetHeight:852, querySelector:()=>({offsetHeight:104}) }));
  const noktalarDugumu = { ...kutu(), children:bolumler.map(kutu) };
  const akis = { ...kutu(), querySelectorAll:()=>bolumler, querySelector:()=>null };
  const kok = { ...kutu(), isConnected:true, querySelector:s =>
    s === '[data-yur-akis]' ? akis : s === '.yur-noktalar' ? noktalarDugumu : kutu() };
  const geriAl = [];
  function gecici(nesne, ad, deger) {
    const eski = Object.getOwnPropertyDescriptor(nesne, ad);
    Object.defineProperty(nesne, ad, {value:deger, writable:true, configurable:true});
    geriAl.push(() => eski ? Object.defineProperty(nesne,ad,eski) : delete nesne[ad]);
  }
  let kare;
  const kareler = [], izleme = [];
  try {
    if (!globalThis.window) gecici(globalThis,'window',{addEventListener() {},removeEventListener() {}});
    if (!globalThis.document) gecici(globalThis,'document',{documentElement:kutu()});
    gecici(window,'innerWidth',393);
    gecici(window,'scrollY',0);
    gecici(globalThis,'getComputedStyle',()=>({getPropertyValue:()=>'68px',paddingBottom:'112px'}));
    gecici(globalThis,'requestAnimationFrame',f=>{ kare=f; return 1; });
    const n = {x:0.28,y:0.48,w:0.32,h:0.16};
    yuruyusBaslat({kok,img:resim,kayit:{kirp:[0.03,0.04,0.94,0.92],noktalar:[n]},odak:[31,38],
      yakin:1.25,kucukUrl:'',hareketsiz:true});
    for (const adim of [0,0.25,0.5,1,1.75,2,2.4,3]) {
      window.scrollY = adim*852;
      kare(performance.now());
      const sonuc = resim.style.transform.match(/translate3d\(([-.\d]+)px, ([-.\d]+)px, 0\) scale\(([-.\d]+)\)/);
      if (!sonuc) throw Error('Kamera dönüşümü okunamadı.');
      kareler.push({adim,x:Number(sonuc[1]),y:Number(sonuc[2]),s:Number(sonuc[3])});
    }
    window.scrollY = 852;
    const iz = yuruyusBaslat({kok,img:resim,kayit:{noktalar:[]},odak:[50,40],kucukUrl:'',hareketsiz:false});
    for (let i=0; i<8; i++) { kare(performance.now()); izleme.push(iz.kamera); }
    if (document.fonts) await document.fonts.ready;
  } finally {
    kok.isConnected = false;
    for (const geri of geriAl.reverse()) geri();
  }
  return { noktalar, egim, kareler, izleme };
}

if (process.argv[2]) {
  const yol = resolve(process.argv[2]);
  const c = await cevaplar(pathToFileURL(yol).href);
  const kaynak = await readFile(resolve(yol,'js/ekranlar/bugun.js'),'utf8');
  const bas = kaynak.indexOf('function yuruyusSonu('), bit = kaynak.indexOf('export function seritUst(',bas);
  if (bas < 0 || bit < 0) throw Error('Yürüyüş sonu yordamı bulunamadı.');
  c.turlar = [0,1,5,8,100].map(adet => {
    const html = runInNewContext(kaynak.slice(bas,bit)+'\nyuruyusSonu({id:"ornek",ad:"Örnek"})',{
      turBilgisi:()=>({toplam:adet}), ikon:()=>'', bilinenAd:ad=>ad, d:{kisaAdlar:{}}, kacis:s=>s, kunye:()=>''
    });
    return {adet,adres:html.match(/href="([^"]+)" data-test="yur-tur"/)[1],
      baslik:html.match(/class="yur-tur-baslik">([^<]+)/)[1],
      alt:html.match(/class="yur-tur-baslik">[^<]+<\/span><small[^>]*>([^<]+)/)[1]};
  });
  console.log(JSON.stringify(c));
} else {
  const { webkit, devices } = createRequire(import.meta.url)('playwright');
  const b = await webkit.launch();
  try {
    const p = await b.newPage({ ...devices['iPhone 15 Pro'], viewport: { width: 393, height: 852 }, serviceWorkers:'block' });
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
    const c = await p.evaluate(cevaplar, 'https://sanat-atlasi.pages.dev');
    await p.route('**/js/ekranlar/bugun.js?g4', async route => {
      const yanit = await route.fetch({url:'https://sanat-atlasi.pages.dev/js/ekranlar/bugun.js'});
      const kaynak = await yanit.text();
      const imza = "export function turBilgisi(kip = 'karisik', akim = null) {";
      if (!kaynak.includes(imza)) throw Error('Tur bilgisi kaynakta bulunamadı.');
      await route.fulfill({contentType:'text/javascript',body:kaynak.replace(imza,imza+' return {toplam:testAdedi};')
        + '\nlet testAdedi; export function kartSinamasi(n,s){testAdedi=n;return yuruyusSonu(s)}'});
    });
    c.turlar = await p.evaluate(async () => {
      const o = await import('/js/ekranlar/ortak.js'), m = await import('/js/ekranlar/bugun.js?g4');
      return [0,1,5,8,100].map(adet => {
        const kutu = document.createElement('div');
        kutu.innerHTML = m.kartSinamasi(adet,o.d.harita.get(o.gununId()));
        const kart = kutu.querySelector('[data-test=yur-tur]');
        return {adet,adres:kart.getAttribute('href'),baslik:kart.querySelector('.yur-tur-baslik').textContent,
          alt:kart.querySelector('small').textContent};
      });
    });
    console.log(JSON.stringify(c));
  } finally { await b.close(); }
}
