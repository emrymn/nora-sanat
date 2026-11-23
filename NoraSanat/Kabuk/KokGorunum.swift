import NoraCekirdek
import SwiftUI

/// Uygulamanın kökü (ISLER.md K1): yerli sekmeler. Z2c'den beri site yalnız ilk taşımada ve DEBUG karşılaştırmalarında
/// kurulur (`WebKabugu.gerekli`); kurulduğunda da yalnız seçili sekme taşınmamışsa görünür. Hiç sekme taşınmadıysa yerli çubuk hiç kurulmaz ve uygulama bugünküyle birebir aynıdır. Bkz. `Gecis`.
/// Yerli ekranların çubuğu `YerliSekmeCubugu` (T4): sitenin çubuğuyla aynı yerde, aynı görünüşte.
struct KokGorunum: View {
    @State private var durum = KabukDurumu.shared
    @State private var tema = TemaDeposu.shared
    @Environment(\.scenePhase) private var evre

    var body: some View {
        ZStack {
            if !Gecis.yerliSekmeler.isEmpty {
                // Sistemin sekme çubuğu gizli; yerine sitenin çubuğunun aynısı (T4) en üstte durur
                TabView(selection: Binding(get: { durum.secili }, set: { durum.sec($0) })) {
                    ForEach(Sekme.allCases) { s in
                        yerliEkran(s)
                            .toolbar(.hidden, for: .tabBar)
                            // Kaydırılan içerik yüzen çubuğun altında kalmasın (sitede sayfanın alt boşluğu)
                            .safeAreaInset(edge: .bottom, spacing: 0) {
                                Color.clear.frame(height: SekmeCubugu.Olcu.yukseklik + SekmeCubugu.Olcu.enAzAlt)
                            }
                            .tag(s)
                    }
                }
            }
            // Z2c-3b: site yalnız gerektiğinde (taşıma, DEBUG karşılaştırma); bkz. `WebKabugu.gerekli`
            if WebKabugu.gerekli {
                site
                    .opacity(durum.siteGorunur ? 1 : 0)
                    .allowsHitTesting(durum.siteGorunur)
                    .accessibilityHidden(!durum.siteGorunur)
            }
            if !Gecis.yerliSekmeler.isEmpty {
                // Site görünürken de kurulu (saydam): hap sitenin seçimini izler, yerliye geçince oradan kayar
                YerliSekmeCubugu()
                    .opacity(durum.cubukGorunur ? 1 : 0)
                    .allowsHitTesting(durum.cubukGorunur)
                    .accessibilityHidden(!durum.cubukGorunur)
            }
        }
        .environment(tema)
        .environment(durum)
        // Saat/pil çubuğu sitenin rengine uysun (koyu zeminde açık yazı)
        .preferredColorScheme(tema.koyu ? .dark : .light)
        // Widget'a dokununca: norasanat://bugun
        .onOpenURL { Gezgin.shared.ac($0) }
        // Z2c-2: renkler ayarlardan ve günün tablosundan (açılışta ve her dönüşte; gün değişmiş olabilir)
        .task { TemaHesabi.yenile() }
        .onChange(of: evre) { _, yeni in
            if yeni == .active { durum.rozetiYenile(); TemaHesabi.yenile() }
        }
    }

    private var site: some View {
        WebKabugu(tema: tema)
            .ignoresSafeArea()
            .background(Color(uiColor: tema.siteRengi).ignoresSafeArea())
    }

    @ViewBuilder
    private func yerliEkran(_ s: Sekme) -> some View {
        if Gecis.yerli(s) {
            switch s {
            case .bugun: BugunSekmesi()
            case .yolculuk: YolculukSekmesi()
            case .galeri: GaleriSekmesi()
            case .calis: CalisSekmesi()
            case .ben: BenSekmesi()
            }
        } else {
            // Taşınmamış sekme seçilince site bunun üstüne gelir
            Color(uiColor: tema.siteRengi).ignoresSafeArea()
        }
    }
}

/// Henüz yazılmamış yerli sekmenin yeri (DEBUG `-yerliSekme` ile denenir). Şerit işi bunu kendi ekranıyla değiştirir.
struct SekmeYeri: View {
    let sekme: Sekme
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var durum

    var body: some View {
        VStack(spacing: 12) {
            Text(sekme.baslik).font(Yazi.serif(34, stil: .largeTitle))
            Text("Yerli ekran henüz yazılmadı").font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
            if let a = durum.yerliAdres[sekme] {
                Text(a).font(Yazi.sans(13)).monospaced().foregroundStyle(Color(tema.renkler.murekkep3))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(tema.renkler.zemin).ignoresSafeArea())
        .foregroundStyle(Color(tema.renkler.murekkep))
    }
}
