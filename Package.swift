// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "spiritualrecordsserver",
    platforms: [
      .macOS(.v10_15),
    ],
    products: [
        .library(name: "spiritualrecordsserver", targets: ["App"]),
    ],
    dependencies: [
      .package(url: "https://github.com/vapor/vapor.git", from: "4.3.0"),
      .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-rc.3.1"),
      .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0-rc.3"),
      .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0-rc.1.2"),
      .package(url: "https://github.com/swift-aws/S3.git", from: "4.7.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
          .product(name: "Vapor", package: "vapor"),
          .product(name: "Fluent", package: "fluent"),
          .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
          .product(name: "Leaf", package: "leaf"),
          .product(name: "S3", package: "S3"),
        ]),
        .target(name: "Run", dependencies: [
          .target(name: "App"),
        ]),
        .testTarget(name: "AppTests", dependencies: [
          .target(name: "App"),
        ])
    ]
)
