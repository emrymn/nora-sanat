# Nora Sanat

**Sanat Atlası**'nın iPhone uygulaması. Ana ekranda **Nora Sanat** adıyla durur.

Uygulama, Sanat Atlası'nı (`sanat-atlasi.pages.dev`) Safari'nin çubukları olmadan, tam ekran açan küçük bir Swift çerçevesidir. Sanat Atlası'nın kendisi ayrı depoda (`emrymn/sanat-atlasi`) durur ve orada geliştirilir. Oraya gelen her yenilik **Xcode'a gerek kalmadan** uygulamaya da gelir.

- **İnternetsiz de açılır.** Bir kez internetle açtıktan sonra sitenin önbelleği uygulamanın içinde de çalışır.
- İlerlemen ve ayarların uygulamanın içinde kalıcı olarak saklanır.
- **Doğru/yanlış titreşimi** iPhone'un kendi titreşim motoruyla çalışır: doğruda tek, yanlışta çift titreşim.
- "Silinsin mi?" gibi sorular iOS'un kendi pencereleriyle gelir.
- Wikipedia, müze sayfaları gibi dış linkler Safari'de açılır.
- Kenardan kaydırarak geri gidebilirsin.
- **Ana ekran widget'ı "Günün tablosu":** Bugün ekranındaki tablonun aynısı, her gece yenilenir. Dokununca Nora Sanat açılır.
- **Tekrar hatırlatması:** Tekrarı gelen sanatçı varsa her gün seçtiğin saatte "Bugün 12 sanatçı tekrarını bekliyor" bildirimi.
- **Simge rozeti:** Sitedeki Ayarlar → *Simge rozeti* artık Nora Sanat'ın simgesinde çalışır.

## Mac'te ilk kurulum (bir kere)

Podcast uygulamasında yaptığının aynısı. Apple ID'n Xcode'a zaten ekli.

```bash
cd ~ && git clone https://github.com/emrymn/nora-sanat.git
```

```bash
cd ~/nora-sanat && ./kur.sh
```

```bash
open NoraSanat.xcodeproj
```

iPhone'u bağla, üstten iPhone'unu seç ve **▶**'a bas. İlk açılışta telefon "güvenilmeyen geliştirici" derse: **Ayarlar → Genel → VPN ve Aygıt Yönetimi** → Apple Development … → **Güven**.

> **Ücretsiz Apple ID ile en çok 3 uygulama** yüklenebilir ve her biri 7 günde bir Xcode'dan yeniden yüklenmelidir (▶). Verilerin silinmez.
> Widget, uygulamanın içinde gelir; ayrı bir uygulama sayılmaz. Ama Apple'da ayrı bir kimlik (App ID) açar. Ücretsiz hesapta haftada en çok 10 kimlik açılabilir; Podcast + Nora Sanat + widget bunun içinde rahat kalır.

## Widget'ı ekleme

1. Ana ekranda boş bir yere basılı tut → sol üstte **Düzenle** → **Widget Ekle**.
2. Listede **Nora Sanat**'ı bul. Küçük, orta ya da büyük boyutu seç → **Widget Ekle**.
3. İlk açılışta internet gerekir: tabloyu ve görselini siteden kendisi indirir. Sonra her gece yarısı yenilenir.

Widget, Bugün ekranındaki tabloyla aynı kuralla seçer. Uygulamada "başka bir sanatçı getir" dersen widget yine günün asıl tablosunu gösterir.

## Tekrar hatırlatması

- İlk açılışta, tekrarı gelen bir sanatçın varsa iPhone **bildirim izni** sorar: **İzin Ver**.
- Bildirim her gün **20:00**'de gelir, yalnızca o gün tekrar bekleyen sanatçı varsa. Turu bitirdiysen o günün bildirimi kendiliğinden kalkar.
- Saati değiştirmek ya da kapatmak için: iPhone **Ayarlar → Uygulamalar → Nora Sanat → Tekrar hatırlatması**.
- Bildirime dokununca Nora Sanat **Çalış** sekmesinde açılır.
- Sayılar Sanat Atlası'nın kendi ilerlemenden hesaplanır (sitenin "tekrar bekliyor" sayısıyla aynı). Sitenin koduna dokunulmadı.
- Simgede sayı görmek istersen: Nora Sanat'ta **Ayarlar → Simge rozeti**'ni aç.

