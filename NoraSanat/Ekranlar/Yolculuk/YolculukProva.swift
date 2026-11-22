// Kaynak: sanat-atlasi js/ekranlar/{harita,pekistir,zaman}.js @ a866b86
// CI karşılaştırması (G5): `-yolculukProva <ad>` aynı durumu solda sitede (`-yalnizSite`), sağda yerli ekranda kurar.
// Hazır olunca `tmp/yolculuk-hazir`'a adı yazar. İlerleme yerlide yalnız bellekte değişir; sitede en sonda
// `geri-yukle` eski kaydı geri koyar.
#if DEBUG && targetEnvironment(simulator)
import Foundation
import NoraCekirdek

@MainActor enum YolculukProva {
    static var ad: String? { NoraSanatApp.arguman("-yolculukProva") }

    /// `NoraSanatApp.init`: `-yalnizSite` açılışında sitenin kendi ekranını kurar
    static func siteyiHazirla() {
        guard ad != nil, CommandLine.arguments.contains("-yalnizSite") else { return }
        Task { await site() }
    }

    static let turlar = ["tanisma","soru","cevap","sergi","seviye-tamam","grup-sonu"]
    static func hazir(_ ad: String) {
        try? Data(ad.utf8).write(to: FileManager.default.temporaryDirectory.appendingPathComponent("yolculuk-hazir"), options: .atomic)
    }
    static func ornek(_ il: inout Ilerleme) {
        il.islenen = Array(1...57)
        let gecen = JSONDeger.nesne(.init(ciftler:[("kolay",.sayi(1)),("orta",.sayi(1))]))
        il[alan:"bolumler"] = .nesne(.init(ciftler:[("2-1",gecen),("2-2",gecen),("3-1",gecen),("4-1",.nesne(.init(ciftler:[("kolay",.sayi(0.5))])))]))
        il[alan:"haritaYolcu"] = .metin("4-1")
    }

    static func site() async {
        guard let ad else { return }
        do {
            _ = try await IlerlemeKoprusu.shared.oku()
            let sonuc = try await IlerlemeKoprusu.shared.benBetigi(betik,["ad":ad])
            if sonuc as? String == ad { hazir(ad) }
        } catch {
            let yol = FileManager.default.temporaryDirectory.appendingPathComponent("yolculuk-hata")
            try? Data(String(describing:error).utf8).write(to:yol)
        }
    }

    static let betik = #"""
    const o = await import('/js/ekranlar/ortak.js');
    const h = await import('/js/ekranlar/harita.js');
    const p = await import('/js/ekranlar/pekistir.js');
    const bekle = ms => new Promise(r=>setTimeout(r,ms));
    const bul = s => document.querySelector(s);
    const kadar = async f => {
        for(let n=0;n<200;n++){const v=f(); if(v) return v; await bekle(100);}
        throw Error('G5: '+ad+' beklenen ekrana ulaşamadı');
    };
    const anahtar='nora-g5-ci-yedek';
    if(ad==='geri-yukle'){
        if(localStorage.getItem(anahtar)) {
            o.d.ilerleme=JSON.parse(localStorage.getItem(anahtar));
            o.kaydet(); localStorage.removeItem(anahtar);
        }
        return ad;
    }
    if(!localStorage.getItem(anahtar)) localStorage.setItem(anahtar,JSON.stringify(o.d.ilerleme));
    o.d.ilerleme=JSON.parse(localStorage.getItem(anahtar));
    if(['durak','tanisma','soru','cevap','sergi','seviye-tamam','grup-sonu'].includes(ad)){
        o.d.ilerleme.islenen=Array.from({length:57},(_,i)=>i+1);
        o.d.ilerleme.bolumler=Object.fromEntries(['2-1','2-2','3-1'].map(id=>[id,{kolay:1,orta:1}]));
        o.d.ilerleme.bolumler['4-1']={kolay:.5}; o.d.ilerleme.haritaYolcu='4-1';
    }
    if(ad==='zaman'){
        (await import('/js/ekranlar/zaman.js')).zamanSayfasi();
        await kadar(()=>bul('[data-test="zaman-grup"]')); return ad;
    }
    await h.haritaSayfasi();
    if(ad==='harita'){await kadar(()=>bul('.harita-resim')?.complete);return ad;}
    if(ad==='kurs'){bul('[data-kurs-rozet]').click();await kadar(()=>bul('[data-test="kurs-pencere"]'));return ad;}
    if(ad==='motif'){bul('[data-motif]').click();await kadar(()=>bul('[data-test="harita-motif-pencere"]'));return ad;}
    if(ad==='kilit'||ad==='durak'){
        bul(ad==='kilit'?'[data-bolum][data-acik="false"]':'[data-bolum="4-1"]').click();
        await kadar(()=>bul('.hp2'));return ad;
    }
    const grup=ad==='tanisma'||ad==='grup-sonu';
    await p.pekistir('bolum','4-1/'+(grup?'tanitim-1':'kolay'),{yeni:true,onayli:true});
    for(let n=0;n<700;n++){
        const tanis=bul('[data-konu-tanisma-gec]');
        if(ad==='tanisma' && tanis) return ad;
        if(ad==='soru' && bul('[data-bilmiyorum]'))return ad;
        if(ad==='cevap' && bul('[data-test="sonuc"]'))return ad;
        if(ad==='grup-sonu' && bul('[data-test="grup-ozet"]'))return ad;
        if((ad==='sergi'||ad==='seviye-tamam') && bul('[data-test="bolum-ozet"]')){
            if(ad==='seviye-tamam') bul('[data-test="seviye-tamam"]').scrollIntoView({block:'start'});
            else window.scrollTo(0,0);
            return ad;
        }
        const kart=o.d.oturum?.kart;
        const sec=kart && bul('[data-sanatci="'+CSS.escape(kart.id)+'"]:not(:disabled)');
        const dugme=tanis||bul('[data-sonraki]')||bul('[data-ikinci]')||sec;
        if(dugme) dugme.click();
        else if(kart?.ters && bul('[data-ters-eser]')){
            const i=kart.ters.findIndex(x=>x.id===kart.id); bul('[data-ters-eser="'+i+'"]')?.click();
        }
        await bekle(90);
    }
    throw Error('G5: '+ad+' adım sınırı');
    """#
}
#endif
