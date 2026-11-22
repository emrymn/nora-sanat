// G4: simülatörde -yalnizSite ile açılmış gerçek WKWebView üzerinde çalışır.
import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { setTimeout as bekle } from 'node:timers/promises';
import { RemoteDebugger } from 'appium-remote-debugger';
import { getSimulator } from 'appium-ios-simulator';

const [udid, bundle, liste] = process.argv.slice(2);
const simulator = await getSimulator(udid);
const socketPath = await simulator.getWebInspectorSocket();
if (!socketPath) throw Error('Simülatörde Web Inspector bulunamadı.');
const platformVersion = execFileSync('xcrun', ['simctl','getenv',udid,'SIMULATOR_RUNTIME_VERSION'], {encoding:'utf8'}).trim();
if (!platformVersion) throw Error('Simülatörün iOS sürümü okunamadı.');
const web = new RemoteDebugger({ bundleId: bundle, socketPath, platformVersion, logFullResponse: false });

async function beklenen(oku, ad) {
  for (let i = 0; i < 40; i++) {
    try {
      const sonuc = await oku();
      if (sonuc) return sonuc;
    } catch (hata) {
      if (i === 39) throw hata;
    }
    await bekle(750);
  }
  throw Error(ad + ' hazır olmadı');
}

// Her iki konumda da gerçek ayrıntı ve bir biyografi olmalı. Konumları sitenin
// kendi ölçümünden al; Swift tarafı bağımsız hesapladığı konumu doğrular.
function hedef(bolum) {
  if (bolum.startsWith('ayrinti-')) {
    const adimlar = [...document.querySelectorAll('.yur-adim')];
    const i = adimlar.findIndex((a, i) => i >= 2 && i < 2 + window.g4NoktaSayisi &&
      a.classList.contains('kart-ustte') === (bolum === 'ayrinti-ust') && a.dataset.gorunen);
    if (i < 0) return null;
    const el = adimlar[i];
    return {el, y: scrollY + el.getBoundingClientRect().top, adim:i, soz:el.querySelector('h2').textContent};
  }
  const secici = {hayati:'.yur-hayat', eserler:'[data-test="yur-eserler"]', tur:'[data-test="yur-tur"]'}[bolum];
  const el = document.querySelector(secici);
  if (!el || !document.querySelector('[data-yur-bio] h2')) return null;
  const oran = {hayati:0, eserler:0.5, tur:0.85}[bolum];
  const r = el.getBoundingClientRect();
  const y = scrollY + r.top - (innerHeight - r.height) * oran;
  return {el, y, adim:0, soz:{hayati:'Hayat', eserler:'eserleri', tur:'Bugünkü'}[bolum]};
}

try {
  await web.connect();
  const sayfa = await beklenen(async () => (await web.selectApp(null, 1, true))
    .find(p => p.url?.startsWith('https://sanat-atlasi.pages.dev/')), 'Bugün sayfası');
  await web.selectPage(...sayfa.id.split('.'), true);
  await beklenen(() => web.execute("!!document.querySelector('.yur-kapak')"), 'Kapak');
  const satirlar = [];
  for (const id of ['andrea-mantegna','ambrogio-lorenzetti','fra-angelico','sandro-botticelli']) {
    // Sadece bu WebView belleğindeki günlük seçimi kullan. Simülatör kaydına yazma.
    await web.execute(`void (async () => {
      const o = await import('/js/ekranlar/ortak.js');
      const b = await import('/js/ekranlar/bugun.js');
      o.d.ilerleme.gununDegisim = {tarih:o.bugun(), id:${JSON.stringify(id)}};
      window.g4NoktaSayisi = o.d.yuruyus[o.gununId()].noktalar.length;
      b.anaSayfa();
    })()`);
    await bekle(4000);
    const bolumler = ['ayrinti-alt','ayrinti-ust','hayati','eserler','tur'];
    const sorgu = bolum => '(' + hedef.toString() + ')(' + JSON.stringify(bolum) + ')';
    if (!await web.execute(bolumler.map(b => '!!' + sorgu(b)).join(' && '))) continue;
    for (const bolum of bolumler) {
      const t = sorgu(bolum);
      await web.execute(`(() => { const h=${t}; window.scrollTo({top:h.y, behavior:'instant'}); })()`);
      await bekle(4200);
      const bilgi = await web.execute(`(() => {
        const h=${t}, r=h.el.getBoundingClientRect();
        const kontrol=h.adim ? h.el.querySelector('.yur-kart') : h.el.querySelector('[data-yur-bio] h2') || h.el;
        const k=kontrol.getBoundingClientRect();
        if (k.top < -2 || k.bottom > innerHeight + 2) throw Error('Bölüm görünmüyor: '+h.soz+' '+k.top);
        return {adim:h.adim, soz:h.soz};
      })()`);
      execFileSync('xcrun', ['simctl','io',udid,'screenshot','ekranlar/bugun-site-'+bolum+'.png'], {stdio:'inherit'});
      satirlar.push([bolum,id,bilgi.adim,bilgi.soz].join('|'));
    }
    break;
  }
  if (satirlar.length !== 5) throw Error('İki kart konumuna uygun eser bulunamadı.');
  writeFileSync(liste,satirlar.join('\n')+'\n');
} finally {
  await web.disconnect();
}
