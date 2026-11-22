// Kaynak: sanat-atlasi js/kamera.js (gorusAlani, durusa, kameraYolu, egri, KAMERA_EGRI, kameraKareleri),
// js/ekranlar/ders.js (gorAdimi, gorKare, gorHedef, gorIleri, ogrenAdimi, ogrenCiz, ogrenIleri, ayirtAdimi, ayirtCiz,
// ayirtSec, adimUst, adimSonu, SON_YAZI), js/tasarim.js (roma) @ a866b86
// Dersin adım ekranlarının (Gör, Öğren, Ayırt et) arayüzden bağımsız kuralları. Kâhin: Testler/kahin/ders_adimlari.mjs.
import Foundation

// MARK: - Gör kamerası (js/kamera.js)

/// Bir kamera duruşu: resmin sol üst köşesinin ekrandaki yeri ve ölçek (transform-origin 0 0)
public struct KameraDurusu: Equatable, Sendable, Codable {
    public var tx: Double
    public var ty: Double
    public var s: Double

    public init(tx: Double, ty: Double, s: Double) {
        self.tx = tx
        self.ty = ty
        self.s = s
    }
}

/// Görüş alanı: bakılan noktanın resimdeki yeri (ux, uy) ve görünen genişlik (w, resim pikseliyle)
public struct GorusAlani: Equatable, Sendable {
    public var ux: Double
    public var uy: Double
    public var w: Double
}

/// İki duruş arasındaki yumuşak yol (van Wijk ve Nuij; d3 `interpolateZoom` ile aynı formül)
public struct KameraYolu: Sendable {
    public let a: KameraDurusu
    public let b: KameraDurusu
    /// Süre (ms): yolun uzunluğuna göre 750…1900
    public let sure: Int
    /// |S|: yolun uzunluğu (0.002'den kısaysa kamera hiç yürümez)
    public let uzunluk: Double
    private let ornekle: @Sendable (Double) -> KameraDurusu

    init(a: KameraDurusu, b: KameraDurusu, sure: Int, uzunluk: Double, ornekle: @escaping @Sendable (Double) -> KameraDurusu) {
        self.a = a
        self.b = b
        self.sure = sure
        self.uzunluk = uzunluk
        self.ornekle = ornekle
    }

    /// t (0…1) → duruş; uç noktalar tam
    public func ornek(_ t: Double) -> KameraDurusu {
        t <= 0 ? a : t >= 1 ? b : ornekle(t)
    }
}

public enum DersKamerasi {
    /// Geri çekilmenin derinliği (d3'te √2)
    public static let rho = 1.15

    public static func gorusAlani(_ p: KameraDurusu, W: Double, orta: Double) -> GorusAlani {
        GorusAlani(ux: (W / 2 - p.tx) / p.s, uy: (orta - p.ty) / p.s, w: W / p.s)
    }

    public static func durusa(_ g: GorusAlani, W: Double, orta: Double) -> KameraDurusu {
        let s = W / g.w
        return KameraDurusu(tx: W / 2 - g.ux * s, ty: orta - g.uy * s, s: s)
    }

    /// `kameraYolu(a, b, W, orta)`
    public static func kameraYolu(_ a: KameraDurusu, _ b: KameraDurusu, W: Double, orta: Double) -> KameraYolu {
        let g0 = gorusAlani(a, W: W, orta: orta)
        let g1 = gorusAlani(b, W: W, orta: orta)
        let dx = g1.ux - g0.ux
        let dy = g1.uy - g0.uy
        let d2 = dx * dx + dy * dy
        let r2 = rho * rho
        let S: Double
        let ornek: @Sendable (Double) -> KameraDurusu
        if d2 < 1e-6 * max(1, g0.w * g0.w) {
            // aynı noktada yalnız yakınlaşma ya da uzaklaşma
            S = log(g1.w / g0.w) / rho
            ornek = { t in
                durusa(GorusAlani(ux: g0.ux + t * dx, uy: g0.uy + t * dy, w: g0.w * exp(rho * t * S)), W: W, orta: orta)
            }
        } else {
            let d1 = d2.squareRoot()
            let b0 = (g1.w * g1.w - g0.w * g0.w + r2 * r2 * d2) / (2 * g0.w * r2 * d1)
            let b1 = (g1.w * g1.w - g0.w * g0.w - r2 * r2 * d2) / (2 * g1.w * r2 * d1)
            let k0 = log((b0 * b0 + 1).squareRoot() - b0)
            let k1 = log((b1 * b1 + 1).squareRoot() - b1)
            S = (k1 - k0) / rho
            let ch0 = cosh(k0)
            let sh0 = sinh(k0)
            ornek = { t in
                let s = t * S
                let u = (g0.w / (r2 * d1)) * (ch0 * tanh(rho * s + k0) - sh0)
                return durusa(
                    GorusAlani(ux: g0.ux + u * dx, uy: g0.uy + u * dy, w: (g0.w * ch0) / cosh(rho * s + k0)),
                    W: W, orta: orta
                )
            }
        }
        let sure = Int(jsYuvarla(min(1900, max(750, 520 + abs(S) * 520))))
        return KameraYolu(a: a, b: b, sure: sure, uzunluk: abs(S), ornekle: ornek)
    }

