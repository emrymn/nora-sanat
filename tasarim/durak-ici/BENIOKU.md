# Yolculuk · Durak İçi (Bölüm Turu) Yeniden Tasarım Önerileri

Nora Sanat uygulamasında **Yolculuk** sekmesindeki bir durağın **içinin** — yani bölüm turunun (`BolumTuruEkrani.swift`, `BolumTanismasi.swift`, `BolumSoruKarti.swift`, `YolculukProva.swift`; site karşılığı `js/bolum.js`, `js/ekranlar/pekistir.js`) — yeniden tasarım önerileri. **Harita ve durak paneli ile uygulama koduna dokunulmamıştır.**

Üç HTML dosyası da (`yon-1.html`, `yon-2.html`, `yon-3.html`) `390×844` iPhone genişliğinde, yerel yazı tipleriyle (`NoraSanat/YaziTipleri/`), Rönesans dönem desen karosuyla (`NoraSanat/Ekranlar/Galeri/Desenler/desen-ronesans@3x.png`) ve [`gorseller/`](gorseller/) altındaki **12 farklı kamu malı tabloyla** tamamen **internetsiz** çalışır; dış bağlantı ve görsel tekrarı yoktur.

Her HTML dosyasında:
- **Tanışma → Sorular → Cevap yaprağı → Sonuç** akışının tamamı telefonun içinde tıklanarak baştan sona oynanır.
- Üst önizleme çubuğundan **Adım** (`Tanışma` / `Soru` / `Yanlış cevap` / `Sonuç`), **Seviye** (`Kolay` / `Orta` / `Zor`), **Tema** (`Gece` / `Gündüz`) ve **Hareket** (`Tam hareket` / `Hareketi azalt`) anında değiştirilebilir.
- Her yön için Gece'de 4 (`tanışma`, `soru`, `yanlış cevap yaprağı`, `sonuç`), Gündüz'de 2 (`soru`, `sonuç`) olmak üzere toplam **18 PNG** (`deviceScaleFactor: 2`, `780×1688 px`) [`goruntuler/`](goruntuler/) klasöründedir.

---

## Bugünkü ekranın sorunları ve çözüm yaklaşımı

Mevcut `BolumTanismasi.swift`, `BolumSoruKarti.swift` ve `BolumTuruEkrani.swift` incelendiğinde ve Emre'nin geri bildirimleri (*Çalış'ta "Yön 4 · Bugünün oturumu" gibi sade, sakin, yaratıcı ve işlevsel; kalabalık ekran yok*) değerlendirildiğinde dört ana sorun öne çıkıyor:

1. **Soru ve cevap ekranında eserin sıkışması:** `BolumSoruKarti.swift`'te `A/B/C/D` harf daireli `88 px` yüksek şıklar dikey alanı tüketiyor; cevap verildiğinde hem kalan şıklar hem de alt yaprak birlikte durduğundan eser görseli `140 px`'e kadar küçülüp geri plana itiliyor.
   - *Çözüm:* Harf rozetleri kaldırıldı. Eser her zaman sahnenin başrolünde kalır; cevap verildiğinde şıklar çekilerek öğrenme alanına ve yan yana karşılaştırmaya nefes alanı açar.
2. **Eski tasarım dilinden kalan görsel gürültü:** `PkEtiket` büyük harfli harf aralıklı etiketler, köşeli `GecDugmesi` (`cornerRadius: 3`), sonuçtaki `GEÇTİ` / `AZ KALDI` büyük harf hapları ve `I KOLAY / II ORTA / III ZOR` Roma rakamları `TASARIM_DILI.md` ilkeleriyle çelişiyor.
   - *Çözüm:* Tüm üst yazılar cümle düzeninde `13 px` yarı kalın pirinç (`--pirinc`), ilerlemeler `3 px` ince çizgiler ya da inci dizisi, seviyeler yalın *Kolay · Orta · Zor* olarak kuruldu.
3. **Sonuç ekranının uzunluğu ve bilgi tekrarı:** Mevcut `BolumSonucuGorunumu` dört ağır bloğu (eğri ipli `sergiDuvari` + `Hareketi aç`, 148 px madalyon, yüzde/çubuk/izler/sayılar, Roma rakamlı salon yolu) üst üste yığarak geçiş bilgisini dört kez tekrarlıyor.
   - *Çözüm:* Sonuç ekranı tek bakışta okunan bir hiyerarşiye indirildi: `"N / M doğru"`, `"Senin gözün %X · Hedef %75"`, yıldızlar, (3. yıldız tamamlandığında) `"Rönesans tamamlandı · bütün duraklar üç yıldız"` kutlaması, sade eser incelemesi ve başparmak eriminde sabit tek dolu eylem düğmesi (`Orta'ya geç` / `Tekrar dene` / `Haritaya dön`).
