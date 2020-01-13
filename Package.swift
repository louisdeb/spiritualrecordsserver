// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "spiritualrecordsserver",
    products: [
        .library(name: "spiritualrecordsserver", targets: ["App"]),
    ],
    dependencies: [
      .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),
      .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
      .package(url: "https://github.com/vapor/auth.git", from: "2.0.4"),
      .package(url: "https://github.com/vapor/leaf.git", from: "3.0.0"),
      .package(url: "https://github.com/vapor-community/vapor-ext.git", from: "0.3.4"),
      .package(url: "https://github.com/skelpo/s3-vapor3", .revision("a504056ac772aa41f2dd71da6ba1344909049592"))
    ],
    targets: [
        .target(name: "App", dependencies: ["Leaf", "Authentication", "FluentPostgreSQL", "Vapor", "VaporExt", "S3"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)
