// Y1 · Sesli rehberli bakış: akış planı ve süre dağılımı (sitede karşılığı yok, iPhone'a özgü).
// İçerik sitenin veri dosyalarından gelir: data/eser_ayrintilari.json (G1, js/ayrinti.js), data/yuruyus.json (G4),
// data/eser_notlari.json (js/karsilastir.js eserNotu), data/eser_hikayeleri.json (js/hikaye.js).
import Foundation

/// Kullanıcının seçtiği bakış süresi.
public enum DinlemeSuresi: Int, CaseIterable, Sendable, Identifiable {
    case uc = 3
    case bes = 5
    case on = 10

    public var id: Int { rawValue }
    public var saniye: Double { Double(rawValue) * 60 }
    public var yazi: String { "\(rawValue) dk" }
}

/// Görselin içinde bir alan; görselin en/boyuna oranla 0–1 (`x`, `y` sol üst köşe).
public struct DinlemeKutusu: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var w: Double
    public var h: Double

    public init(x: Double, y: Double, w: Double, h: Double) {
        self.x = x; self.y = y; self.w = w; self.h = h
    }

    /// İki kutunun kesişiminin birleşimine oranı (aynı ayrıntıyı iki kaynakta tanımak için).
    public func ortusme(_ o: DinlemeKutusu) -> Double {
        let iw = max(0, min(x + w, o.x + o.w) - max(x, o.x))
        let ih = max(0, min(y + h, o.y + o.h) - max(y, o.y))
        let kesisim = iw * ih
        let birlesim = w * h + o.w * o.h - kesisim
        return birlesim > 0 ? kesisim / birlesim : 0
    }

    /// `noktaOdagi`'nın beklediği biçim.
    public func nokta(ad: String = "", metin: String = "") -> AyrintiNoktasi {
        AyrintiNoktasi(ad: ad, x: x, y: y, w: w, h: h, metin: metin)
    }
}

/// Rehberin üzerinde durduğu bir ayrıntı.
public struct DinlemeNoktasi: Equatable, Sendable {
    public var ad: String
    public var metin: String
    public var kutu: DinlemeKutusu

    public init(ad: String, metin: String, kutu: DinlemeKutusu) {
        self.ad = ad; self.metin = metin; self.kutu = kutu
    }
}

/// Bir eserin dinleme için toplanmış içeriği.
public struct DinlemeKaynagi: Equatable, Sendable {
    public var baslik: String
    public var sanatci: String
    public var tarih: String
    public var notMetni: String
    /// Hikâyenin "Ne oluyor?" paragrafları (noktalardan önce okunur)
    public var olay: [String]
    /// "Ressamla bağı" ve "Gözden kaçanlar" (süre kalırsa noktalardan sonra)
    public var ek: [String]
    public var noktalar: [DinlemeNoktasi]

    public init(baslik: String, sanatci: String, tarih: String = "", notMetni: String = "",
                olay: [String] = [], ek: [String] = [], noktalar: [DinlemeNoktasi] = []) {
        self.baslik = baslik; self.sanatci = sanatci; self.tarih = tarih; self.notMetni = notMetni
        self.olay = olay; self.ek = ek; self.noktalar = noktalar
    }

    /// Künye: "Arnolfini Portresi. Jan van Eyck, 1434."
    public var kunye: String {
        let b = baslik.trimmingCharacters(in: .whitespacesAndNewlines)
        let alt = [sanatci, tarih].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }.joined(separator: ", ")
        return [b, alt].filter { !$0.isEmpty }.map(DinlemeKurallari.noktala).joined(separator: " ")
    }
}

/// Akışın bir adımı.
public struct DinlemeAdimi: Equatable, Sendable {
    public enum Tur: String, Equatable, Sendable {
        /// Tablonun tamamı, künye ve not
        case acilis
        /// Hikâyenin paragrafı; tablo üzerinde yavaş gezinerek
        case anlati
        /// Bir ayrıntıya yaklaşma
        case nokta
        /// Söz yok: yalnız bakış (süre artarsa)
        case sessiz
        /// Tablonun tamamına dönüş
        case kapanis
    }

