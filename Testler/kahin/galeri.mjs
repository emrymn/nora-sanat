// Kaynak: sanat-atlasi js/{arama,akim,ikonografi,basyapit,birlesme}.js ve js/ekranlar/gozat.js @ a866b86
// İlk argüman salt okunur site deposudur. Ağ yerine aynı commit'in data/ dosyaları okunur.
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { createRequire } from 'node:module';

async function cevaplar({ js, d, al, enBilinen }) {
    const { sanatciEserleri } = await import(js + '/eserler.js');
    const { enBilinenEserler, tipikKonular } = await import(js + '/akim.js');
    const { AKIM_KAPAK, temsilOlabilir } = await import(js + '/temsil.js');
    const { acikSanatcilar } = await import(js + '/kilit.js');
    const { basyapitlariAl, eserEslestir } = await import(js + '/basyapit.js');
    const { konulariAl } = await import(js + '/ikonografi.js');
    const { akimBilgisiBirlestir, ozellikleriBirlestir } = await import(js + '/birlesme.js');
    const { ara, dizinKur, normallestir } = await import(js + '/arama.js');

    const { kapakSec } = await import(js + '/ikonografi.js');
    const { cerceveTipi } = await import(js + '/cerceve.js');
    const { akimYuzyillari } = await import(js + '/tasarim.js');
    const { okunacakAd, sesDosyasi } = await import(js + '/kunye.js');
    const varMi = id => d.harita.has(id);
    const ikonografi = await al('ikonografi');
    const konular = konulariAl(ikonografi, varMi);
    const hamBas = (await al('basyapitlar')).eserler;
    const basGirdi = { eserler: [null, {}, ...hamBas.slice(0, 12)] };
    const basyapitlar = basyapitlariAl(basGirdi, varMi).filter(temsilOlabilir);
    const hareket = ['Gotik', 'Uluslararası Gotik', 'Rokoko'];
    const alt = async ad => ({ akimlar: Object.fromEntries(Object.entries((await al(ad)).akimlar).filter(([k]) => hareket.includes(k))) });
    const bilgiGirdi = await alt('akim_bilgi'), ozGirdi = await alt('akim_ozellikleri');
    const liste = Object.fromEntries(await Promise.all([...d.harita.values()].map(async s => [s.id, await sanatciEserleri(s, { canli: false })])));
    const islenen = [...new Set(d.sanatcilar.map(x => x.konu).filter(Number.isFinite))].filter((_, i) => i % 2 === 0);
    const ek = [d.sanatcilar.find(s => !islenen.includes(s.konu)).id];
    const acik = acikSanatcilar(d.sanatcilar, islenen, ek);
    const dizin = dizinKur({ sanatcilar: d.sanatcilar, eserler: acik.flatMap(s => liste[s.id].map(e => ({ e, s }))), konular, basyapitlar, adlar: d.kisaAdlar });
    const sorgular = ['g', 'giotto', 'Ş', 'müjde', 'meryem', 'gece', 'night', 'durer', 'İsa', 'ıŞıK', 'saint john', 'É È! şß', 'resimsizzz'];
    const aramalar = sorgular.map(sorgu => {
      const r = ara(dizin, sorgu);
      return { sorgu, normal: normallestir(sorgu), sayilar: r.sayilar,
        gruplar: Object.fromEntries(Object.keys(r.sayilar).map(t => [t, r[t].map(x => x.id)])) };
    });
    const salonlar = d.akimlar.map(a => {
      const uyeler = d.sanatcilar.filter(s => s.akim === a.ad);
      const sirali = [...uyeler].sort((a,b) => Number(islenen.includes(b.konu)) - Number(islenen.includes(a.konu)) || (a.dogum ?? 0) - (b.dogum ?? 0));
      const ozel = AKIM_KAPAK[a.ad] && uyeler.flatMap(s => liste[s.id]).find(e => e.qid === AKIM_KAPAK[a.ad]);
      const kapak = ozel || sirali.slice(0,8).map(s => enBilinen(liste[s.id])).find(Boolean);
      const dortlu = enBilinenEserler(uyeler.filter(s => islenen.includes(s.konu)).map(s => ({ s, eserler: liste[s.id] })));
      return { ad: a.ad, yy: akimYuzyillari(uyeler, {roma:true}), cerceve: cerceveTipi(a.ad),
        konular: tipikKonular(konular, uyeler.filter(s=>islenen.includes(s.konu)).map(s=>s.id)).map(k=>k.id), kapak: kapak?.anahtar ?? null, dortlu: dortlu.map(x => x.e.anahtar) };
    });
    const baglar = Object.fromEntries(konular.map(k => [k.id, k.eserler.map(([anahtar,sanatci]) => eserEslestir(liste[sanatci],{anahtar,sanatci})).filter(e => e?.gorseller.length).map(e => e.anahtar)]));
    const { tanimaKirpimlariAl, kirpimEseri, incelemeKaydi } = await import(js + '/tanimaKirpim.js');
    const { ayrintiAnahtari } = await import(js + '/ayrinti.js');
    const { gorselAdi, secilenGorsel } = await import(js + '/gorsel.js');
    const hamKirp = await al('tanima_kirpimlari');
    const kirpGirdi = Object.fromEntries(['konular', 'sanatcilar'].map(t => [t, Object.fromEntries(
      Object.entries(hamKirp[t]).slice(0,5).map(([id,l]) => [id, [null, {}, ...l, l[0], {...l[0], w:0}]])
    )]));
    const kirp = tanimaKirpimlariAl(kirpGirdi);
    const kirpSonuc = Object.fromEntries(['konular', 'sanatcilar'].map(t => [t,Object.fromEntries([...kirp[t]].map(([id,l]) =>
      [id,l.map(k => kirpimEseri(k,liste[k.sanatci],ayrintiAnahtari,e=>gorselAdi(secilenGorsel(e)))?.anahtar ?? '')]))]));
    const ornek = kirp.sanatcilar.values().next().value[0];
    const n = { ad:ornek.ad, metin:'Eşleşti', x:ornek.x, y:ornek.y, w:ornek.w, h:ornek.h };
    const mevcut = {anahtar:ornek.anahtar, sanatci:ornek.sanatci, gorsel:ornek.gorsel,
      noktalar:[{...n, ad:'Önceki', x:n.x+0.1},n]};
    const incelemeler = [mevcut, {...mevcut,gorsel:'başka'}, null].map(kayit=>{
      const r = incelemeKaydi(ornek,kayit,'Açıklama');
      return {kayit, ilk:r.kayit.noktalar[r.nokta], adet:r.kayit.noktalar.length};
    });
    const { ipSertligi, sarkacAdim } = await import(js + '/sallanma.js');
    const { donusIzle, donustenEgim } = await import(js + '/egim.js');
    const salinim = Array.from({length: 8}, (_,i) => {
      const ip = 12 + ((i*13)%4)*7, egim = (((i*37)%5)-2)*0.4;
      let durum = {aci:0,hiz:0}, donus = {x:0,y:0};
      const adimlar = [190, 800, 0, -250, -1000, 33, 0].map(hiz => {
        donus = donusIzle(donus, {gamma:hiz}, 1/30);
        durum = sarkacAdim(durum, -5*donustenEgim(donus).x, 1/30, ipSertligi(ip));
        const yuvarla = n => Number(n.toFixed(10));
        return {hiz, x:yuvarla(donus.x), aci:yuvarla(durum.aci), v:yuvarla(durum.hiz)};
      });
      return {ip,egim,adimlar};
    });
    const kapaklar = Object.fromEntries(konular.map(k => [k.id, kapakSec(k.eserler.map(([anahtar,sanatci]) =>
      eserEslestir(liste[sanatci],{anahtar,sanatci})).filter(e => e?.gorseller.length))?.anahtar ?? '']));
    const adlar = Object.fromEntries(d.sanatcilar.map(s => [s.ad, okunacakAd(s.ad)]));
    const sesler = [{ses:'dosya'}, {okunus:true}, {}, {ses:'x',okunus:true}].map(k => ({k, url:sesDosyasi({id:'deneme'},k)}));
    const kayitlar = [...acik.slice(0, 4).flatMap(s => liste[s.id].slice(0, 1).map(e => ({s:s.id, a:e.anahtar}))).reverse(), {s: 'yok', a: 'yok'}];
    return { islenen, ek, salinim, ornek, incelemeler, kirpGirdi, kirpSonuc, kapaklar, adlar, sesler, basGirdi, bilgiGirdi, ozGirdi, bilgi: akimBilgisiBirlestir(bilgiGirdi).akimlar,
      oz: ozellikleriBirlestir(ozGirdi.akimlar), baglar, salonlar, aramalar, kayitlar,
      koleksiyon: kayitlar.map(x => liste[x.s]?.find(e => e.anahtar === x.a)).filter(Boolean).map(e => e.anahtar) };

}

