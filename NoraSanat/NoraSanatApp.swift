import SwiftUI
import UIKit

@main
struct NoraSanatApp: App {
    init() {
        Hatirlatici.shared.baslat()   // bildirime dokununca açılacak sayfa için, açılışta kurulmalı
        Yazi.kaydet()                 // sitenin yazı tipleri (NoraSanat/YaziTipleri)
        #if DEBUG
        // -adres "#/ilerleme": site o sayfada açılır (CI ekran görüntüleri için)
        if let adres = Self.arguman("-adres") { Gezgin.shared.git(adres) }
        // -benKaydir kurs: site (-yalnizSite) Ben'in o bölümüne kayar (C4b karşılaştırma görüntüleri)
        BenKarsilastirma.siteyiKaydir()
        // -galeriKaydir dizin: site Galeri'nin o bölümüne kayar (G2b karşılaştırma görüntüleri)
        GaleriKarsilastirma.siteyiKaydir()
        #endif
    }

    /// Açılış argümanının değeri: `-ekran ilerleme` → "ilerleme"
    static func arguman(_ ad: String) -> String? {
        let a = CommandLine.arguments
        guard let i = a.firstIndex(of: ad), i + 1 < a.count else { return nil }
        return a[i + 1]
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if CommandLine.arguments.contains("-widgetOnizleme") {
                WidgetOnizleme()
            } else if Self.arguman("-ekran") == "ilerleme" {
                // Site arkada yüklenir (köprü onu kullanır), özet üstte
                ZStack {
                    KokGorunum()
                    IlerlemeOzeti(yaz: CommandLine.arguments.contains("-ilerlemeYaz"))
                }
            } else if Self.arguman("-ekran") == "goruntuleyici" {
                GoruntuleyiciOnizleme()   // G1: ayrıntı noktası olan ilk eser
            } else if Self.arguman("-ekran") == "pekistir" {
                ZStack {
                    KokGorunum().accessibilityHidden(true)
                    PekistirmeEkrani(ilkTur: .sanatci(.karisik))
                        .environment(TemaDeposu.shared)
                }
            } else if Self.arguman("-ekran") == "tema" {
                // Site arkada yüklenir (canlı tema için), örnekler üstte
                ZStack {
                    KokGorunum()
                    TemaOrnekleri().environment(TemaDeposu.shared)
                }
            } else {
                KokGorunum()
            }
            #else
            KokGorunum()
            #endif
        }
    }
}
