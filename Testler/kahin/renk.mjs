// Z2c-2 kâhini: sitenin resim rengi ve renkli Gündüz kuralları (js/renk.js, js/gunduzRenk.js, js/tasarim.js kontrast),
// sitenin kendi modülleriyle, tarayıcısız (Node). Girdiler tohumlu rastgele: küçük "tablolar" (birkaç renk bölgesi,
// gürültü, saydam pikseller, vernik kayması, gravür gibi renksiz) ve tek tek renkler.
//
//   node Testler/kahin/renk.mjs <sanat-atlasi deposu> > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/renk/cevaplar.json
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';

const kok = resolve(process.argv[2] || '.');
const R = await import(pathToFileURL(resolve(kok, 'js/renk.js')));
const G = await import(pathToFileURL(resolve(kok, 'js/gunduzRenk.js')));
const T = await import(pathToFileURL(resolve(kok, 'js/tasarim.js')));

let tohum = 20261124;
const rng = () => {
  tohum |= 0; tohum = (tohum + 0x6d2b79f5) | 0;
  let t = Math.imul(tohum ^ (tohum >>> 15), 1 | tohum);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const tam = (n) => Math.floor(rng() * n);
const sinir = (x) => Math.max(0, Math.min(255, Math.round(x)));
const renkUret = () => R.hexe([tam(256), tam(256), tam(256)]);

function resim(w, h, tur) {
  const veri = new Uint8ClampedArray(w * h * 4);
  const bolge = 1 + tam(6);
  const renkler = Array.from({ length: bolge }, () => {
    if (tur === 'gri') { const g = tam(256); return [g, g, g]; }
    if (tur === 'vernik') return [120 + tam(130), 90 + tam(110), 30 + tam(70)];
    return [tam(256), tam(256), tam(256)];
  });
  const merkez = renkler.map(() => [rng() * w, rng() * h]);
  const gurultu = tur === 'gurultu' ? 80 : 18;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    let en = 0, d = Infinity;
    merkez.forEach(([cx, cy], i) => { const e = (cx - x) ** 2 + (cy - y) ** 2; if (e < d) { d = e; en = i; } });
    const c = renkler[en];
    const i = (y * w + x) * 4;
    const n = (rng() - 0.5) * gurultu;
    veri[i] = sinir(c[0] + n); veri[i + 1] = sinir(c[1] + n * (tur === 'gri' ? 1 : rng())); veri[i + 2] = sinir(c[2] + n);
    veri[i + 3] = tur === 'saydam' && rng() < 0.3 ? tam(128) : 255;
  }
  return veri;
}

const turler = ['renkli', 'renkli', 'renkli', 'vernik', 'gri', 'gurultu', 'saydam'];
const resimler = [];
for (let k = 0; k < 70; k++) {
  const tur = turler[k % turler.length];
  const w = 16 + tam(24), h = 16 + tam(24);
  const veri = resim(w, h, tur);
  const adet = k % 5 === 0 ? 3 + tam(5) : 6;
  const palet = R.paletHesapla(veri, adet);
  const tonlar = R.tonlariHesapla(veri);
  const zeminler = ['#121110', '#ECE8E1', G.resimdenPalet(tonlar)?.bg || '#e6dcc4'];
  const gp = G.resimdenPalet(tonlar);
  resimler.push({
    tur, w, h, adet,
    piksel: Buffer.from(veri.buffer).toString('base64'),
    palet,
    vurgu: R.vurguSec(palet),
    temalar: zeminler.map((z) => ({ zemin: z, tema: R.renkTemasi(palet, z) })),
    tonlar,
    gunduz: gp,
    degiskenler: gp ? G.paletDegiskenleri(gp) : null,
  });
}

const renkler = [];
for (let k = 0; k < 200; k++) {
  const c = renkUret(), z = rng() < 0.5 ? '#121110' : (rng() < 0.5 ? '#ECE8E1' : renkUret());
  renkler.push({
    renk: c, zemin: z,
    hsl: R.hsl(c), geri: R.hsldenHex(...R.hsl(c)),
    kontrast: T.kontrast(c, z),
    acik: R.acikHal(c, z), dolu: R.doluButon(c), yumusak: R.yumusat(c),
    karisim: R.karistir(c, z, 0.3),
  });
}

const hazir = Object.fromEntries(G.GUNDUZ_RENKLERI.map((s) => {
  const p = G.gunduzPaleti(s, null);
  return [s, p ? { palet: p, degiskenler: G.paletDegiskenleri(p) } : null];
}));

process.stdout.write(JSON.stringify({ resimler, renkler, hazir }) + '\n');