    /// CSS `cubic-bezier(x1, y1, x2, y2)` eğrisi (zaman → ilerleme)
    public static func egri(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> @Sendable (Double) -> Double {
        let bx: @Sendable (Double) -> Double = { t in ((1 - 3 * x2 + 3 * x1) * t + (3 * x2 - 6 * x1)) * t * t + 3 * x1 * t }
        let by: @Sendable (Double) -> Double = { t in ((1 - 3 * y2 + 3 * y1) * t + (3 * y2 - 6 * y1)) * t * t + 3 * y1 * t }
        let dbx: @Sendable (Double) -> Double = { t in 3 * (1 - 3 * x2 + 3 * x1) * t * t + 2 * (3 * x2 - 6 * x1) * t + 3 * x1 }
        return { x in
            if x <= 0 { return 0 }
            if x >= 1 { return 1 }
            var t = x
            for _ in 0..<8 {
                let e = bx(t) - x
                if abs(e) < 1e-6 { break }
                let d = dbx(t)
                if abs(d) < 1e-6 { break }
                t -= e / d
            }
            // Newton kaçarsa ikiye bölme
            if !(t >= 0 && t <= 1) || abs(bx(t) - x) > 1e-4 {
                var lo = 0.0
                var hi = 1.0
                t = x
                for _ in 0..<30 {
                    if bx(t) < x { lo = t } else { hi = t }
                    t = (lo + hi) / 2
                }
            }
            return by(t)
        }
    }

    /// Kameranın eğrisi: yavaş kalkış, uzun ve yumuşak iniş (`KAMERA_EGRI`)
    public static let kameraEgrisi = egri(0.45, 0.05, 0.2, 1)

    /// `kameraKareleri(yol, adet)`: eğriyle dağıtılmış duruşlar (ofset 0…1)
    public static func kameraKareleri(_ yol: KameraYolu, adet: Int = 40) -> [(ofset: Double, durus: KameraDurusu)] {
        (0...adet).map { i in
            let o = Double(i) / Double(adet)
            return (o, yol.ornek(kameraEgrisi(o)))
        }
    }

    /// `gorHedef(kok)`: ayrıntı (ya da resmin tamamı) üst çubukla panel arasındaki alana oturur; resim o alanı hep kaplar.
    /// - W: sahnenin genişliği; ust: üst çubuğun altı + 8; alt: panelin üstü − 8 (sahneye göre)
    /// - resim: resmin doğal boyu; nokta: ayrıntının kesirli dikdörtgeni (nil: resmin tamamı)
    public static func hedef(
        W: Double,
        ust: Double,
        alt: Double,
        resim: (w: Double, h: Double),
        nokta: (x: Double, y: Double, w: Double, h: Double)?
    ) -> (p: KameraDurusu, orta: Double, olcek: Double) {
        let IW = resim.w
        let IH = resim.h
        let alanH = max(120, alt - ust)
        let sigdir = min(W / IW, alanH / IH)
        let s: Double
        let cx: Double
        let cy: Double
        if let n = nokta {
            // ayrıntı alanın %88'ine sığar; resmin tamamından daha uzak olmaz, 6 kattan fazla yaklaşmaz
            s = min(sigdir * 6, max(sigdir, min((W * 0.88) / (n.w * IW), (alanH * 0.88) / (n.h * IH))))
            cx = (n.x + n.w / 2) * IW
            cy = (n.y + n.h / 2) * IH
        } else {
            s = sigdir
            cx = IW / 2
            cy = IH / 2
        }
        func sinirla(_ v: Double, _ en: Double, _ enCok: Double) -> Double {
            en > enCok ? (en + enCok) / 2 : min(enCok, max(en, v))
        }
        let tx = sinirla(W / 2 - cx * s, W - IW * s, 0)
        let ty = sinirla((ust + alt) / 2 - cy * s, alt - IH * s, ust)
        return (KameraDurusu(tx: tx, ty: ty, s: s), (ust + alt) / 2, s / sigdir)
    }

    /// JS `Math.round`: .5 yukarı
    static func jsYuvarla(_ x: Double) -> Double { (x + 0.5).rounded(.down) }
}

// MARK: - Gör adımı

/// Yürüyüşün bir ayrıntısı (data/yuruyus.json `noktalar[]`)
public struct GorNoktasi: Equatable, Sendable, Codable {
    public var ad: String
    public var metin: String
    public var x: Double
    public var y: Double
    public var w: Double
    public var h: Double
}

/// Gör'de yürünen bir eser: yürüyüş kaydı (`{ sanatci, kayit }`)
public struct GorEseri: Equatable, Sendable, Identifiable {
    public var id: String { sanatci }
    public var sanatci: String
    /// Kaydın özgün eser adı (`kayit.eser`)
    public var eser: String
    public var qid: String?
    /// Yıl yazısı (`kayit.yil`; yoksa "")
    public var yil: String
    /// Görselin yerel adı (`kayit.gorsel`) ve varsa en büyük kopya (`kayit.buyuk`)
    public var gorsel: String
    public var buyuk: String?
    public var noktalar: [GorNoktasi]
}

/// Gör'ün bir karesi: eserin tamamı (`ni == -1`) ya da bir ayrıntısı
public struct GorKaresi: Equatable, Sendable, Codable {
    /// eserin sırası
    public var ei: Int
    /// ayrıntının sırası; -1: eserin tamamı
    public var ni: Int
    /// ayrıntının bütün Gör içindeki sırası (1'den); eserin tamamında bir önceki ayrıntınınki
    public var sira: Int
}

/// Gör karesinin yazıları (`gorKare` → `yaz`)
public struct GorYazilari: Equatable, Sendable {
    /// `[data-gor-eser]`: üst satır (sanatçı · eser · yıl · eser 1 / 3)
    public var eser: String
    /// `[data-gor-baslik]`
    public var baslik: String
    /// `[data-gor-metin]`
    public var metin: String
    /// `[data-gor-noktalar]` aria-label
    public var noktalar: String
    /// İleri düğmesi
    public var ileri: String
    /// Geri düğmesi gizli mi (ilk kare)
    public var geriGizli: Bool
}

public enum DersAdimKurallari {
    /// `gorPlani` ile aynı süzme, ama ekranın gerektirdiği bütün kayıtla: yürüyüşü yazılmış ilk `adet` eser.
    public static func gorEserleri(ders: JSONDeger?, yuruyus: JSONDeger?, adet: Int = CalisDersKurallari.gorEserSiniri) -> [GorEseri] {
        let yuruyusEserler = yuruyus?["eserler"] ?? yuruyus
        var eserler: [GorEseri] = []
        for g in ders?["gor"]?.dizi ?? [] {
            guard let sid = g["sanatci"]?.metin,
                  let gEser = g["eser"]?.metin,
                  let kayit = yuruyusEserler?[sid],
                  kayit["eser"]?.metin == gEser,
                  let ham = kayit["noktalar"]?.dizi,
                  !ham.isEmpty else { continue }
            let noktalar = ham.map { n in
                GorNoktasi(
                    ad: n["ad"]?.metin ?? "",
                    metin: n["metin"]?.metin ?? "",
                    x: n["x"]?.sayi ?? 0,
                    y: n["y"]?.sayi ?? 0,
                    w: n["w"]?.sayi ?? 1,
                    h: n["h"]?.sayi ?? 1
                )
            }
            let yil: String
            switch kayit["yil"] {
            case .sayi(let x)?: yil = x == x.rounded() ? String(Int(x)) : String(x)
            case .metin(let m)?: yil = m
            default: yil = ""
            }
            eserler.append(GorEseri(
                sanatci: sid,
                eser: gEser,
                qid: kayit["qid"]?.doluMetin,
                yil: yil,
                gorsel: kayit["gorsel"]?.metin ?? "",
                buyuk: kayit["buyuk"]?.doluMetin,
                noktalar: noktalar
            ))
            if eserler.count >= adet { break }
        }
        return eserler
    }

