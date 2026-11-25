// Z4a · "Dinleyerek bak" doğal sesi: Gemini TTS ("Fola") ile önceden kaydedilen anlatım parçaları.
// Kaynak ve sözleşme: sanat-atlasi scripts/ses_uret.py (PR #238; betiğin başındaki "Sözleşme"), data/ses_dizini.json.
//   metin   = noktala(re.sub(r'\s+', ' ', unicodedata.normalize('NFC', parça)))
//   anahtar = sha1(metin, UTF-8) onaltılık, ilk 16 hane
//   ses     = <R2>/<klasor>/<anahtar>.mp3, zamanlama = <R2>/<klasor>/<anahtar>.json
import Foundation

/// Bir anlatım parçasının kayıt anahtarı (`ses_uret.py` `duzgun` + `anahtar`).
public enum SesAnahtari {
    /// Python `str.isspace()`'in boşlukları (`re` `\s` bunlarla eşleşir): U+2028, NBSP, ince boşluklar dahil.
    static let bosluklar: Set<UInt32> = [
        0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x85, 0xA0, 0x1680,
        0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006, 0x2007, 0x2008, 0x2009, 0x200A,
        0x2028, 0x2029, 0x202F, 0x205F, 0x3000,
    ]

    public static func bosluk(_ s: Unicode.Scalar) -> Bool { bosluklar.contains(s.value) }

    /// `duzgun(s)`: NFC, boşluk dizileri tek boşluk, kırpılmış, sonunda noktalama yoksa ".".
    public static func metin(_ s: String) -> String {
        var sonuc = String.UnicodeScalarView()
        var bosta = false
        for c in s.precomposedStringWithCanonicalMapping.unicodeScalars {
            if bosluk(c) {
                bosta = true
            } else {
                if bosta, !sonuc.isEmpty { sonuc.append(" ") }
                bosta = false
                sonuc.append(c)
            }
        }
        return DinlemeKurallari.noktala(String(sonuc))
    }

    /// `anahtar(metin)`: SHA-1'in ilk 16 onaltılık hanesi. `metin` zaten `metin(_:)`'den geçmiş olmalı.
    public static func anahtar(_ metin: String) -> String {
        String(SHA1.ozet(Array(metin.utf8)).map { String(format: "%02x", $0) }.joined().prefix(16))
    }

    /// Ham parçanın anahtarı (önce düzgünleştirilir); boş metinde nil.
    public static func parcaAnahtari(_ ham: String) -> String? {
        let m = metin(ham)
        return m.isEmpty ? nil : anahtar(m)
    }
}

/// Saf Swift SHA-1 (yalnız Foundation; Linux'ta CryptoKit yok). Güvenlik için değil, betiğin dosya adlarıyla eşleşmek için.
enum SHA1 {
    static func ozet(_ girdi: [UInt8]) -> [UInt8] {
        var h: [UInt32] = [0x6745_2301, 0xEFCD_AB89, 0x98BA_DCFE, 0x1032_5476, 0xC3D2_E1F0]
        var m = girdi
        let bitUzunluk = UInt64(girdi.count) &* 8
        m.append(0x80)
        while m.count % 64 != 56 { m.append(0) }
        for i in (0..<8).reversed() { m.append(UInt8((bitUzunluk >> (UInt64(i) * 8)) & 0xFF)) }
        func dondur(_ x: UInt32, _ n: UInt32) -> UInt32 { (x << n) | (x >> (32 - n)) }
        var w = [UInt32](repeating: 0, count: 80)
        for blok in stride(from: 0, to: m.count, by: 64) {
            for i in 0..<16 {
                let j = blok + i * 4
                w[i] = UInt32(m[j]) << 24 | UInt32(m[j + 1]) << 16 | UInt32(m[j + 2]) << 8 | UInt32(m[j + 3])
            }
            for i in 16..<80 { w[i] = dondur(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1) }
            var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4]
            for i in 0..<80 {
                let f: UInt32, k: UInt32
                switch i {
                case 0..<20: f = (b & c) | (~b & d); k = 0x5A82_7999
                case 20..<40: f = b ^ c ^ d; k = 0x6ED9_EBA1
                case 40..<60: f = (b & c) | (b & d) | (c & d); k = 0x8F1B_BCDC
                default: f = b ^ c ^ d; k = 0xCA62_C1D6
                }
                let t = dondur(a, 5) &+ f &+ e &+ k &+ w[i]
                e = d; d = c; c = dondur(b, 30); b = a; a = t
            }
            h[0] = h[0] &+ a; h[1] = h[1] &+ b; h[2] = h[2] &+ c; h[3] = h[3] &+ d; h[4] = h[4] &+ e
        }
        return h.flatMap { v in (0..<4).map { UInt8((v >> (24 - UInt32($0) * 8)) & 0xFF) } }
    }
}

