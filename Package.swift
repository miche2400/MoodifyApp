// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MoodifyApp",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "MoodifyApp",
            targets: ["MoodifyApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "0.2.0") // Supabase dependency
    ],
    targets: [
        .target(
            name: "MoodifyApp",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift") 
            ],
            path: "Sources/MoodifyApp",
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Assets.xcassets")
            ]
        ),
        .testTarget(
            name: "MoodifyAppTests",
            dependencies: ["MoodifyApp"],
            path: "Tests/MoodifyAppTests"
        ),
        .testTarget(
            name: "MoodifyAppUITests",
            dependencies: ["MoodifyApp"],
            path: "Tests/MoodifyAppUITests"
        )
    ]
)
