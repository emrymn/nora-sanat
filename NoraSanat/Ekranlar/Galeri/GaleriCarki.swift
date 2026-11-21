// Kaynak: sanat-atlasi js/ekranlar/gozat.js carkHtml, carkKur @ a866b86
import NoraCekirdek
import SwiftUI

struct GaleriCarki: View {
    let salonlar: [AkimDurumu]
    @Binding var sira: Int
    @Environment(TemaDeposu.self) private var tema
    @State private var suruklemeBasi: Int?

    var body: some View {
        GeometryReader { geo in
            let orta = geo.size.width / 2
            ZStack {
                Canvas { c, _ in
                    var yay = Path()
                    yay.addArc(center: CGPoint(x: orta, y: 716), radius: 700, startAngle: .degrees(-108), endAngle: .degrees(-72), clockwise: false)
                    c.stroke(yay, with: .color(Color(tema.renkler.murekkep3)), lineWidth: 1)
                    for i in -12...12 {
                        let aci = Double(i) * .pi / 180
                        var cizgi = Path()
                        cizgi.move(to: CGPoint(x: orta + 700 * sin(aci), y: 716 - 700 * cos(aci)))
                        let r = i.isMultiple(of: 6) ? 690.0 : 696.0
                        cizgi.addLine(to: CGPoint(x: orta + r * sin(aci), y: 716 - r * cos(aci)))
                        c.stroke(cizgi, with: .color(Color(tema.renkler.pirinc)), lineWidth: 1)
                    }
                }
                ForEach(-1...1, id: \.self) { fark in
                    let i = sira + fark
                    if salonlar.indices.contains(i) {
                        Button { sira = i } label: {
                            Text(salonlar[i].ad).font(Yazi.serif(fark == 0 ? 17 : 13))
                                .multilineTextAlignment(.center).lineLimit(2)
                                .frame(width: orta * 0.58, height: 44)
                        }
                        .position(x: orta + CGFloat(fark) * orta * 0.76, y: fark == 0 ? 45 : 60)
                    }
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(DragGesture(minimumDistance: 12).onChanged { v in
                if suruklemeBasi == nil { suruklemeBasi = sira }
                let adim = Int((-v.translation.width / 65).rounded())
                sira = min(salonlar.count - 1, max(0, (suruklemeBasi ?? sira) + adim))
            }.onEnded { _ in suruklemeBasi = nil })
        }
        .frame(height: 84)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Akımlar çarkı")
        .accessibilityValue(salonlar.indices.contains(sira) ? salonlar[sira].ad : "")
        .accessibilityAdjustableAction { yon in
            if yon == .increment { sira = min(salonlar.count - 1, sira + 1) }
            if yon == .decrement { sira = max(0, sira - 1) }
        }
    }
}