    /// Kareler: her eser için önce giriş (resmin tamamı), sonra ayrıntıları
    public static func gorKareleri(_ noktaSayilari: [Int]) -> [GorKaresi] {
        var kareler: [GorKaresi] = []
        var sayac = 0
        for (ei, n) in noktaSayilari.enumerated() {
            kareler.append(GorKaresi(ei: ei, ni: -1, sira: sayac))
            for ni in 0..<n {
                sayac += 1
                kareler.append(GorKaresi(ei: ei, ni: ni, sira: sayac))
            }
        }
        return kareler
    }

    /// Gör'ün açıldığı kare: sıradaki ayrıntı; eserin ilk ayrıntısındaysa önce eserin tamamı
    public static func gorBaslangici(_ kareler: [GorKaresi], i: Double, toplam: Int) -> Int {
        let kalinan = CalisDersKurallari.kalinanYer(i: i, toplam: toplam)
        var konum = kareler.firstIndex { $0.ni >= 0 && $0.sira == kalinan + 1 } ?? -1
        if konum > 0 && kareler[konum].ni == 0 { konum -= 1 }
        return max(0, konum)
    }

    /// Kayıtlı oranın karşılığı görülen ayrıntı / madde / ikili sayısı (`Math.round(i * toplam)`)
    public static func gorulen(i: Double, toplam: Int) -> Int {
        Int(DersKamerasi.jsYuvarla(i * Double(toplam)))
    }

