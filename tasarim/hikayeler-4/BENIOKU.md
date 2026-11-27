# Hikâyeler Sekmesi — 4. Tur Tasarım (Substack Minimal Üstüne)

Bu tur, Emre’nin 3. turda seçip uygulamaya giren **“Yön 2 · Substack Minimal”** tasarımının üstüne kuruludur; sıfırdan değildir. Takımyıldız, zaman çizelgesi, filtre yığını ve çip kalabalığı yoktur. **Uygulama koduna (Swift) dokunulmamıştır**; yalnızca tasarım taslakları ve ekran görüntüleri üretilmiştir.

Her iki yön de (`yon-1.html`, `yon-2.html`) **tek bir bağımsız HTML dosyasıdır** (`390×844` iPhone ölçüsü), uygulamanın yerel yazı tipleri (`Bodoni Moda`, `Newsreader`, `Archivo`), `TASARIM_DILI.md` Gece/Gündüz renkleri, `sanat-atlasi` deposundaki gerçek **60 hikâye** (`data/sanatci_hikayeleri.json`), **Türkçe eser adları** (`data/eser_adlari_tr.json`), gerçek Fola ses süreleri (`data/ses_dizini.json`) ve `gorseller/` klasörüne indirilen Wikimedia Commons kamu malı eserlerle **tamamen çevrimdışı** çalışır.

Tüm `390×844` (`deviceScaleFactor: 2`, `780×1688 px`) Gece ve Gündüz ekran görüntüleri [`goruntuler/`](goruntuler/) klasöründedir (44 PNG; tamamında `scrollWidth = 390`, `0` kırık görsel, ekran başına en çok `1` dolu düğme, tüm dokunma hedefleri `≥ 44 px`).

---

## İki Yön Arasındaki Fark

İki yön de Substack’in bülten sadeliğini korur; aralarındaki fark **Öne Çıkanlar düzeni** ve **Tam Ekran Çalar görünümüdür**:

| Özellik | Yön 1 · Substack Editoryal (`yon-1.html`) | Yön 2 · Substack Kompakt Bülten (`yon-2.html`) |
|---|---|---|
| **Öne Çıkanlar** | Kutusuz, sola yaslı Substack ana yazısı (`16:9` büyük kapak) + altında yatay kaydırılan `16:9` kapaklı 4 kartlık şerit. | Alt perdeli `16:9` dergi vitrin kapağı + altında yatay kaydırılan kompakt yan-yana bülten kartları (`Devam et` bölümü ilk ekranda daha yukarı çıkar). |
| **Tam Ekran Çalar** | **Sahne / Albüm Odaklı:** Tablo renginden çok hafif üst hale, merkezde büyük `268×268` kare kapak eseri, altında bölüm çentikli çubuk, ana kontroller ve `Hız · Bölümler · Uyku · Metin` alt araç şeridi. | **Editoryal / Okuma Masası:** Saf kâğıt/kömür zemin, üstte kompakt `72×72` kapak + başlık, ortada **canlı okunan paragraf önizleme kartı** (dokununca tam metne açılır), altta doğrudan görünür **Sıradaki** çubuğu ve **Otomatik** anahtarı. |

---

## Öne Çıkanlar Seçim Kuralı

Uygulama tek kullanıcılıdır; uydurma “popülerlik”, okunma sayısı veya sunucu sıralaması yoktur. Öne Çıkanlar (1 büyük kapak + 4 yatay kart = **5 yazı**) cihazda deterministik olarak şu sırayla seçilir:

1. **Yeni eklenenler (son 7 gün):** `olusturma` tarihi bugünden en çok 7 gün önce olan ve henüz bitirilmemiş (`yer.bitti != true`) hikâyeler, en yeniden eskiye sıralanır. En yenisi büyük kapak olur.
2. **Elle seçilmişler (isteğe bağlı):** Yeni eklenenler 5’i doldurmuyorsa, `data/sanatci_hikayeleri.json` içinde isteğe bağlı `"one_cikan": true` işaretli (editör seçkisi) ve henüz bitirilmemiş hikâyeler eklenir.
3. **Dönem dengeli haftalık seçki (tamamlayıcı):** Hâlâ 5’ten az yazı varsa, okunmamış hikâyeler arasından her dönemden en çok 1 sanatçı gelecek biçimde yılın haftasına (`ISO week`) bağlı sabit bir döndürmeyle tamamlanır. Böylece yeni içerik gelmeyen haftalarda da raf sessizce tazelenir, sunucu gerektirmez.

