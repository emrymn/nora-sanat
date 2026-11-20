# Nora Sanat → tamamen Swift: iş dağılımı

Bu dosya iki Claude hesabının (Hesap A, Hesap B) ortak iş listesidir. Oturumlar birbirini görmez; **her şey burada yazılıdır.**
Her iş ayrı bir oturumda yapılır. **İşi bitiren, bu dosyada kendi işinin durumunu ve devir notunu yazar.**

**Hedef.** Sanat Atlası'nın (`emrymn/sanat-atlasi`, yayında `sanat-atlasi.pages.dev`) bütün ekranlarını Swift ile yeniden yazmak.
- Geçiş **sekme sekme** olur. Taşınmamış sekmeler o güne kadar sitenin kendisini (WKWebView) gösterir. Uygulama her an kullanılabilir kalır.
- Sitenin görünüşü ve davranışı korunur.
- Bitince web görünümü kalkar.

---

## Oturum kuralları

### Başlarken
1. `git checkout main && git pull`. Sonra `CLAUDE.md`'yi, bu dosyanın tamamını ve işinin bölümünü oku.
2. **Bağımlılıklar** sütunundaki işler `bitti` değilse başlama. Kullanıcıya hangi işin beklendiğini söyle.
3. Sanat Atlası'nı salt okunur indir ve işinin kaynak dosyalarını oku. Commit'ini not et (`git -C <yol> rev-parse --short HEAD`):
   ```bash
   git clone --depth 1 https://github.com/emrymn/sanat-atlasi /tmp/sa
   ```
4. Dal aç: `is/<ID>-<kısa-ad>`, örneğin `is/T2-ilerleme`.
5. İlk commit'te tablodaki durumunu `sürüyor (Hesap X, tarih)` yap.
6. Hemen **taslak PR** aç. Öbür hesap ne yapıldığını açık PR'lardan görür.

### Bitirirken
1. CI yeşil olmalı. Ekran görüntülerine bak: ekran sitedekine benziyor mu?
2. Bu dosyada iki şeyi güncelle:
   - Tablodaki durum: `PR açık (#n)`.
   - İşinin altındaki **Devir notu**: ne yapıldı, ne kaldı, tuzaklar, kaynak commit, sonraki işe ipucu.
