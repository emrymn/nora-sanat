// Z4a · "Dinleyerek bak" kamerası (sitede karşılığı yok). Kaynak: nora-sanat dal neon/dinle-tasarim (PR #70, yalnız
// referans) tasarim/dinle/kamera.js (KAMERA_AYAR, cubicBezier, tabanOlcu, hedefHesapla, kameraYerlesim, kutuEkranda,
// _zamanGuncelle) ve BENIOKU.md "Swift'e aktarılacak kamera yolu ve eğri değerleri"; Yön 3'ün seçenekleri
// (yon-3.html: odakYOrani 0.42, tamYOrani 0.37, tamPay 18).
// Her şey saf fonksiyon: ekran her karede yalnız `durum(gecen:)`'i çağırır, kare başına durum saklanmaz.
import Foundation

/// Kameranın durumu: tablo koordinatında bakılan nokta (`u`, `v` 0–1), log ölçek (`z = ln s`), noktanın ekrandaki yüksekliği.
public struct KameraDurumu: Equatable, Sendable {
    public var u: Double
    public var v: Double
    public var z: Double
    public var capaY: Double

    public init(u: Double, v: Double, z: Double, capaY: Double) {
        self.u = u; self.v = v; self.z = z; self.capaY = capaY
    }

    public var olcek: Double { exp(z) }
}

/// Tablonun ekrandaki yerleşimi: tam görünümde sahneye sığan boy (`taban`), merkezden ölçek ve kayma.
public struct KameraYerlesimi: Equatable, Sendable {
    public var tabanW: Double
    public var tabanH: Double
    public var olcek: Double
    public var tx: Double
    public var ty: Double
}

/// Ekranda bir kutunun çerçevesi (ayrıntı ışığı için)
public struct EkranKutusu: Equatable, Sendable {
    public var x: Double, y: Double, w: Double, h: Double
    public var ortaX: Double { x + w / 2 }
    public var ortaY: Double { y + h / 2 }
}

public enum DinleKamerasi {
    // KAMERA_AYAR
    public static let pay = 0.56
    public static let enAzOlcek = 1.48
    public static let enCokOlcek = 2.68
    public static let anlatiOlcek = 1.24
    public static let gecisTaban = 2.8
    public static let gecisMesafe = 2.6
    public static let gecisEnAz = 2.9
    public static let gecisEnCok = 4.4
    public static let nefesTaban = 0.16
    public static let nefesMesafe = 0.62
    public static let nefesEnCok = 0.48
    public static let suzmeHizi = 0.0052
    public static let suzmeSiniri = 0.072
    public static let suzmeSalinimU = 0.0052
    public static let suzmeSalinimV = 0.0038
    /// Süzülmenin devreye girme sabiti (sn): rampa = 1 − exp(−τ / 2,2)
    public static let rampaSabiti = 2.2
    /// Hareket azaltılınca çapraz geçiş (sn)
    public static let caprazSure = 0.90
    /// Duraklatma freni (s⁻¹): zaman hızı üstel sönümle 1 → 0
    public static let fren = 6.5
    /// Yön 3
    public static let odakYOrani = 0.42
    public static let tamYOrani = 0.37
    public static let tamPay = 18.0
    /// Başlangıç ve bitişte tablonun en çok kaplayacağı yükseklik (altında yazılar ve düğmeler var; tasarımda yok,
    /// dikey tablolar başlığın altına girmesin diye)
    public static let tamEnCokYukseklik = 0.54

