// Kaynak: sanat-atlasi js/bolum.js (bolumKaydi, gectiMi, yildizSayisi, bolumSonucuIsle, gorulenGruplar,
// tanismaGrubuGoruldu, tanitimGoruldu, BOLUM_GECME), js/ekranlar/pekistir.js (kartCiz tanitimIsaret, kartiBitir,
// sergiyeEkle, grupOzeti, bolumOzeti, kipKisa, BOLUM_SV_AD) @ a866b86
import Foundation

/// `bolumSonucuIsle`'nin dönüşü
public struct BolumSonucu: Codable, Equatable {
    public let oran: Double
    public let gecti: Bool
    public let yeniGecti: Bool
    public let yildizOnce: Int
    public let yildizSonra: Int
}

/// Bölüm kaydının (`ilerleme.bolumler[id]`) kuralları
public enum BolumKurallari {
    /// `BOLUM_GECME`
    public static let gecme = 0.75
    /// `BOLUM_SEVIYELER`
    public static let seviyeler = ["kolay", "orta", "zor"]
    /// `BOLUM_SORU`
    public static func soruSayisi(_ seviye: String) -> Int { seviye == "kolay" ? 8 : 10 }

    /// `bolumKaydi(ilerleme, id)`
    public static func kayit(_ il: Ilerleme, _ id: String) -> SiraliNesne { il[alan: "bolumler"]?[id]?.nesne ?? .bos }
    /// `gectiMi(kayit, seviye)`
    public static func gecti(_ k: SiraliNesne, _ seviye: String) -> Bool { (k[seviye]?.sayi ?? 0) >= gecme }
    /// `yildizSayisi(kayit)`
    public static func yildiz(_ k: SiraliNesne) -> Int { seviyeler.filter { gecti(k, $0) }.count }

    private static func yaz(_ il: inout Ilerleme, _ id: String, _ k: SiraliNesne) {
        let hepsi = il[alan: "bolumler"]?.nesne ?? .bos
        il[alan: "bolumler"] = .nesne(hepsi.ayarlandi(id, .nesne(k)))
    }

    /// `bolumSonucuIsle(ilerleme, id, seviye, dogru, toplam)`: en iyi oranı tutar
    @discardableResult
    public static func sonucuIsle(_ il: inout Ilerleme, id: String, seviye: String, dogru: Int, toplam: Int) -> BolumSonucu {
        let once = kayit(il, id)
        let oran = toplam > 0 ? Double(dogru) / Double(toplam) : 0
        let sonra = once.ayarlandi(seviye, .sayi(max(once[seviye]?.sayi ?? 0, (oran * 1000).rounded() / 1000)))
        yaz(&il, id, sonra)
        return BolumSonucu(oran: oran, gecti: oran >= gecme, yeniGecti: oran >= gecme && !gecti(once, seviye),
                           yildizOnce: yildiz(once), yildizSonra: yildiz(sonra))
    }

    private static func grupAlani(_ orta: Bool) -> String { orta ? "tanitimOrtaGrup" : "tanitimGrup" }

    /// `gorulenGruplar(kayit, seviye, adet)`
    public static func gorulenGruplar(_ k: SiraliNesne, orta: Bool, adet: Int) -> [Int] {
        if k[orta ? "tanitimOrta" : "tanitim"]?.mantik == true { return Array(0..<adet) }
        return Set(k[grupAlani(orta)]?.dizi?.compactMap(\.tamSayi) ?? []).filter { $0 < adet }.sorted()
    }

    /// `tanismaGrubuGoruldu(ilerleme, id, seviye, grup, adet)`
    public static func grubuGoruldu(_ il: inout Ilerleme, id: String, orta: Bool, grup: Int, adet: Int) {
        var k = kayit(il, id)
        let l = Set((k[grupAlani(orta)]?.dizi?.compactMap(\.tamSayi) ?? []) + [grup]).sorted()
        k = k.ayarlandi(grupAlani(orta), .dizi(l.map { .sayi(Double($0)) }))
        if l.filter({ $0 < adet }).count >= adet { k = k.ayarlandi(orta ? "tanitimOrta" : "tanitim", .mantik(true)) }
        yaz(&il, id, k)
    }

    /// `tanitimGoruldu(ilerleme, id, seviye)`
    public static func tanitimGoruldu(_ il: inout Ilerleme, id: String, orta: Bool) {
        yaz(&il, id, kayit(il, id).ayarlandi(orta ? "tanitimOrta" : "tanitim", .mantik(true)))
    }
}

extension BolumSeviyesi {
    /// `TANITIM_SEVIYE[sv] || sv`: "kolay" | "orta" | "zor"
    public var anahtar: String {
        switch self {
        case .kolay: return "kolay"
        case .orta: return "orta"
        case .zor: return "zor"
        case .tanitim(let orta, _): return orta ? "orta" : "kolay"
        }
    }
    /// `BOLUM_SV_AD[sv]`
    public var ad: String {
        switch self {
        case .kolay: return "Kolay"
        case .orta: return "Orta"
        case .zor: return "Zor"
        case .tanitim(let orta, _): return orta ? "Orta tanıtımı" : "Tanıtım"
        }
    }
    public var grup: Int? { if case let .tanitim(_, g) = self { return g }; return nil }
    public var tanitimMi: Bool { if case .tanitim = self { return true }; return false }
}

