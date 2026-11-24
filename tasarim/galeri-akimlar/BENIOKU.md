# Galeri · Akımlar Ekranı — Tasarım Yönleri

Galeri sekmesinin açılış ekranı (`GaleriAna.swift` / `gozat.js` Akımlar) için üç farklı yeniden tasarım önerisi. Mevcut ekrandaki dairesel **Akımlar çarkı**, dikey kaydırmayla çakışıp dokunuşları yuttuğu ve 28 akımı tek tek çevirmeyi gerektirdiği için her üç yönde de çarkın bu sorunu kökten çözülmüştür.

Bütün dosyalar `390×844` iPhone genişliğinde, yukarıdan aşağı kaydırılan tam sayfa olarak hazırlanmıştır; yerel kamu malı tablolar ([`gorseller/`](gorseller/), 8 dönemden `1280 px`), uygulamanın kendi dönem desen karoları (`NoraSanat/Ekranlar/Galeri/Desenler/desen-*.png`) ve değişken yazı tipleriyle (`NoraSanat/YaziTipleri/`) internetsiz çalışır. Üst çubuktan **Gece / Gündüz** teması değiştirilebilir; dönem atlama, akım seçme, yatay şerit kaydırma ve dizin satırından salon seçme etkileşimleri HTML içinde canlıdır.

## Ortak temel ve gerçekçi içerik

- **Gerçek 28 akım ve 9 dönem grubu:** Uygulamanın canlı kataloğundaki (`akimlar.json`, `BOLGELER`) bütün 28 akım, kronolojik sırayla ve 9 dönem grubunda (`Orta Çağ`, `Rönesans`, `Barok`, `Klasisizm ve Geç Barok`, `Rokoko ve Neoklasisizm`, `Romantizmden Realizme`, `Empresyonizm`, `Post-Empresyonizm ve Sembolizm`, `Modern sanat`) yer alır.
- **Örnek kullanıcı konumu:** Konu 35'e kadar işlenmiş gerçekçi bir orta nokta seçildi (**10 açık salon**, 18 kilitli). Ekran kullanıcının güncel salonu olan **Hollanda Altın Çağı**'nda (`2 / 5 sanatçı açık`, Barok) açılır; sıradaki kilitli salon **Fransız Klasisizmi** (`Konu 37'de açılır`).
- **8 farklı dönemden Wikimedia Commons kamu malı eser (`1280 px`):**
  1. Orta Çağ: Giotto, *Ağıt* (y. 1305) — [`ortacag.jpg`](gorseller/ortacag.jpg)
  2. Rönesans: Sandro Botticelli, *Venüs'ün Doğuşu* (y. 1485) — [`ronesans.jpg`](gorseller/ronesans.jpg)
  3. Barok: Johannes Vermeer, *İnci Küpeli Kız* (1665) — [`barok.jpg`](gorseller/barok.jpg)
  4. Klasisizm / Rokoko: Jean-Honoré Fragonard, *Salıncak* (1767) — [`rokoko.jpg`](gorseller/rokoko.jpg)
  5. Romantizmden Realizme: Caspar David Friedrich, *Bulut Denizinin Üzerindeki Gezgin* (1818) — [`romantik.jpg`](gorseller/romantik.jpg)
  6. Empresyonizm: Claude Monet, *İzlenim, Gün Doğumu* (1872) — [`empresyonizm.jpg`](gorseller/empresyonizm.jpg)
  7. Post-Empresyonizm: Vincent van Gogh, *Yıldızlı Gece* (1889) — [`postempresyonizm.jpg`](gorseller/postempresyonizm.jpg)
  8. Modern sanat: Edvard Munch, *Çığlık* (1893) — [`modern.jpg`](gorseller/modern.jpg)
