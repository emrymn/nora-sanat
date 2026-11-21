// C1c: pekiştirme turunda tanışma ve "başka eser", canlı sitenin kendi modülleri ve gerçek katalogla.
// pekistir_turlari.mjs kalıbı: rastgele bir ilerleme ve tur (karışık, dönem, hepsi, konu, hatalar), sonra en çok
// 10 kart. Ek olarak sitenin js/ekranlar/pekistir.js @ a866b86 akışından:
//  - konu turunda turdan önceki tanışmalar (konuTanismaGoster): gösterilen eserler o turda sorulmaz (tanismaGorulen);
//  - öbür turlarda yeni sanatçının kartından önceki tanışma (kartCiz: tanismaGerekirMi, tanismaGoster);
//  - görseli açılmayan kart için başka eser (baskaEser);
//  - eseri bulunamayan kart atlanır ama sayaçta kalır (kartCiz: o.oturum.ilerle());
//  - cevap yaprağı için karıştırma sayısı (k.karisanSayi), seviye sonucu (k.seviyeSonuc) ve tur özetindeki gecenler.
// Swift testi (PekistirTanismaTests) aynı akışı TurKaydi ile yürütür; rastgele sayıların sırası ve sayısı da aynı olmalı.
//
//   node Testler/kahin/pekistir_tanisma.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/pekistir/tanisma.json
import { createRequire } from 'node:module';
const { chromium } = createRequire(import.meta.url)('playwright');

