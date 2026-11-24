# Galeri · Başyapıtlar ve Konular — Tasarım Yönleri

Galeri sekmesinin **Başyapıtlar** (`BasyapitListesi.swift` / `gozat.js` `basyapitListesi`) ve **Konular** (`KonuSayfalari.swift` `KonularSayfasi` / `gozat.js` `konularCiz`) ekranları için ikişer yeniden tasarım önerisi. Her ekran için biri bugünküne yakın ama daha sakin ve bilgilendirici (**Yön 1**), biri ekranın işini baştan kurgulayan cesur öneri (**Yön 2**) hazırlanmıştır.

Bütün dosyalar `390×844` iPhone genişliğinde, yukarıdan aşağı kaydırılan tam sayfa olarak hazırlanmıştır. Yerel kamu malı görseller (`gorseller/`, `1280 px`), uygulamanın kendi dönem desen karoları (`NoraSanat/Ekranlar/Galeri/Desenler/desen-*.png`) ve değişken yazı tipleriyle (`NoraSanat/YaziTipleri/`) tamamen **internetsiz** çalışır; hiçbir dış adres içermez. Her dosyanın üst çubuğundan **Gece / Gündüz** teması değiştirilebilir; dönem/grup/yüzyıl süzgeçleri, öne çıkan geçişleri, okundu işaretleme ve önizleme çekmeceleri HTML içinde canlı çalışır.

İki temada tam sayfa PNG çıktıları (`deviceScaleFactor: 2`, `780 px` genişlik) [`goruntuler/`](goruntuler/) klasöründedir.

---

## Tasarım ilkeleri ve önceki geri bildirimler

