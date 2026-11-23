// Z3f kâhini: sitenin harf tablosu ve Google Fonts adresi (js/harfler.js), sitenin modülüyle, tarayıcısız.
//   node Testler/kahin/harfler.mjs <sanat-atlasi deposu> > Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/harfler/cevaplar.json
// Site tabloyu değiştirirse Paketler/NoraCekirdek/Sources/NoraCekirdek/Galeri/DonemHarfleri.swift de güncellenir.
import { pathToFileURL } from 'node:url';
import { resolve } from 'node:path';
const h = await import(pathToFileURL(resolve(process.argv[2] || '.', 'js/harfler.js')));
const ornek = [['Rönesans', h.BOLGE_HARFLERI.ronesans], ['Orta Çağ', h.BOLGE_HARFLERI.ortacag],
  ['Romantizmden Realizme', h.BOLGE_HARFLERI.romantik], ['Empresyonizm', h.BOLGE_HARFLERI.empresyonizm], ['Kübizm', h.AKIM_HARFLERI['Kübizm']]];
process.stdout.write(JSON.stringify({ akimlar: h.AKIM_HARFLERI, bolgeler: h.BOLGE_HARFLERI,
  adresler: ornek.map(([metin, harf]) => ({ metin, harf, adres: h.fontAdresi(harf, metin) })) }) + '\n');
