// Kaynak: sanat-atlasi js/ekranlar/ayarlar.js (devasaBilgisi, devasaGoster, devasaIndir'in d.devasaIndirme'si) @ a866b86
import Foundation

/// Bir indirme parçasının durumu (`d.devasaIndirme`). Uygulama arka planda kapanıp açılınca sürsün diye saklanır.
public struct CevrimdisiDurumu: Codable, Sendable, Equatable {
    /// Bu parçadaki dosya sayısı
    public var toplam: Int
    /// Listenin tamamı
    public var hepsi: Int
    /// Parçadan önce telefonda olanlar
    public var onceden: Int
    public var oncedenBayt: Double
    public var biten = 0
    public var bitenBayt = 0.0
    public var hata = 0
    public var yazilamadi = 0
    public var bitti = false
    public var parca: Int
    public var parcaSayisi: Int
    public var sonParca: Bool
    public var durduruldu = false
    public var yerYok = false
    public var inemedi = false
    public var parcaBitti = false
    public var sonHata: String?

    public init(_ p: CevrimdisiListe.Parca) {
        toplam = p.urller.count
        hepsi = p.hepsi
        onceden = p.onceden
        oncedenBayt = p.oncedenBayt
        parca = p.parca
        parcaSayisi = p.parcaSayisi
        sonParca = p.sonParca
    }

    public var suruyor: Bool { !bitti }

    /// Parça bitince (`devasaIndir`'in `finally`'si)
    public mutating func bitir(durduruldu d: Bool) {
        durduruldu = d
        inemedi = biten > 0 && biten == hata
        parcaBitti = !d && !yerYok && !sonParca && !inemedi
        bitti = true
    }
}

/// Ayarlar'daki "En büyük kopyaları telefona indir" bölümünün yazıları ve düğmeleri, sitedeki gibi.
public struct CevrimdisiGorunum: Sendable, Equatable {
    public enum Tur: Sendable, Equatable { case olagan, hata, tamam }

    public let bilgi: String
    public let mesaj: String
    public let mesajTuru: Tur
    public let indir: Bool
    public let indirKapali: Bool
    public let durdur: Bool
    public let sil: Bool
    /// İlerleme çubuğu (değer, en çok); yoksa nil
    public let cubuk: (deger: Double, enCok: Double)?

    public static func == (a: Self, b: Self) -> Bool {
        a.bilgi == b.bilgi && a.mesaj == b.mesaj && a.mesajTuru == b.mesajTuru && a.indir == b.indir
            && a.indirKapali == b.indirKapali && a.durdur == b.durdur && a.sil == b.sil
            && a.cubuk?.deger == b.cubuk?.deger && a.cubuk?.enCok == b.cubuk?.enCok
    }

    /// - Parameters:
    ///   - telefonda: listedekilerden telefonda olanların sayısı
    ///   - durum: bu açılıştaki indirme (yoksa nil)
    public init(liste: CevrimdisiListe, telefonda n: Int, durum i: CevrimdisiDurumu?) {
        let hepsi = liste.telefonAdresleri.count
        let nd = liste.devasaAdresleri.count
        let toplam = liste.toplamBayt
        let ne = hepsi > nd
            ? "\(nd) eserin 4096 piksele kadar en yüksek kalitedeki hali ve sayfalarda görünen 1280 ile 400 piksellik halleri (\(hepsi) dosya)"
            : "\(nd) eserin 4096 piksele kadar en yüksek kalitedeki hali"
        let hepsiVar = hepsi > 0 && n >= hepsi
        bilgi = hepsiVar
            ? "Hepsi telefonda: \(hepsi) görsel (\(ne))\(toplam > 0 ? " · \(Self.gb(toplam)) GB" : ""). Sayfalar ve görüntüleyici internet olmadan, telefondan açılır."
            : "\(ne)\(toplam > 0 ? " · toplam \(Self.gb(toplam)) GB" : ""). Telefonda: \(n) / \(hepsi). İnince sayfalar ve görüntüleyici internet olmadan, telefondan açılır. "
                + Self.indirmeNotu(liste)
        let suruyor = i?.suruyor ?? false
        indir = !(hepsiVar && !suruyor)
        indirKapali = suruyor
        durdur = suruyor
        sil = i == nil ? n > 0 : !suruyor
        guard let i else {
            mesaj = ""; mesajTuru = .olagan; cubuk = nil
            return
        }
        cubuk = (Double(i.biten), Double(i.toplam > 0 ? i.toplam : 1))
        mesajTuru = i.yerYok || i.inemedi || (i.bitti && i.hata > 0) ? .hata : i.bitti ? .tamam : .olagan
        mesaj = Self.mesaj(i, toplamBayt: toplam)
    }

    /// Sitenin "Wi-Fi’de indir. …" cümlesinin uygulamadaki karşılığı. Sitede sayfa her parçadan sonra kendini yeniler
    /// ve kapanınca indirme durur; uygulama arka planda indirir (`URLSession` arka plan oturumu).
    public static func indirmeNotu(_ liste: CevrimdisiListe) -> String {
        "Wi-Fi’de indir. ~\(gb(Double(CevrimdisiListe.parcaGorsel) * 3.3e6)) GB’lık parçalar hâlinde iner; uygulamadan çıksan da arka planda sürer. Uygulamayı kaydırıp kapatırsan bir dahaki açışında kaldığı yerden devam eder."
    }

