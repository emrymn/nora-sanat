// Kaynak: sanat-atlasi js/gorsel.js @ a866b86 (site 1.90.3)
import Foundation

/// Bir görselin adresleri: yerel kopya (sitedeki gorseller/k 400 px), R2'deki 1280 px (b/) ve en büyük (d/) kopyalar,
/// yoksa Commons küçük resmi ya da müze IIIF adresi. Sitenin `gorselUrl`, `yerelUrl`, `ustKopya`, `devasaUrl`,
/// `gorselOrani`, `yuruyusAdresleri` kurallarıyla aynı. Dönen adresler mutlaktır (site köküne göre çözülür).
public struct GorselAdresleri: Sendable {
    public static let kaynakAdi: [String: String] = [
        "commons": "Wikimedia Commons", "met": "The Met", "aic": "Art Institute of Chicago",
        "cma": "Cleveland Museum of Art", "nga": "National Gallery of Art", "wikiart": "WikiArt",
        "rijks": "Rijksmuseum", "yuag": "Yale University Art Gallery", "smk": "SMK – Statens Museum for Kunst",
    ]
    /// Wikimedia'nın hazır küçük resim basamakları
    public static let adimlar = [330, 500, 960, 1280, 1920]

    public let kok: String
    /// "kaynak:kimlik" → yerel ad
    let yerel: [String: String]
    let buyukYerel: Set<String>
    let oranlar: [String: Double]
    // data/gorsel_kaynagi.json
    public let adres: String
    public let hepsiBuyuk: Bool
    let devasa: Set<String>
    let muze: [String: String]
    public let devasaBayt: Double
    let surumler: [String: String]
    let bSurumler: [String: String]

    /// - Parameters: dosyaların ayrıştırılmış hâli (yoksa nil): yerel_gorseller, gorsel_oranlari, gorsel_kaynagi
    public init(yerel y: JSONDeger? = nil, oranlar o: JSONDeger? = nil, kaynak k: JSONDeger? = nil,
                kok: URL = SiteVerisi.site) {
        self.kok = kok.absoluteString.hasSuffix("/") ? kok.absoluteString : kok.absoluteString + "/"
        // yerelGorselleriAyarla(yerelG && yerelG.gorseller, yerelG && yerelG.buyuk)
        var yerel: [String: String] = [:]
        for (a, v) in y?["gorseller"]?.nesne?.ciftler ?? [] { yerel[a] = v.jsMetni }
        self.yerel = yerel
        buyukYerel = Set((y?["buyuk"]?.dizi ?? []).map(\.jsMetni))
        var oranlar: [String: Double] = [:]
        for (a, v) in o?["oranlar"]?.nesne?.ciftler ?? [] { if let s = v.sayi { oranlar[a] = s } }
        self.oranlar = oranlar
        // uzakGorselleriAyarla
        var adres = ""
        if let a = k?["adres"]?.metin, a.hasPrefix("https://") {
            adres = a
            while adres.hasSuffix("/") { adres.removeLast() }
        }
        self.adres = adres
        let var_ = !adres.isEmpty
        hepsiBuyuk = var_ && k?["buyuk"] == .mantik(true)
        devasa = var_ ? Set((k?["devasa"]?.dizi ?? []).map(\.jsMetni)) : []
        var muze: [String: String] = [:]
        if var_ { for (a, m) in k?["muze"]?.nesne?.ciftler ?? [] { if let m = m.metin, Self.kaynakAdi[m] != nil, m != "wikiart" { muze[a] = m } } }
        self.muze = muze
        if var_, let b = k?["devasa_bayt"]?.sayi, b.isFinite, b > 0 { devasaBayt = b } else { devasaBayt = 0 }
        func surumOku(_ x: JSONDeger?) -> [String: String] {
            var s: [String: String] = [:]
            guard var_ else { return s }
            for (a, v) in x?.nesne?.ciftler ?? [] {
                let m = v.jsMetni
                if m.range(of: "^[0-9a-f]{4,16}$", options: .regularExpression) != nil { s[a] = m }
            }
            return s
        }
        surumler = surumOku(k?["surumler"])
        bSurumler = surumOku(k?["b_surumler"])
    }

