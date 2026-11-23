// Kaynak: sanat-atlasi js/harfler.js (yukle, harfUygula), css/app.css (.donem-harfi) @ a866b86
import CoreText
import NoraCekirdek
import SwiftUI

/// Z3f: dönemin harfiyle başlık (İş 48): akım sayfasının büyük adı, haritadaki dönem adları. Yazı tipi yalnız bu
/// başlığın harfleri için Google Fonts'tan iner ve cihazda saklanır; inmezse (ilk açılış çevrimdışı) uygulamanın
/// serifi kalır. Boy `olcek` katı; harf aralığı yazı tipinin kendi aralığı (`.donem-harfi { letter-spacing: 0 }`).
struct DonemYazisi: View {
    let metin: String
    let harf: DonemHarfi?
    let boyut: CGFloat
    var agirlik: CGFloat = 400
    var stil: UIFont.TextStyle = .largeTitle
    @State private var font: UIFont?

    var body: some View {
        let olcekli = boyut * CGFloat(harf?.olcek ?? 1)
        Group {
            if let font {
                Text(metin).font(Font(UIFontMetrics(forTextStyle: stil).scaledFont(for: font)))
            } else {
                Text(metin).font(Yazi.serif(olcekli, agirlik: agirlik, stil: stil))
            }
        }
        .task(id: metin + (harf?.aile ?? "")) {
            guard let harf else { font = nil; return }
            font = await HarfYukleyici.shared.font(harf, metin: metin, boyut: olcekli)
        }
    }
}

/// css2 adresi → TrueType (uygulamanın isteğine Google TrueType verir) → CoreText. Dosyalar Caches/Harfler'de.
actor HarfYukleyici {
    static let shared = HarfYukleyici()
    private var bellek: [String: Data] = [:]
    private let klasor = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Harfler", isDirectory: true)

    func font(_ h: DonemHarfi, metin: String, boyut: CGFloat) async -> UIFont? {
        let adres = h.adres(metin: metin.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let veri = await veri(adres),
              let tanimlar = CTFontManagerCreateFontDescriptorsFromData(veri as CFData) as? [CTFontDescriptor],
              let t = tanimlar.first else { return nil }
        return CTFontCreateWithFontDescriptor(t, boyut, nil) as UIFont
    }

    private func dosya(_ adres: String) -> URL {
        // Adresten kararlı bir ad (FNV-1a)
        var h: UInt64 = 0xcbf29ce484222325
        for b in adres.utf8 { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return klasor.appendingPathComponent(String(h, radix: 16) + ".ttf")
    }

    private func veri(_ adres: String) async -> Data? {
        if let v = bellek[adres] { return v }
        let yer = dosya(adres)
        if let v = try? Data(contentsOf: yer) { bellek[adres] = v; return v }
        guard let url = URL(string: adres),
              let css = try? await URLSession.shared.data(from: url).0,
              let metin = String(data: css, encoding: .utf8),
              let r = metin.range(of: #"url\((https://[^)]+)\)"#, options: .regularExpression),
              let fontAdresi = URL(string: String(metin[r].dropFirst(4).dropLast())),
              let v = try? await URLSession.shared.data(from: fontAdresi).0,
              let tanim = CTFontManagerCreateFontDescriptorsFromData(v as CFData) as? [CTFontDescriptor], !tanim.isEmpty
        else { return nil }
        try? FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
        try? v.write(to: yer, options: .atomic)
        bellek[adres] = v
        return v
    }
}
