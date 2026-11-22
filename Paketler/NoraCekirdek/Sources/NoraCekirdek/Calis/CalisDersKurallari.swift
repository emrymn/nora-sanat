// Kaynak: sanat-atlasi js/ders.js, js/dersIcerik.js, js/bolum.js, js/ekranlar/ders.js @ a866b86
import Foundation

/// Dersin üç adımı (`DERS_ADIMLARI`): Gör → Öğren → Ayırt et
public enum DersAdimi: String, CaseIterable, Sendable, Codable {
    case gor = "gor"
    case ogren = "ogren"
    case ayirt = "ayirt"

    public var ad: String {
        switch self {
        case .gor: return "Gör"
        case .ogren: return "Öğren"
        case .ayirt: return "Ayırt et"
        }
    }
}

/// Bir adımın ilerleme kaydı (`{ i: 0…1, t: "YYYY-MM-DD" | nil }`)
public struct DersAdimKaydi: Equatable, Sendable, Codable {
    public var i: Double
    public var t: String?

    public init(i: Double = 0, t: String? = nil) {
        self.i = i
        self.t = t
    }
}

/// Bir dönemin ders kaydı (`ilerleme.dersler[akim]`)
public struct DersKaydi: Equatable, Sendable, Codable {
    public var gor: DersAdimKaydi
    public var ogren: DersAdimKaydi
    public var ayirt: DersAdimKaydi

    public init(
        gor: DersAdimKaydi = .init(),
        ogren: DersAdimKaydi = .init(),
        ayirt: DersAdimKaydi = .init()
    ) {
        self.gor = gor
        self.ogren = ogren
        self.ayirt = ayirt
    }

    public subscript(_ adim: DersAdimi) -> DersAdimKaydi {
        get {
            switch adim {
            case .gor: return gor
            case .ogren: return ogren
            case .ayirt: return ayirt
            }
        }
        set {
            switch adim {
            case .gor: gor = newValue
            case .ogren: ogren = newValue
            case .ayirt: ayirt = newValue
            }
        }
    }
}

/// Ekrandaki ders durumu (`dersDurumu`)
public struct DersDurumu: Equatable, Sendable, Codable {
    public struct AdimDurumu: Equatable, Sendable, Codable {
        public var adim: DersAdimi
        public var ad: String
        public var i: Double
        public var bitti: Bool
    }

    public var adimlar: [AdimDurumu]
    public var siradaki: DersAdimi?
    public var biten: Int
    public var bitti: Bool
}

/// Menüdeki kısa durum (`dersHali`)
public enum DersHali: String, Sendable, Codable {
    case bitti = "bitti"
    case suruyor = "suruyor"
    case sirada = "sirada"

    public var etiket: String {
        switch self {
        case .bitti: return "Bitti"
        case .suruyor: return "Sürüyor"
        case .sirada: return "Sırada"
        }
    }
}

/// `data/ders_kaynaklari.json` içindeki eser referansı (`{ sanatci, eser?, baslik?, qid?, anahtar? }`)
public struct DersEserRef: Equatable, Sendable, Codable {
    public var sanatci: String
    public var eser: String?
    public var baslik: String?
    public var qid: String?
    public var anahtar: String?

    public init(sanatci: String, eser: String? = nil, baslik: String? = nil, qid: String? = nil, anahtar: String? = nil) {
        self.sanatci = sanatci
        self.eser = eser
        self.baslik = baslik
        self.qid = qid
        self.anahtar = anahtar
    }

    init?(json j: JSONDeger) {
        guard let s = j["sanatci"]?.metin, !s.isEmpty else { return nil }
        sanatci = s
        eser = j["eser"]?.metin
        baslik = j["baslik"]?.metin
        qid = j["qid"]?.metin
        anahtar = j["anahtar"]?.metin
    }
}

/// Gör planı (`gorPlani`): yürüyüşü yazılmış ilk 3 eser ve toplam ayrıntı sayısı
public struct GorPlani: Equatable, Sendable, Codable {
    public struct EserKaydi: Equatable, Sendable, Codable {
        public var sanatci: String
        public var eser: String
        public var noktaSayisi: Int
    }
    public var eserler: [EserKaydi]
    public var toplam: Int
}

/// Öğren planı maddesi (`ogrenPlani`)
public struct OgrenMaddesi: Equatable, Sendable, Codable {
    public struct Kanit: Equatable, Sendable, Codable {
        public var sanatci: String
        public var eser: String
        public var qid: String?
        public var anahtar: String?
        public var yer: String
        public var cumle: String
        public var id: String
    }
    public struct Aciklama: Equatable, Sendable, Codable {
        public var sanatci: String?
        public var yer: String
        public var cumle: String
        public var id: String
    }
    public var no: Int
    public var madde: String
    public var kanitlar: [Kanit]
    public var aciklamalar: [Aciklama]
}

/// Ayırt et planı ikilisi (`ayirtPlani`)
public struct AyirtIkilisi: Equatable, Sendable, Codable {
    public struct Cumle: Equatable, Sendable, Codable {
        public var kaynak: String?
        public var cumle: String
    }
    public var komsu: String
    public var acik: Bool
    public var cumleler: [Cumle]
    public var kendi: [DersEserRef]
    public var karsi: [DersEserRef]
    public var kendiMaddeler: [String]
    public var komsuMaddeler: [String]
}