## İlerlemeni Safari'deki Atlas'tan taşıma

Safari'den ana ekrana eklediğin **Atlas** ile Nora Sanat verilerini paylaşamaz. Bir kere taşıman gerekiyor:

1. Ana ekrandaki eski **Atlas**'ı aç. **Ayarlar** (sağ üstteki dişli) → **Yedekle**'ye bas. İlerlemen panoya kopyalanır.
2. **Nora Sanat**'ı aç. **Ayarlar → Yedeği geri yükle** kutusuna yapıştır ve onayla.
3. İlerlemenin geldiğini gördükten sonra eski Atlas simgesini silebilirsin.

## Güncelleme

- **Sanat Atlası'ndaki yenilikler:** Hiçbir şey yapman gerekmez. Uygulama açılınca gelir. Sanat Atlası "yeni sürüm hazır" derse **Yenile**'ye bas.
- **Nora Sanat çerçevesindeki değişiklikler** (seyrek):

  ```bash
  cd ~/nora-sanat && git pull
  ```

  Sonra Xcode'da **▶**.

## Telefonda deneme listesi

- [ ] Ana ekrandaki simgenin altında **Nora Sanat** yazıyor.
- [ ] Açılınca Tuval geliyor. Üstte saat/pil çubuğu okunuyor, altta sekme çubuğu tam görünüyor (çentik ve alt çizgi üstüne binmiyor).
- [ ] Sekmeler, kaydırma ve tam ekran görüntüleyici çalışıyor.
- [ ] Atölye'de bir tur: doğru cevapta tek, yanlışta çift titreşim (Ayarlar'da titreşim açıkken).
- [ ] Ayarlar'da bir "silinsin mi?" sorusu iOS penceresiyle çıkıyor, **Vazgeç** çalışıyor.
- [ ] Bir sanatçının Wikipedia linki Safari'de açılıyor.
- [ ] Uçak modunu aç, uygulamayı yukarı kaydırıp kapat, tekrar aç. Yine açılıyor.
- [ ] Yedek geri yükleme sonrası ilerleme görünüyor.
- [ ] Widget galerisinde **Nora Sanat → Günün tablosu** var. Üç boyutta da tablo, adı, ressamı ve yılı görünüyor. Bugün ekranındakiyle aynı tablo.
- [ ] Widget'a dokununca Nora Sanat Bugün ekranında açılıyor.
- [ ] (T1 sonrası) Güncellemeden sonra widget'ı bir kez internetteyken yenile (ana ekranda bekle): tablo yine geliyor. Sonra uçak modunda da görünmeye devam ediyor.
- [ ] (T2 sonrası) Uygulama her zamanki gibi açılıyor; Ben sekmesinde ilerlemen (işlenen konular, seri, tekrar sayısı) aynen duruyor. Bir tur çöz: sayılar artıyor, uygulamayı kapatıp açınca kalıyor.
- [ ] Bildirim izni soruldu. iPhone Ayarlar → Uygulamalar → Nora Sanat'ta **Tekrar hatırlatması** (Hatırlat, Saat) var.
- [ ] Saati bir sonraki saat başına al (örneğin şimdi 20:40 ise 21:00), Nora Sanat'ı aç ve kapat: o saatte "Bugün N sanatçı tekrarını bekliyor" geliyor. N, Çalış'taki sayıyla aynı.
- [ ] Bildirime dokununca Çalış sekmesi açılıyor.
- [ ] Nora Sanat'ta Ayarlar → **Simge rozeti** açılabiliyor ve simgede sayı çıkıyor.
- [ ] (T3) Uygulama eskisi gibi açılıyor: sekmeler, titreşim, Gece/Gündüz geçişi, saat çubuğunun rengi aynı. Gündüz'e geçince saat/pil çubuğu koyu yazıya dönüyor.
- [ ] (T4) Uygulama yine eskisi gibi (henüz hiçbir sekme yerli değil). Xcode'da Scheme → Run → Arguments'a `-yerliSekme galeri` ekleyip çalıştır:
  - Sitenin çubuğunda Galeri'ye dokun: çubuk yerinde kalıyor, yalnız hap Galeri'ye kayıyor (yerli Galeri yeri açılır).
  - Yerli çubukta Yolculuk'a dokun: site geri geliyor, hap kaymaya devam ediyor; çubuk zıplamıyor.
  - Simgeler, yazılar, Çalış'taki sayı sitedekiyle aynı. Parmağı çubukta gezdir: hap parmağı izliyor.
  - Ortadaki dişliye dokun (ya da yukarı çek): Hızlı ayarlar açılıyor. Gündüz'e geç: renkler değişiyor; Günlük kart +/− site Ayarlar'ında da aynı.
