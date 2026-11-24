// Z3v (yeni, sitede yok): Bugün → "Paylaş". Günün tablosu tek bir görsel olarak (Instagram hikâyesi 1080×1920, gönderi /
// mesaj 1080×1350) iOS paylaşım menüsüyle gönderilir.
// Tasarım: dal neon/paylas-karti-tasarim (PR #54), Yön 4 "Perde ve ayrıntı" (tasarim/paylas-karti/yon-4.html; ölçüler
// oradaki CSS'ten, CSS pikseli = kart pikseli). Geometri (kapak yerleşimi, ayrıntı çerçevesi, kare kırpım) çekirdekte:
// `PaylasKarti` (NoraCekirdek/Bugun/PaylasKarti.swift, testli). Renkler yalnız `TemaRenkleri`'nden.
import NoraCekirdek
import SwiftUI
import UIKit

/// Kartın içeriği: hepsi Bugün'ün zaten yüklediği yerden (BugunDeposu, BugunTablosu)
struct PaylasIcerigi: Identifiable {
  var id: String { tarih + "|" + (nokta?.ad ?? "") }
  let tarih: String
  let akim: String
  let eser: String
  let sanatciYil: String
  /// Yürüyüşte o an açık olan nokta (yoksa ilki)
  let nokta: BugunTablosu.Nokta?
  /// Bugün'deki odak (tablonun 0–1 kesirleri) ve yürüyüş kırpımı
  let odak: CGPoint
  let kirp: [Double]?
  /// Akımın dönemi (zemin deseni, `GaleriDonem`)
  let donem: String?
  /// Bugün'ün gösterdiği tablo: büyük kopya gelene kadar önizleme
  let onizleme: UIImage?
  /// Büyük kopya (yoksa 1280'lik)
  let adres: URL?

  @MainActor
  init(_ s: BugunTablosu, depo: BugunDeposu, adim: Int) {
    tarih = s.tablo.tarih
    akim = s.akim
    eser = s.tablo.eser
    sanatciYil = PaylasKarti.sanatciYil(s.tablo)
    nokta = PaylasKarti.noktaSirasi(adim: adim, noktaSayisi: s.kayit.noktalar.count).map { s.kayit.noktalar[$0] }
    odak = depo.odak
    kirp = depo.kirp
    donem = depo.baglam?.katalog.flatMap { GaleriDonem.akimin($0, s.akim) }
    onizleme = depo.resim
    adres = s.buyuk ?? s.tablo.gorsel
  }

  /// Tabloyu ImageRenderer'dan önce UIImage olarak yükler (ImageRenderer uzaktan yüklenen görseli beklemez):
  /// GorselDeposu'ndaki büyük kopya; inemezse Bugün'ün gösterdiği.
  func tablo() async -> UIImage? {
    if let r = await GorselCozucu.shared.resim(adres, piksel: 2560) { return r }
    return onizleme
  }
}

/// Kartın çizime hazır hali: tablo ve ayrıntının kare kırpımı
struct PaylasMalzemesi {
  let icerik: PaylasIcerigi
  let tablo: UIImage
  let kirpim: UIImage?

  init(_ icerik: PaylasIcerigi, tablo: UIImage) {
    self.icerik = icerik
    self.tablo = tablo
    let boy = CGSize(width: tablo.size.width * tablo.scale, height: tablo.size.height * tablo.scale)
    if let n = icerik.nokta, let cg = tablo.cgImage,
      let k = cg.cropping(to: PaylasKarti.kareKirpim(n.alan, resim: boy).integral)
    {
      kirpim = UIImage(cgImage: k)
    } else {
      kirpim = nil
    }
  }

  /// ImageRenderer ile PNG (scale 1: 1080 px genişlik)
  @MainActor
  func ciz(_ boy: PaylasKarti.Boy, renkler: TemaRenkleri) -> UIImage? {
    let r = ImageRenderer(content: PaylasKartiGorunumu(m: self, boy: boy, r: renkler))
    r.scale = 1
    r.proposedSize = ProposedViewSize(boy.boyut)
    r.isOpaque = true
    return r.uiImage
  }
}

/// Yön 4: kenardan kenara tablo (altta zemine eriyen), ayrıntının ince çerçevesi, akım / ad / sanatçı · yıl, cam not
/// kartı (solda ayrıntının kırpımı) ve imza
struct PaylasKartiGorunumu: View {
  let m: PaylasMalzemesi
  let boy: PaylasKarti.Boy
  let r: TemaRenkleri

