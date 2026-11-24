# Nora Sanat → tamamen Swift: iş dağılımı

Bu dosya Claude ve ChatGPT'nin ortak iş listesi ve raporudur. Oturumlar birbirini görmez; **her şey burada yazılıdır.**
Her iş ayrı bir oturumda yapılır. **İşi bitiren, bu dosyada kendi işinin durumunu ve devir notunu yazar** (rapor budur).

**Kim ne yapar:**
| Şerit | Araç | Görev |
|---|---|---|
| **K** | Claude (iki hesap) | Temel işler (T1–T3, Z2, Z3) ve **her PR'ın denetimi** |
| **G** | ChatGPT (Codex) | Görsel ağırlıklı ekranlar: G2–G5. G1'i Gemini bitiriyor (PR #8) |
| **C** | ChatGPT (Codex) | Çalışma ağırlıklı ekranlar: C1–C5 |

G ve C şeritlerinin işleri **birbirinden ayrıdır**: farklı sekmeler, farklı klasörler (K6). Aynı dosyaya dokunmazlar.
İkisi de artık ChatGPT'de; iki ayrı ChatGPT oturumunda aynı anda yürüyebilirler.

**Hedef.** Sanat Atlası'nın (`emrymn/sanat-atlasi`, yayında `sanat-atlasi.pages.dev`) bütün ekranlarını Swift ile yeniden yazmak.
- Geçiş **sekme sekme** olur. Taşınmamış sekmeler o güne kadar sitenin kendisini (WKWebView) gösterir. Uygulama her an kullanılabilir kalır.
- Sitenin görünüşü ve davranışı korunur.
- Bitince web görünümü kalkar.

---

## Oturum kuralları

### Başlarken
0. **Hangi işi yapacağını kullanıcı söyler** ("T3'ü yap", "G1'i yap"). Mesajda iş adı yoksa kendin seçme; kullanıcıya hangisini istediğini sor. (Önceden "sıradaki işi al" deniyordu: iki oturum aynı anda başlayınca ikisi de T1'i yaptı, biri boşa gitti.)
1. `git checkout main && git pull`. Sonra `CLAUDE.md`'yi, bu dosyanın tamamını ve işinin bölümünü oku.
2. **Bağımlılıklar** sütunundaki işler `bitti` değilse başlama. Kullanıcıya hangi işin beklendiğini söyle.
3. **Açık PR'lara bak** (GitHub'da Pull requests, ya da `gh pr list`). Başlığında aynı iş kimliği (ör. "T3") olan açık PR varsa **başlama**: kullanıcıya o PR'ı söyle.
4. Sanat Atlası'nı salt okunur indir ve işinin kaynak dosyalarını oku. Commit'ini not et (`git -C <yol> rev-parse --short HEAD`):
   ```bash
   git clone --depth 1 https://github.com/emrymn/sanat-atlasi /tmp/sa
   ```
5. Dal aç: `is/<ID>-<kısa-ad>`, örneğin `is/T2-ilerleme`.
6. İlk commit'te tablodaki durumunu `sürüyor (Araç, tarih)` yap. Örnek: `sürüyor (ChatGPT, 2026-11-21)`.
7. Hemen **taslak PR** aç; başlığı iş kimliğiyle başlasın (ör. "T3 · Kabuk"). Öbür araçlar ne yapıldığını açık PR'lardan görür.

### Bitirirken
1. CI yeşil olmalı. Ekran görüntülerine bak: ekran sitedekine benziyor mu?
2. Bu dosyada iki şeyi güncelle:
   - Tablodaki durum: `PR açık (#n)`.
   - İşinin altındaki **Devir notu**: ne yapıldı, ne kaldı, tuzaklar, kaynak commit, sonraki işe ipucu.
