// Kaynak: sanat-atlasi js/ekranlar/bugun.js, js/yuruyus.js, css/app.css @ a866b86
import NoraCekirdek
import SwiftUI

/// T7: Bugün yerli sekme (G4 + G4b). DEBUG `-yalnizSite` ile site.
enum BugunGecisi {
  static var sekmeler: Set<Sekme> {
    #if DEBUG
    if CommandLine.arguments.contains("-yalnizSite") { return [] }
    #endif
    return [.bugun]
  }
}

struct BugunSekmesi: View {
  @Environment(KabukDurumu.self) private var kabuk
  @Environment(TemaDeposu.self) private var tema
  @Environment(\.scenePhase) private var evre
  @Environment(\.accessibilityReduceMotion) private var hareketAz
  @State private var depo = BugunDeposu()
  @State private var hareket = BugunHareketi()
  @State private var tarih = GunTarihi.gun(Date())
  @State private var deneme = 0
  @State private var acilan: Acilis?
  @State private var kayma = 0.0
  @State private var izlenenAdim = 0.0
  @State private var hedefAdim = 0.0
  @State private var yonKaymasi = 0.0
  @State private var izleme: Task<Void, Never>?
  @State private var yukari = false
  @State private var boylar: [Int: Double] = [:]
  @State private var perde = false
  @State private var hareketHatasi = false
  @State private var atlama: Int?
  @State private var atlamaIsi: Task<Void, Never>?
  @State private var yaziGizli = false
  @State private var cubukGizli = false
  @State private var ekranUstu = 0.0
  @State private var ekranAlti = 0.0
  @State private var konumHedefi: Double?

  private enum Acilis: String, Identifiable {
    case resim, hikaye, incele
    var id: String { rawValue }
  }
  private var durgun: Bool { hareketAz || tema.ayar.hareket == "kapali" }
  private var etkin: Bool { evre == .active && kabuk.secili == .bugun }
  // js/egim.js egimBaslat: izin gerekmiyorsa (yerlide CoreMotion izin istemez) ayar açıkken hemen dinlenir
  private var algilama: Bool { etkin && depo.egimAcik && !durgun && acilan == nil }

  var body: some View {
    Group {
      if let s = depo.sayfa, let resim = depo.resim {
        GeometryReader { g in
          yuruyus(s, resim, g.size)
        }
        .ignoresSafeArea()
      } else if let hata = depo.hata {
        ContentUnavailableView {
          Text(hata)
        } actions: {
          Button("Yeniden dene") { deneme += 1 }
        }
      } else {
        ProgressView("Günün tablosu yükleniyor")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(tema.renkler.zemin).ignoresSafeArea())
    .background {
      GeometryReader { geo in
        Color.clear.onAppear { guvenliAlan(geo) }.onChange(of: geo.safeAreaInsets) { _, _ in
          guvenliAlan(geo)
        }
      }
    }
    .task(id: "\(etkin)-\(tarih)-\(deneme)") {
      guard etkin else { return }
      await depo.yukle(tarih: tarih)
    }
    .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
      tarih = GunTarihi.gun(Date())
    }
    .onChange(of: evre) { _, yeni in if yeni == .active { tarih = GunTarihi.gun(Date()) } }
    .onChange(of: algilama) { _, ac in if ac { hareket.baslat() } else { hareket.durdur() } }
    .onDisappear {
      hareket.durdur()
      izleme?.cancel()
      izleme = nil
      atlamaIsi?.cancel()
      atlama = nil
      yaziGizli = false
    }
    .alert("Hareket ayarı kaydedilemedi", isPresented: $hareketHatasi) { Button("Tamam") {} }
    .sekmeCubuguGizli(cubukGizli && etkin, sekme: .bugun)
    .fullScreenCover(item: $acilan) { kip in
      if let e = depo.sayfa?.eser {
        Goruntuleyici(
          eserler: [e], baslangic: 0, incelemeyeBasla: kip == .incele,
          hikayeyeBasla: kip == .hikaye, baglam: depo.baglam)
      }
    }
  }

