// Kaynak: sanat-atlasi @ a866b86 (site 1.90.3)
//  - js/ekranlar/ortak.js: SEKMELER, SEKME_IKONU, sekmeleriCiz, sekmeRozeti, sekmeSurukle
//  - js/ekranlar/hizliAyar.js: hızlı ayarlar dili ve yaprağı (Tema, Hareket, Günlük kart ±5, 5…100)
//  - js/tasarim.js: YOLLAR (simgeler), ikon()
//  - css/app.css: .sekmeler, .sekme-isaret, .sekme-rozet, .hizli-dil, .hizli-yaprak; :root --sekme-h, --sekme-alt;
//    "İş 190 · Sekme çubuğu tuvaldeki gibi" (#sekmeler)
// Yerli sekme çubuğunun (T4) siteden alınan kuralları: hangi sekmeler, hangi simgeler, nerede durur.
// Kâhin: Testler/kahin/sekme_cubugu.mjs → Ornekler/sekme_cubugu/cevaplar.json (sitenin çubuğunun ölçülen yerleri,
// simgelerin sınır kutuları, hızlı ayar seçenekleri).
import Foundation

public enum SekmeCubugu {
    /// Uygulamanın çubuğundaki sekmeler, sırasıyla. Z4f (Emre'nin isteği): Bugün · Hikâyeler · Yolculuk · Çalış · Galeri
    /// (Z4b'de Bugün · Hikâyeler · Çalış · Galeri · Yolculuk idi).
    /// Sitenin çubuğu (`SEKMELER`) dört sekme ve başka sırada: `siteSekmeleri`. Ben çubukta değil (ana ekranların sağ
    /// üstündeki kişi düğmesi).
    public static let sekmeler: [Sekme] = [.bugun, .hikayeler, .yolculuk, .calis, .galeri]

    /// Sitenin çubuğundaki sekmeler, sırasıyla (`SEKMELER`); kâhinin ölçtüğü yerleşim bu dördüyle
    public static let siteSekmeleri: [Sekme] = [.bugun, .yolculuk, .galeri, .calis]

    /// Seçili uygulama sekmesinin çubuktaki yeri. Ben (İlerleme, Ayarlar) sitede Bugün seçili görünür.
    public static func sira(_ s: Sekme) -> Int { sekmeler.firstIndex(of: s) ?? 0 }

    // MARK: Simgeler

    /// `ikon(ad, 22, 1.5)`: 24'lük viewBox, çizgi; seçili sekmede çizgi 1.7
    public enum Simge: String, CaseIterable, Sendable {
        case bugun = "sekme-bugun"
        case yolculuk = "sekme-harita"
        case galeri = "sekme-gozat"
        case calis = "firca"          // SEKME_IKONU: Çalış'ın simgesi fırça (1.80.0)
        case ayarlar = "ayarlar"      // hızlı ayar dili
        case eksi = "eksi"
        case arti = "arti"
        case ileri = "ileri"
        /// Z4b: Hikâyeler (sitede yok; Neon'un tasarımındaki açık kitap, hikayeler-3/hikaye-verisi.js `IKONLAR`)
        case hikayeler = "hikayeler"

        /// js/tasarim.js `YOLLAR[ad]`, olduğu gibi
        public var isaretleme: String {
            switch self {
            case .bugun:
                return #"<rect x="4" y="3.5" width="16" height="17" rx="1.5"/><rect x="7.5" y="7" width="9" height="10"/>"#
            case .yolculuk:
                return #"<path d="M6 20c0-4 12-4 12-8s-12-4-12-8"/><circle cx="6" cy="20" r="1.4"/><circle cx="6" cy="4" r="1.4"/>"#
            case .galeri:
                return #"<rect x="3.5" y="4" width="7.5" height="9"/><rect x="13.5" y="4" width="7" height="5.5"/><rect x="13.5" y="12" width="7" height="8"/><rect x="3.5" y="15.5" width="7.5" height="4.5"/>"#
            case .calis:
                return #"<path d="M20 4l-9 9"/><path d="M11 13c-2.2-.6-4.6.8-5 3.2-.2 1.4-.9 2.4-2.5 3 3.4 1.2 8.3.3 9-3.4.2-1-.4-2.1-1.500-2.800z"/>"#
            case .ayarlar:
                return #"<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>"#
            case .eksi: return #"<path d="M5 12h14"/>"#
            case .arti: return #"<path d="M12 5v14M5 12h14"/>"#
            case .ileri: return #"<path d="m9 18 6-6-6-6"/>"#
            case .hikayeler:
                return #"<path d="M4.5 6.5c2.5-1.2 5-.8 7.5 1 2.5-1.8 5-2.2 7.5-1v11.8c-2.5-1.1-5-.7-7.5 1-2.5-1.7-5-2.1-7.5-1Z"/><path d="M12 7.5v11.8"/>"#
            }
        }

