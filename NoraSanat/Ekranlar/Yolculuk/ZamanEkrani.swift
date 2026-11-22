// Kaynak: sanat-atlasi js/ekranlar/zaman.js, css/app.css (.zm-*) @ a866b86
import SwiftUI
import NoraCekirdek

struct ZamanEkrani: View {
    let katalog: SiteKatalogu
    let ilerleme: Ilerleme
    @State private var yil: Int
    @State private var suruklemeBasi: Int?
    private let cubuklar: [ZamanKadrani.Cubuk]
    @Environment(TemaDeposu.self) private var tema

    init(katalog: SiteKatalogu, ilerleme: Ilerleme) {
        self.katalog = katalog
        self.ilerleme = ilerleme
        _yil = State(initialValue: ZamanKadrani.baslangic(katalog.sanatcilar, islenen: ilerleme.islenenKume))
        cubuklar = ZamanKadrani.yogunluk(katalog.sanatcilar, islenen: ilerleme.islenenKume)
    }

    var body: some View {
        let liste = ZamanKadrani.yasayanlar(katalog.sanatcilar, yil: yil)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                GaleriUst(etkin: .zaman, koleksiyonDolu: !(ilerleme[alan:"koleksiyon"]?.dizi?.isEmpty ?? true),
                          ara: { Gezgin.shared.git("#/ara") }, koleksiyon: { Gezgin.shared.git("#/koleksiyon") }) { b in
                    let yollar = ["#/gozat","#/basyapitlar","#/konular","#/zaman"]
                    if b != .zaman { Gezgin.shared.git(yollar[b.rawValue]) }
                }.padding(.horizontal,24)
                Section {
                    Text("Cetveli kaydır ya da dokun: o yıl hayatta olanlar aşağıda.")
                        .font(Yazi.okuma(15, italik: true)).padding(.vertical,14).padding(.horizontal,24)
                    if liste.isEmpty { Text("Bu yıl için kayıtlı sanatçı yok. Cetveli biraz kaydır.").padding() }
                    ForEach(katalog.akimlar) { a in
                        let uyeler = liste.filter { $0.sanatci.akim == a.ad }
                        if !uyeler.isEmpty {
                            HStack {
                                Circle().fill(Color(GaleriRenk.akim(katalog,a.ad))).frame(width:8,height:8)
                                Text(a.ad).font(Yazi.serif(21))
                                Text("\(uyeler.count)").font(Yazi.sans(12))
                            }.padding(.top,18).padding(.horizontal,24)
                            ForEach(uyeler) { x in satir(x) }
                        }
                    }
                } header: { panel(liste.count) }
            }
        }.background(Color(tema.renkler.zemin)).foregroundStyle(Color(tema.renkler.murekkep))
    }

    private func panel(_ sayi: Int) -> some View {
        VStack(spacing: 10) {
            HStack {
                adim(-10)
                Spacer()
                VStack(spacing: 3) {
                    Etiket(ZamanKadrani.evre(yil))
                    Text(String(yil)).font(Yazi.serif(52)).cssSatir(.serif,52,49.4)
                    Text("\(sayi) sanatçı hayatta").font(Yazi.sans(13))
                }
                Spacer()
                adim(10)
            }.frame(height:91).padding(.horizontal, 24)
            cetvel
        }.padding(.top,8).background(Color(tema.renkler.zemin)).overlay(alignment:.bottom) { Divider() }
    }


    private var cetvel: some View {
        GeometryReader { g in
            Canvas { baglam, boyut in
                let orta = boyut.width / 2
                let enCok = Double(max(1, cubuklar.map(\.sayi).max() ?? 1))
                for c in cubuklar where c.sayi > 0 {
                    let x = orta + CGFloat(c.id - yil) * 4
                    guard x > -40 && x < boyut.width else { continue }
                    let h = CGFloat(3 + (27 * Double(c.sayi) / enCok).rounded())
                    let renk = Color(GaleriRenk.akim(katalog, c.akim ?? "")).opacity(c.acik ? 1 : 0.28)
                    baglam.fill(Path(CGRect(x: x+1, y: 30-h, width: 38, height: h)), with: .color(renk))
                }
                for y in stride(from: 1250, through: 2000, by: 10) {
                    let x = orta + CGFloat(y - yil) * 4
                    guard x > -20 && x < boyut.width+20 else { continue }
                    let h: CGFloat = y.isMultiple(of: 50) ? 11 : 5
                    baglam.fill(Path(CGRect(x: x, y: 31, width: 1, height: h)), with: .color(.secondary))
                    if y.isMultiple(of: 100) { baglam.draw(Text(String(y)).font(Yazi.sans(10)), at: CGPoint(x:x,y:51)) }
                }
                baglam.fill(Path(CGRect(x: orta-1, y: 0, width: 2, height: boyut.height)), with: .color(Color(tema.renkler.vurguAcik)))
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                let bas = suruklemeBasi ?? yil
                suruklemeBasi = bas
                yil = ZamanKadrani.sinirla(Double(bas) - Double(v.translation.width)/4)
            }.onEnded { v in
                if abs(v.translation.width) < 3 {
                    yil = ZamanKadrani.sinirla(Double(yil) + Double(v.location.x - g.size.width/2)/4)
                }
                suruklemeBasi = nil
            })
        }
        .frame(height:64).accessibilityElement(children:.ignore)
        .accessibilityLabel("Yıl").accessibilityValue(String(yil))
        .accessibilityAdjustableAction { yon in yil = ZamanKadrani.sinirla(Double(yil + (yon == .increment ? 1 : -1))) }
    }

    private func adim(_ fark: Int) -> some View {
        Button { yil = ZamanKadrani.sinirla(Double(yil+fark)) } label: {
            GaleriIkon(simge:fark<0 ? .geri : .ileri,boyut:22)
        }.buttonStyle(YuvarlakDugme()).accessibilityLabel(fark<0 ? "10 yıl geri" : "10 yıl ileri")
    }

    private func satir(_ x: ZamanKadrani.Yasam) -> some View {
        let s = x.sanatci
        let acik = ilerleme.islenenKume.contains(s.konu ?? -1)
        return Button { Gezgin.shared.git("#/sanatci/" + s.id) } label: {
            HStack(spacing:14) {
                RoundedRectangle(cornerRadius:4).fill(Color(tema.renkler.yuzey)).overlay {
                    if acik { UzakGorsel(url:katalog.kucukGorselAdresi(s.id,genislik:200,kotuler:ilerleme.kotuGorseller)) }
                }.frame(width:48,height:48).clipShape(RoundedRectangle(cornerRadius:4))
                VStack(alignment:.leading,spacing:4) {
                    Text(katalog.bilinenAd(s.id) ?? s.ad).font(Yazi.serif(20))
                    Text(x.yas(yil) + " · " + (acik ? SiteYazisi.yillarYaz(dogum:s.dogum,olum:s.olum) : "Konu \(s.konu ?? 0)’da açılır")).font(Yazi.sans(12))
                    OranCubugu(oran:x.pay(yil),yukseklik:2)
                }
                Spacer()
                if acik { GaleriIkon(simge:.ileri,boyut:18) }
            }.frame(minHeight:72).overlay(alignment:.bottom){ Divider() }
        }.buttonStyle(.plain).disabled(!acik).opacity(acik ? 1 : 0.5).padding(.horizontal,24)
    }
}