/// Bir dönemin bütün ders hesabı (`dersBilgisi`)
public struct DersBilgisi: Equatable, Sendable, Identifiable {
    public var id: String { akim }
    public var akim: String
    public var adimlar: [DersAdimi]
    public var gor: GorPlani
    public var ogren: [OgrenMaddesi]
    public var ayirt: [AyirtIkilisi]
    public var acikSanatcilar: [Sanatci]
    public var kayit: DersKaydi
    public var durum: DersDurumu
    public var kapakAdaylari: [DersEserRef]

    public var hal: DersHali { CalisDersKurallari.dersHali(durum) }
}

/// Yolculuk haritası bölümü (`js/bolum.js` `bolumleriKur`)
public struct HaritaBolumu: Equatable, Sendable, Codable, Identifiable {
    public var id: String
    public var akim: String
    public var sira: Double
    public var no: Int
    public var adet: Int
    public var konular: [Int]
    public var sanatcilar: [String]

    public var bolumAdi: String {
        adet > 1 ? "\(akim) · \(no). bölüm" : akim
    }
}

/// Harita bölümünün kilit/açıklık durumu (`js/bolum.js` `bolumDurumlari`)
public struct HaritaBolumDurumu: Equatable, Sendable, Codable, Identifiable {
    public enum KilitNedeni: Equatable, Sendable, Codable {
        case kurs(konu: Int?)
        case ders(akim: String)
        case bolum(id: String)
        case akim(ad: String, gecen: Int, gereken: Int)
    }

    public var bolum: HaritaBolumu
    public var id: String { bolum.id }
    public var akim: String { bolum.akim }
    public var kursAcik: Bool
    public var acik: Bool
    public var neden: KilitNedeni?
    public var kolayGecti: Bool
    public var ortaGecti: Bool
    public var zorGecti: Bool
    public var yildiz: Int
}

/// Çalış ekranındaki ders ve harita kuralları (`js/ders.js`, `js/dersIcerik.js`, `js/bolum.js`, `js/ekranlar/ders.js`)
public enum CalisDersKurallari {
    public static let gorEserSiniri = 3
    public static let kanitEserSiniri = 3
    public static let aciklamaSiniri = 2
    public static let dogrulandi = "dogrulandi"
    public static let bolumGecme = 0.75
    public static let akimGecme = 0.6
    public static let kumeEnAz = 3
    public static let birlesenDuraklar: [String: String] = ["Uluslararası Gotik": "3-1"]

    private static func sinirla(_ x: Double) -> Double {
        min(1, max(0, (x * 1000).rounded() / 1000))
    }

    private static func tarihMi(_ s: String) -> Bool {
        s.range(of: "^\\d{4}-\\d{2}-\\d{2}$", options: .regularExpression) != nil
    }

    // MARK: - js/ders.js

    /// `dersKaydi(ilerleme, akim)`
    public static func dersKaydi(_ ilerleme: Ilerleme, akim: String) -> DersKaydi {
        let k = ilerleme[alan: "dersler"]?[akim]
        func adim(_ a: DersAdimi) -> DersAdimKaydi {
            let x = k?[a.rawValue]
            let i = x?["i"]?.sayi ?? 0
            let t = x?["t"]?.metin
            return DersAdimKaydi(i: i > 0 ? i : 0, t: (t?.isEmpty == false) ? t : nil)
        }
        return DersKaydi(gor: adim(.gor), ogren: adim(.ogren), ayirt: adim(.ayirt))
    }

    /// `adimBittiMi(kayit, adim)`
    public static func adimBittiMi(_ kayit: DersKaydi, _ adim: DersAdimi) -> Bool {
        kayit[adim].i >= 1.0 - 1e-9
    }

    /// `adimIsle(ilerleme, akim, adim, oran, bugun)`
    @discardableResult
    public static func adimIsle(
        ilerleme: inout Ilerleme,
        akim: String,
        adim: DersAdimi,
        oran: Double,
        bugun: String
    ) -> (once: DersKaydi, sonra: DersKaydi, bitti: Bool, yeniBitti: Bool) {
        let once = dersKaydi(ilerleme, akim: akim)
        let r = oran.isFinite ? sinirla(oran) : 0
        let i = max(once[adim].i, r)
        var sonraAdim = DersAdimKaydi(i: i, t: once[adim].t)
        let yeniBitti = !adimBittiMi(once, adim) && i >= 1.0 - 1e-9
        if yeniBitti { sonraAdim.t = bugun }
        var sonra = once
        sonra[adim] = sonraAdim
        var dersler = ilerleme[alan: "dersler"]?.nesne ?? .bos
        func adimJSON(_ x: DersAdimKaydi) -> JSONDeger {
            var c: [(String, JSONDeger)] = [("i", .sayi(x.i))]
            c.append(("t", x.t.map { .metin($0) } ?? .bos))
            return .nesne(SiraliNesne(c))
        }
        dersler = dersler.ayarlandi(akim, .nesne(SiraliNesne([
            ("gor", adimJSON(sonra.gor)),
            ("ogren", adimJSON(sonra.ogren)),
            ("ayirt", adimJSON(sonra.ayirt)),
        ])))
        ilerleme[alan: "dersler"] = .nesne(dersler)
        return (once, sonra, adimBittiMi(sonra, adim), yeniBitti)
    }