        public var komutlar: [YolKomutu] { SVGYolu.komutlar(isaretleme: isaretleme) }

        public init(_ s: Sekme) {
            switch s {
            case .bugun, .ben: self = .bugun
            case .hikayeler: self = .hikayeler
            case .yolculuk: self = .yolculuk
            case .galeri: self = .galeri
            case .calis: self = .calis
            }
        }
    }

    // MARK: Ölçüler (css/app.css)

    public enum Olcu {
        /// --sekme-h
        public static let yukseklik: Double = 62
        /// --sekme-pad
        public static let ic: Double = 6
        /// 1px kenar
        public static let kenar: Double = 1
        /// left/right: env(safe-area-inset-*) + 14px
        public static let yan: Double = 14
        /// --sekme-alt: max(12px, env(safe-area-inset-bottom))
        public static let enAzAlt: Double = 12
        public static let enGenis: Double = 520
        /// Simge 22, çizgi 1.5 (seçili 1.7); simge ile ad arası 3; ad 600 11px/1.2 Archivo
        public static let simge: Double = 22
        public static let simgeCizgi: Double = 1.5
        public static let seciliCizgi: Double = 1.7
        public static let simgeAra: Double = 3
        public static let yazi: Double = 11
        /// Hızlı ayar dili: 58×28, ekranın ortasında; çubuğun üst kenarına 8 binmiş
        public static let dilGenislik: Double = 58
        public static let dilYukseklik: Double = 28
        public static let dilBindirme: Double = 8
        public static let dilSimge: Double = 17
        /// Rozet: üstten 3, sekmenin ortasının 6 sağında; 18 yüksek, en az 18 geniş, iç 0 5
        public static let rozetUst: Double = 3
        public static let rozetSag: Double = 6
        public static let rozet: Double = 18
        /// Hızlı ayar yaprağı: çubukla aynı genişlikte, alt kenarı çubuğun ortasında; üst köşeler 28
        public static let yaprakKose: Double = 28
    }

    /// Ekranda bir dikdörtgen (sol üst köşe)
    public struct Kutu: Equatable, Sendable, Codable {
        public var x: Double, y: Double, genislik: Double, yukseklik: Double
        public init(x: Double, y: Double, genislik: Double, yukseklik: Double) {
            self.x = x; self.y = y; self.genislik = genislik; self.yukseklik = yukseklik
        }
        public var ortaX: Double { x + genislik / 2 }
    }

    /// Çubuğun ve parçalarının ekrandaki yeri (sitenin CSS'iyle aynı hesap)
    public struct Yerlesim: Equatable, Sendable {
        public var cubuk: Kutu
        /// Seçili sekmenin hapı ve sekmelerin dokunma alanı (sırayla)
        public var sekmeler: [Kutu]
        public var dil: Kutu
        /// Çubuğun alttan uzaklığı (--sekme-alt)
        public var alt: Double

        /// Çalış rozetinin sekmesi
        public var rozetSira: Int