---

## Beğeni, “Sonra Oku” ve Veri Saklama Önerisi

- **Sayaç ve yorum yok:** Tek kullanıcı olduğu için kalp ve yer imi yanında hiçbir sayaç görünmez.
- **“Sonra oku” yeri (öneri):** Arşiv’in üstündeki sekmeler tam olarak 3 sade sekmede tutulur (**`En yeni · Dönem · Beğendiklerim`**). **“Sonra oku”** listesi ise **Ana ekranda `Devam et` bölümünün hemen altında** (yalnızca kayıtlı yazı varsa görünür; kayıt yoksa bölüm gizlenir) en çok 3 kompakt satır olarak durur. Bu yerleşim hem Arşiv sekmelerini 4’e çıkarıp kalabalıklaştırmaz, hem de kullanıcının “sonra okuyacağım” diye işaretlediği yazılara sekmeyi açar açmaz tek dokunuşla dönmesini sağlar.
- **Nerede saklanır?** Bugünkü okuma yerleri (`hikayeYerleri` — `UserDefaults`) gibi cihazda tutulur, sunucu yoktur. İki seçenekten önerilen:
  - **Kısa yol (Z4b ile uyumlu):** `UserDefaults` içinde `hikayeBegenileri` (`Set<String>`) ve `hikayeSonraOku` (`[String]`, eklenme sırasıyla) + çalar tercihleri (`hikayeHizi`, `hikayeOtomatikSonraki`).
  - **Yedeklemenin parçası olsun istenirse:** `Ilerleme` kaydına isteğe bağlı bir `hikayeler` alt nesnesi (`begenilenler`, `sonraOku`, `yerler`) eklenerek Ben › Yedekle JSON’una dahil edilebilir (mevcut `Ilerleme` bilinmeyen alanları koruduğu için geriye dönük güvenlidir).

---

## Süreler ve Ses Verisi Notu

- **Okuma süresi:** `kelime / 160` dakika (yuvarlanmış, en az 1 dk; `HikayeAkisi.okumaDakikasi` ile aynı).
- **Dinleme süresi:** 60 hikâyenin **55’i** `data/ses_dizini.json` içindeki gerçek Fola parça sürelerinin toplamından hesaplanmıştır.
- **Tahmini süre notu:** Aşağıdaki **4 yeni hikâyenin** (`2026-11-27`) Fola ses kaydı `data/ses_dizini.json`’da henüz bulunmadığı için dinleme süreleri uygulamadaki `DinlemeKurallari.okumaSuresi` (`harf / 12 + cümle × 0,35 sn`) kuralıyla **tahmini** olarak hesaplanmıştır:
  - `pierre-auguste-renoir` (0/41 parça — tahmini)
  - `correggio` (0/33 parça — tahmini)
  - `giovanni-bellini` (0/36 parça — tahmini)
  - `gustave-caillebotte` (0/32 parça — tahmini)
  - Ek olarak `francisco-de-goya` hikâyesinde 38/39 parça gerçek, 1 parça tahminidir.

---

## Ekranlar ve Görüntü Bağlantıları