    public static func sinirla(_ x: Double, _ a: Double, _ b: Double) -> Double { max(a, min(b, x)) }
    static func ara(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

    // MARK: - Eğriler

    /// CSS `cubic-bezier(p1x, p1y, p2x, p2y)` (Newton-Raphson; kamera.js `cubicBezier`).
    public static func bezier(_ p1x: Double, _ p1y: Double, _ p2x: Double, _ p2y: Double, _ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        let cx = 3 * p1x, bx = 3 * (p2x - p1x) - cx, ax = 1 - cx - bx
        let cy = 3 * p1y, by = 3 * (p2y - p1y) - cy, ay = 1 - cy - by
        func ornekX(_ t: Double) -> Double { ((ax * t + bx) * t + cx) * t }
        func ornekY(_ t: Double) -> Double { ((ay * t + by) * t + cy) * t }
        func turevX(_ t: Double) -> Double { (3 * ax * t + 2 * bx) * t + cx }
        var t = x
        for _ in 0..<8 {
            let dx = ornekX(t) - x
            if abs(dx) < 1e-6 { break }
            let d = turevX(t)
            if abs(d) < 1e-6 { break }
            t = sinirla(t - dx / d, 0, 1)
        }
        return ornekY(t)
    }

    /// Konum eğrisi: yumuşak kalkış, uzun kadife varış
    public static func egriKonum(_ t: Double) -> Double { bezier(0.42, 0, 0.18, 1, t) }
    /// Ölçek eğrisi: doğal mercek hızlanması
    public static func egriOlcek(_ t: Double) -> Double { bezier(0.36, 0, 0.20, 1, t) }
    /// Hareket azaltılınca çapraz geçişin eğrisi
    public static func egriCapraz(_ t: Double) -> Double { bezier(0.4, 0, 0.2, 1, t) }

    /// Nefes zarfı: sin(π · t^0.88)^1.55 (uçlarda değer ve türev 0, tepe t ≈ 0,44)
    public static func nefes(_ t: Double) -> Double {
        let x = sinirla(t, 0, 1)
        return pow(max(0, sin(Double.pi * pow(x, 0.88))), 1.55)
    }

    /// Uzaklaşma derinliği: A = clamp(0,16 + 0,62·d, 0,16, 0,48)
    public static func nefesDerinligi(_ d: Double) -> Double {
        sinirla(nefesTaban + d * nefesMesafe, nefesTaban, nefesEnCok)
    }

    /// İki ayrıntı arası geçiş süresi: clamp(2,8 + 2,6·d, 2,9, 4,4)
    public static func gecisSuresi(_ d: Double) -> Double {
        sinirla(gecisTaban + d * gecisMesafe, gecisEnAz, gecisEnCok)
    }

    /// Adımın türüne göre geçiş süresi (kamera.js planKur `gecisSuresi`); nokta adımında mesafeye göre.
    public static func gecisSuresi(_ tur: DinlemeAdimi.Tur, mesafe d: Double) -> Double {
        switch tur {
        case .acilis: return 1.4
        case .anlati: return 3.1
        case .nokta: return gecisSuresi(d)
        case .sessiz: return 3.4
        case .kapanis: return 3.6
        }
    }

    // MARK: - Hedef

    /// Tablonun sahneye sığan boyu (kenarlarda `pay` boşlukla)
    public static func taban(en: Double, boy: Double, sahneW: Double, sahneH: Double, kenar: Double = tamPay)
        -> (w: Double, h: Double) {
        let maxW = max(1, sahneW - kenar * 2), maxH = max(1, sahneH - kenar * 2)
        let oran = boy > 0 && en > 0 ? en / boy : 1
        var w = maxW, h = w / oran
        if h > maxH { h = maxH; w = h * oran }
        return (w, h)
    }

    /// Tablonun tamamı (açılış, sessiz bakış, kapanış, başlangıç, bitiş): yatayda ortada, dikeyde ekranın %37'sinde;
    /// tablo ekranın %54'ünden uzunsa küçülür ve tepesi üst çubuğun altında kalır.
    public static func tamHedef(en: Double, boy: Double, sahneW: Double, sahneH: Double, ust: Double = 0)
        -> KameraDurumu {
        let t = taban(en: en, boy: boy, sahneW: sahneW, sahneH: sahneH)
        let s = min(1, sahneH * tamEnCokYukseklik / max(1, t.h))
        let capa = max(tamYOrani * sahneH, ust + t.h * s / 2)
        return KameraDurumu(u: 0.5, v: 0.5, z: log(s), capaY: capa)
    }

    /// Kaynak görselin çözünürlüğünü aşmayan en büyük ölçek: (kaynakEn · 1,18) / (tabanW · dpr)
    public static func pikselSiniri(kaynakEn: Double, tabanW: Double, dpr: Double) -> Double {
        (kaynakEn * 1.18) / (max(1, tabanW) * max(2, dpr))
    }

    /// Bir adımın hedefi. `kutu` nil: tablonun tamamı. `kaynakEn`: yüklü görselin piksel eni.
    /// Ölçek [1,48, 2,68] arasında ama piksel sınırını hiç aşmaz (sınır 1,48'in altındaysa sınır kazanır).
    public static func hedef(kutu: DinlemeKutusu?, tur: DinlemeAdimi.Tur, en: Double, boy: Double, kaynakEn: Double,
                             dpr: Double, sahneW: Double, sahneH: Double, ust: Double = 0) -> KameraDurumu {
        guard let k = kutu else { return tamHedef(en: en, boy: boy, sahneW: sahneW, sahneH: sahneH, ust: ust) }
        let t = taban(en: en, boy: boy, sahneW: sahneW, sahneH: sahneH)
        let guvenliH = sahneH * 0.60, guvenliW = sahneW * 0.90
        let kw = max(0.04, k.w) * t.w, kh = max(0.04, k.h) * t.h
        let sinir = pikselSiniri(kaynakEn: kaynakEn, tabanW: t.w, dpr: dpr)
        var s: Double
        if tur == .anlati {
            s = min(anlatiOlcek, sinir)
        } else {
            let ham = min(guvenliW * pay / kw, guvenliH * pay / kh)
            s = min(min(enCokOlcek, sinir), max(enAzOlcek, ham))
        }
        s = max(1, s)
        var u = k.x + k.w / 2, v = k.y + k.h / 2
        let capa = odakYOrani * sahneH
        let olcekW = t.w * s, olcekH = t.h * s
        if olcekW > sahneW {
            let yari = (sahneW / 2) / olcekW
            u = sinirla(u, yari, 1 - yari)
        } else {
            u = 0.5
        }
        if olcekH >= sahneH {
            let enAz = capa / olcekH
            let enCok = 1 - (sahneH - capa) / olcekH
            v = enAz <= enCok ? sinirla(v, enAz, enCok) : 0.5
        } else if olcekH > sahneH * 0.80 {
            let ustPay = capa / olcekH
            let altPay = (sahneH - capa - 24) / olcekH
            let enAz = sinirla(ustPay, 0.08, 0.48)
            let enCok = sinirla(1 - max(0.06, altPay), 0.52, 0.94)
            v = sinirla(v, enAz, enCok)
        }
        return KameraDurumu(u: u, v: v, z: log(s), capaY: capa)
    }

    /// Durumun ekrandaki karşılığı: merkezden `scaleEffect(olcek)` ve `offset(tx, ty)`.
    public static func yerlesim(_ d: KameraDurumu, en: Double, boy: Double, sahneW: Double, sahneH: Double)
        -> KameraYerlesimi {
        let t = taban(en: en, boy: boy, sahneW: sahneW, sahneH: sahneH)
        let s = exp(d.z)
        return KameraYerlesimi(tabanW: t.w, tabanH: t.h, olcek: s,
                               tx: -(d.u - 0.5) * t.w * s,
                               ty: -(d.v - 0.5) * t.h * s + (d.capaY - sahneH / 2))
    }

    /// Tablodaki bir kutunun ekrandaki çerçevesi (ışık canlı kamerayı gecikmesiz izler)
    public static func ekranda(_ k: DinlemeKutusu, _ y: KameraYerlesimi, sahneW: Double, sahneH: Double) -> EkranKutusu {
        let w = y.tabanW * y.olcek, h = y.tabanH * y.olcek
        let sol = sahneW / 2 + y.tx - w / 2, ust = sahneH / 2 + y.ty - h / 2
        return EkranKutusu(x: sol + k.x * w, y: ust + k.y * h, w: k.w * w, h: k.h * h)
    }

    /// Ayrıntı ışığının opaklığı: kamera yolun %68'ini geçince smoothstep ile doğar.
    public static func isikOpakligi(gecen: Double, sure: Double) -> Double {
        let p = sinirla((gecen / max(0.001, sure) - 0.68) / 0.45, 0, 1)
        return p * p * (3 - 2 * p)
    }
}

/// Bir hedefe giden yol ve varıştan sonraki canlı süzülme. Değer türü: ekran her karede `durum(gecen:)` ile hesaplar.
public struct KameraGecisi: Equatable, Sendable {
    public var bas: KameraDurumu
    public var hedef: KameraDurumu
    /// Yolun süresi (sn; 0: anında)
    public var sure: Double
    /// Uzaklaşma yayının derinliği (0: yay yok)
    public var derinlik: Double
    /// Mikro salınımın evresi (adım sırasından)
    public var faz: Double
    /// Varıştan sonra süzülme (başlangıç ve bitişte yok)
    public var suzulme: Bool