4. **Aynı ekranda yarışan dolu düğmeler:** Cevap yaprağında dairesel portre diskli `Sanatçı` düğmesi ile dolu `Sonraki kart` düğmesi yarışıyordu.
   - *Çözüm:* Her ekranda yalnızca **tek dolu hap düğme** (Gece'de krem `--ink` zemin / `--bg` yazı, Gündüz'de koyu `--ink` zemin / `--bg` yazı); ikincil eylemler (`Sanatçı`, `Bilmiyorum`, `Haritaya dön`, `Tekrarla`) sade düz yazı ya da cam yuvarlak düğme.

---

## Korunanlar ve `TASARIM_DILI.md` uyumu

- **Örnek durak:** `Kuzey Rönesansı · 1. bölüm` (*Jan van Eyck*, *Robert Campin*, *Rogier van der Weyden*, *Petrus Christus*) — 4 sanatçı × 3 benzersiz kamu malı tablo = **12 farklı tablo**; `tanima_notlari.json` ve `sanatcilar.json`'dan gerçek "Nasıl tanırım?" metinleri.
- **Bütün adımlar:** Tanışma (3 eser vitrini + büyütme + yıllar/akım + "Nasıl tanırım?") → 8 soruluk seviye turu (4 şık + "Bilmiyorum" + ilerleme göstergesi + turdan çıkış onayı) → Cevap yaprağı (doğru/yanlış + doğru sanatçı/akım + eser adı/yılı + "Nasıl tanırım?" + yanlışta `"Bu ikisini 2. kez karıştırdın. Yan yana bak:"` karşılaştırması + kapalı `"Ayrıntılar"`) → Sonuç (`"N / M doğru"`, `"Senin gözün %X · Hedef %75"`, yıldızlar, dönem tamamlandı, `"Haritaya dön"`).
- **Üç katmanlı zemin ve yazı üçlüsü:** Kömür / sıcak kâğıt zemin (`--bg`) + `3×3 px` nokta dokusu + aktif tablonun baskın iki tonundan yumuşak köşe halesi + Rönesans dönem deseni (Gece `%4`, Gündüz `%4,5`); başlıklarda **Bodoni Moda**, okuma ve künyelerde **Newsreader**, arayüzde **Archivo**.
- **Erişilebilirlik ve hareket azaltma:** `prefers-reduced-motion: reduce` ve önizleme çubuğundaki *Hareketi azalt* anahtarı bütün kayma/yay geçişlerini anlık sade geçişe indirir. Tüm etkileşimli düğmeler `≥ 44 px` dokunma hedefine sahiptir; `390 px` genişlikte yatay taşma yoktur (`scrollWidth = 390`).

---

## Titreşim ve dokunsal geri bildirim anları

Mevcut `NoraSanat/Kabuk/Titresim.swift` ile birebir uyumlu dokunsal geri bildirim haritası (Ayarlar → Titreşim kapalıysa hiçbiri tetiklenmez):

| An | Eylem | `Titresim.swift` karşılığı | Not |
|---|---|---|---|
| Tanışma eser seçimi | Başka küçük kareye / noktaya dokunma | `Titresim.secim` (`UISelectionFeedbackGenerator`) | Hafif tık; görsel değişimini hissettirir |
| Tanışma / Soru geçişi | `Sıradaki`, `Kolay'a başla`, `Sonraki soru` | `Titresim.dokunus` (`.light`) | Başparmak onay hissi |
| Doğru cevap | Doğru sanatçıyı seçme | `Titresim.dogru` (`.success`) | Tek, temiz onay darbesi |
| Yanlış cevap / Bilmiyorum | Yanlış sanatçı veya `Bilmiyorum` | `Titresim.yanlis` (`.error`) | Çift darbe; yan yana karşılaştırmaya dikkat çeker |
| Tur sonucu · Yıldız / Dönem tamamlandı | Geçme eşiği (`%75+`) aşıldığında | `Titresim.dokunus` → `Titresim.dogru` | Hareket azaltma açıksa yalnız tek `.success` |
| Turdan çıkış onayı | `×` düğmesine dokunma | `Titresim.secim` | Kazara çıkış riskini azaltan yumuşak uyarı |