3. Kullanıcıya şunları yaz:
   - PR linki.
   - Telefonda neyi deneyeceği (README'deki deneme listesine de ekle).
   - G ya da C işiyse: "Şimdi Claude'a denetlet."
4. **Hiçbir araç kendi PR'ını birleştirmez.** Sıra şöyle:
   1. CI yeşil.
   2. Claude denetimi (aşağıda) "onay".
   3. Kullanıcı "birleştir" der.
5. Birleşince durumu `bitti (#n)` yap. Bunu bir sonraki oturum da yapabilir.

### Bilgisayarında Xcode yoksa (ChatGPT ve Claude için aynı)
- Oturumlar bulutta (Linux) çalışır. iOS orada derlenemez, derlemeyi GitHub Actions yapar (`.github/workflows/ios-derle.yml`).
- Paket testleri Linux'ta çalışabilir: `swift test --package-path Paketler/NoraCekirdek` (Swift kuruluysa).
- CI sonucunu göremiyorsan PR'ı öyle bırak ve devir notuna "CI sonucu görülmedi" yaz. Denetçi Claude CI'ı okur.
- Kâhin (`Testler/kahin`) tarayıcı ister. Çalıştıramıyorsan beklenen değer dosyasını boş bırakma: devir notuna "kâhin denetçide" yaz. Denetçi Claude üretir.

### Çakışmasız çalışma
- Her iş **yalnız kendi klasörlerine** dokunur (bkz. K6).
- Ortak dosyalara (Kabuk, Tema, `IlerlemeKoprusu`, `Package.swift`, `project.pbxproj`) yalnız **Temel** işleri (Claude) dokunur.
- G işleri `NoraSanat/Ekranlar/{Galeri,Bugun,Yolculuk,Goruntuleyici}/`, C işleri `NoraSanat/Ekranlar/{Calis,Ben}/` altında çalışır. Mantık için `NoraCekirdek/<Konu>/` alt klasörleri de aynı biçimde ayrılır.
- Bir şerit işi ortak dosyada küçük bir değişikliğe ihtiyaç duyarsa önce `main`'i çeker. Değişikliği küçük tutar ve devir notunda yazar.
- Bu dosyada yalnız **kendi satırını ve kendi bölümünü** değiştir. Böylece iki PR aynı satıra dokunmaz.

## Denetim (Claude)
Kullanıcı yeni bir Claude oturumunda şunu yazar: *"koordinasyon/ISLER.md'deki denetim kurallarıyla PR #n'i denetle"*. Denetçi:
1. PR'ı ve işin bu dosyadaki bölümünü okur. Sitenin karşılık gelen kaynak dosyalarını açar.
2. CI'ı okur. Kırmızıysa kökünü bulur ve düzeltmeyi aynı dala gönderir.
3. Davranışı sitenin davranışıyla karşılaştırır:
   - Eksik özellik var mı?
   - Yanlış kural var mı? (çeldirici, vade, adlar, yıl, görsel adresi)
   - Site ilerlemesine yanlış yazma var mı? (K2: bilinmeyen alanlar korunmalı)
   - Kâhin testi eksikse yazar.
4. Ekran görüntülerini sitedeki aynı ekranla yan yana koyar.
5. Sonucu iki yere yazar:
   - **PR'a yorum:** maddeler halinde bulgular.
   - **Bu dosyada, işin bölümüne bir satır:** `Denetim: Claude, tarih — onay | düzeltme istendi (n madde) — yorum linki`.
6. Küçük ve kesin düzeltmeleri kendisi gönderir. Büyük olanları PR yorumunda bırakır; işi yapan araç aynı dalda düzeltir.
7. Onay verdiyse kullanıcıya "birleştir dersen birleştiririm" der. **Birleştirmeyi yalnız kullanıcı açıkça isterse yapar.**


---

## Mimari kararlar

**K1 · Sekme sekme geçiş.**
- Uygulama yerli bir `TabView` olur: Bugün, Yolculuk, Galeri, Çalış. Bunlara ek olarak Ben/Ayarlar.
- `Kabuk/Gecis.swift`'teki `yerliSekmeler` listesinde olmayan sekme, sitenin o adresini gösterir (`#/`, `#/harita`, `#/gozat`, `#/pekistir`).
- Site tek bir WKWebView'dir: Nora Sanat çerçevesi (`WebKabugu`), titreşim, rozet ve tekrar köprüleri.
- Bir sekmenin bütün işleri bitince adı `yerliSekmeler`'e eklenir.

**K2 · İlerlemenin tek kaynağı geçiş boyunca sitedir.**
- Kayıt `localStorage['sanat-atlasi:ilerleme']` içindedir. Şeması `js/depo.js` (`varsayilanIlerleme`, `ilerlemeDogrula`).
- Swift tarafı `Ilerleme` modelini **bilmediği alanları da koruyarak** okur ve yazar (ham JSON sözlüğü + tipli erişim).
- `IlerlemeKoprusu` okuma ve yazmayı sitenin kendi modülleriyle yapar. Böylece site ile Swift ekranları hep aynı veriyi görür; yedek ve IndexedDB yansısı da sitenin kodundan geçer.
  - Okuma: `const o = await import('/js/ekranlar/ortak.js'); o.d.ilerleme`.
  - Yazma: `Object.assign(o.d.ilerleme, yeni); o.kaydet();`.
  - Aynı adres aynı modül örneğini verir. Bu yöntem `Testler/kahin`'de denendi.
- **Z2**'de kayıt Swift'e taşınır ve WKWebView kalkar.

**K3 · Veri siteden gelir, uygulamaya gömülmez.**
- `data/*.json` siteden indirilir ve önbelleğe alınır. Örnek kalıp: `NoraCekirdek/TabloYukleyici.swift`. Görseller R2'den gelir (`data/gorsel_kaynagi.json`).
- Böylece Qwen'in ya da ChatGPT'nin eklediği içerik Xcode olmadan uygulamaya gelir.
- İnternet yoksa son indirilen veri kullanılır.

**K4 · Mantık `Paketler/NoraCekirdek`'e girer ve kâhinle sınanır.**
- Saf kurallar pakete girer: tekrar, çeldirici, seçim, adres çözme. Linux'ta `swift test` geçmeli.
- Beklenen değerler canlı sitenin kendi modüllerinden alınır (bkz. `Testler/kahin/README.md`).
- Her dosyanın başında kaynak yazılır: `// Kaynak: sanat-atlasi js/leitner.js @ <commit>`.

**K5 · Görünüş sitedeki gibi.**
- Renkler ve ölçüler `css/app.css`'teki `:root` değişkenlerinden alınır. Tasarım dili sitede `TASARIM_DILI.md`'de.
- Temalar: Gece (varsayılan), Gündüz ve Gündüz renkleri (`js/gunduzRenk.js`).
- Yazı tipleri sitedekiyle aynı ya da en yakın iOS karşılığı.
- Arayüz SwiftUI ile yazılır ve iOS'un kendi hissini verir: kaydırma, geçişler, menüler.

**K6 · Klasör sahipliği.**
- Ekranlar: `NoraSanat/Ekranlar/<Sekme>/…`. Mantık: `Paketler/NoraCekirdek/Sources/NoraCekirdek/<Konu>/…` (SwiftPM alt klasörleri kendiliğinden alır).
- Testler `Tests/NoraCekirdekTests/<Konu>Tests.swift`, örnekler `Ornekler/<konu>/`.
- Her ekranın bir DEBUG açılış argümanı olur: `-ekran <ad>`. CI bununla ekran görüntüsü alır; işi yapan `.github/workflows/ios-derle.yml`'e kendi adımını ekler.

**K7 · Site değişmeye devam eder.**
- Her iş taşıdığı site dosyalarını ve commit'ini devir notuna yazar.
- Sonradan sitede o dosyalar değişirse farkı şununla görülür:
  ```bash
  git -C /tmp/sa log <commit>..HEAD -- <dosyalar>
  ```
- Bu farklar **Y (yetişme)** işi olarak taşınır.

---

## İş listesi

**Şeritler:**
- Her araç **kendi şeridindeki** işleri yapar: Claude K; ChatGPT G ve C. Hangi işi yapacağını kullanıcı mesajında adıyla verir.
- Bağımlılığı bitmemiş işe başlanmaz. G ve C, temel (T1–T3) birleşene kadar bekler. Sadece G1, T1'den sonra başlayabilir.
- Aynı anda yürüyebilecek işler tablodaki bağımlılıklardan okunur. İki oturuma aynı iş verilmez.
- Tahmini süreler "oturum" cinsindendir. Bir oturum bir PR demektir.

| ID | İş | Şerit | Bağımlılık | Oturum | Durum |
|----|----|-------|------------|--------|-------|
| T1 | Site verisi ve görsel adresleri | K | – | 1–2 | bitti (#4) |
| T2 | İlerleme köprüsü + tekrar kuralları | K | – | 1–2 | bitti (#5) |
| T3 | Kabuk: yerli sekmeler, tema, görsel önbelleği | K | T1, T2 | 1 | bitti (#6) |
| G1 | Tam ekran görüntüleyici | G | T1 | 1–2 | bitti (#8) |
| C1 | Pekiştirme oturumu (kartlar, sorular) | C | T2, T3 | 2 | bitti: C1a (#7), C1b (#9), C1c (#14) |
| G2 | Galeri: akımlar, sanatçı, eserler, arama, koleksiyon | G | T3, G1 | 2–3 | bitti (#11); görünüş G2b'de |
| C1c | Pekiştirme: tanışma ve eksik adımlar | C | C1b | 1 | bitti (#14) |
| C2 | Çalış ana ekranı | C | C1 | 1 | bitti (#16) |
| G2b | Galeri: görünüş sitedeki gibi (K5) | G | G2, C4b | 1 | bitti (#15) |
| G3 | Başyapıtlar: liste ve yakın okuma | G | G2 | 1 | bitti (#19) |
| C3 | Dersler (Gör, Öğren, Ayırt et) + eser dersleri | C | C2, G1 | 2 | bitti (#22) |
| G4 | Bugün (Tuval) + resmin içinde yürüyüş | G | T3, G1 | 2 | bitti (#18); görünüş G4b'de |
| G4b | Bugün: görünüş sitedeki gibi (perde, alttaki ayrıntıda yakınlaşma, tur kartı) | G | G4 | 1 | bitti (#25) |
| C4 | Ben: İlerleme, Ayarlar, yedekle/geri yükle | C | T3 | 1–2 | bitti (#10) |
| C4b | Ben: görünüş sitedeki gibi (K5) | C | C4, T4 | 1 | bitti (#13) |
| G5 | Yolculuk haritası + Zaman | G | T3, C1 | 2 | bitti (#20): G5a ChatGPT, G5b (görünüş) Claude |
| Z3a | Yolculuk cilası | G | G5 | 1 | bitti (#27) |
| C5 | Çevrimdışı görseller (21 GB) | C | C4 | 1 | bitti (#21) |
| T4 | Yerli sekme çubuğu sitenin çubuğu gibi | K | T3 | 1 | bitti (#12) |
| T5 | Hareket izni penceresi çıkmasın | K | T3 | 1 | bitti (#17) |
| T6 | Çalış yerli sekme | K | C3 | 1 | bitti (#23) |
| T7 | Bugün + Yolculuk yerli; sekmesiz adresler yerli ekrana | K | G4b, G5 | 1 | bitti (#26) |
| T8 | CI'ı paralel makinelere böl (ekran görüntüleri) | K | T7 | 1 | bitti (#28) |
| Z2 | İlerlemeyi Swift'e al, WKWebView'i kaldır | K | hepsi | 1 | Z2a (#30), Z2b (#31), Z2c-1 (#34), Z2c-2 (#35) birleşti; Z2c-3 (#36) |
| Z3 | Cila + sitedeki son değişikliklere yetişme | K | Z2 | 1 | bekliyor |
| Z3b | Ders ve yazı cilası | C | C3 | 1 | birleşti (#29) |
| Z3c | Galeri ve Çalış zemininde tablonun iki renginden süzme | K | G3, C2 | 1 | birleşti (#32) |
| Z3d | Süzme telefonda görünmüyordu: renkler canlı, süzme güçlü | K | Z3c | 1 | PR açık |
| Z3e | Telefonda görülen iki hata: Galeri çarkı (iOS 18 kaydırma), Yolculuk dönem köprüsü | K | G2b, Z3a | 1 | PR açık |
| Z3f | Dönemin harfi: akım başlığı ve harita dönem adları (js/harfler.js, İş 48) | K | G2b, Z3a | 1 | birleşti (#38) |
| Z3i | Bugün cilası: sekmeye yeniden dokununca süzülerek başa dönüş (kullanıcı isteği; sitede yok), eğimin yumuşatması ve ışığı (js/egim.js TABLO_IZ, .egim-isik), "Yeni sürüm var mı?" bütün veriyi yeniler | K | T7 | 1 | birleşti (#41) |
| Z3j | Telefon geri bildirimi: çark ışığı ve alt payı, Galeri bölüm geçişi, arama büyüyerek, sekme girişi, Çalış kapak yürüyüşü (İş 191), Bugün açılış sırası, Gündüz süzmesi | K | Z3i | 1 | bitti (#42) |
| Z3k | Çark ışığı kutuda kesilmiyor (üst kenarda düz bant kalıyordu) | K | Z3j | 1 | bitti (#43) |
| Z3l | Galeri akım sayfası: renk şeridi (`paletBirlestir`) ve eğik yazılar (Archivo eğilerek, Newsreader'ın italiği) | K | Z3k | 1 | bitti (#44) |
| Z3m | Ekran rengi (ekranRengi) ve Başyapıtlar odaklı kırpma | K | Z3l | 1–2 | PR açık (#46) |
| Z3n | Ben panosu sahnenin dibinde (sitede padding-top 16; uygulama eski 120'yi koyuyordu), Yolculuk hapının yanındaki madalyon kalktı (sitede yok) | K | Z3k | 1 | PR açık |
| Z3q | Karşılaştırma kartları: başyapıt kaydı olmayan öneriye sanatçının katalogundan birebir tutan eserin görseli (kullanıcı isteği; sitede yok) | K | Z3n | 1 | PR açık |
| Y1 | Sesli rehberli bakış (yeni özellik) | – | G1, G4 | 1 | fikir: kullanıcı başlatınca |

**Sekmeler ne zaman yerli olur:**
- Galeri: G1 + G2 + G2b (görünüş) + G3 → **yerli (G3, #19)**
- Bugün: G4 + G4b (görünüş) → **yerli (T7)**
- Yolculuk: G5 (G5a + G5b) → **yerli (T7)**
- Çalış: C1 (C1a, C1b, C1c) + C2 + C3 → **yerli (T6)**
- Ben/Ayarlar: C4 + C4b (görünüş) → **yerli (C4b, #13)**
- Herhangi bir sekme yerli olmadan önce: T4 (yerli sekme çubuğu)

---

## İşler

### T1 · Site verisi ve görsel adresleri (Claude)
**Amaç:** Swift'te sitenin verisini sitenin gördüğü gibi görmek: hangi sanatçılar, hangi akımlar, bir sanatçının eser listesi, her eserin görsel adresi.

**Site kaynakları:**
- `js/app.js` `basla()` (hangi dosyalar yüklenir, hangi sırayla işlenir)
- `js/birlesme.js`, `js/resim.js` (`gorunurSanatcilar`, `gorunurAkimlar`)
- `js/eserler.js` (`onbellekEseri`, kopya, çıkarılan ve düzeltilen eserler, ortak atıflar, Türkçe adlar)
- `js/gorsel.js` (`gorselUrl`, `yerelUrl`, `secilenGorsel`, `ustKopya`, `gorselOrani`)
- `js/kurs.js`, `js/adlar.js`, `js/yardimci.js`

**Yapılacaklar:**
- `SiteVerisi`: dosyaları indirir ve önbelleğe alır. `TabloYukleyici`'nin genellenmiş hali; widget da bunu kullanmaya geçebilir.
- Codable modeller: `Sanatci`, `Akim`, `Konu`, `Eser`, `Gorsel`.
- Yukarıdaki süzme ve birleştirme kuralları.

**Kâhin:**
- `d.sanatcilar` ve `d.akimlar` kimlik listeleri.
- 20 sanatçının `sanatciEserleri` sonucu: başlık, yıl, görsel adresi 400 ve 1280.

**Bitti sayılır:** Kâhin testleri geçiyor ve widget yeni katmanla aynı tabloyu buluyor.

**Devir notu:** Claude, 2026-11-20 — PR #4 (dal `claude/quirky-turing-o4raim`: oturum ortamı bu dalı şart koştu, `is/T1-…` değil).
- **Kaynak:** `sanat-atlasi` @ `a866b86` (site 1.90.3). Taşınan: `js/app.js` `basla()` (dosya listesi ve sıra), `birlesme.js` (`sanatcilariBirlestir`, `akimlariBirlestir`), `resim.js`, `eserler.js` (`onbellekEseri`, `kopyalariAyikla`, `cikarilanlariAyikla`, `duzeltmeleriUygula`, ortak atıflar, `yilSupheliMi`, `eserAdiBul`, `sanatciEserleri`), `gorsel.js` (`gorselUrl`, `yerelUrl`, `commonsKucuk`, `gorselYedek`, `devasaUrl`, `devasaKaynagi`, `gorselOrani`, `ustKopya`, `yuruyusAdresleri`, `secilenGorsel`, `pekistirmeyeUygunMu`, `gorselSayfasi`, `gorselKaynakYazisi`), `kurs.js` (`kursKonulari`), `adlar.js` (`adParcala`, `bilinenAd`), `yardimci.js` (`dosyaNormal`, `notTemizle`, `baslikNormal`, `yilYaz`, `yillarYaz`), `md5.js`.
- **Yapılan** (`Paketler/NoraCekirdek/Sources/NoraCekirdek/SiteVerisi/`):
  - `SiteVerisi` (actor): `data/*.json` indirir, Caches'te saklar (varsayılan ömür 6 saat), internet yoksa son ineni verir. `veri(_:)`, `veriler(_:)`, `katalog()`.
  - `SiteKatalogu`: sitenin `d`'si. `tumSanatcilar`, `sanatcilar`, `akimlar`, `konular`, `kursKonulari`, `harita`, `kisaAdlar`, `akimRenk`, `akimSira`, `dikeyler`, `eserler(sanatciId)`, `gorselAdresi(eser, genislik:, kotuler:)`, `bilinenAd`, `adParcalari`.
  - `GorselAdresleri` (`k.gorsel`): bütün görsel adres kuralları; adresler **mutlak** döner (`gorseller/k/…` site köküne çözülür).
  - Modeller: `Sanatci` (+ `ham` JSON: modelde olmayan alanlar), `KursEseri`, `Akim`, `Konu` (+ `kapak`), `Eser`, `Gorsel`, `KisaAd`, `AdParcalari`.
  - `JSONDeger`/`SiraliNesne`: anahtar sırasını koruyan JSON okuyucu (aşağıda neden).
  - Widget: `TabloYukleyici` indirmeyi `SiteVerisi` ile yapıyor (kendi klasörü; önbellek dosya adları değişti, ilk açılışta bir kez yeniden iner), `GununTablosuCozucu.gorselAdresi` `GorselAdresleri`'ne bağlandı.
- **Kâhin:** `Testler/kahin/site_verisi.mjs` → `Ornekler/site_verisi/` (cevaplar + aynı anda alınmış veri dosyaları, ~4,9 MB). Sınananlar: kimlik listeleri (tüm/görünür sanatçı, birleşen akım), akımlar (sıra, komşu, renk), 57 kurs konusunun kapağı, 155 sanatçının ad parçaları, 20 sanatçının `sanatciEserleri` sonucu (851 eser: anahtar, başlık, Türkçe ad, tarih, yıl, müze, kaynak, ortak atıf, görsel 400/1280, en büyük kopya, `ustKopya`, oran, pekiştirmeye uygunluk), yerel kopyası olmayan 40 görselin Commons/müze/WikiArt adresleri, widget ↔ katalog aynı günün tablosu (100 gün). `SiteVerisiTests`, `SiteYazisiTests`; Linux'ta 26 test geçiyor. `CANLI=1 swift test …` canlı indirmeyi de sınar (CI'da atlanır).
- **Kalan / bilinçli farklar:**
  - Eser önbelleği (`eserler_onbellek.json`) 30 günden eskiyse site canlı Wikidata'daki yeni eserleri listenin sonuna ekler; Swift eklemez (kâhin `canli: false`). Bugünkü dosya 2026-11-13 tarihli: **2026-12-13'ten sonra** site yeniden üretmezse listelerin sonu farklılaşabilir. Önbellekte kaydı olmayan sanatçıda da yalnız kurs resimleri döner.
  - Taşınmayanlar (ilgili işe kalır): odak noktaları (`gorsel_odak*.json`, `yuruyus_odak.json`, `kaplamaKaymasi`) → G1/G4; günün resmi seçimleri (`gunun_resimleri.json`) → G4; `eser_notlari.json`, palet → G1; `eserSec`/`zorlukDilimi`/`kolaylikAl`, `akimOrtaYillari` → C1; `telefonAdresleri`/`devasaAdresleri` → C5; `akimBilgisiBirlestir`, `ozellikleriBirlestir` (akim_bilgi/akim_ozellikleri) → G2; `seviyeleriBirlestir` → T2.
- **Tuzaklar:**
  - Site `Object.entries` sırasına dayanıyor (ör. ortak atıfların sırası `eserler_onbellek.json`'daki sanatçı sırası; `sanatcilar.json` sırasından farklı). `JSONSerialization` sırayı kaybeder; veri dosyalarını `JSONDeger.coz` ile oku.
  - Swift `String` karşılaştırması Unicode eşdeğerliğine bakar (NFC = NFD), JS bakmaz. Verideki anahtarlarda böyle çakışma yok (denetlendi) ama yeni bir sözlükte akılda tut.
  - Kullanıcının "kötü görsel" işaretleri `GorselAdresleri.secilen(e, kotuler:)`'e verilmeli (ilerlemedeki `kotuler`, T2'den).
- **Sonraki işe ipucu:** `let k = try await SiteVerisi().katalog()`; `k.eserler(id)` sitedeki sanatçı sayfası listesiyle aynı sırada; ekranda `e.gorunenAd`, `e.tarih`; ızgara için `k.gorselAdresi(e, genislik: 400)`, kart/görüntüleyici için 1280, yakınlaştırmada `k.gorsel.ustKopya(…, buyuk: true)` ya da `devasaUrl`. Uygulamada tek `SiteVerisi` örneği tutulmalı (T3 Kabuk'ta ortama koyar).
- **Site değişirse (K7):** `git -C /tmp/sa log a866b86..HEAD -- js/app.js js/birlesme.js js/resim.js js/eserler.js js/gorsel.js js/kurs.js js/adlar.js js/yardimci.js`; kâhini yeniden çalıştır: `node Testler/kahin/site_verisi.mjs`.
- **CI:** yeşil (iOS derleme #11, `6b7e78d`). Ekran görüntüleri artifact'ta; oturumdan indirilemedi, denetçi baksın.
- **Not:** T1'i başka bir Claude oturumu da aynı anda yaptı (PR #3). Yalnız biri birleşmeli; T2 (#5) bu PR'ın üstüne kurulu.

**Denetim:** Claude, 2026-11-20 — **onay** (PR #4 yorumu). Kâhin bugünkü siteye karşı yeniden çalıştırıldı, veri dosyaları ve cevaplar örneklerle aynı. Eklenen `testTamKatalog`: görünür 155 sanatçının **bütün 7.349 eseri** (anahtar, ad, yıl, 400/1280 adres, pekiştirmeye uygunluk) sanatçı başına özetle siteyle aynı; bozulunca 155 hata veriyor (denendi). CI widget görüntüsü yeni katmanla doğru tabloyu gösteriyor. PR #3 (aynı iş) kapatıldı.

### T2 · İlerleme köprüsü + tekrar kuralları (Claude)
**Amaç:** İlerlemeyi Swift'ten okuyup yazmak (K2) ve tekrar kurallarını Swift'te kullanmak.

**Site kaynakları:**
- `js/depo.js` (şema ve doğrulama)
- `js/leitner.js`, `js/gecmis.js`, `js/ogrenme.js`, `js/seviye.js`, `js/kilit.js` (`acikSanatcilar`)
- `js/ekranlar/ortak.js` (`d`, `kaydet`, `acikListe`, `skor`)

**Yapılacaklar:**
- `Ilerleme` modeli: bilinmeyen alanları korur.
- `IlerlemeKoprusu`: `oku() async`, `yaz(_:) async`. Uygulamadaki tek WKWebView üzerinden çalışır; site yüklenmeden çağrılırsa bekler.
- Leitner aralıkları, vade, zayıf/görüldü, günlük kayıt, seri, gelecek yük, seviye geçişi.

**Kâhin:**
- Rastgele 200 ilerleme nesnesi üret.
- Her birinde sitenin `vadeSayisi`, `gelecekYuk`, `tekrarAraligi`/kutu güncellemesi ve `acikSanatcilar` sonuçlarını al.

**Bitti sayılır:**
- Kâhin testleri geçiyor.
- DEBUG ekranında (`-ekran ilerleme`) okunan ilerleme özeti görünüyor.
- Bir test yazması siteye yansıyor: CI'da sitede `#/ilerleme` ekran görüntüsü.

**Devir notu:** Claude, 2026-11-20 — PR #5, dal `is/T2-ilerleme`. **T1'in (#4) üstüne kurulu** (sıralı JSON okuyucu ve `Sanatci`/`Akim`/`Eser` modelleri oradan); PR'ın tabanı T1 dalı, #4 birleşince GitHub tabanı main'e çevirir. #4'ten önce birleştirilmemeli.
- **Kaynak:** `sanat-atlasi` @ `a866b86` (site 1.90.3). Taşınan: `js/leitner.js` (hepsi), `js/gecmis.js` (hepsi), `js/seviye.js` (hepsi), `js/ogrenme.js` (tanışma, karıştırılanlar), `js/kilit.js` (`acikSanatcilar`, `akimDurumlari`, `yeniAcilanlar`), `js/birlesme.js` `seviyeleriBirlestir`, `js/depo.js`'ten `gunlukGuncelle`, `sonCalisilanEkle` ve şema. Okuma/yazma yolu: `js/ekranlar/ortak.js` (`d`, `kaydet`), `js/depo.js` (`kayitKilitliMi`).
- **Yapılan:**
  - `NoraCekirdek/Ilerleme/`: `Ilerleme` (ham JSON üstünde tipli alanlar: `islenen`, `skorlar`, `skorlarKonu`, `gecmis`, `seviyeler`, `karisanlar`, `ekSanatcilar`, `sonCalisilanlar`, `kotuGorseller`, `gunluk`, `ayar(_:)`, `kayitNo`; bilinmeyen alanlar ve anahtar sırası korunur), `Skor`/`SkorKaydi`/`GunKaydi`/`SeviyeKaydi`/`Karisan`, kurallar `Leitner`, `Gecmis`, `Seviye`, `Ogrenme`, `Kilit`. `JSONYazici`: `JSON.stringify` ile aynı çıktı.
  - `NoraSanat/Kabuk/IlerlemeKoprusu.swift` (`@MainActor`, `IlerlemeKoprusu.shared`): `oku()`, `yaz(_:)`, `degistir { … }`. Site yüklenmediyse bekler (30 sn). Yazma `Object.assign(o.d.ilerleme, yeni); o.kaydet()`; okunduğundan beri sitede kayıt olduysa (`kayitNo` farklı) yazmaz → `.cakisma`; `degistir` taze kayıtla 3 kez dener. Site kaydı kilitlediyse `.kilitli`.
  - DEBUG `-ekran ilerleme` (`NoraSanat/Kabuk/IlerlemeOzeti.swift`): okunan ilerlemenin özeti (kayıt no, işlenen, açık sanatçı, seri, bugün/yarın vade, 14 günlük yük, seviyeler, karıştırılanlar); site arkada yüklü. `-ilerlemeYaz` ile önce deneme yazar. DEBUG `-adres "#/…"`: site o sayfada açılır.
  - CI: `5-ilerleme-ozeti.png` (Swift'in okuduğu + yazdığı), ardından uygulama yeniden açılıp `6-site-ilerleme.png` (sitenin `#/ilerleme`'si yazılanı göstermeli: 7-8. konular işlendi, bugün 12 kart).
- **Kâhin:**
  - `Testler/kahin/ilerleme.mjs` → `Ornekler/ilerleme/cevaplar.json` (3 MB): tohumlu rastgele 200 ilerleme; `vadeSayisi`, `yarinVade`, `gelecekYuk` (tüm ve açık sanatçılarla), `cevapla` (1000+ skor), `zayifMi`, `vadesiGeldiMi`, `tekrarAraligi`, `gecmisDogrula`, `seri`, `takvim`, `haftalikOran`, `acikSanatcilar`, `yeniAcilanlar`, `akimDurumlari`, `tanismaGerekirMi`, `karisanlarDogrula`, `enCokKarisanlar`, `seviyelerDogrula`, `seviyeleriBirlestir`, `seviyeCevapla`, `seviyeDurumu`, `seviyeKisa`, `ustaMi`, `oran`. Bir de **yazma vakası**: sitenin gerçek ilerlemesine sitenin işlemleri uygulanınca çıkan JSON metni, Swift'in aynı işlemlerden sonra yazdığıyla **birebir aynı**. Linux'ta 12 yeni test geçiyor (kuralı bilerek bozunca yakalıyor).
  - `Testler/kahin/ilerleme_koprusu.mjs`: köprü betiklerini (Swift dosyasındaki metin aynen) canlı sitede çalıştırır: site yüklenirken okuma bekliyor, yazma kaydediyor ve kayıt no artıyor, eski numarayla yazma reddediliyor, yeniden açınca site Swift'in yazdığını okuyor ve `#/ilerleme` gösteriyor. Geçti (bulutta, Chromium). CI'da (macOS) Playwright olmadığı için orada çalışmaz; denetçi elle çalıştırır.
- **Kalan:**
  - `ilerlemeDogrula`'nın tamamı taşınmadı: site kaydı açılışta doğruluyor, Swift onun doğruladığını okuyor. Z2'de (kayıt Swift'e geçince) gerekecek; `bolumlerDogrula`, `derslerDogrula`, `koleksiyonDogrula`, `bildirimlerDogrula`, `gorulenDogrula` ve ayar düzeltmeleri dahil.
  - Swift yazınca sitede o an açık olan sayfa kendiliğinden yeniden çizilmez (`kaydet` bellekteki sayfaları eskitir; sekmeye dönünce yenilenir). Swift ekranları siteyle aynı anda görünmeyeceği için şimdilik sorun değil.
  - Sitedeki değişiklikler Swift'e bildirilmiyor: Swift ekranı görünür olduğunda `oku()` ile tazelemeli (T3/C işleri).
  - `TekrarKoprusu` betiği aynen duruyor (rozet ve bildirim sayıları); Z2'de `Gecmis.gelecekYuk`/`vadeSayisi`'ne geçer.
- **Tuzaklar:**
  - Okumadan sonra site açılışta bir kez `kaydet()` çağırır (kayıt no artar): açılışta okunan kayıtla yazmak `.cakisma` verir. Hep `degistir` kullan.
  - Skorlar sitenin kendi nesneleri: `Skor`/`SkorKaydi`'nin bilmediği alanlar `ham`'da korunur; yeni alan eklemek için `Ilerleme[alan:]`.
  - Gün dizgeleri cihazın yerel günüdür (`GunTarihi.gun(Date())` = sitenin `bugunStr()`).
- **Sonraki işe ipucu (C1, C2, C4):** `let il = try await IlerlemeKoprusu.shared.oku()`; kart cevabı: `try await IlerlemeKoprusu.shared.degistir { il in var sk = il.skorlar; sk[id, default: SkorKaydi()].sanatci = Leitner.cevapla(sk[id]?.sanatci, dogru: d, bugun: gun); il.skorlar = sk; il.gecmisEkle(…); il.sonCalisilanEkle(id) }`. Açık sanatçılar: `il.acikSanatcilar(katalog.sanatcilar)`. 14 günlük yük grafiği (C2): `Gecmis.gelecekYuk`. Seviye (C1): `Seviye.isle`, `Seviye.eserSeviyesi`.
- **Site değişirse (K7):** `git -C /tmp/sa log a866b86..HEAD -- js/leitner.js js/gecmis.js js/seviye.js js/ogrenme.js js/kilit.js js/depo.js js/ekranlar/ortak.js`; `node Testler/kahin/ilerleme.mjs > …/Ornekler/ilerleme/cevaplar.json` ve `node Testler/kahin/ilerleme_koprusu.mjs`.
- **CI:** yeşil (iOS derleme #15, `f984b27`): köprü ve DEBUG ekranı derlendi, simülatör adımları geçti. `5-ilerleme-ozeti.png` ve `6-site-ilerleme.png` artifact'ta; oturumdan indirilemedi, denetçi baksın (6'da 7-8. konular işlendi ve bugün 12 kart görünmeli).


**Denetim:** Claude, 2026-11-20 — **onay** (PR #5 yorumu). Linux'ta 38 test geçti. `ilerleme_koprusu.mjs` canlı sitede yeniden çalıştırıldı: okuma, yazma, çakışma reddi ve yeniden açılışta sitenin Swift'in yazdığını okuması geçti. `ilerleme.mjs` yeniden çalıştırıldı: cevaplar aynı (yalnız `yazma` vakasındaki `olusturma` zaman damgası farklı, beklenen). CI görüntüleri: Swift özeti "siteye yazıldı · kayıt 5", sitenin `#/ilerleme` sayfası yazılanı gösteriyor. Düzeltme: CI'da `norasanat://` denemesi en sona alındı (simülatörün onay penceresi sonraki görüntülerin üstüne biniyordu).

### T3 · Kabuk (Claude)
**Amaç:** Yerli sekme çubuğu (K1). Sekmeler şimdilik siteyi gösterir; uygulama bugünküyle aynı çalışır.

**Yapılacaklar:**
- `NoraSanat/Kabuk/`: `KokGorunum` (TabView), `Gecis` (`yerliSekmeler`), `Tema` (K5), `Gorsel` (disk önbellekli görsel görünümü), `Titresim`.
- Sitenin kendi alt sekme çubuğu yerli çubukla çakışmamalı. Taşınmamış sekmede site tam ekran kalır ve yerli çubuk gizlenir; sekme geçişi sitenin çubuğuyla olur. Tüm sekmeler taşınınca yerli çubuk görünür. Alternatif bir çözüm seçersen devir notuna yaz.
- Widget, bildirim ve rozet bugünkü gibi çalışmaya devam etmeli.

**Bitti sayılır:**
- CI ekran görüntüleri bugünkünden farksız.
- `-ekran tema` ile renk ve yazı örnekleri görünüyor (gece ve gündüz).

**Devir notu:** Claude, 2026-11-20 · PR #6 · dal `claude/busy-cray-8z3g7e` (oturumun zorunlu dalı; `is/T3-…` açılamadı).
- **Kaynak:** sanat-atlasi `a866b86` (site 1.90.3). Taşınanlar:
  - `js/ekranlar/yonlendirme.js` `rotalar` (adres → sekme)
  - `js/ekranlar/ortak.js` `SEKMELER`, `TEMA_RENK`
  - `css/app.css` `:root` renk değişkenleri (gece, gündüz; Gündüz'ün koyu pirinci dosyanın sonunda) ve ölçüler
  - `js/titresim.js` (doğru tek, yanlış çift darbe)
  - yazı tipleri: `index.html`'deki Google Fonts
  K7 farkı: `git -C /tmp/sa log a866b86..HEAD -- js/ekranlar/yonlendirme.js js/ekranlar/ortak.js css/app.css js/titresim.js js/gunduzRenk.js index.html`
- **Seçilen çözüm (K1'in önerdiğiyle aynı, yarım geçiş için tamamlandı):**
  - Hiç sekme taşınmadıysa yerli çubuk hiç kurulmuyor; site tam ekran, uygulama bugünküyle birebir aynı.
  - Taşınmış bir sekmeye gelince site gizleniyor (opaklık 0; yüklü kalıyor), yerli ekran ve **yerli sekme çubuğu** görünüyor. Bu sekmeye nasıl gelindiği fark etmez: sitenin çubuğu, sitenin bir bağlantısı, widget, bildirim.
  - Yerli çubukta taşınmamış bir sekmeye dokununca site geri geliyor ve sitenin kendi sekme düğmesine basılıyor (kullanıcı dokunmuş gibi; ana ekran kalınan kaydırma yerinde).
  - Ben (İlerleme, Ayarlar) uygulamada 5. sekme. Sitede `#/ilerleme` ve `#/ayarlar` Bugün'ün altında görünür.
- **Yapılanlar:**
  - `NoraCekirdek/Gecis/Sekme.swift`: `Sekme` (bugun, yolculuk, galeri, calis, ben; `kokAdres`, `baslik`, `siteKimligi`) ve `SiteRotalari.siteSekmesi(_:)` / `sekme(_:)`. Sekmesiz sayfalar (pekiştirme kartı, karşılaştırma) nil döner, açıldıkları sekmede kalır.
  - `NoraCekirdek/Tema/TemaRenkleri.swift`: `RGBA` (CSS renk ayrıştırma), `TemaRenkleri.gece` / `.gunduz` (24 değişken, Türkçe adlarla; CSS adı yorumda), `TemaRenkleri(degiskenler:yedek:)` (sitenin canlı değerleri), `TemaOlcu`, `TemaAyari`.
  - `NoraCekirdek/Gorsel/GorselDeposu.swift`: görsellerin disk önbelleği (`Caches/Gorseller`, adresin MD5'i). Aynı adres için tek indirme yapılıyor; 400 MB'ı aşınca en uzun süredir kullanılmayanlar siliniyor.
  - `NoraSanat/Kabuk/KokGorunum.swift`: kök görünüm (tek WKWebView ve yerli TabView), `SekmeYeri` (yazılmamış yerli ekranın yeri).
  - `NoraSanat/Kabuk/Gecis.swift`:
    - `Gecis.tasinanlar`: **bir sekme bitince adı buraya eklenir**.
    - `KabukDurumu` (`secili`, `siteAdresi`, `yerliAdres[sekme]`).
    - Adres köprüsü (sitenin `hashchange`'i).
    - `Gezgin.git` (widget, bildirim) hedef sekme yerliyse yerli ekranı açıyor.
  - `NoraSanat/Kabuk/Tema.swift`:
    - `TemaDeposu` (`renkler`, `ayar`, `siteRengi`; eski `SiteTemasi`'nın yerine).
    - `TemaKoprusu`: sitenin `<html>` teması ve stili değişince hesaplanmış değişkenleri gönderiyor. Renkli Gündüz paleti ve tablonun vurgusu dahil.
    - `Yazi.serif` / `sans` / `okuma`: Bodoni Moda, Archivo, Newsreader. Değişken yazı tipleri; ağırlık ve optik boyut eksenlerle veriliyor, boyut Dinamik Yazı'yla ölçekleniyor.
    - Yazı tipleri `NoraSanat/YaziTipleri/` altında (OFL lisanslı, ~1,9 MB, açılışta kaydediliyor).
  - `NoraSanat/Kabuk/Gorsel.swift`: `UzakGorsel(url:icerik:yedek:)`. Görsel kutunun piksel boyuna küçültülerek çözülüyor, bellekte tutuluyor, yüklenince yumuşakça beliriyor. Adı bilerek `Gorsel` değil: `Gorsel` T1'in görsel modeli.
  - `NoraSanat/Kabuk/Titresim.swift`: `dogru`, `yanlis`, `secim`, `dokunus`, `desen` (sitenin `navigator.vibrate`'i) ve `Titresim.acik(il)` (sitenin titreşim ayarı).
  - `NoraSanat/Ekranlar/<Sekme>/<Sekme>Sekmesi.swift`: beş sekmenin iskeleti. Şerit işleri gövdeyi değiştirir; böylece ortak dosyaya dokunmaları gerekmez.
  - DEBUG açılış argümanları:
    - `-ekran tema`: Gece ve Gündüz örnekleri, altta sitenin canlı teması, yazı tiplerinin yüklendiği (✓).
    - `-yerliSekme galeri,ben`: yarım ekranları denemek için o sekmeleri yerli sayar.
  - CI'a iki ekran görüntüsü eklendi: `7-tema.png`, `8-yerli-sekme.png` (`-yerliSekme galeri -adres "#/gozat"`: yerli çubuk ve Galeri yeri).
- **Kâhin:**
  - `Testler/kahin/kabuk.mjs` → `Ornekler/kabuk/cevaplar.json`. 37 adreste sitenin sekme çubuğunda seçili sekme; gece, nötr gündüz ve renkli gündüzde (lapis) hesaplanmış değişkenler. Testler (`KabukTests.swift`) sabit tablonun Gündüz'ün koyu pirincini kaçırdığını yakaladı, düzeltildi.
  - `Testler/kahin/kabuk_koprusu.mjs`: Swift dosyalarındaki adres ve tema betikleri canlı sitede çalıştırıldı; adres, tema geçişleri ve sitenin sekme düğmesi geçti. Belge başında `<html>` yokken tema betiğinin kırıldığını yakaladı, düzeltildi. CI'da (macOS) Playwright olmadığı için orada çalışmaz; denetçi elle çalıştırır.
  - Linux'ta paket testleri: 47 test, 1'i yalnız canlı modda (atlanıyor).
- **Kalan / sonraki işler için:**
  - Yerli ekran `@Environment(TemaDeposu.self)` ve `@Environment(KabukDurumu.self)` okur. İkisi `KokGorunum`'un altında hazır; dışında (ör. DEBUG ekranı) `.environment(TemaDeposu.shared)` verilmeli.
  - `UzakGorsel` ve `SekmeYeri` de `TemaDeposu`'nu ortamdan bekler.
  - Renkler: `Color(tema.renkler.murekkep)`, zemin `tema.renkler.zemin`. Site açılmadan önce sabit tablo kullanılır.
  - `--vurgu` ailesi sitede tablonun renginden üretilir (`renkleriYaz`); sabit tablodaki değer yalnız başlangıç değeri. Swift ekranı kendi tablosunun vurgusunu isterse `js/renk.js`'i taşıması gerekir (G4).
  - Yerli ekran sitenin adresine göre derin bağlantı açacaksa `durum.yerliAdres[.galeri]`'yi okur, sonra `durum.adresIslendi(.galeri)` çağırır.
  - Hareket ayarı: `tema.ayar.hareketAzaltilmis`.
  - Görsel: `UzakGorsel(url: katalog.gorselAdresi(e, genislik: 400, kotuler: il.kotuGorseller))`. Görüntüleyici (G1) büyük kopyayı `GorselDeposu.shared.veri(url)` ile kendisi çözebilir.
  - Yerli çubuğun simgeleri SF Symbols (sitenin çizimlerine en yakın). Sitenin kendi simgeleri istenirse Z3'te SVG'den taşınır.
  - Sitenin `history.replaceState` ile yaptığı adres değişimleri `hashchange` vermez, köprüye gelmez. Bugün yalnız yarım oturumda `#/pekistir`'e dönüşte var; sekme aynı kaldığı için etkisi yok.
- **Tuzaklar:**
  - Yerli sekme seçiliyken site görünmez ama yüklü ve çalışır kalır. WKWebView kaldırılmamalı (Z2'ye kadar köprüler ona bağlı).
  - `Gecis.tasinanlar`'a bir sekme eklemek o sekmenin bütün yollarını (alt sayfalar dahil: `#/sanatci/…`, `#/akim/…`) yerliye bağlar: `SiteRotalari.sekme`.
- **CI:** 9892ece yeşil (https://github.com/emrymn/nora-sanat/actions/runs/44821824720): iOS derlemesi, çekirdek testleri ve sekiz ekran görüntüsünün hepsi alındı (`7-tema.png`, `8-yerli-sekme.png` yeni). Görüntüleri oturumdan açamadım; denetçi `ekranlar` yükünden 1–6'nın bugünküyle aynı olduğuna, 7'de Gece/Gündüz örneklerine ve yazı tiplerinin ✓ olduğuna, 8'de sitenin gizlenip yerli çubuğun Galeri seçili göründüğüne baksın.

**Denetim:** Claude, 2026-11-21 — **onay, bir düzeltmeyle** (PR #6 yorumu).
- Linux'ta 48 test geçti.
- `kabuk.mjs` canlı sitede yeniden çalıştırıldı: sekmeler ve sabit renkler aynı. Yalnız `--vurgu` ailesi farklı; site onu günün tablosundan üretiyor, test bu yüzden onu bilerek hariç tutuyor.
- `kabuk_koprusu.mjs` canlı sitede geçti.
- CI görüntüleri: 1–6 bugünküyle aynı. 7'de Gece/Gündüz ve üç yazı tipi ✓.
- **Hata:** 8'de yerli çubuk yoktu; görüntü 1 ile aynıydı.
  - Neden: `-adres`, widget ya da bildirim yerli Galeri'yi açıyordu, ama site açılışta kendi adresini (`#/`) bildirince seçim Bugün'e dönüyordu.
  - Düzeltme: karar `SiteRotalari.secim` olarak çekirdeğe alındı (`SekmeTests.testSitedenGelenAdresleSekmeSecimi`). Taşınmış sekmenin adresi her zaman yerliyi açar. Taşınmamış sekmeye yalnız sitenin sekmesi gerçekten değişince geçilir.
- Yazı tipleri OFL, lisans dosyaları içinde, ~1,9 MB: uygun.

### G1 · Tam ekran görüntüleyici (Gemini bitirir; sonraki G işleri ChatGPT)
**Site kaynakları:** `js/goruntuleyici.js`, `js/ayrinti.js`, `js/hikaye.js`, `js/keskin.js`, `js/koleksiyon.js`, `js/bildirim.js`, `js/karsilastir.js`.

**Yapılacaklar:**
- İki parmakla yakınlaştırma ve kaydırma, eserler arası geçiş, aşağı çekince kapanma.
- Künye, not ve hikâye.
- Rehberli ayrıntı noktaları.
- Koleksiyon kalbi, "kötü görsel" bildirimi (ilerlemeye yazar), keskin üst kopya.
- Başka ekranlar şöyle açar: `Goruntuleyici(eserler:baslangic:)`.

**Devir notu:** Gemini, 2026-11-21 — PR #8, dal `is/G1-goruntuleyici`.
- **Kaynak:** `sanat-atlasi` @ `a866b86`. Taşınan dosyalar: `js/goruntuleyici.js`, `js/ayrinti.js`, `js/hikaye.js`, `js/keskin.js`, `js/koleksiyon.js`, `js/bildirim.js`, `js/karsilastir.js` (ve `js/ikonografi.js`'teki `eserKonusu`).
- **Yapılan:**
  - `Paketler/NoraCekirdek/Sources/NoraCekirdek/Goruntuleyici/`:
    - `Ayrinti.swift`: `AyrintiNoktasi`, `AyrintiKaydi`, `NoktaOdagi`, `AyrintiKurallari` (`noktaGecerliMi`, `ayrintilariAl`, `ayrintiAnahtari`, `ayrintiBul`, `eserinAyrintisi`, `noktaOdagi`, `noktaYeri`, `yakinlasmaSiniri`; JS `Math.round` ile birebir uyumlu `jsRound`).
    - `Hikaye.swift`: `HikayeKarakteri`, `HikayeKaydi`, `HikayeKurallari` (`hikayeleriAl`, `eserinHikayesi`, `karakterKaydi`).
    - `Koleksiyon.swift`: `KoleksiyonKaydi`, `KoleksiyonKurallari` (`dogrula`, `koleksiyondaMi`, `degistir`, `sinir = 500`).
    - `Bildirim.swift`: `BildirimKaydi`, `BildirimKurallari` (`nedenler`, `dogrula`, `eseriBildir`, `kotuIsaretle`, `sinir = 300`).
    - `GoruntuleyiciKurallari.swift`: `kaynakYazisi`, `notlariAl`, `eserNotu`, `taninmaMetni`, `karsilastirmaAdresi`, `karsilastirmaRotasi`, `benzerSanatcilar`, `ikonografiKonuHaritasi`, `eserKonusu`, `keskinlik`, `commonsUstu`, `keskinUstAdres`.
    - `GoruntuleyiciBaglami.swift`: `GoruntuleyiciGorselAdresleri` ve `GoruntuleyiciBaglami` (`SiteVerisi` üzerinden `SiteKatalogu`, `eser_notlari.json`, `eser_ayrintilari.json`, `eser_hikayeleri.json` ve `ikonografi.json` verilerini yükleyip T1'in `GorselAdresleri` ve `SiteKatalogu` ile birleştiren veri bağlamı).
  - `NoraSanat/Ekranlar/Goruntuleyici/`:
    - `Goruntuleyici.swift`: `Goruntuleyici(eserler:baslangic:)` tam ekran görüntüleyici ekranı. İki parmakla yakınlaştırma (1x–6x), çift dokunuşla 2.5x ↔ 1x, kaydırma, tek dokunuşla sade görünüm, eserler arası geçiş (yatay kaydırma veya ok düğmeleri), aşağı çekince küçülüp şeffaflaşarak kapanma, ilk eserde sağa çekince kapanma, künye/not/konu bağlantısı/kaynak sayfası, koleksiyon işareti ve `⋯` bildirim menüsü (`IlerlemeKoprusu.shared.degistir` ile ilerlemeye yazar).
    - `GoruntuleyiciGorseli.swift`: T3'ün görsel bileşeni henüz olmadığı için geçici `AsyncImage` tabanlı keskin görsel bileşeni (önce 1280/800 px birincil kopya, hata olursa yedek adres, yüklendikten sonra arkada 4096 px `devasaUrl` üst kopya indirip sarsıntısız geçiş) ve `TabloIsigiGorunumu` (400 px bulanık arka plan ışığı).
    - `AyrintiGorunumu.swift`: `AyrintiNoktalariKatmani` (tablo üzerinde numaralı ayrıntı noktaları) ve `AyrintiIncelemePaneli` (Önceki / Sonraki / Bitir).
    - `HikayePaneliGorunumu.swift`: alttan açılan "Hikâyesi" paneli ("Ne oluyor?", "Kim kimdir?", "Ressamla bağı", "Gözden kaçanlar" ve "Karakterleri resimde gör").
- **Kâhin ve Testler:**
  - `Testler/kahin/goruntuleyici.mjs` → `Paketler/NoraCekirdek/Tests/NoraCekirdekTests/Ornekler/goruntuleyici/` (`cevaplar.json` + veri dosyaları): 264 başyapıtın bütün ayrıntı noktaları, 3 farklı sahne boyutunda `noktaOdagi` ve `yakinlasmaSiniri`, 5 hikâye ve karakter kutuları, 155 görünür sanatçının tanıma metinleri ve `benzerSanatcilar` listesi, 293 eserin künye `kaynakYazisi`, `devasaKaynagi`, `sayfa`, `eserNotu`, `ayrinti`, `hikaye` ve ikonografi `konu` eşleşmeleri, koleksiyon ve bildirim adımları.
  - `Paketler/NoraCekirdek/Tests/NoraCekirdekTests/GoruntuleyiciTests.swift`: 7 yeni XCTest eklendi; toplam 45 paket testi ve iOS Simulator `xcodebuild` derlemesi hatasız geçiyor.
- **Kalan / Tuzaklar:**
  - JS `Math.round(-x.5)` negatif yarımları `+∞` yönüne (`-x`) yuvarlarken Swift `.rounded()` `-∞` yönüne (`-(x+1)`) yuvarlıyor; `noktaOdagi`'nda birebir uyum için `floor(x + 0.5)` (`jsRound`) kullanıldı.
  - T3 birleştiğinde `GoruntuleyiciGorseli` içindeki `AsyncImage` yapısı T3'ün disk önbellekli `Gorsel` bileşenine geçirilebilir.
- **Sonraki işe ipucu (G2, G3, G4, C3):** Başka ekranlardan `Goruntuleyici(eserler: eserListesi, baslangic: indeks)` ile doğrudan tam ekran (`fullScreenCover`) açılabilir; doğrudan inceleme veya hikâye kipinde açmak için `incelemeyeBasla: true` / `hikayeyeBasla: true` verilebilir.
- **Site değişirse (K7):** `git -C /tmp/sa log a866b86..HEAD -- js/goruntuleyici.js js/ayrinti.js js/hikaye.js js/keskin.js js/koleksiyon.js js/bildirim.js js/karsilastir.js js/ikonografi.js`; kâhini yeniden çalıştır: `node Testler/kahin/goruntuleyici.mjs`.

**Denetim:** Claude, 2026-11-21 — **onay, düzeltmelerle** (PR #8 yorumu).
- Gemini'nin örnekleri sitenin eski sürümünden (1.81.3, 154 ayrıntı) alınmıştı. Kâhin canlı 1.90.3'e karşı yeniden çalıştırıldı (264 ayrıntı); testler güncel örneklerle geçiyor.
- Kaynak commit `28f751ed` sitede yok → `a866b86`.
- `KoleksiyonKurallari.degistir` listeyi süzüyordu, site süzmüyor; düzeltildi. Kâhine eski, eksik alanlı kayıtla başlangıç durumu eklendi (eski kod bu durumda kalırdı).
- Kâhindeki Mac masaüstü yolu kaldırıldı.
- CI görüntüsü eklendi: `-ekran goruntuleyici` → `9-goruntuleyici.png` (ayrıntı noktası olan ilk eser).
- G2'ye kalan: görseller hâlâ `AsyncImage`; T3'ün `UzakGorsel` / `GorselDeposu`'na geçilmeli (önbellek, küçültme).

### C1 · Pekiştirme oturumu (ChatGPT)
**Site kaynakları:**
- `js/oturum.js`, `js/celdirici.js`, `js/ters.js`, `js/turlar.js`, `js/soruTurlari.js`, `js/devam.js`, `js/titresim.js`
- `js/ekranlar/pekistir.js`, `js/ekranlar/soruTurlari.js`

**Yapılacaklar:**
- Kart seçimi, zor yanlış seçenekler, aynı oturumda geri dönen yanlışlar.
- Bütün tur türleri: karışık, dönem, konu, bölüm, hatalar.
- Cevap yaprağı.
- Yarım oturumu sürdürme.
- Sonuçlar `IlerlemeKoprusu` ile yazılır.
- İki oturum önerilir: **C1a** mantık + kâhin, **C1b** ekranlar.

**Devir notu:** ChatGPT, 2026-11-21 — C1a, PR #7 (`is/C1a-pekistir-mantik`).
- Kaynak: `sanat-atlasi` @ `a866b86`; `js/oturum.js`, `celdirici.js`, `turlar.js`, `bolum.js`, `eserler.js`, `ters.js`, `soruTurlari.js`, `ekranlar/{pekistir,soruTurlari}.js`.
- `TurPlani.kur` karışık, dönem, konu, harita bölümü ve hatalar turlarını kurar. `PekistirmeKarti.hazirla` eser, zorluk ve seçenekleri seçer. `PekistirmeOturumu.cevapla` tamamlanan kartın T2 skor, seviye, günlük ve geçmiş değişikliklerini birlikte uygular. Yanlış kart başına en çok üç geri dönüş vardır. Ek kurs bölümü ve ikonografi sorularının ayrı skorları `SoruTuru` içindedir.
- Yedi yeni XCTest geçti. Sabit kaynak sürümünün JS modülleriyle üretilen cevaplar `Ornekler/pekistir/cevaplar.json` içinde. Çevrimdışı üretim: `node Testler/kahin/pekistir.mjs /tmp/sa`. Canlı tarayıcı karşılaştırması: **kâhin denetçide** (yerelde Playwright paketi yok).
- C1b: kart cevap yaprağı, yarım oturumun saklanması/sürdürülmesi ve köprüye yazma. Köprü yeniden denerse oturum kopyasına aynı cevabı uygula; yalnız başarılı yazmadan sonra ekranın oturumunu ilerlet. Telefonda yeni deneme adımı C1b ekranıyla gelecek.

**Denetim (C1a):** Claude, 2026-11-21 — **onay** (PR #7 yorumu).
- `pekistir.mjs` canlı sitede çalıştırıldı, cevaplar örneklerle aynı. Site a866b86'dan beri bu dosyalarda değişmedi.
- Kurallar sitenin kaynağıyla satır satır karşılaştırıldı.
- Eklenen uçtan uca kâhin `pekistir_turlari.mjs` → `PekistirTurlariTests`:
  - Gerçek katalog, 60 rastgele ilerleme, altı tur türü, 510 kart.
  - Tur planı, eser, şıklar, akım şıkları, ters soru, tekrar kuyruğu, rastgele sayıların sırası ve sayısı, ilerlemenin yedi alanı sitenin yaptığıyla aynı.
  - Rastgelelik sitenin `rastgeleYap`'ı; Swift'e `SiteRastgelesi` olarak test içinde taşındı.
- Düzeltme: `konu` kapanışı artık `(eser, sanatçıId)` alıyor. Sitede QID'si olmayan eserin konusu `sanatçıId|başlık` ile bulunuyor; eski imzayla bulunamazdı.
- `pekistir.mjs` Playwright'ı diğer kâhinler gibi `createRequire` ile yüklüyor.
- C1b için notlar:
  - `cevapla(seciliSeviye:)` ekranda seçilen alt seviyedir, kartın seviyesi değil. Alt seviye seçilmediyse `nil` verilir.
  - Kart sitedeki gibi cevaptan önce hazırlanmalı. `hazirla` `sonEserler`'i ilerlemeye yazar.
  - `SoruTuru` (kurs bölümü ve ikonografi turları) yalnız okuyarak karşılaştırıldı. C1b ekranlarıyla birlikte kâhine eklenmeli.

**Devir notu (C1b):** ChatGPT, 2026-11-21 · PR #9 · `is/C1b-pekistir-ekran`.
- Kaynak: `sanat-atlasi` @ `a866b86`, `js/{oturum,devam,soruTurlari,titresim}.js` ve `js/ekranlar/{pekistir,soruTurlari}.js`.
- C2 ve G5, `PekistirmeEkrani(ilkTur:)` ile ilgili turu açabilir. Çalış sekmesi C2 ve C3 tamamlanana kadar siteyi gösterir. DEBUG denemesi: `-ekran pekistir`.
- Kart, ters soru, sanatçı ve akım cevap yaprakları, tur özeti ve yedi gün içinde yarım tura dönüş eklendi. Kart C1a ile cevaptan önce hazırlanır. Seçilen alt seviye yoksa `nil` iletilir. Skorlar, tekrar kuyruğu ve görünen kartın cevap adımı aynı `IlerlemeKoprusu.degistir` çağrısında yazılır. Yerli oturum `ayarlar.noraPekistirmeOturumu` alanında tutulur. Web’in IndexedDB’deki yarım turu ayrı kalır.
- CI #45'te çekirdek, köprü, iOS derleme ve simülatör adımları geçti. `10-pekistirme.png` (G1'den sonra yeniden numaralandı) incelendi: gerçek eser, kart sayacı, dört sanatçı ve Bilmiyorum düğmesi görünür. Klasörler dışındaki bağlantılar DEBUG açılışı, CI ve bu devir notudur.
- Kâhin: `a866b86` sürümünün JS modülleriyle kurs bölümü ve ikonografi şıkları, aday sırası, yanlış skor ve devam kuyruğu üretildi. `PekistirmeKaydiTests` (paket testlerinde) bunları ve iki sorunun arasında/cevap yaprağında kapatıp sürdürmeyi karşılaştırır.
- Telefonda: karışık turda Bilmiyorum'a dokun, akım sorusunda uygulamayı kapat, yeniden açıp sürdür. Eser ve şıklar korunmalı; tur sonunda kart bir kez sayılmalı.

**Denetim (C1b):** Claude, 2026-11-21 — **onay, eksikler C1c'ye** (PR #9 yorumu).
- Paket testleri geçti (65).
- `pekistir_ek.mjs` sitenin a866b86 modülleriyle çalıştırıldı, testteki değerlerle aynı.
- Akış C1a API'sini doğru kullanıyor: iki aşamalı karışık kart (skor akım cevabından sonra tek yazmada), ters kart, Bilmiyorum, ek turlar, yarım tur.
- `ayarlar.noraPekistirmeOturumu` güvenli: site bilinmeyen ayarları korur (`js/depo.js` `ilerlemeDogrula`: `{ ...t.ayarlar, ...v.ayarlar }`).
- Düzeltmeler:
  - Test dosyası uygulama klasöründen paket testlerine taşındı. CI'daki kopyalama ve `-DPEKISTIRME_TESTI` kaldırıldı; artık Linux'ta da çalışıyor.
  - Kâhin paket kaynaklarından `Testler/kahin/pekistir_ek.mjs`'e taşındı.
  - CI görüntüsü G1'den sonra 10 numara oldu.
- **Eksik (sitenin `js/ekranlar/pekistir.js` akışına göre) → C1c.** Ekran yalnız DEBUG'da açıldığı için telefonda etkisi yok, ama Çalış yerli olmadan önce tamamlanmalı.

### C1c · Pekiştirme: tanışma ve eksik adımlar (ChatGPT)
**Site kaynakları:** `js/ekranlar/pekistir.js` (`kartCiz`, `tanismaGoster`, `konuTanismaGoster`, `tanismaCiz`, `baskaEser`, `ipucuMetni`, `karsiSeritHtml`, `seviyeTamamHtml`, `seviyeHaplari`, `ozetCiz`, `sergiyeEkle`), `js/ogrenme.js` (`tanismaGerekirMi`, `tanismaEserleri`).

**Yapılacaklar** (C1b'nin ekranına, aynı klasörlerde):
- **Tanışma.**
  - Karışık, dönem ve hatalar turunda yeni sanatçının (`tanismaGerekirMi`) kartından önce "Yeni sanatçı · önce tanış" ekranı.
  - Tanışmada üç eser gösterilir (`tanismaEserleri`); bu eserler o turda sorulmaz (`PekistirmeKarti.hazirla(tanismadaGorulen:)`).
  - Konu turunda `plan.tanisma` arka arkaya, turdan önce.
  - `ayarlar.tanisma == false` ise tanışma yok.
- **Başka eser** düğmesi (`baskaEser`).
- **Cevap yaprağı.**
  - İpucu ("Nasıl tanırım?", `tanima_notlari.json`).
  - Karıştırılan ikili şeridi (`karsiSeritHtml`).
- **Seviye.**
  - Dönem turunda alt seviye seçimi (`seviyeHaplari`).
  - Seviye atlayınca gösterim (`seviyeTamamHtml`).
- **Tur özeti.** Sitedeki gibi: oran, sergi, geçilen seviyeler.
- **Sayaç.** Eseri bulunamayan kart sitede `ilerle` ile atlanır ve sayaçta kalır; `simdikiniAtla` kartı kuyruktan siliyor. Sayaç sitedeki gibi olmalı.
- **Görünüş (K5).** Kart ve cevap yaprağı sitenin kartına benzesin: tipografi, kart çerçevesi, şık düğmeleri, ilerleme çubuğu. CI'da aynı turun sitedeki görüntüsüyle yan yana karşılaştır.
- Kâhin: tanışma eserleri ve `tanismadaGorulen` ile kart seçimi `pekistir_turlari.mjs` kalıbıyla.

**Devir notu:** Claude, 2026-11-21 · PR #14 · dal `claude/affectionate-bell-ognrcy` (oturumun zorunlu dalı). C şeridinin işi; kullanıcı Claude'a verdi. Aynı anda C4b başka bir Claude oturumunda sürdüğü için `Ekranlar/Ben/` ve `Gecis.swift`'e dokunulmadı.
- **Kaynak:** sanat-atlasi `a866b86` (site 1.90.3; bu dosyalar o günden beri değişmedi). Taşınan: `js/ekranlar/pekistir.js` (`kartCiz`, `tanismaGoster`, `konuTanismaGoster`, `tanismaCiz`, `tanismaVitrin`, `gecDugme`, `baskaEser`, `ipucuMetni`, `akimiAciklarMi`, `karsiSeritHtml`, `kutuSatiri`, `seviyeSatiri`, `seviyeHaplari`, `seviyeSec`, `ozetCiz`, `gecenlerHtml`, `eylemKarti`, `kartGoster`, `tersGoster`, `kartpostalAc`), `js/ogrenme.js` (`tanismaGerekirMi`, `tanismaEserleri`), `js/bolum.js` (`bolumEserleri`), `js/karsilastir.js` (`notlariAl`, `taninmaMetni`). Görünüş: `css/app.css` (`.soru-ust`, `.ince-cubuk.parcali`, `.soru-sahne`, `.soru-isik`, `.hale-nefes`, `.secenek`, `.alt-yaprak`, `.tanisma*`, `.gec-*`); ölçüler sitenin hesaplanmış stillerinden (Playwright, iPhone 15 Pro).
  K7 farkı: `git -C /tmp/sa log a866b86..HEAD -- js/ekranlar/pekistir.js js/ogrenme.js js/bolum.js js/karsilastir.js css/app.css`
- **Çekirdek** (`NoraCekirdek/Pekistir/`):
  - `TurKaydi`: kart tanışması (karışık, dönem, hatalar; `ayarlar.tanisma === false` ise yok), konu turunun turdan önceki tanışmaları (`tanisma`, `tanismaGec`, `tanismaGeri`); gösterilenler o turda sorulmaz (`tanismaGorulen` → `PekistirmeKarti.hazirla(tanismadaGorulen:)`). Bölüm turu için de tanışma eserleri seçiliyor (`bolumEserleri`), ama bölüm işaretleri (`tanitimGoruldu`, grup) G5'e kaldı.
  - `baskaEser` (en çok dört kez), `seviyeHaplari` / `seviyeSec`, kart başına `seviye`, `karisan`, `seviyeSonucu`, `akimCevabi`; turda `gecenler`, `sonResim`, `gorunenKonum` (cevaptan sonra sayaç aynı kartta kalır), `bitti`.
  - **Sayaç:** eseri bulunamayan kart artık kuyruktan silinmiyor; site gibi atlanıp sayaçta kalıyor (`simdikiniAtla`).
  - Yeni alanların hepsi isteğe bağlı: C1b'nin sakladığı yarım tur çözülüyor (`testEskiKayitCozulur`).
  - `PekistirmeVerileri`: `tanima_notlari.json`, `ipucu` (`ipucuMetni`), `konu`, `kolaylikFn`. `CevapYazilari`: yaprak, tanışma ve özet metinleri.
- **Ekran** (`Ekranlar/Calis/Pekistir/`):
  - `TanismaGorunumu`: kartela, vitrin + şerit, görüntüleyici, Nasıl tanırım?, ileri düğmesi; konu turunda çentikler ve geri.
  - `KartGorunumu`: üst satır, parçalı çubuk, seviye hapları, eserin ışığı ve hale, harfli şıklar, Bilmiyorum, görsel açılmazsa başka eser. Ters soru: levha, kartpostallar, büyük görünümde "Bu eser". Cevap yaprağı: sonuç, bilgi, ipucu (Devamı/Kısalt), karıştırılan ikili şeridi, Karşılaştır, Ayrıntılar (tekrar kutusu, seviye, kaynak), Sanatçı ve Sonraki.
  - Tur özeti: x / n, not, seviye atlayan dönemler, Bir tur daha, Tuval'e dön. `PekistirmeOgeleri`: ortak parçalar (`PkEtiket` vb.; C4b ile ad çakışmasın diye önekli).
- **Kâhin:** `Testler/kahin/pekistir_tanisma.mjs` → `Ornekler/pekistir/tanisma.json`: 60 durum, 464 adım (66 kart tanışması, 10 konu tanışması, 70 başka eser, atlanan kart, 19 seviye atlama, ısınma, ters). `PekistirTanismaTests` akışı `TurKaydi` ile yürütüyor: tanışma eserleri, tanışmadan sonra kart seçimi, başka eser, sayaç ve kuyruk, karıştırma sayısı, seviye sonucu, gecenler, rastgele sayıların sayısı, ilerlemenin yedi alanı sitenin yaptığıyla aynı. Kural bilerek bozulunca yakalıyor (`tanismaGorulen` verilmezse 17 kartta, eski `simdikiniAtla` ile atlanan kartta). Linux'ta 80 test geçiyor.
- **Bilinçli farklar / kalan:**
  - Karışık kartta site seviye ve karıştırma sayısını birinci soruda yazar; burada (C1a'dan beri) kart bitince tek yazmada gider, yaprak için önceden hesaplanır. Sonuç aynı.
  - Tanışmadaki "Dinle" (okunuş, `dinleEkle`) ve hareketler (geç animasyonu, yaldız yaprakları, sayarak yazma) yok → Z3.
  - "Sanatçı", "Karşılaştır" ve "Tuval'e dön" `Gezgin.shared.git` ile sitenin adresine gider. Çalış yerli olunca (C2) bu adresler yerli değilse pekiştirmeden çıkılmalı.
  - Bölüm turunun sergisi ve `seviyeTamamHtml` (yıldızlar, madalyon) yalnız harita bölümünde; bölüm turu henüz menüde yok → **G5**.
  - Kurs bölümü ve ikonografi turlarının yaprağı sade (sitede ayrı ekran, `js/ekranlar/soruTurlari.js`) → C2.
  - `PekistirmeEkrani` kendisi `.sekmeCubuguGizli` çağırmaz (DEBUG'da `KabukDurumu` ortamda yok). Onu yerleştiren ekran (C2), sitedeki gibi tur sürerken çubuğu gizlemeli.
- **CI:** d941528 yeşil (https://github.com/emrymn/nora-sanat/actions/runs/44883231600): çekirdek testleri, iOS derlemesi, simülatör adımları. Yeni görüntüler: `10a-pekistirme-ilk.png` (tanışma), `10-pekistirme.png` (kart), `10c-pekistirme-yaprak.png` (yanlış şıktan sonra yaprak; açılışlar arası aynı tur sürüyor, yarım tur da sınanmış oluyor), `10s-site-pekistirme.png` (aynı adreste sitenin turu). Sitenin Playwright görüntüleriyle (tanışma, kart, yaprak) yan yana bakıldı: düzen, yazı tipleri, renkler, şıklar, yaprak ve tanışma düğmesi aynı. Düzeltilen: tanışma düğmesinin halkası taşıyordu.
- **Telefonda:** README'deki C1c maddesi (`-ekran pekistir`). Çalış henüz yerli değil; telefonda değişen bir şey yok.

**Denetim (C1c):** Claude, 2026-11-21 — **onay** ([PR #14 yorumu](https://github.com/emrymn/nora-sanat/pull/14#issuecomment-7060261746)). Linux'ta 85 test geçti (main ile birlikte). `pekistir_tanisma.mjs` canlı sitede yeniden çalıştırıldı: çıktı örnekle aynı (yalnız `olusturma` zaman damgası). CI görüntülerinde tanışma, kart ve yaprak sitenin düzeninde. Küçük eksik: tanışmadaki okunuş satırı (`IPA`) da yok, "Dinle" ile birlikte Z3'te.

### G2 · Galeri (ChatGPT)
**Site kaynakları:**
- `js/ekranlar/gozat.js`, `js/ekranlar/akim.js` + `js/akim.js`, `js/ekranlar/arama.js` + `js/arama.js`
- `js/ekranlar/koleksiyon.js`
- `js/ikonografi.js`, `js/tanimaKirpim.js`, `js/temsil.js`, `js/harfler.js`, `js/cerceve.js`, `js/kunye.js`, `js/imza.js`, `js/tasarim.js`

**Kapsam:**
- Akım çarkı ve akım sayfası.
- Sanatçı sayfası ve eser ızgarası.
- Konular ve ikonografi.
- Arama ve Koleksiyonum.

**Devir notu:** ChatGPT, 2026-11-21 — [PR #11](https://github.com/emrymn/nora-sanat/pull/11), dal `is/G2-galeri`.
- Kaynak: `sanat-atlasi` @ `a866b86`, `js/ekranlar/{gozat,akim,arama,koleksiyon}.js`, `js/{akim,arama,ikonografi,temsil,birlesme,basyapit,cerceve,tasarim,kunye,imza,tanimaKirpim}.js`.
- Galeri, T1 kataloğundan akımlar çarkını, salonları, sanatçı künyesini, eser ızgarasını, ikonografi konularını, dört gruplu aramayı ve koleksiyon duvarını kurar. Kilit ve koleksiyon T2 köprüsünden okunur. Görüntüleyici kapanınca kalpteki değişiklik duvara yansır. G1 ana görseli, yedeği, keskin kopyayı ve arka ışığı T3 görsel çözücüsünden alır.
- Kâhin: `node Testler/kahin/galeri.mjs <site-deposu>`; argümansız çalıştırıldığında Playwright ile canlı siteyi kullanır. `GaleriTests` aynı katalogda arama gruplarını, sıraları, birleşen akım bilgisini, kapakları, dörtlüleri, konuları ve eser eşleşmelerini denetler.
- Telefonda Debug: `-yerliSekme galeri -adres "#/gozat"`. Çarkı kaydır, açık salonda sanatçıya gir, ikinci eseri açıp kalbe dokun. Koleksiyonum'da aynı eseri açıp kalbi kaldır ve duvara dön. Aramada Türkçe ve özgün eser adını dene. CI: `-galeriSayfa "#/gozat"` ile gerçek yerli kabukta `galeri.png`; OCR açık salonun giriş düğmesini doğrular, `4-url-calis` son görüntüdür.
- G3 için: Galeri’nin tamamını etkinleştirme kararı G3 sonunda. Başyapıt arama sonucu yakın okuma içeriğine bağlanır. G3 kendi liste ve yakın okuma ekranlarını getirince bu hedef ortaklaştırılabilir. Galeri üst şeridindeki Başyapıtlar ve Zaman, G3/G5 bağlanana kadar sitenin okuma sayfasını açar.

**Denetim (G2):** Claude, 2026-11-21 — **davranış onay; görünüş G2b'ye** ([PR #11 yorumu](https://github.com/emrymn/nora-sanat/pull/11#issuecomment-7060261876)). `swift test` geçti. `galeri.mjs` hem site deposuyla hem canlı sitede çalıştırıldı: çıktı örnekle birebir aynı (canlı kip `playwright-core` arıyordu, `playwright` yapıldı). Görünüş sitedekinden belirgin farklı (çark kartı, yazılar, salon/konu/sanatçı sayfaları çoğunlukla iOS listeleri; CI'da yalnız çark görüntüsü). Galeri yerli olmadığı için telefonda değişen yok. GaleriKatalogu'ndaki temsil kopyaları G2b'de `Temsil.swift`'e geçmeli.

### G2b · Galeri: görünüş sitedeki gibi (ChatGPT şeridi; kullanıcının isteğiyle Claude)
**Site kaynakları:** `js/ekranlar/{gozat,akim,arama,koleksiyon,ortak,bugun}.js`, `css/app.css` (Galeri bölümleri), sitede `TASARIM_DILI.md`.

**Yapılacaklar:** G2'nin ekranları (`NoraSanat/Ekranlar/Galeri/`) sitenin sayfalarına benzesin (PR #11 denetimi). Ölçüler hesaplanmış stillerden; CI'da her ekran için site (`-yalnizSite`) ve yerli yan yana. Ben'in ortak parçaları yeniden kullanılır; temsil kuralları `NoraCekirdek/SiteVerisi/Temsil.swift`'ten.

**Devir notu:** Claude, 2026-11-21 · [PR #15](https://github.com/emrymn/nora-sanat/pull/15) · dal `claude/great-darwin-3hounp` (oturumun zorunlu dalı). G şeridi işi; kullanıcının isteğiyle Claude yaptı.
- **Kaynak:** sanat-atlasi `a866b86` (site 1.90.3). Taşınanlar:
  - `js/ekranlar/gozat.js`: `gozAtUst`, `gozAt`, `carkHtml`, `carkKur`, `onizlemeleriDoldur`, `akimSayfasi`, `sanatciSatiri`, `sanatciSayfasi`, `tumEserler`, `basyapitBaglariniDoldur`, `karsilastirSecici`, `karsilastirmaSutunu`, `karsilastirSayfasi`, `konularCiz`, `knGovdeCiz`, `knSahne`, `knKart`, `hepsineBak`, `bsySahneBagla`, `konuSayfasi`, `konuSahnesiniDoldur`, `metniKatla`, `konuGalerisiAc`
  - `js/ekranlar/akim.js`: `kimlikDoldur`, `bolumBasligi`, `tanimaNotlari`, `eserIzgarasi`, `pekistirDugmesi`, `dugmeBilgisi`, `donemHikayesi`, `konuDizini`, `akimKarsilastirSayfasi`, `USLUPLAR`, `TEKNIKLER`; `js/akim.js` `DORTLU_SECIMI`, `enBilinenEserler`
  - `js/ekranlar/arama.js`, `js/ekranlar/koleksiyon.js` (üst), `js/ekranlar/bugun.js` (`seritUst`, `eserSeridi`, `notBolumleri`, `donemCizelgesi`), `js/ekranlar/ortak.js` (`sayfaZemini`, `ust`, `akimRenk`, `isimHtml`), `js/kunye.js`, `js/imza.js`, `js/temsil.js` (`AKIM_KAPAK`), `js/ikonografi.js` (`kapakSec`), `js/harita.js` (`BOLGELER`), `js/yardimci.js` (`bulunmaEki`), `js/tasarim.js` (`YOLLAR`)
  - `css/app.css`: `.gz-ust`, `.arama-hapi`, `.arama-kalp`, `.bolumler`, `.hale`, `.bsy-hale`, `.bsy-desen` (+ `--desen` SVG'leri), `.cark*`, `.zaman-kart`, `.akim-dizin*`, `.akim-sahne*`, `.akim-bolum*`, `.akim-hikaye*`, `.akim-ipucu*`, `.akim-eser*`, `.donem-dugme*`, `.donem`, `.akim-komsu*`, `.akim-konu-dizin`, `.akim-karsi*`, `.sanatci-ust`, `.isim-blok`, `.ad-*`, `.portre-arka`, `.imza`, `.dinle`, `.ipa`, `.serit-ust`, `.eserler`, `.eser`, `.tumu`, `.izgara`, `.bolum`, `.satir`, `.kucuk-kare`, `.basyapit-bag`, `.karsilastir-sec`, `.kars*`, `.by-*`, `.konu-*`, `.arama-alan`, `.arama-ipucu`
  - Ölçüler canlı sitenin hesaplanmış stillerinden (Playwright, iPhone 15 Pro 393 pt, Gece; `getComputedStyle` + `getBoundingClientRect`).
  K7 farkı: `git -C /tmp/sa log a866b86..HEAD -- js/ekranlar/gozat.js js/ekranlar/akim.js js/akim.js js/ekranlar/arama.js js/ekranlar/koleksiyon.js js/ekranlar/bugun.js js/ekranlar/ortak.js js/kunye.js js/imza.js js/temsil.js js/ikonografi.js js/harita.js css/app.css`
- **Çekirdek:**
  - `SiteVerisi/Temsil.swift`: `akimKapak` (`AKIM_KAPAK`), `dortluSecimi` (`DORTLU_SECIMI`), `kapakSec`, `enBilinenEserler`. `GaleriKatalogu`'ndaki satır içi kopyalar (`temsil`, Gotik QID'i, Puvis seçimi) kalktı: `konuKapagi` → `Temsil.kapakSec`, `carkKapagi` → `Temsil.akimKapak` + `Temsil.enBilinen`, `dortlu` → `enBilinenler` (sanatçısıyla birlikte; "sanatçıId|başlık" anahtarı da tanınır, sıralama kararlı).
  - Tuzak: sitenin `kapakSec`'inde "eşitlikte kurs eseri öne" koşulu hiç tutmuyor (`onbellekEseri` nesnelerinde `kurs` alanı yok). Swift de uygulamıyor; `galeri.mjs` kapakları bunu doğruladı (bir konu farklı çıkıyordu).
  - `SiteYazisi.bulunmaEki` ("Konu 3'te açılır"; G2 "işlenince açılır" yazıyordu). Testler: `testBulunmaEkiSitedekiyle` (sitenin modülünden 20 değer), `testKapakSec`. Linux'ta 88 test (1 atlanan).
- **Ekranlar** (`NoraSanat/Ekranlar/Galeri/`):
  - `GaleriGorunusu.swift`: `GaleriSimge`/`GaleriIkon` (sitenin SVG'leri), `SayfaZemini` (hale + dönem deseni), `GaleriUst` + `BolumHaplari`, `GaleriSayfaUst` (`.ust`), `SanatciUst`, `VurguEtiket`, `GaleriSatir` (`.satir`), `Rozet`, `GaleriListe`, `EserKarti`, `DonemCizelgesi`, `GaleriBolum`, `OkumaMetni`; kenardan kaydırarak geri (gizli gezinme çubuğunda da).
  - `Desenler/desen-<dönem>@3x.png`: `css/app.css` `--desen` SVG'lerinden 288 px karolar (Playwright'la çizildi); `--ink` %4 ile döşenir.
  - `GaleriAna.swift`: kemerli kartların yatay şeridi (210 × 269.7, 22 aralık; komşu `translateY(30k) scale(1 − 0.2k)`, kemer opaklığı 1 − 0.55k, yazı 1 − 1.6k), "Işık" çarkı (yarıçap 700, 12°, 2°'de bir çentik, dönen adlar, ışıklı nokta, 01 / 28), parmakla çevirme ve dokunma, "Bütün akımlar" dizini.
  - `AkimSalonu.swift`: sahne, künye, dönemin hikâyesi, mercekli "Nasıl tanınır?", en bilinen eserler, ustalar, "Bu dönemi pekiştir" kartı, dönem, "Yan yana koy", tipik konular; üsluba göre bölüm başlıkları (Orta Çağ altın baş harf, Rönesans ortalı, Barok…). `AkimKarsilastir`.
  - `SanatciKunyesi.swift` (yeniden): büyük ad, tam ad, silik portre, altın imza (maske), Dinle ve IPA, yıllar · kurs, seviye satırı. `SanatciSayfasi.swift`: sanatçı, `EserSeridi`, `TumEserler` (`IkiSutunDuvar`), `SanatciKarsilastir`.
  - `KonuSayfalari.swift`: `KonularSayfasi` (yapışkan grup sekmeleri, öne çıkanlar kartı 6 sn'de bir döner, şeritler, "Hepsine bak"), `KonuSayfasi` (sahne, başlık, özet, katlanan hikâye, tanıma kartları ve kırpımlar, duraklar, "Bütün resimler" yaprağı).
  - `AramaKoleksiyon.swift`: arama (altı çizili Bodoni alan, dört grup, en çok 8, "ve n sonuç daha"), Koleksiyonum (G2'nin duvarı yeni üstle).
  - `GaleriSekmesi.swift`: gezinme çubuğu her sayfada gizli; sayfalar `GaleriEylemleri` ve `GaleriResim` ile kuruluyor. `GaleriCarki.swift` silindi.
  - Karşılaştırma sayfaları sitedeki gibi sekmesiz (`.sekmeCubuguGizli`).
- **Ortak dosyalarda küçük değişiklik:** `NoraSanatApp.swift` (DEBUG): `GaleriKarsilastirma.siteyiKaydir()`.
- **CI karşılaştırması:** yerli `-yerliSekme galeri -adres "#/gozat" -galeriSayfa <adres> [-galeriKaydir dizin|eserler|pekistir]`, site `-yalnizSite -adres <adres> [-galeriKaydir …]`. Yerli ekran hazır olunca `tmp/galeri-hazir` yazar. Görüntüler: `galeri-<ad>.png`, `site-galeri-<ad>.png`, `galeri-yan-yana-<ad>.png` (solda site): ana, ana-dizin, akim, akim-eserler, akim-pekistir, sanatci, eserler, konular, konu, ara, koleksiyon, karsilastir, akim-karsilastir. Eski `galeri.png` adımı bunun içinde (ana ekranda "Salona gir" OCR'ı).
- **CI:** a36f435 yeşil (https://github.com/emrymn/nora-sanat/actions/runs/44894994139). İlk koşu derlemede kaldı (çark tek kapanışta tür denetimi süresini aşıyordu → küçük açık türlü parçalar). `galeri-yan-yana-*.png` on üçüne de bakıldı: Galeri üstü, kemerli kart, akım salonu (sahne, hikâye, eserler, pekiştir kartı, dönem), sanatçı, tüm eserler, konular, konu, arama, koleksiyon ve iki karşılaştırma sitedekiyle aynı düzen, yazı tipi ve renklerde. Sonra düzeltilen: çark ~40 pt yukarıdaydı (sitede öğe 479.9), dönen adlar yayın üstüne oturmuyordu; dizinde kilitli satırlar fazla soluktu; akım karşılaştırmada maddeler numarasızdı; konu sahnesi kısaydı (`min(62vh, 520)`), özetin “ işareti yoktu.
  - 5743b49 yeşil (https://github.com/emrymn/nora-sanat/actions/runs/44897472471): çark ve dönen adlar, konu sahnesi ve “ işareti sitedekiyle aynı yerde. Bu koşuda yerli `galeri-ana.png`'nin üstünde arkadaki gizli sitenin "Harekete ve Yöne Erişmek İstiyor" penceresi çıktı (WKWebView'in izin isteği, G2b'nin değil; önceki koşuda yoktu). Galeri yerli olunca site arkada bu izni istememeli → G3 / Z2.
- **Bilinen farklar / kalan:**
  - Tüm eserler duvarında sıra farklı: sitede CSS `columns` (sütun sütun akar), burada kısa olan sütuna.
  - Akımın kendi yazı tipi (`harfUygula`, ör. Gotik'te Grenze Gotisch) yok; başlık Bodoni.
  - Akım paleti (`eserPaleti`, eser görsellerinden renk) ve sanatçı/konu sayfasının eserden gelen rengi (`ekranRengi`) yok; hale `--vurgu` ile.
  - "Bu dönemi pekiştir" sahnesindeki dönem tekniği gösterisi (mozaik, vitray… parçaları) yok; yalnız eser kemerde. Dada'nın kesik harfleri yok.
  - Giriş hareketleri (`data-gozcu` belirmeleri, desen geçişi dışında), çark önizlemelerindeki üç küçük çerçeve (sitede de gizli) yok.
  - Başyapıtlar ve Zaman G3 / G5'e kadar sitenin sayfasını yaprakta açar; yakın okuma (`#/basyapit/…`) sade yerli sayfa.
  - Koleksiyon duvarının asılı tablo görünüşü G2'deki gibi (sitenin `.asi-cerceve` çerçeveleri yaklaşık).
- **Tuzaklar:**
  - Gezinme çubuğu gizli: geri hareketi için `UINavigationController` jest temsilcisi (GaleriGorunusu.swift sonu) bütün uygulamada geçerli.
  - Çark: şeridin konumu `PreferenceKey` ile okunur; çark çevrilirken konum parmaktan gelir ve şerit en yakın akıma kayarak izler.
  - Ben'de de `EserDuvari` var; Galeri'ninki `IkiSutunDuvar`.

**Denetim (G2b):** Claude, 2026-11-21 — **onay** ([PR #15 yorumu](https://github.com/emrymn/nora-sanat/pull/15#issuecomment-7067177100)). 88 test geçti; `galeri.mjs` ve `temsil.mjs` canlı sitede örneklerle aynı. 13 yan yana görüntünün hepsi sitenin düzeninde. Küçük: sanatçıda "Notlarımdan" etiketi altın (sitede gri); `UINavigationController` eklentisi bütün uygulamayı etkiliyor (Z3). Yan bulgu: gizli site hareket izni penceresi açabiliyor (`WebKabugu` temsilcisi `.grant` dönmesine rağmen) → ayrı iş.

### C2 · Çalış ana ekranı (ChatGPT)
**Site kaynakları:** `js/ekranlar/calisma.js`, `js/deste.js`.

**Kapsam:** Bugünün dersi kartı, günlük tekrar, başka turlar, 14 günlük yük grafiği.

**Devir notu:** Gemini, 2026-11-21 · [PR #16](https://github.com/emrymn/nora-sanat/pull/16) · dal `is/C2-calis`. Gemini'nin hakkı bitince notu ve CI düzeltmesini denetçi Claude yazdı (2026-11-22).
- **Kaynak:** sanat-atlasi `a866b86`: `js/ekranlar/{ders,pekistir,soruTurlari,calisma,gozat,bugun}.js`, `js/{ders,dersIcerik,bolum,oturum,soruTurlari,ikonografi,gecmis,deste,sallanma,egim}.js`, `css/app.css` (`.ders-*`, `.calis-*`, `.tur-izgara`, `.pk-*`, `.salon`, `.hedef-sec`).
- **Çekirdek** (`NoraCekirdek/Calis/`): `CalisKurallari` (tur önizlemesi `turOzeti`, soru turları, 14 günlük yük, konum yazısı), `CalisDersKurallari` (ders planı, Gör → Öğren → Ayırt et adımları, harita bölümleri), `DesteFizigi` (destenin yaylı sarkacı ve eğim). Kâhin `Testler/kahin/calis.mjs` → `Ornekler/calis/cevaplar.json` (+ `ders_kaynaklari.json`); `CalisTests` (94 test, Linux).
- **Ekranlar** (`Ekranlar/Calis/`): `CalisSekmesi` (ana / Turlar / ders alt sayfaları, adresle açılış, tur sürerken `.sekmeCubuguGizli`), `CalisAnaGorunumu` (bugünün dersi kartı, günlük tekrar, Çalışma masan: Dersler / Başka turlar, kilitli dersler, harita satırı, 14 gün), `DonemTurlariGorunumu` (bugünkü tur destesi, günlük hedef, yarım kalan tur, döneme göre salonlar), `CalisDersSayfasi`. `PekistirmeEkrani` dışarıdan model ve `disAdreseGit` alıyor (C1c'nin C2 maddeleri).
- **CI:** `-yerliSekme calis,ben -adres "#/pekistir" [-calisSayfa donem] [-calisKaydir turlar|yuk|salon]`, hazır olunca `tmp/calis-hazir`; `yan-yana-calis-*.png` (solda site). Kâhin yalnız bu dalda canlı sitede koşar (libm farkı için 11 haneye yuvarlanır).
- **Kalan:** Dersin adımları (Gör, Öğren, Ayırt et ekranları) hâlâ sitenin sayfasını açar → **C3**. Çalış C3 bitince yerli olur. Yerli "Yarım kalan tur" kartı uygulamanın kendi kaydından (`noraPekistirmeOturumu`) gelir; site bu kaydı bilmediği için sitedeki ekranda görünmez.

**Denetim (C2):** Claude, 2026-11-22 — **onay** ([PR #16 yorumu](https://github.com/emrymn/nora-sanat/pull/16)). 94 test geçti; `calis.mjs` canlı sitede yeniden çalıştırıldı, cevaplar örnekle aynı. Yan yana görüntülerde Çalış ana ekranı, Başka turlar ve 14 gün sitenin düzeninde; yerli ekran biraz daha iri (Z3). CI kırmızıydı: Turlar ekranında OCR başlığı resmin üstünde okuyamıyordu ("Turu başlat" aranıyor). Gemini'nin Galeri görüntülerini bu dalda atlatan koşulu kaldırıldı.

### G3 · Başyapıtlar (ChatGPT şeridi; kullanıcının isteğiyle Claude)
**Site kaynakları:** `js/basyapit.js`, `js/basyapitSayfa.js`, `js/ekranlar/basyapit.js`.

**Kapsam:** Liste (dönem sekmeleri), yakın okuma sayfası, yan yana karşılaştırma.

**Devir notu:** Claude, 2026-11-21 · [PR #19](https://github.com/emrymn/nora-sanat/pull/19) · dal `claude/happy-keller-hfidv4` (oturumun zorunlu dalı). G2b (#15) birleşti; main ile birleştirildi. Aynı anda C2 başka oturumda sürdüğü için `Ekranlar/Calis/`'e dokunulmadı.
- **Kaynak:** sanat-atlasi `a866b86` (site 1.90.3). Taşınanlar:
  - `js/basyapit.js`: `basyapitlariAl`, `basyapitBul`, `sanatcininBasyapitlari`, `eserEslestir`, `oneCikanlar`, `gorunenBaslik`
  - `js/basyapitSayfa.js`: hepsi (`sade`, `noktalariYerlestir`, `kirpim`, `sozlukAl`, `kunyeSatirlari`, `karsilastirmalariAl`, `terimIsaretle`, `dersBolumleri`, `okumaDakikasi`)
  - `js/ekranlar/basyapit.js`: `basyapitSayfasi`, `ayrintiHtml`, `kunyeHtml`, `yanYanaAc`, `dersiBagla`, `basyapitDersSayfasi`
  - `js/ekranlar/gozat.js`: `basyapitVeri`, `basyapitAdresi`, `basyapitListesi`, `bsyGruplari`, `bsyGovdeCiz`, `bsySahne`, `bsyKart`, `bsySahneBagla`, `eserRozetleri`
  - `js/eserDersi.js`: `yayinAl`, `dersKlasoru`, `dersDurumu`, `dersGorunurMu`, `dersYolu`, `temizle`, `satirIci`, `mdHtml`; `js/ekranlar/eserDersi.js` `dersinDurumu`; `js/hikaye.js` `hikayeHtml`; `js/harita.js` `BOLGELER`; `js/temsil.js` `temsilOlabilir`
  - `css/app.css`: `.by-*`, `.bsy*`, `.hikaye-bolum`, `.eser-rozet*`, `.vitrin-akim`, `.serit-son`. Ölçüler canlı sitenin **hesaplanmış** stillerinden (Playwright, iPhone 15 Pro, Gece).
  K7 farkı: `git -C /tmp/sa log a866b86..HEAD -- js/basyapit.js js/basyapitSayfa.js js/ekranlar/basyapit.js js/ekranlar/gozat.js js/eserDersi.js js/hikaye.js css/app.css`
- **Çekirdek** (`NoraCekirdek/Basyapit/`):
  - `Basyapit.swift`: `Basyapit` (`gorunenBaslik`, `ozgunSatiri`, `adres`), `BasyapitKurallari` (`al` = `basyapitlariAl` + temsil dışı eleme, `bul`, `sanatcinin`, `eser`, `sonraki`, `oneCikanlar`, `gruplar`), `Donem` (`BOLGELER`, `bolgeBul`).
  - `BasyapitSayfasi.swift`: sayfanın saf yardımcıları ve `metinler` (sitenin `terimleriIsle` sırası: bölüm metni, o bölümün tek ayrıntısının açıklaması, sonra ayrıntılı anlatım).
  - `EserDersi.swift`: `DersYayini` (kapı), `DersMetni.temizle`, `satirIci`, `mdHtml`. C3 (eser dersleri) de kullanabilir.
  - `MetinBloklari.swift`: sitenin ürettiği HTML'i (kaçırılmış metin, `mdHtml`, `terimIsaretle`) ekran için bloklara çevirir.
  - `JSDuzen.swift`: JS düzenli ifadeleri; JS'te `\b`/`\w` ASCII'dir (Türkçe harf sözcük dışı), ICU'da Unicode. Desenlerde `⟨b⟩`, `⟨w⟩` ASCII karşılığa çevrilir.
  - `GaleriKatalogu.basyapitlar` artık `[Basyapit]` (G2'deki satır içi süzme ve "Q3947103" kalktı; `notTemizle` uygulanıyor).
- **Kâhin:** `node Testler/kahin/basyapit.mjs` (canlı site, Playwright) → `Ornekler/basyapit/` (`basyapitlar.json` ve `dersler.json` girdi, `cevaplar.json` cevap; ~5 MB). 263 başyapıt: liste, 9 dönem grubu, 210 öne çıkan durumu (3 açıklık × 7 gün × Hepsi ve her dönem), her sayfa için eser eşleşmesi, ayrıntı kaydı, ayrıntıların bölümlere yerleşimi, her noktanın 3 oranda iki kırpımı, ders durumu, künye (dersli/derssiz), sözlük, karşılaştırmalar, `temizle`, ders bölümleri, okuma dakikası, terim işaretli bütün HTML'ler (106 dersin hepsi); kenar durumları (`gorunenBaslik`, `sade`, `mdHtml`, `temizle`, `terimIsaretle`). `BasyapitTests` (6 test) bunları karşılaştırır; ayrıntı yerleşiminde kural bilerek bozulunca 445 hata. Linux'ta 94 test (1 atlanan).
- **Ekranlar** (`NoraSanat/Ekranlar/Galeri/`):
  - `BasyapitListesi.swift`: Galeri üstü (Başyapıtlar seçili), yapışkan dönem sekmeleri, `BasyapitSahnesi` (372 px, 6 sn'de bir döner, rozetler), Hepsi'de dönem şeritleri ("n eser ›", "Hepsine bak"), dönemde akım başlıkları ve `.ritim` ızgara; `bsyKart` (kilit etiketi, rozetler, akım noktası). `EserRozetleri`.
  - `YakinOkuma.swift`: kapak (kenardan kenara, %74, dik tabloda başlık 64 pt biner), kalp, başlık (akım → akım sayfası, sanatçı → sanatçı sayfası), hikâye, bölümler ve ayrıntı kırpımları (dokununca görüntüleyici o ayrıntıda), ayrıntı yoksa "Yakından bak" maddeleri, "Daha derine in" kartı ve aynı sayfada ayrıntılı anlatım, karşılaştırmalar, künye, sözlük, sıradaki, not; başlık çıkınca üst cam çubuk, altta "Yakından bak · n ayrıntı" hapı, terime dokununca sözlük kartı. `DersDeposu` (yayın ve ders dosyaları), `MetinGorunumu` (HTML blokları → `Text`; terimler `nora-terim://` bağlantısı, noktalı pirinç altı çizgi), `CamDugme`, `DoluDugme`, `OkumaBolumu`.
  - `YanYana.swift`: iki eser üst üste, cam etiketler, kapat, kart ve "Eserin sayfası".
  - `GaleriSekmesi.swift`: `GaleriYolu.basyapitlar / okuma / okumaDers` (`#/basyapitlar`, `#/basyapit/<k>`, `#/basyapit/<k>/ders`); Başyapıtlar hapı yerli listeyi, arama ve sanatçı sayfasındaki yakın okumalar yerli sayfayı açar (G2'nin geçici sade sayfası kalktı). `GaleriEylemleri.goruntule(eser, incele, nokta)`. Zaman G5'e kadar siteyi yaprakta açar. `GaleriGecisi.sekmeler`.
- **Ortak dosyalarda küçük değişiklikler:**
  - `Kabuk/Gecis.swift`: `tasinanlar = BenGecisi.sekmeler ∪ GaleriGecisi.sekmeler` (**Galeri artık yerli**; DEBUG `-yalnizSite` site).
  - `SiteVerisi.kokDosyasi(yol)`: `data/` dışındaki dosyalar (ders klasörleri), önbellekli; .json değilse JSON denetimi yok.
  - `Goruntuleyici(incelemeNokta:)` (G1): inceleme açılınca doğrudan o ayrıntıya gider (`incelemeNokta`).
  - `GaleriGorunusu.swift`: `GaleriSimge.kitap`, `.cik`.
- **CI:** `galeri-yan-yana-*.png` (solda site, sağda yerli): `basyapitlar`, `basyapitlar-serit`, `basyapitlar-donem` (Rönesans), `okuma` (Elçiler), `okuma-ayrinti`, `okuma-derin` (`#/basyapit/Q1212937/ders`), `okuma-son` (künye, sözlük), `yan-yana` (Q979440'ın ilk resimli karşılaştırması). `-galeriKaydir serit|donem|okuma-ayrinti|okuma-derin|okuma-son|yanyana`; sitede tıklanacaklar `||` ile sırayla. 8b (sitenin çubuğu) artık `-yalnizSite` ile (Galeri yerli).
  - 600ba95 yeşil (https://github.com/emrymn/nora-sanat/actions/runs/44940413401). İlk koşu derlemede kaldı: `.ritim` satırlarını kuran tek ifade tür denetimi süresini aşıyordu → ayrı işlev. Main'e G2b squash birleşince çakışma çıktı (içerik aynıydı), giderildi.
  - Sekiz yan yana görüntünün hepsine bakıldı: Galeri üstü, dönem sekmeleri, öne çıkan kart ve rozetler, dönem şeritleri, Rönesans ızgarası (geniş kart, kilit etiketi), Elçiler'in kapağı, başlığı, hikâyesi, ayrıntı şeritleri, ayrıntılı anlatım, künye ve sözlük kutuları, yan yana karşılaştırma sitedekiyle aynı düzen, yazı tipi ve renklerde. Sonra düzeltilen (3e0f10d): "Yakından bak" hapı dişli dilin altında kalıyordu (49 pt), öne çıkan kartta seçili nokta pirinç değildi, yan yanada üst resim durum çubuğunun altından başlıyordu. 9213f9c yeşil (https://github.com/emrymn/nora-sanat/actions/runs/44943856095): hap dişlinin üstünde, sitedekinden ~11 pt aşağıda (kabul edildi).
  - Yerli sayfada başlık kayınca üst cam çubuk görünüyor; sitenin CI görüntüsünde (`scrollIntoView` atlamasıyla) görünmüyor. Davranış sitenin koduyla aynı (başlık ekrandan çıkınca).
- **Bilinen farklar / kalan:**
  - Görsel odağı (`odakliGorsel`, yüzün çevresinden kırpma) yok: kartlar ortadan kırpılıyor (G2b'de de böyle).
  - Kapak oranı yerel kopya oranından (`gorsel_oranlari.json`); oranı bilinmeyen eserde kapak 4:5 sayılır ve ayrıntı kırpımları çıkmaz (site resmi indirip ölçüyor).
  - Ayrıntılı anlatım kapatılıp yeniden açılınca site ilk açılışta işaretlenen terimleri ikinci kez işaretlemiyor; burada işaretler korunuyor.
  - Sitede terimler ders gelince, ayrıntı açıklamaları resim oranı gelince işlenir (sıra yarışa bağlı); burada hep belge sırası.
  - Giriş hareketleri (`data-gozcu`, kartların yükselmesi), sahne noktalarının dolma animasyonu, `ekranRengi` (eserden gelen hale rengi) yok; hale `--vurgu`.
  - Yan yanada resim alanlarının zemini `--surface` (`UzakGorsel`'in zemini; sitede sayfa zemini).
  - Gizli sitenin hareket izni penceresi (G2b denetimi) bu işte ele alınmadı → ayrı iş.

**Denetim (G3):** Claude, 2026-11-22 — **onay; Galeri yerli** (PR #19 yorumu). Linux'ta 94 test geçti. `basyapit.mjs` canlı sitede yeniden çalıştırıldı: `basyapitlar`, `dersler`, `cevaplar` örneklerle birebir aynı. Sekiz yan yana görüntüde liste, dönem şeritleri, öne çıkan kart, yakın okuma (kapak, hikâye, ayrıntılar, derin anlatım, künye, sözlük) ve yan yana sitedekiyle aynı. İki yerli görüntüde hareket izni penceresi vardı: dal T5'ten önceydi; main (T5) alındı.

### C3 · Dersler (ChatGPT)
**Site kaynakları:**
- `js/ders.js`, `js/dersIcerik.js`, `js/eserDersi.js`, `js/kamera.js`
- `js/ekranlar/ders.js`, `js/ekranlar/dersVerisi.js`, `js/ekranlar/eserDersi.js`
- `basyapit-dersleri/` (Markdown → SwiftUI)

**Devir notu:** Claude, 2026-11-22 · [PR #22](https://github.com/emrymn/nora-sanat/pull/22) · dal `claude/eager-brahmagupta-tnbnm5` (oturumun zorunlu dalı). C şeridi işi; kullanıcının isteğiyle Claude yaptı.
- **G3'e dayanır:** dal G3'ün son hâlinden (PR #19, onaylı ama birleşmemiş) açıldı. Önce #19 birleşmeli; sonra bu PR'ın farkı yalnız C3 kalır.
- **Kaynak:** sanat-atlasi `a866b86`: `js/kamera.js`, `js/ekranlar/ders.js` (gorAdimi … adimSonu, olaylariBagla), `js/ders.js`, `js/dersIcerik.js`, `js/ekranlar/dersVerisi.js`, `js/tasarim.js` (`roma`), `css/app.css` (`.ders-ust`, `.ders-gor*`, `.ders-noktalar`, `.ders-ogren`, `.ders-kanit*`, `.ders-aciklama`, `.ders-ayirt`, `.ders-ikili*`, `.ders-fark*`, `.ders-son*`, `.ders-alt-cubuk`, `--ders-*`, `html .ders-dugme.dolu` → `--pg-asil` = `--vurgu-acik`).
- **Çekirdek** (`NoraCekirdek/Calis/DersAdimlari.swift`): `DersKamerasi` (gorusAlani, durusa, kameraYolu, egri, kameraEgrisi, kameraKareleri, `hedef` = gorHedef), `DersAdimKurallari` (gorEserleri: `gorPlani`'nın tam kayıtlı hâli; gorKareleri, gorBaslangici, gorYazilari, gorIlerle; roma, Öğren/Ayırt et başlık ve düğme yazıları, cumleKaynagi; ustEtiketi, sonYazisi, sonrakiAdim, dersBittiYazisi; yuruyusEserAdi, kisaAd).
- **Kâhin:** `Testler/kahin/ders_adimlari.mjs` sitenin kendi ekranlarını gezer (bütün konular işlenmiş geçici profil): 28 dersin her Gör karesi (yazılar ve kameranın kurduğu duruş), Gör'ün kaldığı yerden açılışı (8 oran), her Öğren maddesi, her Ayırt et ikilisi, adım sonları; 26 kamera yolu, eğriler, `roma`. `DersAdimlariTests` (4 test). Linux'ta paketin bütün testleri geçti (104). Kamera ölçüleri tarayıcının yazı çizimine bağlı olduğundan CI'da yeniden üretilmez.
- **Ekranlar** (`Ekranlar/Calis/Ders/`): `DersAdimEkrani` (adım seçimi, adım sonu, Gör'süz ders, ders yoksa/kilitliyse `CalisDersSayfasi`), `DersGorAdimi` (koyu sahne; kamera Canvas + TimelineView ile `kameraYolu`'nu örnekler, yeni resim yerine oturur ve eskisiyle çapraz solar, büyük kopya arkadan gelir; metin solup yükselir; Hareket kapalıyken anında), `DersOgrenAdimi`, `DersAyirtAdimi` (sol/sağ rastgele; cevaptan sonra esere dokununca görüntüleyici), `DersAdimOrtak` (üst, çizgiler, düğme, alt çubuk, adım sonu, renkler). İlerleme `PekistirmeModeli.dersAdimiIsle` → `IlerlemeKoprusu` (`adimIsle`, yalnız artar).
- **Bağlantılar:** `CalisSekmesi` `AltSayfa.adim(akım, adım)`; `#/pekistir/ders/<akım>/<adım>` yerli adıma gider, adım ekranında sekme çubuğu gizli. Bugünün dersi kartındaki halkalar ve devam satırı, ders sayfasındaki adım satırları ve devam düğmesi adımları açar (önceki devam düğmesi yanlışlıkla dönem turunu başlatıyordu). Adımdan adıma geçiş yer değiştirir; geri ders sayfasına döner.
- **Eser dersleri:** sitede ayrı ekran yok; başyapıt sayfasının içinde "Daha derine in" (`#/basyapit/<anahtar>/ders`, İş 188). G3'te yerli (`YakinOkuma`, `DersDeposu`, `EserDersi.swift`). `js/eserDersi.js`'teki `kanitDizini` ve `sorulariAl`'ı site ekranları kullanmıyor; taşınmadı.
- **Görünüş (K5):** ölçüler canlı sitenin hesaplanmış stillerinden (393 pt, Gece). CI: `-yerliSekme calis,ben -adres "#/pekistir/ders/Gotik[/adım]" -calisSayfa ders:Gotik[:adım]`, hazır olunca `tmp/ders-hazir`; `ders-yan-yana-{ders,gor,ogren,ayirt}.png` (solda site), ayrıca yalnız yerli `ders-ayirt-cevap.png` (`-dersCevapla`: soldaki esere dokunur; ilerleme yazdığı için en sonda).
- **Kalan:** Çalış'ı yerli sekmelere eklemek (`Gecis.tasinanlar`; bu işte Kabuk'a dokunulmadı). Site Gör'de eserin palet rengini (`ekranRengi`) dolu düğmeye verir; yerli taraf temanın `vurguAcik`'ini kullanır (Kabuk sitenin canlı değişkenlerini okuyorsa aynıdır).
- **Tuzaklar:** Gör'ün ölçü birimi resmin ilk (1280) kopyasının boyudur; büyük kopya gelince ölçü değişmez (sitede de `img.style.width` sabit). Kamera hedefi üst çubuğun altı + 8 ile panelin üstü − 8 arasıdır; panel yazıya göre uzayıp kısalınca kamera yeniden kurulur.
- **CI:** derleme ve paket testleri yeşil. İş süresi 40 → 60 dk yapıldı: G3 + C2 görüntüleri tek başına ekran görüntüsü adımını 36 dk'ya çıkarıyor, C3 ~5 dk ekliyor (40 dk'da C3'e sıra gelmeden iptal oluyordu). Ders sayfasının dolu düğmesi C2'de köşeli ve pirinçti, sitedeki gibi hap ve `--vurgu-acik` yapıldı.
  - **Düzeltme (2026-11-22, Claude):** ilk koşulardaki "yerli" Gör/Öğren/Ayırt et görüntüleri aslında sitenin kendisiydi (o yüzden piksel piksel aynıydı). `Sekme.swift`'in rota tablosunda adım adresleri sekmesiz (`nil`); Kabuk `-adres "#/pekistir/ders/<akım>/<adım>"` ile gelen adresi siteye bırakıyor. CI artık yerli ekranı `-adres "#/pekistir" -calisSayfa ders:Gotik:<adım>` ile açıyor. Yerli adım ekranlarının gerçek yan yana karşılaştırması bu düzeltmeden sonraki koşuda; denetimdeki "yan yana aynı" bulgusu adım ekranları için bu yüzden geçersiz.
  - **Gerçek yan yana (PR #24, 2026-11-22):** yerli Gör, Öğren, Ayırt et ve cevaplı Ayırt et (fark sütunları) sitedeki düzende. Farklar: çok satırlı serif başlıklarda satır arası yerlide açık (Bodoni'nin kendi satırı 1.525 em, sitede 1.1–1.15; SwiftUI eksi `lineSpacing`'i yok sayıyor, denendi; çözüm UILabel + `maximumLineHeight` gibi ortak bir yazı bileşeni, Z3); Bodoni başlıklar yerlide biraz dar düşüyor, satır kırılımı bir sözcük kayabiliyor; dolu düğmenin rengi o an temanın `vurguAcik`'i (site o sayfada nötr `--vurgu-acik`'i gösteriyordu) → Z3.
  - **Çalış yerli olurken (Gecis işi):** sitenin içinden gelen `#/pekistir/ders/<akım>/<adım>` adresleri Çalış'a yönlendirilmeli (bugün siteye gider). Uygulamanın kendi düğmeleri adımları zaten doğrudan açıyor.

**Denetim (C3):** Claude, 2026-11-22 — **onay** (PR #22 yorumu). Linux'ta 104 test geçti. `ders_adimlari.mjs` canlı sitede yeniden çalıştırıldı: tek fark Ayırt et'te iki eserin hangi yanda durduğu (sitede rastgele; test sıradan bağımsız karşılaştırıyor), o ayıklanınca cevaplar örnekle aynı. Yan yana görüntülerde ders sayfası, Gör, Öğren ve Ayırt et sitedekiyle aynı; ders sayfasının dolu düğmesi sitede eserin rengini (`ekranRengi`) alıyor, yerlide temanın altını (Z3). Çalış'ın yerli olması (`Gecis.tasinanlar`) ayrı küçük işte (Claude).

### G4 · Bugün (ChatGPT)
**Site kaynakları:**
- `js/ekranlar/bugun.js`, `js/yuruyus.js`, `js/egim.js`, `js/gunduzRenk.js`, `js/renk.js`, `js/gunun.js`
- Seçim kuralı Swift'te zaten var: `NoraCekirdek/GununSanatcisi.swift`.

**Kapsam:**
- Günün tablosu, perde açılışı.
- Resmin içinde yürüyüş (kaydırdıkça ayrıntıdan ayrıntıya), eğim hareketi.
- Hayatı, bugünkü tur kartı.

**Devir notu:** ChatGPT, 2026-11-21 · [taslak PR #18](https://github.com/emrymn/nora-sanat/pull/18) · `is/G4-bugun`.
- Kaynak: sanat-atlasi `a866b86`, `js/ekranlar/bugun.js`, `js/yuruyus.js`, `js/egim.js`, `js/gunun.js`, `js/gunduzRenk.js`, `js/renk.js` ve `css/app.css`. Günlük seçim mevcut `GununTablosuCozucu` ve `GununSanatcisi` üzerinden. Ayarlar'da o gün için seçilmiş sanatçı da geçerli. Odaklar sitenin `adlaOdak/yuruyusEki` yordamlarından, renkli Gündüz mevcut tema köprüsünden gelir.
- Kapakta perde, kısa ad, varsa imza, Hayatı ve kayda göre Hikâyesi/İncele; tam ekran G1. Yürüyüşte kırpma sınırları, ölçülen kart yüksekliğine göre üst/alt konum, hareketi azaltma ve jiroskop; Hayatı'nda serbest kaydırma, kaynak, günün turu, eserler, okunuş ve başa dönüş. Tur sayısı kabuğun gerçek rozetinden okunur.
- K5: Playwright/WebKit, iPhone 15 Pro, 393 × 852. Kapak kenarı 24 pt, soyadı 64 pt (tek satıra sığarken en az 34 pt), eser 17 pt, eylemler en az 48 pt; ayrıntı kartında başlık 26/29,12 ve metin 18/27 pt. Ben'in `cssSatir`, `Etiket`, `BenIkon` parçaları ile Galeri'nin `GaleriIkon` ve okunuş kuralları kullanılır.
- Kâhin: `Testler/kahin/bugun.mjs` (yerelde salt okunur site deposu, CI'da canlı site); iki resim oranı, üç ayrıntı konumu ve iki kart yüksekliği, sekiz kamera karesi, sekiz izleme adımı, jiroskop ve beş tur kartı. `BugunTests` ayrıca aynı güne özel sanatçı seçimini, eski/geçersiz seçimin geri dönüşünü ve G1'e verilen eseri sınar.
- Telefonda DEBUG `-yerliSekme bugun -adres "#/"` ile açılır. Resme, varsa Hikâyesi'ne veya İncele'ye dokun; kaydırarak ayrıntılar ile Hayatı'nı aç, turu başlat. Gerçek iPhone'da hareket düğmesi ve yana/öne eğim denenmeli. CI aynı adresi `-yalnizSite` ile de açar; `ekranlar/yan-yana-bugun.png` solda site, sağda yerli. `-bugunKaydir` ile aynı sanatçı ve adımda `yan-yana-bugun-ayrinti-alt.png`, `-ayrinti-ust.png`, `-hayati.png`, `-eserler.png` ve `-tur.png` çekilir. Site, DEBUG `-siteBetik` ile gerçek WebView içinde bölüme kayar. CI `tmp/site-betik` sonucundaki sanatçı ve adımı okuyup site görüntüsünü alır; ardından yerli ekran kendi hesapladığı konumu doğrular. Görüntüler CI arşivindedir. `4-url-calis.png` son çekimdir. Normal sürümde etkinleştirme ortak `Gecis.swift` entegrasyonuna kalır.


- **Claude ekleri (GPT hakkı bitince, 2026-11-22):** `-siteBetik` istisnasında `WKJavaScriptExceptionMessage` yazılır (CI günlüğünde görünsün); `bugun-site-cekimi.mjs` öğe ekran dışında kalırsa `scrollIntoView` ile bir kez daha dener. CI 3156c15 yeşil: beş bölümün site/yerli çifti alındı.

**Denetim (G4):** Claude, 2026-11-22 — **onay; Bugün henüz yerli değil, görünüş G4b'ye** (PR #18 yorumu). İlk denetimin 3 maddesi yapıldı (her bölüm için yan yana, base64 yok, `Gecis.swift`'e dokunulmadı). Yan yana: kapak ve üstteki ayrıntı kartı sitedekiyle aynı. Farklar (G4b): alttaki ayrıntıda sitede kamera ayrıntıya yaklaşıyor, yerlide tablonun tamamı; Hayatı/eserler/tur'da sitede yazının arkası koyulaşıyor ve üst şerit (tarih, Ben) duruyor, yerlide resim parlak kalıyor ve yazı durum çubuğuna biniyor; tur kartında sayı kutusu ve ok sitedekinden farklı.

### G4b · Bugün: görünüş sitedeki gibi
- Yukarıdaki denetimin farkları. Yöntem G2b gibi: `yan-yana-bugun-*.png` çiftleri birebir olana kadar. `Gecis.swift`'e dokunma; Bugün'ün yerli olması G4b denetiminden sonra Claude'da (K).

**Devir notu:** Claude, 2026-11-22 · [taslak PR #25](https://github.com/emrymn/nora-sanat/pull/25) · dal `claude/g4b-bugun-screen-8zq61x` (oturumun zorunlu dalı). G şeridi işi; kullanıcının isteğiyle Claude yaptı. G4 (#18) main'de olmadığı için dal origin/main + `is/G4-bugun` birleşimi üstünde; #18 birleşince PR farkı yalnız G4b'ye iner.
- **Kaynak:** sanat-atlasi `a866b86`: `js/yuruyus.js` (`yuruyusBaslat`: `boya`, `kare`, `perdeYaz`), `js/egim.js` (`egimBaslat`, `egimDegeri`), `js/ekranlar/bugun.js` (`ustHtml`, `kapakHtml`, `yuruyusSonu`, `yuruyusKur`), `js/ekranlar/ortak.js` `kunye`, `js/kunye.js` `dinleEkle`, `css/app.css` (`.bugun-ust`, `.bugun-tarih`, `.bugun-ben`, `.yur-sahne::after`, `.yur-bulanik`, `.bugun-yuruyus > .bugun-ust::before`, `.yur-noktalar`, `.yur-kart`, `.yur-hayat`, `.yur-son*`, `.yur-tur*`, `.yur-deste*`, `.yur-karo*`, `.yur-harf`, `.yur-kare*`, `.isim-ek`, `.yur-basa*`, `.bugun-notlar .egim-dugme`). Ölçüler canlı sitenin hesaplanmış stillerinden (Playwright, 393 pt).
  K7: `git -C /tmp/sa log a866b86..HEAD -- js/yuruyus.js js/egim.js js/ekranlar/bugun.js js/ekranlar/ortak.js js/kunye.js css/app.css`
- **Kök neden (G4 denetimindeki farkların çoğu):** kaydırma konumu okunmuyordu. İçeriğin arkasındaki `GeometryReader` tercihi kaydırınca güncellenmiyordu; kayma hep 0 kaldı. Bu yüzden kamera ayrıntıya yaklaşmıyor, perde koyulaşmıyor, yürüyüşte sekme çubuğu ve hareket düğmesi duruyordu. Şimdi `BugunKaymaIzi`: iOS 18'de `onScrollGeometryChange`, iOS 17'de içeriğin `.scrollView` uzayındaki yeri (`onGeometryChange`).
- **Eğim:** sitede eğim izni gerekmiyorsa ayar açıkken hemen dinlenir ve `egimDegeri()` ilk örnekten önce `{0, 0}` döner; resim her yandan 26 px taşar. Yerlide `izin` düğmeye basılana kadar kapalıydı ve ilk jiroskop örneği bekleniyordu; aslan karesindeki ~30 pt dikey fark bu paydan (CI günlüğünde site dönüşümü `perspective … translate3d(-26px, …)`). Artık `algilama` = ayar açık; `BugunHareketi.baslat` değeri hemen `.zero` yapar; simülatörde `varMi` sitenin `egimVar()`ı gibi doğru.
- **Görünüş:** sahne gradyanı `rgba(18,17,16)` .5/0/0/.8/.96; buğu malzeme + `rgba(18,17,16,.6)`, saydamlığı perde (resmin kendisine `.blur` bantlı ve karanlık çıktı). Üst şerit: tarih 11.5/600 aralık 2.3 `#aca498`, Ben `rgba(18,17,16,.5)`; Hayatı'na inerken arkasında `::before` perdesi (0.92 → 0, ekran üstünden şeridin 40 pt altına). Hareket düğmesi kapakta (kapakla kayar). Yürüyüş noktaları pirinç. Ayrıntı kartı malzeme + `rgba(24,22,20,.5)`, 1 px `rgba(235,229,218,.14)` çizgi (boyuta dahil).
- **Hayatı ve son** (`BugunHayati.swift`, baştan): h2 34/37.4, metin 19/29.45, kaynak 13/18.2 `--yur-ikincil` (alt 40); künye `BugunTablosu.sonKunye` (yıllar · akım, pirinç, testli); "Resmi gezdin." 40/42; tur kartı (deste 70 × 66, ±8° kartlar `#4e3d2c`/`#6d5236`, sayı kartı `#26221e` + pirinç 1.5, halkalı ok 40); iki karo (harf halkası 52, 2 × 2 kareler 30 × 26, en az 150, eşit boy); Dinle/IPA (Galeri'deki `.isim-ek` gibi); Başa dön halkası 56 + BAŞA DÖN 11/600 aralık 2.2.
- **Tuzak:** Newsreader'ın iOS'taki doğal satırı ~1.0247 × boyut (ortak `cssSatir`'ın varsaydığı 1.0 değil). Hayatı'nın uzun metninde satır başına +0.47 pt, 20 satırda ~10 pt kayma ölçüldü. Bugün'de yerel `bugunOkumaSatiri` kullanılıyor; ortak `Yazi.Aile.satirOrani` (Ben, T4 dosyası) Z3'te düzeltilmeli (uzun okuma metinlerini etkiler).
- **CI:** site betiği (`Testler/bugun-site-cekimi.mjs`) Hayatı içindeki gerçek kaydırmayı (`konum`) ve ölçüleri (`H`, alt pay, kart, resim dönüşümü) döndürür; yerli `-bugunKonum` ile aynı yere gider (iOS 18 `ScrollPosition`, yalnız DEBUG), kamera hedefe oturunca `tmp/bugun-durum`'a kayma/adım/çerçeve yazar, günlükte `yerli <bölüm>: …`. Eserler OCR sözcüğü `Izgara` (karonun başlığı sitede de sekme çubuğunun arkasında).
- **Yan yana** (e415f90, eğimden önce): kapak, iki ayrıntı, Hayatı, eserler, tur aynı düzen, yazı ve renkte; satırlar ±1 pt. Kalan fark aslan karesinde kameranın 26 px payıydı (yukarıda).
- **Kalan / bilinen:** tur kartındaki parıltı (`yur-parilti`) ve dokunma hareketleri (deste açılır, ok kayar) yok. Hareket düğmesinin basılı/basısız simge tonu yok. Gündüz temasında yürüyüş renkleri sabit koyu (sitede de `.bugun-yuruyus` her temada koyu).
- **Ortak dosya:** dokunulmadı (`Gecis.swift` dahil). Bugün'ün yerli olması denetimden sonra Claude'da.

**Denetim (G4b):** Claude, 2026-11-22 — **onay** (PR #25 yorumu). CI e415f90 yeşil (eğim payı düzeltmesi 387cf47 sonrası CI birleştirmeden önce); altı yan yana görüntü (kapak, alttaki ve üstteki ayrıntı, Hayatı, eserler, tur) sitedekiyle birebire yakın. G4 squash ile girdiği için main'le çakışma Claude'da çözüldü (taban 0f8bd91; sonuç farkı dalın G4b farkıyla aynı).

### C4 · Ben (ChatGPT)
**Site kaynakları:** `js/ekranlar/ilerleme.js`, `js/ekranlar/ayarlar.js`, `js/ekranlar/hizliAyar.js`, `js/kurs.js`, `js/yenilikler.js`, `js/rozet.js`.

**Kapsam:**
- Konular ("işlendi").
- Akım doğruluk çubukları, en zayıflar.
- Bütün ayarlar.
- Yedekle ve geri yükle: **sitenin JSON biçimiyle aynı**, eski yedekler çalışmalı.

**Devir notu:** ChatGPT, 2026-11-21 — PR #10, `is/C4-ben`.
- Kaynak: `sanat-atlasi` @ `a866b86`; `js/ekranlar/{ilerleme,pano,ayarlar,hizliAyar}.js`, `js/{depo,devam,kurs,gunduzRenk,rozet,yenilikler}.js`.
- Ben yerli sekmedir. İlerleme kurs konularını ve toplu işaretlemeyi, açık sanatçıları, kalıcıları, vadeyi, çalışma geçmişini, akım doğruluklarını, zayıfları ve karıştırılanları gösterir. Normal okumalar ve değişiklikler T2 köprüsünden geçer; renkler ve yazılar T3 temasındandır.
- Ayarlar günlük kart, tanışma, tema, gündüz rengi, yazı boyutu, hareket, rozet, eğim, titreşim, günün sanatçısı, geliştirici modu ve cihaz araçlarını içerir. C5'e kadar çevrimdışı görsellerin indirme, durdurma ve silme işlemleri mevcut site deposunda yürür.
- Yedek panoya veya JSON dosyasına alınır. Yapıştırılan ya da dosyadan seçilen eski/yeni yedeği sitenin `yedekCoz` işlevi doğrular. Konu ve skor sayıları gösterilip onay alınır. Onaydan beri kayıt değişmişse geri yükleme durur. Yarım oturum da sitenin doğrulamasından ve IndexedDB yolundan geçer.
- `Testler/kahin/ben.mjs` geçici tarayıcı profilinde gerçek siteyi çalıştırır. Pano, zayıf sırası, konu/ayar değişiklikleri, eski ve zarflı yedek, yarım oturum, hatalı JSON yapısı, çakışma ve geliştirici modundan dönüş sınanır. `BenTests` aynı örnekleri Swift kurallarına uygular.
- Telefonda: Ben'den bir konuyu işaretle; Ayarlar'dan gündüz rengini değiştir. Yedek al, bir ayarı değiştir, yedeği denetle ve onayla; önceki ayar ve konu sayısı geri gelmeli. DEBUG: `-adres "#/ilerleme"` veya `-adres "#/ayarlar" -benSayfa ayarlar`. CI görüntüleri: `ben-ilerleme.png`, `ben-ayarlar.png`. T2'nin web görüntüsü ayrı alınır ve `4-url-calis` en sondadır.

**Denetim (C4):** Claude, 2026-11-21 — **onay; Ben henüz yerli değil, görünüş C4b'ye** (PR #10 yorumu).
- Paket testleri geçti.
- `ben.mjs` canlı sitede çalıştırıldı, cevaplar aynı. Kâhin Swift dosyasındaki yedek, geri yükleme ve geliştirici betiklerini sitenin içinde gerçekten çalıştırıyor.
- Geri yükleme güvenli: yedeği sitenin `yedekCoz`'u çözüyor, onaydan beri `kayitNo` değiştiyse duruyor.
- **Görünüş K5'e uymuyor.** CI görüntülerinde Ben standart iOS listesi: sistem başlığı, sitenin kolajı, büyük rakamları ve tipografisi yok. Telefonda Ben'e her girişte görünür bir gerileme olurdu.
  - Bu yüzden `Gecis.tasinanlar` boş kaldı; yerli Ben yalnız DEBUG `-yerliSekme ben` ile açılıyor (CI görüntüleri böyle alınıyor).
  - Görünüş **C4b**'de düzeltilecek.
- Yerli sekme çubuğu (T3) sitenin yüzen çubuğuna benzemiyor → **T4** (Claude). Hiçbir sekme T4'ten önce yerli olmaz.

### C4b · Ben: görünüş sitedeki gibi (ChatGPT)
**Site kaynakları:** `js/ekranlar/{ilerleme,pano,ayarlar}.js`, `css/app.css` (Ben ve ayarlar bölümleri), sitede `TASARIM_DILI.md`.

**Yapılacaklar:**
- C4'ün ekranları (`NoraSanat/Ekranlar/Ben/`) sitenin Ben ve Ayarlar sayfalarına benzesin:
  - üstte eser kolajı;
  - "Kursun neresindesin" büyük serif rakamlar;
  - Sanatçı / Kalıcı / Tekrar sütunları;
  - son 12 hafta ızgarası;
  - bölüm başlıkları sitenin küçük büyük harfli etiketleri gibi.
- Yazılar `Yazi.serif/sans/okuma`, renkler `TemaDeposu`.
- Karşılaştırma görüntüsü: CI'da aynı adreste sitenin (`-yalnizSite`) ve yerli ekranın görüntüsü yan yana alınsın.
- Bitince `Gecis.tasinanlar = BenGecisi.sekmeler`; ama T4 bitmeden değil.

**Devir notu:** Claude, 2026-11-21 · PR #13 · dal `claude/happy-euler-f36zti` (oturumun zorunlu dalı). C şeridi işi; kullanıcının isteğiyle Claude yaptı.
- **Kaynak:** sanat-atlasi `a866b86` (site 1.90.3). Taşınanlar:
  - `js/ekranlar/ilerleme.js`: `ilerlemeSayfasi`, `parcalar`, `eserDuvari`, `siradakiKonuHtml`, `kursBolumleriHtml`, `konuKarti`, `kitapKapagi`, `karisanlarBolumu`, `tanisKartiHtml`, `konuIsaretle`
  - `js/ekranlar/calisma.js`: `takvimHtml`, `oranGrafigi`, `yukGrafigi`, `koleksiyonBagi`
  - `js/ekranlar/pano.js`: `seviyeIziHtml`, `kutuPipHtml`; `js/ekranlar/ortak.js`: `ust`, `etiket`, `tabloDugme`, `akimNoktasi`
  - `js/ekranlar/ayarlar.js`: `ayarlarSayfasi` ve bölümleri (sıra, yazılar); `js/tasarim.js`: `YOLLAR` (geri, ileri, işaret, kilit, doğru, karşılaştır, kapat, hareket, mühür, kum saati), `pgDisk`
  - `css/app.css`: `.ilr-*`, `.duvar*`, `.etiket`, `.bolum-baslik`, `.ust*`, `.calisma-takvim`, `.tk`, `.grafik*`, `.satir`, `.siradaki*`, `.isle-ince`, `.kilitli-kare`, `.kurs-kip`, `.salon-raf*`, `.destek`, `.kitap*`, `.konu-karti*`, `.konu-portre`, `.akim-kart*`, `.cevapsiz-akimlar`, `.hatalar-satir`, `.zayif-*`, `.kutu-pip`, `.sv-iz`, `.secim-hap`, `.tanis-*`, `.eser-dugme`/`.ed-*`, `.ayar`, `.parcali`, `.adimlayici`, `.konu`, `.anahtar`, `.dugme`, `.dugme.ince`, `.pg-disk`
  - Ölçüler canlı sitenin **hesaplanmış** stillerinden alındı (Playwright, 393 pt, Gece; css dosyasında aynı seçici birkaç kez eziliyor, son değer geçerli).
  K7 farkı: `git -C /tmp/sa log a866b86..HEAD -- js/ekranlar/ilerleme.js js/ekranlar/calisma.js js/ekranlar/pano.js js/ekranlar/ayarlar.js js/ekranlar/ortak.js js/tasarim.js css/app.css`
- **Yapılanlar** (hepsi `NoraSanat/Ekranlar/Ben/`):
  - `BenGorunusu.swift`: ortak parçalar. `BenSimge`/`BenIkon` (sitenin SVG'leri), `Etiket` (11 px, 0.2em, Türkçe büyük harf), `BolumBasligi`, `BenUst` (yuvarlak geri, 48 px başlık, sağ düğme), `YuvarlakDugme`, `Ayrac`, `HapDugme` (`.dugme` / `ince`), `PigmentDisk`, `ParcaliSecim`, `AnahtarBicimi` (`.anahtar`; konu kartında mürekkep renkli), `AnahtarYazisi`, `KucukHap`, `OranCubugu`, `KutuPip`, `SeviyeIzi`, `AkimNoktasi`, `AyarBolumu`, `AyarAciklamasi`.
  - `BenSekmesi.swift`: `List` yerine `ScrollView`. Sahne (kayan `EserDuvari`, üst, pano, `TabloDugme` "Tekrar bekliyor"), sonra takvim, grafikler, Koleksiyonum / Ayarlar satırları, sıradaki konu, kitaplık, akımlar, zayıflar. Ayarlar sitedeki gibi ayrı sayfa (yandan kayar). Açık sekmeye yeniden dokunma başa kaydırır, Ayarlar'dan Ben'e döner.
  - `BenGrafikler.swift`: `CalismaTakvimi` (7×12, akım renkli kare, bugün çerçeveli), `CalismaEgrileri` (sitenin SVG'leri `Canvas`'la aynı ölçüde), `BenSatiri`.
  - `BenKitaplik.swift`: `SiradakiKonu` (kilitli kareler, dolan "İşlendi yap"), `KursKitapligi` (kip, bölüm rafı, Roma rakamı, halka, kitaplar; sıradaki kitaba kayar), `KonuKarti` (portreler, İşlendi anahtarı, "1–n arası hepsi işlendi").
  - `BenAkimlar.swift`: `AkimBolumu` (resimli kartlar, seviye etiketi, Sırayla/Zayıf önce, cevapsız haplar), `ZayifBolumu` (karıştırılanlar, Hatalarım turu, zayıflar), `TanisKarti` (Ö6; C4'te yoktu), `AkisDuzeni`.
  - `BenAyarlari.swift` + `BenAraclari.swift` + `BenCevrimdisi.swift`: sitenin sırası ve yazıları. Değişken yazılar (günün sanatçısı, sürüm, yenilikler, hata sayısı, elle odaklar, yürüyüş sayısı, eğim izni, gündüz rengi örnekleri) sitenin modüllerinden tek betikle okunuyor (`AyarBilgisi.betik`). Çevrimdışı bölüm sitede varsa görünür (artık açılır kapanır değil).
  - `BenDeposu.yap/degistir(bitti:)`: işlemden sonra yeni ilerlemeyle çağrılır (Tanış kartı için).
  - Davranış, köprü betikleri (`benYedekAl`, `benGeriYukle`, `benGelistirici`) ve kâhin C4'teki gibi; `ben.mjs` değişmedi.
- **Ortak dosyalarda küçük değişiklikler:**
  - `Kabuk/Gecis.swift`: `tasinanlar = BenGecisi.sekmeler` (**Ben artık yerli**; DEBUG `-yalnizSite` site). `KabukDurumu.dilGizle(_:sekme:)` / `dilGorunur` (T4'ün önerisi).
  - `Kabuk/YerliSekmeCubugu.swift`: dil `dilGorunur` değilse gizli.
  - `NoraSanatApp.swift` (DEBUG): `BenKarsilastirma.siteyiKaydir()`.
- **CI karşılaştırması:** `-benKaydir kurs|akim|yedek` (DEBUG) yerli ekranı ve siteyi (`-yalnizSite`) aynı bölüme kaydırır; yerli ekran hazır olunca `tmp/ben-hazir` yazar. CI her biri için `site-*.png`, `ben-*.png` ve ikisinin birleşimi `yan-yana-*.png` üretir (solda site, sağda yerli): ilerleme, ilerleme-kurs, ilerleme-akim, ayarlar, ayarlar-yedek.
- **Denetim düzeltmeleri (PR #13 yorumları):**
  1. Küçük görsel kuralı: `katalog.eserler(id).first` yerine sitenin `enBilinen` kuralı. Çekirdek `SiteVerisi/Temsil.swift`: `Temsil.disi` (`TEMSIL_DISI`), `olabilir` (`temsilOlabilir`), `enBilinen`, `kucukGorsel`, `bilinirlikSirasi`, `siradaki` (`eserKareleriDoldur`); `SiteKatalogu.kucukGorselAdresi` / `eserGorselAdresi`. Kitap kapakları, portreler, sıradaki konunun kareleri, Tanış kartı, zayıflar, akım kartları ve eser duvarı bunu kullanıyor; "Tekrar bekliyor" yelpazesi bilinirlik sırasıyla 0–2. eser, zemin `3 + gün % 7`.
     Kâhin `Testler/kahin/temsil.mjs` → `Ornekler/temsil/cevaplar.json` (155 sanatçı; 43'ünde site ilk eseri değil başka bir eseri seçiyor; 25 "kötü görsel" durumu; Berlinghieri'nin temsil dışı panosu). `TemsilTests` (5 test).
  2–4. Ayarlar: başlık 40 px (`.ust h1`; Ben'de 48). Bodoni Moda'nın kendi satır yüksekliği 1.525 em, sitede CSS `line-height` 1.2 → `cssSatir(aile, boyut, satir)` ile satır yükseklikleri CSS'e eşitlendi (ayar başlığı 26.4, açıklama 19.5 + 7.2 boşluk, anahtar yazıları 20.25 / 16.875). Gündüz rengi kutuları 72 pt, 13 px. "Nötr kâğıt" örneği sitedeki gibi iki renkli (`.renk-ornek.notr`). Yazı boyutu açıklaması vardı ama sekme çubuğunun altında kalıyordu; ölçek düzelince görünür.
- **CI:** 84e605e yeşil (https://github.com/emrymn/nora-sanat/actions/runs/44884426437); son ince ayar commit'i sonrası yeniden koşar.
  - İlk koşular: `UIFont.TextStyle.caption` yok (`.caption1`); Ayarlar'da yerli koddan çağrılan `izinVarMi()` iOS hareket izni penceresini açıp ekranı kapattı → betikten çıkarıldı.
  - `yan-yana-*.png` beşine de bakıldı: Ben'in başı, kitaplık, akımlar, Ayarlar ve Yedek bölümleri sitedekiyle aynı düzende, aynı yazı tipleri ve renklerde. Büyük rakamın boşluğu ve Ayarlar açıklamalarının satır aralığı sonradan sıkılaştırıldı.
  - Bilinen küçük farklar: bazı kitap kapakları sitedekinden farklı eser (kapak dosyası yoksa ilk sanatçının en bilinen eseri; site aynı kuralı izliyor ama eser sırası farklı olabilir); "Nötr kâğıt" örneği düz daire (sitede ikiye bölünmüş); duvarın eserleri farklı (sitede sıra rastgele kayıyor).
- **Kalan / sonraki işler için:**
  - Sitedeki giriş hareketleri (kitapların rafa dizilmesi, sayıların sayarak gelmesi, kitap parıltısı, sıradaki konunun kayarak gelmesi) yok; yalnız duvar kayması, İşlendi dolması, kart açılması ve Tanış kartı hareketli. Z3'te.
  - Sitede işaretlemeden sonra çıkan kısa bildirimler (`bildir`: "Açıldı: …") yok (C4'te de yoktu).
  - Ayarlar'daki iletiler sitedeki gibi bölümün altında değil, iOS uyarısıyla (C4'teki gibi).
  - Gündüz'de pano kartı ve gölgeler yaklaşık; CI görüntüleri yalnız Gece.
- **Tuzaklar:**
  - Ayarlar açılınca gizli site `#/ayarlar`'a gider (çevrimdışı indirme durumu sitenin sayfasından okunuyor). Bu yüzden yerli Ben'in adresi de `#/ayarlar` olur; sorun değil, ama C5'te indirme Swift'e geçince bu kalkmalı.
  - `EserDuvari` `TimelineView` ile döner; Ben seçili değilken, Ayarlar açıkken ve hareket azaltılmışken durur.

**Denetim (C4b):** Claude, 2026-11-21 — **onay, düzeltmelerden sonra** ([1](https://github.com/emrymn/nora-sanat/pull/13#issuecomment-7059887616), [2](https://github.com/emrymn/nora-sanat/pull/13#issuecomment-7060050613)). İlk CI kırmızıydı: Ayarlar açılışta `izinVarMi()` çağırıp iOS hareket izni penceresini açıyordu (C4b oturumu düzeltti). İstenen: küçük görseller sitenin `enBilinen` kuralıyla (`Temsil.swift`, `temsil.mjs` canlı sitede yeniden çalıştırıldı, 155 sanatçı aynı), yazı boyutu açıklaması, nötr kâğıt diski, Ayarlar ölçüleri. Son CI'ın yan yana görüntülerinde Ben, kitaplık, akımlar ve Ayarlar sitedekiyle aynı. **Ben, telefonda ilk yerli sekme.**

### T4 · Yerli sekme çubuğu sitenin çubuğu gibi (Claude)
- `KokGorunum`'un yerli çubuğu sitenin yüzen, yuvarlak köşeli çubuğuna benzesin: aynı simgeler (SVG'den), aynı yerleşim, Çalış rozeti.
- Siteden yerliye geçişte çubuk yerinde kalıyormuş gibi görünsün.

**Devir notu:** Claude, 2026-11-21 · PR #12 · dal `claude/cool-albattani-hix2af` (oturumun zorunlu dalı).
- **Kaynak:** sanat-atlasi `a866b86` (site 1.90.3). Taşınanlar:
  - `js/ekranlar/ortak.js`: `SEKMELER`, `SEKME_IKONU`, `sekmeleriCiz`, `sekmeRozeti`, `sekmeSurukle`
  - `js/ekranlar/hizliAyar.js`: dişli dil ve yaprak
  - `js/tasarim.js`: `YOLLAR`, `ikon()`
  - `css/app.css`: `.sekmeler`, `#sekmeler` (İş 190), `.sekme-isaret`, `.sekme-rozet`, `.hizli-dil`, `.hizli-yaprak`, `--sekme-h`, `--sekme-alt`
  K7 farkı: `git -C /tmp/sa log a866b86..HEAD -- js/ekranlar/ortak.js js/ekranlar/hizliAyar.js js/tasarim.js css/app.css`
- **Yapılanlar:**
  - Çekirdek `Gecis/SekmeCubugu.swift`:
    - `SekmeCubugu.sekmeler`: sitedeki 4 sekme. Ben seçiliyken sitedeki gibi Bugün seçili görünür.
    - `Simge`: sitenin SVG'leri, olduğu gibi kopyalandı.
    - `Yerlesim`: çubuk, sekmeler, simge, dil ve rozetin yeri; CSS'in hesabıyla, güvenli alan dahil.
    - `enYakin` / `surukle`: dokunuş ve sürükleme.
  - Çekirdek `HizliAyar`: tema ve hareket seçenekleri, günlük kart 5…100.
  - Çekirdek `Gecis/SVGYolu.swift`: küçük SVG okuyucu (path/rect/circle; yaylar kübik eğriye çevrilir).
  - `Kabuk/YerliSekmeCubugu.swift`:
    - Cam çubuk (`--tab-bg` + blur, mürekkep %14 kenar), kayan hap (0.45 s yaylı eğri).
    - Parmakla sürükleme, seçili simgede zıplama, Çalış rozeti, dişli dil.
    - Hareket kapalıysa ya da iOS'ta azaltılmışsa animasyon kısalır.
  - `Kabuk/HizliAyarYapragi.swift`: Tema, Hareket, Günlük kart ±5, Bütün ayarlar (`#/ayarlar`).
  - `Kabuk/SekmeCubuguKoprusu.swift`: rozet (`turBilgisi('karisik').toplam`) ve hızlı ayar okuma/yazma betikleri. Sitenin yaprağı gibi yazar: `kaydet()`, `temaUygula()`.
  - `KokGorunum`:
    - Sistemin sekme çubuğu gizli (`.toolbar(.hidden, for: .tabBar)`).
    - Her yerli sekmenin altında çubuk kadar boşluk (`safeAreaInset`).
    - Yerli çubuk site görünürken de kurulu ve saydam: hap sitenin seçimini izler, yerliye geçince oradan kayar.
  - `Gecis.sekmeyeGecBetigi` (`Gezgin.sekmeyeGec(s, onceki:, bas:)`): yerliden siteye geçerken sitenin hapı önce hareketsiz yerli hapın yerine konur, sonra yeni sekmeye kayar. Site zaten o sekmedeyse (`bas: false`) yalnız hap kayar.
  - `KabukDurumu`:
    - `calisRozeti`, `rozetiYenile()`: adres değişince, site yüklenince, ilerleme yazılınca ve uygulama öne gelince yenilenir. Site hazır değilse saniyede bir yeniden dener.
    - `yenidenDokunma[sekme]`: açık sekmeye yeniden dokunma sayacı.
    - `cubuguGizle` / `.sekmeCubuguGizli(_:sekme:)`, `hizliAcik`.
  - SF Symbols simgeleri (`Sekme.simge`) kaldırıldı.
- **Kâhin:**
  - `Testler/kahin/sekme_cubugu.mjs` → `Ornekler/sekme_cubugu/cevaplar.json`. İçinde:
    - simgelerin işaretlemesi ve `getBBox()` sınır kutusu;
    - 393×852, 320×568, 430×932, 820×1180'de çubuk, sekmeler, hap, simge, dil ve rozet yerleri;
    - hızlı ayar seçenekleri, günlük kart sınırları (yaprağın kendi + / − düğmeleriyle).
    - Ayrıca Swift'teki köprü betiklerini canlı sitede çalıştırır: rozet sitenin rozetiyle aynı (8 = 8); tema, hareket ve kart yazılıyor, `localStorage`'a gidiyor.
  - `SekmeCubuguTests` (7 test): sınır kutuları 0,01, yerleşim 0,01 içinde siteyle aynı.
  - `kabuk_koprusu.mjs` artık `Gecis.sekmeyeGecBetigi`'ni dosyadan okuyor. Hapın 3'ten 2'ye ve `bas: false` ile 0'dan 2'ye kaydığını sınıyor; geçti.
  - Linux'ta paket testleri: 75 test, 1'i yalnız canlı modda (atlanıyor).
- **CI:** 784596e yeşil (https://github.com/emrymn/nora-sanat/actions/runs/44873522825).
  - Yeni görüntüler: `8b-site-cubuk.png` (aynı adreste sitenin çubuğu) ve `8c-hizli-ayar.png`.
  - `8-yerli-sekme.png` ile `8b`'nin alt kısımları yan yana bakıldı: çubuk, simgeler, hap, rozet ve dil aynı yerde ve aynı görünüşte.
  - `ben-ilerleme.png`'de yerli çubukta Bugün seçili (sitedeki gibi).
  - Düzeltmeler: ilk koşuda rozet yoktu (site hazır olmadan soruluyordu); ikincide rozet simgenin üstündeydi. İkisi düzeltildi.
- **Kalan / sonraki işler için:**
  - Hiçbir sekme hâlâ yerli değil. T4 bitti, artık `Gecis.tasinanlar`'a sekme eklenebilir.
  - Yerli ekranlar:
    - Açık sekmeye yeniden dokunmayı `.onChange(of: durum.yenidenDokunma[.galeri])` ile dinleyip köke dönsün ya da başa kaysın (sitede en başa kaydırır).
    - Sitede çubuğun gizlendiği sayfalarda (sekmesiz: karşılaştırma, pekiştirme kartı) `.sekmeCubuguGizli(true, sekme: …)` kullansın. `fullScreenCover` zaten çubuğun üstüne çıkar.
  - **C4b için:** Sitede `#/ayarlar`'da dişli dil gizli (`HizliAyar.dilGorunur`). Yerli Ben'in Ayarlar sayfası kabuğa görünmüyor; Ben, Ayarlar açıkken kabuğa bildirmeli. Önerim: `KabukDurumu`'na küçük bir `dilGizli` bayrağı. Şimdilik dil orada da görünüyor.
  - Yürüyüşte (G4) sitede çubuk aşağı kayıp kaybolur (`yuruyus-icinde`). Bu `cubuguGizle` ile yapılabilir; kayma animasyonu henüz yok.
  - Gündüz'de çubuğun gölgesi yaklaşık: `--golge-rgb` yerine mürekkep %14. Renkli Gündüz'de çubuk sitenin `--tab-bg`'sini `TemaKoprusu`'ndan alıyor.
- **Tuzaklar:**
  - Hızlı ayar yazımı sitenin `d.ilerleme`'sine doğrudan yazar (sitenin yaprağı gibi), `IlerlemeKoprusu.degistir`'den geçmez. Kayıt kilidini site `kaydet()`'te kendisi denetler.
  - Yerli çubuk yazıları Dinamik Yazı'yla büyümez (sitede de sabit 11 px); çubuk yüksekliği sabit 62.

### G5 · Yolculuk + Zaman (ChatGPT)
**Site kaynakları:**
- `js/harita.js`, `js/bolum.js`, `js/ekranlar/harita.js`, `js/surukleKapat.js`, `js/sallanma.js`
- `js/zaman.js`, `js/ekranlar/zaman.js`

**Devir notu:** Claude, 2026-11-22 · [PR #20](https://github.com/emrymn/nora-sanat/pull/20) · dal `is/G5-yolculuk`. İş iki parça: **G5a** (ChatGPT: çekirdek, kâhin, ilk ekranlar ve CI karşılaştırması) ve **G5b** (kullanıcının isteğiyle Claude: ara denetimdeki 11 maddeyle görünüş sitedeki gibi). ChatGPT not yazmamıştı; ikisini de bu not anlatıyor.
- **Kaynak:** sanat-atlasi `a866b86` (site 1.90.3). Taşınanlar:
  - `js/harita.js`: `BOLGELER`, `W`, `H`, `ARA`, `SEPYA_PAY`, `SEPYA_GECIS`, `vakit`, `haritaKur`, `sepyaSiniri`, `yolcuYeri`, `yolcuYolu` (tek parça), adres kalıpları
  - `js/ekranlar/harita.js`: `haritaSayfasi`, `durakHtml`, `madalyonHtml`, `siradakiSeviye`, `siradakiIs`, `motifHtml`, `resimHtml`, `gecisHtml`, `yolcuHtml`, `yuru`, `konumaKaydir`, `kaydirmaIzle` (dönem göstergesi), `kursRozetiHtml`, `kursPenceresi`, `durakPenceresi` (1.89 "G2"), `motifPenceresi`, `motifEseri`, `kapakDoldur`, `motifKapakDoldur`, `olaylariBagla`
  - `js/bolum.js`: `bolumKaydi`, `gectiMi`, `yildizSayisi`, `bolumSonucuIsle`, `gorulenGruplar`, `tanismaGrubuGoruldu`, `tanitimGoruldu`, `BOLUM_SORU`, `BOLUM_GECME` (bölümleri kurmak ve kilitler C2'nin `CalisDersKurallari`'nda)
  - `js/ekranlar/pekistir.js` (bölüm dalı): `konuTanismaGoster`, `kartCiz` (`tanitimIsaret`), `kartiBitir`, `sergiyeEkle`, `grupOzeti`, `bolumOzeti`, `seviyeTamamHtml`, `tamamlananDonem`, `pkUst`, `kipKisa`, `BOLUM_SV_AD`, `BOLUM_YONELME`
  - `js/zaman.js`, `js/ekranlar/zaman.js` (hepsi)
  - `css/app.css`: `.harita-ust`, `.harita-ozet`, `.kurs-rozet*`, `.harita-vakit`, `.harita-zaman*`, `.harita-durak*`, `.durak-halka`, `.durak-yildizlar`, `.durak-kilit`, `.durak-etiket`, `.harita-gecis-yazi*`, `.harita-resim.sepya`, `.harita-pencere*`, `.hp-kapak*`, `.hp-basla`, `.kurs-pencere`, `.kurs-siradaki`, `.motif-kapak`, `#uygulama .hp2*`, `.ozet`, `.grup-ozet`, `.bolum-sonuc`, `.sergi-*`, `.asi*`, `.seviye-tamam`, `.st-*`, `.skor*`, `.yol*`, `.durak-nokta`, `.durak-ad`, `.gecis*`, `.sonuc-harita`, `.zm-*`
  K7 farkı: `git -C /tmp/sa log a866b86..HEAD -- js/harita.js js/bolum.js js/ekranlar/harita.js js/ekranlar/pekistir.js js/zaman.js js/ekranlar/zaman.js css/app.css`
- **Çekirdek** (`NoraCekirdek/Yolculuk/`):
  - `YolculukHaritasi.kur`: durakların dönemi, meydanı, sembolü, ölçüsü, kilit yazısı ve kaydı (`haritaKur` + `bolumDurumlari`, İş 191 ders kapısıyla). `YolcuPatikasi`: öğrencinin patikası, süresi, pozu. `ZamanKadrani`: `yasayanlar`, `yogunluk`, `yuzyilEvresi`, başlangıç yılı.
  - `BolumTuru.swift` (G5b'de yeniden): `BolumKurallari` (kayıt, yıldız, `sonucuIsle`, `grubuGoruldu`, `tanitimGoruldu`, `gorulenGruplar`), `BolumSonucu`, `BolumTuru` (pekiştirme turu `TurKaydi` + yalnız ilk denemelerin sergisi + bitişte kayıt; `baslik` = `kipKisa`, `tanismaYazilari`).
  - Kâhin `node Testler/kahin/yolculuk.mjs /tmp/sa` (sitenin kendi modülleri) → `Ornekler/yolculuk/cevaplar.json`: bütün durakların adı, sanatçıları, grupları, yeri, sembolü, kilit yazısı, yıldızı; yedi yılın evresi ve yaşayanları; 75 cetvel çubuğu; grup ve tanıtım işaretleri; beş `bolumSonucuIsle` dönüşü (G5b ekledi; öbür cevaplar aynı kaldı). `YolculukTests` (3 test). `Testler/kahin/yolculuk-olculeri.mjs` hesaplanmış ölçüleri yazar (CI'da yalnız bu dalda ayrı iş).
- **Ekranlar** (`NoraSanat/Ekranlar/Yolculuk/`):
  - `YolculukSekmesi.swift`: harita (dokuz dönem alttan üste; köprülerde yüzyıl, elmaslı çizgi, ad, "n bölüm · k açık"; son açık durağın üstü sepya), durak madalyonu (halka genişlik + 34, yıldız / 3 pirinç; üç yıldız; kilitlide kesik halka ve kilit; `scale 1.14`), "buradasın" etiketi, öğrenci ve yürüyüş, saklı motif alanları, sabit kurs rozeti, gündüz/gece, ortadaki döneme göre değişen dönem göstergesi. Açılışta "buradasın" durağının üstü ekranın %55'inde (`konumaKaydir`).
  - `YolculukPencereleri.swift`: sekme çubuğunun 10 üstünde yüzen, aşağı çekince kapanan kartlar: `DurakPenceresi` (hp2: bulanık kapak zemini, kapak, tek beyaz düğme, gruplar, seviyeler, Orta eserleri, Akım sayfası; kilitlide kilit yazısı ve "Derse git"), `KursPenceresi` (Türkçe konu adı `konular_tr.json`, "k sanatçı açılacak", İşlendi yap, Bütün konular), `MotifPenceresi` (yaldız çerçeveli eser ve künye levhası, dokununca görüntüleyici; uzun hikâye `harita_motifler.json`).
  - `BolumTuruEkrani.swift`: `BolumOyunu` (tur `noraYolculuk-<id>`'ye yazılır, yarım kalırsa aynı seviyede sürer). Tanışma ve sorular Çalış'ın `TanismaGorunumu` / `KartGorunumu`'yla (sitede de aynı pekiştirme ekranı); tur sonu yerli: `GrupOzeti`, `BolumSonucuGorunumu` (sergi duvarı, madalyon, yıldızlar, dönem kutlaması, skor, salonlar, geçiş hapları).
  - `ZamanEkrani.swift`: **Galeri'nin sekmesi** (`GaleriYolu.zaman`, `#/zaman`; G3'ün Safari yaprağı kalktı): yapışkan panel, cetvel (çubuklar, çentikler, ibre, kenarlarda solma), akım akım liste.
- **Ortak dosyalarda küçük değişiklikler:**
  - `Calis/Pekistir/PekistirmeModeli.swift`: isteğe bağlı `disEylem`, `turBasligi`, `tanismaYazilari` (yalnız Yolculuk verir; Çalış'ta davranış aynı). `KartGorunumu`, `TanismaGorunumu` başlığı ve tanışma yazılarını buradan alır.
  - `Galeri/GaleriSekmesi.swift`: `GaleriYolu.zaman`; `SiteBolumu` ve `SFSafariViewController` kalktı.
  - `Hatirlatici.swift`: DEBUG `-izinSorma` (CI'da bildirim izni penceresi çıkmasın). `NoraSanatApp.swift`: DEBUG `YolculukProva.siteyiHazirla()` (eski Obj-C kurucu `YolculukSiteProva.m` silindi).
  - `Gecis.swift`'e dokunulmadı: **Yolculuk hâlâ yerli değil**; denetimden sonra Claude ekler.
- **CI karşılaştırması:** `-yolculukProva <ad>`; solda site (`-yalnizSite`), sağda yerli (`-yerliSekme yolculuk`; Zaman `-adres "#/zaman"` ile yerli Galeri'de). Hazır olunca `tmp/yolculuk-hazir`. Görüntüler `yan-yana-yolculuk-<ad>.png`: harita, zaman, kurs, motif, kilit, durak, tanisma, soru, cevap, grup-sonu, sergi, seviye-tamam. Tur provaları durak 4-1'de (Erken Rönesans), ilerleme yerlide yalnız bellekte; sitede sonda `geri-yukle`. Her açılışta `-izinSorma`.
- **Bilinen farklar / kalan:**
  - Hareketler: durakların yere konması, nabız, kıvılcımlar ve ışık sütunu, köprülerin kaydırmaya bağlı sis/yarık hareketi, sergide asılış ve sallanma (`sallanma.js`), yıldızların sırayla gelişi, yaldız yaprakları yok. Gündüz/gece geçişi anında.
  - Sembollerin ayak ölçümü (`ayakOlc`) yok: halka sembolün ortasında. Kontur filtresi (`#durak-kontur`) yerine açık bir gölge.
  - "Buradasın" hapı (şimdiki durak ekrandan çıkınca) yok. Köprü adları dönemin harfiyle (`harfUygula`) değil, Bodoni.
  - Sergide çerçeve türleri (`cerceveTipi`: kemer, tabernakel, barok…) yok, hepsi vurgu degradesi. "Hareketi aç" düğmesi yok.
  - Bölüm turunda sekme çubuğu görünür kalır (sitede de görünür).
- **Tuzaklar:**
  - `.position` uygulanan görünüm bütün kabı kaplar: `scrollTo` hedefi olarak dolguyla yerleştirilmiş ayrı 1×1 görünüm (`"konum"`) kullan.
  - Tur kaydı `BolumTuru` Codable; yeni alan eklersen isteğe bağlı yap (eski kayıt çözülemezse tur sıfırdan başlar).
- **CI:** a3a4da5 yeşil (https://github.com/emrymn/nora-sanat/actions/runs/45038413846): çekirdek 115 test (1 atlanan), derleme, bütün görüntüler. İlk koşu derlemede kaldı (`AkisDuzeni` adı Ben'dekiyle çakışıyordu → `OrtaliAkis`). On iki `yan-yana-yolculuk-*.png`'ye bakıldı: kurs, motif, durak, kilit ve Zaman sitedekiyle neredeyse birebir (aynı kart, yazı, renk, kırılım); tanışma, soru, cevap aynı bileşen (sorulan eser rastgele, farklı); grup sonu, sergi, seviye tamam sitenin düzeninde; hiçbirinde izin penceresi yok. Sonra düzeltilen: harita "buradasın"a kaymıyordu (ilk `scrollTo` düzenden önce; sitedeki gibi iki kez), grup sonu başlığı 48 → 40.


**Denetim (G5):** Claude, 2026-11-22 — **onay** (PR #20 yorumu). Linux'ta 115 test geçti; `yolculuk.mjs` site deposunda (`a866b86`) yeniden çalıştırıldı, çıktı `yolculuk/cevaplar.json` ile aynı. İlk ara denetimin 11 maddesi G5b'de yapıldı: 12 yan yana görüntüde harita, durak, kilit, kurs, motif, grup sonu, seviye tamam, sergi ve Zaman sitedekine çok yakın; Zaman Galeri'nin altında; bildirim penceresi yok; `.m` dosyası kalktı. Kalan küçük farklar (Z3'e): harita ilk kaydırma konumu ve üstteki durak simgesi; Tanış'ta sitede eser tam genişlik en üstte, yerlide üst şerit + başlık + çerçeveli eser; grup sonu başlığı yerlide büyük (3 satır, sitede 2); soru/cevapta eser sitedekinden küçük; sergide "Hareketi aç" düğmesi yok.

### Z3a · Yolculuk cilası (ChatGPT)

**Devir notu:** [PR #27](https://github.com/emrymn/nora-sanat/pull/27). Kaynak `sanat-atlasi@a866b86`, `js/ekranlar/harita.js`, `js/ekranlar/pekistir.js`, `js/sallanma.js` ve `css/app.css`.
- Harita dönemlerin yerleşimi tamamlandığında şimdiki durağın üst kenarına kayar. Kurs hapının yanındaki madalyon aynı durağın penceresini açar.
- Tanış ekranında tam genişlikte eser önce gelir. Küçük eser seçimi, büyütme ve sanatçılar arasında ilerleme korunur.
- Grup özeti başlığı 34 pt. Soru görseli ekran yüksekliğine göre, cevap görseli de başlık, seçenekler ve cevap yaprağından kalan alana göre boyutlanır.
- Sergide hareket düğmesi tablolara yer açar. Telefonda hareket açıldıktan sonra eğim asılara yansır. Hareketi azalt ayarı etkinse veya eğim kapalıysa algılayıcı başlamaz.
- Telefonda haritayı açıp madalyona dokun, bir grupla tanış, soruyu yanıtla ve sergide hareketi açıp telefonu eğ. Görünüş karşılaştırması için CI arşivindeki `yan-yana-yolculuk-{harita,tanisma,grup-sonu,soru,cevap,sergi}.png` dosyaları kullanılır.

### C5 · Çevrimdışı görseller (ChatGPT şeridi; kullanıcının isteğiyle Claude)
**Site kaynakları:** `js/devasaOnbellek.js`, Ayarlar'daki "En büyük kopyaları telefona indir" (`js/ekranlar/ayarlar.js`), `js/gorsel.js`, `js/eserler.js` `gosterilenGorseller`.

**Kapsam:** Arka planda indirme, boyut ve ilerleme göstergesi, durdurma, silme. İndirilenler uygulamanın görsel önbelleğinde önce kullanılır, internet yokken de görünür.

**Devir notu:** Claude, 2026-11-22 · [PR #21](https://github.com/emrymn/nora-sanat/pull/21) · dal `claude/eager-ramanujan-l5weox` (oturumun zorunlu dalı). C şeridi işi; kullanıcının isteğiyle Claude yaptı.
- **Kaynak:** sanat-atlasi `a866b86` (site 1.90.3). Taşınanlar:
  - `js/gorsel.js`: `devasaSuz`, `suzulduMu`, `devasaAdresleri`, `telefonAdresleri`, `tahminiBayt`, `telefonToplamBayt`, `B_ORTALAMA_BAYT`, `K_ORTALAMA_BAYT`
  - `js/eserler.js`: `gosterilenGorseller`
  - `js/ekranlar/ayarlar.js`: Ayarlar'daki `data-test="devasa-indir"` bölümü, `devasaBilgisi`, `devasaGoster`, `devasaIndir` (parça seçimi, `d.devasaIndirme`, bitiş kuralları), `devasaSurdur`, `devasaSil`, durdurma
  - `js/devasaOnbellek.js`: `kaliciYaz/Oku`, `kaliciAdresler` (listede olmayanların silinmesi, %20 koruması), `kaliciSil`, `defterAdi` (dosya adı kalıbı), `PARCA`
  - `css/app.css`: `.ayar .dugme`, `progress`, `.mesaj`, `.mesaj.hata`, `.mesaj.tamam`
  K7 farkı: `git -C /tmp/sa log a866b86..HEAD -- js/gorsel.js js/eserler.js js/ekranlar/ayarlar.js js/devasaOnbellek.js`
- **Çekirdek** (`NoraCekirdek/Cevrimdisi/`):
  - `CevrimdisiListe`: indirme listesi sitedeki sırayla (en büyük kopyalar, en büyüğü olmayanların 1280'likleri, bütün 400'lükler, kalan 1280'likler), `tahminiBayt`, `toplamBayt`, `parca(telefonda:)` (parça planı: ~0,7 GB ya da 1000 dosya, kaçıncı / kaç parça). Bugün: **5624 eser, 19 402 dosya, 21,0 GB, 33 parça** (iş tablosundaki "321 MB" eskiydi).
  - `CevrimdisiDurumu` (`d.devasaIndirme`, `bitir`), `CevrimdisiGorunum` (Ayarlar'ın açıklaması, iletisi, ileti rengi, İndir / Durdur / Telefondan sil düğmeleri, çubuk), `gb`.
  - `CevrimdisiDepo`: Application Support/CevrimdisiGorseller (Caches değil: iOS yer daralınca silmesin; iCloud yedeğine girmez). Dosya adı adresin türü ve adı (`d-<ad>[-sürüm].jpg`, `b-…`, `k-…`): klasörün listesi hangi adreslerin telefonda olduğunu söyler, defter gerekmez. `telefondakiler` listede olmayan eski sürümleri siler (sitedeki %20 korumasıyla).
  - `SiteKatalogu.gosterilenGorseller()`; `SiteKatalogu.onbellekSirasi` ve `GorselAdresleri.devasaListesi` eklendi (sıra için; T1 dosyalarında küçük değişiklik).
  - `GorselDeposu` (T3): bir adresi önce `CevrimdisiDepo`'da arar (`veri`, `diskte`). `UzakGorsel`, görüntüleyici ve büyük kopya hep buradan geçtiği için indirilenler internetsiz de görünür.
- **Uygulama** (`NoraSanat/Ekranlar/Ben/`):
  - `CevrimdisiIndirici.swift`: arka plan `URLSession` (`com.emrymn.norasanat.cevrimdisi`). Bir parçanın dosyaları birden verilir (aynı sunucuya 3 bağlantı, 90 sn zaman aşımı), parça bitince sıradaki başlar; uygulama arka plandayken ve iOS onu kapatınca da sürer, iş bitince iOS uygulamayı uyandırır, sıradaki parça orada verilir. Kullanıcı uygulamayı kaydırıp kapatırsa iOS görevleri iptal eder: açılışta kaldığı yerden sürer (sitenin `devasaSurdur`'u; işaret `UserDefaults` `cevrimdisi.surdur`, durum `cevrimdisi.durum`, liste `Application Support/CevrimdisiListe.json`). İnen dosya, yanıt 2xx ve `image/` ise temsilcide hemen yerine taşınır; yer yoksa indirme durur ("Telefonda yer kalmadı").
  - Açılışta sitenin eski indirmesi durdurulur ve sürdürme işareti (`sanat-atlasi:devasa-surdur`) silinir: gizli site artık arkada ayrıca indirmez. "Telefondan sil" sitenin eskiden IndexedDB'ye indirdiklerini de siler.
  - `BenCevrimdisi.swift`: bölüm `CevrimdisiIndirici` ve `CevrimdisiGorunum`'la; sıra sitedeki gibi (açıklama, düğmeler, çubuk, ileti). **C4b tuzağı kalktı:** Ayarlar açılınca gizli site artık `#/ayarlar`'a gitmiyor, bölüm sitenin sayfasını okumuyor.
  - `NoraSanatApp.swift` (ortak, küçük): `@UIApplicationDelegateAdaptor(NoraSanatUygulamaTemsilcisi.self)` (`handleEventsForBackgroundURLSession`; açılışta `baslat()`).
- **Kâhin:** `Testler/kahin/cevrimdisi.mjs` → `Ornekler/cevrimdisi/cevaplar.json`. Önce canlı sitenin veri dosyalarının `Ornekler/site_verisi/`'ndekilerle aynı olduğunu denetler (Swift testi listeyi oradan kurar). Sınananlar: listenin sayıları, **19 402 adresin sıralı MD5'i** ve her 97. adres, toplam bayt, `tahminiBayt`; sekiz "telefondakiler" kümesiyle parça planı (`devasaIndir`'in parça kodu kâhinde aynen); Ayarlar'ın açıklaması (telefonda 0 ve 5 görsel: sitenin IndexedDB'sine sahte kayıt) ve on indirme durumunun iletisi, ileti sınıfı, düğmeleri, çubuğu (sayfa her durumda yeniden çizilip okunur). `CevrimdisiTests` (8 test); Linux'ta paket testleri: 96 test, 1 atlanan. Listenin sırası bilerek bozulunca yakalıyor.
- **Bilinçli farklar:**
  - Açıklamanın "Wi-Fi’de indir." sonrası: sitede "her parçadan sonra uygulama kendini yenileyip…, iPhone kapalı uygulamanın indirmesine izin vermiyor"; uygulamada "uygulamadan çıksan da arka planda sürer; kaydırıp kapatırsan bir dahaki açışında kaldığı yerden devam eder" (`CevrimdisiGorunum.indirmeNotu`). Test o cümleye kadar karşılaştırır.
  - Parça bitince sitede sayfa yenilenir; burada sıradaki parça hemen başlar ("Parça 2 / 33 bitti · … Sıradaki parça başlıyor…").
  - Sitenin indirme izi / hata günlüğü (`izBirak`, `hataEkle`, `depoDurumu`, defter doğrulaması) yok: dosya sistemi güvenilir, defter gerekmiyor. "Kaydedilemedi" iletisinde sitenin hata adı yerine dosya sistemi hatası yazar.
  - Ekran açık tutma (`wakeLock`) yok: arka planda indiği için gerek yok.
  - Sitenin önceden IndexedDB'ye indirdikleri Swift'e taşınmaz (WebKit deposundan GB'larca veriyi köprüden geçirmek pratik değil); yerli ekranlar onları kullanmaz, taşınmamış site sekmeleri kullanmaya devam eder. Telefonda ikisi birden yer kaplayabilir; "Telefondan sil" ikisini de siler.
- **Tuzaklar:**
  - Arka plan oturumu tek kimlikle kurulur (`baslat()`, bir kez). Uygulama arka planda yeniden açılınca görevlerin sonuçları görev listesinden önce gelebilir (`erkenBiten`).
  - CI simülatöründe arka plan oturumu her dosyada `NSURLErrorDomain -1` (bilinmeyen hata) veriyor (arka plan aktarım servisi sanal makinede çalışmıyor). Böyle bir oturum hatasında (`-1`, `-996`, `-997`, paylaşılan kap) o dosya uygulama içi oturumla yeniden denenir ve o açılış boyunca uygulama içi oturum kullanılır (arka plana geçince `beginBackgroundTask` ile biraz süre). Telefonda arka plan oturumunun gerçekten çalıştığı (uygulamadan çıkınca sayının artması) yalnız telefonda sınanabilir; README'deki deneme listesinde.
  - Liste 19 bin adres: `toplamBayt` bir kez hesaplanır; her çizimde listeyi dolaşma.
- **CI:** 4ae9e00 yeşil (https://github.com/emrymn/nora-sanat/actions/runs/45012346929).
  - `yan-yana-ayarlar-cevrimdisi.png` (`-benKaydir cevrimdisi`, solda site): başlık, açıklama (sayılar aynı: 5624 eser, 19402 dosya, 21,0 GB, Telefonda: 0 / 19402), İndir düğmesi sitedeki gibi; yalnız "Wi-Fi’de indir." sonrası bilinçli farklı. OCR "Telefonda: 0 / " denetler.
  - `c5-cevrimdisi-indi.png` (`-cevrimdisiIndir -cevrimdisiParca 2`): iki en büyük kopya gerçekten indi (`d-8f8ae43f7bffc40f.jpg` 4,7 MB, `d-00061aac1c2ec3d5.jpg`), ekranda "Telefonda: 2 / 19402", "Telefondan sil" ve "Parça 1 / 3213 bitti". CI dosya sayısını ve OCR "bitti"yi denetler.
  - İlk koşular: arka plan oturumu simülatörde `NSURLErrorDomain -1` verdi (iki dosya da hata) → uygulama içi oturuma geri dönüş eklendi (tuzaklarda).
  - Öbür görüntüler (Ben, Galeri, Çalış, T5) eskisi gibi alındı.

**Denetim (C5):** Claude, 2026-11-22 — **onay** (PR #21 yorumu). Linux'ta 96 test geçti. `cevrimdisi.mjs` canlı sitede yeniden çalıştırıldı: cevaplar örnekle aynı (19 402 adresin sıralı MD5'i dahil). `yan-yana-ayarlar-cevrimdisi`: bölüm sitedekiyle aynı (yalnız bilinçli farklı indirme notu); `c5-cevrimdisi-indi`: iki en büyük kopya gerçekten indi, "Telefondan sil" ve ilerleme iletisi görünüyor. C4b'nin `#/ayarlar` tuzağı kalktı. Arka plan oturumunun telefonda çalıştığı yalnız telefonda sınanabilir (README).

### T5 · Hareket izni penceresi çıkmasın (Claude)
- Sorun: site (ya da yerli koddan çağrılan betik) `DeviceMotionEvent.requestPermission()` isteyince iOS'un "Harekete ve Yöne Erişmek İstiyor" penceresi çıkıyordu (C4b'nin ilk CI'ı, G2b'nin 5743b49 koşusu). `WebKabugu`'daki temsilci `.grant` dönüyordu ama `async` biçimiydi.
- Yapılan: temsilci tamamlama bloklu biçime geçti. CI: `-yalnizSite -hareketIzniDene` ile site izin ister; sonuç `granted` olmalı ve ekranda pencere (OCR "Erişmek") olmamalı (`t5-hareket-izni.png`).

**Devir notu:** Claude, 2026-11-21 · PR #17 · dal `claude/T5-hareket-izni`.
- `NoraSanat/WebKabugu.swift`: `Koordinator.webView(_:requestDeviceOrientationAndMotionPermissionFor:initiatedByFrame:decisionHandler:)` → `.grant`. DEBUG `-hareketIzniDene`: sayfa yüklenince `requestPermission()` çağrılır, sonuç `tmp/hareket-izni`'ye yazılır.
- CI (6a123c4 yeşil): "hareket izni: granted", görüntüde pencere yok. Bu adım artık her PR'da koşar; temsilci bozulursa CI kırmızı olur.
- Not: eski `async` biçimin neden yetmediği kesin değil (iki koşuda pencere çıktı, her koşuda değil). Yeni biçimle izin isteği hiç bekletilmeden cevaplanıyor.
- Telefonda: Bugün'de "Telefonu eğince tablo oynasın" açıkken uygulamayı kapatıp aç; izin sorusu çıkmamalı.

### T6 · Çalış yerli sekme (Claude)
- C1 + C2 + C3 bitti; Çalış `Gecis.tasinanlar`'a girer (`CalisGecisi.sekmeler`, `CalisSekmesi.swift`; DEBUG `-yalnizSite` ile site).
- CI: sitenin pekiştirme görüntüsü (`10s-site-pekistirme`) artık `-yalnizSite` ile; `4-url-calis` (widget → `norasanat://calis`) yerli Çalış'ı açar.

**Devir notu:** Claude, 2026-11-22. Bağlantılar C2/C3'te hazırdı (`yerliAdres[.calis]`, `yenidenDokunma`, `.sekmeCubuguGizli`); yalnız kayıt ve CI. Yerli olmayan sekmeler: Bugün (G4) ve Yolculuk (G5).

### T7 · Bugün ve Yolculuk yerli sekme (Claude)
- G4 + G4b ve G5 bitti; `BugunGecisi`, `YolculukGecisi` `Gecis.tasinanlar`'a girer. **Beş sekme de yerli**: site görünmez, yalnız ilerleme köprüsü için arkada (Z2'ye kadar). DEBUG `-yalnizSite` ile site.
- `SiteRotalari.yerliSekme` (testli): sitede sekmesiz sayfalar da yerli sekmeye gider: `#/pekistir/…` (tur, ders adımları; C3 #24 notu) Çalış'a, `#/karsilastir/…`, `#/akim-karsilastir/…` Galeri'ye. `#/pekistir/bolum/<id>/<seviye>` (Yolculuk bölüm turu) nil. `Gezgin.git` → `yerliyeGit` bunu kullanır: Galeri'deki "Pekiştir" (`#/pekistir/donem/<akım>`) T6'dan beri gizli siteye gidiyordu, artık yerli Çalış'ta turu açar.
- `SiteRotalari.secim`: sitenin bildirdiği adres öncekiyle aynıysa seçim değişmez. Bugün yerli olunca sitenin açılıştaki "#/" bildirimi widget'la açılmış sekmeyi Bugün'e çeviriyordu.

**Devir notu:** Claude, 2026-11-22. Bilinen: siteden yerli Yolculuk'a gelen adres yalnız haritayı açar (durak/bölüm adresle açılmaz).

### T8 · CI'ı paralel makinelere böl (Claude)
- Ekran görüntüsü adımı tek simülatörde sırayla ~55 dk (102 görüntü; G5 ile ~70, sınır 75). Uygulama bir kez derlenir (artifact), Ben / Galeri / Çalış+dersler / Bugün / Yolculuk / genel kontroller ayrı macOS işlerinde aynı anda çekilir. Depo açık: macOS dakikası ücretsiz.
- `derle` işi: kâhinler, paket testleri, derleme, uygulamanın içi; `.app` → `uygulama` arşivi. `ekran` matrisi (`galeri-1`, `galeri-2`, `calis`, `yolculuk`, `genel`, `ben`, `bugun`; uzunlar önce) her biri kendi simülatöründe `Testler/ci/ekran.sh <grup>`; görüntüler `ekranlar-<grup>` arşivinde (adlar eskisi gibi).
- Her grup temiz simülatörle başlar: ilk açılış, sonra (Ben, Galeri, Çalış, Yolculuk) T2'nin deneme ilerlemesi. Yeni ekran adımı eklerken ilgili grubun işlevine yaz; widget adresi (`4-url-calis`) `genel`in sonunda kalmalı.
- PR'ların CI'ını beklerken tek bir "derle" yerine bütün kontrol koşularına bak (8 iş).
- İlk koşu (c14c543): derle 3 dk; gruplar 10–23 dk; hesapta aynı anda çalışan macOS işi sınırlı (başka PR'ların CI'ıyla paylaşılıyor), bu yüzden toplam 51 dk. Galeri (23 dk) ikiye bölündü.

### Z3c · Galeri ve Çalış zemininde tablonun iki rengi (Claude)
- Kullanıcının isteği (2026-11-22): "başyapıtlarda arkaplanda ışıklı hale vardı… renk süzmeleri şeklinde". Kaynak: kullanıcının tasarım tuvali "Başyapıt Sayfası — Bütüncül Tasarım" (2026-11-16, Galeri · Başyapıtlar ve 1 · Açılış): `.zemin`'de tablonun iki renginden süzme, sol üstte %24 → %6 → 0 (120% 60%), sağ altta %16 → 0 (90% 50%). Sitede bu tek renge (vurgu) indi, İş 192'de üçte birine düştü (%10/%5). **Bilinçli fark, yalnız uygulama** (kullanıcı seçti).
- `TabloRenkleri.cift` (çekirdek, testli): tablonun 24 × 24 kopyasında 12 ton dilimi; ikisi de ağır ve en az 60° ayrık ikili, ağır olan sol üste; tasarımdaki açıklık/doygunluğa getirilir. Elçiler: kırmızı-kahve + zeytin yeşili (perde küçük kopyada zeytin).
- Kullanıcı: "o süzmeyi Çalış ve Galeri kısmının bütün arka planlarında istiyorum". Tasarım tuvalinde de Galeri · Akımlar (altın + mavi, Giotto) ve Çalış (mavi + altın) aynı zeminde.
- `SayfaZemini(tablo:alan:)`: sayfanın ana tablosundan iki süzme (Gündüz'de %60'ı). Ana tablo: Akımlar'da çarkın seçili salonunun kapağı, akım salonunda en bilinen eser, sanatçı sayfasında en bilinen eseri, konu sayfasında kapak, Başyapıtlar'da öne çıkan kartta görünen tablo, başyapıt sayfasında o tablo. Çalış'ın her sayfasında bugünün dersinin kapağı. Ana tablosu olmayan sayfalar (arama, koleksiyon, konular, bütün eserler, karşılaştırmalar) bölümde son bakılan tablonun renklerini sürdürür (`ZeminTablosu`); hiç yoksa eski tek renkli hale.
- Çalış'taki eski üst hale (`CalisSayfaHalesi`) kalktı.

### Z2 · Swift'e devir (Claude)
**Kapsam:**
- İlerleme tek seferlik Swift deposuna taşınır (Application Support'ta JSON; şema aynı kalır, yedek uyumlu).
- WKWebView ve `WebKabugu` kalkar.
- `TekrarKoprusu`'nun işi `Hatirlatici`'ye geçer: sayılar doğrudan Swift'ten hesaplanır.
- App-Bound Domains kaldırılır.

**Plan (kullanıcı onayladı, 2026-11-22):** üç PR.
- **Z2a · kurallar** (uygulama değişmez): `IlerlemeKurallari` (js/depo.js doğrulama, varsayılan, yedek metni/çözümü, günlük, son çalışılanlar, yedek hatırlatması, en yeni kayıt, geliştirici modu) ve `IlerlemeDosyasi` (Application Support'ta `ilerleme.json` + `onceki.json`, artan `kayitNo`, çakışma, bozuk kaydı saklama, okunamazsa kilit).
- **Z2b · geçiş**: ilk açılışta site ilerlemesi bir kez okunup Swift dosyasına yazılır (site verisi silinmez). `IlerlemeKoprusu` aynı arayüzle dosyaya döner; Ben'in site betikleri (yedek, geri yükleme, ayar bilgisi, hareket izni…), rozet, tema/hareket ayarları ve `TekrarKoprusu` sayıları Swift'ten. Site yalnız taşıma için yüklenir.
- **Z2c · temizlik**: `WebKabugu`, köprüler, App-Bound Domains kalkar; site yalnız DEBUG `-yalnizSite` ile (CI karşılaştırmaları).
- Kullanıcı Z2b'yi yüklemeden önce Ben → Ayarlar → Yedekle ile yedek alır; yükledikten sonra işlenen konular, tekrar sayısı ve yarım turun aynı olduğuna bakar.

**Z2a devir notu:** Claude, 2026-11-22.
- `NoraCekirdek/Ilerleme/IlerlemeKurallari.swift`: kurallar JSONDeger üzerinde, sitenin alt doğrulamaları dahil (karisanlar, seviyeler + birleşen akımlar, dersler, geçmiş, koleksiyon, harita görülenleri, bölümler, bildirimler). JS ayrıntıları birebir: `parseInt`, doğruluk, `{...x}` yayılımı (dizi/metin), `Math.round`, UTF-16 sıralama ve uzunluk. Bilinmeyen üst düzey alanlar sitedeki gibi atılır (Swift'e özel her şey `ayarlar` içinde durmalı: ör. `calis.tur`).
- Kâhin `Testler/kahin/depo.mjs` (Node, tarayıcısız): 413 doğrulama vakası (96'sı sitenin hata metniyle), 25 yedek metni, 15 çözüm, 57 küçük kural, 20 en yeni kayıt, 12 geliştirici aç/kapat. Hepsi aynı.
- Tuzak: sitenin doğrulaması tam sabit değil (`derslerDogrula` günü olup ilerlemesi 0 olan adımı ilk geçişte `{i:0}` bırakır, ikincide siler); test "iki geçişten sonra sabit".
- `IlerlemeDosyasi` testleri: yaz/oku, önceki kopya, çakışma, bozuk ana kayıttan öncekine dönüş (bozuk dosya saklanır), hiçbir kopya okunamazsa kilit.

**Z2b devir notu:** Claude, 2026-11-22.
- `IlerlemeKoprusu` (`oku`, `yaz`, `degistir` aynı): kayıt `Application Support/Ilerleme/ilerleme.json`. İlk çağrıda dosya yoksa sitenin `d.ilerleme`'si okunup doğrulanır ve yazılır (taşıma; site kaydı okuyamayıp kilitlediyse `kayitKilitliMi` taşınmaz, `.kilitli`). Site açılmazsa `.siteYok`, sonraki çağrıda yeniden denenir; boş ilerleme hiç yazılmaz.
- **Ayna:** her yazımdan sonra `aynaBetigi` kaydı sitenin belleğine ve deposuna yazar (`kaydet`, `temaUygula`). Sitenin hâlâ okuduğu şeyler bu sayede doğru: `TemaKoprusu` (renkler), `SekmeCubuguKoprusu.rozet`, `TekrarKoprusu` (localStorage), Ben'in site betikleri (`benBetigi`), CI'daki `-yalnizSite` karşılaştırmaları. Site betiği çalıştırmadan önce `aynaBitsin()`.
- Swift'e geçenler: Yedekle (`yedekAl`: `sonYedek` + `yedekMetni`), yedeği denetle (`yedekCoz`), Geri yükle (`geriYukle`: numara denetimi, kilit açılır), Geliştirici modu (`gelistirici`; konu/bölüm listeleri hâlâ siteden), hızlı ayarlar (`SekmeCubuguKoprusu.ayarlar/yaz`).
- Sitenin yarım oturumu (`d.yarim`) taşınmaz: yerli turlar zaten `ayarlar['calis.tur']`'da. Yedekteki `yarimOturum` yok sayılır.
- Kâhin `ilerleme_koprusu.mjs`: taşıma okuması ve ayna canlı sitede (Chromium) geçti.
- Z2c'ye kalan site okumaları: `TemaKoprusu` (renkli Gündüz, tablonun vurgusu: js/renk.js), rozet (`turBilgisi`), `TekrarKoprusu` (takvim), Ben: ayar bilgisi, günün sanatçısı değiştirme, hata günlüğü, elle odaklar, hareket izni, geliştirici listeleri; `BugunDeposu` odak/gündüz rengi.
- **Z2c-2 devir notu** (Claude, 2026-11-23): js/renk.js + js/gunduzRenk.js + kontrast Swift'te: `ResimRengi`, `GunduzPaleti` (`Tema/ResimRengi.swift`), `TemaRenkleri.hesapla/zeminHex`; kâhin `renk.mjs` (70 tablo, 200 renk). Uygulamada `NoraSanat/Kabuk/TemaHesabi.swift`: ayarlar kayıttan, vurgu günün tablosunun paletinden (sitenin `gununRengi`'si; görsel yoksa akım rengi), otomatik Gündüz tablonun renk ailelerinden; paletler UserDefaults'ta saklanır (açılışta beklemeden). `TemaKoprusu` ve themeColor gözlemi kalktı. Fark: site her ekranda o ekranın eserinden renk alır (`ekranRengi`); uygulama şimdilik her yerde günün rengini kullanır (daha önce de gizli sitenin o anki rengiydi).
- **Z2c-3a devir notu** (Claude, 2026-11-23): Ben → Ayarlar ve Bugün siteye sormaz. `OdakVerisi` (js/gorsel.js odak önceliği, `yuruyusEki`; `Bugun/OdakVerisi.swift`, testli), `GununSanatcisi.baska`, `GununTablosuCozucu.havuz`; uygulamada `ElleOdaklar` (UserDefaults; sitenin localStorage'ındakiler site yüklenince bir kez alınır), `BenDeposu.ayarBilgisi/baskaSanatci/siteSurumu/veriyiYenile/gelistiriciListeleri`. Kalkanlar: hata günlüğü ve Yenilikler bölümleri (sitenin kendi günlüğü ve sürüm notları), hareket izni (CoreMotion izin istemez), `d.oturum = null` / `temaUygula` betikleri. Kalan: "Sırayla ortala" sitenin görüntüleyicisini açıyor → Z2c-3b (yerli "Odağı işaretle"), sonra site kalkar.
- **Z2c-3b devir notu** (Claude, 2026-11-23): site uygulamadan kalktı: `WebKabugu.gerekli` (ilerleme dosyası yoksa — taşıma —, cihazdaki elle odaklar henüz alınmadıysa ya da DEBUG `-yalnizSite`) değilse `KokGorunum` siteyi hiç kurmaz; `hazirSite` beklemeden `siteYok`, ayna yapılmaz. Site yüklenince `IlerlemeKoprusu.siteYuklendi()` dosyadaki kaydı bir kez siteye yazar (CI'daki site karşılaştırmaları güncel veriyi görür). Görüntüleyicide yerli "Odağı işaretle" / "Bitti" / "Otomatiğe dön", Tuval çerçevesi ve odak durumu (geliştirici modunda ve `ortalama`'da); Ayarlar → "Sırayla ortala" yerli görüntüleyiciyi açar (`BenDeposu.yuruyusEserleri`). Sitenin cihazdaki deposu (localStorage, IndexedDB) silinmez: eski ilerlemenin yedeği olarak durur. Kalan Z3 işleri: site her ekranda o ekranın eserinden renk alır (`ekranRengi`), uygulama günün rengini; App-Bound Domains ve DEBUG karşılaştırma altyapısı CI için kalır.

**Z2c planı** (Claude, 2026-11-23; kullanıcı: "direkt sen yap hepsini"):
- **Z2c-1 · sayaçlar**: Çalış rozeti (`CalisKurallari.turBilgisi`), simge rozeti (`Gecmis.vadeSayisi`/`yarinVade`) ve tekrar takvimi (`TekrarTakvimi.hesapla`, kâhin `tekrar_takvimi.mjs`) Swift'te: `NoraSanat/Kabuk/SayacDeposu.swift`. `TekrarKoprusu.swift`, sitenin rozet/izin köprüleri ve `sekme_cubugu.mjs`'nin köprü bölümü kalktı.
- **Z2c-2 · renkler**: js/renk.js (`paletHesapla`, `vurguSec`, `renkTemasi`, `tonlariHesapla`) ve js/gunduzRenk.js (`resimdenPalet`, hazır paletler) Swift'e; `TemaDeposu` renkleri siteden değil ayarlardan ve günün tablosundan hesaplar.
- **Z2c-3 · site kalkar**: Ben'in kalan betikleri, Bugün odak rengi, Galeri/Ben bekleme betikleri; `WebKabugu` yalnız DEBUG `-yalnizSite`'ta.

### Z3 · Cila + yetişme (Claude)
**Kapsam:**
- K7'ye göre sitedeki değişikliklerin taşınması.
- Erişilebilirlik (VoiceOver, Dinamik Yazı).
- Son karşılaştırma: sitedeki her ekranla yan yana ekran görüntüsü.

**Devir notu:** –

### Z3b · Ders ve yazı cilası
- C3 (PR #24 yan yanası) ve G4b'deki "Tuzak"tan kalan farklar: Ders Gör ve Öğren adımlarının görünüşü, ortak `Yazi.Aile.satirOrani` (Newsreader).
- `Gecis.swift`, `Kabuk/`, `Ekranlar/Yolculuk/` ve `.github/workflows/ios-derle.yml`'e dokunulmaz.

**Devir notu:** Claude, 2026-11-22 · [PR #29](https://github.com/emrymn/nora-sanat/pull/29) · dal `is/Z3b-ders`. C şeridi işi; kullanıcının isteğiyle Claude yaptı.
- **Kaynak:** sanat-atlasi `a866b86`: `css/app.css` (`h1, h2, h3 { text-wrap: balance }`, `.ders-ust`, `.ders-gor .ders-ust`, `--ust-bosluk`, `.ders-gor-panel`, `.ders-gor-panel h2`, `.ders-alt-cubuk`, `.ders-madde`, `.ders-soru`), `js/ekranlar/ders.js` (`gorAdimi`, `ogrenCiz`, `altCubuk`).
  K7: `git -C /tmp/sa log a866b86..HEAD -- css/app.css js/ekranlar/ders.js`
- **Kök neden (Gör'de büyük eser + aşağıdaki panel, Öğren'de görünmeyen Açıklama):** Kabuk (`KokGorunum`) her yerli sekmeye sekme çubuğu kadar alt pay ekliyor (`safeAreaInset`, ~74 pt); adım ekranında çubuk gizliyken de kalıyordu. Gör paneli ve Öğren'in alt çubuğu 74 pt yukarıdaydı; Gör'de kamera alanı daraldığı için eser büyük, Öğren'de Açıklama alt çubuğun altında. `DersAdimEkrani` artık bu payı yok sayar (`ignoresSafeArea(.container, edges: .bottom)`) ve yalnız pencerenin alt güvenli alanını koyar (`safeAreaPadding`), sitedeki `env(safe-area-inset-bottom)` gibi. Kabuk'a dokunulmadı; çubuğu gizleyen öbür yerli ekranlarda da aynı pay olabilir (ör. Pekiştirme, Karşılaştır) → Z3'te Kabuk'ta genel çözüm (çubuk gizliyken pay 0).
- **Gör üst çubuğu:** `.ders-gor .ders-ust`'ta `--ust-bosluk` çubuğun kendi dolgusu ve `min-height: 52px` border-box: içerik ortalanmaz. `DersAdimUst(sahne: true)` en az yüksekliksiz (4 pt yukarı; site 77.3, yerli 81 → 77.3).
- **`CssBaslik` (`DersAdimOrtak.swift`):** çok satırlı serif başlık; her sözcük ayrı `Text`, `CssBaslikDuzeni` (Layout) açgözlü kırar, birden çok satırda satır sayısını artırmayan en dar genişliği arar (`text-wrap: balance`), her satırı CSS `line-height` yüksekliğinde, yazı ortada dizer. Bodoni'nin 1.525 em'lik kendi satırı artık başlık satır arasını açmıyor (C3'teki "SwiftUI eksi lineSpacing'i yok sayıyor" sorunu). Kullananlar: Gör başlığı (28/30.8), Öğren maddesi (27/31.05), Ayırt et sorusu (26/29.9). Erişilebilirlikte tek öğe (metnin tamamı). Başka ekranlardaki çok satırlı Bodoni başlıklar da buna geçebilir (gerekirse ortak bir yere taşınır).
- **`Yazi.Aile.satirOrani`:** Newsreader 1.0 → 1.0247 (G4b'deki ölçüm). Bugün'ün yerel `bugunOkumaSatiri`'si kalktı, iki yer `cssSatir(.okuma, …)`'ya bağlandı (Bugün görüntüleri piksel piksel aynı kaldı). Uzun okuma metinlerinde satır başına ~0.4 pt daralma: Galeri Karşılaştır'da Giotto sütunu sitedekiyle aynı yerde bitiyor (önce ~6 pt aşağıdaydı). Yolculuk da `cssSatir(.okuma)` kullanıyor, dosyalarına dokunulmadı.
- **CI 0f1c683 yeşil.** Yan yana: Gör (eser, başlık "Aziz Maxima ve Aziz / Ansanus ile Müjde (Triptik)", metin, noktalar, düğme) ve Öğren (başlık "Altın zemin ve ahşap / pano üzerine tempera", Açıklama, alt çubuk) sitedekiyle ±1–2 pt. Eski koşuyla karşılaştırma: Ben, Ayarlar, Bugün, Çalış ana/turlar/yük/salon, Galeri ana/konu/ara aynı; Ayırt et, İlerleme, Turlar'daki farklar rastgele seçilen resimler (düzen aynı).
- **Kalan:** dolu düğmenin rengi yerlide temanın `vurguAcik`'i, site o sayfada nötr `--vurgu-acik` (C3'ten, Z3). Öğren'de eserin alt yazısı (Archivo 13) bir sözcük farklı kırılıyor ("Sahneler ·" / "· 1235"). Kanıt kutusu ~2 pt aşağıda (Archivo'nun 1.088 oranı yuvarlaması).


**Denetim:** Claude, 2026-11-21 — **onay** (PR #12 yorumu).
- Linux'ta 75 test geçti.
- `sekme_cubugu.mjs` ve `kabuk_koprusu.mjs` canlı sitede yeniden çalıştırıldı: cevaplar aynı. Rozet köprüsü sitenin rozetiyle aynı (8 = 8).
- CI: `8-yerli-sekme` ile `8b-site-cubuk` alttan kesilip üst üste kondu; simgeler, yerleşim, hap, Çalış rozeti ve dişli dil birebir. `8c-hizli-ayar` sitenin üslubunda.
- 1–10 ve Ben görüntüleri eskisi gibi. Telefonda hiçbir sekme yerli değil, uygulama aynı.
- Hızlı ayar yaprağı kapsam dışı değil: sitenin çubuğundaki dişli dil onu açıyor.

### Z3m · Ekran rengi ve odaklı kırpma (Claude)
**Devir notu:** Claude, 2026-11-24 · [PR #46](https://github.com/emrymn/nora-sanat/pull/46) · dal `claude/Z3m-ekran-rengi`. Z3l'in (#44) üstüne kuruldu (`TemaHesabi.pikseller` orada dışa açıldı); #44 birleşince main dala alındı.
- **Kaynak:** sanat-atlasi `cca62eb`: `js/ekranlar/ortak.js` (`ekranRengi`, `renkSabitle`, `gununRengi`, `eserPaleti`, `renkleriYaz`, `odakliGorsel`, `odagaKaydir`, `kucukGorsel { odak }`, `odaklariYukle`), `js/renk.js` (`paletGetir`, `renkTemasi`), `js/gorsel.js` (`paletUrl`, `gorselOdakNoktasi`, `gorselOdagi`), çağıranlar: `js/ekranlar/gozat.js` (`sanatciSayfasi`, `tumEserler`, `konuSayfasi`, `karsilastirSayfasi`, Başyapıtlar kartı ve sahnesi), `js/ekranlar/basyapit.js` (`basyapitSayfasi`, sıradaki ve kıyas görselleri), `js/ekranlar/ders.js` (`kapaklariDoldur`), `js/ekranlar/pekistir.js` (`kartCiz`, ters soru), `js/ekranlar/soruTurlari.js`, `js/ekranlar/akim.js` (sahne).
  K7: `git -C /tmp/sa log cca62eb..HEAD -- js/ekranlar/ortak.js js/renk.js js/gorsel.js js/ekranlar/gozat.js js/ekranlar/basyapit.js js/ekranlar/ders.js js/ekranlar/pekistir.js js/ekranlar/soruTurlari.js`
- **Ekran rengi** (`NoraSanat/Kabuk/EkranRengi.swift`): `.ekranRengi(url:yedek:notr:)` ortamdaki `TemaDeposu`'nun yerine aynı temayı, vurgusu o eserin paletinden bir kopya koyar (`TemaRenkleri.ekran`, çekirdek, testli). Ekranın kendi gövdesi de `tema.renkler` okuduğu için değiştirici ekranın **dışında**, kurulduğu yerde verilir. Palet gelene kadar önceki renk durur (sitede de); görsel açılmazsa yedek (`ResimRengi.eserPaleti`), yedek yoksa nötr; eser de yedek de yoksa ortamın rengi. Geçiş 0,45 sn, hareket azaltılmışsa (ayar ya da sistem) anında. Paletler bellekte (`EkranPaletleri`).
  - Galeri (`GaleriSekmesi.hedefSayfa`): sanatçı, tüm eserler, karşılaştırma (ilk eser, yedek akım rengi), konu (kapak, yedek `#8A827A`), yakın okuma (eser, yedek akım rengi).
  - Çalış (`CalisSekmesi`): giriş bugünün dersinin kapağından (`CalisAnaGorunumu.dersler`, gövdedeki hesap buraya çıkarıldı), ders sayfası ve adımları o dersin kapağından (sitede adımlar renk yazmaz, ders sayfasının rengi sürer). Kapak yoksa renk değişmez.
  - Pekiştirme ve soru turu kartları (`PekistirmeEkrani`): sorulan eser, yedek yok; ters soruda cevaptan önce nötr. Değiştirici kartın `.id`'sinin dışında: kart değişince önceki kartın rengi yenisi gelene kadar durur.
  - Sekme ana ekranları, Pekiştir menüsü (dönem turları), tanışma ve öbürleri günün rengini (`TemaHesabi`) taşır.
- **Odaklı kırpma:** `OdakliKirpim.yerlesim` (çekirdek, testli): `object-fit: cover; object-position: x% y%` (taşan pay × yüzde; odak yoksa ortadan). `OdakVerisi.odak(eser, adresler:, kotuler:)`: gösterilen görselin yerel adıyla odak. `UzakGorsel(odak:)` (isteğe bağlı), `GorselOdaklari` (odak dosyaları bir kez; cihazdaki elle odaklar her okumada), `OdakliGorsel`; Galeri'de `GaleriResim.odakli(e, boy)`: Başyapıtlar kartları ve öne çıkan sahne, yakın okumada sıradaki ve kıyas görselleri, akım sahnesi.
- **Ortak dosyalarda küçük değişiklik:** `Tema.swift` (`TemaDeposu.gunduz`, iki `init`, `uygula(gunduz:)`), `TemaHesabi.swift` (`gunduz: g` geçiyor), `Gorsel.swift` (`UzakGorsel.odak`).
- **Bilinen farklar / kalan:**
  - Sitede `--vurgu` belgenin kökünde değişir, sekme çubuğu da dahil; uygulamada yalnız ekranın altı (sekme çubuğu vurgu kullanmıyor, fark görünmez). Sitenin Gündüz'deki `--golge-rgb`'si (`golgeyiYaz`) taşınmadı (uygulamada karşılığı yok).
  - Palet adresi 400'lük kopya (`gorselAdresi(e, 400)`); sitenin `paletUrl`'si yerel kopyası olmayan Commons görselinde `commonsKucuk(PALET_GENISLIGI)` kullanır. 64 piksele küçültüldüğü için palet aynı ya da çok yakın.
  - Paletler cihazda saklanmıyor (sitede IndexedDB); uygulama açıldıktan sonra her eser bir kez hesaplanır.
  - Odaklı kırpma Yolculuk'taki Zaman kartlarında (`gozat.js` zaman fonu) ve Çalış'taki ders/salon kapaklarında yok (o dosyalar bu işin dışında / başka oturumda). Yakın okumanın kapağı sitede de kırpılmaz.
- **Ayrıca:** sanatçı künyesindeki "Dinle" yazısı sitedeki gibi `--vurgu-acik` (`.isim-ek .dinle`; önce vurgu ile mürekkebin karışımıydı, eserin rengi görünmüyordu).
- **CI:** abf7c6d yeşil (8 iş, 151 çekirdek testi). İlk koşu derlemede kalmıştı (`CalisAnaGorunumu`'nda yardımcıya taşınan `bugunkuAkim`). Galeri yan yana görüntülerinde (sanatçı, akım) düzen siteyle aynı.

---

## Yeni özellikler (Y): sitede olmayan, iPhone'a özgü

Taşımadan ayrıdır; sitede karşılığı olmadığı için kâhin yerine davranış testi ve CI görüntüsü yeter. Şerit iş verilince seçilir.

### Y1 · Sesli rehberli bakış
**Fikir (kullanıcı, 2026-11-21):** Bir tabloya dokunmadan, uzun ve yavaş bakmak. Rehber sesle anlatır, tablo kendiliğinden ayrıntıdan ayrıntıya süzülür.

**Yapılacaklar:**
- **Kaynak.** Var olan içerik kullanılır:
  - G1'in ayrıntı noktaları (`eser_ayrintilari.json`, `AyrintiKurallari.noktaOdagi`);
  - G4'ün resmin içinde yürüyüşü (`yuruyus.json`);
  - eser notu ve hikâye (`eser_notlari.json`, `eser_hikayeleri.json`).
- **Akış.**
  - Açılışta tablonun tamamı ve künyesi okunur.
  - Sonra her noktaya yavaşça yaklaşılır (20–40 sn), noktanın metni okunur, kısa bir sessizlik bırakılır.
  - En sonda tablonun tamamına dönülür.
  - Süre seçilir: 3 / 5 / 10 dk. Nokta yoksa yalnız not ve hikâyeyle, tablo üzerinde yavaş gezinerek.
- **Ses.**
  - `AVSpeechSynthesizer`, Türkçe ses; telefonda varsa "gelişmiş" ses seçilir.
  - Arka planda kesintisiz çalar (ses oturumu).
  - Kilit ekranında ve kulaklıkta duraklat / sonraki (`MPRemoteCommandCenter`, Now Playing'de tablonun resmi).
  - Sessiz seçeneği: yalnız yazı altyazı gibi.
- **Ekran.**
  - Mod sürerken sönmez (`isIdleTimerDisabled`).
  - Hareket azaltılmışsa yakınlaşma yerine yumuşak geçiş.
  - StandBy'da ve AirPlay'de (televizyon) tam ekran.
- **Bitiş.** "En çok neye baktın?" gibi kısa bir soru ya da o sanatçının tekrar kartı.
- **Giriş yerleri.** Görüntüleyicide "Dinleyerek bak" düğmesi; günün tablosu; widget ve Siri ("günün tablosuna bak").

**Devir notu:** –

### Fikir havuzu (henüz iş değil)
- Bildirimde soru (tekrar hatırlatmasında resim ve şıklar)
- Spotlight'ta sanatçı ve eser araması
- Kilit ekranı ve StandBy widget'ı
- Kısayollar / Siri eylemleri
- Günün tablosu duvar kâğıdı (Kısayollar otomasyonu)
- Müzeye yaklaşınca bildirim
- Paylaş menüsü
- Paylaşılabilir eser kartı
- Görsel Arama (Live Text)
- Arka planda çevrimdışı indirme (C5 ile)
- Etkileşimli widget
- Kamerayla tablo tanıma (büyük)
- Gerçek boyutta AR (büyük)
- Mac'te açma
- Apple Watch (büyük)

