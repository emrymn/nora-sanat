# Nora Sanat: kodlama ajanları için (ChatGPT Codex)

Bu depo Sanat Atlası'nın (`emrymn/sanat-atlasi`) iPhone uygulamasıdır: SwiftUI, iOS 17+, Swift dil modu 5. Ekranlar sitedeki karşılıklarından Swift'e taşınıyor.
Bütün metinler, yorumlar, commit ve PR'lar **Türkçe**.

**Başlamadan önce oku:**
1. `koordinasyon/ISLER.md`: iş listesi, senin şeridin (ChatGPT: **G** ve **C**), başlarken ve bitirirken kuralları, mimari kararlar.
2. `CLAUDE.md`: depo kuralları (senin için de geçerli).

**Kısaca:**
- Yalnız kullanıcının mesajında adıyla verdiği işi yap; kendin iş seçme. Bağımlılığı `bitti` değilse başlama.
- **Teslim etmeden önce:** CI yeşil olmalı; sitenin kuralını taşıyan her parça kâhin + XCTest ile sınanmış olmalı (`Testler/kahin/README.md`); yeni ekran CI'da ekran görüntüsüyle görünmeli. "Kâhin denetçide" ya da "CI görülmedi" diye teslim etme.
- Dalın adı `is/<ID>-<kısa-ad>`. Hemen taslak PR aç.
- Yalnız kendi klasörlerine dokun. `project.pbxproj`'a, `Package.swift`'e ve ortak Kabuk dosyalarına dokunma.
- Bitirince `koordinasyon/ISLER.md`'de **kendi satırını** (durum) ve **kendi bölümündeki Devir notunu** güncelle. Rapor budur.
- PR'ı birleştirme. Önce Claude denetler, sonra kullanıcı birleştirir.
- iOS derlemesini GitHub Actions yapar. Ortamında Xcode yoksa bu normaldir.
- Paket testleri: `swift test --package-path Paketler/NoraCekirdek`. Kâhinler: `Testler/kahin/README.md`.
