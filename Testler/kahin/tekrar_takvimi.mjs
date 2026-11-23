// Z2c kâhini: uygulamanın eski köprü betiğinin tekrar takvimi (NoraSanat/TekrarKoprusu.swift, Z2c'de silindi; işlev aşağıda
// aynen), tohumlu rastgele ilerlemelerle. Swift karşılığı: TekrarTakvimi.hesapla (Paketler/NoraCekirdek/…/TekrarPlani.swift).
//
//   node Testler/kahin/tekrar_takvimi.mjs > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/tekrar_takvimi/cevaplar.json
// Eski köprü betiğinin takvim işlevi (NoraSanat/TekrarKoprusu.swift, Z2c'de silindi; sitenin vadeSayisi'yle aynı sayım)
const GUN = 14;
function iki(n) { return (n < 10 ? '0' : '') + n; }
function gunStr(d) { return d.getFullYear() + '-' + iki(d.getMonth() + 1) + '-' + iki(d.getDate()); }
function gunEkle(t, n) { var p = t.split('-').map(Number); return gunStr(new Date(p[0], p[1] - 1, p[2] + n, 12)); }

// ham: localStorage'daki ilerleme (JSON); bugun: "YYYY-MM-DD"
function takvim(ham, bugun) {
  var v = JSON.parse(ham);
  if (!v || typeof v !== 'object') return null;
  if (v.ilerleme && typeof v.ilerleme === 'object') v = v.ilerleme;
  var sk = v.skorlar && typeof v.skorlar === 'object' ? v.skorlar : {};
  var sinir = [], gunler = [];
  for (var i = 0; i < GUN; i++) { sinir.push(gunEkle(bugun, i)); gunler.push(0); }
  Object.keys(sk).forEach(function (id) {
    var s = sk[id] || {};
    var t = [s.sanatci, s.akim]
      .filter(function (x) { return x && x.son && typeof x.sonraki === 'string' && x.sonraki; })
      .map(function (x) { return x.sonraki; })
      .sort();
    if (!t.length) return;
    for (var i = 0; i < GUN; i++) {
      if (t[0] <= sinir[i]) { for (var j = i; j < GUN; j++) gunler[j]++; break; }
    }
  });
  return { bugun: bugun, gunler: gunler, rozet: !!(v.ayarlar && v.ayarlar.rozet) };
}

let tohum = 20261123;
const rng = () => {
  tohum |= 0; tohum = (tohum + 0x6d2b79f5) | 0;
  let t = Math.imul(tohum ^ (tohum >>> 15), 1 | tohum);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const sec = (a) => a[Math.floor(rng() * a.length)];
const gun = (taban, fark) => {
  const [y, a, g] = taban.split('-').map(Number);
  const d = new Date(Date.UTC(y, a - 1, g + fark));
  return d.toISOString().slice(0, 10);
};
const bugunler = ['2026-11-23', '2026-12-30', '2027-02-27', '2028-02-28', '2026-03-28'];
function skor(bugun) {
  const r = rng();
  if (r < 0.08) return sec([null, 0, 'x', [], true]);
  const s = { kutu: Math.floor(rng() * 5), dogru: 1, yanlis: 0 };
  s.son = sec([gun(bugun, -3), gun(bugun, -40), null, '', 0, 1]);
  s.sonraki = rng() < 0.1 ? sec(['', null, 5, undefined]) : gun(bugun, Math.floor(rng() * 40) - 10);
  return s;
}
const vakalar = [];
for (let i = 0; i < 300; i++) {
  const bugun = sec(bugunler);
  const skorlar = {};
  const n = Math.floor(rng() * 30);
  for (let k = 0; k < n; k++) {
    const kayit = {};
    if (rng() < 0.8) kayit.sanatci = skor(bugun);
    if (rng() < 0.6) kayit.akim = skor(bugun);
    skorlar['s' + k] = rng() < 0.05 ? sec([null, 3, 'a']) : kayit;
  }
  let il = { skorlar, ayarlar: { rozet: sec([true, false, 1, 0, 'evet', undefined]) } };
  if (rng() < 0.1) il = { ilerleme: il };
  if (rng() < 0.05) il = sec([{}, { skorlar: null }, { skorlar: [] }]);
  const ham = JSON.stringify(il);
  vakalar.push({ girdi: JSON.parse(ham), bugun, cikti: takvim(ham, bugun) });
}
process.stdout.write(JSON.stringify({ vakalar }) + '\n');
