// Kaynak: sanat-atlasi js/gorsel.js @ a866b86 (site 1.90.3)
// Bir eserin görsellerinin adresleri: sitenin yerel kopyaları (gorseller/k, 400 px), R2'deki 1280'lik (b/) ve en büyük
// (d/) kopyalar, yoksa kaynağın kendi adresi (Commons küçük resmi, IIIF, WikiArt, müze).
// Dönen adresler mutlaktır (site göreli adreslerini sitenin köküne göre çözer).
import Foundation

public struct GorselKaynagi: Sendable {
    public static let kaynakAdi: [String: String] = [
        "commons": "Wikimedia Commons",
        "met": "The Met",
        "aic": "Art Institute of Chicago",
        "cma": "Cleveland Museum of Art",
        "nga": "National Gallery of Art",
        "wikiart": "WikiArt",
        "rijks": "Rijksmuseum",
        "yuag": "Yale University Art Gallery",
        "smk": "SMK – Statens Museum for Kunst",
    ]

    /// Wikimedia'nın hazır küçük resim basamakları
    public static let adimlar = [330, 500, 960, 1280, 1920]

    /// Göreli adreslerin çözüldüğü kök ("https://sanat-atlasi.pages.dev/")
    public let site: String
    /// "kaynak:kimlik" → yerel ad (data/yerel_gorseller.json `gorseller`)
    let yerel: [String: String]
    /// 1280'lik kopyası depoda olanlar (eski biçim; `uzak.buyuk` yoksa)
    let buyukYerel: Set<String>
    /// yerel ad → genişlik/yükseklik (data/gorsel_oranlari.json)
    let oranlar: [String: Double]

    // data/gorsel_kaynagi.json (R2)
    let adres: String
    let hepsiBuyuk: Bool
    let devasa: Set<String>
    let muze: [String: String]
    /// En büyük kopyaların toplam boyu (bayt; bilinmiyorsa 0)
    public let devasaBayt: Int
    let surumler: [String: String]
    let bSurumler: [String: String]

    /// Ham dosyalardan (yoksa nil): yerel_gorseller, gorsel_oranlari, gorsel_kaynagi
    public init(yerelGorseller: Data?, oranlar: Data?, kaynak: Data?, site: URL = SiteVerisi.site) {
        self.site = site.absoluteString.hasSuffix("/") ? site.absoluteString : site.absoluteString + "/"

        let y = JSONNesne.sozluk(yerelGorseller)
        var yerel: [String: String] = [:]
        for (a, v) in JSONNesne.sozluk(y?["gorseller"]) ?? [:] { if let s = JSONNesne.metin(v) { yerel[a] = s } }
        self.yerel = yerel
        self.buyukYerel = Set(((y?["buyuk"] as? [Any]) ?? []).compactMap { $0 as? String })

        var o: [String: Double] = [:]
        for (a, v) in JSONNesne.sozluk(JSONNesne.sozluk(oranlar)?["oranlar"]) ?? [:] { if let n = JSONNesne.sayi(v) { o[a] = n } }
        self.oranlar = o

        let k = JSONNesne.sozluk(kaynak)
        var adres = (k?["adres"] as? String) ?? ""
        if !adres.hasPrefix("https://") { adres = "" }
        while adres.hasSuffix("/") { adres.removeLast() }
        self.adres = adres
        let var_ = !adres.isEmpty
        hepsiBuyuk = var_ && JSONNesne.dogru(k?["buyuk"])
        devasa = var_ ? Set(((k?["devasa"] as? [Any]) ?? []).compactMap { $0 as? String }) : []
        var m: [String: String] = [:]
        if var_ {
            for (ad, v) in JSONNesne.sozluk(k?["muze"]) ?? [:] {
                if let s = v as? String, Self.kaynakAdi[s] != nil, s != "wikiart" { m[ad] = s }
            }
        }
        muze = m
        devasaBayt = var_ ? (JSONNesne.sayi(k?["devasa_bayt"]).flatMap { $0 > 0 && $0.isFinite ? Int($0) : nil } ?? 0) : 0
        func surumOku(_ x: Any?) -> [String: String] {
            guard var_ else { return [:] }
            var o: [String: String] = [:]
            for (ad, v) in JSONNesne.sozluk(x) ?? [:] {
                let s = JSONNesne.jsMetni(v)
                if s.range(of: "^[0-9a-f]{4,16}$", options: .regularExpression) != nil { o[ad] = s }
            }
            return o
        }
        surumler = surumOku(k?["surumler"])
        bSurumler = surumOku(k?["b_surumler"])
    }