/// `data/ses_dizini.json`: kaydı olan parçalar ve gerçek süreleri.
public struct SesDizini: Equatable, Sendable {
    public var model: String
    public var ses: String
    /// R2'deki klasör ("ses/Fola")
    public var klasor: String
    /// anahtar → süre (sn)
    public var parcalar: [String: Double]

    public init(model: String = "", ses: String, klasor: String, parcalar: [String: Double]) {
        self.model = model; self.ses = ses; self.klasor = klasor; self.parcalar = parcalar
    }

    public init?(json: JSONDeger?) {
        guard let j = json, let p = j["parcalar"]?.nesne else { return nil }
        let ses = j["ses"]?.metin ?? ""
        var klasor = j["klasor"]?.metin ?? (ses.isEmpty ? "" : "ses/\(ses)")
        while klasor.hasSuffix("/") { klasor.removeLast() }
        while klasor.hasPrefix("/") { klasor.removeFirst() }
        guard !klasor.isEmpty else { return nil }
        var parcalar: [String: Double] = [:]
        for (k, v) in p.ciftler { if let s = v.sayi, s > 0 { parcalar[k] = s } }
        self.init(model: j["model"]?.metin ?? "", ses: ses, klasor: klasor, parcalar: parcalar)
    }

    public init?(veri: Data?) {
        guard let d = veri, let j = try? JSONDeger.coz(d) else { return nil }
        self.init(json: j)
    }

    /// Ham parçanın kaydı varsa anahtarı
    public func anahtar(_ ham: String) -> String? {
        guard let a = SesAnahtari.parcaAnahtari(ham), parcalar[a] != nil else { return nil }
        return a
    }

    /// Ham parçanın kaydı varsa gerçek süresi (sn)
    public func sure(_ ham: String) -> Double? { anahtar(ham).flatMap { parcalar[$0] } }

    /// Ses ve zamanlama adresleri. `kok`: görsellerin R2 adresi (`gorsel_kaynagi.json` `adres`).
    public func adresler(_ anahtar: String, kok: String) -> (mp3: URL, json: URL)? {
        var k = kok
        while k.hasSuffix("/") { k.removeLast() }
        guard k.hasPrefix("https://"),
              let mp3 = URL(string: "\(k)/\(klasor)/\(anahtar).mp3"),
              let json = URL(string: "\(k)/\(klasor)/\(anahtar).json") else { return nil }
        return (mp3, json)
    }
}

/// Bir parçanın kelime zamanlaması (`<anahtar>.json`) ya da kaydı olmayan metin için tahmini akış.
/// Harf konumları metnin Unicode kod noktası indisleridir (Python `str` indisi); burada `unicodeScalars` ile çevrilir.
public struct AltyaziAkisi: Equatable, Sendable {
    public struct Kelime: Equatable, Sendable {
        /// Kelimenin söylenmeye başladığı an (sn)
        public var bas: Double
        /// Kod noktası aralığı
        public var harf: Range<Int>
        /// Aynı aralık UTF-16 biriminde (`AVSpeechSynthesizer`'ın verdiği `NSRange` için)
        public var utf16: Range<Int>
        public var yazi: String
    }

    public var metin: String
    public var sure: Double
    public var kelimeler: [Kelime]

    /// `<anahtar>.json` → akış. Zamanlama bozuksa (konumlar metnin dışında) nil.
    public init?(json: JSONDeger?) {
        guard let j = json, let metin = j["metin"]?.metin, let liste = j["kelimeler"]?.dizi else { return nil }
        let sk = Array(metin.unicodeScalars)
        var kelimeler: [Kelime] = []
        for k in liste {
            guard let u = k.dizi, u.count >= 3, let bas = u[0].sayi, let a = u[1].sayi, let b = u[2].sayi else {
                return nil
            }
            let ia = Int(a), ib = Int(b)
            guard ia >= 0, ib > ia, ib <= sk.count else { return nil }
            kelimeler.append(Self.kelime(sk, ia..<ib, bas: bas))
        }
        self.metin = metin
        self.sure = j["sure"]?.sayi ?? (kelimeler.last?.bas ?? 0)
        self.kelimeler = kelimeler
    }

    public init?(veri: Data?) {
        guard let d = veri, let j = try? JSONDeger.coz(d) else { return nil }
        self.init(json: j)
    }