- [ ] (C1c) Çalış hâlâ sitenin. Xcode'da Arguments'a `-ekran pekistir` ekleyip çalıştır (yerli pekiştirme, karışık tur):
  - Hiç sorulmamış sanatçıda önce "Yeni sanatçı · önce tanış" geliyor: üç eser, şeritte dokununca vitrin değişiyor, vitrine dokununca görüntüleyici açılıyor. "Soruya geç": sorulan eser tanışmadakilerden biri değil.
  - Kart sitedeki gibi: üstte × ve sayaç, parçalı çizgi, harfli dört şık, Bilmiyorum. Yanlış şık: yaprakta ipucu, "Karşılaştır" ve Ayrıntılar (tekrar kutusu, seviye).
  - Aynı ikiliyi ikinci kez karıştır: yaprakta "Bu ikisini 2. kez karıştırdın" ve iki sanatçının ikişer eseri.
  - Ayarlar'da Tanışma kapalıyken yeni sanatçıda tanışma gelmiyor.
  - Tur bitince "x / n kart doğru", seviye atlayan dönem varsa listesi, "Bir tur daha".
- [ ] (C4b) Ben artık yerli. Bugün'de sağ üstteki Ben düğmesine dokun:
  - Üstte kayan eser duvarı, "Ben" başlığı, büyük konu sayısı, Sanatçı / Kalıcı / Tekrar sütunları sitedeki gibi. Altta yerli sekme çubuğu, Bugün seçili.
  - Son 12 hafta karelerinde bugünkü kare çerçeveli; çalıştığın günler akımın renginde.
  - Sıradaki konuda **İşlendi yap**: düğme dolup "İşlendi" oluyor, sonra sıradaki konu geliyor; yeni sanatçı açıldıysa altta "… yeni sanatçı açıldı · Tanış" kartı çıkıyor.
  - Kurs kitaplığında bir kitaba dokun: kart altında açılıyor; "Dokununca işaretle"de kitaba dokunmak konuyu doğrudan işaretliyor.
  - Akım kartları, "Zayıf önce", en zayıf sanatçılar ve "Hatalarım turu" dokununca doğru yere gidiyor.
  - Dişliye dokun: Ayarlar açılıyor, alttaki dişli dil gizleniyor. Tema, gündüz rengi, yazı boyutu, hareket hapları ve anahtarlar sitedeki gibi; değiştirince site de aynı ayarı gösteriyor. Geri düğmesi Ben'e döndürüyor.
  - Yedekle, ayarı değiştir, yedeği yapıştırıp **Geri yükle**: onay sorusu çıkıyor, önceki ayar geri geliyor.
