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
