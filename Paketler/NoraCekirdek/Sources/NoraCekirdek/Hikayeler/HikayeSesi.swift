// Z4b · Hikâyelerin sesi: Z4a'nın sözleşmesiyle (sanat-atlasi scripts/ses_uret.py `hikaye_parcalari`, @ 1f54a6c).
// Parçalar sırayla: başlık, alt başlık, giriş paragrafları, her bölüm için bölüm başlığı (yılsız) ve paragrafları,
// kapanış paragrafları. Eserlerin "bag" notları ve bağlantılar okunmaz. Her parça `duzgun`dan geçer (SesAnahtari.metin);
// boş olan ve daha önce geçen (aynı düzgün metin) atlanır. Kayıt: ses/Fola/<anahtar>.mp3 (+ .json kelimeler).
import Foundation

/// Okunacak bir parça
public struct HikayeParcasi: Equatable, Sendable {
    public enum Yer: Equatable, Hashable, Sendable {
        case baslik
        case altBaslik
        /// Bölümün sırası
        case bolumBasligi(Int)
        /// `SanatciHikayesi.paragraflar` içindeki yeri
        case paragraf(Int)
    }

    public var yer: Yer
    /// Verideki metin
    public var ham: String
    /// `duzgun(ham)`: kayıttaki metin (altyazı akışı bu metnin üstünde)
    public var metin: String
    /// `sha1(metin)[:16]`
    public var anahtar: String

    public var paragraf: Int? {
        if case .paragraf(let n) = yer { return n }
        return nil
    }
}

public enum HikayeSesi {
    /// `hikaye_parcalari()`: hikâyenin okunacak parçaları, sırayla
    public static func parcalar(_ h: SanatciHikayesi) -> [HikayeParcasi] {
        var adaylar: [(HikayeParcasi.Yer, String)] = [(.baslik, h.baslik), (.altBaslik, h.altBaslik)]
        var no = 0
        for p in h.giris {
            adaylar.append((.paragraf(no), p))
            no += 1
        }
        for (bi, b) in h.bolumler.enumerated() {
            adaylar.append((.bolumBasligi(bi), b.baslik))
            for p in b.paragraflar {
                adaylar.append((.paragraf(no), p))
                no += 1
            }
        }
        for p in h.kapanis {
            adaylar.append((.paragraf(no), p))
            no += 1
        }
        var gorulen = Set<String>()
        var sonuc: [HikayeParcasi] = []
        for (yer, ham) in adaylar {
            let m = SesAnahtari.metin(ham)
            guard !m.isEmpty, gorulen.insert(m).inserted else { continue }
            sonuc.append(HikayeParcasi(yer: yer, ham: ham, metin: m, anahtar: SesAnahtari.anahtar(m)))
        }
        return sonuc
    }

    /// Parçanın süresi (sn): kaydı varsa kaydın gerçek süresi, yoksa telefonun sesinin tahmini süresi
    /// (`DinlemeKurallari.okumaSuresi`, Z4a'daki gibi).
    public static func sure(_ p: HikayeParcasi, dizin: SesDizini?) -> Double {
        if let s = dizin?.parcalar[p.anahtar], s > 0 { return s }
        return DinlemeKurallari.okumaSuresi(p.metin)
    }

    public static func sureler(_ l: [HikayeParcasi], dizin: SesDizini?) -> [Double] { l.map { sure($0, dizin: dizin) } }

    /// Kaydı olan parça
    public static func kayitli(_ p: HikayeParcasi, dizin: SesDizini?) -> Bool { (dizin?.parcalar[p.anahtar] ?? 0) > 0 }

    /// Paragrafın parçası: paragrafın kendisi okunmuyorsa (aynı metin daha önce geçtiyse) sonraki ilk parça
    public static func parca(paragraf no: Int, _ l: [HikayeParcasi]) -> Int? {
        if let i = l.firstIndex(where: { $0.paragraf == no }) { return i }
        return l.firstIndex { ($0.paragraf ?? -1) > no }
    }

    /// Parçanın vurgulanacak paragrafı: paragrafsa kendisi; başlık, alt başlık, bölüm başlığı nil
    public static func paragraf(parca i: Int, _ l: [HikayeParcasi]) -> Int? {
        l.indices.contains(i) ? l[i].paragraf : nil
    }

    /// Bütün dinlemenin içindeki an (sn): `sira`. parçanın başına kadar geçen süre + parçanın içindeki an
    public static func gecen(_ sureler: [Double], sira: Int, an: Double) -> Double {
        guard !sureler.isEmpty else { return 0 }
        let s = min(max(0, sira), sureler.count - 1)
        return sureler[..<s].reduce(0, +) + min(max(0, an), sureler[s])
    }

    /// Bütün dinlemenin içindeki bir anın parçası ve parçanın içindeki an. Sondan sonrası: son parçanın sonu.
    public static func yer(_ sureler: [Double], gecen: Double) -> (sira: Int, an: Double) {
        guard !sureler.isEmpty else { return (0, 0) }
        var kalan = max(0, gecen)
        for (i, s) in sureler.enumerated() {
            if kalan < s { return (i, kalan) }
            kalan -= s
        }
        return (sureler.count - 1, sureler[sureler.count - 1])
    }

    /// ±15 sn: parça sınırlarını aşarak (geri giderken başa, ileri giderken sona dayanır)
    public static func atla(_ sureler: [Double], sira: Int, an: Double, fark: Double) -> (sira: Int, an: Double) {
        let toplam = sureler.reduce(0, +)
        let hedef = min(max(0, gecen(sureler, sira: sira, an: an) + fark), toplam)
        return yer(sureler, gecen: hedef)
    }

    /// Dinleme hızları (`1×` düğmesi sırayla dolaşır)
    public static let hizlar: [Double] = [1, 1.25, 1.5, 0.85]

    public static func sonrakiHiz(_ h: Double) -> Double {
        let i = hizlar.firstIndex { abs($0 - h) < 0.001 } ?? -1
        return hizlar[(i + 1) % hizlar.count]
    }

    /// "1×", "1,25×", "0,85×"
    public static func hizYazisi(_ h: Double) -> String {
        var s = String(format: "%.2f", h)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s.replacingOccurrences(of: ".", with: ",") + "×"
    }

    /// "4:07", "1:02:05"
    public static func saat(_ sn: Double) -> String {
        let t = max(0, Int(sn.rounded(.down)))
        let s = t / 3600, d = (t % 3600) / 60, k = t % 60
        let kk = k < 10 ? "0\(k)" : "\(k)"
        if s > 0 { return "\(s):\(d < 10 ? "0\(d)" : "\(d)"):\(kk)" }
        return "\(d):\(kk)"
    }
}
