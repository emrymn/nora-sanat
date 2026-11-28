// Z4g: Emre'nin isteği: üstte Çalış'taki gibi durum çubuğunun altına uzanan tam ekran öne çıkanlar (yana kaydırılan
// 5 bitirilmemiş en yeni yazı), altta Devam et şeridi ve Bütün hikâyeler iki sütunlu ızgarası.
// Z4f: ana ekran bütün hikâyelerin kapak ızgarası (Emre: "bütün hikâyeler gözüksün"); Z4e'nin öne çıkanları ve arşivi kalktı.
// Z4b · Hikâyeler sekmesi (yeni; sitede yok). Tasarım: Neon "Yön 2 · Substack Minimal" (Emre seçti; dal
// neon/hikayeler-tasarim-3, PR #75, birleştirilmedi): tasarim/hikayeler-3/yon-2.html (`.sub-ust`, `.sub-akis`,
// `.sub-yazi`), ortak.css, goruntuler/yon-2-ana-{gece,gunduz}.png. Emre'nin değişikliği: "Ben" çubukta değil, sağ üstteki
// kişi düğmesinde (Yön 2'nin ayrı yuvarlak Ben kapsülü yok).
import NoraCekirdek
import SwiftUI

/// Hikâyeler sitede yok: hep yerli
enum HikayelerGecisi {
    static var sekmeler: Set<Sekme> { [.hikayeler] }
}

/// Z4h: Hikâyeler gezinti rotaları (sanatçı yazısı, dizi sayfası, dizi bölümü)
enum HikayeRota: Hashable {
    case yazi(String)
    case dizi(String)
    case bolum(String)
}

struct HikayelerSekmesi: View {
    @Environment(KabukDurumu.self) private var kabuk
    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared
    /// Açık sayfalar (yazı, dizi ya da dizi bölümü)
    @State private var yol: [HikayeRota] = []
    @State private var aramaAcik = false
    @State private var basaDon = 0

