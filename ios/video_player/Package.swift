// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "video_player",
    platforms: [
        .iOS("15.0"),
    ],
    products: [
        .library(name: "video-player", targets: ["video_player"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "video_player",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "SnapKit", package: "SnapKit"),
            ],
            path: "Sources/video_player",
            exclude: [
                "VideoPlayerPlugin.h",
                "VideoPlayerPlugin.m",
            ],
            resources: [
                .process("Assets"),
            ]
        ),
    ]
)