    /// `dersDurumu(kayit, adimlar)`
    public static func dersDurumu(_ kayit: DersKaydi, adimlar: [DersAdimi] = DersAdimi.allCases) -> DersDurumu {
        let liste = DersAdimi.allCases.filter { adimlar.contains($0) }
        let durumlar = liste.map { a in
            DersDurumu.AdimDurumu(adim: a, ad: a.ad, i: kayit[a].i, bitti: adimBittiMi(kayit, a))
        }
        let siradaki = durumlar.first { !$0.bitti }?.adim
        let biten = durumlar.filter(\.bitti).count
        return DersDurumu(adimlar: durumlar, siradaki: siradaki, biten: biten, bitti: biten == liste.count)
    }

    /// `bugununDersi({ acikAkimlar, ilerleme, yolculukAkimi, adimlar })`
    public static func bugununDersi(
        acikAkimlar: [String],
        ilerleme: Ilerleme,
        yolculukAkimi: String? = nil,
        adimlar: ((String) -> [DersAdimi])? = nil
    ) -> String? {
        func bitmedi(_ ad: String) -> Bool {
            let a = adimlar?(ad) ?? DersAdimi.allCases
            return !dersDurumu(dersKaydi(ilerleme, akim: ad), adimlar: a).bitti
        }
        if let y = yolculukAkimi, acikAkimlar.contains(y), bitmedi(y) {
            return y
        }
        return acikAkimlar.first(where: bitmedi)
    }

    /// `derslerDogrula(v)` (`js/ders.js`)
    public static func derslerDogrula(_ v: JSONDeger?) -> [String: DersKaydi] {
        guard let nesne = v?.nesne else { return [:] }
        var sonuc: [String: DersKaydi] = [:]
        for (ham, k) in nesne.ciftler {
            guard k.nesne != nil, ham.count <= 80 else { continue }
            let ad = Birlesme.akimAdi(ham)
            let eski = sonuc[ad] ?? DersKaydi()
            var yeni = DersKaydi()
            var doluAdim = false
            for a in DersAdimi.allCases {
                let x = k[a.rawValue]
                let i = (x?["i"]?.sayi).flatMap { $0.isFinite ? sinirla($0) : nil } ?? 0
                let gun = (x?["t"]?.metin).flatMap { tarihMi($0) ? $0 : nil }
                let o = eski[a]
                let enIyi = max(i, o.i)
                let gunler = [gun, o.t].compactMap { $0 }.sorted()
                if enIyi > 0 || !gunler.isEmpty {
                    doluAdim = true
                    yeni[a] = DersAdimKaydi(i: enIyi, t: (!gunler.isEmpty && enIyi >= 1.0 - 1e-9) ? gunler.first : nil)
                }
            }
            if doluAdim { sonuc[ad] = yeni }
        }
        return sonuc
    }

    // MARK: - js/dersIcerik.js

    /// `dersBul(kaynak, akim)`
    public static func dersBul(kaynak: JSONDeger?, akim: String) -> JSONDeger? {
        kaynak?["dersler"]?.dizi?.first { $0["akim"]?.metin == akim }
    }

    /// `gorPlani(ders, yuruyus, adet)`
    public static func gorPlani(ders: JSONDeger?, yuruyus: JSONDeger?, adet: Int = gorEserSiniri) -> GorPlani {
        let yuruyusEserler = yuruyus?["eserler"] ?? yuruyus
        var eserler: [GorPlani.EserKaydi] = []
        for g in ders?["gor"]?.dizi ?? [] {
            guard let sid = g["sanatci"]?.metin,
                  let gEser = g["eser"]?.metin,
                  let kayit = yuruyusEserler?[sid],
                  kayit["eser"]?.metin == gEser,
                  let noktalar = kayit["noktalar"]?.dizi,
                  !noktalar.isEmpty else { continue }
            eserler.append(.init(sanatci: sid, eser: gEser, noktaSayisi: noktalar.count))
            if eserler.count >= adet { break }
        }
        return GorPlani(eserler: eserler, toplam: eserler.reduce(0) { $0 + $1.noktaSayisi })
    }

    /// `dersAdimlari(ders, yuruyus)`
    public static func dersAdimlari(ders: JSONDeger?, yuruyus: JSONDeger?) -> [DersAdimi] {
        gorPlani(ders: ders, yuruyus: yuruyus).eserler.isEmpty ? [.ogren, .ayirt] : DersAdimi.allCases
    }