    /// Kaydı olmayan metin: süre kelimelere `ses_uret.py` `kelime_zamanlari`'nın kuralıyla paylaştırılır
    /// (harf sayısı + 1,5; cümle sonu +6, virgül +3; baştaki 0,12 ve sondaki 0,25 sn sessizlik).
    public init(metin: String, sure: Double) {
        let sk = Array(metin.unicodeScalars)
        var araliklar: [Range<Int>] = []
        var i = 0
        while i < sk.count {
            if SesAnahtari.bosluk(sk[i]) { i += 1; continue }
            var j = i
            while j < sk.count, !SesAnahtari.bosluk(sk[j]) { j += 1 }
            araliklar.append(i..<j)
            i = j
        }
        let agirlik = araliklar.map { r -> Double in
            var w = Double(r.count) + 1.5
            let son = sk[r.upperBound - 1]
            if ".!?…".unicodeScalars.contains(son) { w += 6 } else if ",;:".unicodeScalars.contains(son) { w += 3 }
            return w
        }
        let basBosluk = 0.12, sonBosluk = 0.25
        let toplam = agirlik.reduce(0, +)
        let olcek = toplam > 0 ? max(0, sure - basBosluk - sonBosluk) / toplam : 0
        var t = basBosluk
        var kelimeler: [Kelime] = []
        for (r, w) in zip(araliklar, agirlik) {
            kelimeler.append(Self.kelime(sk, r, bas: t))
            t += w * olcek
        }
        self.metin = metin
        self.sure = sure
        self.kelimeler = kelimeler
    }

    private static func kelime(_ sk: [Unicode.Scalar], _ r: Range<Int>, bas: Double) -> Kelime {
        let once = sk[0..<r.lowerBound].reduce(0) { $0 + UTF16.width($1) }
        let boy = sk[r].reduce(0) { $0 + UTF16.width($1) }
        var v = String.UnicodeScalarView()
        v.append(contentsOf: sk[r])
        return Kelime(bas: bas, harf: r, utf16: once..<(once + boy), yazi: String(v))
    }

    /// `sn` anında söylenen kelimenin sırası (henüz başlamadıysa -1).
    public func kelime(sn: Double) -> Int {
        var sonuc = -1
        for (i, k) in kelimeler.enumerated() {
            if k.bas <= sn + 0.0001 { sonuc = i } else { break }
        }
        return sonuc
    }

    /// Konuşma sentezinin söylediği UTF-16 konumundaki kelime (-1: henüz yok).
    public func kelime(utf16 konum: Int) -> Int {
        var sonuc = -1
        for (i, k) in kelimeler.enumerated() {
            if k.utf16.lowerBound <= konum { sonuc = i } else { break }
        }
        return sonuc
    }

    /// Kelimenin içinde bulunduğu cümle (kelime sıraları). Cümle `.!?…` ile biten kelimede biter; çok uzun cümle
    /// `enCok` kelimelik parçalara bölünür (altyazı en çok iki-üç satır kalsın).
    public func cumle(kelime i: Int, enCok: Int = 22) -> Range<Int> {
        guard !kelimeler.isEmpty else { return 0..<0 }
        let k = min(max(0, i), kelimeler.count - 1)
        var parcalar: [Range<Int>] = []
        var bas = 0
        for (j, w) in kelimeler.enumerated() {
            let son = w.yazi.unicodeScalars.last.map { ".!?…".unicodeScalars.contains($0) } ?? false
            // Kapanış tırnağı ya da ayraçla biten cümle de cümledir: "…bak." ya da "(…)."
            let sonIki = w.yazi.unicodeScalars.suffix(2)
            let tirnakli = sonIki.count == 2 && ".!?…".unicodeScalars.contains(sonIki.first!)
                && "\"”»)'’".unicodeScalars.contains(sonIki.last!)
            if son || tirnakli || j == kelimeler.count - 1 {
                parcalar.append(bas..<(j + 1))
                bas = j + 1
            }
        }
        // uzunları böl
        var bolunmus: [Range<Int>] = []
        for p in parcalar {
            if p.count <= enCok {
                bolunmus.append(p)
            } else {
                let parca = Int((Double(p.count) / Double(enCok)).rounded(.up))
                let boy = Int((Double(p.count) / Double(parca)).rounded(.up))
                var s = p.lowerBound
                while s < p.upperBound {
                    bolunmus.append(s..<min(p.upperBound, s + boy))
                    s += boy
                }
            }
        }
        return bolunmus.first { $0.contains(k) } ?? 0..<kelimeler.count
    }
}
