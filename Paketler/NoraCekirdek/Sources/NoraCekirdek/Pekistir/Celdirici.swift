// Kaynak: sanat-atlasi js/celdirici.js, js/turlar.js, js/ekranlar/pekistir.js @ a866b86
import Foundation

public enum Celdirici {
    public enum Zorluk { case kolay, orta, zor, karma }

    static func soyadi(_ s: Sanatci) -> String {
        let ad = dolu(s.adArama) ?? s.ad
        return ad.replacingOccurrences(of: #"\(.*?\)"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: ",.*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\b(the (elder|younger)|il (giovane|vecchio)|jr\.?|sr\.?)"#,
                                  with: " ", options: [.regularExpression, .caseInsensitive])
            .lowercased(with: Locale(identifier: "tr")).split(whereSeparator: \.isWhitespace).last.map(String.init) ?? ""
    }

    static func yasam(_ s: Sanatci, ortalar: [String: Double]) -> ClosedRange<Double>? {
        if let d = s.dogum {
            return Double(d)...Double(max(d, s.olum ?? (d + 60)))
        }
        if let o = s.olum { return Double(o - 60)...Double(o) }
        return ortalar[s.akim].map { ($0 - 30)...($0 + 30) }
    }

    public static func sanatciSecenekleri(_ hedef: Sanatci, sanatcilar: [Sanatci], akimlar: [Akim],
                                          acik: Set<String>, zorluk: Zorluk, ortak: [String], es: String? = nil,
                                          rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> [String] {
        func orta(_ a: ClosedRange<Double>?) -> Double {
            guard let a else { return 0 }
            return (a.lowerBound + a.upperBound) / 2
        }
        var yillar: [String: [Double]] = [:]
        for s in sanatcilar {
            if let a = yasam(s, ortalar: [:]) { yillar[s.akim, default: []].append(orta(a)) }
        }
        let ortalar = yillar.mapValues { $0.reduce(0, +) / Double($0.count) }
        let hedefYas = yasam(hedef, ortalar: ortalar)
        func yakin(_ s: Sanatci, _ pay: Double) -> Bool {
            guard let a = hedefYas, let b = yasam(s, ortalar: ortalar) else { return false }
            return b.lowerBound <= a.upperBound + pay && b.upperBound >= a.lowerBound - pay
        }
        let akim = akimlar.first { $0.ad == hedef.akim }
        let komsu = Set(akim?.komsular ?? [])
        let sira = Dictionary(akimlar.map { ($0.ad, $0.sira) }, uniquingKeysWith: { _, son in son })
        var secilen: [Sanatci] = []
        var kullanilan = Set(ortak + [hedef.id])
        var adlar = Set([hedef.ad])
        let hedefSoyadi = soyadi(hedef)
        var soyadlar = Set([hedefSoyadi])
        var gevsek = false
        func ekle(_ adaylar: [Sanatci], sinir: Int = 3, acikOnce: Bool = true) {
            let liste = acikOnce ? karistir(adaylar, rastgele) : adaylar
            let sirali = acikOnce ? liste.filter { acik.contains($0.id) } + liste.filter { !acik.contains($0.id) } : liste
            for s in sirali {
                if secilen.count >= sinir { break }
                let soy = soyadi(s)
                if kullanilan.contains(s.id) || adlar.contains(s.ad) || (gevsek ? soy == hedefSoyadi : soyadlar.contains(soy)) { continue }
                secilen.append(s)
                kullanilan.insert(s.id)
                adlar.insert(s.ad)
                soyadlar.insert(soy)
            }
        }
        let ayni = sanatcilar.filter { $0.akim == hedef.akim }
        let komsular = sanatcilar.filter { komsu.contains($0.akim) && yakin($0, 50) }
        if zorluk == .karma || zorluk == .kolay {
            if zorluk == .karma {
                ekle(ayni, sinir: 1)
                ekle(komsular, sinir: 1)
            }
            let uzak = sanatcilar.filter { s in
                guard let akim, let no = sira[s.akim] else { return false }
                return !komsu.contains(s.akim) && abs(no - akim.sira) >= 3
            }
            ekle(uzak)
            ekle(sanatcilar.filter { $0.akim != hedef.akim && !komsu.contains($0.akim) })
        } else if zorluk == .orta {
            ekle(komsular)
            ekle(sanatcilar.filter { $0.akim != hedef.akim && yakin($0, 100) })
        }
        func genel() {
            ekle(ayni)
            ekle(komsular)
            ekle(sanatcilar.filter { yakin($0, 100) })
            if secilen.count < 3 {
                let m = orta(hedefYas)
                ekle(sanatcilar.sorted {
                    abs(orta(yasam($0, ortalar: ortalar)) - m) < abs(orta(yasam($1, ortalar: ortalar)) - m)
                }, acikOnce: false)
            }
        }
        genel()
        if secilen.count < 3 { gevsek = true; genel() }
        var sonuc = karistir([hedef.id] + secilen.map(\.id), rastgele)
        if let es, !sonuc.contains(es), !ortak.contains(es), let s = sanatcilar.first(where: { $0.id == es }),
           s.ad != hedef.ad, soyadi(s) != hedefSoyadi {
            let yerler = sonuc.indices.filter { sonuc[$0] != hedef.id }
            if !yerler.isEmpty { sonuc[yerler[Int(rastgele() * Double(yerler.count))]] = es }
        }
        return sonuc
    }

    public static func akimSecenekleri(_ ad: String, akimlar: [Akim], kolay: Bool,
                                       rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> [String] {
        guard let hedef = akimlar.first(where: { $0.ad == ad }) else { return [ad] }
        let komsu = Set(hedef.komsular)
        let ilk = kolay ? akimlar.filter { !komsu.contains($0.ad) && abs($0.sira - hedef.sira) >= 3 }.map(\.ad)
                        : hedef.komsular
        var sonuc = [ad]
        for k in karistir(ilk, rastgele) where sonuc.count < 4 && !sonuc.contains(k) && akimlar.contains(where: { $0.ad == k }) {
            sonuc.append(k)
        }
        let yakin = akimlar.filter { !sonuc.contains($0.ad) }.sorted {
            (abs($0.sira - hedef.sira), $0.sira) < (abs($1.sira - hedef.sira), $1.sira)
        }
        sonuc += yakin.prefix(4 - sonuc.count).map(\.ad)
        return karistir(sonuc, rastgele)
    }
}