  private var hikaye: Bool { boy == .hikaye }
  /// Temanın koyu ve açık ucu: tablonun üstündeki öğeler (hap, çerçeve, büyüteç) iki temada da koyu zemin + açık yazı
  private var koyu: RGBA { r.koyu ? r.zemin : r.murekkep }
  private var acik: RGBA { r.koyu ? r.murekkep : r.zemin }
  private func f(_ a: Yazi.Aile, _ boyut: CGFloat, _ agirlik: CGFloat = 400) -> Font {
    Font(Yazi.uiFont(a, boyut, agirlik: agirlik))  // Dinamik Yazı ölçeklemesi yok: kart piksel ölçülü
  }

  var body: some View {
    let b = boy.boyut
    ZStack(alignment: .topLeading) {
      zemin
      kapak
      icerikKatmani
    }
    .frame(width: b.width, height: b.height)
    .clipped()
    .environment(\.colorScheme, r.koyu ? .dark : .light)
  }

  // MARK: Zemin (`.zemin-doku`, `.zemin-hale`, `.zemin-desen`)

  private var zemin: some View {
    let b = boy.boyut
    return ZStack {
      Color(r.zemin)
      // `.zemin-doku`: 6 px aralıkla 1 px noktalar, mürekkep %3,5
      Canvas { c, s in
        var p = Path()
        var y = 3.0
        while y < s.height {
          var x = 3.0
          while x < s.width {
            p.addEllipse(in: CGRect(x: x - 0.5, y: y - 0.5, width: 1, height: 1))
            x += 6
          }
          y += 6
        }
        c.fill(p, with: .color(Color(r.murekkep, 0.035)))
      }
      // `.zemin-hale`: radial-gradient(95% 42% at 96% 100%, pirinç %24 → %7 (%48) → 0 (%82)); Gündüz'de çarparak
      RadialGradient(
        stops: [
          .init(color: Color(r.pirinc, r.koyu ? 0.24 : 0.18), location: 0),
          .init(color: Color(r.pirinc, r.koyu ? 0.07 : 0.05), location: 0.48),
          .init(color: Color(r.pirinc, 0), location: 0.82),
        ], center: UnitPoint(x: 0.96, y: 1), startRadius: 0, endRadius: 0.95 * b.width
      )
      .scaleEffect(x: 1, y: 0.42 * b.height / (0.95 * b.width), anchor: UnitPoint(x: 0.96, y: 1))
      .blendMode(r.koyu ? .normal : .multiply)
      // `.zemin-desen`: akımın dönem karosu (Galeri'nin `SayfaZemini`'ndeki), mürekkep %3,6 / %4,2
      if let d = m.icerik.donem, let karo = UIImage(named: "desen-\(d)") {
        Image(uiImage: karo).renderingMode(.template).resizable(resizingMode: .tile)
          .foregroundStyle(Color(r.murekkep, r.koyu ? 0.036 : 0.042))
      }
    }
    .frame(width: b.width, height: b.height)
  }

  // MARK: Kapak (`.kapak-resim`, `.odak-cerceve`, `.kapak-erime`)

  private var kapak: some View {
    let kutu = boy.kapak
    let boyut = CGSize(width: m.tablo.size.width, height: m.tablo.size.height)
    let k = PaylasKarti.kapak(
      resim: boyut, kirp: m.icerik.kirp, odak: m.icerik.odak, nokta: m.icerik.nokta?.alan, boy: boy)
    return ZStack(alignment: .topLeading) {
      Image(uiImage: m.tablo).resizable().interpolation(.high)
        .frame(width: k.resim.width, height: k.resim.height)
        .offset(x: k.resim.minX, y: k.resim.minY)
      if let c = k.cerceve {
        let kose = min(22, min(c.width, c.height) / 4)
        RoundedRectangle(cornerRadius: kose)
          .strokeBorder(Color(acik, 0.88), lineWidth: 2.5)
          .background(RoundedRectangle(cornerRadius: kose + 2).stroke(Color(koyu, 0.34), lineWidth: 2).padding(-1))
          .shadow(color: Color(koyu, 0.32), radius: 15, y: 12)
          .frame(width: c.width, height: c.height)
          .offset(x: c.minX, y: c.minY)
      }
      LinearGradient(
        stops: hikaye
          ? [
            .init(color: Color(koyu, r.koyu ? 0.44 : 0.24), location: 0), .init(color: Color(r.zemin, 0), location: 0.18),
            .init(color: Color(r.zemin, 0), location: 0.66), .init(color: Color(r.zemin, 0.32), location: 0.80),
            .init(color: Color(r.zemin, 0.86), location: 0.93), .init(color: Color(r.zemin, 1), location: 1),
          ]
          : [
            .init(color: Color(koyu, r.koyu ? 0.44 : 0.24), location: 0), .init(color: Color(r.zemin, 0), location: 0.20),
            .init(color: Color(r.zemin, 0), location: 0.64), .init(color: Color(r.zemin, 0.36), location: 0.78),
            .init(color: Color(r.zemin, 0.88), location: 0.92), .init(color: Color(r.zemin, 1), location: 1),
          ],
        startPoint: .top, endPoint: .bottom
      )
      .frame(width: kutu.width, height: kutu.height)
    }
    .frame(width: kutu.width, height: kutu.height, alignment: .topLeading)
    .clipped()
  }

