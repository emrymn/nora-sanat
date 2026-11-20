// Kaynak: sanat-atlasi js/ogrenme.js, js/kilit.js @ a866b86 (site 1.90.3)
import Foundation

/// Sık karıştırılan ikili: `karisanlar["a|b"] = { n, son }`
public struct Karisan: Equatable, Sendable, Codable {
    public var n: Int
    public var son: String
    public init(n: Int, son: String) { self.n = n; self.son = son }
    public var json: JSONDeger { .nesne([("n", .sayi(n)), ("son", .metin(son))]) }
}

/// En çok karıştırılan ikili (`enCokKarisanlar` öğesi)
public struct KarisanIkili: Equatable, Sendable, Codable {
    public var a, b: String
    public var n: Int
    public var son: String
}

/// Tanışma ve karıştırılan ikililer (js/ogrenme.js)
public enum Ogrenme {
    public static let karisanEsigi = 2

    /// `tanismaGerekirMi`: sanatçı hiç sorulmadıysa
    public static func tanismaGerekir(_ s: SkorKaydi?) -> Bool { !Leitner.goruldu(s?.sanatci) && !Leitner.goruldu(s?.akim) }

    /// `tanismaEserleri`: en tipik/ünlü eserler (sorulacak eser hariç)
    public static func tanismaEserleri(_ havuz: [Eser], haric: String?, adet: Int = 3, kolaylik: ((Eser) -> Double?)? = nil) -> [Eser] {
        func p(_ e: Eser) -> Double { kolaylik?(e) ?? -1 }
        return havuz.filter { $0.anahtar != haric }.enumerated()
            .sorted { x, y in
                let (a, b) = (x.element, y.element)
                if p(a) != p(b) { return p(a) > p(b) }
                if a.sl != b.sl { return a.sl > b.sl }
                return x.offset < y.offset
            }
            .prefix(adet).map(\.element)
    }

    /// `karisanAnahtari`: alfabetik sıralı iki kimlik
    public static func anahtar(_ a: String, _ b: String) -> String {
        a.utf16.lexicographicallyPrecedes(b.utf16) || a == b ? "\(a)|\(b)" : "\(b)|\(a)"
    }

    /// `karisanEkle`: yanlış cevapta; ikilinin yeni sayısı
    @discardableResult
    public static func ekle(_ karisanlar: inout [String: Karisan], dogruId: String, secilenId: String, tarih: String) -> Int {
        guard !dogruId.isEmpty, !secilenId.isEmpty, dogruId != secilenId else { return 0 }
        let k = anahtar(dogruId, secilenId)
        let n = (karisanlar[k]?.n ?? 0) + 1
        karisanlar[k] = Karisan(n: n, son: tarih)
        return n
    }

    /// `enCokKarisanlar`: `sirali` kaydın nesne sırası (eşitlikte JS'in kararlı sıralaması bunu korur)
    public static func enCok(_ sirali: [(anahtar: String, deger: Karisan)], adet: Int = 5, esik: Int = karisanEsigi,
                             varMi: (String) -> Bool = { _ in true }) -> [KarisanIkili] {
        sirali.map { k, v -> KarisanIkili in
            let p = k.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            return KarisanIkili(a: p.first ?? "", b: p.count > 1 ? p[1] : "", n: v.n, son: v.son)
        }
        .filter { $0.n >= esik && varMi($0.a) && varMi($0.b) }
        .enumerated()
        .sorted { x, y in
            if x.element.n != y.element.n { return x.element.n > y.element.n }
            if x.element.son != y.element.son { return x.element.son > y.element.son }
            return x.offset < y.offset
        }
        .prefix(adet).map(\.element)
    }

    /// Sözlükten (sıra bilinmiyorsa anahtar sırasıyla)
    public static func enCok(_ karisanlar: [String: Karisan], adet: Int = 5, esik: Int = karisanEsigi,
                             varMi: (String) -> Bool = { _ in true }) -> [KarisanIkili] {
        enCok(karisanlar.sorted { $0.key < $1.key }.map { (anahtar: $0.key, deger: $0.value) }, adet: adet, esik: esik, varMi: varMi)
    }

    /// `karisanlarDogrula`, nesne sırasıyla (yinelenen ikili ilk yerinde, son değeriyle)
    public static func dogrulaSirali(_ k: JSONDeger?) -> [(anahtar: String, deger: Karisan)] {
        guard let n = k?.nesne else { return [] }
        var sonuc: [(anahtar: String, deger: Karisan)] = []
        var yer: [String: Int] = [:]
        for (a, v) in n.ciftler {
            let p = a.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard p.count == 2, !p[0].isEmpty, !p[1].isEmpty, p[0] != p[1] else { continue }
            guard let sayi = v["n"]?.tamSayi, sayi >= 1 else { continue }
            let ka = anahtar(p[0], p[1])
            let deger = Karisan(n: sayi, son: v["son"]?.metin ?? "")
            if let i = yer[ka] { sonuc[i].deger = deger } else { yer[ka] = sonuc.count; sonuc.append((ka, deger)) }
        }
        return sonuc
    }

    /// `karisanlarDogrula`
    public static func dogrula(_ k: JSONDeger?) -> [String: Karisan] {
        Dictionary(dogrulaSirali(k).map { ($0.anahtar, $0.deger) }, uniquingKeysWith: { _, b in b })
    }
}

/// Bir akımın kilit durumu (`akimDurumlari` öğesi)
public struct AkimDurumu: Equatable, Sendable, Codable {
    public var ad: String
    public var sira: Double
    public var toplam: Int
    public var acikSayisi: Int
    public var acik: Bool
    public var acilacagiKonu: Int?
}

/// Kilit: bir sanatçı, konusu "işlendi" işaretlenince açılır (js/kilit.js)
public enum Kilit {
    /// `acikSanatcilar(sanatcilar, islenen, ekIdler)`
    public static func acikSanatcilar(_ sanatcilar: [Sanatci], islenen: Set<Int>, ek: [String] = []) -> [Sanatci] {
        let e = Set(ek)
        return sanatcilar.filter { s in s.konu.map { islenen.contains($0) } ?? false || e.contains(s.id) }
    }

    /// `akimDurumlari`
    public static func akimDurumlari(_ akimlar: [Akim], _ sanatcilar: [Sanatci], islenen: Set<Int>) -> [AkimDurumu] {
        akimlar.enumerated().sorted { $0.element.sira != $1.element.sira ? $0.element.sira < $1.element.sira : $0.offset < $1.offset }
            .map(\.element).map { a in
                let uyeler = sanatcilar.filter { $0.akim == a.ad }
                let acik = uyeler.filter { s in s.konu.map { islenen.contains($0) } ?? false }
                let kapali = uyeler.filter { s in !(s.konu.map { islenen.contains($0) } ?? false) }.compactMap(\.konu)
                return AkimDurumu(ad: a.ad, sira: a.sira, toplam: uyeler.count, acikSayisi: acik.count, acik: !acik.isEmpty,
                                  acilacagiKonu: kapali.min())
            }
    }

    /// `yeniAcilanlar`: bir konu işaretlenince yeni açılan sanatçılar
    public static func yeniAcilanlar(_ sanatcilar: [Sanatci], once: Set<Int>, sonra: Set<Int>) -> [Sanatci] {
        sanatcilar.filter { s in guard let k = s.konu else { return false }; return !once.contains(k) && sonra.contains(k) }
    }
}
