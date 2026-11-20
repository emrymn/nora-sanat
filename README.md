# Nora Sanat

**Sanat Atlası**'nın iPhone uygulaması. Ana ekranda **Nora Sanat** adıyla durur.

Uygulama, Sanat Atlası'nı (`sanat-atlasi.pages.dev`) Safari'nin çubukları olmadan, tam ekran açan küçük bir Swift çerçevesidir. Sanat Atlası'nın kendisi ayrı depoda (`emrymn/sanat-atlasi`) durur ve orada geliştirilir. Oraya gelen her yenilik **Xcode'a gerek kalmadan** uygulamaya da gelir.

- **İnternetsiz de açılır.** Bir kez internetle açtıktan sonra sitenin önbelleği uygulamanın içinde de çalışır.
- İlerlemen ve ayarların uygulamanın içinde kalıcı olarak saklanır.
- **Doğru/yanlış titreşimi** iPhone'un kendi titreşim motoruyla çalışır: doğruda tek, yanlışta çift titreşim.
- "Silinsin mi?" gibi sorular iOS'un kendi pencereleriyle gelir.
- Wikipedia, müze sayfaları gibi dış linkler Safari'de açılır.
- Kenardan kaydırarak geri gidebilirsin.

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

## Geliştirme

```
NoraSanat.xcodeproj/    Xcode projesi (NoraSanat/ klasörü senkronize: yeni dosyalar kendiliğinden girer)
Config/                 Base.xcconfig, Info.plist (App-Bound Domains), Local.xcconfig (git'e girmez)
NoraSanat/              NoraSanatApp.swift (giriş), WebKabugu.swift (WKWebView çerçevesi)
.github/workflows/      Her PR'da: derleme + simülatörde açılış ekran görüntüsü
```