    /// `devasaGoster`'in iletisi. Tek fark: parça bitince sitede sayfa yenilenir, burada sıradaki parça hemen başlar.
    public static func mesaj(_ i: CevrimdisiDurumu, toplamBayt toplam: Double) -> String {
        let indi = i.biten - i.hata
        let kac = toplam > 0 && i.hepsi > 0 ? " · ~\(gb(min(toplam, i.oncedenBayt + i.bitenBayt))) / \(gb(toplam)) GB" : ""
        if i.yerYok { return "Telefonda yer kalmadı: \(indi) görsel indirildi. Yer açıp yeniden bas, kaldığı yerden sürer." }
        if i.bitti && i.durduruldu { return "Durduruldu: \(indi) görsel indirildi. Yeniden basınca kaldığı yerden sürer." }
        if i.bitti && i.inemedi && i.yazilamadi > 0 {
            return "Görseller indi ama telefona kaydedilemedi (\(i.sonHata ?? "bilinmeyen hata")). Hata günlüğünü kopyalayıp gönder."
        }
        if i.bitti && i.inemedi { return "Görseller indirilemedi. İnternet bağlantını kontrol edip yeniden bas; kaldığı yerden sürer." }
        if i.bitti && i.parcaBitti {
            return "Parça \(i.parca) / \(i.parcaSayisi) bitti · telefonda \(i.onceden + indi) / \(i.hepsi). Sıradaki parça başlıyor…"
        }
        if i.bitti {
            return i.toplam > 0
                ? "Bitti: \(indi) görsel indirildi\(i.hata > 0 ? ", \(i.hata) indirilemedi (yeniden basınca tekrar denenir)" : "")."
                : "Hepsi zaten telefonda."
        }
        return "Telefonda \(i.onceden + indi) / \(i.hepsi) · Parça \(i.parca) / \(i.parcaSayisi)\(kac)"
    }

    /// Bayt → "21,0" (GB, bir ondalık; `toLocaleString('tr', …)`)
    public static func gb(_ b: Double) -> String {
        let onda = Int((b / 1e8).rounded(.toNearestOrAwayFromZero))
        let tam = onda / 10, kesir = abs(onda % 10)
        var s = String(abs(tam))
        var i = s.count - 3
        while i > 0 { s.insert(".", at: s.index(s.startIndex, offsetBy: i)); i -= 3 }
        return "\(onda < 0 ? "-" : "")\(s),\(kesir)"
    }
}

/// Z3x: Ayarlar → Çevrimdışı satırının özeti (yeni tasarım, sitede yok): "812 / 1.420 görsel · 2,4 / 4,1 GB", yüzde ve
/// 3 pt'lik ilerleme çizgisi. Sitenin uzun açıklaması (`CevrimdisiGorunum.bilgi`) kartın altında dipnot olarak kalır.
public struct CevrimdisiOzeti: Sendable, Equatable {
    /// Telefondaki görsel sayısı (indirme sürerken parçada inenler dahil)
    public let telefonda: Int
    public let hepsi: Int
    /// Telefondakilerin yaklaşık boyu (bayt); toplam bilinmiyorsa 0
    public let bayt: Double
    public let toplamBayt: Double

    public init(liste: CevrimdisiListe, telefonda n: Int, durum i: CevrimdisiDurumu?) {
        hepsi = liste.telefonAdresleri.count
        toplamBayt = liste.toplamBayt
        if let i, i.suruyor || i.bitti {
            telefonda = min(hepsi, max(n, i.onceden + i.biten - i.hata))
        } else {
            telefonda = min(hepsi, n)
        }
        if let i, i.suruyor, toplamBayt > 0 {
            bayt = min(toplamBayt, i.oncedenBayt + i.bitenBayt)
        } else {
            bayt = hepsi > 0 ? toplamBayt * Double(telefonda) / Double(hepsi) : 0
        }
    }

    /// 0…1
    public var oran: Double { hepsi > 0 ? min(1, Double(telefonda) / Double(hepsi)) : 0 }
    public var tamam: Bool { hepsi > 0 && telefonda >= hepsi }
    /// Aşağı yuvarlanır: hepsi inmeden %100 yazmaz
    public var yuzde: Int { tamam ? 100 : min(99, Int((oran * 100).rounded(.down))) }
    public var yuzdeYazisi: String { "%\(yuzde)" }

    public var altYazi: String {
        let sayi = "\(Self.binlik(telefonda)) / \(Self.binlik(hepsi)) görsel"
        guard toplamBayt > 0 else { return sayi }
        return "\(sayi) · \(CevrimdisiGorunum.gb(bayt)) / \(CevrimdisiGorunum.gb(toplamBayt)) GB"
    }

    /// 1420 → "1.420"
    public static func binlik(_ n: Int) -> String {
        var s = String(abs(n))
        var i = s.count - 3
        while i > 0 { s.insert(".", at: s.index(s.startIndex, offsetBy: i)); i -= 3 }
        return (n < 0 ? "-" : "") + s
    }
}
