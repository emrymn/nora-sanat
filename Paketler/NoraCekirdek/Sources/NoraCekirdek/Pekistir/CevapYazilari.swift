// Kaynak: sanat-atlasi js/ekranlar/pekistir.js (kipKisa, akimiAciklarMi, kutuSatiri, seviyeSatiri, kartGoster,
// tersGoster, konuTanismaGoster, ozetCiz), js/ekranlar/ortak.js (eserAdi), js/yardimci.js (yillarYaz) @ a866b86
import Foundation

/// Pekiştirme ekranlarının yazıları: sitedeki metinlerle aynı.
public enum CevapYazilari {
    /// Yanlış ve "bilmiyorum" cevabının notu
    public static let tekrarNotu = "bu kart 3–5 kart sonra yine gelecek"

    /// `eserAdi(e)`: "Başlık, tarih"
    public static func eserAdi(_ e: Eser) -> String { e.tarih.isEmpty ? e.gorunenAd : "\(e.gorunenAd), \(e.tarih)" }

    /// `yillarYaz(s)`
    public static func yillar(_ s: Sanatci) -> String {
        switch (s.dogum, s.olum) {
        case (nil, nil): return "tarih bilinmiyor"
        case (nil, let o?): return "ö. \(SiteYazisi.yilYaz(o))"
        case (let d?, nil): return "d. \(SiteYazisi.yilYaz(d))"
        case let (d?, o?): return d < 0 && o < 0 ? "MÖ \(-d)–\(-o)" : "\(SiteYazisi.yilYaz(d))–\(SiteYazisi.yilYaz(o))"
        }
    }

    /// `kipKisa(kip, akim)`: tur ekranlarının başlığı
    public static func kipAdi(_ kip: PekistirmeKipi) -> String {
        switch kip {
        case .kursBolumu: return "Bölüm turu"
        case .ikonografi: return "İkonografi"
        case .sanatci(.karisik): return "Karışık"
        case .sanatci(.hatalar): return "Hatalarım"
        case .sanatci(.donem(let ad)): return ad ?? "Hepsi"
        case .sanatci(.konu(let no)): return "Konu \(no)"
        case .sanatci(.bolum): return "Bölüm"
        }
    }

    /// `akimiAciklarMi(metin, akim)`: metin akımı ele veriyor mu (karışık kartta birinci sorudan sonra gizlenir)
    public static func akimiAciklarMi(_ metin: String, _ akim: String) -> Bool {
        let tr = Locale(identifier: "tr")
        let m = metin.lowercased(with: tr)
        return akim.lowercased(with: tr)
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "()")))
            .filter { $0.utf16.count >= 4 }
            .contains { m.contains(String($0.prefix(5))) }
    }

    /// Sonuç satırı: büyük yazı ve yanındaki küçük not
    public static func sonuc(dogru: Bool, bilmiyorum: Bool) -> (String, String) {
        dogru ? ("Doğru", "") : bilmiyorum ? ("Bilmiyorum", tekrarNotu) : ("Yanlış", tekrarNotu)
    }

    /// Karışık kartın ikinci sorusu (akım): akım doğru ama sanatçı yanlışsa kart yine gelir.
    public static func akimSonucu(akimDogru: Bool, sanatciDogru: Bool, bilmiyorum: Bool) -> (String, String) {
        if akimDogru { return sanatciDogru ? ("Doğru", "") : ("Doğru", "sanatçı yanlıştı, \(tekrarNotu)") }
        return bilmiyorum ? ("Bilmiyorum", tekrarNotu) : ("Yanlış", tekrarNotu)
    }

    /// İkinci sorunun notu: görünen komşu akımlar ve birinci soruda gizlenen ipucu
    public static func akimNotu(akim: String, akimlar: [Akim], ipucu: String) -> String {
        let gorunur = Set(akimlar.map(\.ad))
        let komsular = (akimlar.first { $0.ad == akim }?.komsular ?? []).filter(gorunur.contains)
        return [komsular.isEmpty ? "" : "Komşu akımlar: \(komsular.joined(separator: ", ")).",
                akimiAciklarMi(ipucu, akim) ? ipucu : ""].filter { !$0.isEmpty }.joined(separator: " ")
    }

    /// `kutuSatiri(sk)`: Leitner kutusu (altı nokta), bu cevapla ilerledi mi ve bir sonraki tekrar
    public static func kutu(_ sk: Skor?, bugun: String) -> (kutu: Int, ilerledi: Bool, yazi: String)? {
        guard let sk else { return nil }
        let kutu = max(0, min(Leitner.araliklar.count - 1, sk.kutu))
        let ilerledi = kutu > 0 && sk.sonraki == GunTarihi.ekle(bugun, Leitner.araliklar[kutu])
        let gun = sk.sonraki.flatMap { s in GunTarihi.gunNo(s).flatMap { a in GunTarihi.gunNo(bugun).map { a - $0 } } } ?? 0
        let yazi = kutu > 0 ? "\(kutu). kutu · \(gun > 0 ? "\(gun) gün sonra tekrar" : "bugün tekrar")" : "Baştan · bu turda yine gelecek"
        return (kutu, ilerledi, yazi)
    }

    /// `seviyeSatiri(k)`: dönemin seviyesi; ısınma; seviye atlandıysa kutlama. `kayit` cevaptan sonraki kayıt.
    public static func seviyeSatiri(_ r: SeviyeSonucu, akim: String, kartSeviyesi: Int?, kayit: SeviyeKaydi) -> String? {
        if r.bolum { return nil }
        if r.isinma {
            return "Isınma · \(Seviye.bul(kartSeviyesi ?? 0).ad) · \(akim) \(Seviye.bul(r.once).ad) penceresine yazılmadı"
        }
        if r.gecti { return "\(akim) \(Seviye.bul(r.sonra).ad) seviyeye geçti" }
        return "\(akim) · \(Seviye.durum(kayit))"
    }

    /// Konu tanışmasının alt notu ve ileri düğmesinin yazıları (`konuTanismaGoster`)
    public static func konuTanismasi(konu: String, son: Bool, kartSayisi: Int, sonraki: String?)
        -> (etiket: String, not: String, ust: String, ana: String) {
        (
            "Konu \(konu) · yeni sanatçı",
            son ? "Sırada bu konunun sanatçılarından \(kartSayisi) kartlık kısa bir tur var." : "Sonra bu konunun öbür yeni sanatçısı geliyor.",
            son ? "Hazırsan" : "Sıradaki sanatçı",
            son ? "Tura başla" : (sonraki ?? "Sonraki sanatçı")
        )
    }

    /// Tur özetinin italik satırı (`ozetCiz`)
    public static func ozetNotu(yanlis: Int) -> String {
        yanlis > 0 ? "Yanlış yaptıkların daha sık karşına çıkacak." : "Hepsi doğru, harika."
    }
}
