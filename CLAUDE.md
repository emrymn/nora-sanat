# Nora Sanat — Claude için notlar

Sanat Atlası PWA'sının (`emrymn/sanat-atlasi`, yayında: https://sanat-atlasi.pages.dev/) iPhone çerçeve uygulaması. SwiftUI + WKWebView, iOS 17+. Tek kullanıcı: depo sahibi. Metinler, yorumlar, commit ve PR'lar **Türkçe**.

## Kurallar
- Uygulamanın içeriği bu depoda değil: özellik ve tasarım değişiklikleri `sanat-atlasi` deposunda yapılır. Burada yalnız çerçeve (yerel köprüler, izinler, açılış, simge) değişir.
- `Config/Info.plist` → `WKAppBoundDomains` (en çok 10). Service worker'ın çalışması ve sitenin yüklediği dış kaynaklar için gerekli; sitenin yeni bir alan adından kaynak yüklemesi gerekirse buraya eklenir.
- Yerel köprüler `WebKabugu.swift`'teki `Koordinator`'da: `navigator.vibrate` → titreşim, JS `alert/confirm/prompt` → `UIAlertController`, hareket izni, dış linkler → Safari.
- `NoraSanat/` Xcode 16 senkronize klasör; yeni dosya için `project.pbxproj`'a dokunma. İmzalama `Config/Local.xcconfig`'te (`./kur.sh`), pbxproj'a yazma.
- Swift dil modu 5.
- Kod bulutta (Linux) yazılır; derleme ve simülatör ekran görüntüsünü `.github/workflows/ios-derle.yml` yapar. PR yeşil olmadan birleştirme yok.