### 1. Ana Ekran (`ana` · `ana-devam-yok`)
- Üstte yapışkan `Hikâyeler` başlığı, sağ üstte bugünkü gibi **Arama** ve **Ben** (kişi) düğmeleri.
- **Öne çıkanlar:** Büyük kapak yazısı (beğen ve sonra oku simgeleriyle) + yatay kaydırılan 4 öne çıkan yazı.
- **Devam et:** Yarım kalan okumalar ve dinlemeler; her kartta **Okuma mı Dinleme mi olduğu** (kitap/kulaklık simgesi), **kalan dakika** ve ince pirinç ilerleme çizgisi; tek dokunuşla kaldığı yerden açılır. Yarım yazı yoksa (`ana-devam-yok`) **bu bölüm hiç görünmez**.
- **Sonra oku:** Kaydedilmiş yazılar varsa Devam Et’in altında kompakt liste; yoksa gizli.
- **Tüm hikâyeler:** Altta 60 hikâyelik Arşiv’e giriş kartı.
- **Yön 1:** [Ana Gece](goruntuler/yon-1-ana-gece.png) · [Ana Gündüz](goruntuler/yon-1-ana-gunduz.png) · [Devam Yok Gece](goruntuler/yon-1-ana-devam-yok-gece.png) · [Devam Yok Gündüz](goruntuler/yon-1-ana-devam-yok-gunduz.png)
- **Yön 2:** [Ana Gece](goruntuler/yon-2-ana-gece.png) · [Ana Gündüz](goruntuler/yon-2-ana-gunduz.png) · [Devam Yok Gece](goruntuler/yon-2-ana-devam-yok-gece.png) · [Devam Yok Gündüz](goruntuler/yon-2-ana-devam-yok-gunduz.png)

### 2. Arşiv (`arsiv` · `arsiv-donem` · `arsiv-begendiklerim`)
- 60 hikâyenin tamamı; üstte Substack tarzı alt çizgili 3 sade sekme: **`En yeni · Dönem · Beğendiklerim`**.
- Her satırda küçük kapak (`58×58`), başlık, `sanatçı · yıllar`, okuma ve dinleme süreleri, durum (`Yeni`, `Okundu`, `N dk kaldı` + ilerleme çizgisi) ve sessiz kalp/yer imi düğmeleri.
- **`Dönem`** sekmesi 60 sanatçıyı doğum yılına göre kronolojik sıralar ve uygulamadaki gerçek dönemleri (`Orta Çağ`, `Rönesans`, `Barok`, `Klasisizm ve Geç Barok`, `Rokoko ve Neoklasisizm`, `Romantizmden Realizme`, `Empresyonizm`, `Post-Empresyonizm ve Sembolizm`) ince ara başlıklarla ayırır.
- **`Beğendiklerim`** sekmesi cihazda beğenilen yazıları listeler.
- **Yön 1:** [En yeni Gece](goruntuler/yon-1-arsiv-gece.png) · [Gündüz](goruntuler/yon-1-arsiv-gunduz.png) · [Dönem Gece](goruntuler/yon-1-arsiv-donem-gece.png) · [Gündüz](goruntuler/yon-1-arsiv-donem-gunduz.png) · [Beğendiklerim Gece](goruntuler/yon-1-arsiv-begendiklerim-gece.png) · [Gündüz](goruntuler/yon-1-arsiv-begendiklerim-gunduz.png)
- **Yön 2:** [En yeni Gece](goruntuler/yon-2-arsiv-gece.png) · [Gündüz](goruntuler/yon-2-arsiv-gunduz.png) · [Dönem Gece](goruntuler/yon-2-arsiv-donem-gece.png) · [Gündüz](goruntuler/yon-2-arsiv-donem-gunduz.png) · [Beğendiklerim Gece](goruntuler/yon-2-arsiv-begendiklerim-gece.png) · [Gündüz](goruntuler/yon-2-arsiv-begendiklerim-gunduz.png)

### 3. Okuma ve Yazı Sonu Eylem Çubuğu (`okuma-eylem-cubugu`)
- Mevcut `HikayeOkuma` ekranı (Newsreader 19/1,74 metin, tam genişlikte kırpılmamış eserler, “Bu dönemle bağı”, bağlantılı yazılar, kaynaklar) aynen korunur.
- Kapanışın hemen altına Substack tarzı ince bir **eylem çubuğu** eklenir: **`Beğen · Sonra oku · Paylaş`** (sayaç ve yorum yok).
- Altta yüzen ince okuma çalarına dokununca doğrudan **Tam Ekran Çalar** açılır.
- **Yön 1:** [Gece](goruntuler/yon-1-okuma-eylem-cubugu-gece.png) · [Gündüz](goruntuler/yon-1-okuma-eylem-cubugu-gunduz.png)
- **Yön 2:** [Gece](goruntuler/yon-2-okuma-eylem-cubugu-gece.png) · [Gündüz](goruntuler/yon-2-okuma-eylem-cubugu-gunduz.png)