    var body: some View {
        NavigationStack(path: $yol) {
            Group {
                switch depo.durum {
                case .hazir:
                    HikayeAna(ac: ac, diziAc: diziAc, aramaAcik: $aramaAcik, basaDon: basaDon)
                case .yukleniyor:
                    ProgressView("Hikâyeler hazırlanıyor…")
                        .font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(tema.renkler.zemin).ignoresSafeArea())
                case .yok:
                    VStack(spacing: 16) {
                        Text("Hikâyeler yüklenemedi.").font(Yazi.sans(15)).foregroundStyle(Color(tema.renkler.murekkep2))
                        Button("Yeniden dene") { Task { await depo.yukle(zorla: true) } }.buttonStyle(HapDugme())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(tema.renkler.zemin).ignoresSafeArea())
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: HikayeRota.self) { rota in
                Group {
                    switch rota {
                    case .yazi(let id):
                        if let h = depo.yaziVeyaBolum(id) {
                            HikayeOkuma(hikaye: h, ac: ac)
                        } else {
                            Color(tema.renkler.zemin).ignoresSafeArea()
                        }
                    case .dizi(let id):
                        if let d = depo.dizi(id) {
                            DiziSayfasi(dizi: d, bolumAc: bolumAc)
                        } else {
                            Color(tema.renkler.zemin).ignoresSafeArea()
                        }
                    case .bolum(let id):
                        if let b = depo.diziBolumu(id) {
                            HikayeOkuma(hikaye: b.hikaye, ac: ac)
                        } else {
                            Color(tema.renkler.zemin).ignoresSafeArea()
                        }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        // Okurken ve dizi sayfasında çubuk yok: altta çalar durur
        .sekmeCubuguGizli(!yol.isEmpty, sekme: .hikayeler)
        .task {
            await depo.yukle()
            #if DEBUG
            HikayeProva.sekmeAcildi()
            #endif
        }
        .onChange(of: kabuk.yerliAdres[.hikayeler], initial: true) { _, adres in
            guard let adres else { return }
            if let id = HikayeAdresi.sanatci(adres) {
                let hedef = HikayeRota.yazi(id)
                if yol.last != hedef { yol = [hedef] }
            } else if let dy = HikayeAdresi.diziYolu(adres) {
                if let bid = dy.bolum {
                    yol = [.dizi(dy.dizi), .bolum(bid)]
                } else {
                    yol = [.dizi(dy.dizi)]
                }
            } else {
                yol = []
            }
            kabuk.adresIslendi(.hikayeler)
        }
        .onChange(of: kabuk.yenidenDokunma[.hikayeler]) { _, _ in
            // Açık sekmeye yeniden dokunma: alt sayfadan ana ekrana, ana ekranda en başa
            if !yol.isEmpty { yol = [] } else { basaDon += 1 }
        }
    }

    private func ac(_ id: String) {
        Titresim.secim()
        if depo.diziBolumu(id) != nil {
            yol.append(.bolum(id))
        } else {
            yol.append(.yazi(id))
        }
    }

    private func diziAc(_ id: String) {
        Titresim.secim()
        yol.append(.dizi(id))
    }

    private func bolumAc(_ id: String) {
        Titresim.secim()
        yol.append(.bolum(id))
    }
}

// MARK: - Ana ekran

/// Z4g: üstte Çalış'taki gibi tam ekran öne çıkanlar (durum çubuğunun altına uzanan kenardan kenara eser görseli,
/// yana kaydırılan 5 sayfa, Oku / Dinle düğmeleri, 8 sn otomatik geçiş), aşağı kaydırınca buzlu cam ince üst çubuk;
/// altta varsa Devam et şeridi, "Bütün hikâyeler" ara başlığı, süzgeç hapları ve iki sütunlu kapak ızgarası.
struct HikayeAna: View {
    enum Suzgec: String, CaseIterable, Identifiable {
        case tumu = "Tümü"
        case donem = "Dönem"
        case begendiklerim = "Beğendiklerim"
        case sonraOku = "Sonra oku"
        var id: String { rawValue }
    }

    let ac: (String) -> Void
    let diziAc: (String) -> Void
    @Binding var aramaAcik: Bool
    let basaDon: Int

    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var depo = HikayeDeposu.shared
    @State private var calar = HikayeCalari.shared
    @State private var ustCubukAcik = false
    @State private var oneCikanId: String?
    @State private var otomatikDurdu = false
    @State private var suzgec: Suzgec = {
        #if DEBUG
        return HikayeProva.suzgec
        #else
        return .tumu
        #endif
    }()

    private let sutunlar = [GridItem(.flexible(), spacing: 14, alignment: .top),
                            GridItem(.flexible(), spacing: 14, alignment: .top)]

    /// Öne çıkanlar: en yeni, bitirilmemiş en çok 5 yazı (hepsi bitmişse en yeni 5'e düşer)
    private var oneCikanListe: [SanatciHikayesi] {
        let l = depo.oneCikanlar
        return l.isEmpty ? Array(depo.enYeni.prefix(5)) : l
    }

    private var aktifOneCikan: SanatciHikayesi? {
        let l = oneCikanListe
        if let id = oneCikanId, let h = l.first(where: { $0.id == id }) { return h }
        return l.first
    }

    private var hareketKapali: Bool { hareketAz || tema.ayar.hareketAzaltilmis }
    private var otomatikAcik: Bool { !otomatikDurdu && !hareketKapali }

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let zeminHikaye = aktifOneCikan ?? depo.enYeni.first
        GeometryReader { geo in
            let ust = geo.safeAreaInsets.top
            let genislik = geo.size.width
            ZStack(alignment: .top) {
                ScrollViewReader { kaydir in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Color.clear
                                .frame(height: 0)
                                .id("ust")

                            oneCikanSahne(ust: ust, genislik: genislik, c: c)

                            devamEt(c)
                                .id("devam")
                            dizilerRafi(c, genislik: genislik)
                                .id("diziler")
                            butunHikayelerBasi(c)
                                .id("butun-hikayeler")
                            suzgecler(c)
                            izgara(c).padding(.top, 14)
                            Color.clear.frame(height: calar.acik ? 96 : 24)
                        }
                    }
                    .ignoresSafeArea(.container, edges: .top)
                    .scrollIndicators(.hidden)
                    .onChange(of: basaDon) { _, _ in
                        withAnimation(hareketKapali ? nil : .easeOut(duration: 0.35)) {
                            kaydir.scrollTo("ust", anchor: .top)
                        }
                    }
                    #if DEBUG
                    .task {
                        // CI: süzgeçli çekimler ızgaraya, Devam et çekimi şeride kayar (Z4g'nin tam ekran öne
                        // çıkanları ve Z4h'nin dizi rafı bunları ilk ekranın altına itti)
                        let args = CommandLine.arguments
                        let hedef: (String, UnitPoint)?
                        if HikayeProva.suzgec != .tumu {
                            hedef = ("butun-hikayeler", UnitPoint(x: 0.5, y: 0.15))
                        } else if args.contains("-hikayeDevam") {
                            hedef = ("devam", UnitPoint(x: 0.5, y: 0.3))
                        } else if args.contains("-hikayeAsagi") {
                            hedef = depo.diziler.isEmpty ? ("butun-hikayeler", UnitPoint(x: 0.5, y: 0.15))
                                : ("diziler", UnitPoint(x: 0.5, y: 0.26))
                        } else {
                            hedef = nil
                        }
                        guard let hedef else { return }
                        try? await Task.sleep(for: .milliseconds(900))
                        withAnimation(.easeOut(duration: 0.25)) { kaydir.scrollTo(hedef.0, anchor: hedef.1) }
                    }
                    #endif
                }

                if ustCubukAcik {
                    hikayeUstCubugu(c)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .coordinateSpace(name: "hikaye-kaydir")
        }
        // Z4f/Z4g: Galeri'deki gibi hale ve dönem deseni (aktif öne çıkan yazının kapağından ve döneminden)
        .background(SayfaZemini(donem: zeminHikaye.flatMap { depo.donem($0.id) },
                                tablo: zeminHikaye.flatMap { depo.kucukAdres($0.kapakQid, sanatci: $0.id, genislik: 400) },
                                alan: .hikayeler))
        .overlay {
            if aramaAcik {
                HikayeArama(kapat: { withAnimation(.easeOut(duration: 0.2)) { aramaAcik = false } }) { id in
                    aramaAcik = false
                    ac(id)
                }
                .transition(.opacity)
            }
        }
        .task(id: "\(otomatikAcik)|\(oneCikanListe.map(\.id).joined(separator: ","))") {
            let l = oneCikanListe
            if oneCikanId == nil || !l.contains(where: { $0.id == oneCikanId }) {
                oneCikanId = l.first?.id
            }
            guard otomatikAcik, l.count > 1 else { return }
            while !Task.isCancelled && !otomatikDurdu {
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled, !otomatikDurdu else { break }
                let guncel = oneCikanListe
                guard guncel.count > 1 else { break }
                let simdiki = oneCikanId ?? guncel[0].id
                let sira = guncel.firstIndex { $0.id == simdiki } ?? 0
                let sonraki = guncel[(sira + 1) % guncel.count].id
                withAnimation(.easeInOut(duration: 0.45)) {
                    oneCikanId = sonraki
                }
            }
        }
    }

    // MARK: Öne çıkanlar (Çalış'ın kapağı gibi üstü tam ekran)

    @ViewBuilder
    private func oneCikanSahne(ust: CGFloat, genislik: CGFloat, c: HikayeRenk) -> some View {
        let liste = oneCikanListe
        let kapakYuksekligi = 276 + ust
        if !liste.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(liste) { h in
                                oneCikanSayfa(h, kapakYuksekligi: kapakYuksekligi, ust: ust, genislik: genislik, c: c)
                                    .id(h.id)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $oneCikanId)
                    .scrollIndicators(.hidden)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 6).onChanged { v in
                            if abs(v.translation.width) > 4 { otomatikDurdu = true }
                        }
                    )

                    // Kapak altı konumu: kaydırınca buzlu cam üst çubuğu açar
                    Color.clear
                        .frame(width: genislik, height: kapakYuksekligi)
                        .allowsHitTesting(false)
                        .onGeometryChange(for: Bool.self) { proxy in
                            proxy.frame(in: .named("hikaye-kaydir")).maxY < 120
                        } action: { acik in
                            if acik != ustCubukAcik {
                                withAnimation(hareketKapali ? nil : .easeOut(duration: 0.2)) {
                                    ustCubukAcik = acik
                                }
                            }
                        }

                    // En üstte görselin üstünde "Hikâyeler" başlığı, arama ve Ben (Çalış'taki "Çalış" gibi)
                    HStack(alignment: .center, spacing: 10) {
                        Text("Hikâyeler")
                            .font(Yazi.okuma(30, agirlik: 600, stil: .largeTitle))
                            .tracking(-0.56)
                            .foregroundStyle(KapakUstu.yazi)
                            .shadow(color: .black.opacity(0.45), radius: 7, y: 2)
                            .accessibilityAddTraits(.isHeader)
                        Spacer(minLength: 8)
                        aramaDugmesi
                        BenDugmesi()
                    }
                    .padding(.leading, 22)
                    .padding(.trailing, 18)
                    .padding(.top, ust + 4)
                    .frame(width: genislik, alignment: .leading)
                    .opacity(ustCubukAcik ? 0 : 1)
                    .allowsHitTesting(!ustCubukAcik)
                    .accessibilityHidden(ustCubukAcik)
                }

                if liste.count > 1 {
                    sayfaNoktalari(liste: liste, c: c)
                }
            }
            .padding(.bottom, 2)
        } else {
            // Hiç hikâye yoksa sade üst başlık
            HStack(spacing: 10) {
                Text("Hikâyeler")
                    .font(Yazi.okuma(28, agirlik: 600, stil: .largeTitle))
                    .tracking(-0.56)
                    .foregroundStyle(c.yazi)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                aramaDugmesi
                BenDugmesi()
            }
            .padding(.leading, 22)
            .padding(.trailing, 18)
            .padding(.top, ust + 8)
            .padding(.bottom, 10)
        }
    }

    private func oneCikanSayfa(
        _ h: SanatciHikayesi,
        kapakYuksekligi: CGFloat,
        ust: CGFloat,
        genislik: CGFloat,
        c: HikayeRenk
    ) -> some View {
        let s = depo.satir(h)
        let sanatciSatiri = [s.sanatci, s.yillar].filter { !$0.isEmpty }.joined(separator: " · ")
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                otomatikDurdu = true
                ac(h.id)
            } label: {
                ZStack(alignment: .top) {
                    ZStack {
                        KapakUstu.zemin
                        UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 28])
                            .frame(width: genislik, height: kapakYuksekligi)
                            .modifier(KapakYuruyusu())
                    }
                    .frame(width: genislik, height: kapakYuksekligi)
                    .clipped()
                    // Altta temanın zeminine ve SayfaZemini halesine pürüzsüz eriyen geçiş (Çalış'taki 140 pt eğri)
                    .mask {
                        VStack(spacing: 0) {
                            Color.black
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .black.opacity(0.44), location: 0.54),
                                    .init(color: .black.opacity(0.06), location: 0.86),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 140)
                        }
                    }

                    // Üstte hafif gölge ("Hikâyeler" başlığı ve durum çubuğu okunsun)
                    LinearGradient(
                        colors: [KapakUstu.golge.opacity(0.62), KapakUstu.golge.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 76 + ust)
                    .allowsHitTesting(false)
                }
                .frame(width: genislik, height: kapakYuksekligi)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(h.baslik), \(s.sanatci)")
            .accessibilityHint("Öne çıkan yazıyı açar")

            VStack(alignment: .leading, spacing: 0) {
                Text(sanatciSatiri)
                    .font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                    .foregroundStyle(c.pirinc)
                    .lineLimit(1)

                Button {
                    otomatikDurdu = true
                    ac(h.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(h.baslik)
                            .font(Yazi.okuma(27, agirlik: 600, stil: .title1))
                            .tracking(-0.45)
                            .cssSatir(.okuma, 27, 27 * 1.18)
                            .foregroundStyle(c.yazi)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)

                        if !h.altBaslik.isEmpty {
                            Text(h.altBaslik)
                                .font(Yazi.sans(14.5, stil: .subheadline))
                                .cssSatir(.sans, 14.5, 20.5)
                                .foregroundStyle(c.yazi2)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 5)
                .accessibilityHint("Yazıyı açar")

                HStack(spacing: 10) {
                    Button {
                        otomatikDurdu = true
                        ac(h.id)
                    } label: {
                        Text("Oku")
                            .font(Yazi.sans(14.5, agirlik: 600))
                            .foregroundStyle(c.zemin)
                            .padding(.horizontal, 24)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(c.yazi))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(h.baslik) yazısını oku")
                    .accessibilityIdentifier("one-cikan-oku-\(h.id)")

                    Button {
                        otomatikDurdu = true
                        Titresim.secim()
                        calar.baslat(h)
                        calar.tamEkran = true
                    } label: {
                        HStack(spacing: 7) {
                            HikayeIkon(simge: .kulaklik, boyut: 16, kalinlik: 1.7)
                            Text("Dinle")
                                .font(Yazi.sans(14.5, agirlik: 600))
                        }
                        .foregroundStyle(c.yazi)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 44)
                        .background {
                            ZStack {
                                Capsule().fill(.ultraThinMaterial)
                                Capsule().fill(c.yuzey.opacity(tema.renkler.koyu ? 0.68 : 0.78))
                                Capsule().strokeBorder(c.kenar, lineWidth: 1)
                            }
                        }
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(h.baslik) yazısını dinle")
                    .accessibilityIdentifier("one-cikan-dinle-\(h.id)")

                    Spacer(minLength: 0)
                }
                .padding(.top, 14)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.top, -34)
            .padding(.bottom, 2)
        }
        .frame(width: genislik, alignment: .topLeading)
        .accessibilityIdentifier("one-cikan-\(h.id)")
    }

    private func sayfaNoktalari(liste: [SanatciHikayesi], c: HikayeRenk) -> some View {
        let aktif = liste.firstIndex { $0.id == (oneCikanId ?? liste.first?.id) } ?? 0
        return Button {
            otomatikDurdu = true
            Titresim.secim()
            let sonraki = liste[(aktif + 1) % liste.count].id
            withAnimation(hareketKapali ? nil : .easeInOut(duration: 0.35)) {
                oneCikanId = sonraki
            }
        } label: {
            HStack(spacing: 6) {
                ForEach(Array(liste.enumerated()), id: \.element.id) { i, _ in
                    let secili = i == aktif
                    Capsule()
                        .fill(secili ? c.pirinc : c.yazi.opacity(0.24))
                        .frame(width: secili ? 20 : 6, height: 6)
                }
            }
            .animation(hareketKapali ? nil : .easeOut(duration: 0.22), value: aktif)
            .padding(.horizontal, 16)
            .frame(minWidth: 88, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Öne çıkan hikâyeler, \(aktif + 1) / \(liste.count)")
        .accessibilityHint("Sonraki öne çıkan hikâyeye geçer")
        .accessibilityAdjustableAction { yon in
            otomatikDurdu = true
            let yeni: Int
            switch yon {
            case .increment: yeni = (aktif + 1) % liste.count
            case .decrement: yeni = (aktif - 1 + liste.count) % liste.count
            @unknown default: return
            }
            withAnimation(hareketKapali ? nil : .easeInOut(duration: 0.35)) {
                oneCikanId = liste[yeni].id
            }
        }
        .accessibilityIdentifier("one-cikan-noktalar")
    }

    /// Aşağı kaydırınca açılan buzlu cam ince üst çubuk (Çalış'taki gibi)
    private func hikayeUstCubugu(_ c: HikayeRenk) -> some View {
        HStack(spacing: 10) {
            Text("Hikâyeler")
                .font(Yazi.okuma(20, agirlik: 600))
                .tracking(-0.3)
                .foregroundStyle(c.yazi)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            aramaDugmesi
            BenDugmesi()
        }
        .padding(.leading, 22)
        .padding(.trailing, 18)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background {
            ZStack(alignment: .bottom) {
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(c.cam.opacity(0.55))
                Rectangle().fill(Color(tema.renkler.murekkep).opacity(0.1)).frame(height: 1)
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private var aramaDugmesi: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { aramaAcik = true }
        } label: {
            HikayeIkon(simge: .ara, boyut: 19, kalinlik: 1.7)
        }
        .buttonStyle(HikayeCamDugme())
        .accessibilityLabel("Ara")
    }

    // MARK: Diziler rafı (Z4h)

    @ViewBuilder
    private func dizilerRafi(_ c: HikayeRenk, genislik: CGFloat) -> some View {
        let liste = depo.diziler
        if !liste.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Diziler")
                        .font(Yazi.okuma(22, agirlik: 600, stil: .title2))
                        .tracking(-0.3)
                        .foregroundStyle(c.yazi)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    Text("\(liste.count) dizi")
                        .font(Yazi.sans(12.5, stil: .footnote))
                        .foregroundStyle(c.yazi3)
                }
                .padding(.horizontal, 22)

                let kartGenisligi: CGFloat = liste.count == 1
                    ? max(260, genislik - 44)
                    : min(312, max(260, genislik - 58))

                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(liste) { d in
                            DiziKarti(dizi: d, genislik: kartGenisligi, ac: diziAc)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 22)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollIndicators(.hidden)
            }
            .padding(.top, depo.devamEt.isEmpty ? 6 : 2)
            .padding(.bottom, 22)
        }
    }

    private func butunHikayelerBasi(_ c: HikayeRenk) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Bütün hikâyeler")
                .font(Yazi.okuma(22, agirlik: 600, stil: .title2))
                .tracking(-0.3)
                .foregroundStyle(c.yazi)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Text("\(depo.enYeni.count) yazı")
                .font(Yazi.sans(12.5, stil: .footnote))
                .foregroundStyle(c.yazi3)
        }
        .padding(.horizontal, 22)
        .padding(.top, depo.devamEt.isEmpty ? 2 : 0)
        .padding(.bottom, 2)
    }

    // MARK: Devam et

    @ViewBuilder
    private func devamEt(_ c: HikayeRenk) -> some View {
        let l = depo.devamEt
        if !l.isEmpty {
            Text("Devam et").font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 22).padding(.bottom, 10)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 10) {
                    ForEach(l, id: \.hikaye.id) { d in devamKarti(d, c) }
                }
                .padding(.horizontal, 22)
            }
            .scrollIndicators(.hidden)
            .padding(.bottom, 14)
        }
    }

    /// Dinlemede kalındıysa dokununca çalar kalınan yerden açılır, okumada kalındıysa yazı kalınan paragraftan
    private func devamKarti(_ d: HikayeVitrini.Devam, _ c: HikayeRenk) -> some View {
        let s = depo.satir(d.hikaye)
        let kalan = depo.kalanDakika(d)
        return Button {
            Titresim.secim()
            if d.dinleme {
                calar.baslat(d.hikaye)
                calar.tamEkran = true
            } else {
                ac(d.hikaye.id)
            }
        } label: {
            HStack(spacing: 10) {
                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 30])
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: d.dinleme ? "headphones" : "book").font(.system(size: 10, weight: .semibold))
                        Text("\(kalan) dk kaldı")
                    }
                    .font(Yazi.sans(11.5, agirlik: 600)).foregroundStyle(c.pirinc)
                    Text(d.hikaye.baslik).font(Yazi.okuma(15, agirlik: 600)).foregroundStyle(c.yazi).lineLimit(1)
                    HikayeCizgi(oran: d.dinleme ? dinlemeOrani(d) : d.yer.oran, yukseklik: 2).padding(.top, 4)
                }
                .frame(width: 168, alignment: .leading)
            }
            .padding(9)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(c.yuzey))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(c.kenar, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(d.dinleme ? "Kaldığın yerden dinle" : "Kaldığın yerden oku")
        .accessibilityIdentifier("devam-\(d.hikaye.id)")
    }

    private func dinlemeOrani(_ d: HikayeVitrini.Devam) -> Double {
        let s = depo.sureler(d.hikaye)
        let t = s.reduce(0, +)
        guard t > 0 else { return d.yer.oran }
        return HikayeSesi.gecen(s, sira: d.yer.parca ?? 0, an: d.yer.an ?? 0) / t
    }

    // MARK: Süzgeç

    private func suzgecler(_ c: HikayeRenk) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Suzgec.allCases) { s in
                    let secili = s == suzgec
                    Button {
                        Titresim.secim()
                        withAnimation(.easeOut(duration: 0.2)) { suzgec = s }
                    } label: {
                        Text(s.rawValue)
                            .font(Yazi.sans(13.5, agirlik: secili ? 600 : 500))
                            .foregroundStyle(secili ? c.zemin : c.yazi2)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(Capsule().fill(secili ? c.yazi : .clear))
                            .overlay(Capsule().strokeBorder(secili ? .clear : c.kenar, lineWidth: 1))
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(secili ? .isSelected : [])
                    .accessibilityIdentifier("suzgec-\(s)")
                }
            }
            .padding(.horizontal, 22)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Izgara

    @ViewBuilder
    private func izgara(_ c: HikayeRenk) -> some View {
        switch suzgec {
        case .tumu:
            kutular(depo.enYeni)
        case .donem:
            ForEach(depo.donemler, id: \.baslik) { g in
                HStack(alignment: .firstTextBaseline) {
                    Text(g.baslik).font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(g.hikayeler.count) yazı").font(Yazi.sans(12)).foregroundStyle(c.yazi3)
                }
                .padding(.horizontal, 22).padding(.top, 10).padding(.bottom, 10)
                kutular(g.hikayeler).padding(.bottom, 16)
            }
        case .begendiklerim:
            let l = depo.begenilenler
            if l.isEmpty { bos("Henüz beğendiğin yazı yok.", "Yazının sonundaki kalbe dokununca burada toplanır.", c) } else { kutular(l) }
        case .sonraOku:
            let l = depo.sonraOkunacaklar
            if l.isEmpty { bos("Listen boş.", "Yazının sonundaki \"Sonra oku\"ya dokununca burada toplanır.", c) } else { kutular(l) }
        }
    }

    private func kutular(_ l: [SanatciHikayesi]) -> some View {
        LazyVGrid(columns: sutunlar, alignment: .leading, spacing: 22) {
            ForEach(l) { h in HikayeKutusu(hikaye: h, ac: ac) }
        }
        .padding(.horizontal, 22)
    }

    private func bos(_ baslik: String, _ alt: String, _ c: HikayeRenk) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(baslik).font(Yazi.okuma(19, agirlik: 600)).foregroundStyle(c.yazi)
            Text(alt).font(Yazi.sans(14)).foregroundStyle(c.yazi2).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22).padding(.top, 24)
    }
}