    public init(bas: KameraDurumu, hedef: KameraDurumu, sure: Double, derinlik: Double = 0, faz: Double = 0,
                suzulme: Bool = true) {
        self.bas = bas; self.hedef = hedef; self.sure = sure; self.derinlik = derinlik; self.faz = faz
        self.suzulme = suzulme
    }

    /// Yerinde duran kamera
    public static func sabit(_ d: KameraDurumu) -> KameraGecisi {
        KameraGecisi(bas: d, hedef: d, sure: 0, suzulme: false)
    }

    /// O anki canlı durumdan yeni hedefe (kamera.js `adimaGit` + `_kamerayaGit`). `sure` verilmezse adımın türünden.
    /// Yay yalnız iki yakın plan arasında: z0 > 0,18, z1 > 0,18 ve uzaklık > 0,05.
    public static func yeni(canli: KameraDurumu, hedef: KameraDurumu, tur: DinlemeAdimi.Tur, sira: Int,
                            sure: Double? = nil, suzulme: Bool = true) -> KameraGecisi {
        let d = hypot(hedef.u - canli.u, hedef.v - canli.v)
        let s = sure ?? DinleKamerasi.gecisSuresi(tur, mesafe: d)
        let yay = canli.z > 0.18 && hedef.z > 0.18 && d > 0.05
        return KameraGecisi(bas: canli, hedef: hedef, sure: s,
                            derinlik: yay ? DinleKamerasi.nefesDerinligi(d) : 0,
                            faz: Double(sira + 1) * 1.37, suzulme: suzulme)
    }