3. Kullanıcıya şunları yaz:
   - PR linki.
   - Telefonda neyi deneyeceği (README'deki deneme listesine de ekle).
   - "Birleştir dersen birleştiririm."
   - **Birleştirmeyi yalnız kullanıcı açıkça isterse yap.**
4. Birleşince durumu `bitti (#n)` yap. Bunu bir sonraki oturum da yapabilir.

### Çakışmasız çalışma
- Her iş **yalnız kendi klasörlerine** dokunur (bkz. K6).
- Ortak dosyalara (Kabuk, Tema, `IlerlemeKoprusu`, `Package.swift`, `project.pbxproj`) yalnız **Temel** işleri dokunur.
- Bir şerit işi ortak dosyada küçük bir değişikliğe ihtiyaç duyarsa önce `main`'i çeker. Değişikliği küçük tutar ve devir notunda yazar.
- Bu dosyada yalnız **kendi satırını ve kendi bölümünü** değiştir. Böylece iki PR aynı satıra dokunmaz.

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
- Hesap A **A** şeridindeki sıradaki işi alır, Hesap B **B** şeridindekini.
- Temel işleri iki şeride dağıtılmıştır: T1 B'de, T2 ve T3 A'da.
- Tahmini süreler "oturum" cinsindendir. Bir oturum bir PR demektir.

| ID | İş | Şerit | Bağımlılık | Oturum | Durum |
|----|----|-------|------------|--------|-------|
| T1 | Site verisi ve görsel adresleri | B | – | 1–2 | bekliyor |
| T2 | İlerleme köprüsü + tekrar kuralları | A | – | 1–2 | bekliyor |
| T3 | Kabuk: yerli sekmeler, tema, görsel önbelleği | A | T1, T2 | 1 | bekliyor |
| B1 | Tam ekran görüntüleyici | B | T1 | 1–2 | bekliyor |
| A1 | Pekiştirme oturumu (kartlar, sorular) | A | T2, T3 | 2 | bekliyor |
| B2 | Galeri: akımlar, sanatçı, eserler, arama, koleksiyon | B | T3, B1 | 2–3 | bekliyor |
| A2 | Çalış ana ekranı | A | A1 | 1 | bekliyor |
| B3 | Başyapıtlar: liste ve yakın okuma | B | B2 | 1 | bekliyor |
| A3 | Dersler (Gör, Öğren, Ayırt et) + eser dersleri | A | A2, B1 | 2 | bekliyor |
| B4 | Bugün (Tuval) + resmin içinde yürüyüş | B | T3, B1 | 2 | bekliyor |
| A4 | Ben: İlerleme, Ayarlar, yedekle/geri yükle | A | T3 | 1–2 | bekliyor |
| B5 | Yolculuk haritası + Zaman | B | T3, A1 | 2 | bekliyor |
| Z1 | Çevrimdışı görseller (321 MB) | A | A4 | 1 | bekliyor |
| Z2 | İlerlemeyi Swift'e al, WKWebView'i kaldır | A | hepsi | 1 | bekliyor |
| Z3 | Cila + sitedeki son değişikliklere yetişme | B | Z2 | 1 | bekliyor |

**Sekmeler ne zaman yerli olur:**
- Galeri: B1 + B2 + B3
- Bugün: B4
- Yolculuk: B5
- Çalış: A1 + A2 + A3
- Ben/Ayarlar: A4

---

## İşler

### T1 · Site verisi ve görsel adresleri (B)
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

**Devir notu:** –

### T2 · İlerleme köprüsü + tekrar kuralları (A)
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

**Devir notu:** –

### T3 · Kabuk (A)
**Amaç:** Yerli sekme çubuğu (K1). Sekmeler şimdilik siteyi gösterir; uygulama bugünküyle aynı çalışır.

**Yapılacaklar:**
- `NoraSanat/Kabuk/`: `KokGorunum` (TabView), `Gecis` (`yerliSekmeler`), `Tema` (K5), `Gorsel` (disk önbellekli görsel görünümü), `Titresim`.
- Sitenin kendi alt sekme çubuğu yerli çubukla çakışmamalı. Taşınmamış sekmede site tam ekran kalır ve yerli çubuk gizlenir; sekme geçişi sitenin çubuğuyla olur. Tüm sekmeler taşınınca yerli çubuk görünür. Alternatif bir çözüm seçersen devir notuna yaz.
- Widget, bildirim ve rozet bugünkü gibi çalışmaya devam etmeli.

**Bitti sayılır:**
- CI ekran görüntüleri bugünkünden farksız.
- `-ekran tema` ile renk ve yazı örnekleri görünüyor (gece ve gündüz).

**Devir notu:** –

### B1 · Tam ekran görüntüleyici (B)
**Site kaynakları:** `js/goruntuleyici.js`, `js/ayrinti.js`, `js/hikaye.js`, `js/keskin.js`, `js/koleksiyon.js`, `js/bildirim.js`, `js/karsilastir.js`.

**Yapılacaklar:**
- İki parmakla yakınlaştırma ve kaydırma, eserler arası geçiş, aşağı çekince kapanma.
- Künye, not ve hikâye.
- Rehberli ayrıntı noktaları.
- Koleksiyon kalbi, "kötü görsel" bildirimi (ilerlemeye yazar), keskin üst kopya.
- Başka ekranlar şöyle açar: `Goruntuleyici(eserler:baslangic:)`.

**Devir notu:** –

### A1 · Pekiştirme oturumu (A)
**Site kaynakları:**
- `js/oturum.js`, `js/celdirici.js`, `js/ters.js`, `js/turlar.js`, `js/soruTurlari.js`, `js/devam.js`, `js/titresim.js`
- `js/ekranlar/pekistir.js`, `js/ekranlar/soruTurlari.js`

**Yapılacaklar:**
- Kart seçimi, zor yanlış seçenekler, aynı oturumda geri dönen yanlışlar.
- Bütün tur türleri: karışık, dönem, konu, bölüm, hatalar.
- Cevap yaprağı.
- Yarım oturumu sürdürme.
- Sonuçlar `IlerlemeKoprusu` ile yazılır.
- İki oturum önerilir: **A1a** mantık + kâhin, **A1b** ekranlar.

**Devir notu:** –

### B2 · Galeri (B)
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

### A2 · Çalış ana ekranı (A)
**Site kaynakları:** `js/ekranlar/calisma.js`, `js/deste.js`.

**Kapsam:** Bugünün dersi kartı, günlük tekrar, başka turlar, 14 günlük yük grafiği.

**Devir notu:** –

### B3 · Başyapıtlar (B)
**Site kaynakları:** `js/basyapit.js`, `js/basyapitSayfa.js`, `js/ekranlar/basyapit.js`.

**Kapsam:** Liste (dönem sekmeleri), yakın okuma sayfası, yan yana karşılaştırma.

**Devir notu:** –

### A3 · Dersler (A)
**Site kaynakları:**
- `js/ders.js`, `js/dersIcerik.js`, `js/eserDersi.js`, `js/kamera.js`
- `js/ekranlar/ders.js`, `js/ekranlar/dersVerisi.js`, `js/ekranlar/eserDersi.js`
- `basyapit-dersleri/` (Markdown → SwiftUI)

**Devir notu:** –

### B4 · Bugün (B)
**Site kaynakları:**
- `js/ekranlar/bugun.js`, `js/yuruyus.js`, `js/egim.js`, `js/gunduzRenk.js`, `js/renk.js`, `js/gunun.js`
- Seçim kuralı Swift'te zaten var: `NoraCekirdek/GununSanatcisi.swift`.

**Kapsam:**
- Günün tablosu, perde açılışı.
- Resmin içinde yürüyüş (kaydırdıkça ayrıntıdan ayrıntıya), eğim hareketi.
- Hayatı, bugünkü tur kartı.

**Devir notu:** –

### A4 · Ben (A)
**Site kaynakları:** `js/ekranlar/ilerleme.js`, `js/ekranlar/ayarlar.js`, `js/ekranlar/hizliAyar.js`, `js/kurs.js`, `js/yenilikler.js`, `js/rozet.js`.

**Kapsam:**
- Konular ("işlendi").
- Akım doğruluk çubukları, en zayıflar.
- Bütün ayarlar.
- Yedekle ve geri yükle: **sitenin JSON biçimiyle aynı**, eski yedekler çalışmalı.

**Devir notu:** –

### B5 · Yolculuk + Zaman (B)
**Site kaynakları:**
- `js/harita.js`, `js/bolum.js`, `js/ekranlar/harita.js`, `js/surukleKapat.js`, `js/sallanma.js`
- `js/zaman.js`, `js/ekranlar/zaman.js`

**Devir notu:** –

### Z1 · Çevrimdışı görseller (A)
**Site kaynakları:** `js/devasaOnbellek.js`, Ayarlar'daki "Görselleri çevrimdışı indir".

**Kapsam:** Arka planda indirme, boyut ve ilerleme göstergesi, iptal.

**Devir notu:** –

### Z2 · Swift'e devir (A)
**Kapsam:**
- İlerleme tek seferlik Swift deposuna taşınır (Application Support'ta JSON; şema aynı kalır, yedek uyumlu).
- WKWebView ve `WebKabugu` kalkar.
- `TekrarKoprusu`'nun işi `Hatirlatici`'ye geçer: sayılar doğrudan Swift'ten hesaplanır.
- App-Bound Domains kaldırılır.

**Devir notu:** –

### Z3 · Cila + yetişme (B)
**Kapsam:**
- K7'ye göre sitedeki değişikliklerin taşınması.
- Erişilebilirlik (VoiceOver, Dinamik Yazı).
- Son karşılaştırma: sitedeki her ekranla yan yana ekran görüntüsü.

**Devir notu:** –
