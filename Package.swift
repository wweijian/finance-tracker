// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Finance",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Finance", targets: ["FinanceApp"])],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0")
    ],
    targets: [
        .executableTarget(
            name: "FinanceApp",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")],
            path: ".",
            exclude: ["AGENTS.md", "Tests", "transactions", "Makefile", "Packaging", "dist"],
            sources: ["App", "Controllers", "Models", "Repositories", "Services", "Views"],
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "FinanceAppTests",
            dependencies: ["FinanceApp"],
            path: "Tests"
        )
    ]
)