    public var tur: Tur
    /// Ekranda metnin üstünde görünen ad (noktanın adı); yoksa ""
    public var baslik: String
    /// Okunan ve altyazıda görünen metin
    public var metin: String
    /// Kameranın hedefi; nil: tablonun tamamı
    public var kutu: DinlemeKutusu?
    /// Kameranın hedefe varış süresi (sn)
    public var yaklasma: Double
    /// Adım başladıktan sonra sözün başlaması (sn)
    public var gecikme: Double
    /// Sözün tahmini süresi (sn; sessiz seçenekte altyazının ekranda kalma süresi)
    public var konusma: Double
    /// Sözden sonraki sessizlik (sn)
    public var sessizlik: Double

    public init(tur: Tur, baslik: String = "", metin: String, kutu: DinlemeKutusu?, yaklasma: Double,
                gecikme: Double, konusma: Double, sessizlik: Double) {
        self.tur = tur; self.baslik = baslik; self.metin = metin; self.kutu = kutu
        self.yaklasma = yaklasma; self.gecikme = gecikme; self.konusma = konusma; self.sessizlik = sessizlik
    }

    /// Adımın tahmini toplam süresi: kamera ve söz birlikte yürür, ardından sessizlik.
    public var sure: Double { max(yaklasma, gecikme + konusma) + sessizlik }
}

/// Dinleme akışı.
public struct DinlemePlani: Equatable, Sendable {
    public var adimlar: [DinlemeAdimi]
    public var toplam: Double { adimlar.reduce(0) { $0 + $1.sure } }

    public init(adimlar: [DinlemeAdimi]) { self.adimlar = adimlar }

    /// `i`. adımın başladığı an (sn; Now Playing'deki geçen süre için).
    public func baslangic(_ i: Int) -> Double {
        adimlar.prefix(max(0, min(i, adimlar.count))).reduce(0) { $0 + $1.sure }
    }

    /// Akışı kurar:
    /// 1. Açılış: tablonun tamamı, künye ve not.
    /// 2. Hikâyenin "Ne oluyor?" paragrafları (süre yetiyorsa).
    /// 3. Noktalar sırayla (her biri 20–40 sn: yaklaşma, metin, kısa sessizlik). Süre yetmezse sondakiler düşer, en az bir nokta kalır.
    /// 4. Süre kalırsa hikâyenin öbür parçaları, sonra noktaların payı 40 sn'ye kadar büyür, sonra sessiz bir bakış.
    /// 5. Kapanış: tablonun tamamı.
    /// Nokta yoksa hikâye ve not okunurken kamera tablonun üzerinde yavaş gezinir.
    public static func kur(_ k: DinlemeKaynagi, sure: DinlemeSuresi) -> DinlemePlani {
        typealias K = DinlemeKurallari
        let butce = sure.saniye

        let acilisMetni = [k.kunye, K.noktala(k.notMetni)].filter { !$0.isEmpty }.joined(separator: " ")
        let acilisSozu = K.okumaSuresi(acilisMetni)
        let acilis = DinlemeAdimi(tur: .acilis, metin: acilisMetni, kutu: nil,
                                  yaklasma: K.acilisGecikmesi + acilisSozu, gecikme: K.acilisGecikmesi,
                                  konusma: acilisSozu, sessizlik: K.acilisSessizligi)
        let kapanisSozu = K.okumaSuresi(K.kapanisMetni)
        let kapanis = DinlemeAdimi(tur: .kapanis, metin: K.kapanisMetni, kutu: nil,
                                   yaklasma: K.kapanisYaklasmasi, gecikme: K.kapanisYaklasmasi,
                                   konusma: kapanisSozu, sessizlik: K.kapanisSessizligi)
        var kalan = butce - acilis.sure - kapanis.sure

        // Gezinti: noktası olmayan anlatıda kamera tablonun bölgeleri arasında yavaşça dolaşır.
        var gezinti = 0
        func anlati(_ metin: String) -> DinlemeAdimi {
            let soz = K.okumaSuresi(metin)
            let kutu = K.gezintiKutusu(gezinti)
            gezinti += 1
            return DinlemeAdimi(tur: .anlati, metin: K.noktala(metin), kutu: kutu,
                                yaklasma: K.anlatiGecikmesi + soz + K.anlatiSessizligi,
                                gecikme: K.anlatiGecikmesi, konusma: soz, sessizlik: K.anlatiSessizligi)
        }

        // Noktalar: önce sığanlar (sırayla, en az bir tane)
        var noktalar: [DinlemeAdimi] = []
        for n in k.noktalar {
            let adim = K.noktaAdimi(n)
            if adim.sure <= kalan || noktalar.isEmpty {
                noktalar.append(adim)
                kalan -= adim.sure
            } else {
                break
            }
        }

        // Olay paragrafları: noktalardan sonra kalan süreye sığanlar (sırayla)
        var olay: [DinlemeAdimi] = []
        for p in k.olay {
            let a = anlati(p)
            guard a.sure <= kalan else { break }
            olay.append(a)
            kalan -= a.sure
        }
        // Nokta yoksa en az bir anlatı (not yoksa tablo sessiz kalmasın)
        if noktalar.isEmpty, olay.isEmpty, let p = k.olay.first {
            let a = anlati(p)
            olay.append(a)
            kalan -= a.sure
        }

        // Ek parçalar (ressamla bağı, gözden kaçanlar): sığanlar
        var ek: [DinlemeAdimi] = []
        for p in k.ek {
            let a = anlati(p)
            if a.sure <= kalan {
                ek.append(a)
                kalan -= a.sure
            }
        }

        // Kalan süre noktaların yaklaşmasını uzatır (adım başına en çok 40 sn)
        if kalan > 0, !noktalar.isEmpty {
            for _ in 0..<4 where kalan > 0.5 {
                let buyuyebilen = noktalar.indices.filter { noktalar[$0].sure < K.noktaEnCok - 0.01 }
                guard !buyuyebilen.isEmpty else { break }
                let pay = kalan / Double(buyuyebilen.count)
                for i in buyuyebilen {
                    let ekle = min(pay, K.noktaEnCok - noktalar[i].sure)
                    noktalar[i].yaklasma = max(noktalar[i].yaklasma, noktalar[i].gecikme + noktalar[i].konusma)
                        + ekle
                    kalan -= ekle
                }
            }
        }

        // Yine kalırsa: söz olmadan bir süre bakış (en çok 60 sn)
        var sessiz: [DinlemeAdimi] = []
        if kalan >= K.sessizEnAz {
            let s = min(K.sessizEnCok, kalan)
            sessiz.append(DinlemeAdimi(tur: .sessiz, metin: K.sessizMetni, kutu: nil,
                                       yaklasma: s, gecikme: 0, konusma: 0, sessizlik: 0))
        }

        return DinlemePlani(adimlar: [acilis] + olay + noktalar + ek + sessiz + [kapanis])
    }
}

