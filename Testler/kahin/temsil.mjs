// C4b kâhini: sanatçının küçük görseli (`enBilinen`, js/ekranlar/ortak.js) ve temsil dışı eserler (`temsilOlabilir`,
// js/temsil.js) canlı sitenin kendi modülleriyle. Her sanatçı için sitenin `sanatciEserleri(s)` listesi (yalnız kuralın
// okuduğu alanlar) ve sitenin seçtiği eserin anahtarı yazılır. Ayrıca: "kötü" işaretli görseller (seçilen eserin bütün
// görselleri reddedilince sıradaki), TEMSIL_DISI eserin hiç seçilmediği ve `bilinirlikSirasi`'nın ilk 10'u.
//
//   node Testler/kahin/temsil.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/temsil/cevaplar.json
import { createRequire } from 'node:module';
import assert from 'node:assert/strict';

const { chromium } = createRequire(import.meta.url)('playwright');
const tarayici = await chromium.launch();
try {
  const sayfa = await tarayici.newPage();
  await sayfa.goto(process.env.SITE || 'https://sanat-atlasi.pages.dev/', { waitUntil: 'domcontentloaded' });
  await sayfa.waitForFunction(() => window.__atlas?.ilerleme && window.__atlas?.sanatcilar, null, { timeout: 90000 });
  const sonuc = await sayfa.evaluate(async () => {
    const o = await import('/js/ekranlar/ortak.js');
    const Es = await import('/js/eserler.js');
    const T = await import('/js/temsil.js');
    const G = await import('/js/gorsel.js');
    const d = o.d;
    d.ilerleme.kotuGorseller = {};
    const sade = (e) => ({
      anahtar: e.anahtar, qid: e.qid ?? null, sl: e.sl || 0, pekistirme: e.pekistirme !== false,
      gorseller: (e.gorseller || []).map((g) => Object.fromEntries(['k', 'd', 'u', 'i'].filter((k) => g[k] != null).map((k) => [k, g[k]]))),
    });
    const sanatcilar = [];
    for (const s of d.sanatcilar) {
      const l = await Es.sanatciEserleri(s).catch(() => []);
      const e = o.enBilinen(l);
      // eserKareleriDoldur: bilinirlik sırası, görseli olanlar (tablo düğmesinin yelpazesi)
      const sirali = o.bilinirlikSirasi(l).filter((x) => x.gorseller && x.gorseller.length).slice(0, 10).map((x) => x.anahtar);
      sanatcilar.push({ id: s.id, eserler: l.map(sade), cevap: e ? e.anahtar : null, sirali });
    }
    // Kötü görseller: seçilen eserin bütün görselleri reddedilince
    const kotuler = [];
    for (const x of sanatcilar.filter((x) => x.cevap).slice(0, 25)) {
      const l = await Es.sanatciEserleri(d.harita.get(x.id));
      const sec = l.find((e) => e.anahtar === x.cevap);
      const kotu = { [sec.anahtar]: sec.gorseller.map(G.gorselAnahtari) };
      d.ilerleme.kotuGorseller = kotu;
      const e = o.enBilinen(l);
      kotuler.push({ id: x.id, kotuler: kotu, cevap: e ? e.anahtar : null });
    }
    d.ilerleme.kotuGorseller = {};
    return { temsilDisi: [...T.TEMSIL_DISI], sanatcilar, kotuler };
  });
  assert.ok(sonuc.sanatcilar.length > 100, 'sanatçı listesi');
  assert.ok(sonuc.sanatcilar.some((x) => x.eserler.some((e) => sonuc.temsilDisi.includes(e.qid))), 'TEMSIL_DISI eser listede yok: örnek eksik');
  console.log(JSON.stringify(sonuc));
} finally {
  await tarayici.close();
}