- [ ] (C5) Ben → Ayarlar → **En büyük kopyaları telefona indir** (indirme artık uygulamanın kendisinde):
  - Açıklamada "5624 eserin … (19402 dosya) · toplam 21,0 GB. Telefonda: 0 / 19402" gibi sayılar var (sayılar siteyle aynı).
  - Wi-Fi'deyken **İndir**: altında çubuk ve "Telefonda n / 19402 · Parça 1 / 33 · ~… GB" ilerliyor; **Durdur** çıkıyor.
  - Uygulamadan çık (ana ekrana dön), birkaç dakika sonra geri gel: sayı arkada da artmış olmalı.
  - **Durdur**: "Durduruldu: n görsel indirildi…". Yeniden **İndir** kaldığı yerden sürüyor.
  - Uygulamayı yukarı kaydırıp kapat, yeniden aç: yarım kalan indirme kendiliğinden sürüyor (Ayarlar'ı açınca sayı artıyor).
  - Birkaç parça indikten sonra uçak modunu aç: Ben'in eser duvarı, kitap kapakları ve tam ekran görüntüleyicide indirilmiş eserler (büyük kopya dahil) yine açılıyor.
  - **Telefondan sil** → "silinsin mi?" → **Sil**: "Silindi.", Telefonda: 0. (Sitenin eskiden indirdikleri de silinir.)
  - iPhone Ayarlar → Genel → iPhone Saklama Alanı → Nora Sanat: "Belgeler ve Veriler" inenler kadar büyüyor, silince küçülüyor.
- [ ] (G2b) Galeri (G3'ten beri yerli sekme):
  - Üstte "Galeri", cam arama hapı ve kalp; altında Akımlar / Başyapıtlar / Konular / Zaman sekmeleri sitedeki gibi.
  - Kemerli kartı parmakla kaydır: komşu kart küçük ve soluk, ortaya oturan büyüyor; alttaki çark ve "01 / 28" birlikte dönüyor, zemin deseni dönem değişince değişiyor. Çarkı parmakla çevir: kartlar onu izliyor.
  - "Bütün akımlar" dizini açılıp kapanıyor. "Salona gir": sahne, hikâye ("Devamını oku"), mercekli tanıma, eserler, sanatçılar, "Tura başla" kartı (Çalış'ta dönem turu açılıyor), dönem, yan yana koy, tipik konular.
  - Sanatçıda büyük ad, Dinle, eser şeridi, "Tümünü göster" (iki sütun), Karşılaştır. Konular'da sekmeler kayarken üstte yapışık kalıyor; öne çıkan kart kendiliğinden değişiyor.
  - Kenardan sağa kaydırınca bir önceki sayfaya dönüyor.
- [ ] (G3) Galeri → **Başyapıtlar**:
  - Üstte dönem sekmeleri yapışık kalıyor; büyük "Öne çıkan" kart 6 sn'de bir değişiyor (rozetler: Hikâye, n ayrıntı). Her dönemin şeridi yana kayıyor, sonunda "Hepsine bak".
  - Bir döneme dokun: akım başlıkları ve iki sütun (beşte biri geniş kart); "Henüz kursta yok" etiketi kurstaki konuna göre.
  - Bir esere gir (ör. Elçiler): tablo kenardan kenara; kalbe dokun, Koleksiyonum'da görünmeli. Aşağı kaydırınca üstte cam çubuk beliriyor, küçük resme dokununca başa dönüyor.
  - Metnin arasındaki ayrıntı kırpımlarına dokun: görüntüleyici o ayrıntıda açılıyor. Alttaki "Yakından bak · n ayrıntı" incelemeyi baştan açıyor.
  - "Okumayı sürdür": ayrıntılı anlatım aynı sayfada açılıyor; noktalı altı çizili terime dokununca altta sözlük kartı. Resimli bir karşılaştırmaya dokun: iki eser üst üste, "Eserin sayfası" o esere gidiyor.
  - Aramada bir başyapıt adı yaz (ör. "elçiler"): sonuç yerli sayfayı açıyor. Sanatçı sayfasındaki "Yakın okuma" satırları da.
- [ ] (Z2b) **Yüklemeden önce** eski sürümde Ben → Ayarlar → Yedekle ile yedek al (JSON dosyası olarak da kaydet). Yeni sürümü yükleyip aç: ilerleme bir kez Swift'e taşınır. Ben'de işlenen konu sayısı, Çalış'taki tekrar sayısı ve yarım kalan tur aynı olmalı. Hızlı ayarlardan temayı değiştir, uygulamayı kapatıp aç: tema kalmalı. Yedekle → Geri yükle (aynı yedekle) sorunsuz olmalı.
- [ ] (Z3d) Galeri ve Çalış zeminindeki renk süzmesi artık açıkça görünmeli: sol üstte tablonun canlı bir rengi (ör. Elçiler'de kırmızı), sağ altta öbürü. Hâlâ silik ya da fazla ise söyle.
- [ ] (Z3c) Galeri ve Çalış'ın zemini o sayfanın tablosunun iki renginden süzülür (sol üstte biri, sağ altta öbürü): Akımlar'da çarkı çevir, renkler salonla değişir; bir sanatçı, konu ya da başyapıt aç; Çalış'ta bugünün dersinin renkleri. Arama ve koleksiyon son bakılan tablonun renklerinde kalır.
- [ ] (T7) Beş sekme de yerli: Bugün ve Yolculuk da Swift. Widget'tan Çalış'ı aç, birkaç saniye bekle: Bugün'e atlamamalı. Galeri'de bir akımın "Pekiştir"ine dokun: Çalış'ta o akımın turu açılmalı. Yolculuk'ta bir durağın "Derse git"i Çalış'ta dersi açmalı.
- [ ] (T6) Çalış artık yerli sekme: Çalış'a dokun, yerli ekran açılıyor (Bugünün dersi, Çalışma masan, Turlar). Widget'taki tekrar sayısına dokununca da yerli Çalış açılıyor. Bir tur başlat: sekme çubuğu gizleniyor, tur bitince geri geliyor.
- [ ] (C3) Çalış'a geç (T6'dan sonra yerli):
  - Bugünün dersi kartında bir adım halkasına (Gör / Öğren / Ayırt et) dokun: doğrudan o adım açılıyor; alttaki devam satırı da sıradaki adımı açıyor. Ders sayfasındaki adım satırları da.
  - **Gör**: koyu sahne, önce eserin tamamı; "Ayrıntılara bak" ile kamera ayrıntıya kayıp yaklaşıyor (uzak ayrıntıda önce biraz geri çekiliyor), alttaki yazı solup yenisi yükseliyor. "Sıradaki eser"de resim çapraz solarak değişiyor. Ayarlar'da Hareket kapalıyken her şey anında.
  - Gör'ü yarıda bırak, dersi yeniden aç: kaldığın ayrıntıdan açılıyor; site de aynı yeri gösteriyor (`#/pekistir/ders/<akım>/gor`).
  - **Öğren**: büyük eser, madde, "Bu eserde" kutusu, üç küçük eser (dokununca büyük eser değişiyor), Açıklama. Büyük esere dokun: görüntüleyici açılıyor. Altta "Anladım · II. özellik".
  - **Ayırt et**: "Hangisi …?" iki eser; birine dokun: doğru yeşil, yanlış kırmızı çerçeve, altında iki sütun ve dönem metinleri. Cevaptan sonra esere dokununca görüntüleyici.
  - Adım bitince yeşil onay, "Sıradaki adım: …" ve "Derse dön"; üç adım da bitince "Haritaya geç". Ben ve sitedeki ders sayfası aynı ilerlemeyi gösteriyor.
- [ ] (G4b) Bugün henüz yerli değil; Xcode'dan `-yerliSekme bugun -adres "#/"` argümanıyla aç:
  - Aşağı kaydır: kamera her ayrıntıya yaklaşıyor, sağda pirinç noktalar; yürürken sekme çubuğu ve hareket düğmesi kayboluyor, yukarı kaydırınca çubuk geri geliyor.
  - Hayatı'na in: resim bulanıklaşıp koyulaşıyor, üstte tarih ve Ben'in arkasında koyu şerit. Sonda pirinç künye, "Resmi gezdin.", desteli tur kartı, iki karo, Dinle, Başa dön halkası.
  - Telefonu eğ: resim hafifçe kayıyor (Ayarlar'da hareket açıkken, düğmeye basmadan).

## Geliştirme

```
NoraSanat.xcodeproj/    Xcode projesi (NoraSanat/ klasörü senkronize: yeni dosyalar kendiliğinden girer)
Config/                 Base.xcconfig, Info.plist (App-Bound Domains), Local.xcconfig (git'e girmez)
NoraSanat/              NoraSanatApp.swift (giriş), WebKabugu.swift (WKWebView çerçevesi),
                        TekrarKoprusu.swift (site ↔ uygulama betiği), Hatirlatici.swift (bildirim, rozet, sayfaya gitme),
                        Settings.bundle (iOS Ayarlar'daki hatırlatma ayarları)
NoraSanat/Kabuk/        IlerlemeKoprusu.swift (sitenin ilerlemesini Swift'ten okuma/yazma), DEBUG özet ekranı (-ekran ilerleme)
NoraSanatWidget/        "Günün tablosu" widget'ı
Paketler/NoraCekirdek/  Arayüzden bağımsız mantık + testler (Linux'ta: swift test --package-path Paketler/NoraCekirdek)
                        SiteVerisi/: sitenin verisi (indirme, önbellek, sanatçılar, eserler, görsel adresleri)
                        Ilerleme/: ilerleme modeli ve tekrar kuralları (Leitner, geçmiş, seviye, kilit)
Testler/                Köprü betiğinin testleri (node --test Testler/tekrarTakvimi.test.mjs)
.github/workflows/      Her PR'da: derleme + simülatörde açılış ekran görüntüsü
```
- [ ] (G5) Galeri → **Zaman** (Galeri'nin dördüncü sekmesi): üstte yıl, "n sanatçı hayatta", altında renkli çubuklu cetvel ve pirinç ibre. Cetveli parmakla kaydır ya da bir yere dokun: yıl ve aşağıdaki akım akım liste değişiyor; açık sanatçıya dokununca sanatçı sayfası. Kilitli satırda "Konu n'de açılır".
- [ ] (G5) Yolculuk henüz sitenin. Xcode'da Arguments'a `-yerliSekme yolculuk` ekleyip çalıştır, Yolculuk'a dokun:
  - Harita "buradasın" durağında açılıyor (durak ekranın ortasının biraz altında, altında adı ve "Kolay · 8 soru seni bekliyor"). Sol üstte kurs rozeti, sağ üstte güneş/ay ve kaydırdıkça değişen dönem etiketi.
  - Durakların çevresinde halka ve altında üç yıldız; kilitlilerde kesik halka ve kilit.
  - Açık bir durağa dokun: öğrenci patikadan yürüyor, altta koyu kart açılıyor (kapak, "Dönem · n sanatçı", ad, beyaz düğme, tanışma grupları, Kolay / Orta / Zor, Akım sayfası). Aşağı çekince kapanıyor.
  - Kurs rozetine dokun: "n / 57 konu işlendi", sıradaki konunun Türkçe adı, "k sanatçı açılacak", **İşlendi yap**. Resimdeki saklı bir motife dokun: çerçeveli eser, hikâye, "… sayfası".
  - Kartta "1. grupla tanış" ya da "Kolay'a başla": tanışma ve sorular Çalış'taki turun aynısı. Grup bitince "Grup tamam" ve "2. grupla tanış"; seviye bitince sergi duvarı, madalyon, yıldızlar, skor, salonlar ve "Orta salonuna geç".
