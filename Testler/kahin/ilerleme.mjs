// T2 kâhini: tekrar kuralları (js/leitner.js, js/gecmis.js, js/ogrenme.js, js/seviye.js, js/kilit.js, js/birlesme.js)
// rastgele 200 ilerleme nesnesinde, canlı sitenin kendi modülleriyle. Rastgelelik tohumlu (sitenin rastgeleYap'ı).
//
//   node Testler/kahin/ilerleme.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/ilerleme/cevaplar.json
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage();
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForFunction(() => window.__atlas && window.__atlas.ilerleme, null, { timeout: 60000 });
const sonuc = await sayfa.evaluate(async () => {
  const o = await import('/js/ekranlar/ortak.js');
  const L = await import('/js/leitner.js');
  const G = await import('/js/gecmis.js');
  const O = await import('/js/ogrenme.js');
  const S = await import('/js/seviye.js');
  const K = await import('/js/kilit.js');
  const B = await import('/js/birlesme.js');
  const Y = await import('/js/yardimci.js');
  const d = o.d;
  const rng = Y.rastgeleYap(20261120);
  const tam = (a, b) => a + Math.floor(rng() * (b - a + 1));
  const sec = (l) => l[Math.floor(rng() * l.length)];
  const ids = d.sanatcilar.map((s) => s.id);
  const akimAdlari = [...d.akimlar.map((a) => a.ad), 'Uluslararası Gotik'];
  const gun0 = '2026-01-01';

  function tarih(bugun, a, b) {
    return L.gunEkle(bugun, tam(a, b));
  }
  function skor(bugun) {
    const r = rng();
    if (r < 0.08) return undefined;
    const goruldu = rng() < 0.85;
    return {
      kutu: tam(0, 5),
      sonraki: goruldu || rng() < 0.3 ? (rng() < 0.05 ? null : tarih(bugun, -25, 45)) : null,
      dogru: tam(0, 12),
      yanlis: tam(0, 8),
      son: goruldu ? tarih(bugun, -60, 0) : null,
    };
  }
  function ilerleme(i) {
    const bugun = L.gunEkle(gun0, tam(0, 700));
    const skorlar = {};
    const n = tam(0, 40);
    for (let k = 0; k < n; k++) {
      const id = rng() < 0.9 ? sec(ids) : `bilinmeyen-${tam(1, 5)}`;
      const s = {};
      const a = skor(bugun), b = skor(bugun);
      if (a) s.sanatci = a;
      if (b) s.akim = b;
      skorlar[id] = s;
    }
    const gecmis = {};
    const gunSayisi = tam(0, 30);
    let t = L.gunEkle(bugun, -tam(0, 3));
    for (let k = 0; k < gunSayisi; k++) {
      if (rng() < 0.75) {
        const kart = tam(0, 30);
        const akimlar = {};
        for (let j = tam(0, 3); j > 0; j--) akimlar[sec(akimAdlari)] = tam(1, 8);
        if (rng() < 0.1) akimlar.Barok = 0;
        gecmis[t] = { kart, dogru: tam(0, kart + 2), akimlar };
      }
      t = L.gunEkle(t, rng() < 0.85 ? -1 : -tam(2, 4));
    }
    if (rng() < 0.1) gecmis['bozuk'] = { kart: 1, dogru: 1 };
    if (rng() < 0.1) gecmis[L.gunEkle(bugun, -40)] = { kart: -1, dogru: 0 };
    const islenen = [...new Set(Array.from({ length: tam(0, 40) }, () => tam(1, 61)))];
    const islenen2 = [...new Set([...islenen, ...Array.from({ length: tam(0, 5) }, () => tam(1, 61))])];
    const ek = Array.from({ length: tam(0, 3) }, () => sec(ids));
    const karisanlar = {};
    for (let k = tam(0, 8); k > 0; k--) {
      const a = sec(ids), b = rng() < 0.1 ? a : sec(ids);
      karisanlar[rng() < 0.5 ? `${a}|${b}` : `${b}|${a}`] = rng() < 0.1 ? { n: 0 } : { n: tam(1, 6), son: rng() < 0.2 ? undefined : tarih(bugun, -30, 0) };
    }
    if (rng() < 0.1) karisanlar['tek'] = { n: 3 };
    const seviyeler = {};
    for (let k = tam(0, 5); k > 0; k--) {
      const son = Array.from({ length: tam(0, 14) }, () => sec([0, 1, 1, 1, 2, 3]));
      seviyeler[sec(akimAdlari)] = rng() < 0.1 ? { s: 5, son } : { s: tam(0, 2), son };
    }
    return { bugun, skorlar, gecmis, islenen, islenen2, ek, karisanlar, seviyeler };
  }

  const vakalar = [];
  for (let i = 0; i < 200; i++) {
    const g = ilerleme(i);
    const skorIdleri = Object.keys(g.skorlar);
    const acik = K.acikSanatcilar(d.sanatcilar, g.islenen, g.ek).map((s) => s.id);
    // her skor için cevap işleme ve durumlar
    const skorlar = [];
    for (const id of skorIdleri.slice(0, 6))
      for (const tur of ['sanatci', 'akim']) {
        const s = g.skorlar[id][tur];
        const dogruMu = rng() < 0.6;
        skorlar.push({
          skor: s ?? null,
          dogruMu,
          sonuc: L.cevapla(s, dogruMu, g.bugun),
          zayif: L.zayifMi(s),
          vadeli: L.vadesiGeldiMi(s, g.bugun),
          goruldu: L.gorulduMu(s),
        });
      }
    const gd = G.gecmisDogrula(g.gecmis);
    const svDogru = S.seviyelerDogrula(g.seviyeler);
    const svBirlesik = B.seviyeleriBirlestir(JSON.parse(JSON.stringify(svDogru)));
    const seviye = Object.entries(svBirlesik).map(([akim, k]) => {
      const cevap = sec([true, false, 'bilmiyorum']);
      return { akim, kayit: k, cevap, sonuc: S.seviyeCevapla(k, cevap), durum: S.seviyeDurumu(k), kisa: S.seviyeKisa(k), usta: S.ustaMi(k), oran: S.oran(k.son) };
    });
    const kar = O.karisanlarDogrula(g.karisanlar);
    vakalar.push({
      girdi: g,
      vadeSayisi: G.vadeSayisi(g.skorlar, skorIdleri, g.bugun),
      vadeSayisiAcik: G.vadeSayisi(g.skorlar, acik, g.bugun),
      yarinVade: G.yarinVade(g.skorlar, skorIdleri, g.bugun),
      gelecekYuk: G.gelecekYuk(g.skorlar, skorIdleri, g.bugun, 14),
      gelecekYukAcik: G.gelecekYuk(g.skorlar, acik, g.bugun, 14),
      seri: G.seri(gd, g.bugun),
      takvim: G.takvim(gd, g.bugun, 4),
      haftalik: G.haftalikOran(gd, g.bugun, 4),
      gecmisDogru: gd,
      acik,
      yeniAcilan: K.yeniAcilanlar(d.sanatcilar, g.islenen, g.islenen2).map((s) => s.id),
      akimDurumlari: K.akimDurumlari(d.akimlar, d.sanatcilar, g.islenen),
      tanisma: skorIdleri.slice(0, 6).map((id) => O.tanismaGerekirMi(g.skorlar[id])),
      skorlar,
      karisanDogru: kar,
      enCokKarisan: O.enCokKarisanlar(kar, { adet: 3 }),
      seviyeDogru: svDogru,
      seviyeBirlesik: svBirlesik,
      seviye,
    });
  }
  // Yazma: sitenin gerçek ilerlemesine (bilinmeyen bir alan eklenmiş) sitenin işlemleri uygulanınca çıkan JSON
  const D = await import('/js/depo.js');
  const il = JSON.parse(JSON.stringify(d.ilerleme));
  il.gelecektekiAlan = { x: [1, 'ğ', null], y: 'ç"\\' };
  il.skorlar['masaccio'] = { sanatci: L.cevapla(undefined, false, '2026-11-19'), bilinmeyen: 7 };
  il.gecmis['2026-11-19'] = { kart: 2, dogru: 1, akimlar: { Barok: 2 } };
  const once = JSON.stringify(il);
  const bugun = '2026-11-20';
  D.gunlukGuncelle(il, bugun);
  il.skorlar['giotto-di-bondone'] ||= {};
  il.skorlar['giotto-di-bondone'].sanatci = L.cevapla(il.skorlar['giotto-di-bondone'].sanatci, true, bugun);
  il.skorlar['masaccio'].sanatci = L.cevapla(il.skorlar['masaccio'].sanatci, true, bugun);
  il.skorlar['masaccio'].akim = L.cevapla(il.skorlar['masaccio'].akim, false, bugun);
  G.gecmisEkle(il, bugun, { dogru: true, akim: 'Gotik' });
  G.gecmisEkle(il, '2026-11-19', { dogru: false, akim: 'Barok' });
  D.sonCalisilanEkle(il, 'giotto-di-bondone');
  S.seviyeIsle(il, 'Gotik', true);
  O.karisanEkle(il, 'giotto-di-bondone', 'cimabue', bugun);
  il.islenen = [...new Set([...il.islenen, 9, 2])].sort((a, b) => a - b);
  const yazma = { once, sonra: JSON.stringify(il) };

  const r = [0, 0.1, 0.3333, 0.34, 0.5, 0.6666, 0.67, 0.99, 0.999999];
  return {
    surum: (await import('/js/surum.js')).SURUM,
    aralikler: L.ARALIKLAR,
    tekrarAraligi: r.map((x) => [x, L.tekrarAraligi(() => x)]),
    sanatcilar: d.sanatcilar.map((s) => [s.id, s.konu, s.akim]),
    akimlar: d.akimlar.map((a) => [a.ad, a.sira]),
    vakalar,
    yazma,
  };
});
console.log(JSON.stringify(sonuc));
await tarayici.close();
