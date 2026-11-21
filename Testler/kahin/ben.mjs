// Kaynak: sanat-atlasi js/ekranlar/{ilerleme,ayarlar,pano}.js ve js/depo.js @ a866b86
// Temiz, geçici tarayıcı profili. Standart çıktı BenTests'in beklediği JSON'dur.
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import assert from 'node:assert/strict';
const gerektir = createRequire(import.meta.url);
const { chromium } = process.env.BEN_CHROMIUM ? gerektir('playwright-core') : gerektir('playwright');
const oku = yol => readFileSync(new URL(yol, import.meta.url), 'utf8');
const girdi = JSON.parse(oku('../../Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/ben/girdi.json'));
const swift = oku('../../NoraSanat/Ekranlar/Ben/BenDeposu.swift');
function betik(ad) {
  const bas = 'static let ' + ad + ' = """';
  assert.ok(swift.includes(bas), ad);
  return swift.split(bas)[1].split('"""')[0];
}
const tarayici = await chromium.launch({ executablePath: process.env.BEN_CHROMIUM || undefined });
try {
  const sayfa = await tarayici.newPage({ bypassCSP: true });
  await sayfa.goto(process.env.BEN_SITE || 'https://sanat-atlasi.pages.dev/', { waitUntil: 'domcontentloaded' });
  await sayfa.waitForFunction(() => window.__atlas?.ilerleme, null, { timeout: 90000 });
  const sonuc = await sayfa.evaluate(async ({g, al, yukle, gelistirici}) => {
    const {d, ekran, acikListe, bugun} = await import('/js/ekranlar/ortak.js');
    const ilr = await import('/js/ekranlar/ilerleme.js');
    const ayar = await import('/js/ekranlar/ayarlar.js');
    const pano = await import('/js/ekranlar/pano.js');
    const depo = await import('/js/depo.js');
    const devam = await import('/js/devam.js');
    const Asenkron = (async () => {}).constructor;
    const denetle = (dogru, ad) => { if (!dogru) throw Error(ad); };
    d.sanatcilar.push(...g.sanatcilar);
    d.akimlar.push(...g.akimlar);
    d.ilerleme = Object.assign(depo.varsayilanIlerleme(), g.il);
    ilr.ilerlemeSayfasi();
    const acik = acikListe();
    const a = pano.akimIstatistigi('C4', acik, d.ilerleme.skorlar, bugun());
    const sonuc = {
      acik: acik.length,
      kalici: pano.kutuDagilimi(acik, d.ilerleme.skorlar).kalici,
      vade: Number(ekran.querySelector('.ilr-sayilar div:last-child dd').textContent),
      akim: [a.dg,a.tp,a.kalici,a.vade,a.n],
      zayif: [...ekran.querySelectorAll('.zayif-liste a')].map(el => el.hash.split('/').pop()),
    };
    ilr.konuIsaretle([992,993,993], true);
    ilr.konuIsaretle(992, false);
    sonuc.islenen = d.ilerleme.islenen.slice();
    ayar.ayarlarSayfasi();
    function kart(n, adim) {
      d.ilerleme.ayarlar.gunlukKart = n;
      ekran.querySelector('[data-kart="' + adim + '"]').click();
      return d.ilerleme.ayarlar.gunlukKart;
    }
    sonuc.kart = [kart(7,-5),kart(98,5)];
    const renk = ekran.querySelector('input[name="gunduzRenk"][value="lapis"]');
    renk.checked = true;
    renk.dispatchEvent(new Event('change', { bubbles:true }));
    sonuc.renk = [d.ilerleme.ayarlar.tema,d.ilerleme.ayarlar.gunduzRenk];

    const geri = new Asenkron('metin','beklenen',yukle);
    const y = { surum:devam.KAYIT_SURUMU, zaman:Date.now(), kip:'karisik', kuyruk:[{id:'ben-a'}], konum:0 };
    d.yarim = y;
    const dis = JSON.parse(await new Asenkron(al)());
    denetle(dis.uygulama === 'sanat-atlasi' && dis.ilerleme.sonYedek === bugun() && dis.yarimOturum.zaman === y.zaman, 'Dışa aktarım');
    const no = d.ilerleme.kayitNo;
    for (const [metin, beklenen] of [['{}',no], [JSON.stringify(dis),no+1]]) {
      let ret = false;
      try { await geri(metin,beklenen); } catch { ret = true; }
      denetle(ret && d.ilerleme.kayitNo === no, 'Hatalı/eski yazma reddi');
    }
    await geri(JSON.stringify(dis), no);
    sonuc.yarim = !!d.yarim && d.yarim.zaman === y.zaman;
    await geri('{"islenen":[3,2,2]}', d.ilerleme.kayitNo);
    sonuc.eski = d.ilerleme.islenen.slice();
    sonuc.yedekOzetleri = [dis.ilerleme, d.ilerleme].map(il => [il.islenen.length, Object.keys(il.skorlar ?? {}).length]);
    denetle(!d.yarim && !d.oturum, 'Eski yedekte yarım oturum temizlenmeli');
    const mod = new Asenkron('ac',gelistirici);
    await mod(true);
    denetle(!!d.ilerleme.gelistirici && d.ilerleme.islenen.length > 2, 'Geliştirici modu');
    await mod(false);
    denetle(!d.ilerleme.gelistirici && d.ilerleme.islenen.join(',') === '2,3', 'Önceki ilerlemeye dön');
    return sonuc;
  }, { g:girdi, al:betik('benYedekAl'), yukle:betik('benGeriYukle'), gelistirici:betik('benGelistirici') });
  console.log(JSON.stringify(sonuc, null, 2));
} finally { await tarayici.close(); }
