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
| C1 | Pekiştirme oturumu (kartlar, sorular) | C | T2, T3 | 2 | C1a bitti (#7), C1b bitti (#9), C1c bekliyor |
| G2 | Galeri: akımlar, sanatçı, eserler, arama, koleksiyon | G | T3, G1 | 2–3 | bekliyor |
| C1c | Pekiştirme: tanışma ve eksik adımlar | C | C1b | 1 | bekliyor |
| C2 | Çalış ana ekranı | C | C1 | 1 | bekliyor |
| G3 | Başyapıtlar: liste ve yakın okuma | G | G2 | 1 | bekliyor |
| C3 | Dersler (Gör, Öğren, Ayırt et) + eser dersleri | C | C2, G1 | 2 | bekliyor |
| G4 | Bugün (Tuval) + resmin içinde yürüyüş | G | T3, G1 | 2 | bekliyor |
| C4 | Ben: İlerleme, Ayarlar, yedekle/geri yükle | C | T3 | 1–2 | bitti (#10) |
| C4b | Ben: görünüş sitedeki gibi (K5) | C | C4, T4 | 1 | bekliyor |
| G5 | Yolculuk haritası + Zaman | G | T3, C1 | 2 | bekliyor |
| C5 | Çevrimdışı görseller (321 MB) | C | C4 | 1 | bekliyor |
| T4 | Yerli sekme çubuğu sitenin çubuğu gibi | K | T3 | 1 | PR açık (#12) |
| Z2 | İlerlemeyi Swift'e al, WKWebView'i kaldır | K | hepsi | 1 | bekliyor |
| Z3 | Cila + sitedeki son değişikliklere yetişme | K | Z2 | 1 | bekliyor |
| Y1 | Sesli rehberli bakış (yeni özellik) | – | G1, G4 | 1 | fikir: kullanıcı başlatınca |

**Sekmeler ne zaman yerli olur:**
- Galeri: G1 + G2 + G3
- Bugün: G4
- Yolculuk: G5
- Çalış: C1 (C1a, C1b, C1c) + C2 + C3
- Ben/Ayarlar: C4 + C4b (görünüş)
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

**Devir notu:** –

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

**Devir notu:** –

### C2 · Çalış ana ekranı (ChatGPT)
**Site kaynakları:** `js/ekranlar/calisma.js`, `js/deste.js`.

**Kapsam:** Bugünün dersi kartı, günlük tekrar, başka turlar, 14 günlük yük grafiği.

**Devir notu:** –

### G3 · Başyapıtlar (ChatGPT)
**Site kaynakları:** `js/basyapit.js`, `js/basyapitSayfa.js`, `js/ekranlar/basyapit.js`.

**Kapsam:** Liste (dönem sekmeleri), yakın okuma sayfası, yan yana karşılaştırma.

**Devir notu:** –

### C3 · Dersler (ChatGPT)
**Site kaynakları:**
- `js/ders.js`, `js/dersIcerik.js`, `js/eserDersi.js`, `js/kamera.js`
- `js/ekranlar/ders.js`, `js/ekranlar/dersVerisi.js`, `js/ekranlar/eserDersi.js`
- `basyapit-dersleri/` (Markdown → SwiftUI)

**Devir notu:** –

### G4 · Bugün (ChatGPT)
**Site kaynakları:**
- `js/ekranlar/bugun.js`, `js/yuruyus.js`, `js/egim.js`, `js/gunduzRenk.js`, `js/renk.js`, `js/gunun.js`
- Seçim kuralı Swift'te zaten var: `NoraCekirdek/GununSanatcisi.swift`.

**Kapsam:**
- Günün tablosu, perde açılışı.
- Resmin içinde yürüyüş (kaydırdıkça ayrıntıdan ayrıntıya), eğim hareketi.
- Hayatı, bugünkü tur kartı.

**Devir notu:** –

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

**Devir notu:** –

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

**Devir notu:** –

### C5 · Çevrimdışı görseller (ChatGPT)
**Site kaynakları:** `js/devasaOnbellek.js`, Ayarlar'daki "Görselleri çevrimdışı indir".

**Kapsam:** Arka planda indirme, boyut ve ilerleme göstergesi, iptal.

**Devir notu:** –

### Z2 · Swift'e devir (Claude)
**Kapsam:**
- İlerleme tek seferlik Swift deposuna taşınır (Application Support'ta JSON; şema aynı kalır, yedek uyumlu).
- WKWebView ve `WebKabugu` kalkar.
- `TekrarKoprusu`'nun işi `Hatirlatici`'ye geçer: sayılar doğrudan Swift'ten hesaplanır.
- App-Bound Domains kaldırılır.

**Devir notu:** –

### Z3 · Cila + yetişme (Claude)
**Kapsam:**
- K7'ye göre sitedeki değişikliklerin taşınması.
- Erişilebilirlik (VoiceOver, Dinamik Yazı).
- Son karşılaştırma: sitedeki her ekranla yan yana ekran görüntüsü.

**Devir notu:** –

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
