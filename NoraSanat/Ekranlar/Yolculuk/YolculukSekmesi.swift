// Kaynak: sanat-atlasi js/ekranlar/harita.js, js/harita.js, css/app.css @ a866b86
import SwiftUI
import NoraCekirdek

@MainActor @Observable
final class YolculukDeposu {
    let site = SiteVerisi()
    var katalog: SiteKatalogu?
    var ilerleme: Ilerleme?
    var dosyalar = [String:JSONDeger]()
    var duraklar = [YolculukDuragi]()
    var hata: String?

    func yukle() async {
        do {
            if katalog == nil {
                async let k = site.katalog()
                let dosya = await site.veriler(["harita.json","harita_yolcu.json","harita_patikalar.json","harita_motifler.json","ders_kaynaklari.json","yuruyus.json"])
                dosyalar = try dosya.mapValues(JSONDeger.coz)
                guard dosyalar["harita.json"] != nil else { throw URLError(.cannotDecodeContentData) }
                katalog = try await k
            }
            guncelle(try await IlerlemeKoprusu.shared.oku())
            let eski = ilerleme?[alan:"haritaGorulen"]?.dizi ?? []
            let yeni = duraklar.filter { $0.acik && !eski.contains(.metin($0.id)) }.map(\.id)
            if !yeni.isEmpty {
                await yaz { il in
                    var idler = il[alan:"haritaGorulen"]?.dizi?.compactMap(\.metin) ?? []
                    for id in yeni where !idler.contains(id) { idler.append(id) }
                    il[alan:"haritaGorulen"] = .dizi(idler.prefix(300).map(JSONDeger.metin))
                }
            }
        } catch { hata = "Yolculuk verileri okunamadı." }
    }

    func yaz(_ islem: (inout Ilerleme) -> Void) async {
        do { guncelle(try await IlerlemeKoprusu.shared.degistir(islem)) }
        catch { hata = "İlerleme kaydedilemedi. Yeniden dene." }
    }

    func guncelle(_ il: Ilerleme) {
        ilerleme = il
        if let katalog, let veri = dosyalar["harita.json"] {
            duraklar = YolculukHaritasi.kur(katalog,ilerleme:il,harita:veri,dersler:dosyalar["ders_kaynaklari.json"],yuruyus:dosyalar["yuruyus.json"])
        }
        hata = nil
    }

    var simdiki: YolculukDuragi? { duraklar.first { $0.acik && !$0.gecti("orta") } ?? duraklar.last(where: \.acik) }
    var yolcu: YolculukDuragi? { duraklar.first { $0.acik && $0.id == ilerleme?[alan:"haritaYolcu"]?.metin } ?? simdiki }
}

struct YolculukSekmesi: View {
    @Environment(KabukDurumu.self) private var kabuk
    @Environment(TemaDeposu.self) private var tema
    @State private var depo = YolculukDeposu()
    @State private var zaman = false
    @State private var yenile = 0
    var body: some View {
        Group {
            if let hata = depo.hata {
                ContentUnavailableView { Text(hata) } actions: {
                    Button("Yeniden dene") { Task { await depo.yukle() } }
                } 
            } else if let k = depo.katalog, let il = depo.ilerleme {
                if zaman { ZamanEkrani(katalog:k, ilerleme:il) }
                else { YolculukHaritaEkrani(depo:depo, katalog:k, il:il, zaman:{ zaman = true }).id(yenile) }
            } else { ProgressView("Yolculuk hazırlanıyor…") }
        }.frame(maxWidth:.infinity,maxHeight:.infinity)
         .background(Color(tema.renkler.zemin)).foregroundStyle(Color(tema.renkler.murekkep))
         .task {
             await depo.yukle()
             #if DEBUG
             if depo.ilerleme != nil, NoraSanatApp.arguman("-yolculukSayfa") != nil {
                 try? Data().write(to:FileManager.default.temporaryDirectory.appendingPathComponent("yolculuk-hazir"))
             }
             #endif
         }
         .onChange(of:kabuk.yerliAdres[.yolculuk],initial:true) { _, adres in
             if let adres { zaman = adres == "#/zaman"; kabuk.adresIslendi(.yolculuk) }
             #if DEBUG
             if NoraSanatApp.arguman("-yolculukSayfa") == "zaman" { zaman = true }
             #endif
         }
         .onChange(of:kabuk.yenidenDokunma[.yolculuk]) { _,_ in zaman = false; yenile += 1 }
    }
}

func haritaGorseli(_ ad: String) -> URL? {
    URL(string:"https://sanat-atlasi.pages.dev/gorseller/harita/\(ad).webp")
}

