// Kaynak: sanat-atlasi js/eserler.js, js/resim.js, js/birlesme.js @ a866b86 (site 1.90.3)
import Foundation

/// Bir sanatçının eser listesini sitenin gördüğü gibi çıkaran kurallar: kopya kayıtlar (İş 101), çıkarılan görseller
/// (İş 117), elle düzeltmeler ve ortak atıflar (İş 174), şüpheli yıl (İş 143), Türkçe adlar.
public struct EserKurallari: Sendable {
    /// sanatçı → [(sil, kalan)] (data/kopya_eserler.json)
    let kopyalar: [String: [(sil: String, kalan: String)]]
    /// data/cikarilan_gorseller.json
    let cikarilan: Set<String>
    // data/eser_duzeltmeleri.json
    let cikar: [String: Set<String>]
    let gorselCikar: [String: [String: Set<String>]]
    let muze: [String: String]
    let tarih: [String: (yil: Int, tarih: String)]
    /// qid → sanatçılar (birden çok sanatçının listesinde olan eserler)
    let ortaklar: [String: [String]]
    /// sanatçı id → ad (künyede "Ayrıca atfedilir")
    let ortakAdlari: [String: String]
    /// Türkçe eser adları: QID ya da "sanatçıId|başlık"
    public let adlar: [String: String]

    init(kopya: JSONDeger?, cikarilan c: JSONDeger?, duzeltme j: JSONDeger?, adlar a: JSONDeger?,
         onbellek: [(sid: String, eserler: [JSONDeger])], sanatciAdlari: [String: String]) {
        // kopyalariAyarla
        var kopyalar: [String: [(String, String)]] = [:]
        for (sid, l) in kopya?["sanatcilar"]?.nesne?.ciftler ?? [] {
            guard let l = l.dizi else { continue }
            kopyalar[sid] = l.compactMap { c in
                guard c.nesne != nil else { return nil }
                return (c["sil"]?.jsMetni ?? "undefined", c["kalan"]?.jsMetni ?? "undefined")
            }
        }
        self.kopyalar = kopyalar
        // cikarilanlariAyarla
        cikarilan = Set((c?["anahtarlar"]?.dizi ?? []).map { $0.jsMetni.precomposedStringWithCanonicalMapping })
        // duzeltmeleriAyarla
        var cikar: [String: Set<String>] = [:]
        for (sid, l) in j?["cikar"]?.nesne?.ciftler ?? [] {
            if let l = l.dizi { cikar[sid] = Set(l.compactMap { $0["qid"]?.doluMetin }) }
        }
        var gc: [String: [String: Set<String>]] = [:]
        for (sid, kayitlar) in j?["gorsel_cikar"]?.nesne?.ciftler ?? [] {
            guard let k = kayitlar.nesne else { continue }
            var m: [String: Set<String>] = [:]
            for (q, l) in k.ciftler {
                if let l = l.dizi {
                    m[q] = Set(l.map { SiteYazisi.dosyaNormal($0.jsMetni).lowercased().precomposedStringWithCanonicalMapping })
                }
            }
            gc[sid] = m
        }
        self.cikar = cikar
        gorselCikar = gc
        var muze: [String: String] = [:]
        for (q, v) in j?["muze"]?.nesne?.ciftler ?? [] { muze[q] = v.dogru ? v.jsMetni : "" }
        self.muze = muze
        var tarih: [String: (Int, String)] = [:]
        for (q, t) in j?["tarih"]?.nesne?.ciftler ?? [] {
            if let y = t["yil"]?.tamSayi { tarih[q] = (y, (t["tarih"]?.dogru ?? false) ? t["tarih"]!.jsMetni : String(y)) }
        }
        self.tarih = tarih
        // ortakAtiflariAyarla (önbellekteki sanatçı sırasıyla)
        var m: [String: [String]] = [:]
        for (sid, eserler) in onbellek {
            for e in eserler {
                guard let q = e["qid"]?.doluMetin, !(cikar[sid]?.contains(q) ?? false) else { continue }
                if !(m[q]?.contains(sid) ?? false) { m[q, default: []].append(sid) }
            }
        }
        ortaklar = m.filter { $0.value.count > 1 }
        ortakAdlari = sanatciAdlari
        // adlariAl
        var adlar: [String: String] = [:]
        for (k, v) in a?["adlar"]?.nesne?.ciftler ?? [] {
            if let s = v.metin?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { adlar[k] = s }
        }
        self.adlar = adlar
    }

    /// `kopyalariAyikla`
    func kopyalariAyikla(_ sid: String, _ liste: [Eser]) -> [Eser] {
        guard let ciftler = kopyalar[sid], !ciftler.isEmpty else { return liste }
        var liste = liste
        var yer: [String: Int] = [:]
        for (i, e) in liste.enumerated() { yer[e.anahtar] = i }
        var silinecek = Set<String>()
        for c in ciftler {
            guard let si = yer[c.sil], let ki = yer[c.kalan], si != ki, !silinecek.contains(c.kalan) else { continue }
            silinecek.insert(c.sil)
            let sil = liste[si]
            if sil.kaynak == "kurs" && liste[ki].kaynak != "kurs" {
                liste[ki].kaynak = "kurs"
                liste[ki].kaynaklar = ["kurs"] + liste[ki].kaynaklar.filter { $0 != "kurs" }
                liste[ki].kursKonu = liste[ki].kursKonu ?? sil.kursKonu
                liste[ki].baslik = sil.baslik
            }
            liste[ki].sl = max(liste[ki].sl, sil.sl)
        }
        return silinecek.isEmpty ? liste : liste.filter { !silinecek.contains($0.anahtar) }
    }