### 4. Tam Ekran Çalar (`calar-tam` · `calar-bolumler` · `calar-uyku` · `calar-metin`)
- Mini çalara ya da okuma içindeki ince çalara dokununca açılır; aşağı kaydırınca veya üst soldaki aşağı okla kapanıp mini çalara döner.
- **Kontroller:** Sürüklenebilir ve **bölüm çentikli** ilerleme çubuğu (geçen / kalan süre), **önceki/sonraki bölüm**, **`−15 sn`**, tek dolu **oynat/duraklat**, **`+30 sn`**, **AirPlay / ses çıkışı** düğmesi, beğen ve sonra oku simgeleri.
- **Hız seçici:** `0,8× · 1× · 1,2× · 1,5× · 1,75× · 2×`.
- **Bölümler ve Sıradaki (`calar-bolumler`):** Hikâyenin gerçek bölüm başlıkları (dokununca doğrudan o bölüme atlar) + altında **Otomatik sonraki** anahtarı ve kısa **Sıradaki** listesi.
- **Uyku zamanlayıcı (`calar-uyku`):** `15 dakika · 30 dakika · 45 dakika · Bölüm sonunda · Kapalı`.
- **Metni göster (`calar-metin`):** Okunan paragraf senkron akar ve vurgulanır; paragrafa ya da üstteki **`Okumaya dön`** düğmesine dokununca doğrudan okuma ekranına döner.
- **Yön 1:**
  - Tam çalar: [Gece](goruntuler/yon-1-calar-tam-gece.png) · [Gündüz](goruntuler/yon-1-calar-tam-gunduz.png)
  - Bölümler ve Sıradaki: [Gece](goruntuler/yon-1-calar-bolumler-gece.png) · [Gündüz](goruntuler/yon-1-calar-bolumler-gunduz.png)
  - Uyku zamanlayıcı: [Gece](goruntuler/yon-1-calar-uyku-gece.png) · [Gündüz](goruntuler/yon-1-calar-uyku-gunduz.png)
  - Metni göster: [Gece](goruntuler/yon-1-calar-metin-gece.png) · [Gündüz](goruntuler/yon-1-calar-metin-gunduz.png)
- **Yön 2:**
  - Tam çalar: [Gece](goruntuler/yon-2-calar-tam-gece.png) · [Gündüz](goruntuler/yon-2-calar-tam-gunduz.png)
  - Bölümler ve Sıradaki: [Gece](goruntuler/yon-2-calar-bolumler-gece.png) · [Gündüz](goruntuler/yon-2-calar-bolumler-gunduz.png)
  - Uyku zamanlayıcı: [Gece](goruntuler/yon-2-calar-uyku-gece.png) · [Gündüz](goruntuler/yon-2-calar-uyku-gunduz.png)
  - Metni göster: [Gece](goruntuler/yon-2-calar-metin-gece.png) · [Gündüz](goruntuler/yon-2-calar-metin-gunduz.png)

### 5. Mini Çalar (`mini`)
- Başka bir sekmede (`Bugün`, `Galeri`, `Çalış`, `Yolculuk`) 5’li sekme çubuğunun `10 px` üstünde durur; ince ilerleme çizgisi, `−15 sn` ve oynat/duraklat içerir. Dokununca **Tam Ekran Çalar** açılır.
- **Yön 1:** [Gece](goruntuler/yon-1-mini-gece.png) · [Gündüz](goruntuler/yon-1-mini-gunduz.png)
- **Yön 2:** [Gece](goruntuler/yon-2-mini-gece.png) · [Gündüz](goruntuler/yon-2-mini-gunduz.png)

---

## Uygulamada Değişecek Swift Dosyaları (Öneri)

*Not: Bu PR’da hiçbir Swift dosyasına dokunulmamıştır; aşağıdakiler uygulama aşaması için yol haritasıdır.*

