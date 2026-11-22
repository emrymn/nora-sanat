// Kaynak: sanat-atlasi js/ekranlar/ders.js (ayirtAdimi, ayirtCiz, ayirtSec, ilkEser, olaylariBagla: data-ayirt-*),
// css/app.css (.ders-ayirt, .ders-soru, .ders-soru-alt, .ders-ikili, .ders-ikili-eser, .ders-ikili-resim, .ders-ikili-ad,
// .ders-fark, .ders-fark-sutunlar, .ders-fark-cumle, .ders-fark-bag) @ a866b86
// Ayırt et: her komşu dönemle bir ikili. İki akımın birinci eserleri yan yana ("Hangisi …?"); hangisinin solda duracağı
// rastgele. Cevaptan sonra iki akımın "Nasıl tanınır?" maddeleri iki sütunda ve dönem metinlerindeki karşılaştırma
// cümleleri. Cevaptan sonra esere dokununca tam ekran (iki eser yan yana gezilir).
import NoraCekirdek
import SwiftUI

@MainActor
struct DersAyirtAdimi: View {
    let model: PekistirmeModeli
    let b: DersBilgisi
    let geri: () -> Void
    let bitir: () -> Void
    let adreseGit: (String) -> Void

    struct Yan: Equatable {
        let eser: Eser
        let sid: String
    }

    struct Ikili: Equatable {
        let konum: Int
        /// solda ve sağda duran eserler (bulunamayan nil)
        let yanlar: [Yan?]
        /// dersin kendi eseri hangi yanda
        let dogru: Int
        var cevap: Int?
    }

    @Environment(TemaDeposu.self) private var tema
    @State private var konum = 0
    @State private var gorulen = 0
    @State private var ikili: Ikili?
    @State private var basladi = false
    @State private var gosterim: DersGosterimi?

    private var hareketAz: Bool { tema.ayar.hareketAzaltilmis }

    var body: some View {
        let r = tema.renkler
        let toplam = b.ayirt.count
        let c = b.ayirt[min(konum, toplam - 1)]
        let ik = ikili?.konum == konum ? ikili : nil
        let cevapli = ik?.cevap != nil

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                DersAdimUst(
                    etiket: DersAdimKurallari.ustEtiketi(akim: b.akim, adim: .ayirt, adimlar: b.adimlar),
                    baslik: DersAdimKurallari.ayirtBasligi(konum: konum, toplam: toplam),
                    durum: b.durum,
                    adim: .ayirt,
                    geri: geri
                )
                .padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 0) {
                    Text(DersAdimKurallari.ayirtSorusu(b.akim))
                        .font(Yazi.serif(26))
                        .cssSatir(.serif, 26, 29.9)
                        .foregroundStyle(Color(r.murekkep))
                        .accessibilityAddTraits(.isHeader)
                    Text(DersAdimKurallari.ayirtAltYazisi(c))
                        .font(Yazi.sans(14))
                        .cssSatir(.sans, 14, 18.9)
                        .foregroundStyle(Color(r.murekkep2))
                        .padding(.top, 4)

                    // `.ders-ikili`
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(0..<2, id: \.self) { i in
                            yan(i, ik: ik, c: c)
                        }
                    }
                    .padding(.top, 14)
                    .accessibilityIdentifier("ders-ikili")