---

## Yön 1 — Sakin Salon (`yon-1.html`)

**Rolü:** *Bugünkünün toparlanmış, kalabalıktan arındırılmış hâli.*

- **Nasıl çalışır?**
  - **Tanışma:** Mevcut vitrin + küçük kareler + kartela + "Nasıl tanırım?" sırası korunur; ancak büyük harfli etiketler, köşeli `GecDugmesi` ve tablonun üstüne rastgele oturan kapatma düğmesi yerine tek satırlı sakin üst çubuk, `3 px` parçalı adım çizgisi ve başparmak eriminde yuvarlak hap `Sıradaki · Campin` / `Kolay'a başla` düğmesi gelir.
  - **Soru:** Harf rozetsiz temiz 2×2 şık ızgarası (`60 px`) sayesinde eser görseli mevcut ekrana göre çok daha büyük ve kırpılmadan nefes alır; altında italik `Bilmiyorum`.
  - **Yanlış cevap yaprağı:** Cevap verildiğinde şıklar tamamen çekilir; buzlu cam alt yaprak yükselirken eser üstte görünmeye devam eder. Yaprakta `Yanlış · Seçtiğin: Christus`, Bodoni Moda doğru sanatçı, Newsreader eser adı/yılı, dokununca açılan "Nasıl tanırım?", `"Bu ikisini 2. kez karıştırdın. Yan yana bak:"` 2×2 karşılaştırma kutusu, kapalı `Ayrıntılar` ve altta solda düz yazı `Sanatçı`, sağda tek dolu `Sonraki soru`.
  - **Sonuç:** Dağınık ipli sergi duvarı yerine temiz 4×2 eser şeridi (yanılınan eser soluk + kırmızı işaretli), sade yüzde/hedef rayı (`%88 · 7 / 8 doğru · Senin gözün %88 · Hedef %75`), 3 pirinç yıldız, `Rönesans tamamlandı` bandı, Roma rakamsız 3 çizgili seviye durumu ve sabit alt çubukta `Haritaya dön`.
- **En güçlü olduğu yer:** Mevcut kullanıcı alışkanlığını bozmadan bütün görsel gürültüyü gidermesi ve SwiftUI'a en düşük maliyetle taşınabilmesi.
- **Ödün:** Akışın temel ritmini değiştirmez; 2×2 şık ızgarasında *Rogier van der Weyden* gibi uzun isimler iki satıra kırılabilir.
- **Görüntüler:**
  - Gece: [Tanışma](goruntuler/yon-1-tanisma-gece.png) · [Soru](goruntuler/yon-1-soru-gece.png) · [Yanlış cevap](goruntuler/yon-1-yanlis-gece.png) · [Sonuç](goruntuler/yon-1-sonuc-gece.png)
  - Gündüz: [Soru](goruntuler/yon-1-soru-gunduz.png) · [Sonuç](goruntuler/yon-1-sonuc-gunduz.png)

---

## Yön 2 — Eser Odaklı Akış (`yon-2.html`)

**Rolü:** *Akışı yeniden düşünen yön — tek sabit sahne, gruplu başparmak şıkları ve gözden geçirme odaklı sonuç.*

- **Nasıl çalışır?**
  - **Tanışma (tek ekrana sığan galeri levhası):** Eser ekranın üst yarısını büyük yuvarlatılmış bir levha olarak kaplar; 3 eser arasında sağ üstteki cam dairelerle (`44×44 px` dokunma hedefli) geçilir. Sanatçı adı, yıllar ve 4 satırlık "Nasıl tanırım?" hemen altındaki tek kartelada oturur — kaydırma gerektirmeden tek bakışta okunur.
  - **Soru (tek sütunlu gruplu liste):** 2×2 kutular yerine `TASARIM_DILI.md`'deki *gruplu liste* bileşeniyle tek kart içinde ince çizgili 4 satır + sağda doğum–ölüm yılları yer alır. Uzun Flaman sanatçı adları asla iki satıra kırılmaz ve başparmağın doğal yayında çok hızlı seçilir.
  - **Yanlış cevap (modal yaprak yerine yerinde dönüşüm):** Ayrı bir alttan açılan modal pencere yerine şık listesi yumuşakça çözülüp **aynı yerde** öğrenme kartına dönüşür. Eser üstte büyük kalır (`212 px`), hemen altında `Yanlış · Seçtiğin: Christus`, `"Bu ikisini 2. kez karıştırdın. Yan yana bak:"` 2×2 karşılaştırması, tam "Nasıl tanırım?" ve kapalı `Ayrıntılar` okunur.
  - **Sonuç (gözden geçirme atölyesi):** Skor kartının hemen altında alt çizgili `Hepsi · 8` / `Yanıldıkların · 1` sekmeleri ve 2 sütunlu eser kartları yer alır. Kullanıcı sonuç ekranında yalnızca puanına bakmaz; tek dokunuşla yanıldığı eseri süzüp bir sonraki tura hazırlanır.
