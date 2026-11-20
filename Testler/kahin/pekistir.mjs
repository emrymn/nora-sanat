// Kaynak: sanat-atlasi js/oturum.js, js/turlar.js, js/celdirici.js @ a866b86
// Varsayılan canlı site. Çevrimdışı karşılaştırma için ilk argüman site deposunun yoludur.
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

async function cevaplar(kok) {
  const { kartlariSec, Oturum } = await import(kok + '/oturum.js');
  const { konuTuru, hatalarTuru } = await import(kok + '/turlar.js');
  const { sanatciSecenekleri } = await import(kok + '/celdirici.js');
  const rng = () => 0.42;
  const bugun = '2026-11-21';
  const adaylar = Array.from({ length: 8 }, (_, i) => ({
    id: String(i), ad: 'Ressam ' + i, akim: i < 4 ? 'A' : 'B', dogum: 1600 + i,
  }));
  const akimlar = [{ ad: 'A', sira: 1, komsular: ['B'] }, { ad: 'B', sira: 2, komsular: ['A'] }];
  const zayif = { kutu: 0, son: bugun, sonraki: bugun, yanlis: 1 };
  const skorlar = { 1: { sanatci: zayif }, 6: { akim: zayif } };
  const karisanlar = { '0|3': { n: 3, son: bugun }, '0|4': { n: 2, son: bugun } };
  const kartlar = (kip, sirala) => kartlariSec({ adaylar, skorlar, bugun, adet: 7, yeniKota: 2, kip, sirala, rng }).map(s => s.id);
  const hatalar = hatalarTuru({ adaylar, skorlar, karisanlar, bugun, rng });
  const o = new Oturum(adaylar.map(s => s.id), { rng });
  const kuyruk = [];
  while (!o.bitti) {
    kuyruk.push(o.simdiki.id);
    o.isle(o.simdiki.id !== '0');
    o.ilerle();
  }
  return {
    donem: kartlar('donem', 'oncelik'), karisik: kartlar('karisik', 'agirlikli'),
    konu: konuTuru(adaylar.slice(0, 3), skorlar, rng), hatalar: hatalar.idler, kuyruk,
    secenekler: sanatciSecenekleri(adaylar[0], { sanatcilar: adaylar, akimlar, acikIdler: new Set(['2']), haric: ['1'], rng }).map(s => s.id),
  };
}

let sonuc;
if (process.argv[2]) {
  sonuc = await cevaplar(pathToFileURL(resolve(process.argv[2], 'js')).href);
} else {
  const { chromium } = await import('playwright');
  const tarayici = await chromium.launch({ headless: true });
  try {
    const sayfa = await tarayici.newPage();
    await sayfa.goto('https://sanat-atlasi.pages.dev');
    sonuc = await sayfa.evaluate(cevaplar, '/js');
  } finally {
    await tarayici.close();
  }
}
console.log(JSON.stringify(sonuc, null, 2));
