// Z4e · Hikâyeler 4. tur (Emre: "öne çıkanlar kısmı olsun, devam et kısmı olsun, … arşiv kısmı olsun, beğenme kısmı
// falan olsun, Substack'e benzesin"). Tasarım: Neon 4. tur (dal neon/hikayeler-tasarim-4, PR #83; birleştirilmedi):
// Emre karışığı seçti: Yön 2'nin ana ekranı, Yön 1'in tam ekran çaları, Yön 2'nin çalardaki "Sıradaki" satırı.
// Ana ekran: Öne çıkanlar (en yeni, bitmemiş) · Devam et (yarım kalanlar) · Sonra oku · Tüm hikâyeler (arşiv).
// Arşiv: En yeni · Dönem (doğum yüzyılına göre) · Beğendiklerim. Beğeni ve sonra-oku telefonda (tek kullanıcı, sayaç yok).
import Foundation

/// Beğenilen ve sonra okunacak yazılar (telefonda saklanır; ilerleme kaydına girmez)
public struct HikayeKitapligi: Codable, Equatable, Sendable {
    /// Yazı → beğenildiği an
    public var begenilen: [String: Date]
    /// Yazı → listeye eklendiği an
    public var sonraOku: [String: Date]

    public init(begenilen: [String: Date] = [:], sonraOku: [String: Date] = [:]) {
        self.begenilen = begenilen
        self.sonraOku = sonraOku
    }

    public func begenildi(_ id: String) -> Bool { begenilen[id] != nil }
    public func sonradaMi(_ id: String) -> Bool { sonraOku[id] != nil }

    /// Beğeniyi aç/kapa; yeni durum
    @discardableResult
    public mutating func begen(_ id: String, tarih: Date = Date()) -> Bool {
        if begenilen.removeValue(forKey: id) != nil { return false }
        begenilen[id] = tarih
        return true
    }

    /// "Sonra oku"yu aç/kapa; yeni durum
    @discardableResult
    public mutating func sonraOkuDegistir(_ id: String, tarih: Date = Date()) -> Bool {
        if sonraOku.removeValue(forKey: id) != nil { return false }
        sonraOku[id] = tarih
        return true
    }

    /// Beğenilenler, en son beğenilen önce
    public func begenilenler(_ l: [SanatciHikayesi]) -> [SanatciHikayesi] {
        l.filter { begenilen[$0.id] != nil }.sorted { begenilen[$0.id]! > begenilen[$1.id]! }
    }

    /// Sonra okunacaklar, en son eklenen önce; bitirilen yazı listede görünmez
    public func sonraOkunacaklar(_ l: [SanatciHikayesi], yerler: [String: OkumaYeri]) -> [SanatciHikayesi] {
        l.filter { sonraOku[$0.id] != nil && yerler[$0.id]?.bitti != true }
            .sorted { sonraOku[$0.id]! > sonraOku[$1.id]! }
    }
}

public enum HikayeVitrini {
    /// "En yeni" sırası: oluşturma günü yeni olan önce; aynı günde dosyada sonra eklenen önce (hikâyeler dosyanın
    /// sonuna eklenir).
    public static func enYeni(_ l: [SanatciHikayesi]) -> [SanatciHikayesi] {
        l.enumerated()
            .sorted { a, b in
                let ga = String(a.element.olusturma.prefix(10)), gb = String(b.element.olusturma.prefix(10))
                return ga != gb ? ga > gb : a.offset > b.offset
            }
            .map(\.element)
    }

    /// Öne çıkanlar: en yeni ve bitirilmemiş yazılar (ilki büyük kartta). Popülerlik yok (tek kullanıcı).
    public static func oneCikanlar(_ l: [SanatciHikayesi], yerler: [String: OkumaYeri], enCok: Int = 5)
        -> [SanatciHikayesi] {
        Array(enYeni(l).filter { yerler[$0.id]?.bitti != true }.prefix(enCok))
    }

    /// "Yeni" etiketi alacak yazılar: son `HikayeAkisi.yeniGun` günde eklenenlerin en yeni `enCok` tanesi (hepsine
    /// "Yeni" yazınca etiket anlamını yitiriyordu).
    public static func yeniler(_ l: [SanatciHikayesi], bugun: Date = Date(), enCok: Int = 4) -> Set<String> {
        Set(enYeni(l).filter { HikayeAkisi.yeniMi($0.olusturma, bugun: bugun) }.prefix(enCok).map(\.id))
    }

    /// Devam et'teki bir yazı
    public struct Devam: Equatable, Sendable {
        public var hikaye: SanatciHikayesi
        public var yer: OkumaYeri
        /// Dinlemede kalındı (yoksa okumada)
        public var dinleme: Bool
    }

    /// Yarım kalan yazılar, en son dokunulan önce
    public static func devamEt(_ l: [SanatciHikayesi], yerler: [String: OkumaYeri], enCok: Int = 6) -> [Devam] {
        l.compactMap { h -> Devam? in
            guard let y = yerler[h.id], y.yarim else { return nil }
            return Devam(hikaye: h, yer: y, dinleme: (y.parca ?? 0) > 0)
        }
        .sorted { $0.yer.tarih > $1.yer.tarih }
        .prefix(enCok)
        .map { $0 }
    }

    /// Arşivin "Dönem" sekmesinde bir grup
    public struct DonemGrubu: Equatable, Sendable {
        /// "XV. yüzyıl" (doğum yılına göre); doğumu bilinmeyenler "Diğer"
        public var baslik: String
        public var hikayeler: [SanatciHikayesi]
    }

