// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Ledgerly",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Ledgerly", targets: ["LedgerlyApp"])],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0")
    ],
    targets: [
        .executableTarget(
            name: "LedgerlyApp",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")],
            path: ".",
            exclude: ["AGENTS.md", "data", "database", "transactions"],
            sources: ["App", "Controllers", "Models", "Repositories", "Services", "Views"],
            resources: [.copy("Resources")]
        )
    ]
)