    /// `ogrenPlani(ders, { kanit, aciklama })`
    public static func ogrenPlani(
        ders: JSONDeger?,
        kanitSiniri: Int = kanitEserSiniri,
        aciklamaSiniri: Int = aciklamaSiniri
    ) -> [OgrenMaddesi] {
        (ders?["ogren"]?.dizi ?? []).map { m in
            var gorulen = Set<String>()
            var kanitlar: [OgrenMaddesi.Kanit] = []
            for a in m["kanit_adaylari"]?.dizi ?? [] {
                guard a["durum"]?.metin == dogrulandi,
                      let sanatci = a["sanatci"]?.doluMetin,
                      let eser = a["eser"]?.doluMetin else { continue }
                let qid = a["qid"]?.doluMetin
                let anahtar = a["anahtar"]?.doluMetin
                let kimlik = "\(sanatci)|\(qid ?? anahtar ?? eser)"
                guard gorulen.insert(kimlik).inserted else { continue }
                if kanitlar.count < kanitSiniri {
                    kanitlar.append(.init(
                        sanatci: sanatci,
                        eser: eser,
                        qid: qid,
                        anahtar: anahtar,
                        yer: a["yer"]?.metin ?? "",
                        cumle: a["cumle"]?.metin ?? "",
                        id: a["id"]?.metin ?? ""
                    ))
                }
            }
            let aciklamalar: [OgrenMaddesi.Aciklama] = (m["genel_adaylar"]?.dizi ?? [])
                .filter { $0["durum"]?.metin == dogrulandi }
                .prefix(aciklamaSiniri)
                .map { a in
                    .init(
                        sanatci: a["sanatci"]?.doluMetin,
                        yer: a["yer"]?.metin ?? "",
                        cumle: a["cumle"]?.metin ?? "",
                        id: a["id"]?.metin ?? ""
                    )
                }
            return OgrenMaddesi(
                no: m["no"]?.tamSayi ?? 0,
                madde: m["madde"]?.metin ?? "",
                kanitlar: kanitlar,
                aciklamalar: aciklamalar
            )
        }
    }

    /// `ayirtPlani(ders, { gorunur, acik, maddeler })`
    public static func ayirtPlani(
        ders: JSONDeger?,
        gorunur: Set<String>? = nil,
        acik: Set<String>? = nil,
        maddeler: (String) -> [String] = { _ in [] }
    ) -> [AyirtIkilisi] {
        let akim = ders?["akim"]?.metin ?? ""
        let l: [AyirtIkilisi] = (ders?["ayirt"]?.dizi ?? []).compactMap { c in
            guard let komsu = c["komsu"]?.metin,
                  gorunur == nil || gorunur!.contains(komsu),
                  let kendiDizi = c["eserler"]?["kendi"]?.dizi,
                  let komsuDizi = c["eserler"]?["komsu"]?.dizi else { return nil }
            let kendi = kendiDizi.compactMap(DersEserRef.init(json:))
            let karsi = komsuDizi.compactMap(DersEserRef.init(json:))
            guard !kendi.isEmpty, !karsi.isEmpty else { return nil }
            let cumleler: [AyirtIkilisi.Cumle] = (c["karsilastirma_cumleleri"]?.dizi ?? []).map { x in
                .init(kaynak: x["kaynak"]?.metin, cumle: x["cumle"]?.metin ?? "")
            }
            return AyirtIkilisi(
                komsu: komsu,
                acik: acik == nil || acik!.contains(komsu),
                cumleler: cumleler,
                kendi: kendi,
                karsi: karsi,
                kendiMaddeler: maddeler(akim),
                komsuMaddeler: maddeler(komsu)
            )
        }
        return l.filter(\.acik) + l.filter { !$0.acik }
    }

    /// `eserEslestir(eserler, sid, ref)`
    public static func eserEslestir(_ eserler: [Eser], sid: String, ref: DersEserRef) -> Eser? {
        let baslik = (ref.baslik?.isEmpty == false ? ref.baslik : ref.eser) ?? ""
        let gorselli = eserler.filter { !$0.gorseller.isEmpty }
        if let qid = ref.qid, !qid.isEmpty, let e = gorselli.first(where: { $0.qid == qid }) {
            return e
        }
        if let a = ref.anahtar, !a.isEmpty, let e = gorselli.first(where: { $0.qid == a || "\(sid)|\($0.baslik)" == a }) {
            return e
        }
        if !baslik.isEmpty, let e = gorselli.first(where: { $0.baslik == baslik || $0.ad == baslik }) {
            return e
        }
        return nil
    }

    /// `adimOrani(gorulen, toplam)`
    public static func adimOrani(gorulen: Int, toplam: Int) -> Double {
        toplam > 0 ? min(1, max(0, Double(gorulen) / Double(toplam))) : 0
    }

    /// `kalinanYer(i, toplam)`
    public static func kalinanYer(i: Double, toplam: Int) -> Int {
        guard toplam > 0, i > 0, i < 1.0 - 1e-9 else { return 0 }
        return min(toplam - 1, Int((i * Double(toplam)).rounded()))
    }

    /// `dersHali(durum)`
    public static func dersHali(_ durum: DersDurumu) -> DersHali {
        if durum.bitti { return .bitti }
        return durum.adimlar.contains { $0.i > 0 } ? .suruyor : .sirada
    }

    // MARK: - js/bolum.js (harita bölümleri ve yolculukAkimi)