/// Izgarada bir hikâye: 4:5 kapak (köşede durum), sanatçı, başlık, süre
struct HikayeKutusu: View {
    let hikaye: SanatciHikayesi
    let ac: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let s = depo.satir(hikaye)
        let durum = depo.durum(hikaye)
        Button { ac(hikaye.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .overlay { UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 28]) }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topLeading) { etiket(durum, c).padding(8) }
                    .overlay(alignment: .bottom) {
                        if let y = depo.yer(hikaye.id), y.yarim {
                            HikayeCizgi(oran: y.oran, yukseklik: 3).padding(.horizontal, 8).padding(.bottom, 8)
                        }
                    }
                Text(s.sanatci).font(Yazi.sans(11.5, agirlik: 600)).foregroundStyle(c.pirinc).lineLimit(1)
                    .padding(.top, 9)
                Text(hikaye.baslik)
                    .font(Yazi.okuma(16, agirlik: 600))
                    .cssSatir(.okuma, 16, 16 * 1.25)
                    .foregroundStyle(c.yazi)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                let sureYazisi = depo.dinlenebilir(hikaye)
                    ? "\(s.okumaDk) dk okuma · \(s.dinlemeDk) dk dinleme"
                    : "\(s.okumaDk) dk okuma"
                Text(sureYazisi).font(Yazi.sans(11)).foregroundStyle(c.yazi3)
                    .lineLimit(1).minimumScaleFactor(0.85)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Yazıyı aç")
        .accessibilityIdentifier("hikaye-\(hikaye.id)")
    }

    @ViewBuilder
    private func etiket(_ d: HikayeAkisi.Durum, _ c: HikayeRenk) -> some View {
        switch d {
        case .yeni: hap("Yeni", c.pirinc)
        case .yarim(let dk): hap("\(dk) dk kaldı", c.pirinc)
        case .okundu: hap("Okundu", c.dogru)
        case .yok: EmptyView()
        }
    }

    private func hap(_ s: String, _ renk: Color) -> some View {
        Text(s).font(Yazi.sans(11, agirlik: 600)).foregroundStyle(.white)
            .padding(.horizontal, 8).frame(height: 22)
            .background(Capsule().fill(renk))
    }
}