    func tam(_ yol: String) -> String {
        yol.isEmpty || yol.hasPrefix("https://") || yol.hasPrefix("http://") ? yol : kok + yol
    }

    func devasaYolu(_ ad: String) -> String { "\(adres)/d/\(ad)\(surumler[ad].map { "-" + $0 } ?? "").jpg" }
    func buyukYolu(_ ad: String) -> String { "\(adres)/b/\(ad)\(bSurumler[ad].map { "-" + $0 } ?? "").jpg" }

    /// Görselin yerel adı (`gorselAdi`); yoksa nil
    public func yerelAd(_ g: Gorsel) -> String? { dolu(yerel[g.yerelAnahtar]) }

    /// `yerelUrl(g, genislik)`: yerel kopya yoksa ""
    public func yerelUrl(_ g: Gorsel, genislik: Int = 800) -> String {
        let a = g.yerelAnahtar
        guard let ad = dolu(yerel[a]) else { return "" }
        if genislik <= 400 { return tam("gorseller/k/\(ad).jpg") }
        if hepsiBuyuk { return buyukYolu(ad) }
        return tam(buyukYerel.contains(a) || buyukYerel.isEmpty ? "gorseller/b/\(ad).jpg" : "gorseller/\(ad).jpg")
    }

    /// `gorselUrl(g, genislik)`
    public func url(_ g: Gorsel, genislik: Int = 800) -> String {
        let y = yerelUrl(g, genislik: genislik)
        if !y.isEmpty { return y }
        switch g.k {
        case "commons":
            return Self.commonsKucuk(g.d, genislik: genislik)
        case "aic":
            return "https://www.artic.edu/iiif/2/\(g.i ?? "undefined")/full/\(genislik <= 400 ? 400 : 843),/0/default.jpg"
        case "nga":
            return "\(g.i ?? "undefined")/full/!\(genislik),\(genislik)/0/default.jpg"
        case "wikiart":
            let u = g.u ?? "undefined"
            guard genislik <= 400 else { return u }
            return u.replacingOccurrences(of: "!HalfHD\\.jpg$", with: "!Large.jpg", options: [.regularExpression, .caseInsensitive])
        default:
            return g.u ?? "undefined"
        }
    }

    /// `gorselYedek(g)`: birincil adres açılmazsa
    public func yedek(_ g: Gorsel) -> String {
        g.k == "commons" ? SiteYazisi.resimUrl(g.d, genislik: 800) : url(g, genislik: 800)
    }

    /// `commonsKucuk(dosya, genislik)`: upload.wikimedia.org küçük resmi
    public static func commonsKucuk(_ dosya: String?, genislik: Int) -> String {
        let ad = SiteYazisi.dosyaNormal(dosya)
        let h = SiteYazisi.md5(ad)
        var uz = ""
        if let r = ad.range(of: "\\.([a-zA-Z0-9]+)$", options: .regularExpression) { uz = String(ad[r].dropFirst()).lowercased() }
        let w = adimlar.first { $0 >= genislik } ?? adimlar[adimlar.count - 1]
        let on = ["tif", "tiff"].contains(uz) ? "lossy-page1-" : ["pdf", "djvu"].contains(uz) ? "page1-" : ""
        let ek = ["jpg", "jpeg", "png", "gif", "webp"].contains(uz) ? "" : uz == "svg" ? ".png" : ".jpg"
        let kod = SiteYazisi.uriBileseni(ad)
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/\(h.prefix(1))/\(h.prefix(2))/\(kod)/\(on)\(w)px-\(kod)\(ek)"
    }

    /// `devasaUrl(g)`: en büyük kopya; yoksa ""
    public func devasaUrl(_ g: Gorsel) -> String {
        guard let ad = yerelAd(g), devasa.contains(ad) else { return "" }
        return devasaYolu(ad)
    }

