// Kaynak: sanat-atlasi js/koleksiyon.js @ a866b86
import Foundation

/// Kullanıcının işaretlediği eser (`ilerleme.koleksiyon` öğesi: `{ a: eserAnahtarı, s: sanatçıId, t: "YYYY-MM-DD" }`).
public struct KoleksiyonKaydi: Equatable, Hashable, Sendable, Codable {
    public var a: String
    public var s: String
    public var t: String

    public init(a: String, s: String, t: String = "") {
        self.a = a
        self.s = s
        self.t = t
    }

    init?(json j: JSONDeger) {
        guard let a = j["a"]?.metin,
              let s = j["s"]?.metin else { return nil }
        self.init(a: a, s: s, t: j["t"]?.metin ?? "")
    }

    public var json: JSONDeger {
        .nesne([
            ("a", .metin(a)),
            ("s", .metin(s)),
            ("t", .metin(t)),
        ])
    }
}

/// Koleksiyonum kuralları (`js/koleksiyon.js`).
public enum KoleksiyonKurallari {
    /// `KOLEKSIYON_SINIRI`
    public static let sinir = 500

    /// `koleksiyonDogrula(k)`: tekrarlar ve bozuk kayıtlar atılır, sınır korunur
    public static func dogrula(_ k: JSONDeger?) -> [KoleksiyonKaydi] {
        guard let dizi = k?.dizi else { return [] }
        var goruldu = Set<String>()
        var sonuc: [KoleksiyonKaydi] = []
        for x in dizi {
            guard let kayit = KoleksiyonKaydi(json: x),
                  !goruldu.contains(kayit.a) else { continue }
            goruldu.insert(kayit.a)
            sonuc.append(kayit)
            if sonuc.count >= sinir { break }
        }
        return sonuc
    }

    /// `koleksiyondaMi(ilerleme, eser)`
    public static func koleksiyondaMi(_ ilerleme: Ilerleme, eser: Eser?) -> Bool {
        guard let eser else { return false }
        let k = ilerleme[alan: "koleksiyon"]?.dizi ?? []
        return k.contains { $0["a"]?.metin == eser.anahtar }
    }

    /// `koleksiyonDegistir(ilerleme, eser, tarih)`: eseri ekler ya da çıkarır; yeni durumu (koleksiyonda mı) döndürür.
    /// Sanatçısı bilinmeyen eser (`eser.sid` boş) eklenmez.
    @discardableResult
    public static func degistir(_ ilerleme: inout Ilerleme, eser: Eser?, tarih: String) -> Bool {
        guard let eser, !eser.sid.isEmpty else { return false }
        // Site listeyi süzmeden değiştirir (yalnız ekler ya da çıkarır); süzme `dogrula`'da, kayıt okunurken
        var k = ilerleme[alan: "koleksiyon"]?.dizi ?? []
        if let i = k.firstIndex(where: { $0["a"]?.metin == eser.anahtar }) {
            k.remove(at: i)
            ilerleme[alan: "koleksiyon"] = .dizi(k)
            return false
        }
        k.insert(KoleksiyonKaydi(a: eser.anahtar, s: eser.sid, t: tarih).json, at: 0)
        if k.count > sinir { k = Array(k.prefix(sinir)) }
        ilerleme[alan: "koleksiyon"] = .dizi(k)
        return true
    }

}
