// Kaynak: sanat-atlasi js/ekranlar/calisma.js (takvimHtml, oranGrafigi, yukGrafigi, koleksiyonBagi),
// css/app.css (.calisma-takvim, .tk, .seri, .grafik, .grafik-svg, .satir) @ a866b86
import NoraCekirdek
import SwiftUI

/// "Son 12 hafta": 7 satır × 12 sütun kareler; dolu kare o günün en çok çalışılan akımının renginde
struct CalismaTakvimi: View {
    let il: Ilerleme
    let katalog: SiteKatalogu
    let bugun: String
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        let r = tema.renkler
        let gunler = Gecmis.takvim(il.gecmis, bugun: bugun, hafta: 12)
        let seri = Gecmis.seri(il.gecmis, bugun: bugun)
        let calisilan = gunler.filter { $0.kart > 0 }.count
        VStack(alignment: .leading, spacing: 0) {
            Ayrac()
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Etiket("Son 12 hafta")
                Spacer(minLength: 0)
                if seri > 0 {
                    (Text("\(seri)").font(Yazi.serif(30)).foregroundColor(Color(r.murekkep))
                        + Text(" günlük seri").font(Yazi.okuma(16, italik: true)))
                        .foregroundStyle(Color(r.murekkep2))
                } else {
                    Text("Seri yok · bugün bir tur çalış").font(Yazi.okuma(16, italik: true))
                        .foregroundStyle(Color(r.murekkep2))
                }
            }
            .padding(.top, 14)
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(["Pzt", "", "Çar", "", "Cum", "", "Paz"].indices, id: \.self) { i in
                        Text(["Pzt", "", "Çar", "", "Cum", "", "Paz"][i])
                            .font(Yazi.sans(10, agirlik: 500, stil: .caption2))
                            .foregroundStyle(Color(r.murekkep3))
                            .frame(maxHeight: .infinity)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityHidden(true)
                HStack(spacing: 4) {
                    ForEach(0..<(gunler.count / 7), id: \.self) { s in
                        VStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { g in kare(gunler[s * 7 + g]) }
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Son 12 haftada \(calisilan) gün çalıştın")
            }
            .padding(.top, 10)
            Text("Kare, o gün en çok çalıştığın akımın renginde.")
                .font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(r.murekkep2))
                .padding(.top, 8).padding(.bottom, 10)
            Ayrac()
        }
        .padding(.top, 4).padding(.bottom, 18)
    }

    @ViewBuilder
    private func kare(_ x: TakvimGunu) -> some View {
        let r = tema.renkler
        let sekil = Rectangle()
        Group {
            if x.gelecek {
                sekil.strokeBorder(Color(r.kenar), style: StrokeStyle(lineWidth: 1, dash: [2, 2])).opacity(0.35)
            } else if x.kart > 0 {
                sekil.fill(Color(RGBA(css: katalog.akimRenk[x.akim ?? ""] ?? "") ?? RGBA(css: "#8A827A")!))
                    .opacity(min(1, 0.55 + Double(x.kart) / 25))
            } else {
                sekil.strokeBorder(Color(r.kenar), lineWidth: 1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay {
            if x.tarih == bugun { sekil.stroke(Color(r.murekkep), lineWidth: 1.5).padding(-2) }
        }
    }
}

/// İ4a "Haftalık doğru oranı" ve İ4b "Önümüzdeki 14 gün": sitenin SVG'leri (340 genişlik) aynı ölçüyle çizilir
struct CalismaEgrileri: View {
    let il: Ilerleme
    let acikIdler: [String]
    let bugun: String
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            oran
            yuk
        }
        .padding(.bottom, 20)
    }

    private func baslik(_ ad: String, _ ozet: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Etiket(ad)
            Spacer(minLength: 0)
            Text(ozet).font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(tema.renkler.murekkep2))
                .multilineTextAlignment(.trailing)
        }
        .padding(.bottom, 6)
    }

    // MARK: Oran

    @ViewBuilder
    private var oran: some View {
        let haftalar = Gecmis.haftalikOran(il.gecmis, bugun: bugun, hafta: 12)
        let veri = haftalar.contains { $0.oran != nil }
        let yazi = veri ? "Son hafta: " + (haftalar.last?.oran.map { "%\(Int(($0 * 100).rounded()))" } ?? "kart yok") : "Henüz veri yok"
        VStack(alignment: .leading, spacing: 0) {
            baslik("Haftalık doğru oranı", veri ? yazi : "İlk turdan sonra burada")
            if veri {
                Canvas { c, boyut in cizOran(c, boyut, haftalar) }
                    .aspectRatio(340 / 114, contentMode: .fit)
                    .accessibilityLabel("Son 12 haftanın doğru oranı çizgisi. \(yazi)")
            }
        }
    }

    private func cizOran(_ c: GraphicsContext, _ boyut: CGSize, _ haftalar: [HaftaOrani]) {
        let r = tema.renkler
        let k = boyut.width / 340
        let G: CGFloat = 340, Y: CGFloat = 96, sol: CGFloat = 30
        let x = { (i: Int) in (sol + CGFloat(i) * (G - sol - 8) / CGFloat(max(1, haftalar.count - 1))) * k }
        let y = { (o: Double) in (6 + (1 - CGFloat(o)) * (Y - 6)) * k }
        for o in [0.0, 0.5, 1.0] {
            var p = Path()
            p.move(to: CGPoint(x: sol * k, y: y(o)))
            p.addLine(to: CGPoint(x: (G - 4) * k, y: y(o)))
            c.stroke(p, with: .color(Color(r.kenar)), lineWidth: 1)
            c.draw(eksenYazisi("\(Int(o * 100))"), at: CGPoint(x: (sol - 6) * k, y: y(o)), anchor: .trailing)
        }
        var yol = Path()
        var acik = false
        for (i, h) in haftalar.enumerated() {
            guard let o = h.oran else { acik = false; continue }
            let n = CGPoint(x: x(i), y: y(o))
            if acik { yol.addLine(to: n) } else { yol.move(to: n) }
            acik = true
        }
        c.stroke(yol, with: .color(Color(r.murekkep)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        let son = haftalar.indices.last { haftalar[$0].oran != nil }
        for (i, h) in haftalar.enumerated() {
            guard let o = h.oran else { continue }
            let rr: CGFloat = (i == son ? 3.6 : 2.4) * k
            let daire = Path(ellipseIn: CGRect(x: x(i) - rr, y: y(o) - rr, width: rr * 2, height: rr * 2))
            if i == son {
                c.fill(daire, with: .color(Color(r.vurguAcik)))
                c.stroke(daire, with: .color(Color(r.murekkep)), lineWidth: 1.5)
            } else {
                c.fill(daire, with: .color(Color(r.murekkep)))
            }
        }
        c.draw(eksenYazisi("12 hafta önce"), at: CGPoint(x: sol * k, y: (Y + 14) * k), anchor: .bottomLeading)
        c.draw(eksenYazisi("bu hafta"), at: CGPoint(x: (G - 4) * k, y: (Y + 14) * k), anchor: .bottomTrailing)
    }

    private func eksenYazisi(_ s: String, boyut: CGFloat = 9.5, renk: RGBA? = nil) -> Text {
        Text(s).font(Yazi.sans(boyut, agirlik: 500, stil: .caption2)).foregroundColor(Color(renk ?? tema.renkler.murekkep3))
    }

    // MARK: Yük

    @ViewBuilder
    private var yuk: some View {
        let gunluk = Gecmis.gelecekYuk(il.skorlar, idler: acikIdler, bugun: bugun, gun: 14)
        let toplam = gunluk.reduce(0, +)
        let yazi = "Bugün \(gunluk.first ?? 0) · yarın \(gunluk.count > 1 ? gunluk[1] : 0) · 14 günde \(toplam) sanatçı"
        VStack(alignment: .leading, spacing: 0) {
            baslik("Önümüzdeki 14 gün", toplam > 0 ? yazi : "Tekrarı gelen sanatçı yok")
            if toplam > 0 {
                Canvas { c, boyut in cizYuk(c, boyut, gunluk) }
                    .aspectRatio(340 / 114, contentMode: .fit)
                    .accessibilityLabel("Önümüzdeki 14 günün vadeli kart sayısı. \(yazi)")
            }
        }
    }

    private static let gunHarfi = ["P", "P", "S", "Ç", "P", "C", "C"]

    private func cizYuk(_ c: GraphicsContext, _ boyut: CGSize, _ gunluk: [Int]) {
        let r = tema.renkler
        let k = boyut.width / 340
        let G: CGFloat = 340, Y: CGFloat = 84
        let adim = (G - 8) / 14
        let en = CGFloat(max(1, gunluk.max() ?? 1))
        var eksen = Path()
        eksen.move(to: CGPoint(x: 4 * k, y: Y * k))
        eksen.addLine(to: CGPoint(x: (G - 4) * k, y: Y * k))
        c.stroke(eksen, with: .color(Color(r.kenar)), lineWidth: 1)
        var takvim = Calendar(identifier: .gregorian)
        takvim.timeZone = TimeZone(identifier: "UTC")!
        for (i, n) in gunluk.enumerated() {
            let t = GunTarihi.ekle(bugun, i)
            let h: CGFloat = n > 0 ? max(3, CGFloat(n) / en * (Y - 16)) : 0
            let cx = 4 + CGFloat(i) * adim + adim / 2
            if h > 0 {
                let kutu = CGRect(x: (cx - adim * 0.3) * k, y: (Y - h) * k, width: adim * 0.6 * k, height: h * k)
                c.fill(Path(kutu), with: .color(Color(i == 0 ? r.vurguAcik : r.murekkep2)))
                c.draw(eksenYazisi("\(n)"), at: CGPoint(x: cx * k, y: (Y - h - 4) * k), anchor: .bottom)
            }
            if let p = GunTarihi.ayir(t),
               let tarih = takvim.date(from: DateComponents(year: p.yil, month: p.ay, day: p.gun)) {
                let hg = takvim.component(.weekday, from: tarih) - 1
                c.draw(eksenYazisi(Self.gunHarfi[hg]), at: CGPoint(x: cx * k, y: (Y + 13) * k), anchor: .bottom)
                c.draw(eksenYazisi("\(p.gun)", boyut: 8.5, renk: r.soluk), at: CGPoint(x: cx * k, y: (Y + 25) * k), anchor: .bottom)
            }
        }
    }
}

/// `.satir.koleksiyon-bag`: serif 20 başlık, 13 px açıklama, sağda simge; altında çizgi
struct BenSatiri: View {
    let baslik: String
    let aciklama: String
    let simge: BenSimge
    var baslikBoyu: CGFloat = 20
    let eylem: () -> Void
    @Environment(TemaDeposu.self) private var tema

    var body: some View {
        Button(action: eylem) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(baslik).font(Yazi.serif(baslikBoyu)).foregroundStyle(Color(tema.renkler.murekkep))
                    Text(aciklama).font(Yazi.sans(13, stil: .footnote)).foregroundStyle(Color(tema.renkler.murekkep2))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                BenIkon(simge: simge, boyut: 20, kalinlik: 1.4).foregroundStyle(Color(tema.renkler.murekkep3))
            }
            .padding(.vertical, 10)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
