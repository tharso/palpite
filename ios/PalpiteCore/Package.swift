// swift-tools-version: 6.0
// Regras do jogo, sem tela. O app iOS usa este pacote; os testes rodam com `swift test`.
import PackageDescription

let package = Package(
    name: "PalpiteCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "PalpiteCore", targets: ["PalpiteCore"]),
    ],
    targets: [
        .target(name: "PalpiteCore"),
        .testTarget(name: "PalpiteCoreTests", dependencies: ["PalpiteCore"]),
    ]
)
