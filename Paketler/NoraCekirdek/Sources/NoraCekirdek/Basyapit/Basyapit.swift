// Kaynak: sanat-atlasi js/basyapit.js (basyapitlariAl, basyapitBul, sanatcininBasyapitlari, eserEslestir, oneCikanlar,
// gorunenBaslik), js/ekranlar/gozat.js (basyapitVeri, basyapitAdresi, bsyGruplari), js/harita.js (BOLGELER, bolgeBul),
// js/temsil.js (temsilOlabilir) @ a866b86
import Foundation

/// Başyapıt yakın okuması (data/basyapitlar.json)
public struct Basyapit: Equatable, Hashable, Sendable, Identifiable {
    public struct Bolum: Equatable, Hashable, Sendable {
        public let baslik, metin: String
    }
    /// QID ya da "sanatçıId|başlık"
    public let anahtar: String
    public let sanatci: String
    public let baslik: String
    public let ozgun, tarih, muze, ozet: String
    public let bolumler: [Bolum]
    public let bak: [String]
    public var id: String { anahtar }

    public init(anahtar: String, sanatci: String, baslik: String, ozgun: String = "", tarih: String = "", muze: String = "",
                ozet: String = "", bolumler: [Bolum], bak: [String] = []) {
        self.anahtar = anahtar; self.sanatci = sanatci; self.baslik = baslik; self.ozgun = ozgun; self.tarih = tarih
        self.muze = muze; self.ozet = ozet; self.bolumler = bolumler; self.bak = bak
    }

    /// `gorunenBaslik(b)` (İş 189): parantez yalnız özgün adın tekrarıysa ya da parantezden önceki kısım özgün adın
    /// kendisiyse atılır ("Elçiler (The Ambassadors)" → "Elçiler"); açıklayıcı parantez kalır.
    public var gorunenBaslik: String {
        let o = JSMetin.kucuk(JSMetin.kirp(ozgun))
        guard !o.isEmpty, let m = Self.parantezli.ilk(baslik) else { return baslik }
        let ayni = { (x: String) in JSMetin.kucuk(JSMetin.kirp(x)) == o }
        return ayni(m[2]) || ayni(m[1]) ? m[1] : baslik
    }
    private static let parantezli = JSDuzen(#"^(.*\S)\s*\(([^()]*)\)$"#)

    /// Sayfadaki özgün ad satırı: başlık olduğu gibi gösteriliyor ve özgün ad başlığın içinde geçmiyorsa
    public var ozgunSatiri: String? {
        !ozgun.isEmpty && gorunenBaslik == baslik && !baslik.contains(ozgun) ? ozgun : nil
    }

    /// `basyapitAdresi(k)`
    public var adres: String { "#/basyapit/" + SiteYazisi.uriBileseni(anahtar) }
}

public enum BasyapitKurallari {
    private static func yazi(_ j: JSONDeger?) -> String? {
        guard let s = j?.metin, !JSMetin.kirp(s).isEmpty else { return nil }
        return s
    }

    /// `basyapitlariAl(json, varMi)` + `.filter(temsilOlabilir)` (basyapitVeri): geçersiz kayıtlar ve temsil dışı eserler atılır;
    /// tarih, müze ve özgün addaki ders notu artıkları gösterimden çıkar (anahtar değişmez)
    public static func al(_ json: JSONDeger?, varMi: (String) -> Bool = { _ in true }) -> [Basyapit] {
        (json?["eserler"]?.dizi ?? []).compactMap { e in
            guard let anahtar = yazi(e["anahtar"]), let sanatci = yazi(e["sanatci"]), varMi(sanatci),
                  let baslik = yazi(e["baslik"]), let bl = e["bolumler"]?.dizi, !bl.isEmpty else { return nil }
            var bolumler: [Basyapit.Bolum] = []
            for b in bl {
                guard let bb = yazi(b["baslik"]), let mt = yazi(b["metin"]) else { return nil }
                bolumler.append(.init(baslik: bb, metin: mt))
            }
            let a = anahtar.hasPrefix("q:") ? String(anahtar.dropFirst(2)) : anahtar
            guard !Temsil.disi.contains(a) else { return nil }
            return Basyapit(anahtar: anahtar, sanatci: sanatci, baslik: baslik,
                            ozgun: SiteYazisi.notTemizle(e["ozgun"]?.metin ?? ""),
                            tarih: SiteYazisi.notTemizle(e["tarih"]?.metin ?? ""),
                            muze: SiteYazisi.notTemizle(e["muze"]?.metin ?? ""),
                            ozet: yazi(e["ozet"]) ?? "", bolumler: bolumler,
                            bak: (e["bak"]?.dizi ?? []).compactMap { yazi($0) })
        }
    }

    public static func al(veri: Data, varMi: (String) -> Bool = { _ in true }) -> [Basyapit] {
        al(try? JSONDeger.coz(veri), varMi: varMi)
    }

    /// `basyapitBul`
    public static func bul(_ liste: [Basyapit], _ anahtar: String) -> Basyapit? { liste.first { $0.anahtar == anahtar } }

    /// `sanatcininBasyapitlari`
    public static func sanatcinin(_ liste: [Basyapit], _ sanatciId: String) -> [Basyapit] { liste.filter { $0.sanatci == sanatciId } }