  private func guvenliAlan(_ geo: GeometryProxy) {
    // Kabuğun sekme çubuğu için yaptığı ek inset ölçüye ikinci kez katılmasın.
    let pencere = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }?.keyWindow
    ekranUstu = Double(pencere?.safeAreaInsets.top ?? geo.safeAreaInsets.top)
    ekranAlti = max(12, pencere?.safeAreaInsets.bottom ?? 0)
  }

  private func yuruyus(_ s: BugunTablosu, _ resim: UIImage, _ boy: CGSize) -> some View {
    let kamera = YuruyusKamerasi(
      ekran: boy, oran: resim.size.width / max(1, resim.size.height), kirp: depo.kirp)
    let ust = ekranUstu + 68
    let alt = ekranAlti + 62 + 26
    let h = max(1, boy.height)
    let adimlar = kamera.duruslar(
      odak: depo.odak, yakin: depo.yakin, noktalar: s.kayit.noktalar.map(\.alan),
      kartBoylari: boylar, ust: ust, alt: alt, taninma: !s.taninma.isEmpty)
    let son = adimlar.count - 1
    let p = min(Double(son), max(0, izlenenAdim))
    let i = Int(p)
    let d =
      atlama.map { adimlar[min(son, $0)] }
      ?? adimlar[i].ara(adimlar[min(i + 1, son)], pay: p - Double(i))
    let asma = atlama.map { $0 == 0 ? 0.0 : 1.0 } ?? min(1, max(0, (kayma / h - Double(son)) / 0.6))
    let gizle = kayma / h > 0.5 && asma < 0.5 && !yukari
    let yatayAci = Double(hareket.deger?.x ?? 0) * 3.0
    let dikeyAci = -Double(hareket.deger?.y ?? 0) * 3.0
    let cerceve = kamera.cerceve(d, buyut: perde || durgun ? 1 : 1.08, egim: hareket.deger)
    return ScrollViewReader { kaydir in
      ZStack(alignment: .topLeading) {
        ZStack(alignment: .topLeading) {
          // `.yur-sahne` zemini #0b0a09; resmi kamera taşır
          YurRenk.hex("#0b0a09")
          Image(uiImage: resim).resizable()
            .frame(width: cerceve.width, height: cerceve.height)
            .position(x: cerceve.midX, y: cerceve.midY)
            .frame(width: boy.width, height: h, alignment: .topLeading)
            .rotation3DEffect(.degrees(yatayAci), axis: (0, 1, 0))
            .rotation3DEffect(.degrees(dikeyAci), axis: (1, 0, 0))
          // `.yur-sahne::after`
          LinearGradient(
            stops: [
              .init(color: YurRenk.zemin(0.5), location: 0), .init(color: YurRenk.zemin(0), location: 0.16),
              .init(color: YurRenk.zemin(0), location: 0.5), .init(color: YurRenk.zemin(0.8), location: 0.78),
              .init(color: YurRenk.zemin(0.96), location: 1),
            ], startPoint: .top, endPoint: .bottom)
        }
        .accessibilityHidden(true)
        Color(tema.renkler.zemin)
          .scaleEffect(x: 1, y: perde || durgun ? 0 : 1, anchor: .top)
          .animation(durgun ? nil : .timingCurve(0.7, 0, 0.2, 1, duration: 1.1), value: perde)
        // `.yur-bulanik`: backdrop-filter blur(18px) + rgba(18, 17, 16, 0.6), saydamlığı perde (asma). Büyük resmin
        // kendisine .blur verince (G4b ilk deneme) görüntü bantlı ve karanlık çıktı; arka plan bulanıklığı sitedekinin aynısı.
        ZStack {
          Rectangle().fill(.ultraThinMaterial)
          YurRenk.zemin(0.6)
        }
        .environment(\.colorScheme, .dark).opacity(asma).allowsHitTesting(false).accessibilityHidden(true)
        ScrollView {
          VStack(spacing: 0) {
            kapak(s) { suzul(hedef: son) { kaydir.scrollTo("hayat", anchor: .top) } }
              .frame(height: h).id(0)
            ForEach(1...son, id: \.self) { n in
              let nokta = s.kayit.noktalar.indices.contains(n - 2) ? s.kayit.noktalar[n - 2] : nil
              let baslik = n == 1 ? s.tablo.eser : (nokta?.ad ?? "Nasıl tanırım?")
              let metin = n == 1 ? s.kunye : (nokta?.metin ?? s.taninma)
              kart(baslik, metin, n)
                .padding(.leading, 16).padding(.trailing, 38)
                .padding(.top, ust).padding(.bottom, alt)
                .frame(height: h, alignment: adimlar[n].kartUstte ? .top : .bottom)
                .id(n)
            }
            BugunHayati(
              s: s, kucukler: depo.kucukler, kunye: depo.kunye, adet: kabuk.calisRozeti, git: git
            ) {
              suzul(hedef: 0) { kaydir.scrollTo(0, anchor: .top) }
            }
            .padding(.top, ekranUstu + 84).padding(.bottom, alt + 14)
            .frame(minHeight: h, alignment: .top)
            .id("hayat")
          }
          .opacity(yaziGizli ? 0 : 1)
          .modifier(BugunKaymaIzi(icerik: true) { kaydi($0, son: son, h: h) })
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(BugunOturmasi(boy: h, hayat: Double(son + 1) * h))
        .modifier(BugunKaymaIzi(icerik: false) { kaydi($0, son: son, h: h) })
        #if DEBUG
          .modifier(BugunKonumaGit(y: konumHedefi))
        #endif
        .onPreferenceChange(BugunKartBoyu.self) { boylar = $0 }
        ustCubuk(perde: asma)
        if p >= 0.5 && asma < 0.3 {
          VStack(spacing: 8) {
            ForEach(0...son, id: \.self) { j in
              Capsule().fill(
                j == Int(p.rounded()) ? Color(tema.renkler.pirinc) : YurRenk.acik(0.45)
              )
              .frame(width: 3, height: j == Int(p.rounded()) ? 26 : 8)
            }
          }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing).padding(
            .trailing, 10
          )
          .allowsHitTesting(false).accessibilityHidden(true)
        }
      }
      .frame(width: boy.width, height: h).clipped()
      .onChange(of: gizle, initial: true) { _, yeni in cubukGizli = yeni }
      .onChange(of: kabuk.yenidenDokunma[.bugun]) { _, _ in kaydir.scrollTo(0, anchor: .top) }
      .onChange(of: kabuk.yerliAdres[.bugun], initial: true) { _, adres in
        guard let adres else { return }
        if adres.hasPrefix("#/gunun/") {
          git("#/sanatci/" + String(adres.dropFirst("#/gunun/".count)), .galeri)
        } else if adres == "#/gunun" {
          kaydir.scrollTo("hayat", anchor: .top)
        } else {
          kaydir.scrollTo(0, anchor: .top)
        }
        kabuk.adresIslendi(.bugun)
      }
      #if DEBUG
      .task(id: boylar) {
        guard let bolum = NoraSanatApp.arguman("-bugunKaydir"), boylar.count >= son else { return }
        do {
          try await Task.sleep(for: .milliseconds(400))
          switch bolum {
          case "ayrinti-alt", "ayrinti-ust":
            guard let n = Int(NoraSanatApp.arguman("-bugunAdim") ?? ""),
                  s.kayit.noktalar.indices.contains(n - 2),
                  adimlar[n].kartUstte == (bolum == "ayrinti-ust") else { return }
            kaydir.scrollTo(n, anchor: .top)
          case "hayati", "eserler", "tur":
            if let konum = NoraSanatApp.arguman("-bugunKonum").flatMap(Double.init) {
              // Hayatı, kapak ve son + 1 adımdan sonra başlar; site de aynı konumda
              kaydir.scrollTo("hayat", anchor: .top)
              try await Task.sleep(for: .milliseconds(300))
              konumHedefi = Double(son + 1) * h + konum
            } else if bolum == "hayati" {
              kaydir.scrollTo("hayat", anchor: .top)
            } else {
              kaydir.scrollTo(bolum, anchor: bolum == "tur" ? UnitPoint(x: 0.5, y: 0.85) : .center)
            }
          default: return
          }
          try await Task.sleep(for: .seconds(4))
          for _ in 0..<40 where abs(izlenenAdim - hedefAdim) > 0.001 {
            try await Task.sleep(for: .milliseconds(250))
          }
          let ip = min(Double(son), max(0, izlenenAdim))
          let dd = adimlar[Int(ip)].ara(adimlar[min(Int(ip) + 1, son)], pay: ip - Double(Int(ip)))
          let c = kamera.cerceve(dd, buyut: 1, egim: nil)
          let durum = "kayma \(Int(kayma)) adim \(String(format: "%.3f", izlenenAdim)) ekran \(Int(h)) ust \(ust) alt \(alt) "
            + "kart \(boylar[Int(ip.rounded())].map { String(format: "%.1f", $0) } ?? "-") "
            + "cerceve \(String(format: "%.1f %.1f %.4f", c.minX, c.minY, c.width / kamera.resim.width))"
          try Data(durum.utf8).write(to: FileManager.default.temporaryDirectory
            .appendingPathComponent("bugun-durum"), options: .atomic)
          try Data(bolum.utf8).write(to: FileManager.default.temporaryDirectory
            .appendingPathComponent("bugun-hazir"), options: .atomic)
        } catch {}
      }
      #endif
      .onAppear {
        #if DEBUG
          if CommandLine.arguments.contains("-bugunKarsilastir"), NoraSanatApp.arguman("-bugunKaydir") == nil {
            try? Data(s.tablo.sanatciId.utf8).write(
              to: FileManager.default.temporaryDirectory.appendingPathComponent("bugun-hazir"),
              options: .atomic)
          }
        #endif
        withAnimation(durgun ? nil : .easeOut(duration: 2.6)) { perde = true }
      }
    }
  }

  private func kaydi(_ y: Double, son: Int, h: Double) {
    if abs(y - yonKaymasi) > 6 {
      yukari = y < yonKaymasi
      yonKaymasi = y
    }
    kamerayiIzle(min(Double(son), max(0, y / h)))
    kayma = y
  }

  private func kamerayiIzle(_ hedef: Double) {
    hedefAdim = hedef
    guard !durgun, atlama == nil else {
      izlenenAdim = hedef
      return
    }
    guard izleme == nil else { return }
    izleme = Task { @MainActor in
      while !Task.isCancelled, izlenenAdim != hedefAdim {
        izlenenAdim = YuruyusKamerasi.sonrakiKare(izlenenAdim, hedef: hedefAdim)
        try? await Task.sleep(for: .milliseconds(16))
      }
      if !Task.isCancelled { izleme = nil }
    }
  }

  private func suzul(hedef: Int, kaydir: @escaping () -> Void) {
    guard !durgun else {
      kaydir()
      return
    }
    atlamaIsi?.cancel()
    withAnimation(.easeInOut(duration: 0.82)) { yaziGizli = true }
    withAnimation(.easeInOut(duration: 2.8)) { atlama = hedef }
    atlamaIsi = Task { @MainActor in
      do {
        try await Task.sleep(for: .milliseconds(820))
        kaydir()
        withAnimation(.easeOut(duration: 1.6)) { yaziGizli = false }
        try await Task.sleep(for: .milliseconds(1980))
        atlama = nil
      } catch {}
    }
  }

  /// `.bugun-ust`: tarih ve Ben sabit; Hayatı'na inerken arkasında koyu bir şerit belirir (`::before`, `--perde`)
  private func ustCubuk(perde asmaUst: Double) -> some View {
    HStack {
      Text(
        Date().formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR")))
          .uppercased(with: Locale(identifier: "tr_TR"))
      )
      .font(Yazi.sans(11.5, agirlik: 600)).tracking(2.3)
      .foregroundStyle(Color(.sRGB, red: 172 / 255, green: 164 / 255, blue: 152 / 255))
      Spacer()
      Button { git("#/ilerleme", .ben) } label: {
        Text("BEN").font(Yazi.sans(11, agirlik: 600)).tracking(0.66).foregroundStyle(YurRenk.yazi)
          .frame(width: 44, height: 44)
          .background(YurRenk.zemin(0.5), in: Circle())
          .overlay(Circle().strokeBorder(Color(.sRGB, red: 104 / 255, green: 78 / 255, blue: 61 / 255, opacity: 0.28)))
          .contentShape(Circle())
      }.buttonStyle(.plain).accessibilityLabel("Ben: ilerleme ve ayarlar")
    }
    .frame(height: 44)
    .padding(.horizontal, 24).padding(.top, ekranUstu + 10)
    .background(alignment: .top) {
      LinearGradient(
        stops: [.init(color: YurRenk.zemin(0.92), location: 0.55), .init(color: YurRenk.zemin(0), location: 1)],
        startPoint: .top, endPoint: .bottom
      )
      .frame(height: ekranUstu + 10 + 44 + 40)
      .opacity(asmaUst).allowsHitTesting(false)
    }
  }

  /// `.bugun-notlar .egim-dugme`: kapakta Ben'in altında (44, aralık 12); kapakla birlikte kayar
  @ViewBuilder private var egimDugmesi: some View {
    if !durgun {
      Button {
        let yeni = !algilama
        Task {
          do {
            _ = try await IlerlemeKoprusu.shared.degistir { $0.ayarla("egim", .mantik(yeni)) }
            depo.egimAcik = yeni
          } catch { hareketHatasi = true }
        }
      } label: {
        BenIkon(simge: .hareket, boyut: 18, kalinlik: 1.6).foregroundStyle(YurRenk.yazi)
          .frame(width: 44, height: 44)
          .background(YurRenk.zemin(0.45), in: Circle())
          .overlay(Circle().strokeBorder(YurRenk.acik(0.18)))
          .contentShape(Circle())
      }
      .buttonStyle(.plain).disabled(!hareket.varMi)
      .accessibilityLabel(algilama ? "Hareketi kapat" : "Hareketi aç")
      .padding(.top, ekranUstu + 66).padding(.trailing, 24)
    }
  }

  private func kapak(_ s: BugunTablosu, hayat: @escaping () -> Void) -> some View {
    ZStack(alignment: .bottomLeading) {
      Button {
        acilan = .resim
      } label: {
        Color.clear.contentShape(Rectangle()).frame(maxWidth: .infinity, maxHeight: .infinity)
      }.disabled(s.eser == nil).accessibilityLabel("Resmi tam ekran aç")
      egimDugmesi.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
      VStack(alignment: .leading, spacing: 6) {
        Button {
          git("#/sanatci/" + s.tablo.sanatciId, .galeri)
        } label: {
          VStack(alignment: .leading, spacing: 0) {
            if !s.ad.ilk.isEmpty {
              Text(s.ad.ilk).font(Yazi.serif(22, italik: true)).cssSatir(.serif, 22, 25.3)
            }
            Text(s.ad.son).font(Yazi.serif(64)).cssSatir(.serif, 64, 62.72).tracking(-0.64)
              .lineLimit(1).minimumScaleFactor(34.0 / 64)
          }
        }
        if let imza = depo.imza {
          Image(uiImage: imza).renderingMode(.template).resizable().scaledToFit()
            .frame(
              width: min(190, 48 * imza.size.width / max(1, imza.size.height)), height: 48,
              alignment: .leading
            )
            .foregroundStyle(Color(tema.renkler.pirinc)).accessibilityLabel(
              s.tablo.sanatci + " imzası")
        } else {
          Text(s.tablo.eserSatiri).font(Yazi.okuma(17, italik: true)).cssSatir(.okuma, 17, 22.95)
        }
        HStack(spacing: 8) {
          if let e = s.eser, depo.baglam?.hikaye(e) != nil {
            hap("Hikâyesi", "book") { acilan = .hikaye }
          }
          if let e = s.eser, depo.baglam?.ayrinti(e) != nil {
            hap("İncele", "magnifyingglass") { acilan = .incele }
          }
          hap("Hayatı", "arrow.down", hayat)
        }.padding(.top, 12)
      }.padding(.horizontal, 24).padding(.bottom, ekranAlti + 124)
        .opacity(perde || durgun ? 1 : 0)
      Image(systemName: "chevron.down").frame(maxWidth: .infinity).padding(.bottom, ekranAlti + 92)
        .accessibilityHidden(true).allowsHitTesting(false)
    }.buttonStyle(.plain).foregroundStyle(.white)
  }

  private func hap(_ ad: String, _ simge: String, _ yap: @escaping () -> Void) -> some View {
    Button(action: yap) {
      HStack(spacing: 6) {
        if simge == "arrow.down" {
          Image(systemName: simge).font(.system(size: 15)).frame(width: 30, height: 30)
            .background(.white.opacity(0.16), in: Circle())
        } else {
          Image(systemName: simge)
        }
        Text(ad).font(Yazi.sans(15, agirlik: 600))
      }.padding(.leading, simge == "arrow.down" ? 7 : 12).padding(.trailing, 12).frame(minHeight: 48)
    }.background(.black.opacity(0.48), in: Capsule()).overlay(
      Capsule().stroke(.white.opacity(0.28)))
  }

  private func kart(_ baslik: String, _ metin: String, _ n: Int) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(baslik).font(Yazi.serif(26)).cssSatir(.serif, 26, 29.12).accessibilityAddTraits(
        .isHeader)
      Text(metin).font(Yazi.okuma(18)).bugunOkumaSatiri(18, 27).fixedSize(
        horizontal: false, vertical: true)
    }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 18)
      .padding(.bottom, 20).padding(1)  // border-box: 1 px kenarlık boyuta dahil
      // `.yur-kart`: rgba(24, 22, 20, 0.5) + blur(14px) saturate(1.1), 1 px rgba(235, 229, 218, 0.14) çizgi
      .foregroundStyle(YurRenk.yazi)
      .background {
        ZStack {
          RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
          RoundedRectangle(cornerRadius: 20).fill(YurRenk.cam(0.5))
        }
      }
      .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(YurRenk.acik(0.14), lineWidth: 1))
      .environment(\.colorScheme, .dark)
      .background {
        GeometryReader { g in
          Color.clear.preference(key: BugunKartBoyu.self, value: [n: g.size.height])
        }
      }
  }

  private func git(_ adres: String, _ sekme: Sekme) {
    kabuk.sec(sekme)
    Gezgin.shared.git(adres)
  }
}

