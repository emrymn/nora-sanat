import AppIntents
import Foundation

/// Z3o (yeni, sitede yok): Siri ve Kısayollar. "Nora Sanat'ta günün tablosunu aç", "Nora Sanat'ta pekiştir" …
/// Her eylem uygulamayı açar ve sitenin adresiyle yerli sekmeye gider (`Gezgin.git`). Kısayollar uygulamasında
/// otomasyona da konabilir (ör. her sabah günün tablosu).

struct GununTablosunuAc: AppIntent {
    static let title: LocalizedStringResource = "Günün tablosunu aç"
    static let description = IntentDescription("Bugün'deki günün tablosunu açar.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        Gezgin.shared.git("#/")
        return .result()
    }
}

struct PekistirmeyeBasla: AppIntent {
    static let title: LocalizedStringResource = "Pekiştirmeye başla"
    static let description = IntentDescription("Tekrarı gelen kartlarla karışık turu başlatır.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        Gezgin.shared.git("#/pekistir/karisik")
        return .result()
    }
}

struct CalisiAc: AppIntent {
    static let title: LocalizedStringResource = "Çalış'ı aç"
    static let description = IntentDescription("Bugünün dersini ve turları gösteren Çalış sekmesini açar.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        Gezgin.shared.git("#/pekistir")
        return .result()
    }
}

struct YolculuguAc: AppIntent {
    static let title: LocalizedStringResource = "Yolculuk haritasını aç"
    static let description = IntentDescription("Yolculuk haritasını kaldığın durakta açar.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        Gezgin.shared.git("#/harita")
        return .result()
    }
}

struct NoraKisayollari: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: GununTablosunuAc(),
                    phrases: ["\(.applicationName)'ta günün tablosunu aç", "\(.applicationName) günün tablosu",
                              "\(.applicationName)'ta bugünün tablosu"],
                    shortTitle: "Günün tablosu", systemImageName: "photo.artframe")
        AppShortcut(intent: PekistirmeyeBasla(),
                    phrases: ["\(.applicationName)'ta pekiştirmeye başla", "\(.applicationName) tekrar",
                              "\(.applicationName)'ta tekrar yap"],
                    shortTitle: "Pekiştir", systemImageName: "rectangle.stack")
        AppShortcut(intent: CalisiAc(),
                    phrases: ["\(.applicationName)'ta çalış", "\(.applicationName) bugünün dersi"],
                    shortTitle: "Çalış", systemImageName: "paintbrush")
        AppShortcut(intent: YolculuguAc(),
                    phrases: ["\(.applicationName)'ta yolculuğu aç", "\(.applicationName) harita"],
                    shortTitle: "Yolculuk", systemImageName: "map")
    }
}