    /// `cikarilanlariAyikla`
    func cikarilanlariAyikla(_ liste: [Eser]) -> [Eser] {
        guard !cikarilan.isEmpty else { return liste }
        return liste.compactMap { e in
            let g = e.gorseller.filter { !cikarilan.contains($0.cikarAnahtari) }
            guard !g.isEmpty else { return nil }
            var y = e
            y.gorseller = g
            return y
        }
    }

    /// `duzeltmeleriUygula`
    func duzeltmeleriUygula(_ sid: String, _ liste: [Eser]) -> [Eser] {
        let c = cikar[sid]
        let gc = gorselCikar[sid]
        return liste.compactMap { e in
            if let q = e.qid, c?.contains(q) ?? false { return nil }
            var y = e
            if let q = e.qid, let atilan = gc?[q] {
                y.gorseller = e.gorseller.filter { !($0.k == "commons" && atilan.contains($0.cikarAnahtari)) }
                if y.gorseller.isEmpty { return nil }
            }
            if let q = e.qid, let m = muze[q] { y.muze = m }
            if let q = e.qid, let t = tarih[q] { y.yil = t.yil; y.tarih = t.tarih }
            return y
        }
    }

    /// `ortakSanatcilar(eser, sanatciId)`
    public func ortakSanatcilar(_ e: Eser, _ sid: String) -> [String] {
        guard let q = e.qid, let l = ortaklar[q] else { return [] }
        return l.filter { $0 != sid }
    }

    /// `eserAdiBul`
    public func eserAdi(_ sid: String, _ e: Eser) -> String {
        dolu(e.qid.flatMap { adlar[$0] }) ?? dolu(adlar["\(sid)|\(e.baslik)"]) ?? ""
    }

    /// `yilSupheliMi`: ölümünden 2 yıldan sonra ya da 12 yaşından önce
    public static func yilSupheli(_ yil: Int?, _ s: Sanatci?) -> Bool {
        guard let yil, let s else { return false }
        return (s.olum.map { yil > $0 + 2 } ?? false) || (s.dogum.map { yil < $0 + 12 } ?? false)
    }

    /// `sanatciEserleri` içindeki son işlem: süzme sırası ve eklenen alanlar
    func isle(_ s: Sanatci, _ ham: [Eser]) -> [Eser] {
        var l = kopyalariAyikla(s.id, duzeltmeleriUygula(s.id, cikarilanlariAyikla(ham)))
        for i in l.indices {
            l[i].sid = s.id
            let o = ortakSanatcilar(l[i], s.id)
            if !o.isEmpty { l[i].ortak = o; l[i].ortakAdlar = o.map { ortakAdlari[$0] ?? $0 } }
            if Self.yilSupheli(l[i].yil, s) && l[i].tarih == SiteYazisi.tarihYaz(l[i].yil) { l[i].yil = nil; l[i].tarih = "" }
            let ad = eserAdi(s.id, l[i])
            if !ad.isEmpty && ad != l[i].baslik { l[i].ad = ad }
        }
        return l
    }
}

// MARK: - Görünür sanatçılar ve akımlar (js/resim.js, js/birlesme.js)

public enum Birlesme {
    /// `BIRLESEN_AKIMLAR`
    public static let akimlar = ["Uluslararası Gotik": "Gotik"]
    public static func akimAdi(_ ad: String) -> String { akimlar[ad] ?? ad }

    /// `sanatcilariBirlestir`
    static func sanatcilar(_ l: [Sanatci]) -> [Sanatci] {
        l.map { s in
            guard let h = akimlar[s.akim] else { return s }
            var y = s
            y.birlesen = s.akim
            y.akim = h
            return y
        }
    }

    /// `akimlariBirlestir`
    static func akimlar(_ l: [Akim]) -> [Akim] {
        l.filter { akimlar[$0.ad] == nil }.map { a in
            var y = a
            var gorulen = Set<String>()
            y.komsular = a.komsular.map(akimAdi).filter { gorulen.insert($0).inserted && $0 != a.ad }
            return y
        }
    }
}

/// js/resim.js: yalnızca iki boyutlu resimsel eserler
struct ResimSuzgeci: Sendable {
    /// küçük harfli Commons dosyası → karar (data/eser_turleri.json kurs)
    let kurs: [String: String]?
    /// ana uğraşı resim olmayanlar
    let anaUgrasDisi: Set<String>

    init(_ t: JSONDeger?) {
        if let k = t?["kurs"]?.nesne {
            var m: [String: String] = [:]
            for (a, v) in k.ciftler where v.dogru { m[a] = v["karar"]?.jsMetni ?? "undefined" }
            kurs = m
        } else { kurs = nil }
        anaUgrasDisi = Set((t?["ana_ugras_disi"]?.nesne?.ciftler ?? []).filter { $0.deger.dogru }.map(\.anahtar))
    }

    /// `kursEseriResimMi`
    func resimMi(_ e: KursEseri) -> Bool {
        guard let karar = kurs?[SiteYazisi.dosyaNormal(e.commonsDosya).lowercased()] else { return true }
        return karar == "resim"
    }

    /// `kursResimleri`
    func kursResimleri(_ s: Sanatci) -> [KursEseri] { s.kursEserleri.filter(resimMi) }

    /// `resimSanatcisiMi(sanatci, turler, onbellek)`; onbellek: sanatçı → ham eser sayısı (dosya yoksa nil)
    func resimSanatcisi(_ s: Sanatci, onbellek: [String: Int]?) -> Bool {
        if anaUgrasDisi.contains(s.id) { return false }
        if !kursResimleri(s).isEmpty { return true }
        guard let onbellek, let n = onbellek[s.id] else { return s.kursEserleri.isEmpty }
        return n > 0
    }
}
