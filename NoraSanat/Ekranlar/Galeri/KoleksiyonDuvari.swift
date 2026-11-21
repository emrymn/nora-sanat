// Kaynak: sanat-atlasi js/ekranlar/koleksiyon.js, js/sallanma.js @ a866b86
import CoreMotion
import NoraCekirdek
import SwiftUI

struct KoleksiyonDuvari: View {
    let eserler: [Eser]
    let galeri: GaleriKatalogu
    let ilerleme: Ilerleme
    let ac: (Int) -> Void

    @Environment(TemaDeposu.self) private var tema
    @Environment(\.accessibilityReduceMotion) private var hareketAz
    @State private var hareket = CMMotionManager()
    @State private var tablolar: [AsiliTablo] = []
    @State private var donus = 0.0
    @State private var hareketAcik = false
    @State private var sonZaman: TimeInterval?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hareket.isGyroAvailable && !hareketAz && !tema.ayar.hareketAzaltilmis && ilerleme.ayar("egim")?.mantik != false {
                Button(hareketAcik ? "Hareketi kapat" : "Hareketi aç") { hareketAcik.toggle() }
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .center, spacing: 20) {
                ForEach(eserler.indices, id: \.self) { i in
                    let e = eserler[i]
                    let aski = tablolar.indices.contains(i) ? tablolar[i] : AsiliTablo(sira: i)
                    let tip = GaleriSergisi.cerceve(galeri.katalog.harita[e.sid]?.akim)
                    Button { ac(i) } label: {
                        VStack(spacing: 4) {
                            VStack(spacing: 0) {
                                Circle().frame(width: 5, height: 5)
                                Path { p in
                                    p.move(to: CGPoint(x: 10, y: aski.ip))
                                    p.addLine(to: CGPoint(x: 55, y: 0))
                                    p.addLine(to: CGPoint(x: 100, y: aski.ip))
                                }.stroke(.secondary, lineWidth: 1).frame(width: 110, height: aski.ip)
                                let k = galeri.katalog
                                let secilen = GorselAdresleri.secilen(e, kotuler: ilerleme.kotuGorseller)
                                UzakGorsel(url: k.gorselAdresi(e, genislik: 400, kotuler: ilerleme.kotuGorseller), icerik: .fit,
                                           yedek: secilen.flatMap { GorselAdresleri.url(k.gorsel.yedek($0)) })
                                    .aspectRatio(secilen.flatMap(k.gorsel.oran) ?? 1, contentMode: .fit)
                                    .border(cerceveRengi(tip), width: ["cita", "cita-kagit"].contains(tip) ? 2 : 6)
                            }.rotationEffect(.degrees(aski.aci + aski.egim), anchor: .top)
                            Text(e.gorunenAd).font(Yazi.serif(16))
                            Text(e.tarih).font(.caption)
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
        .task(id: hareketAcik && !hareketAz && !tema.ayar.hareketAzaltilmis && ilerleme.ayar("egim")?.mantik != false) {
            guard hareketAcik, !hareketAz, !tema.ayar.hareketAzaltilmis, ilerleme.ayar("egim")?.mantik != false else { durdur(); return }
            hareket.gyroUpdateInterval = 1 / 30
            hareket.startGyroUpdates(to: .main) { veri, _ in
                guard let veri, hareket.isGyroActive else { return }
                let sure = min(0.04, max(0, veri.timestamp - (sonZaman ?? veri.timestamp - 1 / 30)))
                sonZaman = veri.timestamp
                donus = AsiliTablo.donus(donus, dereceHizi: veri.rotationRate.y * 180 / .pi, dt: sure)
                if tablolar.count != eserler.count { tablolar = eserler.indices.map { AsiliTablo(sira: $0) } }
                for i in tablolar.indices { tablolar[i].adim(donus: donus, dt: sure) }
            }
        }
        .onDisappear { hareketAcik = false; durdur() }
    }

    private func durdur() {
        hareket.stopGyroUpdates()
        sonZaman = nil
        donus = 0
        tablolar = []
    }

    private func cerceveRengi(_ tip: String) -> Color {
        switch tip {
        case "beyaz", "tas": return .white
        case "cita", "abanoz": return .black
        case "cita-kagit", "tabernakel": return .brown
        default: return Color(tema.renkler.pirinc)
        }
    }
}
