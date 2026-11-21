// Kaynak: sanat-atlasi js/tanimaKirpim.js @ a866b86
import Foundation

public struct TanimaKirpimi: Sendable {
    public let anahtar, sanatci, gorsel, ad: String
    public let x, y, w, h: Double
    public let madde: Int?

    init?(_ j: JSONDeger) {
        func yazi(_ alan: String) -> String? {
            guard let s = j[alan]?.metin, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return s
        }
        guard let a = yazi("anahtar"), let s = yazi("sanatci"), let g = yazi("gorsel"), let ad = yazi("ad"),
              let x = j["x"]?.sayi, let y = j["y"]?.sayi, let w = j["w"]?.sayi, let h = j["h"]?.sayi,
              [x,y,w,h].allSatisfy({ (0...1).contains($0) }), w >= 0.02, h >= 0.02,
              x+w <= 1.0001, y+h <= 1.0001 else { return nil }
        self.anahtar = a; self.sanatci = s; self.gorsel = g; self.ad = ad
        self.x = x; self.y = y; self.w = w; self.h = h
        self.madde = j["madde"]?.tamSayi
    }

    public static func oku(_ veri: JSONDeger?, konu: Bool) -> [String: [TanimaKirpimi]] {
        guard let bolum = veri?[konu ? "konular" : "sanatcilar"]?.nesne else { return [:] }
        var sonuc: [String: [TanimaKirpimi]] = [:]
        for id in bolum.anahtarlar {
            var liste = (bolum[id]?.dizi ?? []).compactMap(TanimaKirpimi.init)
            if konu {
                var maddeler = Set<Int>()
                liste = liste.filter { k in
                    guard let i = k.madde, i >= 0 else { return false }
                    return maddeler.insert(i).inserted
                }.sorted { ($0.madde ?? 0) < ($1.madde ?? 0) }
            }
            if !liste.isEmpty { sonuc[id] = liste }
        }
        return sonuc
    }

    public func eser(_ liste: [Eser], katalog: SiteKatalogu, il: Ilerleme) -> Eser? {
        guard let e = liste.first(where: { AyrintiKurallari.ayrintiAnahtari($0) == anahtar && ($0.sid.isEmpty || $0.sid == sanatci) }),
              let g = GorselAdresleri.secilen(e, kotuler: il.kotuGorseller) ?? e.gorseller.first,
              katalog.gorsel.yerelAd(g) == gorsel else { return nil }
        return e
    }
}
