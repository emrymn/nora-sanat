// Z4a · "Dinleyerek bak" doğal sesi: Gemini TTS "Fola" kayıtlarının dizini ve disk önbelleği (sitede karşılığı yok).
// Sözleşme: sanat-atlasi scripts/ses_uret.py (PR #238). Dizin sitenin data/ses_dizini.json'u (K3: siteden iner, önbelleğe
// alınır); ses ve zamanlama dosyaları görsellerin R2 adresinde (`gorsel_kaynagi.json` `adres`): <adres>/<klasor>/<anahtar>.mp3
// ve .json. Bir kez inen dosya bir daha inmez (anahtar metnin özetidir, metin değişirse anahtar da değişir).
import Foundation
import NoraCekirdek

/// Diskteki bir kayıt: ses dosyası ve kelime zamanlaması.
struct SesKaydi {
    let mp3: URL
    let akis: AltyaziAkisi?
}

actor DinleSesKaynagi {
    static let shared = DinleSesKaynagi()

    private let site = SiteVerisi()
    private var dizinBellegi: SesDizini?
    /// Bu oturumda inemeyen kayıtlar (beklemeyi uzatmasın)
    private var inemeyenler: Set<String> = []
    /// Şu an inen anahtarlar (aynı dosya iki kez istenmesin)
    private var inenler: [String: Task<Bool, Never>] = [:]
    private let oturum: URLSession = {
        let a = URLSessionConfiguration.default
        a.timeoutIntervalForRequest = 20
        return URLSession(configuration: a)
    }()

    private func klasor(_ d: SesDizini) -> URL {
        let k = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DinleSes", isDirectory: true)
            .appendingPathComponent(d.klasor.replacingOccurrences(of: "/", with: "_"), isDirectory: true)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        return k
    }

    /// `data/ses_dizini.json`; yoksa (site henüz yayınlamadı, internet yok, CI'da `-dinleSesYok`) nil → telefonun sesi.
    func dizin() async -> SesDizini? {
        #if DEBUG
        if CommandLine.arguments.contains("-dinleSesYok") { return nil }
        #endif
        if let d = dizinBellegi { return d }
        let d = SesDizini(veri: await site.veri("ses_dizini.json"))
        if d != nil { dizinBellegi = d }
        return d
    }

    /// Diskte varsa kayıt
    func yerel(_ anahtar: String) async -> SesKaydi? {
        guard let d = await dizin() else { return nil }
        let k = klasor(d)
        let mp3 = k.appendingPathComponent("\(anahtar)-\(d.surum(anahtar)).mp3")
        let json = k.appendingPathComponent("\(anahtar)-\(d.surum(anahtar)).json")
        guard FileManager.default.fileExists(atPath: mp3.path) else { return nil }
        return SesKaydi(mp3: mp3, akis: AltyaziAkisi(veri: try? Data(contentsOf: json)))
    }

    /// Planın bütün kayıtlarını arka planda indirir (aynı anda en çok üç). Diskte olanlara dokunmaz.
    func hazirla(_ anahtarlar: [String], kok: String) async {
        var kalan = anahtarlar.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        await withTaskGroup(of: Void.self) { grup in
            var calisan = 0
            while !kalan.isEmpty || calisan > 0 {
                if calisan < 3, !kalan.isEmpty {
                    let a = kalan.removeFirst()
                    calisan += 1
                    grup.addTask { _ = await self.indir(a, kok: kok) }
                } else {
                    await grup.next()
                    calisan -= 1
                }
            }
        }
    }

    /// Kaydı getirir: inmemişse indirmeyi başlatır ve en çok `sure` sn bekler; yine yoksa nil (o adımı telefon okur).
    func kayit(_ anahtar: String, kok: String, sure: Double = 3) async -> SesKaydi? {
        if let y = await yerel(anahtar) { return y }
        inemeyenler.remove(anahtar)
        // İndirme arkada sürer (geç inerse bir sonraki dinlemede çalınır); burada en çok `sure` sn beklenir
        Task { _ = await self.indir(anahtar, kok: kok) }
        let son = Date().addingTimeInterval(sure)
        while Date() < son, !Task.isCancelled, !inemeyenler.contains(anahtar) {
            if let y = await yerel(anahtar) { return y }
            try? await Task.sleep(for: .milliseconds(150))
        }
        return await yerel(anahtar)
    }

    /// Bir kaydı (önce zamanlama, sonra ses) indirir; başarılıysa true.
    private func indir(_ anahtar: String, kok: String) async -> Bool {
        if let t = inenler[anahtar] { return await t.value }
        guard let d = await dizin(), let a = d.adresler(anahtar, kok: kok) else {
            inemeyenler.insert(anahtar)
            return false
        }
        let k = klasor(d)
        let mp3 = k.appendingPathComponent("\(anahtar)-\(d.surum(anahtar)).mp3")
        let json = k.appendingPathComponent("\(anahtar)-\(d.surum(anahtar)).json")
        if FileManager.default.fileExists(atPath: mp3.path) { return true }
        let oturum = self.oturum
        let t = Task<Bool, Never> {
            func getir(_ u: URL) async -> Data? {
                guard let c = try? await oturum.data(from: u),
                      (c.1 as? HTTPURLResponse)?.statusCode == 200, !c.0.isEmpty else { return nil }
                return c.0
            }
            // Zamanlama yoksa da ses çalınır (altyazı tahmini akar)
            if let j = await getir(a.json), AltyaziAkisi(veri: j) != nil {
                try? j.write(to: json, options: .atomic)
            }
            guard let m = await getir(a.mp3) else { return false }
            // Ses en son yazılır: dosya varsa kayıt tamamdır
            guard (try? m.write(to: mp3, options: .atomic)) != nil else { return false }
            // Aynı parçanın eski sürümleri (ve Z4e öncesi sürümsüz adlar) silinir
            let fm = FileManager.default
            for ad in (try? fm.contentsOfDirectory(atPath: k.path)) ?? []
            where ad.hasPrefix(anahtar) && ad != mp3.lastPathComponent && ad != json.lastPathComponent {
                try? fm.removeItem(at: k.appendingPathComponent(ad))
            }
            return true
        }
        inenler[anahtar] = t
        let sonuc = await t.value
        inenler[anahtar] = nil
        if !sonuc { inemeyenler.insert(anahtar) }
        return sonuc
    }
}