    /// `gorKare` yazıları. `kisaAd`: sanatçının kısa adı; `eserAdi`: `yuruyusEserAdi(sid, kayit)`.
    public static func gorYazilari(
        eserler: [GorEseri],
        kareler: [GorKaresi],
        konum: Int,
        kisaAd: String,
        eserAdi: String
    ) -> GorYazilari {
        let k = kareler[konum]
        let es = eserler[k.ei]
        let n = k.ni >= 0 ? es.noktalar[k.ni] : nil
        let adet = es.noktalar.count
        let tamAd = [kisaAd, eserAdi, es.yil].filter { !$0.isEmpty }.joined(separator: " · ")
        let ustSatir = n != nil ? tamAd : [kisaAd, es.yil].filter { !$0.isEmpty }.joined(separator: " · ")
        let eserNo = eserler.count > 1 ? " · eser \(k.ei + 1) / \(eserler.count)" : ""
        let son = konum == kareler.count - 1
        let eserSonu = !son && kareler[konum + 1].ei != k.ei
        let ileri = son ? "Gör’ü bitir" : n == nil ? "Ayrıntılara bak" : eserSonu ? "Sıradaki eser" : "Sonraki ayrıntı"
        return GorYazilari(
            eser: ustSatir + eserNo,
            baslik: n?.ad ?? eserAdi,
            metin: n?.metin ?? "Önce resmin bütününe bak. Sonra \(adet) ayrıntıya tek tek yaklaşacağız.",
            noktalar: n != nil ? "Ayrıntı \(k.ni + 1) / \(adet)" : "\(adet) ayrıntı",
            ileri: ileri,
            geriGizli: konum == 0
        )
    }

    /// `yuruyusEserAdi(sid, kayit)`: Türkçe adı (QID ya da "sanatçı|başlık"), yoksa kaydın özgün adı
    public static func yuruyusEserAdi(_ es: GorEseri, katalog: SiteKatalogu) -> String {
        let e = Eser(anahtar: "", kaynak: "", kaynaklar: [], baslik: es.eser, tarih: "", yil: nil, muze: "", kursKonu: nil,
                     qid: es.qid, gorseller: [], pekistirme: false, sl: 0)
        let ad = katalog.kurallar.eserAdi(es.sanatci, e)
        return JSMetin.kirp(ad.isEmpty ? es.eser : ad)
    }

    /// Sanatçının kısa adı (`kisaAd(id)` → `bilinenAd(s.ad, d.kisaAdlar[id])`); bilinmeyen sanatçıda ""
    public static func kisaAd(_ sid: String, katalog: SiteKatalogu) -> String {
        katalog.bilinenAd(sid) ?? ""
    }