    /// `devasaKaynagi(g)`: en büyük kopya başka kaynaktan (müzeden) geldiyse o kaynağın adı
    public func devasaKaynagi(_ g: Gorsel) -> String {
        guard let ad = yerelAd(g), devasa.contains(ad), let m = muze[ad], m != g.k else { return "" }
        return Self.kaynakAdi[m] ?? ""
    }

    /// `gorselOrani(g)`: genişlik / yükseklik; bilinmiyorsa nil
    public func oran(_ g: Gorsel) -> Double? { yerelAd(g).flatMap { oranlar[$0] } }

    private static let ustKalip = try! NSRegularExpression(pattern: "(?:^|/)([kb])/([0-9a-f]{12,})(?:-[0-9a-f]{4,16})?\\.jpg(?:[?#]|$)")

    /// `ustKopya(src, { buyuk })`: 400 px → 1280 px; 1280 px → en büyük kopya (yalnız `buyuk` istenirse). Yoksa "".
    public func ustKopya(_ src: String, buyuk: Bool = false) -> String {
        let ns = src as NSString
        guard let m = Self.ustKalip.firstMatch(in: src, range: NSRange(location: 0, length: ns.length)) else { return "" }
        let tur = ns.substring(with: m.range(at: 1)), ad = ns.substring(with: m.range(at: 2))
        if tur == "k" { return hepsiBuyuk ? buyukYolu(ad) : tam("gorseller/b/\(ad).jpg") }
        return buyuk && devasa.contains(ad) ? devasaYolu(ad) : ""
    }

    /// `yuruyusAdresleri(ad, buyuk)`: Bugün yürüyüşünün görseli (data/yuruyus.json'daki adla)
    public func yuruyusAdresleri(ad: String, buyuk: String?) -> (kucuk: String, buyuk: String) {
        guard !adres.isEmpty else { return (tam("gorseller/k/\(ad).jpg"), "") }
        if let buyuk, !buyuk.isEmpty {
            let k = buyuk.hasSuffix(".jpg") ? String(buyuk.dropLast(4)) + "-1280.jpg" : buyuk
            return ("\(adres)/\(k)", "\(adres)/\(buyuk)")
        }
        return (hepsiBuyuk ? buyukYolu(ad) : tam("gorseller/k/\(ad).jpg"), devasa.contains(ad) ? devasaYolu(ad) : "")
    }

    /// `gorselSayfasi(g)`: kaynak sayfası (yalnız http(s))
    public func sayfa(_ g: Gorsel) -> String {
        let u = g.k == "commons" ? SiteYazisi.dosyaSayfasi(g.d) : (g.s ?? "")
        return u.lowercased().hasPrefix("http://") || u.lowercased().hasPrefix("https://") ? u : ""
    }

    /// `gorselKaynakYazisi(g)`
    public static func kaynakYazisi(_ g: Gorsel) -> String {
        if g.k == "wikiart" { return "Kaynak: WikiArt" }
        return (kaynakAdi[g.k] ?? g.k) + (dolu(g.l).map { " · " + $0 } ?? "")
    }

    // MARK: Eser düzeyi

    /// `secilenGorsel(eser, kotuler)`: kullanıcının reddetmediği ilk görsel
    public static func secilen(_ e: Eser, kotuler: [String: [String]] = [:]) -> Gorsel? {
        let red = Set(kotuler[e.anahtar] ?? [])
        return e.gorseller.first { !red.contains($0.anahtar) }
    }

    /// `pekistirmeyeUygunMu(eser, kotuler)`
    public static func pekistirmeyeUygun(_ e: Eser, kotuler: [String: [String]] = [:]) -> Bool {
        guard let g = secilen(e, kotuler: kotuler) else { return false }
        return e.pekistirme && !(g.p.map { $0 <= 5 } ?? false)
    }

    /// Adresi `URL`'ye çevirir (boşsa nil). Verideki kaçışsız karakterler kodlanır.
    public static func url(_ s: String) -> URL? {
        guard !s.isEmpty else { return nil }
        return URL(string: s) ?? s.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed.union(.urlQueryAllowed)).flatMap(URL.init(string:))
    }
}
