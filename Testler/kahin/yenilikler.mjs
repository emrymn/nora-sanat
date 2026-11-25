// Z3x kâhini: sitenin sürüm notları (js/yenilikler.js), sitenin kendi modülüyle, tarayıcısız.
//   node Testler/kahin/yenilikler.mjs <sanat-atlasi deposu> Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/yenilikler
// Klasöre iki dosya yazar: sitenin dosyasının kopyası (yenilikler.js; Swift okuyucusu bunu çözer) ve cevaplar.json
// (liste, yenilikYazisi, gosterilecekler örnekleri). Uygulama listeyi her zaman siteden indirir; kopya yalnız test içindir.
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
import { copyFileSync, writeFileSync } from 'node:fs';
const kok = resolve(process.argv[2] || '.');
const hedef = resolve(process.argv[3] || '.');
const y = await import(pathToFileURL(resolve(kok, 'js/yenilikler.js')));
const ornekler = [
  [null, '1.90.3', false], [null, '1.90.3', true], ['1.90.0', '1.90.3', false], ['1.89.2', '1.90.3', true],
  ['1.90.3', '1.90.3', true], ['1.90.1', '1.90.2', true], ['1.2', '1.90.3', true], ['1.30.0', '1.31.0', true],
  [null, '1.0.0', true], ['', '1.90.3', true],
];
const kucuk = [{ surum: '2.0.0', metin: 'c' }, { surum: '1.10.0', metin: 'b' }, { surum: '1.9.1', metin: 'a' }];
copyFileSync(resolve(kok, 'js/yenilikler.js'), resolve(hedef, 'yenilikler.js'));
writeFileSync(resolve(hedef, 'cevaplar.json'), JSON.stringify({
  liste: y.YENILIKLER,
  yazilar: y.YENILIKLER.map(y.yenilikYazisi),
  gosterilecekler: ornekler.map(([son, surum, calismis]) => ({ son, surum, calismis,
    sonuc: y.gosterilecekler(son, surum, calismis).map((x) => x.surum) })),
  kucuk: ornekler.map(([son, surum, calismis]) => ({ son, surum, calismis,
    sonuc: y.gosterilecekler(son, surum, calismis, kucuk).map((x) => x.surum) })),
}, null, 1) + '\n');
