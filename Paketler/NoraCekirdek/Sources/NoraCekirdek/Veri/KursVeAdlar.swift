// Kaynak: sanat-atlasi js/kurs.js, js/adlar.js @ a866b86 (site 1.90.3)
import Foundation

// MARK: - kurs.js

/// İlerleme kitaplığındaki bir kurs konusu ve kapağı (İş 28)
public struct KursKonusu: Hashable, Sendable, Identifiable {
    public struct Kapak: Hashable, Sendable {
        /// Kapağın sanatçısı (dosya yoksa onun en bilinen eseri)
        public var sanatci: String
        /// Derste işlenen eserin Commons dosyası (çözülmüş biçimde)
        public var dosya: String?
        public var baslik: String?
        /// Fotoğraf resim değil (heykel ya da yapı)
        public var resimDegil: Bool = false
    }

    public var konu: Konu
    public var kapak: Kapak
    public var id: Int { konu.no }
}

enum KursKapagi {
    static func kelimeler(_ x: String?) -> [String] {
        var sonuc: [String] = []
        var simdiki = ""
        for u in (x ?? "").lowercased().unicodeScalars {
            if (0x61...0x7A).contains(u.value) || (0xE0...0xFF).contains(u.value) {
                simdiki.unicodeScalars.append(u)
            } else if !simdiki.isEmpty {
                sonuc.append(simdiki); simdiki = ""
            }
        }
        if !simdiki.isEmpty { sonuc.append(simdiki) }
        return sonuc
    }

    static func soyadi(_ s: Sanatci) -> String { kelimeler(JS.dolu(s.adArama) ?? s.ad).last ?? "" }
    static func baslikta(_ s: Sanatci, _ baslik: String) -> Bool { kelimeler(baslik).contains(soyadi(s)) }
    static func baslikIlk(_ s: Sanatci, _ baslik: String) -> Bool { kelimeler(baslik).first == soyadi(s) }

    struct DersEseri { let s: Sanatci; let sira: Int; let e: Sanatci.KursEseri }

    static func dersEserleri(_ no: Int, _ sanatcilar: [Sanatci], _ sec: (Sanatci) -> [(Int, Sanatci.KursEseri)]) -> [DersEseri] {
        sanatcilar.flatMap { s in
            sec(s).filter { $0.1.konu == no && JS.dolu($0.1.commonsDosya) != nil }.map { DersEseri(s: s, sira: $0.0, e: $0.1) }
        }
    }

    static func enUygun(_ l: [DersEseri], _ baslik: String) -> DersEseri? {
        let b = Set(kelimeler(baslik).filter { $0.unicodeScalars.count >= 4 })
        func puan(_ x: DersEseri) -> Int { kelimeler(x.e.baslik).filter { b.contains($0) }.count }
        let adli = l.filter { baslikta($0.s, baslik) }
        guard var en = adli.first else { return nil }
        for x in adli.dropFirst() where puan(x) > puan(en) { en = x }
        return en
    }

    static func eserKapagi(_ x: DersEseri) -> KursKonusu.Kapak {
        .init(sanatci: x.s.id, dosya: Yardimci.dosyaNormal(x.e.commonsDosya), baslik: x.e.baslik)
    }

    /// `konuKapagi`: sanatcilar görünür sanatçılar; tumSanatcilar heykeltıraş ve mimarlar dahil hepsi
    static func kapak(_ konu: Konu, _ sanatcilar: [Sanatci], _ kurallar: EserKurallari, _ tumSanatcilar: [Sanatci]) -> KursKonusu.Kapak? {
        let no = konu.no
        let l = sanatcilar.filter { $0.konu == no }
        if let ilk = l.first { return .init(sanatci: (l.first { $0.kaynak == "kurs" } ?? ilk).id) }
        let resimler = dersEserleri(no, sanatcilar) { kurallar.kursResimleri($0).map { ($0.sira, $0.eser) } }
        if let adli = enUygun(resimler, konu.baslik) { return eserKapagi(adli) }
        if let adi = sanatcilar.first(where: { baslikIlk($0, konu.baslik) }) { return .init(sanatci: adi.id) }
        let hepsi = dersEserleri(no, tumSanatcilar) { ($0.kursEserleri ?? []).enumerated().map { ($0.offset, $0.element) } }
        func resimMi(_ x: DersEseri) -> Bool { resimler.contains { $0.s.id == x.s.id && $0.sira == x.sira } }
        if let foto = enUygun(hepsi, konu.baslik) {
            var k = eserKapagi(foto)
            k.resimDegil = !resimMi(foto)
            return k
        }
        if let r = resimler.first { return eserKapagi(r) }
        guard let h = hepsi.first else { return nil }
        var k = eserKapagi(h)
        k.resimDegil = true
        return k
    }
}

// MARK: - adlar.js

/// data/kisa_adlar.json kaydı: büyük satırda gösterilen bilinen ad ve küçük satırda adın geri kalanı
public struct KisaAd: Codable, Hashable, Sendable {
    public var buyuk: String?
    public var kucuk: String?
    public init(buyuk: String?, kucuk: String?) { self.buyuk = buyuk; self.kucuk = kucuk }
}

/// Sanatçı adının iki satırı: küçük satır (italik) ve büyük satır (bilinen ad); `tam` varsa büyük satırın altında tam ad
public struct AdParcalari: Hashable, Sendable {
    public var ilk: String
    public var son: String
    public var tam: String?
}

public enum Adlar {
    static let ekler: Set<String> = ["van", "von", "de", "der", "den", "da", "di", "del", "della", "du", "la", "le", "ter", "el"]
    static let tr = Locale(identifier: "tr")
    private static let kalip = try! NSRegularExpression(pattern: #"^(.*?)(\s*\([^)]*\))?$"#)

    /// `adParcala`
    public static func parcala(_ ad: String, kisa: KisaAd? = nil) -> AdParcalari {
        if let kisa, let buyuk = JS.dolu(kisa.buyuk) {
            let tam = [buyuk, kisa.kucuk ?? ""].filter { !$0.isEmpty }.joined(separator: " ")
            if ad.hasPrefix(buyuk) {
                return JS.dolu(kisa.kucuk) != nil ? AdParcalari(ilk: "", son: buyuk, tam: tam) : AdParcalari(ilk: "", son: buyuk)
            }
            return AdParcalari(ilk: kisa.kucuk ?? "", son: buyuk)
        }
        let kirpik = JS.kirp(ad)
        let ns = kirpik as NSString
        var ana = kirpik, parantez = ""
        if let m = kalip.firstMatch(in: kirpik, range: NSRange(location: 0, length: ns.length)) {
            ana = JS.kirp(ns.substring(with: m.range(at: 1)))
            if m.range(at: 2).location != NSNotFound { parantez = JS.kirp(ns.substring(with: m.range(at: 2))) }
        }
        var k = ana.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        if k.isEmpty { k = [""] }
        var i = k.count - 1
        // "Limbourg kardeşler" gibi küçük harfle biten adlar bölünmez
        if k.count == 2 && k[1] == k[1].lowercased(with: tr) { i = 0 }
        while i > 0 && ekler.contains(k[i - 1].lowercased(with: tr)) { i -= 1 }
        return AdParcalari(ilk: k[..<i].joined(separator: " "),
                           son: [k[i...].joined(separator: " "), parantez].filter { !$0.isEmpty }.joined(separator: " "))
    }

    /// `bilinenAd`: kısa listelerde kullanılan bilinen ad
    public static func bilinen(_ ad: String, kisa: KisaAd? = nil) -> String { parcala(ad, kisa: kisa).son }
}
