// swift-tools-version:5.9
// Nora Sanat'ın arayüzden bağımsız mantığı: günün tablosu seçimi, tekrar hatırlatma planı.
// Linux'ta da derlenir; `swift test` ile Mac olmadan sınanabilir.
import PackageDescription

let package = Package(
    name: "NoraCekirdek",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "NoraCekirdek", targets: ["NoraCekirdek"]),
    ],
    targets: [
        .target(name: "NoraCekirdek"),
        .testTarget(name: "NoraCekirdekTests", dependencies: ["NoraCekirdek"],
                    resources: [.copy("Ornekler")]),
    ]
)
