// Kaynak: sanat-atlasi js/eserler.js, js/bolum.js, js/ters.js @ a866b86
import Foundation

public enum KartEseri {
    static func havuz(_ eserler: [Eser], _ kotuler: [String: [String]]) -> [Eser] {
        Array(eserler.lazy.filter { GorselAdresleri.pekistirmeyeUygun($0, kotuler: kotuler) }.prefix(12))
    }

    public static func sec(_ eserler: [Eser], tur: PekistirmeTuru, seviye: Int, son: [String],
                           tanismadaGorulen: [String] = [], kolaylik: [String: Double] = [:],
                           isaretli: Set<String> = [], kotuler: [String: [String]] = [:],
                           rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> Eser? {
        var liste = havuz(eserler, kotuler)
        guard !liste.isEmpty else { return nil }
        var kacin = son + tanismadaGorulen
        var katmanli = false
        if case .bolum = tur, seviye < 2 {
            let sirali = Ogrenme.tanismaEserleri(liste, haric: nil, adet: liste.count) { kolaylik[$0.anahtar] }
            let bas = seviye == 1 && sirali.count > 5 ? 5 : 0
            liste = Array(sirali.dropFirst(bas).prefix(5))
            kacin = son
            katmanli = true
        }
        let sonlar = Set(kacin.suffix(min(5, max(0, liste.count - 1))))
        let adaylar = liste.filter { !sonlar.contains($0.anahtar) }
        if !adaylar.isEmpty { liste = adaylar }
        let zorluk = Seviye.eserSeviyesi(seviye)
        if !katmanli && (zorluk < 2 || zorluk > 3) {
            let puanli = liste.filter { kolaylik[$0.anahtar] != nil }.sorted {
                kolaylik[$0.anahtar]! > kolaylik[$1.anahtar]!
            }
            if puanli.count >= 2 {
                let yari = (puanli.count + 1) / 2
                liste = Array(zorluk < 2 ? puanli.prefix(yari) : puanli.suffix(yari))
            }
        }
        func agirlik(_ e: Eser) -> Double { isaretli.contains(e.anahtar) ? 2 : 1 }
        var pay = rastgele() * liste.reduce(0) { $0 + agirlik($1) }
        return liste.first { pay -= agirlik($0); return pay < 0 } ?? liste.last
    }

    public static func tersSorulur(_ tur: PekistirmeTuru, seviye: Int,
                                   rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> Bool {
        tur == .karisik && seviye >= 1 && rastgele() < 0.25
    }

    public typealias Secenek = (id: String, eser: Eser)

    public static func tersSecenekleri(dogru: Secenek, adaylar: [(id: String, eserler: [Eser])],
                                       kotuler: [String: [String]], konu: (Eser) -> String?,
                                       rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> [Secenek]? {
        var sonuc = [dogru]
        let dogruKonu = konu(dogru.eser)
        for aday in adaylar where !sonuc.contains(where: { $0.id == aday.id }) {
            var liste = havuz(aday.eserler, kotuler).filter { !$0.ortak.contains(dogru.id) }
            guard !liste.isEmpty else { continue }
            if let dogruKonu {
                let ayni = liste.filter { konu($0) == dogruKonu }
                if !ayni.isEmpty { liste = ayni }
            }
            sonuc.append((aday.id, liste[Int(rastgele() * Double(liste.count))]))
            if sonuc.count == 4 { return karistir(sonuc, rastgele) }
        }
        return nil
    }
}
