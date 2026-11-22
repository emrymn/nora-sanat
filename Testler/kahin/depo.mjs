// Z2a kâhini: sitenin kayıt kuralları (js/depo.js ilerlemeDogrula, yedekCoz, yedekYarimOturum, yedekMetni,
// gunlukGuncelle, sonCalisilanEkle, enYeniKayit, yedekHatirlatmasi, gelistiriciAc/Kapat), sitenin kendi
// modülleriyle, tarayıcısız (Node). Saat sabit: 2026-11-22T10:00:00Z, saat dilimi UTC.
//
//   TZ=UTC node Testler/kahin/depo.mjs <sanat-atlasi deposu> > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/depo/cevaplar.json
//
// Girdiler tohumlu rastgele: gerçek biçimdeki ilerlemeler, eski sürümler (Sepya, Koyu, Açık), bozuk alanlar (yanlış
// türler, sınır dışı sayılar, tekrarlar, birleşen akımlar), yedek metinleri ve bozuk JSON.
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

if (process.env.TZ !== 'UTC') throw new Error('TZ=UTC ile çalıştır');
const SABIT = Date.parse('2026-11-22T10:00:00.000Z');
const AsilDate = Date;
globalThis.Date = class extends AsilDate {
  constructor(...a) { super(...(a.length ? a : [SABIT])); }
  static now() { return SABIT; }
};

const kok = resolve(process.argv[2] || '.');
const D = await import(pathToFileURL(resolve(kok, 'js/depo.js')));

