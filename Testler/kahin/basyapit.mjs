// Kaynak: sanat-atlasi js/basyapit.js, js/basyapitSayfa.js, js/eserDersi.js, js/ekranlar/{gozat,basyapit,eserDersi}.js @ a866b86
// Başyapıtlar (G3): liste, dönem grupları, öne çıkanlar, yakın okuma sayfasının saf yardımcıları ve ders metni.
// Canlı sitede (Playwright) sitenin kendi modülleriyle çalışır. Çıktı bir klasöre üç dosya olarak yazılır:
//   basyapitlar.json  (girdi: data/basyapitlar.json olduğu gibi)
//   dersler.json      (girdi: ders_yayin.json, her dersin DERS.json'dan kullanılan alanları ve DERS_ORTA.md)
//   cevaplar.json     (sitenin cevapları)
//   node Testler/kahin/basyapit.mjs Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/basyapit
import { writeFile, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { createRequire } from 'node:module';

async function cevaplar() {
  const B = await import('/js/basyapit.js');
  const S = await import('/js/basyapitSayfa.js');
  const D = await import('/js/eserDersi.js');
  const { BOLGELER, bolgeBul } = await import('/js/harita.js');
  const { basyapitVeri, ayrintiVeri } = await import('/js/ekranlar/gozat.js');
  const { d, hikayeVeri } = await import('/js/ekranlar/ortak.js');
  const { sanatciEserleri } = await import('/js/eserler.js');
  const { ayrintiBul, eserinAyrintisi } = await import('/js/ayrinti.js');
  const { kacis } = await import('/js/yardimci.js');
  const al = async (yol) => (await fetch('/' + yol)).json();
  const metin = async (yol) => (await fetch('/' + yol)).text();

  const ham = await al('data/basyapitlar.json');
  const liste = await basyapitVeri();
  const hikayeler = await hikayeVeri();
  const hikayeli = new Set(hikayeler.map((h) => h.anahtar));
  const ayrintilar = await ayrintiVeri();

  // gozat.js bsyGruplari (dışa açık değil; aynı kod)
  const gruplar = [];
  for (const bolge of BOLGELER) {
    const akimlar = d.akimlar
      .filter((a) => bolgeBul(a.sira).id === bolge.id)
      .map((a) => ({ a, l: liste.filter((b) => d.harita.get(b.sanatci).akim === a.ad) }))
      .filter((x) => x.l.length);
    const l = akimlar.flatMap((x) => x.l);
    if (l.length) gruplar.push({ bolge: bolge.id, ad: bolge.ad, yuzyil: bolge.yuzyil, akimlar: akimlar.map((x) => [x.a.ad, x.l.map((b) => b.anahtar)]) });
  }

  // Öne çıkanlar: birkaç gün, üç açıklık durumu, "Hepsi" ve her dönem
  const konular = [...new Set(d.sanatcilar.map((s) => s.konu).filter(Number.isFinite))].sort((a, b) => a - b);
  const durumlar = { hepsi: konular, yarisi: konular.filter((_, i) => i % 2 === 0), hicbiri: [] };
  const oneCikanlar = [];
  for (const [ad, islenen] of Object.entries(durumlar)) {
    const k = new Set(islenen);
    const acikMi = (b) => k.has(d.harita.get(b.sanatci).konu);
    for (const gun of [0, 1, 3, 7, 20411, 20412, 99999]) {
      oneCikanlar.push({ durum: ad, gun, donem: '', sonuc: B.oneCikanlar(liste, hikayeli, acikMi, gun).map((b) => b.anahtar) });
      for (const g of gruplar) {
        // bsyGovdeCiz: seçili dönemin listesi akımlar sırasıyla (`secili.l`)
        const anahtarlar = g.akimlar.flatMap((x) => x[1]);
        const l = anahtarlar.map((a) => liste.find((b) => b.anahtar === a));
        oneCikanlar.push({ durum: ad, gun, donem: g.bolge, sonuc: B.oneCikanlar(l, hikayeli, acikMi, gun).map((b) => b.anahtar) });
      }
    }
  }

  const yayinHam = await al('data/ders_yayin.json');
  const yayin = D.yayinAl(yayinHam);
  const dersler = {};
  const sayfalar = [];
  const adlar = (id) => (d.harita.get(id) || {}).ad || '';
  for (const b of liste) {
    const eserler = await sanatciEserleri(d.harita.get(b.sanatci));
    const e = B.eserEslestir(eserler, b);
    const kayit = ayrintiBul(ayrintilar, b.anahtar) || eserinAyrintisi(ayrintilar, e);
    const noktalar = kayit ? kayit.noktalar : [];
    const yerler = kayit ? S.noktalariYerlestir(b.bolumler, noktalar) : null;
    const kirpimlar = noktalar.map((n) => [0.62, 1, 1.45].map((oran) => [
      S.kirpim(n, oran, 8 / 5, { pay: 1.8, enCok: 3.2 }),
      S.kirpim(n, oran, 4 / 3, { pay: 1.4 }),
    ]));
    const klasor = D.dersKlasoru(yayin, b.anahtar);
    let ders = null, orta = '';
    if (klasor) {
      ders = await al(D.dersYolu(klasor, 'DERS.json')).catch(() => null);
      orta = await metin(D.dersYolu(klasor, 'DERS_ORTA.md')).catch(() => '');
      dersler[klasor] = {
        ders: ders && { temel_kavramlar: ders.temel_kavramlar, kunye: ders.kunye, karsilastirma_onerileri: ders.karsilastirma_onerileri },
        orta,
      };
    }
    const temiz = D.temizle(orta);
    const bolumler = S.dersBolumleri(temiz);
    const terimler = S.sozlukAl(ders);
    const kiyaslar = S.karsilastirmalariAl(ders, liste, b.anahtar, adlar);
    // basyapitSayfasi + dersiBagla: terimler belge sırasıyla (bölüm metni, tek ayrıntının açıklaması), sonra ayrıntılı anlatım
    const kullanilan = new Set();
    const isle = (h) => (terimler.length ? S.terimIsaretle(h, terimler, kullanilan) : h);
    const metinler = [];
    const aciklamalar = {};
    b.bolumler.forEach((x, i) => {
      metinler.push(isle(kacis(x.metin)));
      if (yerler && yerler[i] && yerler[i].length === 1) aciklamalar[yerler[i][0]] = isle(kacis(noktalar[yerler[i][0]].metin));
    });
    const derin = bolumler.map((x) => (x.karsilastirma && kiyaslar.length ? null : isle(D.mdHtml(x.govde))));
    sayfalar.push({
      anahtar: b.anahtar,
      gorunen: B.gorunenBaslik(b),
      eser: e ? e.anahtar : null,
      ayrinti: kayit ? kayit.anahtar : null,
      yerler,
      kirpimlar,
      klasor,
      durum: [D.dersDurumu(yayin, b.anahtar, false), D.dersDurumu(yayin, b.anahtar, true)],
      kunye: S.kunyeSatirlari(b, ders),
      kunyeDerssiz: S.kunyeSatirlari(b, null),
      terimler,
      kiyaslar,
      temiz,
      bolumler,
      dakika: S.okumaDakikasi(temiz),
      metinler,
      aciklamalar,
      derin,
    });
  }
  // Kenar durumları (uydurma girdiler)
  const ornekler = {
    gorunen: [
      { baslik: 'Arnolfini Portresi (Arnolfini Portrait)', ozgun: 'Arnolfini Portrait' },
      { baslik: 'Elçiler (The Ambassadors)', ozgun: 'Elçiler' },
      { baslik: 'Venüs’ün Doğuşu (Cabanel)', ozgun: 'Naissance de Vénus' },
      { baslik: 'İsa (İSA)', ozgun: 'isa' },
      { baslik: 'Yok', ozgun: '' },
      { baslik: 'A (B) (C)', ozgun: 'C' },
    ].map((b) => [b.baslik, b.ozgun, B.gorunenBaslik(b)]),
    sade: ['Çağdaş İŞIK, ışık!', 'Ünlü  “Sanatçı”—Gör', 'Café Œuvre ß 12', '  ', 'Ağaç-kökü'].map((s) => [s, S.sade(s)]),
    md: [
      '# Başlık\n\nParagraf **kalın** ve *italik* `kod` [C12].\nDevamı satırı.\n\n- bir\n- iki *x*\n\n1. a\n2) b\n\n---\n\n> alıntı\n> sürer\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n### Alt <başlık> & "tırnak"\n## İkinci',
      '## Yalnız\nmetin 3*4*5 ve ** boş',
    ].map((m) => [m, D.mdHtml(m)]),
    temizle: [
      '# Ders\n**Eser:** x\n## 1. Tarihsel bağlam (Wikidata)\nResim 1533 yılında yapıldı [C012]. NG kaydı bunu söyler. Kaynak betimlediği gibi: kafatası görünür (belirsiz).\n- madde (A/B)\n## Kaynaklar\n- atla\n## Kimlik\nTanıtım paragrafı.\n- liste atlanır\n## Boş\n## Son\nson   satır ,  bitti.',
    ].map((m) => [m, D.temizle(m)]),
    terim: [
      ['Glazürle boyandı; <b>glazür</b> katmanı. Sfumato!', [{ ad: 'Glazür', tanim: 'x' }, { ad: 'sfumato', tanim: 'y' }, { ad: 'ab', tanim: 'z' }]],
      ['<h3>Memento mori</h3><p>memento mori ve İkonografi; ikonografik</p>', [{ ad: 'Memento mori', tanim: 'x' }, { ad: 'İkonografi', tanim: 'y' }]],
    ].map(([h, t]) => [h, t, S.terimIsaretle(h, t, new Set())]),
  };
  return {
    girdi: { ham, yayinHam, dersler },
    cevap: {
      liste: liste.map((b) => b.anahtar),
      hikayeli: [...hikayeli],
      gruplar,
      oneCikanlar,
      sayfalar,
      ornekler,
    },
  };
}

const hedef = resolve(process.argv[2] || 'Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/basyapit');
const { chromium } = createRequire(import.meta.url)('playwright');
const tarayici = await chromium.launch();
try {
  const sayfa = await tarayici.newPage({ bypassCSP: true });
  await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'domcontentloaded' });
  await sayfa.waitForFunction(() => window.__atlas?.ilerleme, null, { timeout: 90000 });
  await sayfa.addScriptTag({ content: 'window.basyapitCevaplari = ' + cevaplar.toString() });
  const r = await sayfa.evaluate(() => window.basyapitCevaplari());
  await mkdir(hedef, { recursive: true });
  await writeFile(resolve(hedef, 'basyapitlar.json'), JSON.stringify(r.girdi.ham));
  await writeFile(resolve(hedef, 'dersler.json'), JSON.stringify({ yayin: r.girdi.yayinHam, dersler: r.girdi.dersler }));
  await writeFile(resolve(hedef, 'cevaplar.json'), JSON.stringify(r.cevap));
  console.log(`${r.cevap.liste.length} başyapıt, ${Object.keys(r.girdi.dersler).length} ders → ${hedef}`);
} finally {
  await tarayici.close();
}
