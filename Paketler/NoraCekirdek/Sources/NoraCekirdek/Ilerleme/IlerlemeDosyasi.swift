// Z2: ilerlemenin Swift'teki yeri (sitede localStorage + IndexedDB yansısı; js/depo.js ilerlemeYukle, ilerlemeKaydet).
// Sitenin İş 143 kuralları korunur: her kayıt bir öncekinden büyük numara (kayitNo) alır, hiçbir kopya sessizce
// kaybolmaz, okunamayan kayıt silinmez saklanır.
import Foundation

/// `klasor/ilerleme.json` ana kayıt, `klasor/onceki.json` bir önceki kayıt. Yazım atomik (önce geçici dosya).
/// Açılışta ana kayıt okunur; bozuksa ya da doğrulanamıyorsa önceki kayda dönülür ve bozuk dosya `bozuk-<zaman>.json`
/// olarak saklanır. Klasör Application Support'ta: iCloud/iTunes cihaz yedeğine girer.
public final class IlerlemeDosyasi: @unchecked Sendable {
    public enum Hata: Error, Equatable {
        /// Okunduğundan beri başka bir yazım oldu (diskteki kayitNo beklenen değil)
        case cakisma
        /// Dosya var ama hiçbir kopya okunamadı: kayıt kilitlenir, üstüne boş ilerleme yazılmaz (sitenin kayitKilidi)
        case okunamadi(String)
    }

    public let klasor: URL
    private let kilit = NSLock()
    private var sonKayitNo = 0
    /// Hiçbir kopya okunamadıysa bu açılışta yazılmaz
    public private(set) var kilitli = false

    public init(klasor: URL) { self.klasor = klasor }

    public var ana: URL { klasor.appendingPathComponent("ilerleme.json") }
    public var onceki: URL { klasor.appendingPathComponent("onceki.json") }
    public var varMi: Bool { FileManager.default.fileExists(atPath: ana.path) || FileManager.default.fileExists(atPath: onceki.path) }

    /// Kaydı okur ve doğrular. Hiç kayıt yoksa nil (çağıran taşımayı ya da varsayılanı seçer).
    public func oku(bugun: String, simdi: String) throws -> SiraliNesne? {
        kilit.lock(); defer { kilit.unlock() }
        var sorun: [String] = []
        var adaylar: [SiraliNesne] = []
        for url in [ana, onceki] where FileManager.default.fileExists(atPath: url.path) {
            do {
                let veri = try Data(contentsOf: url)
                do {
                    adaylar.append(try IlerlemeKurallari.dogrula(try JSONDeger.coz(veri), bugun: bugun, simdi: simdi))
                } catch {
                    bozukSakla(veri)
                    sorun.append("\(url.lastPathComponent): \(error)")
                }
            } catch {
                sorun.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        // Ana ile önceki arasında numarası büyük olan (ana yazılırken kesildiyse önceki daha yeni olamaz; yine de bakılır)
        let secilen = adaylar.dropFirst().reduce(adaylar.first) { IlerlemeKurallari.enYeniKayit($0, $1) }
        if let secilen {
            sonKayitNo = adaylar.map { Int($0["kayitNo"]?.sayi ?? 0) }.max() ?? 0
            return secilen
        }
        if !sorun.isEmpty {
            kilitli = true
            throw Hata.okunamadi(sorun.joined(separator: " · "))
        }
        return nil
    }

    /// Yazar ve yeni numarasıyla kaydı döndürür. `beklenen`: okunduğu andaki kayitNo (nil: denetleme; ilk kayıt, taşıma,
    /// yedekten geri yükleme). Eski ana kayıt `onceki.json` olur.
    @discardableResult
    public func yaz(_ il: SiraliNesne, beklenen: Int?) throws -> SiraliNesne {
        kilit.lock(); defer { kilit.unlock() }
        if kilitli { throw Hata.okunamadi("kayıt kilitli") }
        let diskte = diskKayitNo()
        if let beklenen, beklenen != diskte { throw Hata.cakisma }
        sonKayitNo = max(sonKayitNo, diskte, Int(il["kayitNo"]?.sayi ?? 0)) + 1
        let yeni = il.ayarlandi("kayitNo", .sayi(Double(sonKayitNo)))
        try FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: ana.path) {
            if FileManager.default.fileExists(atPath: onceki.path) { try FileManager.default.removeItem(at: onceki) }
            try FileManager.default.copyItem(at: ana, to: onceki)
        }
        try JSONDeger.nesne(yeni).jsonVerisi.write(to: ana, options: .atomic)
        return yeni
    }

    /// Yedekten geri yükleme ya da elle düzeltme sonrası kilidi açar (sitenin kayitKilidiniAc)
    public func kilidiAc() { kilit.lock(); kilitli = false; kilit.unlock() }

    private func diskKayitNo() -> Int {
        guard let veri = try? Data(contentsOf: ana), let j = try? JSONDeger.coz(veri) else { return sonKayitNo }
        return Int(j["kayitNo"]?.sayi ?? 0)
    }

    private func bozukSakla(_ veri: Data) {
        let ad = "bozuk-\(Int(Date().timeIntervalSince1970 * 1000)).json"
        try? FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
        try? veri.write(to: klasor.appendingPathComponent(ad), options: .atomic)
    }
}
