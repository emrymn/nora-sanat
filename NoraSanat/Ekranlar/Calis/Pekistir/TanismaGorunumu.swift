// Kaynak: sanat-atlasi js/ekranlar/pekistir.js (tanismaCiz, tanismaVitrin, tanismaVitrinSec, tanismaGoster,
// konuTanismaGoster, gecDugme), js/ekranlar/ortak.js (isimHtml), css/app.css (.tanisma*, .isim, .gec-*) @ a866b86
import NoraCekirdek
import SwiftUI

/// Yeni sanatçıyla tanışma: en tipik eserleri ve "Nasıl tanırım?".
/// Kart tanışması (`tanismaGoster`) ya da konu turunun turdan önceki tanışması (`konuTanismaGoster`).
struct TanismaGorunumu: View {
    let model: PekistirmeModeli
    let tur: TurKaydi
    let kapat: () -> Void
    @Environment(TemaDeposu.self) private var tema
    @State private var secili = 0
    @State private var gosterim: GosterimIstegi?

    private var r: TemaRenkleri { tema.renkler }
    /// Konu turunun tanışması mı (yoksa kartın önündeki tanışma)
    private var konuTanismasi: Bool { tur.tanismaBekliyor }
    private var sanatciId: String? { konuTanismasi ? tur.tanisma?.simdiki : tur.kart?.resim.id }
    private var eserler: [Eser] {
        guard let id = sanatciId else { return [] }
        let anahtarlar = konuTanismasi ? (tur.tanisma?.gosterilen ?? []) : (tur.kart?.tanisma ?? [])
        return anahtarlar.compactMap { model.eser(id, $0) }
    }