    /// R2 kovası biliniyor mu (data/gorsel_kaynagi.json indi ve geçerli)
    public var r2Var: Bool { !adres.isEmpty }

    /// Hiçbir dosya yokken (site de dosyalar inmezse böyle çalışır)
    public static let bos = GorselKaynagi(yerelGorseller: nil, oranlar: nil, kaynak: nil)

    // MARK: Anahtarlar

    /// `gorselAnahtari`: eserin "kötü görsel" kayıtlarında kullanılan anahtar
    public static func anahtar(_ g: Gorsel) -> String {
        g.k == "commons" ? "c:" + Yardimci.dosyaNormal(g.d).lowercased() : "\(g.k):\(JS.dolu(g.i) ?? JS.dolu(g.u) ?? "undefined")"
    }

    /// `yerelAnahtar`: yerel kopya listesindeki anahtar
    public static func yerelAnahtar(_ g: Gorsel) -> String {
        "\(g.k):\(JS.dolu(g.d) ?? JS.dolu(g.i) ?? JS.dolu(g.u) ?? "")"
    }

    /// Görselin yerel kopya adı (16 haneli onaltılık); yoksa nil
    public func yerelAd(_ g: Gorsel) -> String? { JS.dolu(yerel[Self.yerelAnahtar(g)]) }

    // MARK: Adresler

    func mutlak(_ u: String) -> String {
        if u.isEmpty { return "" }
        let k = u.lowercased()
        if k.hasPrefix("https:") || k.hasPrefix("http:") { return u }
        return site + u
    }

    func devasaYolu(_ ad: String) -> String { "\(adres)/d/\(ad)\(surumler[ad].map { "-\($0)" } ?? "").jpg" }
    func buyukYolu(_ ad: String) -> String { "\(adres)/b/\(ad)\(bSurumler[ad].map { "-\($0)" } ?? "").jpg" }

    /// `yerelUrl`: yerel kopyanın adresi; yoksa ""
    public func yerelUrl(_ g: Gorsel, genislik: Int = 800) -> String {
        let a = Self.yerelAnahtar(g)
        guard let ad = JS.dolu(yerel[a]) else { return "" }
        if genislik <= 400 { return mutlak("gorseller/k/\(ad).jpg") }
        if hepsiBuyuk { return buyukYolu(ad) }
        return mutlak(buyukYerel.contains(a) || buyukYerel.isEmpty ? "gorseller/b/\(ad).jpg" : "gorseller/\(ad).jpg")
    }

    /// `gorselUrl`: görselin `genislik` piksellik gösterimi için adresi; görsel yoksa ""
    public func adres(_ g: Gorsel?, genislik: Int = 800) -> String {
        guard let g else { return "" }
        let y = yerelUrl(g, genislik: genislik)
        if !y.isEmpty { return y }
        switch g.k {
        case "commons":
            return Self.commonsKucuk(g.d, genislik: genislik)
        case "aic":
            return "https://www.artic.edu/iiif/2/\(g.i ?? "undefined")/full/\(genislik <= 400 ? 400 : 843),/0/default.jpg"
        case "nga":
            return mutlak("\(g.i ?? "undefined")/full/!\(genislik),\(genislik)/0/default.jpg")
        case "wikiart":
            let u = g.u ?? "undefined"
            guard genislik <= 400 else { return mutlak(u) }
            return mutlak(u.replacingOccurrences(of: "!HalfHD\\.jpg$", with: "!Large.jpg",
                                                 options: [.regularExpression, .caseInsensitive]))
        default:
            return mutlak(g.u ?? "")
        }
    }

