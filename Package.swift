// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "spiritualrecordsserver",
    products: [
        .library(name: "spiritualrecordsserver", targets: ["App"]),
    ],
    dependencies: [
      // 💧 A server-side Swift web framework.
      .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

      // 🔵 Swift ORM (queries, models, relations, etc) built on SQLite 3.
      .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
      
      // 🔐 Vapor Auth
      .package(url: "https://github.com/vapor/auth.git", from: "2.0.3"),
        
      // 🍃 Leaf (front-end)
      .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0")
    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf", "Authentication", "FluentSQLite", "Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

