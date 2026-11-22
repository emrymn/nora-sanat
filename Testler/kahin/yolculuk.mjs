// Kaynak: sanat-atlasi js/{bolum,harita,zaman}.js @ a866b86
// node Testler/kahin/yolculuk.mjs /tmp/sa (aynı commit'in salt okunur kopyası)
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
const kok = resolve(process.argv[2]);
const modul = ad => import(pathToFileURL(resolve(kok,'js',ad+'.js')));
const oku = async ad => JSON.parse(await readFile(resolve(kok,'data',ad+'.json'),'utf8'));
const b = await modul('bolum'), h = await modul('harita'), z = await modul('zaman');
const { sanatcilariBirlestir, akimlariBirlestir } = await modul('birlesme');
const { gorunurSanatcilar, gorunurAkimlar } = await modul('resim');
const sanatcilar = gorunurSanatcilar(sanatcilariBirlestir(await oku('sanatcilar')),await oku('eser_turleri'),await oku('eserler_onbellek'));
const akimlar = gorunurAkimlar(akimlariBirlestir(await oku('akimlar')),sanatcilar);
const bolumler = b.bolumleriKur(akimlar,sanatcilar);
const harita = await oku('harita');
const kisiler = new Map(sanatcilar.map(s=>[s.id,s]));
const kayitlar = Object.fromEntries(bolumler.slice(0,8).map(x=>[x.id,{kolay:.75,orta:.8}]));
const durum = b.bolumDurumlari(bolumler,{bolumler:kayitlar},Array.from({length:58},(_,i)=>i),kisiler,()=>true);
const plan = h.haritaKur(durum.durumlar,harita);
const duraklar = plan.bolgeler.flatMap(r=>r.duraklar.map(x=>({
  id:x.id,bolge:r.id,x:x.x,y:x.y,sembol:x.sembolNo,ad:b.bolumAdi(x),sanatcilar:x.sanatcilar,
  gruplar:b.tanismaGruplari(x.sanatcilar),kilit:x.neden ? b.kilitMetni(x,bolumler) : null,yildiz:x.yildiz
})));
const yillar = [1250,1333,1500,1600,1875,1900,2000].map(y=>({
  yil:y,evre:z.yuzyilEvresi(y),idler:z.yasayanlar(sanatcilar,y).map(x=>x.s.id)
}));
const cubuklar = z.yogunluk(sanatcilar,s=>s.konu<12).map(x=>[x.n,x.akim,x.acik]);
const konumlar = {bolgeler:Object.fromEntries(Object.entries(harita.bolgeler).map(([ad,v])=>[ad,{duraklar:v.duraklar,semboller:v.semboller}]))};
const sonuc = {};
b.tanismaGrubuGoruldu(sonuc,'2-1','kolay',1,2);
b.tanismaGrubuGoruldu(sonuc,'2-1','kolay',0,2);
b.tanitimGoruldu(sonuc,'2-1','orta');
const sonuclar = [[6,8],[4,8],[7,10],[8,10],[0,0]].map(([d,t],i)=>b.bolumSonucuIsle(sonuc,'2-1',['kolay','kolay','orta','orta','zor'][i],d,t));
console.log(JSON.stringify({kayitlar,konumlar,duraklar,yillar,cubuklar,sonuc,sonuclar}));