async function yerel(yol) {
  const kok = resolve(yol);
  const js = pathToFileURL(resolve(kok, 'js')).href;
  const al = async ad => JSON.parse(await readFile(resolve(kok, 'data', ad + '.json'), 'utf8'));
  globalThis.fetch = async yol => new Response(await readFile(resolve(kok, yol)));
  const E = await import(js + '/eserler.js');
  const G = await import(js + '/gorsel.js');
  const B = await import(js + '/birlesme.js');
  const R = await import(js + '/resim.js');
  const yerelG = await al('yerel_gorseller');
  G.yerelGorselleriAyarla(yerelG.gorseller, yerelG.buyuk);
  const tum = B.sanatcilariBirlestir(await al('sanatcilar'));
  const hazir = await E.hazirOnbellek(), turler = await al('eser_turleri');
  E.eserTurleriniAyarla(turler);
  E.ortakAtiflariAyarla(hazir, new Map(tum.map(s => [s.id, s.ad])));
  E.kopyalariAyarla(await al('kopya_eserler'));
  E.cikarilanlariAyarla(await al('cikarilan_gorseller'));
  E.duzeltmeleriAyarla(await al('eser_duzeltmeleri'));
  E.eserAdlariniAyarla(E.adlariAl(await al('eser_adlari_tr')));
  const sanatcilar = R.gorunurSanatcilar(tum, turler, hazir);
  const akimlar = R.gorunurAkimlar(B.akimlariBirlestir(await al('akimlar')).sort((a,b) => a.sira-b.sira), sanatcilar);
  const d = { sanatcilar, akimlar, harita: new Map(sanatcilar.map(s => [s.id,s])), kisaAdlar: (await al('kisa_adlar')).adlar };
  const { temsilOlabilir } = await import(js + '/temsil.js');
    // js/ekranlar/ortak.js enBilinen: bu örnekte kötü görsel işareti yok.
    function enBilinen(eserler) {
      const uygun = eserler.filter(e => temsilOlabilir(e) && G.secilenGorsel(e, {}) && e.pekistirme !== false);
      return uygun.reduce((en,e) => !en || e.sl > en.sl ? e : en, null);
    }
  return cevaplar({ js, d, al, enBilinen });
}

async function canli() {
  const { chromium } = createRequire(import.meta.url)('playwright-core');
  const tarayici = await chromium.launch({ executablePath: process.env.GALERI_CHROMIUM });
  try {
    const sayfa = await tarayici.newPage({ bypassCSP: true });
    await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'domcontentloaded' });
    await sayfa.waitForFunction(() => window.__atlas?.ilerleme, null, { timeout: 90000 });
    // Aynı işlev, sitenin yüklediği katalog ve modül örnekleriyle çalışır.
    await sayfa.addScriptTag({ content: 'window.galeriCevaplari = ' + cevaplar.toString() });
    return await sayfa.evaluate(async () => {
      const { d, enBilinen } = await import('/js/ekranlar/ortak.js');
      const al = async ad => (await fetch('/data/' + ad + '.json')).json();
      return window.galeriCevaplari({ js: '/js', d, al, enBilinen });
    });
  } finally { await tarayici.close(); }
}

console.log(JSON.stringify(process.argv[2] ? await yerel(process.argv[2]) : await canli()));