    /// `adres` URL olarak (geçersizse yüzde kodlanarak)
    public func url(_ g: Gorsel?, genislik: Int = 800) -> URL? { Self.url(adres(g, genislik: genislik)) }

    public static func url(_ s: String) -> URL? {
        guard !s.isEmpty else { return nil }
        return URL(string: s) ?? s.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed.union(.urlPathAllowed)).flatMap(URL.init(string:))
    }

    /// `gorselYedek`: birincil adres açılmazsa denenecek adres (Commons'ta Special:FilePath, öbürlerinde 800 px)
    public func yedek(_ g: Gorsel?) -> String {
        guard let g else { return "" }
        return g.k == "commons" ? Yardimci.resimUrl(g.d, genislik: 800) : adres(g, genislik: 800)
    }

    /// `commonsKucuk`: upload.wikimedia.org küçük resmi (hazır basamaklardan)
    public static func commonsKucuk(_ dosya: String?, genislik: Int) -> String {
        let ad = Yardimci.dosyaNormal(dosya)
        let h = MD5.onaltilik(ad)
        var uz = ""
        if let nokta = ad.lastIndex(of: ".") {
            let son = ad[ad.index(after: nokta)...]
            if !son.isEmpty, son.unicodeScalars.allSatisfy({ $0.isASCII && ($0.properties.isAlphabetic || ("0"..."9").contains($0)) }) {
                uz = son.lowercased()
            }
        }
        let w = adimlar.first { $0 >= genislik } ?? adimlar[adimlar.count - 1]
        let on = (uz == "tif" || uz == "tiff") ? "lossy-page1-" : (uz == "pdf" || uz == "djvu") ? "page1-" : ""
        let ek = ["jpg", "jpeg", "png", "gif", "webp"].contains(uz) ? "" : uz == "svg" ? ".png" : ".jpg"
        let kod = JS.encodeURIComponent(ad)
        let h0 = h.prefix(1), h01 = h.prefix(2)
        return "https://upload.wikimedia.org/wikipedia/commons/thumb/\(h0)/\(h01)/\(kod)/\(on)\(w)px-\(kod)\(ek)"
    }

    /// `devasaUrl`: en büyük kopyanın adresi (görüntüleyici); yoksa ""
    public func devasaUrl(_ g: Gorsel?) -> String {
        guard let g, let ad = yerelAd(g), devasa.contains(ad) else { return "" }
        return devasaYolu(ad)
    }

    /// `devasaKaynagi`: en büyük kopya başka kaynaktan (müzeden) geldiyse o kaynağın adı; yoksa ""
    public func devasaKaynagi(_ g: Gorsel?) -> String {
        guard let g, let ad = yerelAd(g), devasa.contains(ad), let m = muze[ad], m != g.k else { return "" }
        return Self.kaynakAdi[m] ?? ""
    }

    /// `gorselOrani`: genişlik / yükseklik; bilinmiyorsa nil
    public func oran(_ g: Gorsel?) -> Double? {
        guard let g, let ad = yerelAd(g) else { return nil }
        return oranlar[ad]
    }

    private static let ustKalip = try! NSRegularExpression(
        pattern: #"(?:^|/)([kb])/([0-9a-f]{12,})(?:-[0-9a-f]{4,16})?\.jpg(?:[?#]|$)"#)

    /// `ustKopya`: yerel kopyanın bir üst kopyası (400 → 1280; 1280 → en büyük, yalnız `buyuk` istenirse); yoksa ""
    public func ustKopya(_ src: String, buyuk: Bool = false) -> String {
        let ns = src as NSString
        guard let m = Self.ustKalip.firstMatch(in: src, range: NSRange(location: 0, length: ns.length)) else { return "" }
        let tur = ns.substring(with: m.range(at: 1)), ad = ns.substring(with: m.range(at: 2))
        if tur == "k" { return hepsiBuyuk ? buyukYolu(ad) : mutlak("gorseller/b/\(ad).jpg") }
        return buyuk && devasa.contains(ad) ? devasaYolu(ad) : ""
    }

    /// `yuruyusAdresleri`: Bugün yürüyüşünün görseli (`ad`: yerel ad, `buyuk`: kayıttaki ayrı kopya yolu)
    public func yuruyusAdresleri(ad: String?, buyuk: String?) -> (kucuk: String, buyuk: String) {
        let ad = ad ?? "undefined"
        if adres.isEmpty { return (mutlak("gorseller/k/\(ad).jpg"), "") }
        if let buyuk = JS.dolu(buyuk) {
            let kucuk = buyuk.hasSuffix(".jpg") ? String(buyuk.dropLast(4)) + "-1280.jpg" : buyuk
            return ("\(adres)/\(kucuk)", "\(adres)/\(buyuk)")
        }
        return (hepsiBuyuk ? buyukYolu(ad) : mutlak("gorseller/k/\(ad).jpg"), devasa.contains(ad) ? devasaYolu(ad) : "")
    }

    /// `gorselSayfasi`: kaynak sayfası (yalnız http(s)); yoksa ""
    public static func sayfa(_ g: Gorsel) -> String {
        let u = g.k == "commons" ? Yardimci.dosyaSayfasi(g.d) : (g.s ?? "")
        return u.range(of: "^https?://", options: [.regularExpression, .caseInsensitive]) != nil ? u : ""
    }

    /// `gorselKaynakYazisi`: "Wikimedia Commons · CC BY-SA 4.0"
    public static func kaynakYazisi(_ g: Gorsel) -> String {
        if g.k == "wikiart" { return "Kaynak: WikiArt" }
        return "\(JS.dolu(kaynakAdi[g.k]) ?? g.k)\(JS.dolu(g.l).map { " · " + $0 } ?? "")"
    }

    /// `secilenGorsel`: kullanıcının reddetmediği ilk (en iyi) görsel. `kotuler`: ilerlemedeki { eser anahtarı: [görsel anahtarı] }
    public static func secilen(_ e: Eser, kotuler: [String: [String]] = [:]) -> Gorsel? {
        let red = Set(kotuler[e.anahtar] ?? [])
        return e.gorseller.first { !red.contains(anahtar($0)) }
    }

    /// `pekistirmeyeUygunMu`
    public static func pekistirmeyeUygun(_ e: Eser, kotuler: [String: [String]] = [:]) -> Bool {
        guard let g = secilen(e, kotuler: kotuler), e.pekistirme else { return false }
        if let p = g.p, p <= 5 { return false }
        return true
    }
}