/// Akışın sabitleri ve yardımcıları.
public enum DinlemeKurallari {
    /// Türkçe ses, 0,9 hızda: saniyede yaklaşık 12 harf; her cümle sonunda kısa bir duraklama.
    public static let harfHizi = 12.0
    public static let cumleDuraklamasi = 0.35

    public static let acilisGecikmesi = 1.5
    public static let acilisSessizligi = 4.0
    public static let anlatiGecikmesi = 1.0
    public static let anlatiSessizligi = 3.0
    public static let noktaGecikmesi = 3.0
    public static let noktaSessizligi = 5.0
    public static let noktaEnAz = 20.0
    public static let noktaEnCok = 40.0
    public static let kapanisYaklasmasi = 3.0
    public static let kapanisSessizligi = 6.0
    public static let sessizEnAz = 15.0
    public static let sessizEnCok = 60.0

    public static let kapanisMetni = "Şimdi tablonun tamamına bir kez daha bak."
    public static let sessizMetni = "Bir süre yalnız bak."
    public static let bitisSorusu = "En çok neye baktın?"

    /// Metnin tahmini okunma süresi (sn).
    public static func okumaSuresi(_ metin: String) -> Double {
        let t = metin.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return 0 }
        let cumle = max(1, t.filter { ".!?…:".contains($0) }.count)
        return (Double(t.count) / harfHizi + Double(cumle) * cumleDuraklamasi).rounded(toPlaces: 1)
    }

    /// Sonunda noktalama yoksa nokta koyar (ses cümleyi kapatsın).
    public static func noktala(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let son = t.last else { return "" }
        return ".!?…\"”»)".contains(son) ? t : t + "."
    }

    /// Bir noktanın adımı: en az 20 sn (söz uzunsa daha uzun).
    static func noktaAdimi(_ n: DinlemeNoktasi) -> DinlemeAdimi {
        let soz = okumaSuresi(n.metin)
        let yaklasma = max(noktaEnAz - noktaSessizligi, noktaGecikmesi + soz)
        return DinlemeAdimi(tur: .nokta, baslik: n.ad, metin: noktala(n.metin), kutu: n.kutu,
                            yaklasma: yaklasma, gecikme: noktaGecikmesi, konusma: soz, sessizlik: noktaSessizligi)
    }

    /// Noktasız anlatıda kameranın sırayla dolaştığı bölgeler (tablonun %60'ı: yumuşak bir yakınlaşma).
    public static let gezintiKutulari: [DinlemeKutusu] = [
        DinlemeKutusu(x: 0.05, y: 0.05, w: 0.6, h: 0.6),
        DinlemeKutusu(x: 0.35, y: 0.35, w: 0.6, h: 0.6),
        DinlemeKutusu(x: 0.35, y: 0.05, w: 0.6, h: 0.6),
        DinlemeKutusu(x: 0.05, y: 0.35, w: 0.6, h: 0.6),
        DinlemeKutusu(x: 0.2, y: 0.2, w: 0.6, h: 0.6),
    ]

    public static func gezintiKutusu(_ i: Int) -> DinlemeKutusu {
        gezintiKutulari[((i % gezintiKutulari.count) + gezintiKutulari.count) % gezintiKutulari.count]
    }

    /// Noktaları birleştirir: önce rehberli ayrıntılar, sonra yürüyüşün ve hikâyenin noktaları.
    /// Önceki bir kaynakta aynı adlı ya da büyük ölçüde örtüşen (≥ 0,5) nokta ikinci kez alınmaz; bir kaynağın kendi
    /// noktaları olduğu gibi kalır (rehber aynı yere iki kez, farklı bir şey için dönebilir).
    public static func noktalariBirlestir(_ listeler: [[DinlemeNoktasi]]) -> [DinlemeNoktasi] {
        let tr = Locale(identifier: "tr_TR")
        var sonuc: [DinlemeNoktasi] = []
        for liste in listeler {
            let onceki = sonuc
            for n in liste {
                let ad = n.ad.lowercased(with: tr)
                let ayni = onceki.contains { $0.ad.lowercased(with: tr) == ad || $0.kutu.ortusme(n.kutu) >= 0.5 }
                if !ayni { sonuc.append(n) }
            }
        }
        return sonuc
    }

    /// `data/yuruyus.json`'da bu eserin yürüyüşü: aynı sanatçının kaydı, QID'si ya da görselinin yerel adı tutuyorsa.
    public static func yuruyusNoktalari(_ yuruyus: JSONDeger?, eser: Eser, yerelAdlar: [String]) -> [DinlemeNoktasi] {
        guard !eser.sid.isEmpty, let kayit = yuruyus?["eserler"]?[eser.sid] else { return [] }
        let qid = kayit["qid"]?.metin
        let gorsel = kayit["gorsel"]?.metin
        let tutuyor = (qid != nil && qid == eser.qid) || (gorsel.map { yerelAdlar.contains($0) } ?? false)
        guard tutuyor else { return [] }
        return (kayit["noktalar"]?.dizi ?? []).compactMap(AyrintiNoktasi.init(json:)).map {
            DinlemeNoktasi(ad: $0.ad, metin: $0.metin, kutu: DinlemeKutusu(x: $0.x, y: $0.y, w: $0.w, h: $0.h))
        }
    }

    /// Eserin dinleme içeriği: künye, not, hikâye ve bütün noktalar.
    public static func kaynak(eser: Eser, sanatci: String, notMetni: String, ayrinti: AyrintiKaydi?,
                              hikaye: HikayeKaydi?, yuruyus: [DinlemeNoktasi]) -> DinlemeKaynagi {
        func donustur(_ k: AyrintiKaydi?) -> [DinlemeNoktasi] {
            (k?.noktalar ?? []).map {
                DinlemeNoktasi(ad: $0.ad, metin: $0.metin, kutu: DinlemeKutusu(x: $0.x, y: $0.y, w: $0.w, h: $0.h))
            }
        }
        let noktalar = noktalariBirlestir([donustur(ayrinti), yuruyus, donustur(hikaye?.karakterKaydi)])
        return DinlemeKaynagi(
            baslik: eser.gorunenAd, sanatci: sanatci, tarih: eser.tarih, notMetni: notMetni,
            olay: hikaye?.olay ?? [], ek: (hikaye?.ressam ?? []) + (hikaye?.gozden ?? []),
            noktalar: noktalar)
    }
}

extension Double {
    fileprivate func rounded(toPlaces n: Int) -> Double {
        let p = pow(10.0, Double(n))
        return (self * p).rounded() / p
    }
}
