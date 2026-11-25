# Yolculuk · Soru Ekranı (Cevap Öncesi) Tasarım Önerileri

Yolculuk bölüm turunun **soru ekranı** (`NoraSanat/Ekranlar/Yolculuk/BolumSoruKarti.swift`, `PekistirmeOgeleri.swift`; site karşılığı `js/ekranlar/pekistir.js` `kartGoster`, `css/app.css` `.soru-sahne`, `.secenekler`) için üç ayrıntılı yeniden tasarım önerisi.

Temel dil olarak Emre'nin en çok beğendiği **durak-içi Yön 3** soru ekranı (üstte nokta ilerleme + sayaç, ortada tablo, altta cam tepside `"Bu eser kimin?"` + 2×2 şık + `"Bilmiyorum"`) alınıp derinleştirilmiştir. **Harita, durak paneli, tanışma, cevap yaprağı içeriği, sonuç ekranı ve uygulama koduna dokunulmamıştır.**

Üç HTML dosyası da (`yon-1.html`, `yon-2.html`, `yon-3.html`) `390×844` ve küçük ekran `375×667` boyutlarında, yerel yazı tipleriyle (`NoraSanat/YaziTipleri/`), Rönesans dönem desen karosuyla ve [`gorseller/`](gorseller/) altındaki **6 benzersiz kamu malı tabloyla (`1280 px`)** tamamen **internetsiz** çalışır; dış bağlantı yoktur.

---

## Ekranın işi ve korunan bütün kurallar

- **Eser her zaman en büyük öğe:** Dikey (*Arnolfini Portresi*, `0.73`), yatay geniş (*Mérode Sunağı*, `1.97`) ve kareye yakın (*Şansölye Rolin'in Meryem'i*, `0.93`) tabloların tamamı hiç kırpılmadan (`object-fit: contain`), tam oranıyla sahneye oturur.
- **Esere dokununca gizli büyütme:** Tam ekran yakın inceleme açılır; eser adı cevaptan önce **gizli** kalır (`"Eser adı cevaptan sonra görünür"`).
- **Görsel yüklenemezse kurtarma:** Önizleme çubuğundaki *Yükleme hatası* modunda `"Görsel yüklenemedi"` çerçevesi ve `"Başka eser dene"` düğmesi belirir; dokununca aynı sanatçının yedek eseri (*Kırmızı Sarıklı Adam*) yüklenir.
- **İpucu vermeyen tasarım:** Şıklarda doğum/ölüm yılı, akım rengi veya harf rozeti yoktur. Eserin arkasındaki hale/ışık yalnızca sorulan tablonun kendi renklerinden gelir; cevaptan önce akım rengine düşülmez.
- **Karışık tur — ikinci soru (`"Hangi akım?"`):** 1. sorudan sonra cevap geçişindeki `"Hangi akım?"` düğmesine (ya da üst çubuktaki sekmeye) basılınca tablo sahnede kıpırdamadan sabit kalır; yalnız tepsi içindeki başlık (`"Hangi akım?"`, `"Soru 2 / 2"`) ve 4 akım şıkkı değişir.
- **Şıka dokunma anı ve cevap yaprağına geçiş:**
  1. Dokunma anında şık `scale(0.975)` ile hafifçe içe çöker.
  2. Doğruysa seçilen şık yeşil yüzey + yeşil kenar + `✓` dairesiyle vurgulanır; diğer 3 şık çekilir.
  3. Yanlışsa seçilen şık mercan yüzey + `×` (ve hafif yatay sarsılma — hareket azaltılınca sarsılma kalkar), doğru şık yeşil `✓` ile yan yana kalır; elenen 2 şık çekilir.
  4. Eser üstte görünür kalacak biçimde alttan cevap yaprağının geçiş kenarı yükselir (yaprağın içi kapsam dışı olduğundan yalnız geçiş iskeleti gösterilir).
- **Küçük ekran (`375×667`), 44 px hedef ve hareket azaltma:** Üç yön de `375×667` iPhone SE genişliğinde tek ekrana kaydırmasız sığar (`scrollWidth = 375`), `390×844`'te yatay taşma yoktur (`scrollWidth = 390`), tüm etkileşimli düğmeler `≥ 44 px` dokunma hedefine sahiptir; `prefers-reduced-motion: reduce` ve *Hareketi azalt* anahtarı nefes alan haleyi, şık sarsılmasını ve yaprak kaymasını sadeleştirir.

---

## Dokunsal geri bildirim (titreşim) anları

Mevcut `NoraSanat/Kabuk/Titresim.swift` ile birebir uyumlu (Ayarlar → Titreşim kapalıysa sessiz):