private struct YolculukHaritaEkrani: View {
    let depo: YolculukDeposu
    let katalog: SiteKatalogu
    let il: Ilerleme
    let zaman: () -> Void
    @Environment(TemaDeposu.self) private var tema
    @Environment(KabukDurumu.self) private var kabuk
    @State private var tur = YolculukHaritasi.vakit(saat:Calendar.current.component(.hour,from:Date()))
    @State private var durak: YolculukDuragi?
    @State private var kurs = false
    @State private var motif: String?
    private let bolgeler = YolculukHaritasi.bolgeler

    var body: some View {
        GeometryReader { g in
            ScrollViewReader { vekil in
                ScrollView {
                    VStack(spacing:0) {
                        HStack(alignment:.firstTextBaseline) {
                            Text("Yolculuk").font(Yazi.serif(30))
                            Text("\(depo.duraklar.filter(\.acik).count)/\(depo.duraklar.count) bölüm · \(depo.duraklar.reduce(0){$0+$1.yildiz}) ★").font(Yazi.sans(14))
                            Spacer()
                        }.padding(.horizontal,24).frame(height:48)
                        ForEach(bolgeler.indices.reversed(),id:\.self) { i in
                            donem(i,g.size.width)
                            if i > 0 { gecis(i,g.size.width) }
                        }
                        Color.clear.frame(height:1).id("son")
                    }
                }.defaultScrollAnchor(.bottom)
                 .task {
                     await Task.yield()
                     vekil.scrollTo(depo.simdiki?.id ?? "son",anchor:UnitPoint(x:0.5,y:0.55))
                 }
            }
            .overlay(alignment:.top) {
                HStack(alignment:.top) {
                    Button { kurs = true } label: {
                        HStack(spacing:10) {
                            let sayi = katalog.kursKonulari.filter { il.islenenKume.contains($0.no) }.count
                            ZStack { Circle().stroke(.secondary,lineWidth:2)
                                Circle().trim(from:0,to:CGFloat(sayi)/CGFloat(max(1,katalog.kursKonulari.count))).stroke(.yellow,lineWidth:2).rotationEffect(.degrees(-90))
                            }.frame(width:32,height:32)
                            VStack(alignment:.leading) {
                                Text("\(sayi) / \(katalog.kursKonulari.count) konu").font(Yazi.sans(15,agirlik:600))
                                Text(katalog.kursKonulari.first { !il.islenenKume.contains($0.no) }.map { "Sıradaki: Konu \($0.no)" } ?? "Bütün konular işlendi").font(Yazi.sans(12))
                            }
                        }.padding(.leading,10).padding(.trailing,16).frame(height:52).background(.ultraThinMaterial,in:Capsule())
                    }
                    Spacer()
                    Button { tur = tur == "gece" ? "gunduz" : "gece" } label: {
                        Image(systemName:tur == "gece" ? "sun.max" : "moon").frame(width:44,height:44).background(.ultraThinMaterial,in:Circle())
                    }.accessibilityLabel(tur == "gece" ? "Gündüze geç" : "Geceye geç")
                }.buttonStyle(.plain).padding(.horizontal,12).padding(.top,10)
            }
        }
        .sheet(item:$durak,onDismiss:{ Task { await depo.yukle() } }) { x in
            YolculukDurakEkrani(durak:x,katalog:katalog,tur:tur).presentationDragIndicator(.visible)
        }
        .sheet(isPresented:$kurs) {
            VStack(spacing:18) {
                Etiket("Kursun neresindesin")
                Text("\(katalog.kursKonulari.filter { il.islenenKume.contains($0.no) }.count) / \(katalog.kursKonulari.count) konu işlendi").font(Yazi.serif(28))
                if let konu = katalog.kursKonulari.first(where:{ !il.islenenKume.contains($0.no) }) {
                    Etiket("Sıradaki · Konu \(konu.no)")
                    Text(konu.baslik).font(Yazi.serif(20))
                    Button("İşlendi yap") { Task { await depo.yaz { BenPanosu.isaretle([konu.no],islendi:true,il:&$0) } } }.buttonStyle(HapDugme())
                }
                Button("Bütün konular") { kurs = false; kabuk.sec(.ben); Gezgin.shared.git("#/ilerleme") }
                Button("Zaman") { kurs = false; zaman() }
            }.padding(24).presentationDetents([.medium]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(get:{ motif != nil },set:{ if !$0 { motif = nil } })) {
            if let id = motif, let eser = depo.dosyalar["harita.json"]?["eserler"]?[id] {
                ScrollView { VStack(alignment:.leading,spacing:14) {
                    Etiket("Saklı motif")
                    Text(eser["eser_tr"]?.metin ?? id).font(Yazi.serif(32))
                    Text([eser["sanatci"],eser["yil"],eser["yer"]].compactMap{$0?.metin}.joined(separator:" · ")).font(Yazi.sans(14))
                    Text(eser["hikaye"]?.metin ?? "").font(Yazi.okuma(18))
                    ForEach(depo.dosyalar["harita_motifler.json"]?["eserler"]?[id]?["hikaye"]?.dizi?.compactMap(\.metin) ?? [],id:\.self) { Text($0).font(Yazi.okuma(18)) }
                }.padding(24) }.presentationDragIndicator(.visible)
            }
        }
    }

    private func donem(_ i:Int,_ en:CGFloat) -> some View {
        let b = bolgeler[i], boy = en*3
        let duraklar = depo.duraklar.filter { $0.bolge == b }
        let ust = Double(8-i)*1.34
        let sinir = depo.duraklar.filter(\.acik).map { d in Double(8-(bolgeler.firstIndex(of:d.bolge) ?? 0))*1.34 + d.y - 0.07 }.min() ?? 11.72
        let resim = haritaGorseli("donem_\(b)_\(tur)")
        let motifler = depo.dosyalar["harita.json"]?["bolgeler"]?[b]?["motifler"]?.dizi ?? []
        return ZStack(alignment:.topLeading) {
            UzakGorsel(url:resim)
                .overlay { if sinir > ust {
                    UzakGorsel(url:resim).saturation(0.17).colorMultiply(Color(red:0.83,green:0.77,blue:0.65))
                        .mask(LinearGradient(stops:[.init(color:.white,location:max(0,min(1,sinir-ust-0.04))),.init(color:sinir >= ust+1 ? .white : .clear,location:max(0,min(1,sinir-ust)))],startPoint:.top,endPoint:.bottom))
                } }
            ForEach(motifler.indices,id:\.self) { j in
                if let kutu = motifler[j]["kutu"]?.dizi?.compactMap(\.sayi), kutu.count == 4 {
                    Button { motif = motifler[j]["eser"]?.metin } label: { Color.clear.contentShape(Rectangle()) }
                        .frame(width:(kutu[2]-kutu[0])*en,height:(kutu[3]-kutu[1])*boy)
                        .offset(x:kutu[0]*en,y:kutu[1]*boy).accessibilityLabel("Saklı motif \(j+1)")
                }
            }
            ForEach(duraklar) { x in
                let olcek = en/390
                Button { durak = x
                    if x.acik { Task { await depo.yaz { $0[alan:"haritaYolcu"] = .metin(x.id) } } }
                } label: {
                    UzakGorsel(url:haritaGorseli("sembol_\(b)_\(x.sembol)_\(tur)"),icerik:.fit)
                        .overlay { Circle().stroke(x.acik ? .yellow.opacity(0.8) : .gray,lineWidth:2) }
                        .overlay(alignment:.bottom){ Image(systemName:x.acik ? "star.fill" : "lock.fill").font(.caption2) }
                }.buttonStyle(.plain).frame(width:x.en*olcek,height:x.boy*olcek)
                 .position(x:x.x*en+(0.5-x.ax)*x.en*olcek,y:x.y*boy+(0.5-x.ay)*x.boy*olcek)
                 .accessibilityLabel(x.ad + (x.kilit.map { ", "+$0 } ?? ", \(x.yildiz) yıldız")).id(x.id)
            }
            if let x = depo.yolcu, x.bolge == b, let ad = depo.dosyalar["harita_yolcu.json"]?["bolgeler"]?[b]?["ad"]?.metin {
                UzakGorsel(url:haritaGorseli("\(ad)_\(b)_dur_\(tur)"),icerik:.fit).frame(width:44*en/390,height:96*en/390)
                    .position(x:max(18,min(372,x.x*390+(x.x>0.5 ? -34 : 34)))*en/390,y:x.y*boy-44*en/390).allowsHitTesting(false)
            }
        }.frame(width:en,height:boy).clipped()
    }


    private func gecis(_ i:Int,_ en:CGFloat) -> some View {
        ZStack {
            UzakGorsel(url:haritaGorseli("yansima_\(bolgeler[i])_alt_\(tur)")).scaleEffect(x:1,y:-1)
            UzakGorsel(url:haritaGorseli("yansima_\(bolgeler[i-1])_ust_\(tur)")).scaleEffect(x:1,y:-1)
                .mask(LinearGradient(colors:[.clear,.white],startPoint:.top,endPoint:.bottom))
            Text(YolculukHaritasi.adlar[i]).font(Yazi.serif(30)).shadow(radius:5)
        }.frame(width:en,height:en*1.02).clipped()
    }
}