    /// Eserin tam adı (görselin erişilebilirlik adı): `[kisaAd, yuruyusEserAdi, yıl]`
    public static func gorEserAdi(_ es: GorEseri, kisaAd: String, eserAdi: String) -> String {
        [kisaAd, eserAdi, es.yil].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// `gorIleri`: ayrıntı karesinde ilk kez ilerleniyorsa yeni görülen sayısı (yazılacak), yoksa nil
    public static func gorIlerle(_ kare: GorKaresi, gorulen: Int) -> Int? {
        kare.ni >= 0 && kare.sira > gorulen ? kare.sira : nil
    }

    // MARK: - Öğren / Ayırt et

    /// `roma(n)` (js/tasarim.js)
    public static func roma(_ n: Int) -> String {
        String(repeating: "X", count: n / 10) + ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"][n % 10]
    }

    /// Öğren'in başlığı: `Öğren · I / VII`
    public static func ogrenBasligi(konum: Int, toplam: Int) -> String {
        "Öğren · \(roma(konum + 1)) / \(roma(toplam))"
    }

    /// Öğren'in ileri düğmesi
    public static func ogrenIleri(konum: Int, toplam: Int) -> String {
        konum >= toplam - 1 ? "Anladım · Öğren’i bitir" : "Anladım · \(roma(konum + 2)). özellik"
    }

    /// Öğren ve Ayırt et'te ilk kez ilerleniyorsa yeni görülen sayısı (`konum + 1 > gorulen`)
    public static func ilerle(konum: Int, gorulen: Int) -> Int? {
        konum + 1 > gorulen ? konum + 1 : nil
    }

    /// Kanıtın altyazısı: `[kısa ad, eser başlığı (bulunamadıysa kaynaktaki ad), yıl]`
    public static func kanitAltyazisi(kisaAd: String, kanitEseri: String, eser: Eser?) -> String {
        [kisaAd, eser?.gorunenAd ?? kanitEseri, eser?.tarih ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Ayırt et'in başlığı: `Ayırt et · 1 / 3`
    public static func ayirtBasligi(konum: Int, toplam: Int) -> String {
        "Ayırt et · \(konum + 1) / \(toplam)"
    }

    public static func ayirtSorusu(_ akim: String) -> String { "Hangisi \(akim)?" }

    public static func ayirtAltYazisi(_ c: AyirtIkilisi) -> String {
        "Komşu dönem: \(c.komsu)\(c.acik ? "" : " (henüz açılmadı)")"
    }

    public static func ayirtSonucu(dogru: Bool) -> String {
        dogru ? "Doğru · farkı gör" : "Öbürüydü · farkı gör"
    }

    public static func ayirtIleri(konum: Int, toplam: Int) -> String {
        konum >= toplam - 1 ? "Ayırt et’i bitir" : "Sonraki ikili"
    }

    /// Karşılaştırma cümlesinin kaynağı: `Dönem metni · <kaynağın son parçası>`
    public static func cumleKaynagi(_ kaynak: String?) -> String {
        let son = (kaynak ?? "undefined").components(separatedBy: "·").last ?? ""
        return "Dönem metni · \(JSMetin.kirp(son))"
    }

    // MARK: - Adımın üstü ve sonu

    /// `adimUst` etiketi: `Gotik dersi · 2. adım` (adımlar: dersin adımları; Gör'ü olmayan derste Gör açılırsa üç adım)
    public static func ustEtiketi(akim: String, adim: DersAdimi, adimlar: [DersAdimi]) -> String {
        let sira = (adimlar.firstIndex(of: adim) ?? -1) + 1
        return "\(akim) dersi · \(sira). adım"
    }

    /// `SON_YAZI[adim](b)`
    public static func sonYazisi(_ adim: DersAdimi, gorEser: Int, gorToplam: Int, ogren: Int, ayirt: Int) -> String {
        switch adim {
        case .gor: return "\(gorEser) eserde \(gorToplam) ayrıntıya baktın."
        case .ogren: return "\(ogren) özelliğin hepsini gördün."
        case .ayirt: return "\(ayirt) komşu dönemle yan yana baktın."
        }
    }

    /// `adimSonu`: bittikten sonra önerilen adım (önce bu adımdan sonraki bitmemişler, sonra baştakiler); ders
    /// bittiyse nil
    public static func sonrakiAdim(_ adim: DersAdimi, adimlar: [DersAdimi], durum: DersDurumu) -> DersAdimi? {
        guard !durum.bitti else { return nil }
        let i = adimlar.firstIndex(of: adim) ?? -1
        let sonra = adimlar[(i + 1)...].first { a in !(durum.adimlar.first { $0.adim == a }?.bitti ?? false) }
        return sonra ?? durum.siradaki
    }

    /// Ders bitince adım sonunda ve ders sayfasında görünen cümle
    public static func dersBittiYazisi(akim: String, kilit: String) -> String {
        kilit.isEmpty ? "Ders tamam. Haritada \(akim) durakları seni bekliyor; sınavın orada." : "Ders tamam. Haritadaki durakları: \(kilit)"
    }
}