| An | Etkileşim | `Titresim.swift` karşılığı | Amaç |
|---|---|---|---|
| Şıka dokunma (doğru) | Doğru sanatçı / akım seçimi | `Titresim.dogru` (`.success`) | Tek, temiz onay darbesi |
| Şıka dokunma (yanlış) | Yanlış sanatçı / akım seçimi | `Titresim.yanlis` (`.error`) | Çift darbe; mercan vurguyla eşzamanlı |
| `"Bilmiyorum"` | Cevabı pas geçme | `Titresim.dokunus` (`.light`) | Ceza hissi vermeyen yumuşak geçiş |
| Esere dokunup büyütme | Tam ekran yakın inceleme açılışı | `Titresim.secim` | Galeri camı açılış tıkı |
| `"Hangi akım?"` geçişi | 1. sorudan 2. soruya akış | `Titresim.dokunus` (`.light`) | Aynı eser üzerinde yeni soru ritmi |
| Turdan çıkış (`×`) | Çıkış onay penceresi açılışı | `Titresim.secim` | Kazara çıkışı önleyen sakin uyarı |

---

## Yön 1 — İnceltilmiş Cam Tepsi (`yon-1.html`)

**Rolü:** *Emre'nin beğendiği durak-içi Yön 3 soru ekranının doğrudan inceltilmiş, oran-uyarlamalı ve mikro-etkileşimleri cilalanmış hâli.*

- **Üst bar:** Solda `44×44` cam `×`, ortada cam kap içinde 8 noktalı ilerleme (geçilenler yeşil/mercan, şimdiki büyümüş mürekkep noktası), sağda cam `3 / 8` hapı.
- **Eser sahnesi:** Yalnız eserin baskın iki renginden çok yumuşak nefes alan hale (`HaleNefes` akrabası) + `1 px` ince iç parıltı kenarı. Dikey (`406 px`), yatay (`310 px`) ve kare (`368 px`) için ayrı tavanlar; `375×667`'de otomatik sıkılaştırma.
- **Cam tepsi:** Sağ üstte seviye etiketi (`Kolay` · karışıkta `Soru 2 / 2 · Kolay`), 2×2 dokunmatik şıklar (`54 px`, uzun adlar 2 satıra rahatça kırılır) ve altta ortalı italik `Bilmiyorum`.
- **Geçiş:** Şık seçilince elenenler çekilir, kalan 1 veya 2 şık cam tepside kalarak alttan ayrı cevap yaprağı kenarı yükselir.
- **Güçlü yanı:** Beğenilen Yön 3 diline tam sadakat; en dengeli görsel ağırlık.
- **Ödün:** Üstte üç ayrı cam parça (`×`, nokta hapı, sayaç hapı) küçük ekranda biraz daha fazla görsel çerçeve taşır.
- **Görüntüler:**
  - Gece (`390×844`): [Dikey eser](goruntuler/yon-1-dikey-gece.png) · [Yatay eser](goruntuler/yon-1-yatay-gece.png) · [Hangi akım?](goruntuler/yon-1-akim-gece.png) · [Cevap anı](goruntuler/yon-1-cevap-gece.png)
  - Gündüz (`390×844`): [Dikey eser](goruntuler/yon-1-dikey-gunduz.png)
  - Küçük ekran (`375×667`): [Dikey eser (SE)](goruntuler/yon-1-kucuk-gece.png)

---

## Yön 2 — Müze Spotu ve Kesintisiz Üst Şerit (`yon-2.html`)

**Rolü:** *Yön 3'ten cesaret alan, üstteki kutu kalabalığını tamamen kaldıran daha mimari ve Apple tarzı yorum.*

- **Üst bar:** Üç cam kap yerine tek sakin satır — solda `44×44` cam `×`, ortada kutusuz doğrudan zeminde duran nokta izi (aktif soru `18 px` uzayan kapsüle dönüşür), sağda yalın rakam `3 / 8`.
- **Eser sahnesi:** Mevcut `SoruIsigi`'nin inceltilmiş hâli — tablonun kendi bulanık yansıması üstten aşağı zemine erir (`Gece %24`, `Gündüz %11`), tablo çerçevesiz ve keskin durur.
- **Bölünmüş cam tepsi:** İnce bir yatay çizgiyle ikiye ayrılır — üst bantta `"Bu eser kimin?"` / `"Hangi akım?"` + (karışık turda) iki minik adım noktası (`● ○`) ve seviye; alt bölümde kenar çizgisiz, hafif cam dolgulu 2×2 şıklar + `"Bilmiyorum"`.
- **Güçlü yanı:** En sade üst bar; bulanık tablo ışığı sayesinde her eser kendi atmosferini kendiliğinden kurar.
- **Ödün:** Gündüz temasında bulanık ışık çok hafif tutulduğundan Gece kadar dramatik değildir.
- **Görüntüler:**
  - Gece (`390×844`): [Dikey eser](goruntuler/yon-2-dikey-gece.png) · [Yatay eser](goruntuler/yon-2-yatay-gece.png) · [Hangi akım?](goruntuler/yon-2-akim-gece.png) · [Cevap anı](goruntuler/yon-2-cevap-gece.png)
  - Gündüz (`390×844`): [Dikey eser](goruntuler/yon-2-dikey-gunduz.png)
  - Küçük ekran (`375×667`): [Dikey eser (SE)](goruntuler/yon-2-kucuk-gece.png)