- **Dinamik üç katmanlı zemin:** Herhangi bir akım seçildiğinde kömür / sıcak kâğıt zemin üstündeki iki renkli tablo halesi ve o dönemin gerçek `96×96` desen karosu (`desen-<donem>@3x.png`, Gece %4 / Gündüz %4,5) canlı olarak değişir.
- **Ortak kurallar:** Üstte `"Galeri"`, `"Sanatçı, eser ara"`, kalp ve `Akımlar · Başyapıtlar · Konular · Zaman` cam sekme kabı; ekranda **tek dolu düğme** (`"Salona gir"`); tüm dokunma hedefleri en az `44 px`; `390 px`'te sıfır yatay sayfa taşması (`scrollW=390`).

---

## Yön 1 — Müze katları (`yon-1.html`)

**Yaklaşım:** Bugünkü ekranın çok sevilen **kemerli tablo kartını** koruyup, dokunuşları ve dikey kaydırmayı bozan dairesel çarkı tamamen kaldıran en dingin, en tanıdık evrim.

- **Neden bu yön?** Çarkın yerine `TASARIM_DILI.md`'deki `2 px` pirinç alt çizgili **9 dönem atlama şeridi** gelir: *Orta Çağ*'dan *Modern*'e 27 kez çevirmek yerine tek dokunuşla zıplanır. Kemerli kart şeridi yalnız doğal yatay `scroll-snap` kullanır, dikey kaydırmayı asla yakalamaz; altında önceki/sonraki hafif ok düğmeleriyle tek dokunuşta da ilerlenir. Kilitli akımlar soğuk griye boğulmak yerine sıcak kehribar-sepya buğu altında renk sezdirerek merak uyandırır. Altındaki **Bütün akımlar** dizini, 9 dönem başlığı altında `TASARIM_DILI.md`'nin gruplu liste düzeniyle açılıp kapanabilir.
- **En güçlü olduğu yer:** Mevcut kemer kimliğini kaybetmeden çark sorununu sıfıra indiren, en düşük riskli ve en hızlı uygulanabilir geçiş.
- **Ödün:** İlk ekranda aynı anda yalnızca tek bir odak salon tam görünür; 28 akımın bütün dağılımını görmek için aşağı kaydırmak gerekir.
- **`TASARIM_DILI.md`'den ayrılışlar:**
  - *Bölüm sekmelerinde yumuşak cam vurgu:* Seçili bölüm sekmesi dolu `--ink` hap yerine yarı saydam cam hap (`rgba(var(--ink-rgb), 0.14)`) kullanır; böylece ekrandaki tek dolu düğme kuralı `"Salona gir"` için tartışmasız biçimde korunur.
  - *Kemer tepesinde küçük dönem sembolü madalyonu:* Arka plan karosuna ek olarak her kemerin tepesine ince cam daire içinde dönemin sembolü kondu; çünkü akım kaydırılırken dönemin değiştiği gözle anında yakalansın.
- **Görüntüler:** [Gece](goruntuler/yon-1-gece.png) · [Gündüz](goruntuler/yon-1-gunduz.png)

---

## Yön 2 — Yedi yüzyıl duvarı (`yon-2.html`)

**Yaklaşım:** Yatay karusel ve çark fikrinden tamamen vazgeçip **dikey kaydırmanın kendisini 700 yıllık bir müze yürüyüşüne** dönüştüren editoryal duvar düzeni.