- **En güçlü olduğu yer:** Uzun sanatçı adlarının sıfır kırılmayla okunması, cevap anında görsel sıçramanın azalması ve sonuç ekranının gerçek bir pekiştirme/gözden geçirme aracına dönüşmesi.
- **Ödün:** Tek sütunlu şık listesinde sağda görünen doğum–ölüm yılları Zor seviyede ufak ipucu sayılabilir; Zor seviyede yılların gizlenmesi gerekir.
- **Görüntüler:**
  - Gece: [Tanışma](goruntuler/yon-2-tanisma-gece.png) · [Soru](goruntuler/yon-2-soru-gece.png) · [Yanlış cevap](goruntuler/yon-2-yanlis-gece.png) · [Sonuç](goruntuler/yon-2-sonuc-gece.png)
  - Gündüz: [Soru](goruntuler/yon-2-soru-gunduz.png) · [Sonuç](goruntuler/yon-2-sonuc-gunduz.png)

---

## Yön 3 — Küratör Sahnesi (`yon-3.html`)

**Rolü:** *Daha cesur ama sade — Çalış "Yön 4 · Bugünün oturumu"nun sakin şövale ve inci ritmini durak içine taşıyan müze deneyimi.*

- **Nasıl çalışır?**
  - **İnci Adım İzi:** Üstte kalabalık başlık ve tam genişlikte çubuk yerine tek satırda üç hafif cam parça: solda `×`, ortada **inci dizisi** (doğru bilinen inci yeşil, yanlış bilinen ince mercan halka, şimdiki adım büyümüş inci), sağda `1 / 8`.
  - **Tanışma (kenardan kenara şövale perdesi):** Tablo durum çubuğunun arkasına kadar uzanıp aşağı doğru zemine erir; sol altta dokunulabilir eser adı fısıltısı (`Arnolfini Portresi, 1434`), sağ kenarda 3 eserlik dikey çekmece yer alır. Alt kısımda kutusuz, doğrudan zemine oturan Bodoni Moda ad ve Newsreader "Nasıl tanırım?" metni.
  - **Soru (spotlu sahne + yüzen cam tepsi):** Eser, arkada kendi baskın tonundan yumuşak bir haleyle ekranın ortasında tek başına parlar; altta havada asılı tek bir buzlu cam soru tepsisi içinde `"Bu eser kimin?"`, 4 şık ve `Bilmiyorum` durur.
  - **Yanlış cevap (Stüdyo Masası):** Küçücük 62 px pullar yerine ekran gerçek bir karşılaştırma masasına dönüşür: üstte sorulan eserin künye şeridi, ortada `"Bu ikisini 2. kez karıştırdın. Yan yana bak:"` altında **iki geniş sütunda 102 px yüksekliğinde 4:5 eser çiftleri** — fırça, ışık ve portre farkı ilk bakışta gerçekten seçilir!
  - **Sonuç (Yıldız Yayı ve Hafıza Şeridi):** Üstte 3 yıldızın oturduğu ince pirinç yarım yay ve merkezde büyük `%88` (`7 / 8 doğru`), altında `Senin gözün %88 · Hedef %75` ve `Rönesans tamamlandı` mührü. Ortadaki **Hafıza şeridi** 8 eseri dairesel inciler hâlinde dizer (yanılınan eser mercan halkayla baştan seçili gelir; dokunulan eserin künyesi hemen altında açılır); altta Çalış Yön 4 ile akraba bağlantılı düğüm çizgisi (*Kolay — Orta — Zor*).
