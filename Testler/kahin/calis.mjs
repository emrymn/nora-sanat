// C2 kâhini: Çalış ana ekranı, Turlar / Döneme göre ekranı, ders planı, harita bölümleri, soru turları,
// 14 günlük yük grafiği ve deste/eğim fiziği kuralları (js/ders.js, js/dersIcerik.js, js/bolum.js, js/oturum.js,
// js/soruTurlari.js, js/ikonografi.js, js/gecmis.js, js/deste.js, js/sallanma.js, js/egim.js,
// js/ekranlar/{ders,pekistir,soruTurlari,gozat,calisma,bugun}.js @ a866b86) canlı sitenin kendi modülleriyle.
//
//   node Testler/kahin/calis.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/calis/cevaplar.json
import { createRequire } from 'node:module';

const gerektir = createRequire(import.meta.url);
const { chromium } = process.env.CALIS_CHROMIUM ? gerektir('playwright-core') : gerektir('playwright');

const tarayici = await chromium.launch({ executablePath: process.env.CALIS_CHROMIUM || undefined });
try {
  const sayfa = await tarayici.newPage({ bypassCSP: true });
  await sayfa.goto(process.env.CALIS_SITE || 'https://sanat-atlasi.pages.dev/', { waitUntil: 'networkidle', timeout: 90000 });
  await sayfa.waitForFunction(() => window.__atlas && window.__atlas.sanatcilar && window.__atlas.ilerleme, null, { timeout: 60000 });

  const sonuc = await sayfa.evaluate(async () => {
    const o = await import('/js/ekranlar/ortak.js');
    const yard = await import('/js/yardimci.js');
    const kilit = await import('/js/kilit.js');
    const ders = await import('/js/ders.js');
    const icerik = await import('/js/dersIcerik.js');
    const bolum = await import('/js/bolum.js');
    const oturum = await import('/js/oturum.js');
    const turlar = await import('/js/turlar.js');
    const st = await import('/js/soruTurlari.js');
    const ik = await import('/js/ikonografi.js');
    const gecmis = await import('/js/gecmis.js');
    const seviye = await import('/js/seviye.js');
    const pano = await import('/js/ekranlar/pano.js');
    const deste = await import('/js/deste.js');
    const sallanma = await import('/js/sallanma.js');
    const egim = await import('/js/egim.js');
    const ogrenme = await import('/js/ogrenme.js');
    const kars = await import('/js/karsilastir.js');
    const akimM = await import('/js/akim.js');
    const adlar = await import('/js/adlar.js');
    const eserlerM = await import('/js/eserler.js');
    const depo = await import('/js/depo.js');

    const d = o.d;
    const bugunTarih = '2026-11-21';

    // Veri dosyalarını yükle
    const dersKaynagi = await (await fetch('data/ders_kaynaklari.json', { cache: 'no-store' })).json();
    const yuruyusJson = await (await fetch('data/yuruyus.json', { cache: 'no-store' })).json();
    const ikonoJson = await (await fetch('data/ikonografi.json', { cache: 'no-store' })).json();
    const yuruyus = yuruyusJson.eserler || {};

    // 1) Bulunma eki ve konum yazısı
    const bulunmaSayilari = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 19, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    const bulunmaSonuclari = bulunmaSayilari.map((n) => {
      const ek = yard.bulunmaEki(n);
      const konum = `Konu ${ek}${/[aı]$/.test(ek) ? 'sın' : 'sin'}`;
      return { n, ek, konum };
    });

    // 2) Bütün derslerin planları (gorPlani, ogrenPlani, ayirtPlani, dersAdimlari, kapak eseri)
    const gorunurAkimlar = new Set(d.akimlar.map((a) => a.ad));
    const tumAcikAkimlar = new Set(d.akimlar.map((a) => a.ad));
    const maddelerFn = (ad) => ((icerik.dersBul(dersKaynagi, ad) || {}).ogren || []).map((m) => m.madde);
    const dersPlanlari = [];
    for (const a of d.akimlar) {
      const dr = icerik.dersBul(dersKaynagi, a.ad);
      if (!dr) continue;
      const adimlar = icerik.dersAdimlari(dr, yuruyus);
      const gor = icerik.gorPlani(dr, yuruyus);
      const ogren = icerik.ogrenPlani(dr);
      const ayirt = icerik.ayirtPlani(dr, { gorunur: gorunurAkimlar, acik: tumAcikAkimlar, maddeler: maddelerFn });
      // Kapak eseri: ders.ayirt[0].eserler.kendi içindeki ilk eşleşen
      let kapakAnahtar = null;
      const adaylar = (dr.ayirt[0] && dr.ayirt[0].eserler.kendi) || [];
      for (const ref of adaylar) {
        const s = d.harita.get(ref.sanatci);
        if (!s) continue;
        const liste = await eserlerM.sanatciEserleri(s, { canli: false });
        const e = icerik.eserEslestir(liste, ref.sanatci, ref);
        if (e) {
          kapakAnahtar = e.anahtar;
          break;
        }
      }
      dersPlanlari.push({
        akim: a.ad,
        adimlar,
        gorEserler: gor.eserler.map((x) => ({ sanatci: x.sanatci, eser: x.kayit.eser, noktaSayisi: x.kayit.noktalar.length })),
        gorToplam: gor.toplam,
        ogrenSayisi: ogren.length,
        ogrenMaddeler: ogren.map((m) => ({
          no: m.no,
          madde: m.madde,
          kanitlar: m.kanitlar.map((k) => k.id),
          aciklamalar: m.aciklamalar.map((ac) => ac.id),
        })),
        ayirtKomsu: ayirt.map((x) => x.komsu),
        kapakAnahtar,
      });
    }

    // 3) Harita bölümleri (bolumleriKur)
    const tumBolumler = bolum.bolumleriKur(d.akimlar, d.sanatcilar);

    // 4) Farklı ilerleme senaryolarında Çalış ve Turlar ekranlarının bütün kuralları
    const senaryoGirdileri = [
      {
        ad: 'yeni-baslayan',
        il: {
          islenen: [1, 2, 3, 4, 5],
          ayarlar: { gunlukKart: 20 },
          skorlar: {},
          karisanlar: {},
          seviyeler: {},
          dersler: {},
          bolumler: {},
          gunluk: { tarih: bugunTarih, yeni: 0, kart: 0, yeniIdler: [] },
        },
      },
      {
        ad: 'orta-seviye',
        il: {
          islenen: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          ayarlar: { gunlukKart: 15 },
          skorlar: {
            'giotto-di-bondone': {
              sanatci: { kutu: 0, son: '2026-11-20', sonraki: '2026-11-20', dogru: 1, yanlis: 2 },
              akim: { kutu: 2, son: '2026-11-18', sonraki: '2026-11-21', dogru: 3, yanlis: 0 },
            },
            'simone-martini': {
              sanatci: { kutu: 1, son: '2026-11-19', sonraki: '2026-11-21', dogru: 2, yanlis: 1 },
              akim: { kutu: 1, son: '2026-11-19', sonraki: '2026-11-22', dogru: 1, yanlis: 1 },
            },
            'masaccio': {
              sanatci: { kutu: 4, son: '2026-11-10', sonraki: '2026-11-24', dogru: 6, yanlis: 0 },
              akim: { kutu: 4, son: '2026-11-10', sonraki: '2026-11-24', dogru: 5, yanlis: 0 },
            },
            'sandro-botticelli': {
              sanatci: { kutu: 0, son: '2026-11-21', sonraki: '2026-11-21', dogru: 0, yanlis: 3 },
            },
            'fra-angelico': {
              sanatci: { kutu: 2, son: '2026-11-19', sonraki: '2026-11-22', dogru: 2, yanlis: 0 },
            },
          },
          karisanlar: {
            'duccio-di-buoninsegna|giotto-di-bondone': { n: 3, son: '2026-11-20' },
            'fra-angelico|masaccio': { n: 2, son: '2026-11-19' },
          },
          seviyeler: {
            Gotik: { s: 1, son: [1, 1, 0, 1, 1] },
            'Erken Rönesans': { s: 0, son: [1, 0, 1] },
          },
          dersler: {
            Gotik: {
              gor: { i: 1, t: '2026-11-18' },
              ogren: { i: 0.5, t: null },
              ayirt: { i: 0, t: null },
            },
          },
          bolumler: {
            '1-1': { kolay: 0.875, orta: 0.8, tanitim: true },
          },
          gunluk: { tarih: bugunTarih, yeni: 2, kart: 5, yeniIdler: ['cimabue', 'duccio-di-buoninsegna'] },
        },
      },
      {
        ad: 'ileri-seviye',
        il: {
          islenen: Array.from({ length: 22 }, (_, i) => i + 1),
          ayarlar: { gunlukKart: 25 },
          skorlar: {
            'leonardo-da-vinci': {
              sanatci: { kutu: 5, son: '2026-11-01', sonraki: '2026-12-01', dogru: 10, yanlis: 0 },
              akim: { kutu: 5, son: '2026-11-01', sonraki: '2026-12-01', dogru: 10, yanlis: 0 },
            },
            'michelangelo': {
              sanatci: { kutu: 3, son: '2026-11-14', sonraki: '2026-11-21', dogru: 4, yanlis: 1 },
              akim: { kutu: 2, son: '2026-11-18', sonraki: '2026-11-21', dogru: 2, yanlis: 1 },
            },
            'raphael': {
              sanatci: { kutu: 1, son: '2026-11-20', sonraki: '2026-11-21', dogru: 1, yanlis: 2 },
            },
            'caravaggio': {
              sanatci: { kutu: 0, son: '2026-11-21', sonraki: '2026-11-21', dogru: 1, yanlis: 3 },
              akim: { kutu: 1, son: '2026-11-20', sonraki: '2026-11-21', dogru: 2, yanlis: 1 },
            },
          },
          karisanlar: {},
          seviyeler: {
            Gotik: { s: 2, son: [1, 1, 1, 1, 1] },
            'Erken Rönesans': { s: 1, son: [1, 1, 1, 0, 1, 1] },
            'Yüksek Rönesans': { s: 0, son: [0, 1] },
          },
          dersler: {
            Gotik: { gor: { i: 1, t: '2026-11-10' }, ogren: { i: 1, t: '2026-11-10' }, ayirt: { i: 1, t: '2026-11-10' } },
            'Erken Rönesans': { gor: { i: 1, t: '2026-11-12' }, ogren: { i: 1, t: '2026-11-12' }, ayirt: { i: 1, t: '2026-11-12' } },
            'Kuzey Rönesansı': { gor: { i: 0.353, t: null }, ogren: { i: 0, t: null }, ayirt: { i: 0, t: null } },
          },
          bolumler: {
            '1-1': { kolay: 1, orta: 0.9, zor: 0.8, tanitim: true },
            '2-1': { kolay: 0.875, orta: 0.8, tanitim: true },
            '2-2': { kolay: 0.875, orta: 0.8, tanitim: true },
          },
          gunluk: { tarih: bugunTarih, yeni: 6, kart: 12, yeniIdler: [] },
        },
      },
    ];

    const adimHaritasi = new Map(
      (dersKaynagi.dersler || []).map((x) => [x.akim, icerik.dersAdimlari(x, yuruyus)]),
    );

    const senaryolar = [];
    for (const sg of senaryoGirdileri) {
      const il = Object.assign(depo.varsayilanIlerleme(), JSON.parse(JSON.stringify(sg.il)));
      const islenenKume = new Set(il.islenen);
      const acik = kilit.acikSanatcilar(d.sanatcilar, islenenKume, il.ekSanatcilar || []);
      const akimDurum = kilit.akimDurumlari(d.akimlar, d.sanatcilar, islenenKume);
      const acikAkimKumesi = new Set(akimDurum.filter((a) => a.acik).map((a) => a.ad));

      // Harita durumları ve yolculukAkimi
      const dersBittiMi = (akim) => {
        const a = adimHaritasi.get(akim);
        return !a || ders.dersDurumu(ders.dersKaydi(il, akim), a).bitti;
      };
      const haritaDurum = bolum.bolumDurumlari(tumBolumler, il, islenenKume, d.harita, dersBittiMi);
      const bekleyen = haritaDurum.durumlar.find((z) => z.neden && z.neden.tur === 'ders');
      const simdikiDurak = haritaDurum.simdiki && haritaDurum.durumlar.find((z) => z.id === haritaDurum.simdiki);
      const yolculukAkimi = bekleyen ? bekleyen.akim : simdikiDurak ? simdikiDurak.akim : null;

      // Açık dersler ve bugünün dersi
      const siraliDersAkimlari = akimDurum.filter((a) => icerik.dersBul(dersKaynagi, a.ad));
      const acikDersAkimlari = siraliDersAkimlari.filter((a) => a.acik).map((a) => a.ad);
      const kilitliDersAkimlari = siraliDersAkimlari
        .filter((a) => !a.acik)
        .map((a) => ({ ad: a.ad, acilacagiKonu: a.acilacagiKonu ?? null }));

      const bugunku = ders.bugununDersi({
        acikAkimlar: acikDersAkimlari,
        ilerleme: il,
        yolculukAkimi,
        adimlar: (ad) => adimHaritasi.get(ad),
      });

      const acikDersler = acikDersAkimlari.map((akim) => {
        const dr = icerik.dersBul(dersKaynagi, akim);
        const adimlar = adimHaritasi.get(akim);
        const gor = icerik.gorPlani(dr, yuruyus);
        const ogren = icerik.ogrenPlani(dr);
        const ayirt = icerik.ayirtPlani(dr, { gorunur: gorunurAkimlar, acik: acikAkimKumesi, maddeler: maddelerFn });
        const acikSan = acik.filter((s) => s.akim === akim);
        const kayit = ders.dersKaydi(il, akim);
        const durum = ders.dersDurumu(kayit, adimlar);
        const hal = icerik.dersHali(durum);
        const konular = [...new Set(acikSan.map((s) => s.konu))].sort((x, y) => x - y);
        const konuAraligi = !konular.length ? '' : konular.length > 1 ? `Konu ${konular[0]}–${konular[konular.length - 1]}` : `Konu ${konular[0]}`;
        const kunye = [`${acikSan.length} sanatçı`, konuAraligi].filter(Boolean).join(' · ');

        const hbListe = haritaDurum.durumlar.filter((x) => x.akim === akim);
        const hbIlk = hbListe[0];
        const hb = {
          durak: hbListe.length,
          kilit: hbIlk && !hbIlk.acik && durum.bitti ? bolum.kilitMetni(hbIlk, tumBolumler) : '',
        };

        const adimSayisi = (a) => {
          const i = kayit[a].i;
          const toplam = a === 'gor' ? gor.toplam : a === 'ogren' ? ogren.length : ayirt.length;
          const gorulen = Math.round(i * toplam);
          return { toplam, gorulen, yazi: i > 0 && toplam ? `${gorulen}/${toplam}` : '' };
        };
        const adimAciklamasi = (a) =>
          a === 'gor'
            ? `${gor.eserler.length} eserde ${gor.toplam} ayrıntı`
            : a === 'ogren'
              ? `Nasıl tanınır? ${ogren.length} özellik`
              : `Komşu dönemlerle ${ayirt.length} ikili`;

        let davetMetni = '';
        if (!durum.siradaki) {
          if (hb.kilit) davetMetni = `Ders tamam. Haritadaki durakları: ${hb.kilit}`;
          else davetMetni = hb.durak ? `Ders tamam. Haritada ${akim} durakları seni bekliyor; sınavın orada.` : 'Ders tamam.';
        } else if (durum.siradaki === 'gor') {
          davetMetni = `Önce bak: ${adimAciklamasi('gor')}.`;
        } else if (durum.siradaki === 'ogren') {
          const m = ogren[icerik.kalinanYer(kayit.ogren.i, ogren.length)];
          if (m) {
            const n = m.kanitlar.length;
            davetMetni = `Sıradaki özellik: ${m.madde}.${n ? ` ${n} eserde göreceksin.` : ''}`;
          }
        } else {
          davetMetni = `Komşularından ayır: ${ayirt.map((x) => x.komsu).join(', ')}.`;
        }

        const a = durum.siradaki || adimlar[0];
        const suruyor = kayit[a].i > 0 && !durum.adimlar.find((x) => x.adim === a).bitti;
        const devamBaslik = !durum.siradaki ? 'Dersi yeniden aç' : suruyor ? `${ders.ADIM_ADLARI[a]} adımına devam` : `${ders.ADIM_ADLARI[a]} adımını aç`;
        const say = durum.siradaki ? adimSayisi(a) : null;
        let devamAlt = '';
        if (durum.siradaki) {
          if (!say || !say.yazi) devamAlt = adimAciklamasi(a);
          else {
            const birim = a === 'gor' ? 'ayrıntı' : a === 'ogren' ? 'özellik' : 'ikili';
            devamAlt = `${say.gorulen} / ${say.toplam} ${birim}${a === 'gor' ? ` · ${gor.eserler.length} eser` : ''}`;
          }
        }

        return {
          akim,
          hal,
          kunye,
          siradaki: durum.siradaki,
          bitti: durum.bitti,
          davetMetni,
          devamBaslik,
          devamAlt,
          haritaDurak: hb.durak,
          haritaKilit: hb.kilit,
        };
      });

      // Karışık tur özeti ve alt yazısı
      const leitnerM = await import('/js/leitner.js');
      const yeniKota = leitnerM.GUNLUK_YENI_SINIRI - (il.gunluk.tarih === bugunTarih ? il.gunluk.yeni : 0);
      const karisikTur = oturum.turOzeti({
        adaylar: acik,
        skorlar: il.skorlar,
        bugun: bugunTarih,
        adet: il.ayarlar.gunlukKart,
        yeniKota,
        kip: 'karisik',
      });
      const karisikAlt = oturum.turAltYazisi(karisikTur);

      // Sahne destesi (ilk 3 sanatçı)
      const sahneDestesi = acik
        .map((s) => ({ s, k: oturum.kategori(il.skorlar, s.id, 'karisik', bugunTarih) }))
        .sort((x, y) => x.k - y.k)
        .slice(0, 3)
        .map((x) => x.s.id);

      // Hatalarım
      const hatalar = turlar.hatalarTuru({
        adaylar: acik,
        skorlar: il.skorlar,
        karisanlar: il.karisanlar,
        bugun: bugunTarih,
        rng: () => 0.5,
      });
      const kisa = (id) => adlar.bilinenAd(d.harita.get(id).ad, d.kisaAdlar[id]);
      const hatalarAlt = [`${hatalar.hatalilar.length} sanatçı`, hatalar.ikililer.length ? `${hatalar.ikililer.length} karıştırılan ikili` : '']
        .filter(Boolean)
        .join(' · ') + ' · son 7 gün';
      const hatalarIkiliYazi = hatalar.ikililer.map((x) => `${kisa(x.a)} ↔ ${kisa(x.b)}`).join(' · ');

      // Bölüm turu kart sayısı
      const bl = st.kursBolumleri(d.konular, d.konularTr);
      const bolumTuruSayisi = Math.min(
        il.ayarlar.gunlukKart,
        acik.filter((s) => st.sanatciBolumu(s, bl)).length,
      );

      // Karşılaştır seçimi
      let karsSecim = null;
      const [ilkKarisan] = ogrenme.enCokKarisanlar(il.karisanlar || {}, {
        adet: 1,
        esik: 1,
        varMi: (id) => d.harita.has(id),
      });
      if (ilkKarisan) {
        karsSecim = {
          adres: kars.karsilastirmaAdresi(ilkKarisan.a, ilkKarisan.b),
          alt: `${kisa(ilkKarisan.a)} ↔ ${kisa(ilkKarisan.b)}`,
        };
      } else {
        const acikAk = akimDurum.filter((a) => a.acik);
        if (acikAk.length >= 2) {
          karsSecim = {
            adres: akimM.akimKarsilastirmaAdresi(acikAk[0].ad, acikAk[1].ad),
            alt: `${acikAk[0].ad} ↔ ${acikAk[1].ad}`,
          };
        }
      }

      // Hepsi salonu mozaik (4 sanatçı)
      const hepsiMozaik = [];
      const gorulenAkim = new Set();
      for (const s of acik) {
        if (!gorulenAkim.has(s.akim) && hepsiMozaik.length < 4) {
          gorulenAkim.add(s.akim);
          hepsiMozaik.push(s.id);
        }
      }

      // Dönem salonları (3 sıralama: sira, tekrar, zayif)
      const acikDurumlar = akimDurum.filter((a) => a.acik);
      const istler = new Map(acikDurumlar.map((a) => [a.ad, pano.akimIstatistigi(a.ad, acik, il.skorlar, bugunTarih)]));
      const turYazi = (t) => `${t.toplam} kart${t.tekrar ? ` · ${t.tekrar} tekrar` : ''}`;
      const salonSiralamalari = {};
      for (const siraKipi of ['sira', 'tekrar', 'zayif']) {
        const sirali = acikDurumlar.slice();
        if (siraKipi === 'tekrar') sirali.sort((x, y) => istler.get(y.ad).vade - istler.get(x.ad).vade);
        if (siraKipi === 'zayif') {
          sirali.sort((x, y) => {
            const ox = istler.get(x.ad).oran;
            const oy = istler.get(y.ad).oran;
            return seviye.seviyeKaydi(il, x.ad).s - seviye.seviyeKaydi(il, y.ad).s || (ox ?? 2) - (oy ?? 2);
          });
        }
        salonSiralamalari[siraKipi] = sirali.map((a) => {
          const k = seviye.seviyeKaydi(il, a.ad);
          const l = acik.filter((s) => s.akim === a.ad);
          const tem = l.find((s) => s.kaynak === 'kurs') || l[0];
          const dt = oturum.turOzeti({
            adaylar: l,
            skorlar: il.skorlar,
            bugun: bugunTarih,
            adet: il.ayarlar.gunlukKart,
            yeniKota,
            kip: 'donem',
          });
          const ist = istler.get(a.ad);
          return {
            ad: a.ad,
            acikSayisi: a.acikSayisi,
            temsilciId: tem ? tem.id : null,
            seviyeRozeti: seviye.seviyeKisa(k),
            turYazisi: turYazi(dt),
            dogru: ist.dg,
            toplam: ist.tp,
            vade: ist.vade,
            oranYuzde: ist.oran === null ? null : Math.round(100 * ist.oran),
          };
        });
      }

      // 14 günlük gelecek yük
      const gunlukYuk = gecmis.gelecekYuk(
        il.skorlar,
        acik.map((s) => s.id),
        bugunTarih,
        14,
      );
      const yukToplam = gunlukYuk.reduce((t, n) => t + n, 0);
      const yukYazi = yukToplam
        ? `Bugün ${gunlukYuk[0]} · yarın ${gunlukYuk[1] ?? 0} · 14 günde ${yukToplam} sanatçı`
        : 'Tekrarı gelen sanatçı yok';

      senaryolar.push({
        ad: sg.ad,
        il: sg.il,
        yolculukAkimi,
        bugunku,
        kilitliDersAkimlari,
        acikDersler,
        karisikTur,
        karisikAlt,
        sahneDestesi,
        hatalar: {
          idler: hatalar.idler,
          hatalilar: hatalar.hatalilar,
          alt: hatalarAlt,
          ikiliYazi: hatalarIkiliYazi,
        },
        bolumTuruSayisi,
        karsSecim,
        hepsiMozaik,
        salonSiralamalari,
        gunlukYuk,
        yukYazi,
      });
    }

    // 5) Kurs bölümleri ve yüzyıl aralıkları
    const bl = st.kursBolumleri(d.konular, null);
    const kursBolumleriSonuc = bl.map((b) => ({
      id: b.id,
      no: b.no,
      ad: b.ad,
      kisaAd: st.bolumKisaAdi(b),
      konular: b.konular,
      yuzyilAraligi: st.yuzyilAraligi(b, d.sanatcilar),
    }));

    // 6) İkonografi konuları
    const ikonoKonular = ik.konulariAl(ikonoJson, (id) => d.harita.has(id));
    const ikonoSonuc = ikonoKonular.slice(0, 15).map((k) => ({
      id: k.id,
      ad: k.ad,
      tur: k.tur,
      turAdi: ik.TUR_AD[k.tur],
      ozet: k.ozet,
      kaynak: k.kaynak,
      hikayeSayisi: k.hikaye.length,
      eserSayisi: k.eserler.length,
    }));

    // 7) Deste, sarkaç ve eğim fiziği
    const yelpazeGirdileri = [-1, -0.65, -0.25, 0, 0.35, 0.8, 1.4];
    const yelpazeSonuclari = yelpazeGirdileri.map((x) => ({ x, hedef: deste.yelpazeHedefi(x) }));

    let acilimDurum = { aci: 0, hiz: 0 };
    let yatmaDurum = { aci: 0, hiz: 0 };
    const sarkacIzleri = [];
    const h = deste.yelpazeHedefi(0.75);
    for (let i = 0; i < 12; i++) {
      acilimDurum = sallanma.sarkacAdim(acilimDurum, h.acilim, 0.016, 90, 6);
      yatmaDurum = sallanma.sarkacAdim(yatmaDurum, h.yatma, 0.016, 90, 6);
      sarkacIzleri.push({
        acilim: acilimDurum,
        yatma: yatmaDurum,
        durgun: sallanma.durgunMu(acilimDurum, h.acilim) && sallanma.durgunMu(yatmaDurum, h.yatma),
      });
    }

    let donus = { x: 0, y: 0 };
    const egimIzleri = [];
    for (const [beta, gamma, dt] of [
      [15, -30, 0.02],
      [10, -25, 0.02],
      [-5, 40, 0.03],
      [0, 0, 0.5],
    ]) {
      donus = egim.donusIzle(donus, { beta, gamma }, dt);
      egimIzleri.push({
        donus,
        egim: egim.donustenEgim(donus),
      });
    }

    const aciOrnekleri = [
      [45, 20],
      [70, -15],
      [10, 5],
    ].map(([b, g]) => ({
      b,
      g,
      acilar: egim.egimAcilari(b, g),
      hesap: egim.egimHesapla(b, g, { beta: 40, gamma: 0 }),
    }));

    return {
      bugun: bugunTarih,
      bulunmaSonuclari,
      dersPlanlari,
      tumBolumler,
      senaryolar,
      kursBolumleriSonuc,
      ikonoToplam: ikonoKonular.length,
      ikonoSonuc,
      yelpazeSonuclari,
      sarkacIzleri,
      egimIzleri,
      aciOrnekleri,
    };
  });

  console.log(JSON.stringify(sonuc, null, 2));
} finally {
  await tarayici.close();
}
