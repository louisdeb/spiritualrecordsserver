// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "spiritualrecordsserver",
    products: [
        .library(name: "spiritualrecordsserver", targets: ["App"]),
    ],
    dependencies: [
      .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
      .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
      .package(url: "https://github.com/vapor/auth.git", from: "2.0.3"),
      .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),
      .package(url: "https://github.com/vapor-community/vapor-ext.git", from: "0.3.4"),
      .package(url: "https://github.com/LiveUI/S3.git", .revision("253053d5c046b6bd63771218049f62d37cf58653"))
    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf", "Authentication", "FluentPostgreSQL", "Vapor", "VaporExt", "S3"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