const tarayici = await chromium.launch();
const sayfa = await tarayici.newPage();
await sayfa.goto('https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
await sayfa.waitForFunction(() => window.__atlas && window.__atlas.ilerleme, null, { timeout: 60000 });
const sonuc = await sayfa.evaluate(async () => {
  const { d, jsonGetir } = await import('/js/ekranlar/ortak.js');
  const L = await import('/js/leitner.js');
  const S = await import('/js/seviye.js');
  const K = await import('/js/kilit.js');
  const Y = await import('/js/yardimci.js');
  const { gunlukGuncelle, sonCalisilanEkle } = await import('/js/depo.js');
  const { gecmisEkle } = await import('/js/gecmis.js');
  const { karisanEkle, tanismaEserleri, tanismaGerekirMi } = await import('/js/ogrenme.js');
  const { sanatciSecenekleri, akimSecenekleri, akrabaMi } = await import('/js/celdirici.js');
  const { kartlariSec, Oturum, kategori } = await import('/js/oturum.js');
  const { sanatciEserleri, eserSec, pekistirmeHavuzu, kolaylikAl } = await import('/js/eserler.js');
  const { tersSorulurMu, tersSecenekleri } = await import('/js/ters.js');
  const { gorselAnahtari } = await import('/js/gorsel.js');
  const { konuTuru, konuTanismalari, hatalarTuru, esiEkle } = await import('/js/turlar.js');
  const { eserKonusu } = await import('/js/ikonografi.js');
  const { ikonografiVeri } = await import('/js/ekranlar/gozat.js');
  const { bolumler } = await import('/js/ekranlar/harita.js');
  const B_ = await import('/js/bolum.js');
  await ikonografiVeri();
  if (!Object.keys(d.kolaylik || {}).length) d.kolaylik = kolaylikAl(await jsonGetir('data/eser_zorluk.json'));

  const BUGUN = '2026-11-21';
  const BILMIYORUM = '?';
  const ur = Y.rastgeleYap(20261122); // durum ve cevap üreteci (Swift'e gitmez)
  const tam = (a, b) => a + Math.floor(ur() * (b - a + 1));
  const sec = (l) => l[Math.floor(ur() * l.length)];
  const harita = d.harita;
  const eserlerAl = async (s) => (s ? (await sanatciEserleri(s)) || [] : []);
  const tumBolumler = bolumler();
  const konuNolari = [...new Set(d.sanatcilar.map((s) => s.konu).filter((k) => k != null))];

  function skorUret() {
    const goruldu = ur() < 0.85;
    return {
      kutu: tam(0, 5),
      sonraki: goruldu ? L.gunEkle(BUGUN, tam(-20, 30)) : null,
      dogru: tam(0, 9),
      yanlis: tam(0, 6),
      son: goruldu ? L.gunEkle(BUGUN, tam(-12, 0)) : null,
    };
  }

  async function durum(i) {
    const il = structuredClone(d.ilerleme);
    il.islenen = konuNolari.filter(() => ur() < 0.35);
    if (!il.islenen.length) il.islenen = [sec(konuNolari)];
    il.ekSanatcilar = ur() < 0.3 ? [sec(d.sanatcilar).id] : [];
    const acik = K.acikSanatcilar(d.sanatcilar, K.islenenKume(il.islenen), il.ekSanatcilar);
    il.skorlar = {};
    for (const s of acik) {
      if (ur() < 0.5) continue;
      const k = {};
      if (ur() < 0.9) k.sanatci = skorUret();
      if (ur() < 0.5) k.akim = skorUret();
      if (ur() < 0.1) k.bolumKart = skorUret();
      il.skorlar[s.id] = k;
    }
    il.karisanlar = {};
    for (let n = tam(0, 8); n > 0; n--) {
      const a = sec(acik).id, b = sec(acik).id;
      if (a !== b) il.karisanlar[[a, b].sort().join('|')] = { n: tam(1, 5), son: L.gunEkle(BUGUN, tam(-10, 0)) };
    }
    il.gunluk = ur() < 0.7 ? { tarih: BUGUN, yeni: tam(0, 10), kart: tam(0, 30), yeniIdler: [] } : { tarih: L.gunEkle(BUGUN, -1), yeni: 4, kart: 9, yeniIdler: [] };
    il.ayarlar.gunlukKart = sec([5, 10, 20, 30]);
    il.ayarlar.tanisma = ur() < 0.8;
    il.seviyeler = {};
    for (const a of new Set(acik.map((s) => s.akim))) {
      if (ur() < 0.4) continue;
      for (let n = tam(0, 25); n > 0; n--) S.seviyeIsle(il, a, ur() < 0.15 ? 'bilmiyorum' : ur() < 0.8);
    }
    il.sonEserler = {};
    il.koleksiyon = [];
    for (const s of acik.filter(() => ur() < 0.15)) {
      const l = pekistirmeHavuzu(await eserlerAl(s), {}).map((e) => e.anahtar);
      if (!l.length) continue;
      il.sonEserler[s.id] = l.filter(() => ur() < 0.4);
      if (ur() < 0.5) il.koleksiyon.push({ s: s.id, a: sec(l) });
    }
    // Atlanan kart: bir açık sanatçının bütün görselleri "kötü" (eserSec boş döner; kartCiz kartı sayaçta bırakıp geçer)
    if (ur() < 0.35) {
      const kurban = sec(acik);
      il.kotuGorseller = {};
      for (const e of await eserlerAl(kurban)) il.kotuGorseller[e.anahtar] = (e.gorseller || []).map(gorselAnahtari);
    }
    // tur
    const t = i % 5;
    let kip, akim, seciliSeviye = null;
    if (t === 0) kip = 'karisik';
    else if (t === 1) { kip = 'donem'; akim = sec(acik).akim; if (ur() < 0.5) seciliSeviye = tam(0, 2); }
    else if (t === 2) { kip = 'donem'; akim = 'hepsi'; }
    else if (t === 3) { kip = 'konu'; akim = String(sec(il.islenen)); }
    else kip = 'hatalar';
    return { il, kip, akim, seciliSeviye };
  }

  function bolumBilgi(akim) {
    const [id, ham] = String(akim || '').split('/');
    const m = /^(tanitim(?:-orta)?)-(\d+)$/.exec(ham || '');
    const sv = m ? m[1] : ham;
    const grup = m ? Number(m[2]) - 1 : null;
    return { id, sv, grup, b: tumBolumler.find((x) => x.id === id) || null };
  }

  const durumlar = [];
  for (let i = 0; i < 60; i++) {
    const { il, kip, akim, seciliSeviye } = await durum(i);
    const girdi = structuredClone(il);
    const ham = Y.rastgeleYap(1000 + i);
    let sayilar = 0;
    const rng = () => { sayilar++; return ham(); };
    const acikListe = () => K.acikSanatcilar(d.sanatcilar, K.islenenKume(il.islenen), il.ekSanatcilar || []);
    const kolaylikFn = (sid) => (Object.keys(d.kolaylik).length ? (e) => (e.qid && d.kolaylik[e.qid]) || d.kolaylik[`${sid}|${e.baslik}`] : null);

    // turAdaylari
    const hatalarBilgisi = () => hatalarTuru({ adaylar: acikListe(), skorlar: il.skorlar, karisanlar: il.karisanlar, bugun: BUGUN, rng: () => 0.5 });
    let adaylar;
    {
      const acik = acikListe();
      if (kip === 'bolum') { const { b } = bolumBilgi(akim); adaylar = b ? b.sanatcilar.map((id) => acik.find((s) => s.id === id)).filter(Boolean) : []; }
      else if (kip === 'donem' && akim !== 'hepsi') adaylar = acik.filter((s) => s.akim === akim);
      else if (kip === 'konu') adaylar = acik.filter((s) => s.konu === Number(akim));
      else if (kip === 'hatalar') { const h = hatalarBilgisi(); const ids = new Set([...h.idler, ...h.hatalilar]); adaylar = acik.filter((s) => ids.has(s.id)); }
      else adaylar = acik;
      const varMi = await Promise.all(adaylar.map(async (s) => (s.kurs_eserleri || []).length > 0 || (await eserlerAl(s)).length > 0));
      adaylar = adaylar.filter((_, j) => varMi[j]);
    }
    // turSec
    let tur;
    if (kip === 'bolum') {
      const { id, sv, grup, b } = bolumBilgi(akim);
      const idler = adaylar.map((x) => x.id);
      const gruplar = B_.tanismaGruplari(b ? b.sanatcilar : idler).map((g) => g.filter((x) => idler.includes(x)));
      if (sv === 'tanitim' || sv === 'tanitim-orta') {
        tur = grup !== null && gruplar[grup] ? { idler: B_.bolumKartlari(gruplar[grup], B_.grupSoruSayisi(gruplar[grup].length), rng), tanisma: gruplar[grup] } : { idler: [], tanisma: idler };
      } else {
        const kayit = B_.bolumKaydi(il, id);
        const ilk = (sv === 'kolay' && !kayit.tanitim) || (sv === 'orta' && !kayit.tanitimOrta);
        const gorulen = new Set(B_.gorulenGruplar(kayit, sv, gruplar.length));
        tur = { idler: B_.bolumKartlari(idler, B_.BOLUM_SORU[sv], rng), tanisma: ilk ? gruplar.filter((_, j) => !gorulen.has(j)).flat() : [] };
      }
    } else if (kip === 'konu') tur = { idler: konuTuru(adaylar, il.skorlar, rng), tanisma: il.ayarlar.tanisma !== false ? konuTanismalari(adaylar, il.skorlar) : [] };
    else if (kip === 'hatalar') { const h = hatalarTuru({ adaylar, skorlar: il.skorlar, karisanlar: il.karisanlar, bugun: BUGUN, rng }); tur = { idler: h.idler, esler: h.esler }; }
    else {
      const g = gunlukGuncelle(il, BUGUN);
      tur = { idler: kartlariSec({ adaylar, skorlar: il.skorlar, bugun: BUGUN, adet: il.ayarlar.gunlukKart, yeniKota: L.GUNLUK_YENI_SINIRI - g.yeni, kip, sirala: kip === 'karisik' ? 'agirlikli' : akim === 'hepsi' ? 'kronolojik' : 'oncelik', akimSira: d.akimSira, rng }).map((s) => s.id) };
    }
    const plan = { kartlar: tur.idler, tanisma: tur.tanisma || [], esler: tur.esler || {} };
    const o = {
      kip,
      oturum: new Oturum(tur.idler, { rng }),
      esler: tur.esler || null,
      seviye: kip === 'bolum' ? (B_.SEVIYE_NO[B_.TANITIM_SEVIYE[bolumBilgi(akim).sv] || bolumBilgi(akim).sv] ?? 0) : seciliSeviye,
    };
    const kotuler = () => (il.kotuGorseller ||= {});
    const skor = (id) => (il.skorlar[id] ||= {});
    // konusu: Swift'in veri.konu sözlüğü (önce QID, yoksa sanatçıId|başlık) biçiminde kaydedilir
    const konular = {};
    const konusu = (e) => {
      const k = eserKonusu(e);
      if (k) konular[e.qid && eserKonusu({ qid: e.qid }) ? e.qid : `${e.sid}|${e.baslik}`] = k.id;
      return k;
    };
    const tanismaAcik = () => il.ayarlar.tanisma !== false;
    const havuz = (l) => pekistirmeHavuzu(l || [], kotuler());
    const ilgili = new Set();

    // Ö6 · konu turu: turdan önce tanışmalar (konuTanismaGoster + data-konu-tanisma-gec)
    const tanismaGorulen = {};
    const tanismalar = [];
    for (const id of tur.tanisma || []) {
      const s = harita.get(id);
      ilgili.add(id);
      const sec = tanismaEserleri(havuz(await eserlerAl(s)), null, 3, kolaylikFn(id));
      if (!s || !sec.length) continue;
      tanismaGorulen[id] = sec.map((e) => e.anahtar);
      tanismalar.push({ id, eserler: tanismaGorulen[id] });
    }

    const adimlar = [];
    const gecenler = [];
    let kartSayisi = 0;
    while (!o.oturum.bitti && kartSayisi < 10) {
      // kartHazirla
      const konum = o.oturum.konum;
      const toplam = o.oturum.toplam; // kart gösterilirken sayaçtaki toplam
      const s = harita.get(o.oturum.simdiki.id);
      ilgili.add(s.id);
      const eserler = await eserlerAl(s);
      const son = il.sonEserler[s.id] || [];
      const sv = S.kartSeviyesi(S.seviyeKaydi(il, s.akim), o.seviye);
      const kacin = [...son, ...(tanismaGorulen[s.id] || [])];
      const isaretli = new Set((il.koleksiyon || []).filter((x) => x.s === s.id).map((x) => x.a));
      const eser = eserSec(eserler, kacin, rng, kotuler(), { kolaylik: kolaylikFn(s.id), seviye: S.eserSeviyesi(sv), isaretli });
      if (!eser) {
        // kartCiz: eseri bulunamayan kart atlanır, sayaçta kalır
        o.oturum.ilerle();
        adimlar.push({ konum, toplam, kart: { id: s.id, eser: null } });
        continue;
      }
      kartSayisi++;
      il.sonEserler[s.id] = [...son.filter((x) => x !== eser.anahtar), eser.anahtar].slice(-8);
      const acikIdler = new Set(acikListe().map((x) => x.id));
      const secici = () => sanatciSecenekleri(s, { sanatcilar: d.sanatcilar, akimlar: d.akimlar, acikIdler, rng, ortaYillar: d.ortaYillar, haric: eser.ortak || [], seviye: S.SEVIYELER[sv].anahtar }).map((x) => x.id);
      let secenekler = secici();
      const es = o.esler && o.esler[s.id];
      if (es && harita.has(es) && !akrabaMi(s, harita.get(es)) && !(eser.ortak || []).includes(es)) secenekler = esiEkle(secenekler, s.id, es, rng);
      let kart = { id: s.id, eser, eserler, seviye: sv, secenekler, akimSecenekleri: o.kip === 'karisik' ? akimSecenekleri(s.akim, d.akimlar, rng, 4, S.SEVIYELER[sv].anahtar) : null };
      if (tersSorulurMu({ kip: o.kip, seviye: sv, rng })) {
        const ad = [...new Set([...secenekler, ...secici()])].filter((id) => id !== s.id && harita.has(id));
        const celdiriciler = await Promise.all(ad.map(async (id) => ({ id, eserler: await eserlerAl(harita.get(id)) })));
        const ters = tersSecenekleri({ dogru: { id: s.id, eser }, celdiriciler, rng, kotuler: kotuler(), konusu });
        if (ters) kart = { ...kart, tur: 'ters', ters, secenekler: ters.map((x) => x.id), akimSecenekleri: null };
      }
      // kartCiz: yeni sanatçıya sorudan önce tanışma (konu turunda tanışmalar turdan önce yapıldı)
      const tanisma = o.kip !== 'konu' && tanismaAcik() && tanismaGerekirMi(il.skorlar[s.id])
        ? tanismaEserleri(havuz(kart.eserler), kart.eser.anahtar, 3, kolaylikFn(s.id)).map((e) => e.anahtar)
        : null;
      const kayitKart = { id: s.id, eser: eser.anahtar, seviye: sv, secenekler: kart.secenekler, akim: kart.akimSecenekleri, ters: kart.ters ? kart.ters.map((x) => [x.id, x.eser.anahtar]) : null, tanisma };
      // baskaEser: görsel açılmazsa (cevaptan önce) aynı sanatçının başka eseri
      let baska = null;
      if (kart.tur !== 'ters' && ur() < 0.15) {
        const diger = eserSec(kart.eserler.filter((e) => e.anahtar !== kart.eser.anahtar), [], rng, kotuler());
        if (diger) {
          kart.eserler = kart.eserler.filter((e) => e.anahtar !== kart.eser.anahtar);
          kart.eser = diger;
          baska = diger.anahtar;
        }
      }
      // cevap
      const r = ur();
      const cevapS = r < 0.55 ? s.id : r < 0.85 ? sec(kart.secenekler) : BILMIYORUM;
      const cevapA = kart.akimSecenekleri ? (ur() < 0.6 ? s.akim : sec(kart.akimSecenekleri)) : undefined;
      // sanatciCevapla
      if (o.kip !== 'konu') {
        const g = gunlukGuncelle(il, BUGUN);
        if (kategori(il.skorlar, s.id, o.kip, BUGUN) === 2 && !g.yeniIdler.includes(s.id)) { g.yeniIdler.push(s.id); g.yeni++; }
      }
      const dogru = cevapS === s.id;
      const bilmiyor = cevapS === BILMIYORUM;
      const karisan = dogru || bilmiyor ? 0 : karisanEkle(il, s.id, cevapS, BUGUN);
      skor(s.id).sanatci = L.cevapla(skor(s.id).sanatci, dogru, BUGUN);
      const kayit = S.seviyeKaydi(il, s.akim);
      let seviyeSonuc;
      if (o.seviye !== null && o.seviye !== undefined && !S.pencereyeYazilirMi(kayit, kart.seviye))
        seviyeSonuc = { isinma: true, once: kayit.s, sonra: kayit.s, gecti: false };
      else seviyeSonuc = S.seviyeIsle(il, s.akim, bilmiyor ? 'bilmiyorum' : dogru);
      if (seviyeSonuc.gecti) gecenler.push({ akim: s.akim, seviye: seviyeSonuc.sonra });
      sonCalisilanEkle(il, s.id);
      let kartDogru = dogru;
      if (o.kip === 'karisik' && kart.tur !== 'ters') {
        const ad = cevapA === s.akim;
        skor(s.id).akim = L.cevapla(skor(s.id).akim, ad, BUGUN);
        kartDogru = ad && dogru;
      }
      // kartiBitir
      o.oturum.isle(kartDogru);
      gunlukGuncelle(il, BUGUN).kart++;
      gecmisEkle(il, BUGUN, { dogru: kartDogru, akim: s.akim });
      adimlar.push({
        konum, toplam,
        kart: kayitKart, baska,
        cevap: { s: bilmiyor ? null : cevapS, a: cevapA ?? null },
        karisan,
        seviye: { isinma: !!seviyeSonuc.isinma, once: seviyeSonuc.once, sonra: seviyeSonuc.sonra, gecti: !!seviyeSonuc.gecti },
        kuyruk: o.oturum.kuyruk.map((k) => k.id + (k.tekrar ? '*' : '')),
      });
      o.oturum.ilerle();
    }
    const alanlar = ['skorlar', 'karisanlar', 'seviyeler', 'gunluk', 'gecmis', 'sonCalisilan', 'sonEserler'];
    const kolaylik = {};
    for (const sid of ilgili) {
      for (const e of await eserlerAl(harita.get(sid))) {
        for (const k of [e.qid, `${sid}|${e.baslik}`]) if (k && d.kolaylik[k] != null) kolaylik[k] = d.kolaylik[k];
      }
    }
    durumlar.push({
      tur: { kip, akim: akim ?? null, seciliSeviye, bolum: kip === 'bolum' ? bolumBilgi(akim).b.sanatcilar : null },
      ilerleme: JSON.stringify(girdi),
      tohum: 1000 + i, sayilar, kolaylik, konular, plan, tanismalar, adimlar, gecenler,
      sonra: Object.fromEntries(alanlar.map((a) => [a, JSON.stringify(il[a] ?? null)])),
    });
  }
  return { bugun: BUGUN, durumlar };
});
await tarayici.close();
console.log(JSON.stringify(sonuc));