---

## Yön 3 — Geniş Tuval ve Birleşik İlerleme (`yon-3.html`)

**Rolü:** *Eseri en büyük boyuta çıkaran, bilgi tekrarını sıfırlayan ve alt tepsiyi ekran kenarına oturtan en cesur ama sade yön.*

- **Üst bar:** Ortadaki tek cam hap içinde **hem nokta ilerleme hem `3 / 8`** birleşir; sağda kutusuz pirinç **seviye fısıltısı** (`Kolay` / `Orta` / `Zor`) yer alır — böylece tepside seviye tekrar etmez.
- **Eser sahnesi:** Dikeyde `442 px`'e (`375×667`'de `312 px`'e) ulaşan en geniş tuval alanı; yatay tablolar kenarlara `14 px` yaklaşarak genişler.
- **Alt kenara oturan cam tepsi:** Yüzen kutunun alt kenar boşluğunu kaldırıp tabana `28 px` üst köşelerle oturur; `"Bilmiyorum"` başlıkla aynı satırın sağına alınarak dikeyden `44 px` daha kazanılıp tamamı esere verilir. Karışık turda `"Soru 2 / 2"` başlığın hemen üstünde `2,5 px` iki küçük çizgiyle fısıldanır.
- **Geçiş:** Cevap verilince ikinci bir pencere binmek yerine **aynı alt tepsi** aşağıdan yumuşakça genişleyip cevap yaprağına dönüşür — sıfır görsel sıçrama.
- **Güçlü yanı:** Üç yön arasında tabloya en fazla alan bırakan tasarım; tek tepsi içinde kesintisiz soru → cevap dönüşümü.
- **Ödün:** `"Bilmiyorum"` başlığın sağında olduğu için alt ortadaki geleneksel konuma alışık kullanıcı ilk seferde gözüyle arar (yine de başparmak eriminde ve `44 px` hedeflidir).
- **Görüntüler:**
  - Gece (`390×844`): [Dikey eser](goruntuler/yon-3-dikey-gece.png) · [Yatay eser](goruntuler/yon-3-yatay-gece.png) · [Hangi akım?](goruntuler/yon-3-akim-gece.png) · [Cevap anı](goruntuler/yon-3-cevap-gece.png)
  - Gündüz (`390×844`): [Dikey eser](goruntuler/yon-3-dikey-gunduz.png)
  - Küçük ekran (`375×667`): [Dikey eser (SE)](goruntuler/yon-3-kucuk-gece.png)

---

## Kısa karşılaştırma

| Ölçüt | Yön 1 · İnceltilmiş Cam Tepsi | Yön 2 · Müze Spotu | Yön 3 · Geniş Tuval |
|---|---|---|---|
| Üst ilerleme | 3 cam parça (`×` · noktalar · `3/8`) | Kutusuz uzayan nokta kapsülü + yalın `3/8` | Birleşik cam hap (`noktalar \| 3/8`) + seviye |
| Tablo arkası atmosfer | Eser renginden nefes alan hale | Tablonun bulanık ışığı (`SoruIsigi`) | Eser renginden sakin sabit hale |
| Dikey tablo azami boyu (`390×844`) | `406 px` | `418 px` | `442 px` (en büyük) |
| Tepsi yerleşimi | Yüzen 4 köşesi yuvarlak cam tepsi | İnce bantlı iki katmanlı yüzen cam tepsi | Alt kenara oturan kesintisiz cam tepsi |
| `"Bilmiyorum"` yeri | Tepsi alt ortası | Tepsi alt ortası | Başlık satırının sağı (`+44 px` esere alan) |
| Cevap yaprağı geçişi | Tepsinin altından yükselen ayrı yaprak | Tepsinin altından yükselen ayrı yaprak | Aynı tepsinin yerinde genişlemesi |
| `375×667` sığma | Tek ekranda, kaydırmasız | Tek ekranda, kaydırmasız | Tek ekranda, en ferah tablo |