/// JSONSerialization sonuçlarını sitenin gevşek okumasıyla okumak için
enum JSONNesne {
    static func sozluk(_ veri: Data?) -> [String: Any]? {
        guard let veri else { return nil }
        return (try? JSONSerialization.jsonObject(with: veri)) as? [String: Any]
    }

    static func sozluk(_ x: Any?) -> [String: Any]? { x as? [String: Any] }

    static func metin(_ x: Any?) -> String? { x as? String }

    /// Sayı (JSONSerialization'ın NSNumber'ı ya da Swift sayısı)
    static func sayi(_ x: Any?) -> Double? {
        if x is String { return nil }
        if let d = x as? Double { return d }
        if let i = x as? Int { return Double(i) }
        if let n = x as? NSNumber { return n.doubleValue }
        return nil
    }

    static func tamSayi(_ x: Any?) -> Int? {
        guard let d = sayi(x), d.rounded() == d, abs(d) < 1e15 else { return nil }
        return Int(d)
    }

    /// `=== true`
    static func dogru(_ x: Any?) -> Bool { (x as? Bool) == true }

    /// JS doğruluğu (truthy)
    static func dogruMu(_ x: Any?) -> Bool {
        switch x {
        case nil, is NSNull: return false
        case let b as Bool: return b
        case let s as String: return !s.isEmpty
        case let n as NSNumber: return n.doubleValue != 0 && !n.doubleValue.isNaN
        default: return true
        }
    }

    /// `String(x)`
    static func jsMetni(_ x: Any?) -> String {
        switch x {
        case nil: return "undefined"
        case is NSNull: return "null"
        case let s as String: return s
        case let n as NSNumber: return JS.sayi(n.doubleValue)
        default: return "\(x!)"
        }
    }
}
