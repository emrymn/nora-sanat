# Galeri · Akımlar Ekranı — İkinci Tasarım Denemesi

Galeri sekmesinin açılış ekranı (`NoraSanat/Ekranlar/Galeri/GaleriAna.swift`, `GaleriGorunusu.swift`, site karşılığı `js/ekranlar/gozat.js`) için ikinci tasarım denemesi.

İlk denemenin (`neon/galeri-akimlar-tasarim`, PR #56) ardından radikal yeni düzen aramak yerine **bugünkü kemerli salon kartları** fikri korundu; kenardan kenara kapak, yüzyıl cetveli, iki sütunlu tablo duvarı ve aşırı uzun sayfa tamamen dışarıda bırakıldı. Bütün odak **işçilik, sakin akış, sade bilgi hiyerarşisi ve yumuşak geçiş hissine** verildi.

---

## Bugünkü ekrandaki sorunlar ve çözümleri

1. **Çarkın dokunuş ve sayfa kaydırmayı engellemesi:** Her üç yönde de dikey sayfa kaydırmasını tutan dairesel çark yerine doğal yatay `scroll-snap` (`touch-action: pan-x pan-y`) ve dikey kaydırmayı asla yakalamayan hafif gezinme araçları kuruldu.
2. **Sert komşu küçülmesi ve kopuk geçiş:** Mevcut doğrusal `scale(1 − 0.2k)`, `translateY(30k)` ve `1 − 1.6k` sert düşüşleri yerine kosinüs tabanlı nefes alan eğriler, kaydırma boyunca kare kare (`requestAnimationFrame`) harmanlanan **iki renkli tablo halesi**, çapraz solan **dönem sembolü deseni** (`desen-<donem>@3x.png`) ve birbirinin üstüne binmeyen metin geçişleri eklendi.
3. **Alt bölüm kalabalığı ve bilgi tekrarı:** Tablo içine bindirilen rozet/etiketler, tekrarlanan dönem adları, ilerleme çubuğu ve başlangıçta açık durup sayfayı uzatan 28 satırlık liste kaldırıldı. Kart altında yalnızca gereken dört bilgi bırakıldı: **dönem sembolü + yıllar**, **akım adı**, **açık sanatçı ya da kilit bilgisi**, ve ekrandaki **tek dolu düğme (`Salona gir`)**.

---

## Ortak temel ve gerçek içerik

- **Gerçek 28 akım ve 9 dönem grubu:** Kataloğun kronolojik sırasıyla 28 akımı (`Gotik` → `Savaş sonrası figürasyon`) ve 9 dönemi (`Orta Çağ`, `Rönesans`, `Barok`, `Klasisizm ve Geç Barok`, `Rokoko ve Neoklasisizm`, `Romantizmden Realizme`, `Empresyonizm`, `Post-Empresyonizm ve Sembolizm`, `Modern sanat`).
- **Örnek kullanıcı konumu:** Konu 35 işlenmiş gerçekçi orta nokta (**10 açık salon**, 18 kilitli). Ekran **Hollanda Altın Çağı**’nda (`1582–1682`, `2 / 5 sanatçı açık`, Barok) açılır; solda açık komşusu **Flaman Barok**, sağda ise sıradaki kilitli **Fransız Klasisizmi** (`Konu 37’de açılır`) buğulu kapağıyla görünür.
- **28 akımın tamamı için 28 farklı kamu malı tablo (`gorseller/`, `1280 px`, Wikimedia Commons, sıfır tekrar, sıfır dış adres):**
  1. Gotik — Duccio di Buoninsegna, *Rucellai Madonnası* (`01-gotik.jpg`)
  2. Erken Rönesans — Sandro Botticelli, *Venüs’ün Doğuşu* (`02-erken-ronesans.jpg`)
  3. Kuzey Rönesansı — Jan van Eyck, *Arnolfini Portresi* (`03-kuzey-ronesansi.jpg`)
  4. Yüksek Rönesans — Leonardo da Vinci, *Mona Lisa* (`04-yuksek-ronesans.jpg`)
  5. Venedik Rönesansı — Tiziano, *Bakhüs ve Ariadne* (`05-venedik-ronesansi.jpg`)
  6. Maniyerizm — Parmigianino, *Uzun Boyunlu Madonna* (`06-maniyerizm.jpg`)
  7. İtalyan Barok ve Caravaggizm — Caravaggio, *Golyat’ın Başıyla Davut* (`07-italyan-barok.jpg`)
  8. İspanyol Barok — Diego Velázquez, *Nedimeler* (`08-ispanyol-barok.jpg`)
  9. Flaman Barok — Peter Paul Rubens, *Hasır Şapkalı Kız* (`09-flaman-barok.jpg`)
  10. Hollanda Altın Çağı — Johannes Vermeer, *İnci Küpeli Kız* (`10-hollanda-altin-cagi.jpg`)
  11. Fransız Klasisizmi — Nicolas Poussin, *Et in Arcadia ego* (`11-fransiz-klasisizmi.jpg`)
  12. Geç İtalyan Barok — Canaletto, *Büyük Kanal’ın Girişi, Venedik* (`12-gec-italyan-barok.jpg`)
  13. Rokoko — Jean-Honoré Fragonard, *Salıncak* (`13-rokoko.jpg`)
  14. Neoklasisizm — Jacques-Louis David, *Marat’nın Ölümü* (`14-neoklasisizm.jpg`)
  15. Romantizm — Caspar David Friedrich, *Bulut Denizinin Üzerindeki Gezgin* (`15-romantizm.jpg`)
  16. Prerafaelitler — Dante Gabriel Rossetti, *Beata Beatrix* (`16-prerafaelitler.jpg`)
  17. Akademizm ve Oryantalizm — Jean-Léon Gérôme, *Pollice Verso* (`17-akademizm-oryantalizm.jpg`)
  18. Barbizon ve Realizm — Jean-François Millet, *Başak Toplayanlar* (`18-barbizon-realizm.jpg`)
  19. Empresyonizm — Claude Monet, *İzlenim, Gün Doğumu* (`19-empresyonizm.jpg`)
  20. Ukiyo-e (Japon baskısı) — Katsushika Hokusai, *Kanagawa’nın Büyük Dalgası* (`20-ukiyo-e.jpg`)
  21. Post-Empresyonizm — Vincent van Gogh, *Yıldızlı Gece* (`21-post-empresyonizm.jpg`)
  22. Sembolizm — Gustave Moreau, *Görüntü* (`22-sembolizm.jpg`)
  23. Art Nouveau ve Viyana Secession — Gustav Klimt, *Öpücük* (`23-art-nouveau.jpg`)
  24. Ekspresyonizm — Edvard Munch, *Çığlık* (`24-ekspresyonizm.jpg`)
  25. Kübizm — Juan Gris, *Picasso’nun Portresi* (`25-kubizm.jpg`)
  26. Dada — Francis Picabia, *Udnie* (`26-dada.jpg`)
  27. Sürrealizm — Paul Klee, *Senecio* (`27-surrealizm.jpg`)
  28. Savaş sonrası figürasyon — Amedeo Modigliani, *Jeanne Hébuterne* (`28-savas-sonrasi.jpg`)
- **Dinamik üç katmanlı zemin (`TabloRenkleri` uyumlu):** Her tablonun kendi baskın renk çifti çıkarıldı; kart kayarken sol üst ve sağ alt hale RGB düzeyinde kesintisiz harmanlanır (Gündüz’de `multiply`), dönem sınırı geçilince `desen-<donem>@3x.png` karosu yumuşakça çapraz solar (Gece %4, Gündüz %4,5).
- **Kilitli akımlar:** Soğuk griye boğulmak yerine tablonun renk tonlarını sezdiren sıcak buğulu cam (`blur` + hafif doygunluk) ve merkezde sade bir cam kilit mührüyle merak uyandırır; açık ve kilitli kartlar arasında geçişte dikey yükseklik hiç zıplamaz.
- **Teknik doğrulama:** `390×844` telefon genişliğinde sıfır yatay taşma (`scrollWidth = 390`), tüm etkileşimli öğeler en az `44 px`, yerel yazı tipleri (`NoraSanat/YaziTipleri/`) ve yerel desenlerle internetsiz çalışma, Gece ve Gündüz desteği.

---

## Yön 1 — Sakin Kemerler (`yon-1.html`)

**En saf, en ferah evrim — "Müze koridorunda yürümek"**

- **Geçiş hareketi:** Kemerli kartlar kosinüs eğrisiyle usulca büyüyüp küçülür (`0.90 → 1.00`, en çok `12 px` alçalma, komşular sıcak biçimde görünür kalır). Kaydırırken tablo kemer içinde hafif paralaksla (`±14 px`) nefes alır; bir kapı aralığından yandaki salona bakar gibi derinlik verir. Alttaki metin çakışmayan nefes zarfıyla kemerle eşzamanlı kayıp belirir.
- **Gezinme biçimi:** Çarkın yerine üstte tek satır, kutusuz **ince 9 dönem şeridi** gelir. Seçili dönemin altındaki `2 px` pirinç çizgi dönem sınırından geçerken parmakla birlikte komşu döneme kayar; altta yalnız bulunulan dönemin salonlarını gösteren sessiz nokta izi (`• • • —`) yer alır.
- **Alt bölüm:** İlk ekranda kapalı duran tek satırlık sakin **`Bütün akımlar · 28 salon`** açıcısı. Sayfa başlangıçta tam `844 px` içinde dengeli durur; dokunulunca 9 dönemlik gruplu liste yerinde açılır.
- **Neden tercih edilir?** En az arayüz gürültüsü, tek dokunuşta dönem atlama ve SwiftUI’ye en yalın geçiş.
- **Ödün:** İlk bakışta aynı anda yalnızca tek bir dönemin iç dizilimi nokta iziyle görünür; diğer salon adları için dizini açmak gerekir.
- **Görüntüler:** [Gece](goruntuler/yon-1-gece.png) · [Gündüz](goruntuler/yon-1-gunduz.png) · [Geçiş karesi](goruntuler/yon-1-gecis.png)

---

## Yön 2 — Kemerlerin Yayı (`yon-2.html`)

**Eski çarkın şiirini koruyup sıkıntısını çözen yön — "Rotunda yayı ve hafif Işık Kılavuzu"**

- **Geçiş hareketi:** Kemerler kayarken geniş bir mimari yay boyunca çok hafif eğilir (`±2.6°`) ve yumuşakça alçalıp yükselir (`15 px`). Çift ince pirinç çerçeve merkezde ışıldar. Başlık ve durum yazısı doğrudan kendi kemerine bağlı akar; **`Salona gir`** düğmesi ise altta sabit yuvasında kalır, böylece başparmak düğmeyi kovalamaz.
- **Gezinme biçimi:** Üstte hiç dönem şeridi yoktur; kemer doğrudan bölüm sekmelerinin altından yükselir. Eski `150 px`’lik çarkın yerine düğmenin altında **`52 px`’lik hafif Işık Kılavuzu** yer alır: ince pirinç bir ufuk yayı, kartlarla eşzamanlı kayan çentikler, ortada sıcak ışık noktası ve iki yanda tek dokunuşluk komşu dönem geçişleri (`‹ Rönesans · Barok · Klasisizm ›`). `touch-action: pan-y` ile dikey kaydırmayı asla yakalamaz.
- **Alt bölüm:** En altta sade **`Bütün akımlar · 28 salon`** bağlantısı; dokunulunca ekranın altından iOS tarzı buzlu cam bir **çekmece (sheet)** kayarak açılır. Ana ekran hiçbir zaman uzayıp ağırlaşmaz.
- **Neden tercih edilir?** Eski ekranın sevilen ışıklı yay karakterini koruyarak takılma ve kalabalık sorununu tamamen giderir.
- **Ödün:** 700 yıl ötedeki bir döneme atlamak için ya komşu dönemlere birkaç kez dokunmak ya da cam dizin çekmecesini açmak gerekir.
- **Görüntüler:** [Gece](goruntuler/yon-2-gece.png) · [Gündüz](goruntuler/yon-2-gunduz.png) · [Geçiş karesi](goruntuler/yon-2-gecis.png)

---

## Yön 3 — Müze Odası (`yon-3.html`)

**En büyük kemer, odaklı komşular ve elin altında dönem salonları**

- **Geçiş hareketi:** Üç yön arasında en heykelsi kemer oranına (`242×290 px`) sahiptir. Komşu kemerler hafif odak dışı yumuşaklığıyla (`blur 1.4 px`) geri çekilir; merkeze yaklaşırken netleşip tabloda hafif bir nefes alma (`1.06 → 1.00`) ile odaya yerleşir. Alttaki yazı blokları dikey bir nefesle çapraz erir.
- **Gezinme biçimi:** Üstte yatay kayan şerit ya da çark yerine solda tek bir cam **dönem hapı (`Barok ⌄`)** ve sağda 9 dönemi temsil eden sessiz boncuk izi bulunur. Hapa dokununca 9 dönemlik cam seçici açılır ve tek dokunuşla herhangi bir döneme atlanır.
- **Alt bölüm:** **`Salona gir`**’in hemen altında yalnızca **seçili dönemin salonları** (ör. Barok için 4 satırlık tek bir gruplu kart) görünür; böylece o dönemin diğer akımlarına kaydırmadan doğrudan geçilebilir. Altında **`Bütün akımlar · 28 salon`** düğmesiyle kalan dönemler istenince açılır; alt sekme çubuğu üzerinde yumuşak iOS kenar geçişi vardır.
- **Neden tercih edilir?** Tabloya en güçlü sahneyi verirken aynı dönemin komşu salonlarını tek kısa kaydırmada erişilebilir kılar.
- **Ödün:** Diğer iki yöne göre ilk ekranın hemen altında kısa bir dikey kaydırma (`1116 px`) bulunur; dönem geçişi üst haptan iki dokunuştur.
- **Görüntüler:** [Gece](goruntuler/yon-3-gece.png) · [Gündüz](goruntuler/yon-3-gunduz.png) · [Geçiş karesi](goruntuler/yon-3-gecis.png)

---

## Kısa karşılaştırma

| Boyut | Yön 1 · Sakin Kemerler | Yön 2 · Kemerlerin Yayı | Yön 3 · Müze Odası |
|---|---|---|---|
| **Geçiş hareketi** | Kosinüs ölçeği + kemer içi paralaks + yatay nefesli yazı | Geniş yay eğimi (`±2.6°`) + çift çerçeve + kemerle akan yazı | En büyük kemer + komşuda odak yumuşaklığı + dikey nefesli yazı |
| **Gezinme biçimi** | Üstte kayan pirinç çizgili 9 dönem şeridi | Altta 52 px hafif Işık Kılavuzu (`‹ Önceki · Dönem · Sonraki ›`) | Üstte tek cam dönem hapı + 9 dönem boncuk izi (açılır menü) |
| **Alt bölüm & dizin** | İlk ekranda kapalı, yerinde açılan 28’lik gruplu dizin (`844 px`) | Alttan açılan buzlu cam çekmece / sheet (`844 px`) | Yalnız seçili dönemin salonları + isteğe bağlı tam dizin (`1116 px`) |
| **Dikey kaydırma çakışması** | Yok | Yok (`touch-action: pan-y`) | Yok |

---

## `TASARIM_DILI.md` notları

- Üç yönde de `TASARIM_DILI.md` ilkelerine sadık kalındı: tablo önde, numarasız akış, büyük harfli etiket yok, cümle düzeni `13 px` pirinç üst yazı, üç katmanlı zemin (doku + iki renkli hale + %4 / %4,5 dönem deseni), `Bodoni Moda` / `Archivo` / `Newsreader`, `44 px` dokunma hedefleri ve tek dolu düğme (`Salona gir`).
- **Tek bilinçli ayrılış:** Üstteki bölüm sekmelerinde (`Akımlar · Başyapıtlar · Konular · Zaman`) seçili `Akımlar` sekmesi dolu `--ink` yerine yumuşak cam vurgu (`rgba(var(--ink-rgb), 0.13)`) kullanır; böylece ekranda yüksek kontrastlı dolu tek öğe tartışmasız biçimde `Salona gir` kalır ve göz ilk anda tabloya odaklanır.
