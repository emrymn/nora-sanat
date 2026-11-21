// Kaynak: sanat-atlasi js/{soruTurlari,oturum,devam,leitner}.js @ a866b86
// node pekistirmeKahini.mjs /yol/sanat-atlasi
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const kok = process.argv[2];
if (!kok) throw new Error('Sanat Atlası kaynak klasörünü ver.');
const modul = (ad) => import(pathToFileURL(resolve(kok, 'js', ad + '.js')).href);
const { bolumSecenekleri, konuSecenekleri, turSirasi } = await modul('soruTurlari');
const { Oturum } = await modul('oturum');
const { cevapla } = await modul('leitner');
const { kayitYap, kayittanKur } = await modul('devam');
const ids=['a','b','c','d','e'], rng=()=>0.42, bugun='2026-11-21';
const konular=ids.map((id,i)=>({id,tur:i<3?'din':'tarih'}));
const oturum=new Oturum(ids,{rng}); oturum.isle(false); oturum.ilerle();
const geri=kayittanKur(kayitYap({kip:'karisik',oturum}),{varMi:()=>true,rng}).oturum;
console.log(JSON.stringify({bolum:bolumSecenekleri('c',ids.map(id=>({id})),rng),konu:konuSecenekleri(konular[0],konular,rng),sira:turSirasi(ids,()=>undefined,{bugun,rng}),yanlis:cevapla(undefined,false,bugun),kuyruk:geri.kuyruk.map(k=>k.id+(k.tekrar?'*':'')),konum:geri.konum}));