- **Neden bu yön?** Telefonda en doğal ve hiç çakışmayan hareket dikey kaydırmadır. Ekranın tepesinde kullanıcının şu anki salonu (**Hollanda Altın Çağı**) tek dolu `"Salona gir"` düğmesi ve hemen altındaki `"Sıradaki kilit: Fransız Klasisizmi · Konu 37'de açılır"` satırıyla tam odak kartı olarak durur. Hemen altında **Hızlı dönem cetveli** (`Tümü (28) · Orta Çağ · Rönesans · …`) ile istenen dönem tek dokunuşta süzülebilir. Aşağı indikçe 9 dönem kendi büyük sembol mührü ve 2 sütunlu müze duvarı kartlarıyla akar; açık akımlar canlı ve ince `3 px` doluluk çizgili, kilitli dönemler ise ince buzlu cam perde arkasında yumuşak renkli silüetler ve `Konu N'de açılır` fısıltısıyla merak uyandırır. En altta 28 salonluk açılır metin dizini yer alır.
- **En güçlü olduğu yer:** Kaydırma akıcılığı, 28 akımın görsel zenginliğini birden sergileme ve Gündüz temasında basılı sergi kataloğu hissi.
- **Ödün:** Bütün 28 akım kart olarak açıkken tam sayfa boyu diğer iki yönden uzundur (dönem cetveliyle süzülünce tek ekrana iner).
- **`TASARIM_DILI.md`'den ayrılışlar:**
  - *Bölüm sekmelerinde yumuşak cam vurgu:* `"Salona gir"` düğmesinin ekrandaki tek dolu düğme kalması için üst sekme kabında yumuşak cam seçili durum tercih edildi.
  - *Kilitli kartlarda renkli buğulu pencere:* Kilitli akımlar tamamen griye döndürülmek yerine düşük doygunluklu, hafif bulanık renkli önizleme ve buzlu kilit etiketiyle bırakıldı; çünkü açılmamış dönemler "kapalı duvar" gibi değil, aralanmayı bekleyen salonlar gibi merak uyandırsın.
- **Görüntüler:** [Gece](goruntuler/yon-2-gece.png) · [Gündüz](goruntuler/yon-2-gunduz.png)

---

## Yön 3 — Küratörün atlası (`yon-3.html`) *(Cesur ve tamamen yeni yön)*

**Yaklaşım:** Çalış sekmesindeki Yön 4'ün *"ilk ekranda bütün resim"* ilkesini Galeri'ye taşıyan radikal öneri: dairesel çark yerine **kenardan kenara Yaşayan Salon Duvarı** + **28 Çentikli Mimari Yüzyıl Cetveli** + **"Sırada seni bekleyenler"** merak vitrini.

- **Neden bu yön?**
  - **Yaşayan Salon Duvarı:** Seçili akımın tablosu ekranın en üstünden kenardan kenara (`446 px`) akar, altta yumuşakça zemine erir; `"Galeri"` başlığı, arama ve 4 bölüm sekmesi tablonun üstünde ince cam olarak süzülür. Altında `Hollanda Altın Çağı`, açık sanatçıları sezgisel gösteren ince nokta dizisi (`● ● ○ ○ ○`) ve ekrandaki **tek dolu düğme** (`"Salona gir"`) yer alır.
  - **Çarkın yerine 28 Çentikli Mimari Yüzyıl Cetveli (`1210 ———— 1992`):** 28 akımın tamamı tek bir kartta 28 ince dikey çentik olarak görünür: açık 10 salon yüksek aydınlık çentikler, seçili salon parlayan pirinç ibre, 11. sıradaki kilitli *Fransız Klasisizmi* kesikli pirinç işaretli, kalan 17 salon alçak çentiklerdir. Altındaki 9 dönem sekmesi ve o dönemin en çok 4–5 akım hapıyla **700 yılın herhangi bir noktasına tek dokunuşla** atlanır; dikey sayfa kaydırmasıyla çakışma ihtimali sıfırdır.
  - **Sırada seni bekleyenler (Merak vitrini):** Hemen altında yaklaşan 4 farklı dönemin (*Fransız Klasisizmi*, *Romantizm*, *Empresyonizm*, *Post-Empresyonizm*) buğulu renkli önizleme kartları yatay bir şeritte görünür; dokununca üstteki dev duvar anında o kilitli döneme dönüp merak uyandırır.
  - **Bütün akımlar dizini:** Sayfanın devamında 28 akımın tamamı 9 dönem grubu, sembolleri ve küçük eser pullarıyla tek dokunuşta seçilebilir.