    /// `bolumleriKur(akimlar, sanatcilar)` (`js/bolum.js`)
    public static func bolumleriKur(akimlar: [Akim], sanatcilar: [Sanatci]) -> [HaritaBolumu] {
        struct Kume { var konular: [Int] = []; var sanatcilar: [String] = [] }
        struct AkimKumesi {
            let a: Akim
            let uyeler: [Sanatci]
            let kumeler: [Kume]
            let birlesenler: [(kaynak: String, liste: [Sanatci])]
        }

        let siraliAkimlar = akimlar.enumerated()
            .sorted { $0.element.sira != $1.element.sira ? $0.element.sira < $1.element.sira : $0.offset < $1.offset }
            .map(\.element)

        var akimKumeleri: [AkimKumesi] = []
        for a in siraliAkimlar {
            let uyeler = sanatcilar.filter { $0.akim == a.ad }
            var konuHarita: [Int: [Sanatci]] = [:]
            for s in uyeler where s.birlesen == nil {
                if let k = s.konu { konuHarita[k, default: []].append(s) }
            }
            var kumeler: [Kume] = []
            var kume = Kume()
            for k in konuHarita.keys.sorted() {
                kume.konular.append(k)
                let sirali = (konuHarita[k] ?? []).enumerated().sorted {
                    let da = $0.element.dogum ?? 0, db = $1.element.dogum ?? 0
                    return da != db ? da < db : $0.offset < $1.offset
                }.map(\.element.id)
                kume.sanatcilar.append(contentsOf: sirali)
                if kume.sanatcilar.count >= kumeEnAz {
                    kumeler.append(kume)
                    kume = Kume()
                }
            }
            if !kume.sanatcilar.isEmpty {
                if !kumeler.isEmpty {
                    kumeler[kumeler.count - 1].konular.append(contentsOf: kume.konular)
                    kumeler[kumeler.count - 1].sanatcilar.append(contentsOf: kume.sanatcilar)
                } else {
                    kumeler.append(kume)
                }
            }
            var birlesenSirali: [String] = []
            var birlesenHarita: [String: [Sanatci]] = [:]
            for s in uyeler {
                guard let b = s.birlesen else { continue }
                if birlesenHarita[b] == nil { birlesenSirali.append(b) }
                birlesenHarita[b, default: []].append(s)
            }
            let birlesenler = birlesenSirali.map { ($0, birlesenHarita[$0] ?? []) }
            akimKumeleri.append(AkimKumesi(a: a, uyeler: uyeler, kumeler: kumeler, birlesenler: birlesenler))
        }

        let boylar = akimKumeleri.flatMap { $0.kumeler.map(\.sanatcilar.count) }
        let ortalama = boylar.isEmpty ? kumeEnAz : Int((Double(boylar.reduce(0, +)) / Double(boylar.count)).rounded())

        func siraMetni(_ s: Double) -> String {
            s.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(s)) : String(s)
        }

