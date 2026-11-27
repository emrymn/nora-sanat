// Z4e · Hikâyeler arşivi. Tasarım: Neon 4. tur (dal neon/hikayeler-tasarim-4, PR #83; birleştirilmedi):
// tasarim/hikayeler-4/yon-2.html `.arsiv`, goruntuler/yon-2-arsiv{,-donem,-begendiklerim}-*.png. Substack'teki gibi
// üstte sade bir sekme: En yeni · Dönem (sanatçının doğduğu yüzyıl, doğum yılı sırasıyla) · Beğendiklerim.
import NoraCekirdek
import SwiftUI

struct HikayeArsiv: View {
    /// Gezinti yolundaki kimliği (sanatçı kimliklerinden biri olamaz)
    static let kimlik = "arsiv"

    enum Sekme: String, CaseIterable, Identifiable {
        case enYeni = "En yeni"
        case donem = "Dönem"
        case begendiklerim = "Beğendiklerim"
        var id: String { rawValue }
    }

    let ac: (String) -> Void

    @Environment(TemaDeposu.self) private var tema
    @Environment(\.dismiss) private var geri
    @State private var depo = HikayeDeposu.shared
    @State private var calar = HikayeCalari.shared
    @State private var sekme: Sekme = {
        #if DEBUG
        return HikayeProva.arsivSekmesi
        #else
        return .enYeni
        #endif
    }()

    var body: some View {
        let c = HikayeRenk(r: tema.renkler)
        VStack(spacing: 0) {
            ust(c)
            sekmeler(c)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    switch sekme {
                    case .enYeni:
                        liste(depo.enYeni)
                    case .donem:
                        ForEach(depo.donemler, id: \.baslik) { g in
                            Section {
                                liste(g.hikayeler)
                            } header: {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(g.baslik).font(Yazi.sans(13, agirlik: 600)).foregroundStyle(c.pirinc)
                                        .accessibilityAddTraits(.isHeader)
                                    Spacer()
                                    Text("\(g.hikayeler.count) yazı").font(Yazi.sans(12)).foregroundStyle(c.yazi3)
                                }
                                .padding(.top, 18).padding(.bottom, 6)
                                .background(c.zemin)
                            }
                        }
                    case .begendiklerim:
                        let l = depo.begenilenler
                        if l.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: "heart").font(.system(size: 26)).foregroundStyle(c.pirinc)
                                Text("Henüz beğendiğin yazı yok.").font(Yazi.okuma(19, agirlik: 600)).foregroundStyle(c.yazi)
                                Text("Yazıların sonundaki ya da kartlardaki kalbe dokununca burada toplanır.")
                                    .font(Yazi.sans(14)).foregroundStyle(c.yazi2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 36)
                        } else {
                            liste(l)
                        }
                    }
                    Color.clear.frame(height: calar.acik ? 96 : 24)
                }
                .padding(.horizontal, 22)
            }
            .scrollIndicators(.hidden)
            .id(sekme)
        }
        .background(c.zemin.ignoresSafeArea())
    }

    private func liste(_ l: [SanatciHikayesi]) -> some View {
        ForEach(Array(l.enumerated()), id: \.element.id) { i, h in
            HikayeListeSatiri(hikaye: h, ac: ac, son: i == l.count - 1)
        }
    }

    private func ust(_ c: HikayeRenk) -> some View {
        HStack(spacing: 12) {
            Button { geri() } label: { HikayeIkon(simge: .geri, boyut: 20, kalinlik: 1.8) }
                .buttonStyle(HikayeCamDugme())
                .accessibilityLabel("Hikâyeler'e dön")
            VStack(alignment: .leading, spacing: 1) {
                Text("Arşiv")
                    .font(Yazi.okuma(28, agirlik: 600, stil: .largeTitle))
                    .tracking(-0.56)
                    .foregroundStyle(c.yazi)
                    .accessibilityAddTraits(.isHeader)
                Text(sekme == .donem ? "\(depo.hikayeler.count) hikâye · doğum yılına göre" : "\(depo.hikayeler.count) hikâye")
                    .font(Yazi.sans(12.5)).foregroundStyle(c.yazi3)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.top, 4).padding(.bottom, 8)
    }

    /// Altı pirinç çizgili metin sekmeleri
    private func sekmeler(_ c: HikayeRenk) -> some View {
        HStack(spacing: 22) {
            ForEach(Sekme.allCases) { s in
                let secili = s == sekme
                Button {
                    Titresim.secim()
                    withAnimation(.easeOut(duration: 0.2)) { sekme = s }
                } label: {
                    Text(s.rawValue)
                        .font(Yazi.sans(14.5, agirlik: secili ? 600 : 500))
                        .foregroundStyle(secili ? c.yazi : c.yazi3)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(secili ? c.pirinc : .clear).frame(height: 2)
                        }
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(secili ? .isSelected : [])
                .accessibilityIdentifier("arsiv-\(s)")
            }
            Spacer()
        }
        .padding(.horizontal, 22)
        .overlay(alignment: .bottom) { Rectangle().fill(c.kenar).frame(height: 1) }
    }
}