  // MARK: İçerik (`.kart-ic`)

  private var icerikKatmani: some View {
    let b = boy.boyut
    return VStack(alignment: .leading, spacing: 0) {
      hap
      Spacer(minLength: 0)
      Text(m.icerik.akim)
        .font(f(.sans, hikaye ? 31 : 26, 600)).foregroundStyle(Color(r.pirinc))
        .padding(.bottom, hikaye ? 12 : 8)
      Text(m.icerik.eser)
        .font(f(.serif, hikaye ? 100 : 74, 500)).tracking(hikaye ? -1 : -0.74)
        .foregroundStyle(Color(r.murekkep))
        .lineLimit(2).minimumScaleFactor(0.55)
        .cssSatir(.serif, hikaye ? 100 : 74, hikaye ? 102 : 75.48)
        .fixedSize(horizontal: false, vertical: true)
      Text(m.icerik.sanatciYil)
        .font(f(.sans, hikaye ? 36 : 29)).foregroundStyle(Color(r.murekkep2))
        .lineLimit(1).minimumScaleFactor(0.7)
        .padding(.top, hikaye ? 14 : 8)
      if let n = m.icerik.nokta { notKarti(n).padding(.top, hikaye ? 40 : 26) }
      imza.padding(.top, hikaye ? 40 : 30)
    }
    .padding(.top, hikaye ? 232 : 54).padding(.horizontal, 72).padding(.bottom, hikaye ? 204 : 74)
    .frame(width: b.width, height: b.height, alignment: .topLeading)
  }

  /// `.cam-hap`: "Günün tablosu"
  private var hap: some View {
    HStack(spacing: 11) {
      Circle().fill(Color(r.pirinc)).frame(width: 10, height: 10)
      Text("Günün tablosu").font(f(.sans, hikaye ? 26 : 23, 600))
    }
    .foregroundStyle(Color(acik))
    .padding(.horizontal, hikaye ? 24 : 20).padding(.vertical, hikaye ? 12 : 10)
    .background(Capsule().fill(Color(koyu, 0.46)))
    .overlay(Capsule().strokeBorder(Color(acik, 0.22), lineWidth: 1))
  }