    /// `eserEslestir(eserler, kayit)`: önce QID, sonra "sanatçı|başlık"
    public static func eser(_ eserler: [Eser], _ b: Basyapit) -> Eser? {
        eserler.first { ($0.qid != nil && $0.qid == b.anahtar) || b.sanatci + "|" + $0.baslik == b.anahtar }
    }

    /// Sayfanın "Sıradaki" eseri: listede bir sonraki (sonuncudan sonra ilk)
    public static func sonraki(_ liste: [Basyapit], _ b: Basyapit) -> Basyapit? {
        guard liste.count > 1, let i = liste.firstIndex(of: b) else { return nil }
        return liste[(i + 1) % liste.count]
    }

    /// `oneCikanlar(l, hikayeli, acikMi, gun, adet)` (1.76.4): hikâyesi olanlar başta; kalan yerler açık sanatçıların
    /// eserlerinden (hiç yoksa hepsinden), listeye yayılarak ve her gün başka bir yerden başlayarak dolar.
    public static func oneCikanlar(_ l: [Basyapit], hikayeli: Set<String>, acikMi: (Basyapit) -> Bool = { _ in true },
                                   gun: Int = BasyapitKurallari.bugun(), adet: Int = 4) -> [Basyapit] {
        let n = min(adet, l.count)
        var one = Array(l.filter { hikayeli.contains($0.anahtar) }.prefix(n))
        let acik = l.filter { b in !one.contains(b) && acikMi(b) }
        let kalan = acik.isEmpty ? l.filter { !one.contains($0) } : acik
        let adim = max(1, kalan.count / adet)
        var i = 0
        while one.count < n && i < kalan.count {
            let b = kalan[(gun + i * adim) % kalan.count]
            if !one.contains(b) { one.append(b) }
            i += 1
        }
        for b in kalan where one.count < n && !one.contains(b) { one.append(b) }
        for b in l where one.count < n && !one.contains(b) { one.append(b) }
        return one
    }

    /// `Math.floor(Date.now() / 864e5)`: UTC gün sayısı
    public static func bugun(_ t: Date = Date()) -> Int { Int((t.timeIntervalSince1970 * 1000 / 864e5).rounded(.down)) }

    /// `bsyGruplari(liste)`: dönemler (BOLGELER) sırasıyla; her dönemde akımlar `d.akimlar` sırasıyla, akımın eserleri
    /// listedeki sırasıyla. Eseri olmayan akım ve dönem yok.
    public static func gruplar(_ liste: [Basyapit], katalog: SiteKatalogu) -> [BasyapitGrubu] {
        Donem.bolgeler.compactMap { bolge in
            let akimlar: [(ad: String, eserler: [Basyapit])] = katalog.akimlar
                .filter { Donem.bul($0.sira).id == bolge.id }
                .map { a in (a.ad, liste.filter { katalog.harita[$0.sanatci]?.akim == a.ad }) }
                .filter { !$0.eserler.isEmpty }
            let l = akimlar.flatMap(\.eserler)
            return l.isEmpty ? nil : BasyapitGrubu(bolge: bolge, akimlar: akimlar, eserler: l)
        }
    }
}

public struct BasyapitGrubu: Sendable {
    public let bolge: Donem
    public let akimlar: [(ad: String, eserler: [Basyapit])]
    public let eserler: [Basyapit]
}

/// js/harita.js `BOLGELER`: haritanın dokuz dönemi (akım sırası aralıklarıyla)
public struct Donem: Equatable, Hashable, Sendable, Identifiable {
    public let id, ad, yuzyil: String
    public let ilk, son: Double

    public static let bolgeler: [Donem] = [
        .init(id: "ortacag", ad: "Orta Çağ", yuzyil: "Antik çağdan XV. yüzyıla", ilk: 0, son: 3),
        .init(id: "ronesans", ad: "Rönesans", yuzyil: "XV–XVI. yüzyıl", ilk: 4, son: 8),
        .init(id: "barok", ad: "Barok", yuzyil: "XVII. yüzyıl", ilk: 9, son: 12),
        .init(id: "barok2", ad: "Klasisizm ve Geç Barok", yuzyil: "XVII–XVIII. yüzyıl", ilk: 13, son: 14),
        .init(id: "aydinlanma", ad: "Rokoko ve Neoklasisizm", yuzyil: "XVIII. yüzyıl", ilk: 15, son: 16),
        .init(id: "romantik", ad: "Romantizmden Realizme", yuzyil: "XIX. yüzyılın ilk yarısı", ilk: 17, son: 20),
        .init(id: "empresyonizm", ad: "Empresyonizm", yuzyil: "XIX. yüzyılın son çeyreği", ilk: 21, son: 22),
        .init(id: "postempresyonizm", ad: "Post-Empresyonizm ve Sembolizm", yuzyil: "XIX. yüzyıl sonu – XX. yüzyıl başı", ilk: 23, son: 25),
        .init(id: "modern", ad: "Modern sanat", yuzyil: "XX. yüzyıl", ilk: 26, son: 99),
    ]

    /// `bolgeBul(sira)`
    public static func bul(_ sira: Double) -> Donem {
        bolgeler.first { sira >= $0.ilk && sira <= $0.son } ?? bolgeler[bolgeler.count - 1]
    }

    /// `bolgeBul(d.akimSira[ad] ?? 0)`
    public static func akimin(_ k: SiteKatalogu, _ ad: String) -> Donem {
        bul(k.akimlar.first { $0.ad == ad }?.sira ?? 0)
    }
}