/// Bir bölüm turu: pekiştirme turu (`TurKaydi`, kip `.bolum`) + yalnız ilk denemelerin sergisi + bitişte bölüm kaydı.
public struct BolumTuru: Codable {
    /// `sergiyeEkle`: duvara asılan eser (ilk deneme doğru mu)
    public struct AsiliEser: Codable { public let resim: TurKarti.Resim; public let dogru: Bool }
    public private(set) var tur: TurKaydi
    public private(set) var sergi = [AsiliEser]()
    public let id: String
    public let seviye: BolumSeviyesi
    let grupSayisi: Int
    /// Bölüm sonucu (`bolumOzeti`); grup ve tanıtım turlarında nil
    public private(set) var sonuc: BolumSonucu?
    /// Bitiş kaydı yazıldı mı (sitede `grupIsaret`, `bolumSonuc`)
    private var isaretli: Bool?

    public init(durak: YolculukDuragi, seviye: BolumSeviyesi, katalog: SiteKatalogu, veri: PekistirmeVerileri, il: inout Ilerleme) {
        id = durak.id
        self.seviye = seviye
        grupSayisi = durak.gruplar.count
        tur = TurKaydi(kip: .sanatci(.bolum(id: id, sanatcilar: durak.sanatcilar, seviye: seviye)), seviye: nil, katalog: katalog,
                       veri: veri, ilerleme: il, gun: GunTarihi.gun(Date()))
        tur.hazirla(katalog: katalog, veri: veri, ilerleme: &il)
        bitir(&il)
    }

    /// `kipKisa('bolum', …)`: "Erken Rönesans · Kolay", "… · Tanıtım · 1. grup"
    public func baslik(_ durakAdi: String) -> String {
        "\(durakAdi) · \(seviye.ad)" + (seviye.grup.map { " · \($0 + 1). grup" } ?? "")
    }

    /// `konuTanismaGoster`'in bölüm dalı: etiket, not, düğmenin üst ve ana yazısı
    public func tanismaYazilari(durakAdi: String, sonrakiAd: String?) -> (etiket: String, not: String, ust: String, ana: String) {
        let t = tur.tanisma
        let son = t.map { $0.konum + 1 >= $0.sira.count } ?? true
        let toplam = tur.oturum.kuyruk.count
        let orta = seviye.anahtar == "orta"
        let tanSv = orta ? "Orta" : "Kolay"
        let etiket = "\(durakAdi) · \(orta ? "Orta tanıtımı" : "tanıtım")"
        guard son else { return (etiket, "Sonra bu bölümün öbür sanatçısı geliyor.", "Sıradaki sanatçı", sonrakiAd ?? "Sonraki sanatçı") }
        guard toplam > 0 else { return (etiket, "Tanıtım bitti.", "Tanıtım bitti", "Haritaya dön") }
        return (etiket,
                "Sırada bu sanatçılardan \(toplam) soruluk \(tanSv) seviye var; sorular buradaki eserlerden. Geçmek için %\(Int(BolumKurallari.gecme * 100)) doğru.",
                "Hazırsan", orta ? "Orta’ya başla" : "Kolay’a başla")
    }

    public mutating func cevapla(_ secim: String?, katalog: SiteKatalogu, il: inout Ilerleme,
                                 rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        guard let kart = tur.kart, kart.sonuc == nil else { return }
        let toplam = tur.oturum.ilkToplam, dogru = tur.oturum.ilkDogru
        tur.cevapla(secim, katalog: katalog, gun: GunTarihi.gun(Date()), ilerleme: &il, rastgele: rastgele)
        if tur.oturum.ilkToplam > toplam { sergi.append(.init(resim: kart.resim, dogru: tur.oturum.ilkDogru > dogru)) }
    }

    /// Sıradaki kart ya da tanışmada sıradaki sanatçı
    public mutating func ilerle(katalog: SiteKatalogu, veri: PekistirmeVerileri, il: inout Ilerleme) {
        if tur.tanismaBekliyor || tur.kart?.tanisma != nil { tur.tanismaGec(katalog: katalog, veri: veri, ilerleme: &il) }
        else { tur.sonraki(katalog: katalog, veri: veri, ilerleme: &il) }
        bitir(&il)
    }

    public mutating func tanismaGeri(katalog: SiteKatalogu, veri: PekistirmeVerileri, il: Ilerleme) {
        tur.tanismaGeri(katalog: katalog, veri: veri, ilerleme: il)
    }

    public mutating func baskaEser(katalog: SiteKatalogu, il: Ilerleme) {
        tur.baskaEser(katalog: katalog, ilerleme: il)
    }

    /// `kartCiz` (tanışma bitince `tanitimGoruldu`), `grupOzeti` (`tanismaGrubuGoruldu`), `bolumOzeti` (`bolumSonucuIsle`)
    private mutating func bitir(_ il: inout Ilerleme) {
        let orta = seviye.anahtar == "orta"
        if !tur.tanismaBekliyor, tur.tanisma != nil, seviye.grup == nil {
            let k = BolumKurallari.kayit(il, id)
            if k[orta ? "tanitimOrta" : "tanitim"]?.mantik != true { BolumKurallari.tanitimGoruldu(&il, id: id, orta: orta) }
        }
        guard tur.bitti, isaretli != true else { return }
        isaretli = true
        if let g = seviye.grup {
            BolumKurallari.grubuGoruldu(&il, id: id, orta: orta, grup: g, adet: grupSayisi)
        } else if !seviye.tanitimMi {
            sonuc = BolumKurallari.sonucuIsle(&il, id: id, seviye: seviye.anahtar,
                                              dogru: tur.oturum.ilkDogru, toplam: tur.oturum.ilkToplam)
        }
    }

    public var oran: Double { tur.oturum.ilkToplam == 0 ? 0 : Double(tur.oturum.ilkDogru) / Double(tur.oturum.ilkToplam) }
}