---

## İkinci Tur · Yön 3 (Geniş Tuval) Üzerinde Üç Yeni Şık Alanı Önerisi

Yön 3 (*Geniş Tuval*) seçildi. Üst bölüm (cam `×`, birleşik nokta + `3 / 8` hapı, sağda pirinç `Kolay`, ortada büyük kırpılmayan eser) aynen korunarak yalnızca alttaki **şık alanı**, **basılı/seçili hâl** ve **cevap sonrası geçiş** üç farklı dille yeniden tasarlandı (`sik-1.html`, `sik-2.html`, `sik-3.html`).

### Ortak mimari çözüm: Şıka basınca eserin küçülmesini önleme (`0 px` kayma)

Önceki düzenlerde cevap verilince kalan 2 şığın altına ek bir cevap yaprağı eklendiği için alt panel uzuyor, üstteki tablo sıkışıp küçülüyordu. Üç yeni öneride de **sabit alt yükseklik rezervi + yer değiştirme** uygulandı:

- Cevap verilmeden önce 4 şık sabit bir alt yükseklik içinde yaşar (`sik-1`: `224 px`, `sik-2`: `254 px`, `sik-3`: `238 px`; `375×667`'de sırasıyla `196 / 234 / 214 px`).
- Şıka basıldığı anda elenen 2 şık çekilir; **elenen şıkların boşalttığı satır/yükseklik** doğrudan sonuç etiketi (`Doğru` / `Yanlış`) ve tek dolu geçiş düğmesinin (`Hangi akım?` / `Sonraki`) yeri olur.
- **Ölçülen sonuç (`390×844`):** Üç öneride de cevap öncesi ve cevap sonrası tablo yüksekliği **birebir aynıdır (`fark = 0 px`)**:
  - `sik-1`: `446 px → 446 px`
  - `sik-2`: `416 px → 416 px`
  - `sik-3`: `432 px → 432 px`

### Şık etkileşiminde titreşim anları

- **Parmağı şıkka bastırma (`touchstart` / basılı hâl):** `Titresim.secim` (`UISelectionFeedbackGenerator`) — özellikle `sik-3`'teki ters renk mühür hissi ve `sik-2`'deki sol pirinç iz ile eşzamanlı hafif tık.
- **Doğru seçim:** `Titresim.dogru` (`.success`, tek darbe) + yeşil ✓ dairesi.
- **Yanlış seçim:** `Titresim.yanlis` (`.error`, çift darbe) + mercan × dairesi ve `4 px` yatay sarsılma (*Hareketi azalt* açıksa sarsılma kalkar, yalnız renk ve ikon değişir).
- **`"Bilmiyorum"`:** `Titresim.dokunus` (`.light`) — yumuşak geçiş.

---

### Şık 1 — İnce Haçlı Cam Kartela (`sik-1.html`)

**Rolü:** *Bugünkü 2×2 yerleşimin inceltilmiş, dört ayrı koyu kutudan arındırılmış hâli.*

- **Biçim ve yerleşim:** 4 kapalı dikdörtgen kutu yerine tek pürüzsüz cam tepsi içinde saç kılı inceliğinde `+` (haç) çizgisiyle ayrılmış 4 açık dokunma kadranı.
- **Basılı hâl:** Dokunulan kadran kadife aydınlanmayla öne çıkar, metin hafifçe içe çöker (`scale(0.975)`) ve kadranın alt kenarında `2 px` pirinç bir iz açılır.
- **Cevap sonrası:** Elenen alt satır kapanır; üstte doğru ve seçilen iki kadran yeşil `✓` / mercan `×` ile kalır, alt satırın tam yerine geçiş bandı oturur (`0 px` tablo küçülmesi).
- **Güçlü yanı:** Mevcut 2×2 kas hafızasını korurken koyu kutu ağırlığını tamamen yok eder; tabloya en fazla yüksekliği (`446 px`) bırakır.
- **Ödün:** 2 sütunlu olduğu için *Rogier van der Weyden* gibi uzun adlar `390×844`'te iki satıra kırılır.
- **Görüntüler:**
  - [Gece](goruntuler/sik-1-gece.png) · [Basılı an](goruntuler/sik-1-basili-gece.png) · [Cevap sonrası](goruntuler/sik-1-cevap-gece.png) · [Gündüz](goruntuler/sik-1-gunduz.png) · [Hangi akım?](goruntuler/sik-1-akim-gece.png) · [Küçük ekran 375×667](goruntuler/sik-1-kucuk-gece.png)

---

### Şık 2 — Kutusuz Mürekkep Şeritleri (`sik-2.html`)

**Rolü:** *Cam tepsi ve 2×2 ızgarayı tamamen kaldırıp doğrudan zemin üzerinde akan 4 tek satırlı mürekkep şeridi.*

- **Biçim ve yerleşim:** Altta ağır bir panel duvarı yoktur; ince çizgilerle ayrılmış 4 tam genişlikli satır (`47 px`, `375×667`'de `44 px`) doğrudan kömür / sıcak kâğıt zemine oturur.
- **Basılı hâl:** Dokunulan satır yuvarlatılmış mürekkep hapına dönüşür, sol kenarında `3 px` dikey pirinç iz yanar, metin hafifçe sağa kayar ve sağda pirinç ok (`>`) belirir.
- **Cevap sonrası:** Elenen 2 satırın boşalttığı tam `~94 px` alana geçiş bandı oturur; kalan doğru ve seçilen şeritler üstte yeşil `✓` / mercan `×` ile kalır (`0 px` tablo küçülmesi).
- **Güçlü yanı:** En uzun sanatçı ve akım adları bile **asla iki satıra kırılmaz**; göz yukarıdan aşağı tek düz çizgide tarar; Gündüz temasında dergi/katalog kadar sakin görünür.
- **Ödün:** 4 satır dikeyde `254 px` aldığı için dikey tablo yüksekliği `sik-1`'e göre `30 px` daha kısadır (`416 px`, yine ekranın en büyük öğesi).
- **Görüntüler:**
  - [Gece](goruntuler/sik-2-gece.png) · [Basılı an](goruntuler/sik-2-basili-gece.png) · [Cevap sonrası](goruntuler/sik-2-cevap-gece.png) · [Gündüz](goruntuler/sik-2-gunduz.png) · [Hangi akım?](goruntuler/sik-2-akim-gece.png) · [Küçük ekran 375×667](goruntuler/sik-2-kucuk-gece.png)

---

### Şık 3 — Akışkan Müze Fişleri (`sik-3.html`)

**Rolü:** *Sert ızgara ve satırları bırakıp her adı kendi doğal genişliğinde saran tam yuvarlak cam kapsüller.*

- **Biçim ve yerleşim:** Alt tepsi kutusu olmadan, hafif zemin geçişi üzerinde her sanatçı/akım adı kendi genişliğine uyumlu `999 px` yuvarlak cam fişler (`min-height: 48 px`, `375×667`'de `44 px`) hâlinde akar. Uzun ad (*Rogier van der Weyden*) kırpılmadan tek satırda oturur.
- **Basılı hâl:** Dokunulan fiş ters renge (Gece'de krem dolgu / koyu yazı, Gündüz'de koyu dolgu / krem yazı) dönerek mühür gibi öne çıkar (`scale(0.96)`), diğer 3 fiş `%42` opaklığa çekilir.
- **Cevap sonrası:** Elenen 2 fiş kapanır; kalan doğru ve seçilen 2 fiş tek satırda yeşil `✓` / mercan `×` ile yan yana kalır, açılan alt satır yerine geçiş çubuğu oturur (`0 px` tablo küçülmesi).
- **Güçlü yanı:** Koyu 2×2 kutu hissinden en çok uzaklaşan, müze etiketleri gibi hafif ve çağdaş görünüm; basılı hâldeki "mühür" geri bildirimi çok net; tablo alanı hâlâ çok büyük (`432 px`).
- **Ödün:** Dört şığın tamamı çok uzun isimlerden oluşursa 3 satıra sarkabilir (bu durumda sabit `238 px` içinde hâlâ sığar, `375×667`'de sıkılaşır).
- **Görüntüler:**
  - [Gece](goruntuler/sik-3-gece.png) · [Basılı an](goruntuler/sik-3-basili-gece.png) · [Cevap sonrası](goruntuler/sik-3-cevap-gece.png) · [Gündüz](goruntuler/sik-3-gunduz.png) · [Hangi akım?](goruntuler/sik-3-akim-gece.png) · [Küçük ekran 375×667](goruntuler/sik-3-kucuk-gece.png)

---

### Şık önerileri karşılaştırması

| Ölçüt | Şık 1 · İnce Haçlı Kartela | Şık 2 · Mürekkep Şeritleri | Şık 3 · Akışkan Müze Fişleri |
|---|---|---|---|
| Yerleşim | Tek cam yüzeyde `+` çizgili 2×2 | Zemin üstünde kutusuz 4 satır | Doğal genişlikli akışkan cam kapsüller |
| Uzun ad (`Rogier van der Weyden`) | 2 satır (rahat, kırpılmaz) | Tek satır (hiç kırılmaz) | Tek satır (doğal genişlik) |
| Basılı/seçili his | Kadife dolgu + `2 px` pirinç alt iz | Mürekkep hapı + sol dikey pirinç çizgi + ok | Ters renk mühür + diğerleri `%42` soluk |
| Tablo yüksekliği (`390×844`) | `446 px` (`0 px` değişim) | `416 px` (`0 px` değişim) | `432 px` (`0 px` değişim) |
| Alt zemin ağırlığı | Orta (kesintisiz cam tepsi) | En hafif (tepsisiz, saf zemin) | Hafif (yalnız yumuşak sis geçişi) |
| `375×667` sığma | Tek ekranda, tüm hedefler `≥ 44 px` | Tek ekranda, tüm hedefler `≥ 44 px` | Tek ekranda, tüm hedefler `≥ 44 px` |

---

## Üçüncü Tur · Müze ve Atölye Dünyasından Şık Tasarımları (`sik-4`, `sik-5`, `sik-6`)

İkinci turdaki ızgara (`sik-1`), liste (`sik-2`) ve hap (`sik-3`) biçimleri fazla sıradan bulunduğu için tamamen bırakıldı. Yön 3'ün üst bölümü (cam `×`, birleşik nokta + `3 / 8` hapı, sağda pirinç `Kolay`, ortada büyük kırpılmayan eser) birebir korunarak, alttaki şıklar **müze ve atölye dünyasından** üç farklı etkileşim diliyle yeniden tasarlandı (`sik-4.html`, `sik-5.html`, `sik-6.html`).

### Ortak garanti edilen kurallar

- **Izgara, liste ve hap biçimi yok:** Her öneri kendi fiziksel müze/atölye metaforunu taşır (çivili duvar künye plakaları, elde tutulan yelpaze kart destesi, balmumu mühürlü atölye imzaları).
- **Cevap sonrası `0 px` tablo küçülmesi:** Sabit alt yükseklik rezervi ve (`sik-4`'te) sabit `36 px` künye yuvası sayesinde cevap öncesi ve sonrası eser yüksekliği birebir aynı kalır:
  - `sik-4`: `416 px → 416 px` (`0 px` fark)
  - `sik-5`: `416 px → 416 px` (`0 px` fark)
  - `sik-6`: `432 px → 432 px` (`0 px` fark)
- **`"Tekrar"` düğmesi yok:** Cevap sonrasında yalnızca durum etiketi ve tek dolu geçiş düğmesi (`Hangi akım?` / `Sonraki`) görünür; yalnızca doğru ve seçilen şık ekranda kalır.
- **İpucu vermeyen nötr dil:** Çiviler, kart süsleri, mühür diskleri ve baş harf inisiyalleri bütün şıklarda aynı nötr pirinç/mürekkep tonundadır; dönem/akım rengi veya tarih sızdırılmaz.
- **Hareket azaltma (`prefers-reduced-motion` / *Hareketi azalt*):** Plaka sallanması (`civiSallan`), 3B kart dönüşü (`kartDon`) ve balmumu mühür basma sıçraması (`muhurBas`) sade anlık durum geçişine iner; yanlış plaka eğilmeden düz durur.
- **Ölçülen ekran ve dokunma hedefleri:** 18 görüntünün tamamında `scrollWidth = 390` (`375×667`'de `375`), taşan veya kırpılan öğe `0`, kırık görsel `0`, dış URL `0`, tüm etkileşimli düğmeler `≥ 44 px` ve başparmak erimindedir.

### Dokunsal geri bildirim (titreşim) anları

| An | Şık 4 · Künye Plakaları | Şık 5 · El Yelpazesi | Şık 6 · Balmumu Mühür | `Titresim.swift` karşılığı |
|---|---|---|---|---|
| Parmağı koyma / kaldırma | Plaka duvardan kalkar, yuva pirinçle yanar | Kart yelpazeden yukarı sıyrılır | İmza altı mürekkep çizilir, köşede mühür önizlenir | `Titresim.secim` |
| Doğru seçim | Plaka çerçevenin altındaki yuvaya oturur | Kart 3B ters döner, yeşil onay görünür | Tablonun sağ alt köşesine yeşil balmumu basılır | `Titresim.dogru` (`.success`) |
| Yanlış seçim | Doğru plaka yuvaya yerleşir; yanlış plaka tek çividen sallanır | Kalan iki kart 3B dönüp `Doğrusu` / `Seçtiğin` gösterir | Köşeye mercan mühür basılır, yanlış imzanın üstü çizilir | `Titresim.yanlis` (`.error`) |
| `"Bilmiyorum"` | Doğru künye yuvaya sessizce takılır | Doğru kart tek başına dönerek açılır | Doğru imza yeşil mühürle vurgulanır | `Titresim.dokunus` (`.light`) |

---

### Şık 4 — Müze Künye Plakaları (`sik-4.html`)

**Rolü:** *Müzede tablonun altında duran pirinç çivili duvar plakaları — hem tek dokunuşla hem tabloya sürükleyip bırakarak takılır.*

- **Biçim ve yerleşim:** Tablonun hemen altında kesik pirinç çizgili bir **künye yuvası** (`Plakaya dokun ya da buraya sürükle`) bekler. Altta ise iki yandan pirinç çivili, hafif farklı açılarla duran 4 müze plakası (Gece'de koyu bronz/ceviz, Gündüz'de sıcak mermer) iki asimetrik satırda yer alır. Uzun ad (*Rogier van der Weyden*) tek satırda kırpılmadan sığar.
- **Dokunma ve sürükle-bırak:** Plakaya basınca (veya yukarı sürükleyince) plaka duvardan kalkıp düzleşir (`scale(1.04)`), diğer plakalar `%42`'ye çekilir ve tablonun altındaki yuva pirinçle parlayarak (`Künye yuvasına takılıyor`) plakayı çağırır.
- **Cevap sonrası:** Doğru plaka doğrudan tablonun altındaki künye yuvasına düz ve yeşil çivili olarak **takılır**. Yanlış seçildiyse seçilen yanlış plaka sağ çivisinden kurtulup sol çividen `-5.5°` eğilerek sallanır (`civiSallan`); elenen 2 plaka çekilir.
- **Hangi akım? (Soru 2 / 2):** Aynı plaka dili ince iç çerçeve süsüyle (`akim-sus`) çalışır.
- **Güçlü yanı:** Müze deneyimiyle en doğrudan fiziksel bağ; hem hızlı tek dokunuş hem de keyifli sürükle-bırak desteği; doğru yanıt tablonun gerçek künyesi hâline gelir.
- **Ödün:** Künye yuvası tablonun hemen altında sabit `36 px` yer tuttuğu için eser yüksekliği `416 px`'tir (`sik-6`'dan `16 px` kısa, hâlâ ekranın en büyük öğesi).
- **Görüntüler:**
  - [Gece](goruntuler/sik-4-gece.png) · [Basılı / sürükleme](goruntuler/sik-4-basili-gece.png) · [Cevap sonrası](goruntuler/sik-4-cevap-gece.png) · [Gündüz](goruntuler/sik-4-gunduz.png) · [Hangi akım?](goruntuler/sik-4-akim-gece.png) · [Küçük ekran 375×667](goruntuler/sik-4-kucuk-gece.png)

---

### Şık 5 — El Yelpazesi Müze Kartları (`sik-5.html`)

**Rolü:** *Elde tutulan 4 zarif müze kataloğu kartı altta doğal başparmak yayıyla yelpaze gibi açılır.*

- **Biçim ve yerleşim:** Dört dikey müze kartı (`-8.5°`, `-2.8°`, `+2.8°`, `+8.5°`) hafifçe üst üste binerek el yelpazesi oluşturur. Her kartta yalnız nötr bir elmas süsü, ince pirinç iç çerçeve ve ad bulunur; ipucu yoktur. Gündüz temasında sıcak keten karton hissi verir.
- **Basılı an:** Dokunulan kart yelpazeden `24 px` yukarı sıyrılır, açısı sıfırlanıp `scale(1.08)` ile öne gelir ve pirinç çerçevesi parlar; diğer 3 kart `%48` opaklığa iner.
- **Cevap sonrası:** Elenen 2 kart desteden çekilir; kalan doğru ve seçilen kartlar yan yana düzleşerek **3B ters döner** (`rotateY`), çift iç çerçeveli arka yüzlerinde yeşil/mercan mühür ile `Doğrusu` / `Seçtiğin` etiketi görünür.
- **Hangi akım? (Soru 2 / 2):** Kartların iç çerçevesi çift pirinç çizgili dönem kartı süslemesine geçer.
- **Güçlü yanı:** En oyunsu, dokunması en davetkâr ve başparmak kavisini en doğal izleyen etkileşim; 3B dönüş anı çok tatmin edici.
- **Ödün:** Dört dikey kart yan yana dizildiği için *Rogier van der Weyden* gibi uzun adlar kart içinde 3 satıra sarılır (tam okunur ve kırpılmaz).
- **Görüntüler:**
  - [Gece](goruntuler/sik-5-gece.png) · [Kart kalkarken](goruntuler/sik-5-basili-gece.png) · [Cevap sonrası](goruntuler/sik-5-cevap-gece.png) · [Gündüz](goruntuler/sik-5-gunduz.png) · [Hangi akım?](goruntuler/sik-5-akim-gece.png) · [Küçük ekran 375×667](goruntuler/sik-5-kucuk-gece.png)

---

### Şık 6 — Atölye İmzaları ve Balmumu Mühür (`sik-6.html`)

**Rolü:** *Kutusuz ve en sade atölye dili: her şık italik bir ressam imzası ve kabartma balmumu mühürdür; seçilince mühür doğrudan tablonun köşesine basılır.*

- **Biçim ve yerleşim:** Altta hiçbir kutu, kart veya çizgi ızgarası yoktur. Dört sanatçı adı *Newsreader Italic* ile hafif organik eğimlerle (`-0.9°` .. `+0.7°`) iki dengeli atölye satırında durur; her birinin yanında aynı nötr tonda kabartma inisiyal mühür diski (`JE`, `RC`, `RW`, `PC`) ve sol ucunda soluk dolmakalem izi bulunur.
- **Basılı an:** Parmağı basınca imzanın altındaki pirinç mürekkep çizgisi soldan sağa tamamlanır, mühür diski hafifçe dönüp büyür ve **tablonun sağ alt köşesinde** yarı saydam kesik çizgili mühür önizlemesi (`RW`) belirir.
- **Cevap sonrası:** Tablonun sağ alt köşesine kabartmalı fiziksel balmumu mühür (`✓` yeşil veya `×` mercan) **basılır** (`muhurBas` animasyonu). Altta yalnızca doğru imza (yeşil mühür + yeşil alt çizgi) ve yanlış seçilen imza (mercan mühür + üstü çizili ad) kalır.
- **Hangi akım? (Soru 2 / 2):** İmzalar dik *Newsreader* tipografisine ve akım inisiyallerine (`KR`, `ER`, `YR`, `B`) geçer; aynı köşe mühürleme mekaniği sürer.
- **Güçlü yanı:** Üç öneri arasında en ferah, en sade ve tabloya en büyük yüksekliği (`432 px`) bırakan tasarım; hiçbir kutu gürültüsü olmadan sanat atölyesi ruhunu doğrudan taşır.
- **Ödün:** Köşeye basılan `52 px` balmumu mühür cevap anında tablonun sağ alt köşesinin küçük bir parçasını bilinçli olarak örter (yakın inceleme açıldığında tablo yine tertemiz görünür).
- **Görüntüler:**
  - [Gece](goruntuler/sik-6-gece.png) · [Mühür basılırken](goruntuler/sik-6-basili-gece.png) · [Cevap sonrası](goruntuler/sik-6-cevap-gece.png) · [Gündüz](goruntuler/sik-6-gunduz.png) · [Hangi akım?](goruntuler/sik-6-akim-gece.png) · [Küçük ekran 375×667](goruntuler/sik-6-kucuk-gece.png)

---

### Üçüncü tur karşılaştırması

| Ölçüt | Şık 4 · Müze Künye Plakaları | Şık 5 · El Yelpazesi Kartları | Şık 6 · Atölye İmzaları ve Mühür |
|---|---|---|---|
| Müze / atölye metaforu | Çivili duvar künyesi + askı yuvası | Elde tutulan müze kart destesi | Ressam imzası + balmumu mühür |
| Etkileşim | Dokun **veya** tabloya sürükle-bırak | Yelpazeden çekip 3B ters çevir | İmza çiz + tablo köşesine mühür bas |
| Uzun ad (`Rogier van der Weyden`) | Tek satır (kırpılmaz) | 3 satır (kart içinde ortalı) | Tek satır (kırpılmaz) |
| Yanlış cevap görsel dili | Doğru yuvada; yanlış tek çividen sarkar | İki kart 3B dönüp `Doğrusu` / `Seçtiğin` | Köşede mercan mühür + üstü çizili imza |
| Tablo yüksekliği (`390×844`) | `416 px` (`0 px` değişim) | `416 px` (`0 px` değişim) | `432 px` (`0 px` değişim) |
| Görsel ağırlık | Orta (fiziksel plaka dokusu) | Orta-canlı (oyunsu yelpaze) | En hafif ve en sakin (kutusuz) |
| `375×667` sığma | Tek ekranda, hedefler `≥ 44 px` | Tek ekranda, hedefler `≥ 44 px` | Tek ekranda, hedefler `≥ 44 px` |