    var body: some View {
        let s = sanatciId.flatMap(model.sanatci)
        ZStack(alignment: .bottom) {
            Color(r.zemin).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SoruUstu(baslik: CevapYazilari.kipAdi(tur.kip), sayac: sayac, kapat: kapat)
                    if let s { kartela(s).padding(.horizontal, 24).padding(.top, 14) }
                    if !eserler.isEmpty { vitrin.padding(.top, 20) }
                    if let s { ipucu(s).padding(.horizontal, 24).padding(.top, 20) }
                    Text(yazilar.not).font(Yazi.sans(13)).lineSpacing(6).foregroundStyle(Color(r.murekkep2))
                        .padding(.horizontal, 24).padding(.top, 20)
                    Color.clear.frame(height: 130)
                }
            }
            .scrollIndicators(.hidden)
            altDugme
        }
        .id(sanatciId)
        .fullScreenCover(item: $gosterim) { g in
            Goruntuleyici(eserler: g.eserler, baslangic: g.baslangic).environment(tema)
        }
        .accessibilityIdentifier("tanisma")
    }

    private var sayac: String {
        if konuTanismasi, let t = tur.tanisma { return "Tanışma \(t.konum + 1) / \(t.sira.count)" }
        let toplam = tur.oturum.kuyruk.count
        return "\(min(tur.oturum.konum + 1, toplam)) / \(toplam)"
    }

    private var yazilar: (etiket: String, not: String, ust: String, ana: String) {
        guard konuTanismasi, let t = tur.tanisma else {
            return ("Yeni sanatçı · önce tanış", "Birazdan bu sanatçının burada görmediğin bir eseri sorulacak.", "Tanıdım", "Soruya geç")
        }
        let son = t.konum + 1 >= t.sira.count
        let sonraki = son ? nil : model.sanatci(t.sira[t.konum + 1])?.ad
        var konu = ""
        if case let .sanatci(.konu(no)) = tur.kip { konu = String(no) }
        return CevapYazilari.konuTanismasi(konu: konu, son: son, kartSayisi: tur.oturum.kuyruk.count, sonraki: sonraki)
    }

    /// Kartela: etiket, ad (küçük italik ilk satır, büyük bilinen ad, varsa tam ad), yıllar · akım
    private func kartela(_ s: Sanatci) -> some View {
        let p = model.katalog?.adParcalari(s)
        let ilk = p?.ilk ?? "", son = p?.son ?? s.ad, tam = p?.tam
        return VStack(alignment: .leading, spacing: 0) {
            PkEtiket(yazi: yazilar.etiket)
            VStack(alignment: .leading, spacing: 0) {
                if !ilk.isEmpty {
                    Text(ilk).font(Yazi.serif(19, italik: true)).foregroundStyle(Color(r.murekkep2)).padding(.top, 6)
                }
                Text(son).font(Yazi.serif(48)).tracking(-0.48).foregroundStyle(Color(r.murekkep))
                    .lineLimit(1).minimumScaleFactor(0.7)
                if let tam {
                    Text(tam).font(Yazi.serif(19, italik: true)).foregroundStyle(Color(r.murekkep2))
                }
            }
            .padding(.top, ilk.isEmpty ? 4 : 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(s.ad)
            .accessibilityAddTraits(.isHeader)
            Text("\(CevapYazilari.yillar(s)) · \(s.akim)").font(Yazi.sans(14, agirlik: 500)).tracking(0.28)
                .foregroundStyle(Color(r.murekkep2)).padding(.top, 12)
        }
    }

    /// Paspartulu büyük eser ve küçük şerit: şeritte başka esere dokunmak vitrini değiştirir, vitrine dokunmak görüntüleyiciyi açar.
    private var vitrin: some View {
        let liste = eserler
        let i = min(secili, max(0, liste.count - 1))
        return VStack(alignment: .leading, spacing: 12) {
            Button { gosterim = GosterimIstegi(eserler: liste, baslangic: i) } label: {
                UzakGorsel(url: model.gorsel(liste[i], 900), icerik: .fit)
                    .frame(height: 224)
                    .padding(7).background(Color(r.kenar))
                    .shadow(color: .black.opacity(0.45), radius: 18, y: 18)
                    .padding(.vertical, 20).padding(.horizontal, 28)
                    .frame(maxWidth: .infinity)
                    .background(Color(r.yuzey))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(liste[i].gorunenAd) — büyüt")
            HStack(alignment: .firstTextBaseline) {
                Text(liste[i].gorunenAd).font(Yazi.okuma(16, italik: true)).foregroundStyle(Color(r.murekkep)).lineLimit(2)
                Spacer()
                if liste.count > 1 {
                    Text("\(i + 1) / \(liste.count)").font(Yazi.sans(12, agirlik: 500)).tracking(0.96)
                        .foregroundStyle(Color(r.murekkep2)).accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 24)
            if liste.count > 1 {
                HStack(spacing: 8) {
                    ForEach(Array(liste.enumerated()), id: \.element.anahtar) { j, e in
                        Button {
                            withAnimation(tema.ayar.hareketAzaltilmis ? nil : .easeOut(duration: 0.25)) { secili = j }
                        } label: {
                            UzakGorsel(url: model.gorsel(e, 240), icerik: .fill)
                                .frame(width: 52, height: 64).clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(r.murekkep), lineWidth: j == i ? 2 : 0).padding(-3))
                                .opacity(j == i ? 1 : 0.55)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(e.gorunenAd)
                        .accessibilityAddTraits(j == i ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder private func ipucu(_ s: Sanatci) -> some View {
        let metin = model.ipucu(s.id)
        if !metin.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                PkEtiket(yazi: "Nasıl tanırım?", boyut: 12)
                Text(metin).font(Yazi.okuma(17)).lineSpacing(9).foregroundStyle(Color(r.murekkep))
            }
        }
    }

    private var altDugme: some View {
        let y = yazilar
        let t = tur.tanisma
        var geri: String?
        if konuTanismasi, let t, let onceki = t.gecmis.last, t.sira.indices.contains(onceki) {
            geri = model.sanatci(t.sira[onceki])?.ad ?? "Önceki sanatçı"
        }
        return GecDugmesi(ust: y.ust, ana: y.ana,
                          adim: konuTanismasi ? (t?.konum ?? 0) : 0,
                          toplam: konuTanismasi ? (t?.sira.count ?? 0) : 0,
                          geri: geri,
                          geriEylem: { Task { await model.tanismaGeri() } },
                          eylem: { Task { await model.tanismaGec() } })
            .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 14)
            .background(LinearGradient(stops: [.init(color: Color(r.zemin).opacity(0), location: 0),
                                               .init(color: Color(r.zemin), location: 0.2)],
                                       startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}
