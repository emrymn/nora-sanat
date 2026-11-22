// Kaynak: sanat-atlasi js/ekranlar/pekistir.js (pekistirMenusu, donemListesi), js/deste.js (desteEgilimi, sarkacAdim),
// css/app.css (.pk-sahne, .pk-deste, .pk-kart, .pk-govde, .pk-sayi, .tur-karisim, .tur-lejant, .hedef-sec, .pk-salonlar, .salon) @ a866b86
import CoreMotion
import NoraCekirdek
import SwiftUI

/// Döneme göre / Turlar ekranı (`#/pekistir/donem`): bugünkü karışık tur sahnesi (3'lü kart destesi + `DesteFizigi`),
/// günlük hedef seçici, yarım kalan tur ve dönem salonları.
@MainActor
struct DonemTurlariGorunumu: View {
    @Bindable var model: PekistirmeModeli
    var salonlaraIn: Bool = false
    let geri: () -> Void
    let turBaslat: (PekistirmeKipi, Int?) -> Void

    @Environment(TemaDeposu.self) private var tema
    @State private var siralama: DonemSiralamasi = .sira
    @State private var desteHareketi = DesteHareketYoneticisi()

    var body: some View {
        let r = tema.renkler
        if let katalog = model.katalog, let il = model.ilerleme {
            let karisik = CalisKurallari.turBilgisi(
                sanatcilar: katalog.sanatcilar,
                ilerleme: il,
                bugun: model.bugun,
                karisik: true
            )
            let acikSanatcilar = il.acikSanatcilar(katalog.sanatcilar)
            ScrollViewReader { kaydir in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sahne(karisik: karisik, katalog: katalog, il: il)
                            .id("sahne")

                        VStack(alignment: .leading, spacing: 0) {
                            hedefSecici(il: il)
                                .padding(.top, 18)

                            if let tur = model.kayit, !tur.bitti {
                                CalisDevamKarti(model: model, tur: tur) {
                                    model.turAcik = true
                                } bitir: {
                                    Task { await model.yarimBitir() }
                                }
                                .padding(.top, 16)
                            }

                            salonlarBolumu(katalog: katalog, il: il, acikSanatcilar: acikSanatcilar)
                                .padding(.top, 34)
                                .id("salonlar")
                        }
                        .padding(.horizontal, BenOlcu.yan)
                        .padding(.bottom, 128)
                    }
                    .frame(maxWidth: 640, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .ignoresSafeArea(edges: .top)
                .task {
                    if salonlaraIn {
                        try? await Task.sleep(for: .milliseconds(120))
                        withAnimation(.easeOut(duration: 0.35)) {
                            kaydir.scrollTo("salonlar", anchor: .top)
                        }
                    }
                    #if DEBUG
                    if NoraSanatApp.arguman("-calisKaydir") == "salon" {
                        try? await Task.sleep(for: .seconds(2))
                        kaydir.scrollTo("salonlar", anchor: .top)
                    }
                    try? await Task.sleep(for: .seconds(2))
                    try? Data().write(to: CalisKarsilastirma.hazir)
                    #endif
                }
            }
            .onAppear {
                model.yeniZiyaretKapagiSec()
                if !tema.ayar.hareketAzaltilmis {
                    desteHareketi.baslat()
                }
            }
            .onDisappear {
                desteHareketi.durdur()
            }
        } else {
            ProgressView("Turlar hazırlanıyor…")
                .font(Yazi.sans(15))
                .foregroundStyle(Color(r.murekkep2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Üst Sahne (`.pk-sahne`)

    private func sahne(karisik: TurOzeti, katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let desteSanatcilari = CalisKurallari.sahneDestesi(
            sanatcilar: katalog.sanatcilar,
            ilerleme: il,
            bugun: model.bugun
        )
        let kapakSanatci = model.kapakSanatciId.flatMap { model.sanatci($0) }
            ?? desteSanatcilari.first
            ?? il.acikSanatcilar(katalog.sanatcilar).first
        let kapakEser: Eser? = {
            if let sid = kapakSanatci?.id {
                if let anahtar = model.kapakEserAnahtari, let e = model.eser(sid, anahtar) {
                    return e
                }
                return Temsil.enBilinen(katalog.eserler(sid), kotuler: il.kotuGorseller)
            }
            return nil
        }()
        let baslatEserleri: [URL?] = {
            guard let ilk = desteSanatcilari.first else { return [] }
            let sirali = Temsil.bilinirlikSirasi(
                katalog.eserler(ilk.id).filter { GorselAdresleri.secilen($0, kotuler: il.kotuGorseller) != nil && $0.pekistirme }
            )
            return Array(sirali.prefix(4)).map { model.gorsel($0, 400) }
        }()

        return ZStack(alignment: .bottomLeading) {
            // Arka plan tablosu (`.pk-resim`)
            GeometryReader { g in
                ZStack {
                    Color(r.yuzey)
                    if let kapakEser {
                        UzakGorsel(url: model.gorsel(kapakEser, 960), icerik: .fill)
                            .frame(width: g.size.width, height: g.size.height)
                            .clipped()
                    }
                    // `.pk-sahne::before` gradyanı
                    LinearGradient(
                        stops: [
                            .init(color: Color(r.zemin).opacity(0.85), location: 0.0),
                            .init(color: Color(r.zemin).opacity(0.10), location: 0.26),
                            .init(color: Color(r.zemin).opacity(0.25), location: 0.46),
                            .init(color: Color(r.zemin).opacity(0.92), location: 0.74),
                            .init(color: Color(r.zemin), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                // `.pk-ust`: "ÇALIŞ" üst etiketi ve "Turlar" başlığı
                VStack(alignment: .leading, spacing: 2) {
                    Etiket("Çalış")
                        .padding(.leading, 44)
                    BenUst(baslik: "Turlar", boyut: 48, geri: geri)
                }
                .padding(.top, 56)

                // `.pk-deste`: 3'lü kart destesi + DesteFizigi
                yelpazeDestesi(sanatcilar: desteSanatcilari, katalog: katalog, il: il)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: desteSanatcilari.isEmpty ? 80 : 170)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                // `.pk-govde`: Bugünkü tur sayısı, karışım çubuğu, lejant, TabloDugme
                VStack(alignment: .leading, spacing: 10) {
                    Text("BUGÜNKÜ TUR")
                        .font(Yazi.sans(11, agirlik: 600, stil: .caption2))
                        .tracking(2.2)
                        .foregroundStyle(Color(r.vurguAcik))

                    HStack(alignment: .bottom, spacing: 10) {
                        Text("\(karisik.toplam)")
                            .font(Yazi.serif(96))
                            .tracking(-1.92)
                            .cssSatir(.serif, 96, 74.88)
                            .foregroundStyle(Color(r.murekkep))
                            .accessibilityIdentifier("tur-sayi")
                        Text("kart\(karisik.toplam > 0 ? "\n~\(karisik.yaklasikDakika) dk" : "")")
                            .font(Yazi.sans(13, agirlik: 500))
                            .cssSatir(.sans, 13, 16.9)
                            .foregroundStyle(Color(r.murekkep2))
                            .padding(.bottom, 6)
                    }

                    if karisik.toplam > 0 {
                        karisimCubugu(karisik)
                        karisimLejanti(karisik)
                    }

                    TabloDugme(
                        baslik: "Turu başlat",
                        alt: CalisKurallari.turAltYazisi(karisik),
                        sayi: karisik.toplam,
                        eserler: baslatEserleri
                    ) {
                        turBaslat(.sanatci(.karisik), nil)
                    }
                    .accessibilityIdentifier("karisik-dugme")
                }
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.bottom, 22)
        }
        .frame(minHeight: 610)
    }

    private func yelpazeDestesi(sanatcilar: [Sanatci], katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let acilim = desteHareketi.acilim
        let yatma = desteHareketi.yatma
        return ZStack {
            ForEach(Array(sanatcilar.enumerated()), id: \.offset) { i, s in
                let orta = i == 1
                let d = Double(i - 1)
                let temelAci = d * 13.0
                let egimAci = d * acilim * 11.0 + yatma
                let temelX = CGFloat(i - 1) * 54.0
                let egimX = CGFloat(d * acilim * 14.0)
                let egimY = CGFloat(acilim * -6.0)
                let eser = Temsil.enBilinen(katalog.eserler(s.id), kotuler: il.kotuGorseller)

                UzakGorsel(url: eser.flatMap { model.gorsel($0, 320) }, icerik: .fill)
                    .frame(width: orta ? 108 : 92, height: orta ? 148 : 128)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color(r.murekkep), lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.55), radius: 20, y: 12)
                    .rotationEffect(.degrees(temelAci + egimAci), anchor: UnitPoint(x: 0.5, y: 1.2))
                    .offset(x: temelX + egimX, y: (orta ? -5 : 0) + egimY)
                    .zIndex(orta ? 9 : Double(1 + i))
            }
        }
        .accessibilityHidden(true)
    }

    private func karisimCubugu(_ tur: TurOzeti) -> some View {
        let r = tema.renkler
        let toplam = max(1, CGFloat(tur.toplam))
        return GeometryReader { g in
            HStack(spacing: 3) {
                if tur.tekrar > 0 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(r.vurguAcik))
                        .frame(width: max(6, g.size.width * CGFloat(tur.tekrar) / toplam))
                }
                if tur.pekistirme > 0 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(r.murekkep2))
                        .frame(width: max(6, g.size.width * CGFloat(tur.pekistirme) / toplam))
                }
                if tur.yeni > 0 {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(r.dogruIkon))
                        .frame(width: max(6, g.size.width * CGFloat(tur.yeni) / toplam))
                }
            }
        }
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityHidden(true)
    }

