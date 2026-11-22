// Kaynak: sanat-atlasi js/ekranlar/bugun.js, js/yuruyus.js, css/app.css @ a866b86
import NoraCekirdek
import SwiftUI

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
  @State private var izin = false
  @State private var hareketHatasi = false
  @State private var atlama: Int?
  @State private var atlamaIsi: Task<Void, Never>?
  @State private var yaziGizli = false
  @State private var cubukGizli = false
  @State private var ekranUstu = 0.0
  @State private var ekranAlti = 0.0

  private enum Acilis: String, Identifiable {
    case resim, hikaye, incele
    var id: String { rawValue }
  }
  private var durgun: Bool { hareketAz || tema.ayar.hareket == "kapali" }
  private var etkin: Bool { evre == .active && kabuk.secili == .bugun }
  private var algilama: Bool { etkin && izin && depo.egimAcik && !durgun && acilan == nil }

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
        Image(uiImage: resim).resizable()
          .frame(width: cerceve.width, height: cerceve.height)
          .position(x: cerceve.midX, y: cerceve.midY)
          .frame(width: boy.width, height: h, alignment: .topLeading)
          .rotation3DEffect(.degrees(yatayAci), axis: (0, 1, 0))
          .rotation3DEffect(.degrees(dikeyAci), axis: (1, 0, 0))
          .blur(radius: asma * 16).accessibilityHidden(true)
        LinearGradient(
          stops: [
            .init(color: .black.opacity(0.6), location: 0), .init(color: .clear, location: 0.18),
            .init(color: .clear, location: 0.5), .init(color: .black.opacity(0.55), location: 0.74),
            .init(color: .black.opacity(0.9), location: 1),
          ], startPoint: .top, endPoint: .bottom)
        Color(tema.renkler.zemin)
          .scaleEffect(x: 1, y: perde || durgun ? 0 : 1, anchor: .top)
          .animation(durgun ? nil : .timingCurve(0.7, 0, 0.2, 1, duration: 1.1), value: perde)
        Color.black.opacity(asma * 0.7)
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
            .padding(.top, ekranUstu + 84).padding(.bottom, alt + 14).id("hayat")
          }
          .opacity(yaziGizli ? 0 : 1)
          .background {
            GeometryReader { g in
              Color.clear.preference(
                key: BugunKayma.self, value: -g.frame(in: .named("bugun")).minY)
            }
          }
        }
        .coordinateSpace(name: "bugun").scrollIndicators(.hidden)
        .scrollTargetBehavior(BugunOturmasi(boy: h, hayat: Double(son + 1) * h))
        .onPreferenceChange(BugunKayma.self) { y in
          if abs(y - yonKaymasi) > 6 {
            yukari = y < yonKaymasi
            yonKaymasi = y
          }
          kamerayiIzle(min(Double(son), max(0, y / h)))
          kayma = y
        }
        .onPreferenceChange(BugunKartBoyu.self) { boylar = $0 }
        ustCubuk
        if p >= 0.5 && asma < 0.3 {
          VStack(spacing: 8) {
            ForEach(0...son, id: \.self) { j in
              Capsule().fill(
                j == Int(p.rounded()) ? Color(tema.renkler.vurgu) : .white.opacity(0.45)
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
      .onAppear {
        #if DEBUG
          if CommandLine.arguments.contains("-bugunKarsilastir") {
            try? Data(s.tablo.sanatciId.utf8).write(
              to: FileManager.default.temporaryDirectory.appendingPathComponent("bugun-hazir"),
              options: .atomic)
          }
        #endif
        withAnimation(durgun ? nil : .easeOut(duration: 2.6)) { perde = true }
      }
    }
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

  private var ustCubuk: some View {
    VStack(alignment: .trailing, spacing: 12) {
      HStack {
        Text(
          Date().formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR")))
            .uppercased(with: Locale(identifier: "tr_TR"))
        )
        .font(Yazi.sans(11, agirlik: 600)).tracking(2)
        Spacer()
        Button("BEN") { git("#/ilerleme", .ben) }
          .font(Yazi.sans(11, agirlik: 600)).frame(width: 44, height: 44)
          .background(.black.opacity(0.35), in: Circle()).overlay(Circle().stroke(.white.opacity(0.18))).accessibilityLabel(
            "Ben: ilerleme ve ayarlar")
      }
      if !durgun && kayma < 1 {
        Button {
          let yeni = !algilama
          Task {
            do {
              _ = try await IlerlemeKoprusu.shared.degistir { $0.ayarla("egim", .mantik(yeni)) }
              depo.egimAcik = yeni
              izin = yeni
            } catch { hareketHatasi = true }
          }
        } label: {
          BenIkon(simge: .hareket, boyut: 18, kalinlik: 1.6).frame(width: 44, height: 44)
        }.background(.black.opacity(0.35), in: Circle())
          .overlay(Circle().stroke(.white.opacity(0.18))).disabled(!hareket.varMi).accessibilityLabel(
          izin ? "Hareketi kapat" : "Hareketi aç")
      }
    }.foregroundStyle(.white).padding(.horizontal, 24).padding(.top, ekranUstu + 10)
  }

  private func kapak(_ s: BugunTablosu, hayat: @escaping () -> Void) -> some View {
    ZStack(alignment: .bottomLeading) {
      Button {
        acilan = .resim
      } label: {
        Color.clear.contentShape(Rectangle()).frame(maxWidth: .infinity, maxHeight: .infinity)
      }.disabled(s.eser == nil).accessibilityLabel("Resmi tam ekran aç")
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
      Text(metin).font(Yazi.okuma(18)).cssSatir(.okuma, 18, 27).fixedSize(
        horizontal: false, vertical: true)
    }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.top, 18)
      .padding(.bottom, 20)
      .foregroundStyle(Color(white: 0.92)).background(
        .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20)
      )
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

private struct BugunKayma: PreferenceKey {
  static let defaultValue = 0.0
  static func reduce(value: inout Double, nextValue: () -> Double) { value = nextValue() }
}
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