// MARK: - Arama

/// Sade arama: sanatçı adı ya da başlık (`.arama-katman`)
struct HikayeArama: View {
    let kapat: () -> Void
    let sec: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var depo = HikayeDeposu.shared
    @State private var sorgu = ""
    @FocusState private var odak: Bool

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        let sonuc = HikayeAkisi.ara(depo.sirali, sorgu: sorgu, sanatciAdi: depo.sanatciAdi)
        let bolumSonucu = DiziKurallari.ara(depo.diziKatalogu, sorgu: sorgu, sanatciAdi: depo.sanatciAdi)
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    HikayeIkon(simge: .ara, boyut: 18, kalinlik: 1.6).foregroundStyle(c.yazi3)
                    TextField("Yazı veya sanatçı ara…", text: $sorgu)
                        .font(Yazi.sans(16))
                        .foregroundStyle(c.yazi)
                        .focused($odak)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Capsule().fill(c.yuzey))
                .overlay(Capsule().strokeBorder(c.kenar, lineWidth: 1))
                Button("Vazgeç", action: kapat)
                    .font(Yazi.sans(14, agirlik: 500))
                    .foregroundStyle(c.yazi)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 10)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !bolumSonucu.isEmpty {
                        Text("Dizi bölümleri")
                            .font(Yazi.sans(12.5, agirlik: 600))
                            .foregroundStyle(c.pirinc)
                            .padding(.top, 10).padding(.bottom, 4)
                        ForEach(bolumSonucu) { b in
                            let s = depo.satir(b.hikaye)
                            Button { sec(b.id) } label: {
                                HStack(spacing: 12) {
                                    UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 22])
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("\(depo.dizi(b.dizi)?.ad ?? "Dizi") · \(b.sira). bölüm")
                                            .font(Yazi.sans(11.5, agirlik: 600)).foregroundStyle(c.pirinc).lineLimit(1)
                                        Text(b.baslik).font(Yazi.okuma(17, agirlik: 600)).foregroundStyle(c.yazi)
                                            .lineLimit(2)
                                        Text("\(s.sanatci) · \(s.okumaDk) dk okuma")
                                            .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3).lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
                        }
                    }
                    ForEach(sonuc) { h in
                        let s = depo.satir(h)
                        Button { sec(h.id) } label: {
                            HStack(spacing: 12) {
                                UzakGorsel(url: s.kapak, icerik: .fill, yedek: s.kapakYedek, odak: [50, 22])
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(h.baslik).font(Yazi.okuma(17, agirlik: 600)).foregroundStyle(c.yazi)
                                        .lineLimit(2)
                                    Text("\(s.sanatci) · \(s.yillar) · \(s.okumaDk) dk okuma")
                                        .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3).lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
                    }
                    if sonuc.isEmpty && bolumSonucu.isEmpty {
                        Text("Bu aramayla yazı yok.").font(Yazi.sans(15)).foregroundStyle(c.yazi2).padding(.top, 24)
                    }
                }
                .padding(.horizontal, 22)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(c.zemin.ignoresSafeArea())
        .onAppear { odak = true }
    }
}