    /// `gecen` sn sonra kamera (kamera.js `_zamanGuncelle`).
    public func durum(gecen: Double) -> KameraDurumu {
        typealias K = DinleKamerasi
        if gecen < sure {
            let t = K.sinirla(gecen / sure, 0, 1)
            let ep = K.egriKonum(t), ez = K.egriOlcek(t)
            let z = K.ara(bas.z, hedef.z, ez) - (derinlik > 0 ? derinlik * K.nefes(t) : 0)
            return KameraDurumu(u: K.ara(bas.u, hedef.u, ep), v: K.ara(bas.v, hedef.v, ep),
                                z: max(min(0, hedef.z, bas.z), z), capaY: K.ara(bas.capaY, hedef.capaY, ep))
        }
        guard suzulme else { return hedef }
        let tau = gecen - sure
        let rampa = 1 - exp(-tau / K.rampaSabiti)
        let dz = min(K.suzmeSiniri, K.suzmeHizi * (tau - K.rampaSabiti * rampa))
        return KameraDurumu(u: hedef.u + K.suzmeSalinimU * rampa * sin(tau * 0.24 + faz),
                            v: hedef.v + K.suzmeSalinimV * rampa * cos(tau * 0.19 + faz),
                            z: hedef.z + dz, capaY: hedef.capaY)
    }

    /// Yolun ne kadarı alındı (ışık için)
    public func isik(gecen: Double) -> Double { DinleKamerasi.isikOpakligi(gecen: gecen, sure: max(0.001, sure)) }
}

/// Kameranın saati: duvar saatinden kamera zamanına. Duraklatınca zaman hızı `fren` ile üstel sönerek 1'den 0'a iner
/// (ani kilitlenme yok, ~0,45 sn'de durur), sürdürünce aynı biçimde 0'dan 1'e çıkar. Kesintisiz (C¹): değişim anındaki
/// hız saklanır.
public struct KameraSaati: Equatable, Sendable {
    /// Son değişimde birikmiş kamera zamanı
    public private(set) var birikmis: Double = 0
    /// Son değişimin duvar saati
    public private(set) var an: Double
    /// Son değişimdeki hız (0–1)
    public private(set) var hiz0: Double
    public private(set) var calisiyor: Bool

    public init(an: Double, calisiyor: Bool = true) {
        self.an = an
        self.calisiyor = calisiyor
        self.hiz0 = calisiyor ? 1 : 0
    }

    func hiz(_ t: Double) -> Double {
        let e = exp(-DinleKamerasi.fren * max(0, t - an))
        return calisiyor ? 1 - (1 - hiz0) * e : hiz0 * e
    }

    /// `t` anındaki kamera zamanı
    public func gecen(_ t: Double) -> Double {
        let dt = max(0, t - an)
        let k = DinleKamerasi.fren
        let e = (1 - exp(-k * dt)) / k
        return birikmis + (calisiyor ? dt - (1 - hiz0) * e : hiz0 * e)
    }

    public mutating func duraklat(_ t: Double) {
        guard calisiyor else { return }
        birikmis = gecen(t); hiz0 = hiz(t); an = t; calisiyor = false
    }

    public mutating func surdur(_ t: Double) {
        guard !calisiyor else { return }
        birikmis = gecen(t); hiz0 = hiz(t); an = t; calisiyor = true
    }

    /// Yeni yol: sıfırdan, hız korunur (duraklatılmışken adım atlanırsa kamera yine yumuşak durur)
    public mutating func sifirla(_ t: Double) {
        hiz0 = hiz(t); birikmis = 0; an = t
    }
}
