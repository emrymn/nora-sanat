// Kaynak: sanat-atlasi js/gorsel.js (ELLE_ANAHTAR, cihazdakiElleOdaklar, elleOdakKoy) @ a866b86
import Foundation
import NoraCekirdek

/// Z2c-3: bu cihazda elle işaretlenen tablo odakları (görsel adı → [x, y] yüzde). Sitede localStorage
/// `sanat-atlasi:odak-elle`'deydi; site hâlâ yüklüyken bir kez buraya alınır (`sitedenAl`).
@MainActor
enum ElleOdaklar {
    private static let anahtar = "nora.odak.elle.v1"
    private static let alindi = "nora.odak.elle.sitedenAlindi"

    static var hepsi: [String: [Double]] {
        (UserDefaults.standard.dictionary(forKey: anahtar) as? [String: [Double]]) ?? [:]
    }

    /// `elleOdakKoy(g, odak)`: nil siler (otomatiğe dönülür)
    static func koy(_ ad: String, _ odak: [Double]?) {
        guard !ad.isEmpty else { return }
        var l = hepsi
        l[ad] = odak.map(OdakVerisi.elleOdak)
        UserDefaults.standard.set(l, forKey: anahtar)
    }

    static func sil() { UserDefaults.standard.removeObject(forKey: anahtar) }

    /// "Kopyala": `JSON.stringify({ surum: 1, odak })`
    static var metin: String {
        let odak = SiraliNesne(hepsi.sorted { $0.key < $1.key }.map { ($0.key, JSONDeger.dizi($0.value.map { .sayi($0) })) })
        return JSONDeger.nesne(SiraliNesne([("surum", .sayi(1)), ("odak", .nesne(odak))])).jsonMetni
    }

    /// Sitenin localStorage'ındakileri bir kez alır (site kalkmadan önce; cihazdakiler sitedekilerin önündedir)
    static func sitedenAl() async {
        guard !UserDefaults.standard.bool(forKey: alindi) else { return }
        guard let sonuc = try? await IlerlemeKoprusu.shared.benBetigi(
            "return localStorage.getItem('sanat-atlasi:odak-elle') || '{}';") as? String,
              let j = try? JSONDeger.coz(Data(sonuc.utf8)) else { return }
        var l = hepsi
        for c in j.nesne?.ciftler ?? [] where l[c.anahtar] == nil {
            if let d = c.deger.dizi?.compactMap(\.sayi), OdakVerisi.gecerli(d) { l[c.anahtar] = d }
        }
        UserDefaults.standard.set(l, forKey: anahtar)
        UserDefaults.standard.set(true, forKey: alindi)
    }
}