    /// Doğum yılına göre sıralı, doğduğu yüzyıla göre gruplu
    public static func donemler(_ l: [SanatciHikayesi], dogum: (String) -> Int?) -> [DonemGrubu] {
        let sirali = l.enumerated().sorted { a, b in
            let da = dogum(a.element.id) ?? Int.max, db = dogum(b.element.id) ?? Int.max
            return da != db ? da < db : a.offset < b.offset
        }.map(\.element)
        var gruplar: [DonemGrubu] = []
        for h in sirali {
            let b = dogum(h.id).map { "\(roma(yuzyil($0))). yüzyıl" } ?? "Diğer"
            if gruplar.last?.baslik == b { gruplar[gruplar.count - 1].hikayeler.append(h) } else {
                gruplar.append(DonemGrubu(baslik: b, hikayeler: [h]))
            }
        }
        return gruplar
    }

    /// 1267 → 13, 1300 → 13, 1301 → 14; MÖ (negatif) yıllar için de doğru yönde
    public static func yuzyil(_ yil: Int) -> Int { yil > 0 ? (yil - 1) / 100 + 1 : -((-yil - 1) / 100 + 1) }

    /// 13 → "XIII"
    public static func roma(_ n: Int) -> String {
        guard n > 0 else { return "MÖ \(roma(-n))" }
        let l: [(Int, String)] = [(1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
                                  (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
        var k = n, s = ""
        for (d, r) in l { while k >= d { s += r; k -= d } }
        return s
    }

    /// Sıradaki yazılar: "En yeni" sırasında şimdikinden sonra gelen, bitirilmemiş yazılar (sona gelince başa döner)
    public static func siradaki(_ l: [SanatciHikayesi], simdiki: String, yerler: [String: OkumaYeri], enCok: Int = 2)
        -> [SanatciHikayesi] {
        let s = enYeni(l)
        guard let i = s.firstIndex(where: { $0.id == simdiki }) else {
            return Array(s.filter { yerler[$0.id]?.bitti != true }.prefix(enCok))
        }
        let donen = s[(i + 1)...] + s[..<i]
        return Array(donen.filter { yerler[$0.id]?.bitti != true }.prefix(enCok))
    }
}

/// Tam ekran çaların bölüm işareti (ilerleme çubuğundaki çentik ve "Bölümler" listesindeki satır)
public struct HikayeBolumIsareti: Equatable, Sendable {
    /// "Giriş", bölümün başlığı ya da "Kapanış"
    public var ad: String
    /// Bölümün yılları (giriş ve kapanışta boş)
    public var yillar: String
    /// Bölümün sırası (`SanatciHikayesi.bolumler`); giriş ve kapanışta nil
    public var bolum: Int?
    public var kapanis: Bool
    /// Bölümün ilk parçası ve dinlemedeki başlangıcı (sn)
    public var parca: Int
    public var bas: Double
    public var sure: Double
}

public extension HikayeSesi {
    /// Bölüm işaretleri: giriş (başlık, alt başlık ve giriş paragrafları), her bölüm başlığıyla başlayan bölüm ve
    /// kapanış paragrafları. Süreler parça sürelerinden.
    static func bolumIsaretleri(_ h: SanatciHikayesi, parcalar: [HikayeParcasi], sureler: [Double])
        -> [HikayeBolumIsareti] {
        guard !parcalar.isEmpty, parcalar.count == sureler.count else { return [] }
        let kapanisBasi = h.giris.count + h.bolumler.reduce(0) { $0 + $1.paragraflar.count }
        var l: [HikayeBolumIsareti] = []
        var t = 0.0
        for (i, p) in parcalar.enumerated() {
            if i == 0 {
                if case .bolumBasligi(let b) = p.yer {
                    l.append(HikayeBolumIsareti(ad: h.bolumler[b].baslik, yillar: h.bolumler[b].yillar, bolum: b,
                                                kapanis: false, parca: 0, bas: 0, sure: 0))
                } else {
                    l.append(HikayeBolumIsareti(ad: "Giriş", yillar: "", bolum: nil, kapanis: false, parca: 0, bas: 0,
                                                sure: 0))
                }
            } else if case .bolumBasligi(let b) = p.yer {
                l.append(HikayeBolumIsareti(ad: h.bolumler[b].baslik, yillar: h.bolumler[b].yillar, bolum: b,
                                            kapanis: false, parca: i, bas: t, sure: 0))
            } else if let n = p.paragraf, n >= kapanisBasi, l.last?.kapanis != true {
                if let b = l.last?.bolum, h.bolumler[b].paragraflar.isEmpty {
                    // Paragrafsız son bölüm (Rembrandt'ın verisindeki boş "Kapanış"): iki "Kapanış" olmasın, birleşir
                    l[l.count - 1].ad = "Kapanış"
                    l[l.count - 1].yillar = ""
                    l[l.count - 1].bolum = nil
                    l[l.count - 1].kapanis = true
                } else {
                    l.append(HikayeBolumIsareti(ad: "Kapanış", yillar: "", bolum: nil, kapanis: true, parca: i, bas: t,
                                                sure: 0))
                }
            }
            t += sureler[i]
        }
        for i in l.indices { l[i].sure = (i + 1 < l.count ? l[i + 1].bas : t) - l[i].bas }
        return l
    }

    /// Dinlemedeki anın bölüm işareti (sırası)
    static func isaret(_ l: [HikayeBolumIsareti], gecen: Double) -> Int {
        l.lastIndex { $0.bas <= gecen + 0.001 } ?? 0
    }
}