/// Kaydırma konumu. G4'te içeriğin arkasındaki GeometryReader tercihi kaydırınca güncellenmiyordu (CI'da kamera,
/// perde ve sekme çubuğu yerinde kaldı). iOS 18'de ScrollView'in kaydırma geometrisi doğrudan okunur (`icerik: false`,
/// ScrollView'e takılır); iOS 17'de içeriğin `.scrollView` uzayındaki yeri (`icerik: true`, içeriğe takılır).
private struct BugunKaymaIzi: ViewModifier {
  let icerik: Bool
  let degisti: (Double) -> Void
  func body(content: Content) -> some View {
    if #available(iOS 18, *) {
      if icerik {
        content
      } else {
        content.onScrollGeometryChange(for: Double.self) { $0.contentOffset.y + $0.contentInsets.top } action: {
          _, y in degisti(y)
        }
      }
    } else if icerik {
      content.onGeometryChange(for: Double.self) { -$0.frame(in: .scrollView).minY } action: { degisti($0) }
    } else {
      content
    }
  }
}
#if DEBUG
  /// CI: Hayatı'nda sitenin kaydırdığı yere git (iOS 18 ScrollPosition; iOS 17'de yalnız bölüm başı)
  private struct BugunKonumaGit: ViewModifier {
    let y: Double?
    func body(content: Content) -> some View {
      if NoraSanatApp.arguman("-bugunKonum") == nil {
        content
      } else if #available(iOS 18, *) {
        content.modifier(Konum18(y: y))
      } else {
        content
      }
    }
  }
  @available(iOS 18, *)
  private struct Konum18: ViewModifier {
    let y: Double?
    @State private var konum = ScrollPosition()
    func body(content: Content) -> some View {
      content.scrollPosition($konum).onChange(of: y) { _, y in
        if let y { konum.scrollTo(y: y) }
      }
    }
  }
#endif

private struct BugunKartBoyu: PreferenceKey {
  static let defaultValue: [Int: Double] = [:]
  static func reduce(value: inout [Int: Double], nextValue: () -> [Int: Double]) {
    value.merge(nextValue()) { _, b in b }
  }
}

private struct BugunOturmasi: ScrollTargetBehavior {
  let boy, hayat: Double
  func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
    guard boy > 0, target.rect.minY < hayat else { return }
    let eski = (context.originalTarget.rect.minY / boy).rounded()
    let yeni = min(eski + 1, max(eski - 1, (target.rect.minY / boy).rounded()))
    target.rect.origin.y = max(0, min(hayat, yeni * boy))
  }
}