                    if let ik, let cevap = ik.cevap {
                        fark(c, dogru: cevap == ik.dogru)
                            .padding(.top, 16)
                            .transition(hareketAz ? .identity : .opacity.combined(with: .offset(y: 8)))
                    }
                }
                .id(konum)
                .transition(hareketAz ? .identity : .opacity.combined(with: .offset(y: 10)))
                .padding(.bottom, 92)
            }
            .padding(.horizontal, BenOlcu.yan)
            .padding(.top, 12)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) {
            if cevapli {
                DersAltCubuk {
                    if konum > 0 {
                        Button("Geri") { git(konum - 1) }
                            .buttonStyle(DersDugme(tur: .bos))
                            .accessibilityIdentifier("ayirt-geri")
                    }
                    Button { ileri() } label: {
                        Text(DersAdimKurallari.ayirtIleri(konum: konum, toplam: toplam)).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DersDugme(tur: .dolu))
                    .accessibilityIdentifier("ayirt-ileri")
                }
                .transition(.opacity)
            }
        }
        .accessibilityIdentifier("ders-ayirt")
        .fullScreenCover(item: $gosterim) { g in
            Goruntuleyici(eserler: g.eserler, baslangic: g.baslangic).environment(tema)
        }
        .onAppear {
            guard !basladi else { return }
            basladi = true
            konum = CalisDersKurallari.kalinanYer(i: b.kayit.ayirt.i, toplam: toplam)
            gorulen = DersAdimKurallari.gorulen(i: b.kayit.ayirt.i, toplam: toplam)
            ikiliKur()
        }
        .onChange(of: konum) { _, _ in ikiliKur() }
        #if DEBUG
        // CI: ikili kurulunca (-dersCevapla ile soldaki esere dokunup) hazır işareti yazılır
        .task(id: ik?.konum) {
            guard ik != nil else { return }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            DersKarsilastirma.hazirYaz()
        }
        #endif
    }

    // MARK: Eser kartı (`.ders-ikili-eser`)

    @ViewBuilder
    private func yan(_ i: Int, ik: Ikili?, c: AyirtIkilisi) -> some View {
        let r = tema.renkler
        let x = ik?.yanlar[i] ?? nil
        let cevapli = ik?.cevap != nil
        let kendiMi = i == ik?.dogru
        let akim = kendiMi ? b.akim : c.komsu
        let kenar: Color = !cevapli ? Color(r.kenar) : kendiMi ? Color(r.dogru) : ik?.cevap == i ? Color(r.yanlis) : Color(r.kenar)
        let kalin = cevapli && (kendiMi || ik?.cevap == i)
        let ad = x.map { [kisaAd($0.sid), $0.eser.gorunenAd, $0.eser.tarih].filter { !$0.isEmpty }.joined(separator: " · ") } ?? ""

        Button { sec(i) } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Color(r.murekkep).karis(Color(r.zemin), 0.93)
                    if let x { UzakGorsel(url: model.gorsel(x.eser, 500), icerik: .fill) }
                }
                .frame(height: 210)
                .clipped()

                // `.ders-ikili-ad`
                VStack(alignment: .leading, spacing: 2) {
                    if cevapli {
                        HStack(spacing: 6) {
                            if kendiMi {
                                BenIkon(simge: .dogru, boyut: 14, kalinlik: 2.4).foregroundStyle(Color(r.dogruIkon))
                            }
                            Text(akim)
                                .font(Yazi.sans(13, agirlik: 600, stil: .footnote))
                                .cssSatir(.sans, 13, 16.9)
                                .foregroundStyle(kendiMi ? Color(r.dogruIkon) : Color(r.murekkep))
                        }
                        Text(ad)
                            .font(Yazi.sans(12, stil: .caption1))
                            .cssSatir(.sans, 12, 15.6)
                            .foregroundStyle(Color(r.murekkep2))
                    } else {
                        Text(i == 0 ? "Soldaki" : "Sağdaki")
                            .font(Yazi.sans(13, stil: .footnote))
                            .cssSatir(.sans, 13, 16.9)
                            .foregroundStyle(Color(r.murekkep3))
                    }
                }
                .padding(.top, 8).padding(.horizontal, 10).padding(.bottom, 10)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .topLeading)
            }
            .background(Color(r.yuzey))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(kenar, lineWidth: kalin ? 2 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel(cevapli ? "\(akim): \(ad) · büyüt" : (i == 0 ? "Soldaki eser" : "Sağdaki eser"))
        .accessibilityIdentifier("ayirt-sec-\(i)")
    }

    // MARK: Fark (`.ders-fark`)

    private func fark(_ c: AyirtIkilisi, dogru: Bool) -> some View {
        let r = tema.renkler
        return VStack(alignment: .leading, spacing: 12) {
            Text(DersAdimKurallari.ayirtSonucu(dogru: dogru))
                .font(Yazi.sans(13, agirlik: 600, stil: .caption1))
                .cssSatir(.sans, 13, 16.9)
                .foregroundStyle(Color(dogru ? r.dogruIkon : r.yanlisIkon))
                .accessibilityIdentifier("ayirt-sonuc")

            HStack(alignment: .top, spacing: 14) {
                sutun(b.akim, c.kendiMaddeler, ikincil: false)
                sutun(c.komsu, c.komsuMaddeler, ikincil: true)
            }

            ForEach(Array(c.cumleler.enumerated()), id: \.offset) { _, x in
                VStack(alignment: .leading, spacing: 4) {
                    Text(x.cumle)
                        .font(Yazi.okuma(17))
                        .cssSatir(.okuma, 17, 25.5)
                        .foregroundStyle(Color(r.murekkep).karis(Color(r.zemin), 0.12))
                    Text(DersAdimKurallari.cumleKaynagi(x.kaynak))
                        .font(Yazi.sans(12, stil: .caption1))
                        .cssSatir(.sans, 12, 15.6)
                        .foregroundStyle(Color(r.murekkep3))
                }
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Rectangle().fill(Color(r.kenar)).frame(height: 1) }
            }

            Button {
                adreseGit(CalisKurallari.akimKarsilastirmaAdresi(b.akim, c.komsu))
            } label: {
                HStack(spacing: 8) {
                    BenIkon(simge: .karsilastir, boyut: 16, kalinlik: 1.6)
                    Text("İki dönemi ayrıntılı karşılaştır")
                        .font(Yazi.sans(14))
                        .underline()
                }
                .foregroundStyle(Color(r.murekkep2))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(r.yuzey)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color(r.kenar), lineWidth: 1))
        .accessibilityIdentifier("ders-fark")
    }

    private func sutun(_ ad: String, _ maddeler: [String], ikincil: Bool) -> some View {
        let r = tema.renkler
        let d = DersRenkleri(r)
        return VStack(alignment: .leading, spacing: 6) {
            Text(ad)
                .font(Yazi.sans(13, agirlik: 600, stil: .caption1))
                .cssSatir(.sans, 13, 16.9)
                .foregroundStyle(Color(ikincil ? r.murekkep2 : r.murekkep))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(maddeler.enumerated()), id: \.offset) { _, m in
                    Text(m)
                        .font(Yazi.sans(14))
                        .cssSatir(.sans, 14, 18.9)
                        .foregroundStyle(Color(ikincil ? r.murekkep2 : r.murekkep))
                        .padding(.leading, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .leading) { Rectangle().fill(d.kenar).frame(width: 1) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Eylemler

    private func kisaAd(_ sid: String) -> String {
        model.katalog.map { DersAdimKurallari.kisaAd(sid, katalog: $0) } ?? ""
    }

    /// `ilkEser(liste)`: listedeki ilk bulunabilen eser
    private func ilkEser(_ l: [DersEserRef]) -> Yan? {
        guard let katalog = model.katalog else { return nil }
        for ref in l where katalog.harita[ref.sanatci] != nil {
            if let e = CalisDersKurallari.eserEslestir(katalog.eserler(ref.sanatci), sid: ref.sanatci, ref: ref) {
                return Yan(eser: e, sid: ref.sanatci)
            }
        }
        return nil
    }

    private func ikiliKur() {
        guard ikili?.konum != konum, b.ayirt.indices.contains(konum) else { return }
        let c = b.ayirt[konum]
        let kendi = ilkEser(c.kendi)
        let karsi = ilkEser(c.karsi)
        let kendiSolda = Bool.random()
        var yeni = Ikili(konum: konum, yanlar: kendiSolda ? [kendi, karsi] : [karsi, kendi], dogru: kendiSolda ? 0 : 1, cevap: nil)
        #if DEBUG
        // CI: `-dersCevapla` ikiliyi soldaki eser seçilmiş kurar (fark bölümü görünsün; ilerleme yazılmaz)
        if NoraSanatApp.arguman("-dersCevapla") != nil { yeni.cevap = 0 }
        #endif
        ikili = yeni
    }

    /// `ayirtSec(i)`: ilk dokunuş cevaptır (ilerleme yazılır); sonrakiler tam ekranı açar
    private func sec(_ i: Int) {
        guard var ik = ikili, ik.konum == konum else { return }
        if ik.cevap != nil {
            let eserler = ik.yanlar.compactMap { $0?.eser }
            if let hedef = ik.yanlar[i]?.eser {
                gosterim = DersGosterimi(eserler: eserler, baslangic: eserler.firstIndex(of: hedef) ?? 0)
            }
            return
        }
        ik.cevap = i
        if hareketAz { ikili = ik } else { withAnimation(.easeOut(duration: 0.3)) { ikili = ik } }
        if let yeni = DersAdimKurallari.ilerle(konum: konum, gorulen: gorulen) {
            gorulen = yeni
            Task { await model.dersAdimiIsle(akim: b.akim, adim: .ayirt, gorulen: yeni, toplam: b.ayirt.count) }
        }
    }

    private func git(_ yeni: Int) {
        guard b.ayirt.indices.contains(yeni) else { return }
        if hareketAz { konum = yeni } else { withAnimation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.4)) { konum = yeni } }
    }

    private func ileri() {
        if konum >= b.ayirt.count - 1 { bitir(); return }
        git(konum + 1)
    }
}