- **En güçlü olduğu yer:** Çalış Yön 4 ("Bugünün oturumu") ile en güçlü görsel akrabalık; yanlış cevapta iki sanatçıyı gerçekten ayırt ettiren büyük yan yana karşılaştırma; sade ama unutulmaz sonuç ekranı.
- **Ödün:** Yanlış cevap anında sorulan tablo üstteki künye kartına küçülür; ayrıca yarım yay ve etkileşimli hafıza şeridi SwiftUI'da yeni özel bileşenler gerektirir.
- **Görüntüler:**
  - Gece: [Tanışma](goruntuler/yon-3-tanisma-gece.png) · [Soru](goruntuler/yon-3-soru-gece.png) · [Yanlış cevap](goruntuler/yon-3-yanlis-gece.png) · [Sonuç](goruntuler/yon-3-sonuc-gece.png)
  - Gündüz: [Soru](goruntuler/yon-3-soru-gunduz.png) · [Sonuç](goruntuler/yon-3-sonuc-gunduz.png)

---

## Kısa karşılaştırma

| Ölçüt | Yön 1 · Sakin Salon | Yön 2 · Eser Odaklı Akış | Yön 3 · Küratör Sahnesi |
|---|---|---|---|
| Yaklaşım | Bugünkünün temizlenmiş evrimi | Tek sabit sahne, yeni akış | Cesur ama sade müze sahnesi |
| İlerleme göstergesi | `3 px` parçalı çizgi + `1 / 8` | Tek sürekli `3 px` çizgi + `1 / 8` | Cam kap içinde inci dizisi + `1 / 8` |
| Tanışma düzeni | Yuvarlak vitrin + alt kare şerit + kartela | Tek ekrana sığan levha + sağ üst daireler | Kenardan kenara şövale perdesi + sağ çekmece |
| Soru şıkları | Harf rozetsiz 2×2 kutular | Tek kartta 4 satırlı gruplu liste | Yüzen buzlu cam tepsi içinde 2×2 haplar |
| Yanlışta karşılaştırma | Alt yaprak içinde kompakt 2×2 şerit | Yerinde açılan kart içinde 2×2 panel | Stüdyo masasında büyük (`102 px`) 2 sütunlu kıyas |
| Sonuçta eser özeti | 4×2 sade eser şeridi | `Hepsi / Yanıldıkların` filtreli 2 sütunlu kartlar | Dokunulabilir 8'li dairesel hafıza şeridi |
| Çalış Yön 4 akrabalığı | Orta | Yüksek | En yüksek (şövale perdesi, inci ritmi, düğüm omurga) |
| SwiftUI geçiş maliyeti | En düşük | Orta | Orta–yüksek |

---

## Kullanılan kamu malı tablolar (`gorseller/`, 1280 px, Wikimedia Commons)

Hiçbir görsel tekrarlanmaz; tamamı 15. yüzyıl kamu malı eserleridir:

1. `01-van-eyck-arnolfini.jpg` — Jan van Eyck, *Arnolfini Portresi* (1434)
2. `02-van-eyck-rolin.jpg` — Jan van Eyck, *Şansölye Rolin'in Meryem'i* (1435)
3. `03-van-eyck-kirmizi-sarik.jpg` — Jan van Eyck, *Kırmızı Sarıklı Adam* (1433)
4. `04-campin-merode.jpg` — Robert Campin, *Mérode Sunağı (Müjde)* (y. 1427)
5. `05-campin-aziz-barbara.jpg` — Robert Campin, *Werl Sunağı: Azize Barbara* (1438)
6. `06-campin-kadin-portresi.jpg` — Robert Campin, *Bir Kadın Portresi* (y. 1435)
7. `07-weyden-hactan-indirme.jpg` — Rogier van der Weyden, *Haç'tan İndirme* (y. 1435)
8. `08-weyden-kadin-portresi.jpg` — Rogier van der Weyden, *Bir Hanımefendi Portresi* (y. 1460)
9. `09-weyden-azize-magdalena.jpg` — Rogier van der Weyden, *Okuyan Azize Magdalena* (y. 1435)
10. `10-christus-genc-kiz.jpg` — Petrus Christus, *Genç Bir Kızın Portresi* (y. 1470)
11. `11-christus-kuyumcu.jpg` — Petrus Christus, *Dükkânında Bir Kuyumcu (Aziz Eligius)* (1449)
12. `12-christus-kartuzyen.jpg` — Petrus Christus, *Bir Kartuzyen Keşişin Portresi* (1446)