- **En güçlü olduğu yer:** İlk bakışta 28 akımın tamamındaki yerini, sıradaki kilidi ve tablonun atmosferini bir arada sunması; 700 yıl arasında tek dokunuşla gezinebilme hızı; kilitli dönemleri en güçlü merak ettiren kurgu.
- **Ödün:** 28 çentiğin bireysel dokunma aralığı dar olduğundan hassas seçim alttaki dönem sekmeleri ve 44 px'e yakın akım haplarıyla tamamlanır (çentikler doğrudan harita göstergesi + hızlı dokunma olarak çalışır).
- **`TASARIM_DILI.md`'den ayrılışlar:**
  - *Bölüm sekmelerinde cam üstü yumuşak vurgu:* Tablo kenardan kenara en tepeden başladığı için üst arama ve bölüm sekmeleri koyu cam katmanla tablonun üstüne oturtuldu; böylece `"Salona gir"` tek dolu düğme kalır ve tablo ekranın kahramanı olur.
  - *28 çentikli mimari yüzyıl cetveli:* Çark ve düz liste yerine 28 dikey çentikten oluşan kompakt bir zaman haritası eklendi; çünkü kullanıcı 10/28 ilerlemesini ve sıradaki kilidin 700 yıllık çizgideki yerini tek bakışta okuyabilsin.
  - *Sanatçı doluluğu için nokta dizisi (`● ● ○ ○ ○`):* `"2 / 5 sanatçı açık"` metninin yanına ince noktalar kondu; çünkü bir salonun ne kadarının keşfedildiği sayı okumadan da hissedilsin.
  - *"Sırada seni bekleyenler" merak şeridi:* Kilitli akımlar yalnızca dizinin dibine itilmek yerine 4 farklı dönemin buğulu vitrin kartıyla öne çıkarıldı; çünkü açılmamış dönemler yeni ders açma iştahı uyandırsın.
- **Görüntüler:** [Gece](goruntuler/yon-3-gece.png) · [Gündüz](goruntuler/yon-3-gunduz.png)

---

## Kısa karşılaştırma

| Ölçüt | Yön 1 · Müze katları | Yön 2 · Yedi yüzyıl duvarı | Yön 3 · Küratörün atlası |
|---|---|---|---|
| Çarkın yerine gelen mekanizma | 9 dönem atlama şeridi + yatay kemer kaydırma | Dikey müze duvarı + dönem süzme cetveli | 28 çentikli mimari yüzyıl cetveli + dönem akım hapları |
| Dikey kaydırma çakışması | Yok (doğal `scroll-snap`) | Yok (saf dikey akış) | Yok (çark ve yatay karusel yok) |
| 28 akımda nerede olduğum | Üstte tek satır özet + ince 3 px çubuk | Odak kartında + her dönem başlığında | 28 çentikli zaman haritasında tek bakışta |
| Kilitli akımlarda merak | Sıcak sepya-buğu kemer + cam kilit etiketi | Buzlu cam renkli duvar kartları | Ayrı "Sırada seni bekleyenler" vitrin şeridi |
| Dönem sembolü kullanımı | Zemin karosu + sekme + kemer madalyonu | Zemin karosu + büyük dönem mührü | Zemin karosu + duvar mührü + cetvel + dizin |
| Tek dokunuşla 700 yıl atlama | Dönem şeridiyle (1 dokunuş) | Dönem süzgeciyle (1 dokunuş) | Yüzyıl cetveli + dönem sekmesiyle (1 dokunuş) |
| Uygulama akrabalığı | Mevcut kemerlerin temiz evrimi | Başyapıtlar duvarı & Çalış Yön 4 | Bugün perdesi & Çalış Yön 4 |
| SwiftUI geçiş karmaşıklığı | En düşük | Düşük–orta | Orta (yeni yüzyıl cetveli bileşeni) |