### Çekirdek (`Paketler/NoraCekirdek/Sources/NoraCekirdek/Hikayeler/`)
- **`HikayeAkisi.swift`:**
  - `oneCikanlar(_:yerler:bugun:)` — son 7 gün + elle seçilmiş + dönem dengeli haftalık 5’li seçim kuralı.
  - `devamEdenler(_:yerler:)` — yarım kalanlar (`okuma` / `dinleme` türü ayrımı için `OkumaYeri.sonTur` eklenmesi).
  - `arsivSirala(_:sekme:dogumYili:donem:begenilenler:)` — `En yeni`, `Dönem` (doğum yılına göre kronolojik + dönem grupları), `Beğendiklerim`.
  - `siradaki(_:hikayeler:sonraOku:yerler:)` — hikâye bitince çalınacak kısa kuyruk.
- **`HikayeSesi.swift`:**
  - `bolumZamanlari(_:parcalar:sureler:)` — her bölümün başlangıç saniyesi, süresi ve ilk parça sırası (ilerleme çubuğundaki çentikler ve bölüm atlama için).
  - `hizlar` — `[0.8, 1.0, 1.2, 1.5, 1.75, 2.0]` (6 kademeli hız seçimi).
  - İleri atlama: `+30 sn`, geri atlama: `−15 sn`; `oncekiBolum` / `sonrakiBolum` yardımcıları.
- **`SanatciHikayesi.swift`:**
  - İsteğe bağlı `oneCikan: Bool` alanı (JSON’da yoksa `false`).

### Ekranlar (`NoraSanat/Ekranlar/Hikayeler/`)
- **`HikayeDeposu.swift`:**
  - `begenilenler: Set<String>` ve `sonraOku: [String]` kalıcı saklama (`UserDefaults` ya da `Ilerleme` alt nesnesi) + `begenDegistir(_:)`, `sonraOkuDegistir(_:)`.
  - Dönem bilgisi (`Donem.akimin(katalog, akim)`) ve sanatçı doğum yılı erişimi.
- **`HikayelerSekmesi.swift`:**
  - `HikayeAna` yenilenir: **Öne çıkanlar** (büyük kapak + yatay kaydırılan şerit), **Devam et** (yarım yoksa gizli), **Sonra oku** (kayıtlı yoksa gizli), altta **Tüm hikâyeler** ile `HikayeArsivi` ekranına geçiş.
- **`HikayeArsivi.swift` *(yeni dosya)*:**
  - `En yeni · Dönem · Beğendiklerim` 3’lü alt çizgili sekmeli 60 hikâyelik arşiv görünümü.
- **`HikayeOkuma.swift`:**
  - Kapanışın hemen altına **ince eylem çubuğu** (`Beğen · Sonra oku · Paylaş`, `ShareLink`).
  - `HikayeIcCalar` dokunuşunda `tamCalarAcik = true` ile tam ekran çaları `.sheet` / `.fullScreenCover` olarak açma.
- **`HikayeCalari.swift`:**
  - `uykuSuresi` (`15 / 30 / 45 dk / bölüm sonunda / kapalı`) ve bitiş zamanlayıcısı; `otomatikSonraki` ve `siradaki` kuyruğu; `bolumeGit(_:)`, `zamanaGit(_:)` (scrubber sürükleme); kilit ekranı `skipForwardCommand` `+30 sn`.
- **`HikayeCalarGorunumu.swift` & `HikayeTamCalar.swift` *(yeni dosya)*:**
  - `HikayeTamCalar`: seçilen yöne göre tam ekran çalar, bölüm çentikli sürüklenebilir çubuk, hız seçici, Bölümler + Sıradaki yaprağı, Uyku yaprağı, senkron Metin görünümü ve `AVRoutePickerView` (AirPlay).
  - `HikayeMiniCalar`: dokununca yazıya dönmek yerine **Tam Ekran Çalar**’ı açar (oradan `"Okumaya dön"` ile yazıya geçilir).
- **`HikayeOrtak.swift`:**
  - Yeni çizgi simgeler: `kalp`, `yerimi`, `paylas`, `ileri30`, `oncekiBolum`, `sonrakiBolum`, `uyku`, `bolumler`, `metin`, `airplay`.
