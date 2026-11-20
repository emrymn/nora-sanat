// Kaynak: sanat-atlasi js/bildirim.js @ 28f751ed
import Foundation

/// "Bu görsel hatalı" bildirimi (`ilerleme.bildirimler` öğesi: `{ a, s, baslik, neden, g, t }`).
public struct BildirimKaydi: Equatable, Hashable, Sendable, Codable {
    public var a: String
    public var s: String
    public var baslik: String
    public var neden: String
    public var g: String
    public var t: String

    public init(a: String, s: String, baslik: String, neden: String, g: String = "", t: String = "") {
        self.a = a
        self.s = s
        self.baslik = baslik
        self.neden = neden
        self.g = g
        self.t = t
    }

    init?(json j: JSONDeger) {
        guard let a = j["a"]?.metin,
              let s = j["s"]?.metin,
              let neden = j["neden"]?.metin,
              BildirimKurallari.nedenler.contains(neden) else { return nil }
        let baslik = j["baslik"]?.metin ?? ""
        self.init(
            a: a,
            s: s,
            baslik: baslik,
            neden: neden,
            g: j["g"]?.metin ?? "",
            t: j["t"]?.metin ?? ""
        )
    }

    public var json: JSONDeger {
        .nesne([
            ("a", .metin(a)),
            ("s", .metin(s)),
            ("baslik", .metin(baslik)),
            ("neden", .metin(neden)),
            ("g", .metin(g)),
            ("t", .metin(t)),
        ])
    }
}

/// Görsel bildirimi kuralları (`js/bildirim.js`).
public enum BildirimKurallari {
    /// `NEDENLER`
    public static let nedenler = ["Yanlış sanatçı", "Heykel/mimari", "Kötü görsel", "Yanlış ad"]
    /// `SINIR`
    public static let sinir = 300

    /// `bildirimlerDogrula(b)`
    public static func dogrula(_ b: JSONDeger?) -> [BildirimKaydi] {
        guard let dizi = b?.dizi else { return [] }
        return Array(dizi.compactMap(BildirimKaydi.init(json:)).prefix(sinir))
    }

    /// `eseriBildir(ilerleme, eser, gorsel, neden, tarih)`: bildirimi kaydeder ve eseri/görseli `kotuGorseller`'e ekler.
    /// - "Kötü görsel": yalnızca gösterilen görsel çıkar; eserin başka görseli varsa eser kalır.
    /// - Diğer nedenler: eserin bütün görselleri çıkar.
    /// Döndürür: bildirimden sonra seçilen görsel (kalmadıysa nil).
    @discardableResult
    public static func eseriBildir(
        _ ilerleme: inout Ilerleme,
        eser: Eser?,
        gorsel: Gorsel? = nil,
        neden: String,
        tarih: String
    ) -> Gorsel? {
        var kotuler = ilerleme.kotuGorseller
        guard let eser, nedenler.contains(neden) else {
            return eser.flatMap { GorselAdresleri.secilen($0, kotuler: kotuler) }
        }
        let g = gorsel ?? GorselAdresleri.secilen(eser, kotuler: kotuler) ?? eser.gorseller.first
        let gAnahtar = g?.anahtar ?? ""
        var liste = kotuler[eser.anahtar] ?? []
        let eklenecekler: [Gorsel] = neden == "Kötü görsel" ? (g.map { [$0] } ?? []) : eser.gorseller
        for x in eklenecekler {
            let a = x.anahtar
            if !liste.contains(a) {
                liste.append(a)
            }
        }
        kotuler[eser.anahtar] = liste
        ilerleme.kotuGorseller = kotuler

        var b = dogrula(ilerleme[alan: "bildirimler"])
        if let i = b.firstIndex(where: { $0.a == eser.anahtar && $0.neden == neden && $0.g == gAnahtar }) {
            b.remove(at: i)
        }
        b.insert(
            BildirimKaydi(a: eser.anahtar, s: eser.sid, baslik: eser.baslik, neden: neden, g: gAnahtar, t: tarih),
            at: 0
        )
        if b.count > sinir {
            b = Array(b.prefix(sinir))
        }
        ilerleme[alan: "bildirimler"] = .dizi(b.map(\.json))
        return GorselAdresleri.secilen(eser, kotuler: kotuler)
    }

    /// `kotuIsaretle(eser, gorsel, kotuler)` (`js/gorsel.js`): görseli "kötü" işaretler; sıradaki görseli döndürür.
    @discardableResult
    public static func kotuIsaretle(eser: Eser, gorsel: Gorsel, kotuler: inout [String: [String]]) -> Gorsel? {
        let a = gorsel.anahtar
        var liste = kotuler[eser.anahtar] ?? []
        if !liste.contains(a) {
            liste.append(a)
        }
        kotuler[eser.anahtar] = liste
        return GorselAdresleri.secilen(eser, kotuler: kotuler)
    }
}