// Tohumlu rastgele (mulberry32)
let tohum = 20261122;
const rng = () => {
  tohum |= 0; tohum = (tohum + 0x6d2b79f5) | 0;
  let t = Math.imul(tohum ^ (tohum >>> 15), 1 | tohum);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const tam = (a, b) => a + Math.floor(rng() * (b - a + 1));
const sec = (l) => l[Math.floor(rng() * l.length)];
const belki = (p) => rng() < p;

const tarih = () => `2026-${String(tam(1, 12)).padStart(2, '0')}-${String(tam(1, 28)).padStart(2, '0')}`;
const tuhaf = () => sec([null, true, false, 0, -1, 1.5, '', 'x', '12', [], [1, 'a'], {}, { a: 1 }, 1e3, NaN === 0, '2026-1-2']);
const ids = ['giotto-di-bondone', 'duccio', 'rembrandt', 'caravaggio', 'monet', 'a', 'b', 'çini-ustası'];
const akimlar = ['Gotik', 'Uluslararası Gotik', 'Barok', 'Erken Rönesans', 'Empresyonizm'];

function skor() {
  if (belki(0.03)) return tuhaf();
  const s = { kutu: belki(0.03) ? sec([6, -1, 2.5, '3']) : tam(0, 5), dogru: belki(0.03) ? sec([-2, 3.7, '4', null]) : tam(0, 9), yanlis: belki(0.05) ? sec([-1, 2.2]) : tam(0, 6) };
  if (belki(0.8)) s.son = belki(0.15) ? tuhaf() : tarih();
  if (belki(0.8)) s.sonraki = belki(0.15) ? tuhaf() : belki(0.1) ? null : tarih();
  if (belki(0.1)) s.ek = 'korunur';
  return s;
}

function ilerleme() {
  const v = {};
  if (belki(0.7)) v.surum = sec([1, 2, 2, '2', null, 3]);
  v.islenen = belki(0.05) ? sec([null, 'x', [1, 'a'], [1.5]]) : Array.from({ length: tam(0, 20) }, () => tam(1, 60));
  if (belki(0.85)) {
    v.skorlar = {};
    for (let i = 0; i < tam(0, 6); i++) {
      const id = sec(ids);
      const s = {};
      if (belki(0.8)) s.sanatci = skor();
      if (belki(0.5)) s.akim = skor();
      if (belki(0.3)) s.bolumKart = skor();
      v.skorlar[id] = belki(0.02) ? tuhaf() : s;
    }
    if (belki(0.03)) v.skorlar = sec([[], 'x', 5]);
  }
  if (belki(0.5)) {
    v.skorlarKonu = belki(0.1) ? tuhaf() : {};
    if (v.skorlarKonu && typeof v.skorlarKonu === 'object') for (let i = 0; i < tam(0, 4); i++) v.skorlarKonu[sec(['annunciation', 'x'.repeat(130), 'pieta'])] = skor();
  }
  if (belki(0.9)) {
    const a = {};
    if (belki(0.7)) a.tema = sec(['gece', 'gunduz', 'sepya', 'koyu', 'acik', 'mor', 3]);
    if (belki(0.6)) a.gunlukKart = sec([20, 3, 150, '35', '12abc', ' 7', -4, 0, 50.9, null, true, [30], '1e3']);
    for (const k of ['tanisma', 'rozet', 'egim', 'titresim']) if (belki(0.4)) a[k] = sec([true, false, 0, 1, 'evet', null]);
    if (belki(0.5)) a.hareket = sec(['tam', 'sade', 'kapali', 'hızlı']);
    if (belki(0.4)) a.yazi = sec(['standart', 'buyuk', 'kucuk']);
    if (belki(0.4)) a.gunduzRenk = sec(['otomatik', 'lapis', 'pembe']);
    if (belki(0.3)) a['calis.tur'] = JSON.stringify({ zaman: 1 });
    v.ayarlar = belki(0.05) ? sec([null, [1, 2], 5]) : a;
  }
  if (belki(0.6)) v.gunluk = belki(0.1) ? tuhaf() : { tarih: sec(['2026-11-22', tarih()]), yeni: tam(0, 9), kart: tam(0, 30), ...(belki(0.8) ? { yeniIdler: belki(0.1) ? 'x' : [sec(ids)] } : {}) };
  if (belki(0.4)) v.sonEserler = belki(0.2) ? tuhaf() : { [sec(ids)]: ['e1'] };
  if (belki(0.4)) v.kotuGorseller = belki(0.2) ? tuhaf() : { e1: ['g1', 2, 'g2'], e2: 'x' };
  if (belki(0.5)) v.ekSanatcilar = belki(0.1) ? tuhaf() : [sec(ids), sec(ids), 3, sec(ids)];
  if (belki(0.5)) v.sonCalisilanlar = belki(0.1) ? tuhaf() : Array.from({ length: tam(0, 16) }, () => sec([...ids, 'z' + tam(1, 20), 5]));
  if (belki(0.5)) {
    v.karisanlar = belki(0.1) ? tuhaf() : {};
    if (v.karisanlar && typeof v.karisanlar === 'object' && !Array.isArray(v.karisanlar))
      for (let i = 0; i < tam(0, 5); i++) v.karisanlar[sec(['b|a', 'a|b', 'a|a', 'a', '|x', 'monet|duccio', 'a|b|c'])] = sec([{ n: tam(1, 5), son: tarih() }, { n: 0 }, { n: 2 }, { n: 1.5 }, null]);
  }
  if (belki(0.5)) {
    v.seviyeler = belki(0.1) ? tuhaf() : {};
    if (v.seviyeler && typeof v.seviyeler === 'object' && !Array.isArray(v.seviyeler))
      for (let i = 0; i < tam(0, 4); i++) v.seviyeler[sec(akimlar)] = sec([{ s: tam(0, 2), son: Array.from({ length: tam(0, 14) }, () => sec([0, 1, 2, 3, '1'])) }, { s: 3, son: [] }, { s: 1 }, null]);
  }
  if (belki(0.4)) v.sonYedek = sec([tarih(), null, 'dün', 5]);
  if (belki(0.5)) {
    v.gecmis = belki(0.1) ? tuhaf() : {};
    if (v.gecmis && typeof v.gecmis === 'object' && !Array.isArray(v.gecmis))
      for (let i = 0; i < tam(0, 5); i++) v.gecmis[sec([tarih(), 'kötü'])] = sec([{ kart: tam(0, 30), dogru: tam(0, 40), akimlar: { [sec(akimlar)]: tam(0, 5), [sec(akimlar)]: sec([2, -1, 1.5, '3']) } }, { kart: 1 }, { kart: -1, dogru: 0 }, null, { kart: 2, dogru: 1, akimlar: [3, 4] }]);
  }
  if (belki(0.4)) v.koleksiyon = belki(0.1) ? tuhaf() : Array.from({ length: tam(0, 5) }, () => sec([{ a: sec(['e1', 'e2', 'e3']), s: sec(ids), t: tarih() }, { a: 'e9', s: 'x' }, { a: 3, s: 'x' }, null]));
  if (belki(0.4)) v.haritaGorulen = belki(0.1) ? tuhaf() : ['2-1', '2-1', 3, '4-1'];
  if (belki(0.4)) v.haritaYolcu = sec(['4-1', null, 5, 'x'.repeat(45)]);
  if (belki(0.3)) v.haritaYolcuOn = sec([true, false, 1, 'true']);
  if (belki(0.5)) {
    v.bolumler = belki(0.1) ? tuhaf() : {};
    if (v.bolumler && typeof v.bolumler === 'object' && !Array.isArray(v.bolumler))
      for (let i = 0; i < tam(0, 5); i++)
        v.bolumler[sec(['2-1', '3-1', '4-2', 'x-1', '12-10'])] = sec([
          { kolay: rng(), orta: sec([1, 1.2, -0.1, '0.5']), zor: 0, tanitim: sec([true, 1]), tanitimOrta: true, tanitimGrup: [3, 1, 1, 12, -1, 2.5, '4'], tanitimOrtaGrup: [] },
          { kolay: 0.75 }, null, 'x',
        ]);
  }
  if (belki(0.5)) {
    v.dersler = belki(0.1) ? tuhaf() : {};
    if (v.dersler && typeof v.dersler === 'object' && !Array.isArray(v.dersler))
      for (let i = 0; i < tam(0, 4); i++)
        v.dersler[sec([...akimlar, 'u'.repeat(90)])] = sec([
          { gor: { i: sec([1, 0.4, 0.12345, 1.7, -2, 0.9995, '1']), t: sec([tarih(), null, 'x']) }, ogren: { i: rng() }, ayirt: sec([{ i: 1, t: tarih() }, 5, null]) },
          [], null, {},
        ]);
  }
  if (belki(0.4)) v.bildirimler = belki(0.1) ? tuhaf() : [{ a: 'e1', s: 'x', baslik: sec(['Başlık', 5, null, ['a', 'b']]), neden: sec(['Kötü görsel', 'Yanlış ad', 'başka']), g: sec(['g', 3]), t: tarih() }, null];
  if (belki(0.3)) v.sonSurum = sec(['1.90.3', '1.9', 'v1.2.3', null]);
  if (belki(0.15)) v.gelistirici = sec([{ tarih: '2026-11-01T00:00:00.000Z', yedek: { islenen: [1, 2], ayarlar: { tema: 'gunduz' } }, yarim: { kip: 'karisik' } }, { yedek: { islenen: 'x' } }, { tarih: 5, yedek: { islenen: [] }, yarim: 'x' }, true]);
  if (belki(0.3)) v.gununDegisim = sec([{ tarih: tarih(), id: sec(ids) }, { tarih: 'x', id: 'a' }, { id: 'a' }, { tarih: tarih(), id: 3 }, null]);
  if (belki(0.5)) v.olusturma = sec(['2026-01-05T08:00:00.000Z', '', null, 7]);
  if (belki(0.6)) v.kayitNo = sec([tam(0, 900), -1, 2.5, '9']);
  if (belki(0.1)) v.bilinmeyenAlan = 'atılır';
  return belki(0.08) ? { uygulama: 'sanat-atlasi', ilerleme: v } : v;
}

function sonuc(f) {
  try {
    return { cikti: f() };
  } catch (e) {
    return { hata: e.message };
  }
}

const vakalar = [];
const sabitler = [null, 5, 0, 'metin', [], [1, 2], {}, { islenen: [] }, { ilerleme: [] }, { ilerleme: { islenen: [3] } }, { islenen: [1], skorlar: null }, { islenen: [1], skorlar: { a: [] } }, { islenen: [1], skorlar: { a: { sanatci: null } } }];
for (const g of sabitler) vakalar.push({ girdi: g, ...sonuc(() => D.ilerlemeDogrula(g)) });
for (let i = 0; i < 400; i++) {
  const g = ilerleme();
  vakalar.push({ girdi: g, ...sonuc(() => D.ilerlemeDogrula(g)) });
}

const yedekler = [];
for (const v of vakalar.slice(13, 40)) {
  if (v.hata) continue;
  const yarim = belki(0.5) ? { kip: 'karisik', kuyruk: [] } : null;
  yedekler.push({ ilerleme: v.cikti, yarim, metin: D.yedekMetni(v.cikti, yarim) });
}
const cozumler = [];
for (const m of ['', '  ', '{', 'null', '5', '"x"', '[]', '{"islenen":[2,1]}', '﻿ {"ilerleme":{"islenen":[]},"yarimOturum":{"a":1}} \n', '{"yarimOturum":0}', ...yedekler.slice(0, 5).map((y) => y.metin)]) {
  cozumler.push({ metin: m, ...sonuc(() => D.yedekCoz(m)), yarim: D.yedekYarimOturum(m) });
}

const kucukler = [];
for (const v of vakalar.slice(13, 80)) {
  if (v.hata) continue;
  const il = structuredClone(v.cikti);
  const bugun = sec(['2026-11-22', il.gunluk.tarih]);
  const g = structuredClone(il);
  D.gunlukGuncelle(g, bugun);
  const id = sec([...ids, ...(il.sonCalisilanlar.length ? [il.sonCalisilanlar[0]] : [])]);
  const s = structuredClone(il);
  D.sonCalisilanEkle(s, id);
  const hat = sec(['2026-11-22', '2027-03-01', '2026-01-10']);
  kucukler.push({
    ilerleme: il, bugun, gunluk: g.gunluk, id, sonCalisilanlar: s.sonCalisilanlar, hatirlatmaGunu: hat,
    hatirlatma: D.yedekHatirlatmasi(il, hat),
  });
}

const enYeni = [];
for (let i = 0; i < 20; i++) {
  const a = belki(0.15) ? null : { kayitNo: sec([undefined, 0, 3, 9]), ad: 'ls' };
  const b = belki(0.15) ? null : { kayitNo: sec([undefined, 0, 3, 9]), ad: 'idb' };
  for (const x of [a, b]) if (x && x.kayitNo === undefined) delete x.kayitNo;
  enYeni.push({ ls: a, idb: b, secilen: D.enYeniKayit(a, b) });
}

const gelistirici = [];
for (const v of vakalar.slice(13, 60)) {
  if (v.hata || v.cikti.gelistirici) continue;
  const konular = [1, 2, 3, 57];
  const bolumIdleri = ['2-1', '3-1', '9-9'];
  const yarim = belki(0.5) ? { kip: 'donem' } : null;
  const acik = D.gelistiriciAc(structuredClone(v.cikti), konular, bolumIdleri, yarim);
  const kapali = D.gelistiriciKapat({ ...structuredClone(acik), ayarlar: { ...acik.ayarlar, tema: 'gunduz' } });
  gelistirici.push({ ilerleme: v.cikti, konular, bolumIdleri, yarim, acik, kapali });
  if (gelistirici.length >= 12) break;
}

const varsayilan = [D.varsayilanIlerleme(), D.varsayilanIlerleme([5, 1, 2])];

process.stdout.write(JSON.stringify({ simdi: new Date().toISOString(), bugun: '2026-11-22', varsayilan, vakalar, yedekler, cozumler, kucukler, enYeni, gelistirici }));
