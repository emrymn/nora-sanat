// Z4b · Hikâyeler ana ekranı ve okuma yeri (yeni; sitede yok). Tasarım: Neon "Yön 2 · Substack Minimal"
// (dal neon/hikayeler-tasarim-3, PR #75): alt alta yazılar, yarım kalan en üstte ilerleme çizgisiyle; "N dk okuma ·
// N dk dinleme"; sonda bağlantılı yazılar (2–4) ve kaynaklar.
import Foundation

/// Bir yazının okuma yeri (telefonda saklanır)
public struct OkumaYeri: Codable, Equatable, Sendable {
    /// Ekranın üstündeki (en son okunan) paragraf
    public var paragraf: Int
    /// Yazının paragraf sayısı (yazı değişirse oran yine doğru kalsın)
    public var toplam: Int
    /// Sona (bağlantılı yazılara) gelindi ya da dinleme bitti
    public var bitti: Bool
    /// Dinlemede kalınan parça ve parçanın içindeki an (sn)
    public var parca: Int?
    public var an: Double?
    /// Son değişiklik
    public var tarih: Date

    public init(paragraf: Int, toplam: Int, bitti: Bool = false, parca: Int? = nil, an: Double? = nil,
                tarih: Date = Date()) {
        self.paragraf = paragraf
        self.toplam = toplam
        self.bitti = bitti
        self.parca = parca
        self.an = an
        self.tarih = tarih
    }

    /// 0…1
    public var oran: Double {
        if bitti { return 1 }
        guard toplam > 0 else { return 0 }
        return min(1, max(0, Double(paragraf) / Double(toplam)))
    }

    /// Başlanmış ama bitmemiş
    public var yarim: Bool { !bitti && (paragraf > 0 || (parca ?? 0) > 0) }
}

public enum HikayeAkisi {
    /// Dakikada okunan kelime (sessiz okuma, Türkçe uzun metin)
    public static let okumaHizi = 160.0
    /// "Yeni" etiketi: oluşturulduktan sonra bu kadar gün (başlanmamışsa)
    public static let yeniGun = 7

    /// "N dk okuma"
    public static func okumaDakikasi(kelime: Int) -> Int { max(1, Int((Double(kelime) / okumaHizi).rounded())) }

    /// "N dk dinleme" (saniyeden)
    public static func dakika(_ sn: Double) -> Int { max(1, Int((sn / 60).rounded())) }

    /// Kalan okuma (dk)
    public static func kalanDakika(okuma: Int, yer: OkumaYeri) -> Int {
        max(1, Int((Double(okuma) * (1 - yer.oran)).rounded()))
    }

    public enum Durum: Equatable, Sendable {
        case yok
        case yeni
        case yarim(kalanDk: Int)
        case okundu
    }

    /// Ana ekrandaki satırın sağ üstündeki durum
    public static func durum(_ h: SanatciHikayesi, yer: OkumaYeri?, bugun: Date = Date()) -> Durum {
        if let y = yer {
            if y.bitti { return .okundu }
            if y.yarim { return .yarim(kalanDk: kalanDakika(okuma: okumaDakikasi(kelime: h.kelime), yer: y)) }
        }
        return yeniMi(h.olusturma, bugun: bugun) ? .yeni : .yok
    }

    /// "YYYY-AA-GG" bugünden en çok `yeniGun` önceyse
    public static func yeniMi(_ olusturma: String, bugun: Date) -> Bool {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Europe/Istanbul")
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: String(olusturma.prefix(10))) else { return false }
        let fark = bugun.timeIntervalSince(d) / 86_400
        return fark >= -1 && fark < Double(yeniGun)
    }

    /// Ana ekranın sırası: yarım kalanlar en üstte (en son dokunulan önce), sonra öbürleri dosyadaki sırayla.
    public static func sirala(_ l: [SanatciHikayesi], yerler: [String: OkumaYeri]) -> [SanatciHikayesi] {
        let yarim = l.filter { yerler[$0.id]?.yarim == true }
            .sorted { (yerler[$0.id]?.tarih ?? .distantPast) > (yerler[$1.id]?.tarih ?? .distantPast) }
        let ids = Set(yarim.map(\.id))
        return yarim + l.filter { !ids.contains($0.id) }
    }

    /// Arama: sanatçı adı ya da başlık (Türkçe küçük harf, aksan duyarsız: "velazquez" → Velázquez)
    public static func ara(_ l: [SanatciHikayesi], sorgu: String, sanatciAdi: (String) -> String) -> [SanatciHikayesi] {
        let q = sade(sorgu)
        guard !q.isEmpty else { return l }
        return l.filter { sade(sanatciAdi($0.id)).contains(q) || sade($0.baslik).contains(q) || sade($0.id).contains(q) }
    }

    static func sade(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "I", with: "ı").replacingOccurrences(of: "İ", with: "i")
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
    }

    /// Bağlantılı yazılar: bağlantılardan `id`'si olan ve hikâyesi bulunanlar, verideki sırayla, en çok `enCok`.
    /// `id`'siz bağlantı, hikâyesi olmayan sanatçı, yazının kendisi ve tekrar kart olmaz.
    public static func baglantilar(_ h: SanatciHikayesi, hikayeler: Set<String>, enCok: Int = 4) -> [HikayeBaglantisi] {
        var gorulen: Set<String> = [h.id]
        var l: [HikayeBaglantisi] = []
        for b in h.baglantilar {
            guard let id = b.id, hikayeler.contains(id), gorulen.insert(id).inserted else { continue }
            l.append(b)
            if l.count == enCok { break }
        }
        return l
    }

    /// Adresin alan adı ("https://www.nga.gov/x" → "nga.gov")
    public static func alanAdi(_ adres: String) -> String {
        var h = URL(string: adres)?.host ?? adres
        if h.hasPrefix("www.") { h.removeFirst(4) }
        return h
    }

    /// Okuma yerini, ekranın üstündeki paragrafa göre günceller. Geri kaydırma yeri geri almaz (en ileri yer kalır);
    /// sona gelindiyse `bitti`.
    public static func ilerle(_ yer: OkumaYeri?, paragraf: Int, toplam: Int, sonda: Bool, tarih: Date = Date()) -> OkumaYeri {
        var y = yer ?? OkumaYeri(paragraf: 0, toplam: toplam, tarih: tarih)
        let p = min(max(0, paragraf), max(0, toplam))
        if p > y.paragraf || y.toplam != toplam {
            y.paragraf = max(p, y.toplam == toplam ? y.paragraf : 0)
            y.toplam = toplam
            y.tarih = tarih
        }
        if sonda && !y.bitti {
            y.bitti = true
            y.paragraf = toplam
            y.tarih = tarih
        }
        return y
    }

    /// Dinlemenin yerini yazar (paragraf da dinlenen paragrafa ilerler)
    public static func dinlendi(_ yer: OkumaYeri?, parca: Int, an: Double, paragraf: Int?, toplam: Int,
                                bitti: Bool = false, tarih: Date = Date()) -> OkumaYeri {
        var y = ilerle(yer, paragraf: paragraf ?? (yer?.paragraf ?? 0), toplam: toplam, sonda: bitti, tarih: tarih)
        y.parca = bitti ? nil : parca
        y.an = bitti ? nil : an
        y.tarih = tarih
        return y
    }
}