  /// `.yakin-kart`: cam not kartı, solda ayrıntının kırpımı
  private func notKarti(_ n: BugunTablosu.Nokta) -> some View {
    let kirpimBoy: CGFloat = hikaye ? 280 : 196
    let kose: CGFloat = hikaye ? 44 : 34
    return HStack(alignment: .center, spacing: hikaye ? 34 : 26) {
      if let k = m.kirpim {
        ZStack(alignment: .bottomTrailing) {
          Image(uiImage: k).resizable().interpolation(.high).scaledToFill()
            .frame(width: kirpimBoy, height: kirpimBoy).clipped()
          Image(systemName: "magnifyingglass")
            .font(.system(size: hikaye ? 22 : 18, weight: .medium))
            .foregroundStyle(Color(acik))
            .frame(width: hikaye ? 48 : 40, height: hikaye ? 48 : 40)
            .background(Circle().fill(Color(koyu, 0.56)))
            .overlay(Circle().strokeBorder(Color(acik, 0.22), lineWidth: 1))
            .padding(hikaye ? 14 : 11)
        }
        .frame(width: kirpimBoy, height: kirpimBoy)
        .clipShape(RoundedRectangle(cornerRadius: hikaye ? 26 : 22))
        .overlay(
          RoundedRectangle(cornerRadius: hikaye ? 26 : 22).strokeBorder(Color(r.murekkep, r.koyu ? 0.11 : 0.08), lineWidth: 1))
      }
      VStack(alignment: .leading, spacing: hikaye ? 12 : 8) {
        Text(n.ad).font(f(.sans, hikaye ? 28 : 24, 600)).foregroundStyle(Color(r.pirinc))
          .lineLimit(2)
        Text(n.metin).font(f(.okuma, hikaye ? 36 : 29)).foregroundStyle(Color(r.murekkep))
          .cssSatir(.okuma, hikaye ? 36 : 29, hikaye ? 54.72 : 41.76)
          .lineLimit(hikaye ? 8 : 5).truncationMode(.tail)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.trailing, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(hikaye ? 32 : 22)
    .background(RoundedRectangle(cornerRadius: kose).fill(Color(r.yuzey, r.koyu ? 0.72 : 0.88)))
    .overlay(RoundedRectangle(cornerRadius: kose).strokeBorder(Color(r.murekkep, r.koyu ? 0.14 : 0.12), lineWidth: 1.5))
    .shadow(color: Color(koyu, r.koyu ? 0.44 : 0.12), radius: r.koyu ? 32 : 26, y: r.koyu ? 28 : 24)
  }

  /// `.imza`: "Sanat Atlası · sanat-atlasi.pages.dev"
  private var imza: some View {
    HStack(alignment: .firstTextBaseline) {
      Text("Sanat Atlası").font(f(.serif, hikaye ? 30 : 27, 500)).tracking(hikaye ? -0.3 : -0.27)
        .foregroundStyle(Color(r.murekkep2))
      Spacer(minLength: 16)
      Text("sanat-atlasi.pages.dev").font(f(.sans, hikaye ? 26 : 24, 500)).foregroundStyle(Color(r.murekkep3))
    }
  }
}

/// Bugün'deki "Paylaş"ın açtığı yaprak: kartın önizlemesi, boy seçimi (Hikâye varsayılan) ve iOS paylaşım menüsü
struct PaylasYapragi: View {
  let icerik: PaylasIcerigi
  @Environment(TemaDeposu.self) private var tema
  @Environment(\.dismiss) private var kapat
  @State private var boy = PaylasKarti.Boy.hikaye
  @State private var malzeme: PaylasMalzemesi?
  @State private var cizilen: [PaylasKarti.Boy: (resim: UIImage, dosya: URL)] = [:]
  @State private var hata = false

  var body: some View {
    let r = tema.renkler
    NavigationStack {
      VStack(spacing: 20) {
        Picker("Boy", selection: $boy) {
          Text("Hikâye").tag(PaylasKarti.Boy.hikaye)
          Text("Gönderi").tag(PaylasKarti.Boy.gonderi)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("paylas-boy")
        Group {
          if let c = cizilen[boy] {
            Image(uiImage: c.resim).resizable().scaledToFit()
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(r.kenar), lineWidth: 1))
              .shadow(color: .black.opacity(r.koyu ? 0.4 : 0.12), radius: 18, y: 10)
              .accessibilityLabel("Paylaşılacak kart: \(icerik.eser)")
          } else if hata {
            ContentUnavailableView("Tablo yüklenemedi", systemImage: "photo")
          } else {
            ProgressView("Kart hazırlanıyor")
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        if let c = cizilen[boy] {
          ShareLink(
            item: c.dosya,
            preview: SharePreview(icerik.eser, image: Image(uiImage: c.resim))
          ) {
            Label("Paylaş", systemImage: "square.and.arrow.up")
              .font(Yazi.sans(16, agirlik: 600))
              .frame(maxWidth: .infinity, minHeight: 50)
          }
          .buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
          .tint(Color(r.vurguAcik)).foregroundStyle(Color(r.vurguAcikYazi))
          .accessibilityIdentifier("paylas-gonder")
        }
      }
      .padding(.horizontal, 24).padding(.vertical, 16)
      .background(Color(r.zemin).ignoresSafeArea())
      .navigationTitle("Günün tablosunu paylaş")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Kapat") { kapat() } }
      }
    }
    .task(id: "\(boy.rawValue)|\(r.zemin.hex)|\(r.pirinc.hex)") { await hazirla(r) }
  }

  private func hazirla(_ r: TemaRenkleri) async {
    if malzeme == nil {
      guard let t = await icerik.tablo() else {
        hata = true
        return
      }
      malzeme = PaylasMalzemesi(icerik, tablo: t)
    }
    guard let m = malzeme, !Task.isCancelled, let resim = m.ciz(boy, renkler: r) else { return }
    do {
      cizilen[boy] = (resim, try Self.dosyayaYaz(resim, boy: boy, tarih: icerik.tarih))
    } catch {
      hata = true
    }
  }

  /// "nora-sanat-<tarih>.png" (geçici klasörde; paylaşım menüsü dosyayı bu adla gönderir). Ad iki boyda aynı olduğu için
  /// her boy kendi alt klasöründe.
  static func dosyayaYaz(_ resim: UIImage, boy: PaylasKarti.Boy, tarih: String) throws -> URL {
    let klasor = FileManager.default.temporaryDirectory.appendingPathComponent("Paylas/\(boy.rawValue)", isDirectory: true)
    try FileManager.default.createDirectory(at: klasor, withIntermediateDirectories: true)
    let url = klasor.appendingPathComponent(PaylasKarti.dosyaAdi(tarih: tarih))
    guard let png = resim.pngData() else { throw CocoaError(.fileWriteUnknown) }
    try png.write(to: url, options: .atomic)
    return url
  }
}
