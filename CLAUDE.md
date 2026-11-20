# Nora Sanat — Claude için notlar

Sanat Atlası PWA'sının (`emrymn/sanat-atlasi`, yayında: https://sanat-atlasi.pages.dev/) iPhone çerçeve uygulaması. SwiftUI + WKWebView, iOS 17+. Tek kullanıcı: depo sahibi. Metinler, yorumlar, commit ve PR'lar **Türkçe**.

## Swift'e geçiş (Claude + Gemini + ChatGPT, iş iş)
Sanat Atlası'nın ekranları sekme sekme Swift'e taşınıyor. **Her oturum önce `koordinasyon/ISLER.md`'yi okur**: iş listesi, şeritler, mimari kararlar, "başlarken/bitirirken" kuralları.
- Claude **K** şeridini (temel işler) yapar ve Gemini (**G**) ile ChatGPT'nin (**C**) her PR'ını **denetler**. Denetim kuralları ISLER.md'de.
- İşi bitiren o dosyada kendi işinin durumunu ve devir notunu yazar.
- Birleştirme yalnız denetim onayından sonra ve kullanıcı açıkça isteyince.
- Gemini ve ChatGPT `AGENTS.md`'yi okur.

## Kurallar
- Özellik ve içerik geliştirmesi hâlâ `sanat-atlasi` deposunda sürer; burada o ekranların Swift karşılıkları yazılır (kaynak dosya ve commit'i yorumda, davranış kâhin testiyle: `Testler/kahin/README.md`). Taşınmamış sekmeler siteyi gösterir.
- `Config/Info.plist` → `WKAppBoundDomains` (en çok 10). Service worker'ın çalışması ve sitenin yüklediği dış kaynaklar için gerekli; sitenin yeni bir alan adından kaynak yüklemesi gerekirse buraya eklenir.
- Yerel köprüler `WebKabugu.swift`'teki `Koordinator`'da: `navigator.vibrate` → titreşim, JS `alert/confirm/prompt` → `UIAlertController`, hareket izni, dış linkler → Safari.
- `NoraSanat/` ve `NoraSanatWidget/` Xcode 16 senkronize klasör; yeni dosya için `project.pbxproj`'a dokunma. İmzalama `Config/Local.xcconfig`'te (`./kur.sh`), pbxproj'a yazma.
- Sitenin koduna dokunmadan bağlanılır. Uygulama sitenin kurallarını kopyalıyorsa kaynağı yorumda yazılı ve testli olmalı:
  - `Paketler/NoraCekirdek/GununSanatcisi.swift` ↔ `js/gunun.js` (günün sanatçısı), `GununTablosu.swift` ↔ `gununHavuzu`, `yuruyusEserAdi`, `yuruyusAdresleri`.
    Test örnekleri (`Tests/.../Ornekler/site_cevaplari.json`) canlı siteden sitenin kendi modülleriyle alındı. Site bu kuralları değiştirirse örnekleri yeniden al.
  - `NoraSanat/TekrarKoprusu.swift` betiği ↔ `localStorage['sanat-atlasi:ilerleme'].skorlar` ve `js/gecmis.js` `vadeSayisi`.
- Widget uygulamayla veri paylaşmaz (ücretsiz Apple ID'de App Group yok); veriyi siteden kendisi indirir.
- Bildirim/rozet: `Hatirlatici`. Ayarları `NoraSanat/Settings.bundle` (anahtarlar: `hatirlatma`, `hatirlatmaSaati`).
- Arayüzden bağımsız mantık `Paketler/NoraCekirdek`'e girer ve test edilir (yalnız Foundation; SwiftUI/ImageIO dosyaları `#if canImport` ile korunur).
- Swift dil modu 5.
- Kod bulutta (Linux) yazılır; derleme ve simülatör ekran görüntüsünü `.github/workflows/ios-derle.yml` yapar. PR yeşil olmadan birleştirme yok.
