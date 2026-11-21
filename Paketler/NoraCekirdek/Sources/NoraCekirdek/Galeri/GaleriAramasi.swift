// Kaynak: sanat-atlasi js/arama.js ve js/ekranlar/arama.js @ a866b86
import Foundation

public struct GaleriKaydi: Identifiable, Sendable {
    public enum Tur: String, CaseIterable, Sendable { case sanatci, eser, konu, basyapit }
    public let tur: Tur
    public let anahtar: String
    public let baslik: String
    public let sanatci: String?
    let metin: String
    let agirlik: Int
    public var id: String { tur.rawValue + "|" + (sanatci ?? "") + "|" + anahtar }

    public init(_ tur: Tur, _ anahtar: String, _ baslik: String, alanlar: [String?], agirlik: Int = 0, sanatci: String? = nil) {
        self.tur = tur
        self.anahtar = anahtar
        self.baslik = baslik
        self.sanatci = sanatci
        self.agirlik = agirlik
        self.metin = GaleriAramasi.normallestir(alanlar.compactMap { $0 }.joined(separator: " "))
    }
}

public enum GaleriAramasi {
    public static func normallestir(_ s: String) -> String {
        s.lowercased(with: Locale(identifier: "tr")).replacingOccurrences(of: "ı", with: "i")
            .decomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "[\\u0300-\\u036f]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "ß", with: "ss")
            .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    public static func ara(_ dizin: [GaleriKaydi], sorgu: String) -> [GaleriKaydi] {
        let aranan = normallestir(sorgu)
        let kelimeler = aranan.split(separator: " ")
        guard kelimeler.joined().count >= 2 else { return [] }
        let eslesen: [(GaleriKaydi, Int)] = dizin.compactMap { kayit in
            let parcalar = kayit.metin.split(separator: " ")
            var puan = 0
            for k in kelimeler {
                if parcalar.contains(k) { puan += 3 }
                else if parcalar.contains(where: { $0.hasPrefix(k) }) { puan += 2 }
                else if k.count >= 3 && kayit.metin.contains(k) { puan += 1 }
                else { return nil }
            }
            if kayit.metin == aranan { puan += 5 }
            else if kayit.metin.hasPrefix(aranan) { puan += 2 }
            return (kayit, puan)
        }
        return eslesen.sorted { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            if a.0.agirlik != b.0.agirlik { return a.0.agirlik > b.0.agirlik }
            return a.0.metin.compare(b.0.metin, locale: Locale(identifier: "en_US")) == .orderedAscending
        }.map { $0.0 }
    }
}
