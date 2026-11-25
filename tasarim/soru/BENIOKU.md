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