- **Sevilen fikirlerin devamı (Çalış Yön 4 · PR #55 ve Paylaşım Kartı Yön 4 · PR #54):** Bilgiyi gürültüsüz, sakin ve işlevsel biçimde görünür kılan araçlar kullanıldı: tahmini **okuma süreleri** (`~3 dk`, `~4 dk`, `~5 dk`), **boncuklu dağılım haritaları** (Başyapıtlar'da 6 dönem okuma boncuğu, Konular'da 8 yüzyıl yoğunluk boncuğu), sol omurgalı **kronolojik okuma yolu** (yeşil onaylı okunanlar, pirinç halkalı sıradaki eser) ve **ince odak çerçeveli ayrıntı önizlemesi** (*Nedimeler*'de aynadaki çiftin gerçek `eser_ayrintilari.json` koordinatlarıyla).
- **Bilinçli olarak tekrar edilmeyenler (Galeri Akımlar · PR #56):** Kenardan kenara üst başlığın altına giren "şu anki salon" kapağı, dar çentikli yüzyıl cetveli, iki sütunlu tablo duvarı ızgarası ve aynı görselin birden çok kartta yinelenmesi hiçbir yönde kullanılmadı.
- **Korunan ortak çerçeve:** Üstte `"Galeri"`, `"Sanatçı, eser ara"`, kalp ve cam kabında `Akımlar · Başyapıtlar · Konular · Zaman`; Başyapıtlar'da dönem süzgeci ile `Hikâye` ve `n ayrıntı` rozetleri; Konular'da grup süzgeci ile `"n eserde bu konu"`; en az `44 px` dokunma hedefleri; `390 px` genişlikte sıfır yatay sayfa taşması (`scrollW=390`); Gece ve Gündüz temaları.
- **Gerçek katalog verisi (`data/basyapitlar.json`, `eser_hikayeleri.json`, `eser_ayrintilari.json`, `ikonografi.json`):**
  - Başyapıtlar: **264 başyapıt**, **4 hikâyeli eser** (*Nedimeler*, *Elçiler*, *Holofernes'in Kafasını Kesen Judith*, *Medusa'nın Salı*), **264 rehberli inceleme** (5–6 ayrıntı noktası) ve gerçek dönem sayıları (`Orta Çağ 12`, `Rönesans 98`, `Barok 43`, `Rokoko ve Neoklasisizm 34`, `Romantizmden Realizme 34`, `Empresyonizm ve sonrası 43`). Örnek kullanıcı durumu: **14 başyapıt okundu**, sırada *Nedimeler* (`y. 1656`).
  - Konular: **371 konu**, **6 grup** (`Yeni Ahit 86`, `Eski Ahit 37`, `Mitoloji 73`, `Azizler 65`, `Tarih ve edebiyat 76`, `Diğer 34`) ve her konunun kataloğundaki eser tarihlerinden çıkarılmış **gerçek yüzyıl aralıkları ve dağılımları** (`XIII–XX. yy` arası).
- **32 farklı kamu malı eser (Wikimedia Commons, `1280 px`, sıfır tekrar):**
  - **Başyapıtlar (16 eser):** Giotto *Ağıt* (`by-agit.jpg`), Gentile da Fabriano *Müneccimlerin Tapınması* (`by-muneccimler.jpg`), Jan van Eyck *Arnolfini Portresi* (`by-arnolfini.jpg`), Hans Holbein *Elçiler* (`by-elciler.jpg`), Leonardo *Mona Lisa* (`by-monalisa.jpg`), Velázquez *Nedimeler* (`by-nedimeler.jpg`), Artemisia Gentileschi *Judith ve Holofernes* (`by-judith.jpg`), Vermeer *İnci Küpeli Kız* (`by-incikupeli.jpg`), Rembrandt *Gece Devriyesi* (`by-gecedevriyesi.jpg`), Fragonard *Salıncak* (`by-salincak.jpg`), David *Marat'nın Ölümü* (`by-marat.jpg`), Friedrich *Sis Denizi Üzerinde Gezgin* (`by-gezgin.jpg`), Géricault *Medusa'nın Salı* (`by-medusa.jpg`), Monet *İzlenim, Gün Doğumu* (`by-izlenim.jpg`), Van Gogh *Yıldızlı Gece* (`by-yildizligece.jpg`), Munch *Çığlık* (`by-ciglik.jpg`).
  - **Konular (16 farklı eser):** Leonardo *Kayalıklar Meryemi* (`kn-meryem.jpg`), Gauguin *Sarı İsa* (`kn-carmih.jpg`), Leonardo *Meryem'e Müjde* (`kn-mujde.jpg`), Michelangelo *Doni Tondo* (`kn-kutsal-aile.jpg`), Dürer *Âdem ile Havva* (`kn-adem-havva.jpg`), Caravaggio *Judith ve Holofernes* (`kn-judith.jpg`), Caravaggio *Golyat'ın Başıyla Davut* (`kn-davut.jpg`), Zurbarán *Herkül ve Nemea Aslanı* (`kn-herkul.jpg`), Botticelli *Venüs'ün Doğuşu* (`kn-venus.jpg`), Leonardo *Aziz Hieronymus* (`kn-hieronymus.jpg`), Caravaggio *Assisili Aziz Franciscus* (`kn-franciscus.jpg`), Rossetti *Beata Beatrix* (`kn-dante.jpg`), Gérôme *Kleopatra ve Sezar* (`kn-kleopatra.jpg`), Watteau *Fêtes Vénitiennes* (`kn-fetegalante.jpg`), Bruegel *Karda Avcılar* (`kn-aylar.jpg`), Goya *Cadı Ayini* (`kn-cadilar.jpg`).

---

## Başyapıtlar · Yön 1 — Sakin vitrin (`basyapit-yon-1.html`)

**Yaklaşım:** Bugünkü Başyapıtlar ekranının tanıdık yapısını (yapışkan dönem sekmeleri + öne çıkan büyük kart + dönem dönem yatay kayan şeritler) koruyup gürültüyü ayıklayan, okuma durumunu ve içerik derinliğini anında görünür kılan evrim.

- **Neyi iyileştirir?**
  - **Sıradaki okuma kartı:** Öne çıkan büyük kart yalnızca pasif bir slayt değildir; üstte `Hikâye`, `5 ayrıntı` ve `~4 dk` cam rozetleriyle, altta tek cümlelik merak notuyla ve ekrandaki tek dolu hap düğmeyle (`"Okumaya başla · ~4 dk · 5 ayrıntı"`) doğrudan okumaya davet eder.
  - **Okuma izlerin ve hızlı süzgeç:** Kartın hemen altında `"14 başyapıt okudun"` özeti, dönemlere göre 6 küçük ilerleme boncuğu ve tek dokunuşluk `Tümü · Hikâyeliler (4) · Okunmamış` süzgeci yer alır.
  - **Temiz şerit kartları ve gruplu dönem listesi:** Bugünkü siyah büyük harfli `"HENÜZ KURSTA YOK"` etiketi ve büyük harfli akım satırları kaldırıldı. Her şerit kartında okunaklı `Hikâye` / `n ayrıntı` rozetleri, okuma süresi (`~3 dk`) ve okunan eserlerde sağ üstte sakin yeşil tik (`✓`), sıradakinde ince pirinç `"Sırada"` etiketi görünür. Bir dönem seçildiğinde dar iki sütunlu ızgara yerine `TASARIM_DILI.md`'deki **tek sütunlu gruplu liste** açılır.
- **En güçlü olduğu yer:** Mevcut alışkanlığı hiç kırmadan okuma geçmişini, hikâye/ayrıntı zenginliğini ve sıradaki eseri tek bakışta okunur kılması; SwiftUI'ye geçiş maliyetinin düşük olması.
- **Ödün:** 6 dönem şeridi alt alta geldiği için tam sayfa uzunluğu Yön 2'ye göre biraz daha fazladır (`3464 px`).
- **`TASARIM_DILI.md`'den ayrılışlar:**
  - *Bölüm sekmesi dolu hapı + içerikte tek dolu eylem düğmesi:* `TASARIM_DILI.md` hem bölüm sekmelerinde seçili sekmenin dolu (`--ink`) olmasını hem ekranda tek dolu düğme olmasını söyler. Üst bölüm kabında uygulama standardı korunurken sayfa gövdesindeki tek dolu eylem düğmesi `"Okumaya başla"` için ayrıldı.
  - *Şerit kartlarında küçük okunaklı metin rozetleri:* Mevcut uygulamada küçük kartlarda yalnızca ikon duruyordu; kullanıcının `Hikâye` ve `n ayrıntı` sayısını simge çözmeden okuyabilmesi için koyu cam hap içinde kısa metin (`Hikâye`, `6 ayrıntı`) korundu.
  - *Okuma özeti kutusunda 6 küçük dönem boncuğu:* Metnin yanına her dönemin okuma durumunu gösteren 6 sessiz nokta eklendi; çünkü 14 okumanın tek bir döneme mi yoksa yüzyıllara mı yayıldığı sayı okumadan hissedilsin.
- **Görüntüler:** [Gece](goruntuler/basyapit-yon-1-gece.png) · [Gündüz](goruntuler/basyapit-yon-1-gunduz.png)

---

## Başyapıtlar · Yön 2 — Okuma defteri (`basyapit-yon-2.html`) *(Cesur öneri)*

**Yaklaşım:** Başyapıtlar'ı bir "poster rafı" değil, sanat tarihinden geçen kişisel bir **yakın okuma defteri** olarak kurgulayan yön. Çalış Yön 4 (boncuklu harita, süreler, sol omurgalı yol) ile Paylaşım Kartı Yön 4'ün (odak çerçevesi ve yakın kırpım) doğrudan kardeşi.

- **Neden bu yön?**
  - **Ayrıntı odaklı sıradaki okuma kartı:** Yuvarlatılmış (`26 px`) sakin kartın üstündeki *Nedimeler* tablosunda gerçek koordinatlarla (`x: 0.37, y: 0.51`) ince bir odak çerçevesi arka duvardaki aynayı işaretler. Hemen altındaki yakın kırpım kutusu o aynayı büyüterek tek cümleyle merak uyandırır; tek dolu düğme (`"Okumaya gir · ~4 dk · 5 ayrıntı"`) okumayı açar.
  - **Boncuklu dönem haritası (dönem süzgeci):** Yatay kayan sekme şeridi yerine 6 dönem, eser yoğunluğuna göre ölçeklenen 6 sakin boncukta (`Orta Çağ 2 · Rönesans 5 · Barok 4 · …`) tek bakışta görünür. Bir boncuğa dokununca o dönemin okuma/hikâye özeti çıkar ve aşağıdaki yol anında o döneme süzülür; altındaki `Tümü · Hikâyeliler (4) · Sıradakiler · Okunanlar` haplarıyla birleşir.
  - **Kronolojik okuma yolun:** Sol kenarda ince zaman omurgasıyla 1305'ten 1893'e doğru tek sütunda akar. Okunan eserler yeşil onay düğümü (`✓`) ve kompakt kare görselle geri çekilir; sıradaki eser (*Nedimeler*) pirinç ışıklı düğüm ve hafifçe belirginleşmiş çerçeveyle öne çıkar; hikâyeli eserler sıcak pirinç `Hikâye` rozetiyle hemen seçilir.
- **En güçlü olduğu yer:** "Hangilerini okudum, sırada ne var, hangisinde hikâye var?" sorularının tamamını yatay kaydırmaya gerek kalmadan tek dikey akışta çözmesi.
- **Ödün:** Yatay şeritler olmadığı için "Hepsi" görünümünde dönem başına daha az eser ilk bakışta sığar; dönem içi tarama için boncuktan ilgili döneme dokunmak gerekir.
- **`TASARIM_DILI.md`'den ayrılışlar:**
  - *Alt çizgili dönem sekmeleri yerine boncuklu dönem haritası:* Dönem süzgeci 2 px pirinç alt çizgili yatay şerit yerine etkileşimli 6 boncuklu özet kartına taşındı; çünkü hem dönem süzgeci hem de okunan eser dağılımı tek bileşende birleşsin.
  - *Odak çerçevesi ve küçük yakın kırpım önizlemesi:* Paylaşım Kartı Yön 4'teki odak karesi ve kırpım bandı sıradaki okuma kartına uyarlandı; çünkü Başyapıtlar'ı sıradan bir tablo listesinden ayıran "rehberli ayrıntı okuma" hissi daha listeye bakarken sezilsin.
  - *Sol kenarda dikey omurga ve yeşil/pirinç düğümler:* `TASARIM_DILI.md`'deki 3 px düz çizgiler yerine Çalış Yön 4'ün onaylanan kronolojik omurgası kullanıldı; çünkü zaman sırası ve okuma durumu tek çizgide okunsun.
- **Görüntüler:** [Gece](goruntuler/basyapit-yon-2-gece.png) · [Gündüz](goruntuler/basyapit-yon-2-gunduz.png)

---

## Konular · Yön 1 — Hikâye rafları (`konu-yon-1.html`)

**Yaklaşım:** Bugünkü Konular ekranının tanıdık iskeletini (yapışkan 6 grup sekmesi + öne çıkan konu kartı + grup başına yatay kayan şeritler) korurken, Konular'ın asıl eksiği olan **"hangi yüzyıllarda işlendi?"** sorusunu her kartta sessizce görünür kılan evrim.

- **Neyi iyileştirir?**
  - **Öne çıkan konuda yüzyıl izi:** Büyük öne çıkan kartta (`Judith ve Holofernes`) üstte `XV–XX. yy` ve `Doruk XVII. yy` cam hapları, altında `"30 eserde bu konu"` ve `XIII`'ten `XX. yy`'a uzanan **8 boncuklu yüzyıl izi** yer alır; böylece bu sahnenin neden Barok'un imzası olduğu tek saniyede görülür.
  - **Her raf kartında yüzyıl dağılımı:** Grup adı altında tekrar edilen büyük harfli tür etiketi (`YENİ AHİT`) kaldırıldı (bilgi tekrarı yok). Yerine her kartın köşesinde yüzyıl aralığı (`XIII–XX. yy`, `XVIII. yy`), altında `"346 eserde bu konu"` ve en altta 8 küçük noktalı yüzyıl izi (`doruk` yüzyıl pirinçle parlar) gelir.
  - **Grup seçilince gruplu liste:** Dar iki sütunlu duvar yerine her satırda eser, `"n eserde bu konu"`, 1 satırlık *"Resimde nasıl tanınır?"* ipucu ve yüzyıl boncukları görünür.
- **En güçlü olduğu yer:** Mevcut Başyapıtlar/Konular ailesiyle yüksek tutarlılık, düşük geçiş maliyeti ve her konunun çağ aralığını tek bakışta okutması.
- **Ödün:** Ana ekrandaki yatay kartlarda alan dar olduğu için "Resimde nasıl tanınır?" ipucu ancak gruba ya da konuya dokununca görünür.
- **`TASARIM_DILI.md`'den ayrılışlar:**
  - *8 noktalı yüzyıl izi:* Kartların altına ve öne çıkan karta `XIII–XX. yy` arası 8 minik boncuk eklendi; çünkü "hangi yüzyıllarda işlendi ve ne zaman doruk yaptı" bilgisi uzun metin yazmadan tek bakışta okunsun.
  - *Bölüm sekmesi dolu hapı + tek dolu eylem düğmesi:* Üst bölüm kabı uygulama standardını korur; sayfa gövdesindeki tek dolu düğme `"Konuyu aç"`tır.
- **Görüntüler:** [Gece](goruntuler/konu-yon-1-gece.png) · [Gündüz](goruntuler/konu-yon-1-gunduz.png)

---

## Konular · Yön 2 — İkonografi izi (`konu-yon-2.html`) *(Cesur öneri)*

**Yaklaşım:** Konular ekranını Başyapıtlar'ın klonu olmaktan çıkarıp, **resimlerde hikâye tanıma ve yüzyıllar boyu iz sürme** işine özel olarak kurgulayan sakin bir ikonografi rehberi.

- **Neden bu yön?**
  - **Tanıma ipuçlu odak kartı:** Öne çıkan *Judith ve Holofernes* kartı, `"30 eserde bu konu · 6 yüzyıla yayılır"` bilgisinin hemen altında sakin bir `"Resimde nasıl tanınır?"` kutusu sunar (*"Kılıç tutan zengin giyimli genç kadın ve kesik başı bir torbaya koyan yaşlı hizmetçi"*). Ekrandaki tek dolu düğme (`"Hikâyeyi ve 30 eseri gör"`) tek dokunuşla konuya girer.
  - **"Hangi yüzyıllarda?" — Grup + 8 yüzyıl boncuk matrisi:** Tek sakin `--surface` kartının üstünde 6 konu grubu sekmesi (`Hepsi 371 · Yeni Ahit 86 · …`), hemen altında kataloğun tamamından (`371 konu`) hesaplanmış **8 etkileşimli yüzyıl boncuğu** (`XIII. yy: 18` … `XVII. yy: 220` … `XX. yy: 33`) durur. Grup değişince boncuklar o grubun tarihsel ağırlığına göre yeniden ölçeklenir (ör. *Tarih ve edebiyat*'ta XVIII–XIX. yy parlar); bir yüzyıl boncuğuna dokununca o çağın kısa yorumu görünür ve aşağıdaki dizin anında o yüzyıla süzülür.
  - **Tanıma ipuçlu ve yüzyıl izli tek sütunlu dizin:** İki sütunlu duvar yerine her konu `TASARIM_DILI.md`'nin gruplu listesinde nefes alan bir satırda yer alır: solda gerçek eser, sağda `Bodoni` konu adı, `"n eserde bu konu"`, 1–2 satırlık Newsreader **tanıma ipucu** ve en altta 8 noktalı yüzyıl izi (`XIII–XX. yy · doruk XVII. yy`).
- **En güçlü olduğu yer:** Konular ekranının iki temel işini (*hikâyeyi resimde tanımak* + *kaç eserde ve hangi yüzyıllarda işlendiğini görmek*) ilk kez aynı sakin yüzeyde, Başyapıtlar'dan tamamen özgün bir kimlikle çözmesi.
- **Ödün:** Her konu satırında tanıma ipucu ve yüzyıl izi yer aldığı için sayfa dikeyde daha uzundur (`3793 px`); grup ya da yüzyıl boncuğuyla süzüldüğünde 1–2 ekrana iner.
- **`TASARIM_DILI.md`'den ayrılışlar:**
  - *2×4 etkileşimli yüzyıl boncuk kartı:* Grup sekmelerinin hemen altına Çalış Yön 4'ün boncuklu takvimine akraba 8 yüzyıl boncuğu yerleştirildi; çünkü 371 konunun hangi yüzyıllarda yoğunlaştığı tek bakışta görülsün ve yüzyıla göre tek dokunuşla süzülebilsin.
  - *Konu satırlarında doğrudan "nasıl tanınır?" ipucu ve 8 noktalı yüzyıl izi:* Yalnızca konu başlığı ve eser sayısı yerine 2 satırlık Newsreader ipucu ve 8 noktalı yüzyıl çizgisi satır içine alındı; çünkü kullanıcı konuya girmeden önce bile tabloda ne arayacağını ve o hikâyenin çağını görebilsin.
- **Görüntüler:** [Gece](goruntuler/konu-yon-2-gece.png) · [Gündüz](goruntuler/konu-yon-2-gunduz.png)

---

## Kısa karşılaştırma

### Başyapıtlar

| Ölçüt | Yön 1 · Sakin vitrin | Yön 2 · Okuma defteri |
|---|---|---|
| Bugünkü ekrana yakınlık | Yüksek (dönem sekmeleri + yatay şeritler) | Cesur yeniden kurgu (boncuk haritası + dikey yol) |
| Sıradaki okuma & odak | Büyük vitrin kartı + 4 öne çıkan noktası | Odak çerçeveli ve yakın kırpımlı okuma kartı |
| Okuduklarım & ilerleme | Üstte 6 mini boncuk + kartta yeşil tik (`✓`) | 6 dönem boncuğu + sol omurgalı kronolojik yol |
| `Hikâye` ve `n ayrıntı` | Cam rozetler + hızlı `"Hikâyeliler (4)"` süzgeci | Pirinç `Hikâye` rozeti + ayrıntı sayısı + süzgeç |
| Dönem seçilince görünüm | Tek sütunlu gruplu liste | Süzülmüş kronolojik okuma yolu |
| SwiftUI geçiş karmaşıklığı | Düşük | Orta (boncuk haritası + sol omurgalı yol) |

### Konular

| Ölçüt | Yön 1 · Hikâye rafları | Yön 2 · İkonografi izi |
|---|---|---|
| Bugünkü ekrana yakınlık | Yüksek (grup sekmeleri + yatay raflar) | Cesur yeniden kurgu (yüzyıl matrisi + tanıma dizini) |
| "Hangi yüzyıllarda?" bilgisi | Kartta aralık + 8 minik nokta | Grup × 8 etkileşimli yüzyıl boncuğu + satır izi |
| "Resimde nasıl tanınır?" | Grup listesinde ve konu çekmecesinde | Odak kartında ve her konu satırında doğrudan görünür |
| `"n eserde bu konu"` | Öne çıkan kartta ve her raf kartında | Odak kartında ve her konu satırında |
| SwiftUI geçiş karmaşıklığı | Düşük | Orta (etkileşimli 8 yüzyıl boncuk matrisi) |
