# Nora Sanat → tamamen Swift: iş dağılımı

Bu dosya Claude, Gemini ve ChatGPT'nin ortak iş listesi ve raporudur. Oturumlar birbirini görmez; **her şey burada yazılıdır.**
Her iş ayrı bir oturumda yapılır. **İşi bitiren, bu dosyada kendi işinin durumunu ve devir notunu yazar** (rapor budur).

**Kim ne yapar:**
| Şerit | Araç | Görev |
|---|---|---|
| **K** | Claude (iki hesap) | Temel işler (T1–T3, Z2, Z3) ve **her PR'ın denetimi** |
| **G** | Gemini (Jules ya da Gemini CLI) | Görsel ağırlıklı ekranlar: G1–G5 |
| **C** | ChatGPT (Codex) | Çalışma ağırlıklı ekranlar: C1–C5 |

G ve C şeritlerinin işleri **birbirinden ayrıdır**: farklı sekmeler, farklı klasörler (K6). Aynı dosyaya dokunmazlar.

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
6. İlk commit'te tablodaki durumunu `sürüyor (Araç, tarih)` yap. Örnek: `sürüyor (Gemini, 2026-11-21)`.
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

### Bilgisayarında Xcode yoksa (Gemini, ChatGPT ve Claude için aynı)
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
- Her araç **kendi şeridindeki** işleri yapar: Claude K, Gemini G, ChatGPT C. Hangi işi yapacağını kullanıcı mesajında adıyla verir.
- Bağımlılığı bitmemiş işe başlanmaz. G ve C, temel (T1–T3) birleşene kadar bekler. Sadece G1, T1'den sonra başlayabilir.
- Aynı anda yürüyebilecek işler tablodaki bağımlılıklardan okunur. İki oturuma aynı iş verilmez.
- Tahmini süreler "oturum" cinsindendir. Bir oturum bir PR demektir.

| ID | İş | Şerit | Bağımlılık | Oturum | Durum |
|----|----|-------|------------|--------|-------|
| T1 | Site verisi ve görsel adresleri | K | – | 1–2 | bitti (#4) |
| T2 | İlerleme köprüsü + tekrar kuralları | K | – | 1–2 | bitti (#5) |
| T3 | Kabuk: yerli sekmeler, tema, görsel önbelleği | K | T1, T2 | 1 | bekliyor |
| G1 | Tam ekran görüntüleyici | G | T1 | 1–2 | bekliyor |
| C1 | Pekiştirme oturumu (kartlar, sorular) | C | T2, T3 | 2 | bekliyor |
| G2 | Galeri: akımlar, sanatçı, eserler, arama, koleksiyon | G | T3, G1 | 2–3 | bekliyor |
| C2 | Çalış ana ekranı | C | C1 | 1 | bekliyor |
| G3 | Başyapıtlar: liste ve yakın okuma | G | G2 | 1 | bekliyor |
| C3 | Dersler (Gör, Öğren, Ayırt et) + eser dersleri | C | C2, G1 | 2 | bekliyor |
| G4 | Bugün (Tuval) + resmin içinde yürüyüş | G | T3, G1 | 2 | bekliyor |
| C4 | Ben: İlerleme, Ayarlar, yedekle/geri yükle | C | T3 | 1–2 | bekliyor |
| G5 | Yolculuk haritası + Zaman | G | T3, C1 | 2 | bekliyor |
| C5 | Çevrimdışı görseller (321 MB) | C | C4 | 1 | bekliyor |
| Z2 | İlerlemeyi Swift'e al, WKWebView'i kaldır | K | hepsi | 1 | bekliyor |
| Z3 | Cila + sitedeki son değişikliklere yetişme | K | Z2 | 1 | bekliyor |

**Sekmeler ne zaman yerli olur:**
- Galeri: G1 + G2 + G3
- Bugün: G4
- Yolculuk: G5
- Çalış: C1 + C2 + C3
- Ben/Ayarlar: C4

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

**Devir notu:** –

### G1 · Tam ekran görüntüleyici (Gemini)
**Site kaynakları:** `js/goruntuleyici.js`, `js/ayrinti.js`, `js/hikaye.js`, `js/keskin.js`, `js/koleksiyon.js`, `js/bildirim.js`, `js/karsilastir.js`.

**Yapılacaklar:**
- İki parmakla yakınlaştırma ve kaydırma, eserler arası geçiş, aşağı çekince kapanma.
- Künye, not ve hikâye.
- Rehberli ayrıntı noktaları.
- Koleksiyon kalbi, "kötü görsel" bildirimi (ilerlemeye yazar), keskin üst kopya.
- Başka ekranlar şöyle açar: `Goruntuleyici(eserler:baslangic:)`.

**Devir notu:** –

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

**Devir notu:** –

### G2 · Galeri (Gemini)
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

### G3 · Başyapıtlar (Gemini)
**Site kaynakları:** `js/basyapit.js`, `js/basyapitSayfa.js`, `js/ekranlar/basyapit.js`.

**Kapsam:** Liste (dönem sekmeleri), yakın okuma sayfası, yan yana karşılaştırma.

**Devir notu:** –

### C3 · Dersler (ChatGPT)
**Site kaynakları:**
- `js/ders.js`, `js/dersIcerik.js`, `js/eserDersi.js`, `js/kamera.js`
- `js/ekranlar/ders.js`, `js/ekranlar/dersVerisi.js`, `js/ekranlar/eserDersi.js`
- `basyapit-dersleri/` (Markdown → SwiftUI)

**Devir notu:** –

### G4 · Bugün (Gemini)
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

**Devir notu:** –

### G5 · Yolculuk + Zaman (Gemini)
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
