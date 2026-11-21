// Kaynak: sanat-atlasi js/oturum.js, js/leitner.js, js/ekranlar/pekistir.js @ a866b86
import Foundation

public struct PekistirmeOturumu: Codable {
    public struct Kart: Equatable, Codable {
        public let id: String
        public let tekrar: Bool
    }

    public private(set) var kuyruk: [Kart]
    public private(set) var konum = 0
    public private(set) var dogru = 0
    public private(set) var yanlis = 0
    public private(set) var ilkDogru = 0
    public private(set) var ilkToplam = 0
    public var simdiki: Kart? { kuyruk.indices.contains(konum) ? kuyruk[konum] : nil }
    private var tekrarlar: [String: Int] = [:]

    public init(_ kartlar: [String]) {
        kuyruk = kartlar.map { Kart(id: $0, tekrar: false) }
    }

    /// Cevap ve ilerleme tek adımdır. Bitmiş oturuma cevap verilmesi etkisizdir.
    public mutating func ilerle(dogruMu: Bool, rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) {
        guard let kart = simdiki else { return }
        if !kart.tekrar {
            ilkToplam += 1
            if dogruMu { ilkDogru += 1 }
        }
        if dogruMu {
            dogru += 1
        } else {
            yanlis += 1
            if tekrarlar[kart.id, default: 0] < 3 {
                tekrarlar[kart.id, default: 0] += 1
                let yer = min(kuyruk.count, konum + 1 + Leitner.tekrarAraligi(rastgele()))
                kuyruk.insert(Kart(id: kart.id, tekrar: true), at: yer)
            }
        }
        konum += 1
    }

    /// Eseri bulunamayan kartı skora yazmadan çıkarır.
    public mutating func simdikiniAtla() {
        if simdiki != nil { kuyruk.remove(at: konum) }
    }

    public enum KartCevabi {
        /// Sanatçı sorusu veya ters kart. nil “bilmiyorum” cevabıdır.
        case sanatci(String?)
        /// Karışık turdaki iki sorunun cevapları.
        case karisik(sanatci: String?, akim: String?)
    }

    /// Tamamlanan kartı T2'nin ilerleme modeline işler. Tekrar yazmayı önlemek için
    /// çağıran taraf ekranda gösterdiği konumu gönderir.
    @discardableResult
    public mutating func cevapla(konum beklenen: Int, sanatci: Sanatci, tur: PekistirmeTuru,
                                 cevap: KartCevabi, seciliSeviye: Int? = nil, bugun: String,
                                 ilerleme: inout Ilerleme,
                                 rastgele: PekistirmeRastgele = { Double.random(in: 0..<1) }) -> Bool {
        guard konum == beklenen, simdiki?.id == sanatci.id else { return false }
        if case .karisik = cevap, tur != .karisik { return false }
        let id = sanatci.id
        let secilen: String?
        var skor = ilerleme.skorlar[id] ?? SkorKaydi()
        var gun = ilerleme.gunlukGuncelle(bugun: bugun)
        let goruldu = Leitner.goruldu(skor.sanatci) || (tur == .karisik && Leitner.goruldu(skor.akim))
        var kartDogru = true
        switch cevap {
        case let .sanatci(s): secilen = s
        case let .karisik(s, a):
            secilen = s
            kartDogru = a == sanatci.akim
            skor.akim = Leitner.cevapla(skor.akim, dogru: kartDogru, bugun: bugun)
        }
        let dogru = secilen == id
        kartDogru = kartDogru && dogru
        switch tur {
        case .konu, .bolum: break
        default:
            if !goruldu && !gun.yeniIdler.contains(id) {
                gun.yeniIdler.append(id)
                gun.yeni += 1
            }
        }
        skor.sanatci = Leitner.cevapla(skor.sanatci, dogru: dogru, bugun: bugun)
        ilerleme.skorlar[id] = skor
        if let secilen, !dogru {
            _ = Ogrenme.ekle(&ilerleme.karisanlar, dogruId: id, secilenId: secilen, tarih: bugun)
        }
        if case .bolum = tur {
            // Bölüm turu dönemin seviye penceresine yazılmaz.
        } else if Seviye.pencereyeYazilir(Seviye.kayit(ilerleme.seviyeler, sanatci.akim), kartSeviyesi: seciliSeviye) {
            let sonuc: Seviye.Cevap = secilen == nil ? .bilmiyorum : (dogru ? .dogru : .yanlis)
            _ = Seviye.isle(&ilerleme.seviyeler, akim: sanatci.akim, sonuc)
        }
        ilerleme.sonCalisilanEkle(id)
        gun.kart += 1
        ilerleme.gunluk = gun
        ilerleme.gecmisEkle(tarih: bugun, dogru: kartDogru, akim: sanatci.akim)
        ilerle(dogruMu: kartDogru, rastgele: rastgele)
        return true
    }
}