    private func karisimLejanti(_ tur: TurOzeti) -> some View {
        let r = tema.renkler
        return HStack(spacing: 10) {
            if tur.tekrar > 0 {
                lejantOgesi(renk: Color(r.vurguAcik), yazi: "\(tur.tekrar) tekrar")
            }
            if tur.pekistirme > 0 {
                lejantOgesi(renk: Color(r.murekkep2), yazi: "\(tur.pekistirme) pekiştirme")
            }
            if tur.yeni > 0 {
                lejantOgesi(renk: Color(r.dogruIkon), yazi: "\(tur.yeni) yeni")
            }
        }
    }

    private func lejantOgesi(renk: Color, yazi: String) -> some View {
        let r = tema.renkler
        return HStack(spacing: 5) {
            Circle().fill(renk).frame(width: 7, height: 7)
            Text(yazi)
                .font(Yazi.sans(11.5, agirlik: 500))
                .foregroundStyle(Color(r.murekkep2))
        }
    }

    // MARK: Günlük hedef seçici (`.hedef-sec.pk-hedef`)

    private func hedefSecici(il: Ilerleme) -> some View {
        let r = tema.renkler
        let secili = il.ayar("gunlukKart")?.tamSayi ?? 20
        let secenekler = CalisKurallari.gunlukHedefSecenekleri(mevcut: secili)
        return HStack(spacing: 12) {
            Etiket("Günlük hedef")
            Spacer(minLength: 0)
            HStack(spacing: 2) {
                ForEach(secenekler, id: \.self) { n in
                    let aktif = n == secili
                    Button {
                        Task { await model.gunlukHedefSec(n) }
                    } label: {
                        Text("\(n)")
                            .font(Yazi.sans(12, agirlik: 500, stil: .caption1))
                            .foregroundStyle(Color(aktif ? r.zemin : r.murekkep2))
                            .padding(.horizontal, 10)
                            .frame(minHeight: 28)
                            .background(Capsule().fill(aktif ? Color(r.murekkep) : Color.clear))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(aktif ? .isSelected : [])
                }
            }
            .padding(3)
            .overlay(Capsule().strokeBorder(Color(r.kenar), lineWidth: 1))
        }
    }

    // MARK: Döneme göre Salonlar (`.pk-salonlar`)

    private func salonlarBolumu(katalog: SiteKatalogu, il: Ilerleme, acikSanatcilar: [Sanatci]) -> some View {
        let r = tema.renkler
        let salonlar = CalisKurallari.donemSalonlari(
            katalog: katalog,
            ilerleme: il,
            bugun: model.bugun,
            siralama: siralama
        )
        let hepsiTur = CalisKurallari.turBilgisi(
            sanatcilar: katalog.sanatcilar,
            ilerleme: il,
            bugun: model.bugun,
            karisik: false,
            akim: "hepsi"
        )
        let mozaikSanatcilar = CalisKurallari.hepsiMozaikSanatcilari(acik: acikSanatcilar)

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DÖNEME GÖRE")
                    .font(Yazi.sans(11, agirlik: 600, stil: .caption2))
                    .tracking(2.2)
                    .foregroundStyle(Color(r.vurguAcik))
                Text("Salonlar")
                    .font(Yazi.serif(34))
                    .cssSatir(.serif, 34, 35.7)
                    .foregroundStyle(Color(r.murekkep))
                    .accessibilityAddTraits(.isHeader)
            }

            Text("Her dönem Kolay’dan başlar; o dönemde son cevaplarının %\(Int(Seviye.gecisOrani * 100))’i doğru olmadan Orta’ya, sonra Zor’a geçmez.")
                .font(Yazi.sans(13))
                .cssSatir(.sans, 13, 18.85)
                .foregroundStyle(Color(r.murekkep2))

            KucukHap(
                secenekler: DonemSiralamasi.allCases.map { ($0, $0.baslik) },
                secili: $siralama
            )

            VStack(spacing: 12) {
                hepsiSalonKarti(
                    acikSayisi: acikSanatcilar.count,
                    turYazisi: CalisKurallari.donemTurYazisi(hepsiTur),
                    mozaikSanatcilar: mozaikSanatcilar,
                    katalog: katalog,
                    il: il
                )
                ForEach(salonlar) { salon in
                    donemSalonKarti(salon, katalog: katalog, il: il)
                }
            }
            .padding(.top, 4)
        }
    }

    private func hepsiSalonKarti(
        acikSayisi: Int,
        turYazisi: String,
        mozaikSanatcilar: [Sanatci],
        katalog: SiteKatalogu,
        il: Ilerleme
    ) -> some View {
        let r = tema.renkler
        return Button {
            turBaslat(.sanatci(.donem(nil)), nil)
        } label: {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { g in
                    ZStack {
                        Color(r.yuzey)
                        HStack(spacing: 0) {
                            ForEach(Array(mozaikSanatcilar.enumerated()), id: \.offset) { _, s in
                                let eser = Temsil.enBilinen(katalog.eserler(s.id), kotuler: il.kotuGorseller)
                                UzakGorsel(url: eser.flatMap { model.gorsel($0, 320) }, icerik: .fill)
                                    .frame(width: g.size.width / CGFloat(max(1, mozaikSanatcilar.count)), height: g.size.height)
                                    .clipped()
                            }
                        }
                        LinearGradient(
                            stops: [
                                .init(color: Color(r.zemin).opacity(0), location: 0.2),
                                .init(color: Color(r.zemin).opacity(0.92), location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }

                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Etiket("Bütün salonlar")
                        Text("Hepsi, dönem sırasıyla")
                            .font(Yazi.serif(30))
                            .cssSatir(.serif, 30, 30)
                            .foregroundStyle(Color(r.murekkep))
                            .shadow(color: Color(r.zemin).opacity(0.7), radius: 9, y: 2)
                        Text("\(acikSayisi) sanatçı · \(turYazisi)")
                            .font(Yazi.sans(12.5, agirlik: 500))
                            .foregroundStyle(Color(r.murekkep2))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        Circle().fill(Color(r.zemin).opacity(0.55))
                        BenIkon(simge: .ileri, boyut: 18, kalinlik: 1.8)
                            .foregroundStyle(Color(r.murekkep))
                    }
                    .frame(width: 52, height: 52)
                }
                .padding(16)
            }
            .frame(minHeight: 140)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(r.kenar), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("donem-hepsi")
    }

    private func donemSalonKarti(_ salon: DonemSalonu, katalog: SiteKatalogu, il: Ilerleme) -> some View {
        let r = tema.renkler
        let renkDizge = katalog.akimRenk[salon.ad] ?? ""
        let akimRenk = Color(RGBA(css: renkDizge) ?? r.vurguAcik)
        let ustaMi = Seviye.usta(salon.seviyeKaydi)
        let eser = salon.temsilciId.flatMap { Temsil.enBilinen(katalog.eserler($0), kotuler: il.kotuGorseller) }
        return Button {
            turBaslat(.sanatci(.donem(salon.ad)), nil)
        } label: {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { g in
                    ZStack {
                        Color(r.yuzey)
                        if let eser {
                            UzakGorsel(url: model.gorsel(eser, 640), icerik: .fill)
                                .frame(width: g.size.width, height: g.size.height)
                                .clipped()
                        }
                        LinearGradient(
                            stops: [
                                .init(color: akimRenk.opacity(0.35), location: 0.0),
                                .init(color: Color.clear, location: 0.6),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        LinearGradient(
                            stops: [
                                .init(color: Color(r.zemin).opacity(0), location: 0.2),
                                .init(color: Color(r.zemin).opacity(0.92), location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }

                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            AkimNoktasi(renk: renkDizge)
                            Text(salon.seviyeRozeti)
                                .font(Yazi.sans(11, agirlik: 600))
                                .foregroundStyle(Color(ustaMi ? r.vurguAcik : r.murekkep2))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(Color(r.zemin).opacity(0.45))
                                )
                                .overlay(
                                    Capsule().strokeBorder(Color(ustaMi ? r.vurguAcik : r.kenar), lineWidth: 1)
                                )
                        }
                        Text(salon.ad)
                            .font(Yazi.serif(30))
                            .cssSatir(.serif, 30, 30)
                            .foregroundStyle(Color(r.murekkep))
                            .shadow(color: Color(r.zemin).opacity(0.7), radius: 9, y: 2)
                        Text("\(salon.acikSayisi) sanatçı · \(salon.turYazisi)")
                            .font(Yazi.sans(12.5, agirlik: 500))
                            .foregroundStyle(Color(r.murekkep2))
                        SeviyeIzi(kayit: salon.seviyeKaydi, genislik: 120)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // `.salon-halka`: doğruluk halkası
                    ZStack {
                        Circle().fill(Color(r.zemin).opacity(0.55))
                        Circle()
                            .stroke(.white.opacity(0.14), lineWidth: 3)
                            .padding(5)
                        if let oran = salon.oranYuzde {
                            Circle()
                                .trim(from: 0, to: CGFloat(oran) / 100.0)
                                .stroke(akimRenk, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .padding(5)
                            Text("\(oran)")
                                .font(Yazi.okuma(17))
                                .foregroundStyle(Color(r.murekkep))
                        } else {
                            Text("–")
                                .font(Yazi.okuma(17))
                                .foregroundStyle(Color(r.murekkep2))
                        }
                    }
                    .frame(width: 52, height: 52)
                }
                .padding(16)
            }
            .frame(minHeight: 168)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 3,
                    topTrailingRadius: 3
                )
                .fill(akimRenk)
                .frame(width: 3)
                .padding(.vertical, 16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color(r.kenar), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("donem-satir-\(salon.ad)")
    }
}

// MARK: Deste Hareket Yöneticisi (`js/deste.js`)

@MainActor
@Observable
final class DesteHareketYoneticisi {
    private(set) var acilim: Double = 0
    private(set) var yatma: Double = 0

    private let motion = CMMotionManager()
    private var durum = SarkacDurumu()
    private var taban: (beta: Double, gamma: Double)?

    func baslat() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] veri, _ in
            guard let self, let veri else { return }
            let beta = veri.attitude.pitch * 180.0 / .pi
            let gamma = veri.attitude.roll * 180.0 / .pi
            let yeniTaban = DesteFizigi.tabanIzle(taban: self.taban, beta: beta, gamma: gamma)
            self.taban = yeniTaban
            let egim = DesteFizigi.egimHesapla(
                beta: beta,
                gamma: gamma,
                tabanBeta: yeniTaban.beta,
                tabanGamma: yeniTaban.gamma
            )
            self.durum = DesteFizigi.sarkacAdim(self.durum, hedef: egim.x, dt: 1.0 / 60.0)
            let yelpaze = DesteFizigi.yelpazeHedefi(self.durum.aci)
            self.acilim = yelpaze.acilim
            self.yatma = yelpaze.yatma
        }
    }

    func durdur() {
        if motion.isDeviceMotionActive {
            motion.stopDeviceMotionUpdates()
        }
        taban = nil
        durum = SarkacDurumu()
        acilim = 0
        yatma = 0
    }
}