        var sonuc: [HaritaBolumu] = []
        for ak in akimKumeleri {
            var ekler: [(kaynak: String, kume: Kume)] = []
            for (kaynak, l) in ak.birlesenler {
                let kendi = ak.uyeler.filter { $0.birlesen == nil }.enumerated().sorted {
                    let da = $0.element.dogum ?? 0, db = $1.element.dogum ?? 0
                    return da != db ? da > db : $0.offset < $1.offset
                }.map(\.element)
                let ekKendi = kendi.prefix(max(0, ortalama - l.count))
                let tum = (l + ekKendi).enumerated().sorted {
                    let da = $0.element.dogum ?? 0, db = $1.element.dogum ?? 0
                    return da != db ? da < db : $0.offset < $1.offset
                }.map(\.element)
                let konular = Array(Set(tum.compactMap(\.konu))).sorted()
                ekler.append((kaynak, Kume(konular: konular, sanatcilar: tum.map(\.id))))
            }
            let adet = ak.kumeler.count + ekler.count
            let sm = siraMetni(ak.a.sira)
            for (i, k) in ak.kumeler.enumerated() {
                sonuc.append(HaritaBolumu(
                    id: "\(sm)-\(i + 1)",
                    akim: ak.a.ad,
                    sira: ak.a.sira,
                    no: i + 1,
                    adet: adet,
                    konular: k.konular,
                    sanatcilar: k.sanatcilar
                ))
            }
            for (i, ek) in ekler.enumerated() {
                let no = ak.kumeler.count + i + 1
                sonuc.append(HaritaBolumu(
                    id: birlesenDuraklar[ek.kaynak] ?? "\(sm)-\(no)",
                    akim: ak.a.ad,
                    sira: ak.a.sira,
                    no: no,
                    adet: adet,
                    konular: ek.kume.konular,
                    sanatcilar: ek.kume.sanatcilar
                ))
            }
        }
        return sonuc
    }

    /// `bolumDurumlari(bolumler, ilerleme, islenen, harita, dersBitti)` (`js/bolum.js`)
    public static func bolumDurumlari(
        bolumler: [HaritaBolumu],
        ilerleme: Ilerleme,
        harita: [String: Sanatci],
        dersBitti: ((String) -> Bool?)? = nil
    ) -> (durumlar: [HaritaBolumDurumu], simdiki: String?) {
        let k = ilerleme.islenenKume
        let bolumKayitlari = ilerleme[alan: "bolumler"]?.nesne
        func kayitVarMi(_ id: String) -> Bool {
            guard let n = bolumKayitlari?[id]?.nesne else { return false }
            return n.count > 0
        }
        func gectiMi(_ id: String, _ sv: String) -> Bool {
            (bolumKayitlari?[id]?[sv]?.sayi ?? 0) >= bolumGecme
        }
        let oynanan = Set(bolumler.filter { kayitVarMi($0.id) }.map(\.akim))
        func dersAcik(_ akim: String) -> Bool {
            guard let dersBitti else { return true }
            if oynanan.contains(akim) { return true }
            return dersBitti(akim) != false
        }

        var durumlar: [HaritaBolumDurumu] = []
        var oncekiAkim: (akim: String, gecen: Int, toplam: Int)? = nil
        var akimDurum: (akim: String, gecen: Int, toplam: Int)? = nil

        for b in bolumler {
            let eksikKonular = Array(Set(b.sanatcilar.compactMap { harita[$0] }.filter { s in
                guard let konu = s.konu else { return true }
                return !k.contains(konu)
            }.compactMap(\.konu))).sorted()
            let kursAcik = eksikKonular.isEmpty && b.sanatcilar.allSatisfy { harita[$0] != nil }

            if akimDurum == nil || akimDurum?.akim != b.akim {
                if let ad = akimDurum { oncekiAkim = ad }
                akimDurum = (b.akim, 0, b.adet)
            }

            let onceki = durumlar.last
            var oyunAcik: Bool
            var neden: HaritaBolumDurumu.KilitNedeni? = nil

            if let onceki {
                if b.no > 1 {
                    oyunAcik = onceki.acik && onceki.ortaGecti
                    if !oyunAcik { neden = .bolum(id: onceki.id) }
                } else if let oa = oncekiAkim {
                    let gereken = Int(ceil(Double(oa.toplam) * akimGecme - 1e-9))
                    oyunAcik = oa.gecen >= gereken
                    if !oyunAcik { neden = .akim(ad: oa.akim, gecen: oa.gecen, gereken: gereken) }
                } else {
                    oyunAcik = true
                }
            } else {
                oyunAcik = true
            }

            if oyunAcik && !dersAcik(b.akim) {
                oyunAcik = false
                neden = .ders(akim: b.akim)
            }
            if !kursAcik {
                neden = .kurs(konu: eksikKonular.first)
            }

            let acik = kursAcik && oyunAcik
            let kolayGecti = acik && gectiMi(b.id, "kolay")
            let ortaGecti = acik && gectiMi(b.id, "orta")
            let zorGecti = acik && gectiMi(b.id, "zor")
            if ortaGecti { akimDurum?.gecen += 1 }
            let yildiz = acik ? [kolayGecti, ortaGecti, zorGecti].filter { $0 }.count : 0

            durumlar.append(HaritaBolumDurumu(
                bolum: b,
                kursAcik: kursAcik,
                acik: acik,
                neden: acik ? nil : neden,
                kolayGecti: kolayGecti,
                ortaGecti: ortaGecti,
                zorGecti: zorGecti,
                yildiz: yildiz
            ))
        }

        let aciklar = durumlar.filter(\.acik)
        let simdiki = (aciklar.first { !$0.ortaGecti } ?? aciklar.last)?.id
        return (durumlar, simdiki)
    }

    /// `kilitMetni(x, bolumler)` (`js/bolum.js`)
    public static func kilitMetni(_ durum: HaritaBolumDurumu, bolumler: [HaritaBolumu]) -> String {
        guard let n = durum.neden else { return "" }
        switch n {
        case .kurs(let konu):
            return konu.map { "Konu \($0) işlenince açılır." } ?? "Bu bölümün konusu henüz işlenmedi."
        case .ders(let akim):
            return "Çalış’taki \(akim) dersini bitirince açılır."
        case .bolum(let id):
            let ad = bolumler.first { $0.id == id }?.bolumAdi ?? "Önceki bölüm"
            return "\(ad): Orta seviyeyi geçince açılır."
        case .akim(let ad, let gecen, let gereken):
            return "\(ad) akımında \(gereken) bölümün Orta'sını geçince açılır (şu an \(gecen))."
        }
    }

    // MARK: - js/ekranlar/ders.js (menü hesapları ve yazıları)

    /// Bir dönemin ders bilgisini kurar (`dersBilgisi(kaynak, akim)`)
    public static func dersBilgisi(
        kaynak: JSONDeger?,
        yuruyus: JSONDeger?,
        katalog: SiteKatalogu,
        ilerleme: Ilerleme,
        akim: String
    ) -> DersBilgisi? {
        guard let ders = dersBul(kaynak: kaynak, akim: akim) else { return nil }
        let adimlar = dersAdimlari(ders: ders, yuruyus: yuruyus)
        let gor = gorPlani(ders: ders, yuruyus: yuruyus)
        let ogren = ogrenPlani(ders: ders)
        let gorunur = Set(katalog.akimlar.map(\.ad))
        let acikAkimlar = Set(
            Kilit.akimDurumlari(katalog.akimlar, katalog.sanatcilar, islenen: ilerleme.islenenKume)
                .filter(\.acik).map(\.ad)
        )
        func maddeler(_ ad: String) -> [String] {
            (dersBul(kaynak: kaynak, akim: ad)?["ogren"]?.dizi ?? []).compactMap { $0["madde"]?.metin }
        }
        let ayirt = ayirtPlani(ders: ders, gorunur: gorunur, acik: acikAkimlar, maddeler: maddeler)
        let acik = ilerleme.acikSanatcilar(katalog.sanatcilar).filter { $0.akim == akim }
        let kayit = dersKaydi(ilerleme, akim: akim)
        let durum = dersDurumu(kayit, adimlar: adimlar)
        let kapakAdaylari = (ders["ayirt"]?.dizi?.first?["eserler"]?["kendi"]?.dizi ?? [])
            .compactMap(DersEserRef.init(json:))
        return DersBilgisi(
            akim: akim,
            adimlar: adimlar,
            gor: gor,
            ogren: ogren,
            ayirt: ayirt,
            acikSanatcilar: acik,
            kayit: kayit,
            durum: durum,
            kapakAdaylari: kapakAdaylari
        )
    }

    /// Dersin kapak eseri (`kapaklariDoldur`): `ders.ayirt[0].eserler.kendi` içindeki ilk eşleşen eser; yoksa açık ilk sanatçının `enBilinen` eseri.
    public static func dersKapakEseri(_ b: DersBilgisi, katalog: SiteKatalogu, kotuler: [String: [String]] = [:]) -> Eser? {
        for ref in b.kapakAdaylari {
            guard katalog.harita[ref.sanatci] != nil else { continue }
            if let e = eserEslestir(katalog.eserler(ref.sanatci), sid: ref.sanatci, ref: ref) {
                return e
            }
        }
        if let ilk = b.acikSanatcilar.first {
            return Temsil.enBilinen(katalog.eserler(ilk.id), kotuler: kotuler)
        }
        return nil
    }

    /// `yolculukAkimi()` (`js/ekranlar/ders.js`)
    public static func yolculukAkimi(
        katalog: SiteKatalogu,
        ilerleme: Ilerleme,
        kaynak: JSONDeger?,
        yuruyus: JSONDeger?
    ) -> String? {
        let bolumler = bolumleriKur(akimlar: katalog.akimlar, sanatcilar: katalog.sanatcilar)
        var adimHarita: [String: [DersAdimi]]? = nil
        if let dersler = kaynak?["dersler"]?.dizi {
            var m: [String: [DersAdimi]] = [:]
            for x in dersler {
                if let ad = x["akim"]?.metin {
                    m[ad] = dersAdimlari(ders: x, yuruyus: yuruyus)
                }
            }
            adimHarita = m
        }
        let y = bolumDurumlari(
            bolumler: bolumler,
            ilerleme: ilerleme,
            harita: katalog.harita,
            dersBitti: { akim in
                guard let adimHarita else { return nil }
                guard let a = adimHarita[akim] else { return true }
                return dersDurumu(dersKaydi(ilerleme, akim: akim), adimlar: a).bitti
            }
        )
        if let bekleyen = y.durumlar.first(where: {
            if case .ders = $0.neden { return true }
            return false
        }) {
            return bekleyen.akim
        }
        if let simdiki = y.simdiki, let x = y.durumlar.first(where: { $0.id == simdiki }) {
            return x.akim
        }
        return nil
    }

    /// `haritaBilgisi(b)` (`js/ekranlar/ders.js`)
    public static func haritaBilgisi(
        _ b: DersBilgisi,
        katalog: SiteKatalogu,
        ilerleme: Ilerleme,
        kaynak: JSONDeger?,
        yuruyus: JSONDeger?
    ) -> (durak: Int, kilit: String) {
        let bolumler = bolumleriKur(akimlar: katalog.akimlar, sanatcilar: katalog.sanatcilar)
        var adimHarita: [String: [DersAdimi]]? = nil
        if let dersler = kaynak?["dersler"]?.dizi {
            var m: [String: [DersAdimi]] = [:]
            for x in dersler {
                if let ad = x["akim"]?.metin {
                    m[ad] = dersAdimlari(ders: x, yuruyus: yuruyus)
                }
            }
            adimHarita = m
        }
        let l = bolumDurumlari(
            bolumler: bolumler,
            ilerleme: ilerleme,
            harita: katalog.harita,
            dersBitti: { akim in
                guard let adimHarita else { return nil }
                guard let a = adimHarita[akim] else { return true }
                return dersDurumu(dersKaydi(ilerleme, akim: akim), adimlar: a).bitti
            }
        ).durumlar.filter { $0.akim == b.akim }
        let kilit: String
        if let ilk = l.first, !ilk.acik, b.durum.bitti {
            kilit = kilitMetni(ilk, bolumler: bolumler)
        } else {
            kilit = ""
        }
        return (l.count, kilit)
    }

    /// `adimSayisi(b, adim)` (`js/ekranlar/ders.js`)
    public static func adimSayisi(_ b: DersBilgisi, _ adim: DersAdimi) -> (toplam: Int, gorulen: Int, yazi: String) {
        let i = b.kayit[adim].i
        let toplam: Int
        switch adim {
        case .gor: toplam = b.gor.toplam
        case .ogren: toplam = b.ogren.count
        case .ayirt: toplam = b.ayirt.count
        }
        let gorulen = Int((i * Double(toplam)).rounded())
        let yazi = (i > 0 && toplam > 0) ? "\(gorulen)/\(toplam)" : ""
        return (toplam, gorulen, yazi)
    }

    /// `adimAciklamasi(b, adim)` (`js/ekranlar/ders.js`)
    public static func adimAciklamasi(_ b: DersBilgisi, _ adim: DersAdimi) -> String {
        switch adim {
        case .gor: return "\(b.gor.eserler.count) eserde \(b.gor.toplam) ayrıntı"
        case .ogren: return "Nasıl tanınır? \(b.ogren.count) özellik"
        case .ayirt: return "Komşu dönemlerle \(b.ayirt.count) ikili"
        }
    }

    /// `konuAraligi(b)` (`js/ekranlar/ders.js`)
    public static func konuAraligi(_ b: DersBilgisi) -> String {
        let k = Array(Set(b.acikSanatcilar.compactMap(\.konu))).sorted()
        guard let ilk = k.first, let son = k.last else { return "" }
        return k.count > 1 ? "Konu \(ilk)–\(son)" : "Konu \(ilk)"
    }

    /// `dersKunyesi(b)`: `"7 sanatçı · Konu 3–10"`
    public static func dersKunyesi(_ b: DersBilgisi) -> String {
        ["\(b.acikSanatcilar.count) sanatçı", konuAraligi(b)].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// `davet(b)` (`js/ekranlar/ders.js`): sıradaki adımın tek cümlelik daveti
    public static func davet(
        _ b: DersBilgisi,
        harita: (durak: Int, kilit: String) = (0, "")
    ) -> (duz: String, italikMadde: String?, sonEk: String?) {
        guard let a = b.durum.siradaki else {
            if !harita.kilit.isEmpty {
                return ("Ders tamam. Haritadaki durakları: \(harita.kilit)", nil, nil)
            }
            if harita.durak > 0 {
                return ("Ders tamam. Haritada \(b.akim) durakları seni bekliyor; sınavın orada.", nil, nil)
            }
            return ("Ders tamam.", nil, nil)
        }
        switch a {
        case .gor:
            return ("Önce bak: \(adimAciklamasi(b, .gor)).", nil, nil)
        case .ogren:
            let yer = kalinanYer(i: b.kayit.ogren.i, toplam: b.ogren.count)
            guard b.ogren.indices.contains(yer) else { return ("", nil, nil) }
            let m = b.ogren[yer]
            let n = m.kanitlar.count
            let son = n > 0 ? " \(n) eserde göreceksin." : ""
            return ("Sıradaki özellik: \(m.madde).\(son)", m.madde, ".\(son)")
        case .ayirt:
            return ("Komşularından ayır: \(b.ayirt.map(\.komsu).joined(separator: ", ")).", nil, nil)
        }
    }

    /// `devamAltYazisi(b, a, say)` (`js/ekranlar/ders.js`)
    public static func devamAltYazisi(_ b: DersBilgisi, _ a: DersAdimi) -> String {
        let say = adimSayisi(b, a)
        guard !say.yazi.isEmpty else { return adimAciklamasi(b, a) }
        let birim: String
        switch a {
        case .gor: birim = "ayrıntı"
        case .ogren: birim = "özellik"
        case .ayirt: birim = "ikili"
        }
        return "\(say.gorulen) / \(say.toplam) \(birim)\(a == .gor ? " · \(b.gor.eserler.count) eser" : "")"
    }

    /// `devamDugmesi(b, test, sahne)` (`js/ekranlar/ders.js`)
    public static func devamDugmesi(_ b: DersBilgisi, sahne: Bool = true) -> (adim: DersAdimi?, baslik: String, alt: String) {
        if b.durum.siradaki == nil && !sahne {
            return (nil, "Haritaya geç", "")
        }
        let a = b.durum.siradaki ?? b.adimlar.first ?? .gor
        let bitti = b.durum.adimlar.first { $0.adim == a }?.bitti ?? false
        let suruyor = b.kayit[a].i > 0 && !bitti
        let baslik: String
        if b.durum.siradaki == nil {
            baslik = "Dersi yeniden aç"
        } else if suruyor {
            baslik = "\(a.ad) adımına devam"
        } else {
            baslik = "\(a.ad) adımını aç"
        }
        let alt: String
        if sahne {
            alt = b.durum.siradaki != nil ? devamAltYazisi(b, a) : ""
        } else {
            alt = b.durum.siradaki != nil ? adimSayisi(b, a).yazi : ""
        }
        return (a, baslik, alt)
    }
}