        /// `sayi`: çubuktaki sekme sayısı (kâhin sitenin dördüyle sınar); `rozetSira`: Çalış'ın yeri
        public init(ekranGenisligi g: Double, ekranYuksekligi h: Double,
                    solGuvenli: Double = 0, sagGuvenli: Double = 0, altGuvenli: Double = 0,
                    sayi: Int = SekmeCubugu.sekmeler.count, rozetSira: Int = SekmeCubugu.sira(.calis)) {
            self.rozetSira = rozetSira
            alt = max(Olcu.enAzAlt, altGuvenli)
            let sol = solGuvenli + Olcu.yan, sag = sagGuvenli + Olcu.yan
            let alan = max(0, g - sol - sag)
            let gen = min(Olcu.enGenis, alan)
            cubuk = Kutu(x: sol + (alan - gen) / 2, y: h - alt - Olcu.yukseklik, genislik: gen, yukseklik: Olcu.yukseklik)
            let ic = Olcu.kenar + Olcu.ic
            let n = Double(max(1, sayi))
            let sg = (gen - 2 * ic) / n
            let c = cubuk
            sekmeler = (0..<max(1, sayi)).map {
                Kutu(x: c.x + ic + Double($0) * sg, y: c.y + ic, genislik: sg, yukseklik: Olcu.yukseklik - 2 * ic)
            }
            // left: 50% (ekranın ortası, çubuğun değil)
            dil = Kutu(x: g / 2 - Olcu.dilGenislik / 2,
                       y: h - (alt + Olcu.yukseklik - Olcu.dilBindirme) - Olcu.dilYukseklik,
                       genislik: Olcu.dilGenislik, yukseklik: Olcu.dilYukseklik)
        }

        /// Çalış rozetinin sol üst köşesi (genişliği sayıya göre değişir)
        public var rozet: Nokta {
            let s = sekmeler[min(rozetSira, sekmeler.count - 1)]
            return Nokta(s.ortaX + Olcu.rozetSag, s.y + Olcu.rozetUst)
        }

        /// Simgenin sol üst köşesi: simge + 3 + ad (11 × 1.2) sütunu sekmenin ortasında
        public func simge(_ i: Int) -> Nokta {
            let s = sekmeler[i]
            let sutun = Olcu.simge + Olcu.simgeAra + Olcu.yazi * 1.2
            return Nokta(s.ortaX - Olcu.simge / 2, s.y + (s.yukseklik - sutun) / 2)
        }

        /// `sekmeSurukle` `sekmeAt`: parmağın altındaki (ortası en yakın) sekme
        public func enYakin(_ x: Double) -> Int {
            var en = 0, fark = Double.infinity
            for (i, s) in sekmeler.enumerated() where abs(s.ortaX - x) < fark {
                fark = abs(s.ortaX - x)
                en = i
            }
            return en
        }

        /// Sürüklerken hapın yeri (sekme cinsinden, kesirli): `--surukle`
        public func surukle(_ x: Double) -> Double {
            let n = Double(sekmeler.count)
            return max(0, min(n - 1, (x - cubuk.x) / cubuk.genislik * n - 0.5))
        }

        /// Kalkışta dokunuş çubuğa sayılır mı: çubuğun 24 px yakınında (İş 71)
        public func yakin(_ x: Double, _ y: Double) -> Bool {
            x >= cubuk.x - 24 && x <= cubuk.x + cubuk.genislik + 24 && y >= cubuk.y - 24 && y <= cubuk.y + cubuk.yukseklik + 24
        }
    }

    /// Sürüklemenin başladığı sayılan kayma (px)
    public static let suruklemeEsigi: Double = 8

    /// Rozet yazısı (`sekmeRozeti`): 0 ve altı rozet yok
    public static func rozet(_ n: Int) -> String? { n > 0 ? String(n) : nil }
}

/// js/ekranlar/hizliAyar.js: çubuğun üstündeki dişli dilden açılan yaprak
public enum HizliAyar {
    /// js/depo.js TEMALAR, ortak.js TEMA_AD
    public static let temalar: [(String, String)] = [("gece", "Gece"), ("gunduz", "Gündüz")]
    /// js/depo.js HAREKETLER, HAREKET_AD
    public static let hareketler: [(String, String)] = [("tam", "Tam"), ("sade", "Sade"), ("kapali", "Kapalı")]
    /// Günlük kart düğmeleri ±5
    public static let kartAdimi = 5

    /// `a.gunlukKart = Math.min(100, Math.max(5, a.gunlukKart + adim))`
    public static func gunlukKart(_ mevcut: Int, _ adim: Int) -> Int { min(100, max(5, mevcut + adim)) }

    /// Ayarlar'ın kendi sayfasında dil görünmez (`dil.hidden = location.hash === '#/ayarlar'`)
    public static func dilGorunur(adres: String) -> Bool { adres != "#/ayarlar" }
}
