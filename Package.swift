// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "raygun4apple",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_10)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "raygun4apple",
            targets: ["raygun4apple"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "raygun4apple",
            dependencies: [],
            path: "Sources",
            exclude: ["include"],
            cxxSettings: [
                .define("GCC_ENABLE_CPP_EXCEPTIONS", to:"YES"),
                .headerSearchPath("include")
            ],
            linkerSettings: [
                .linkedLibrary("z"),
                .linkedLibrary("c++")
            ]
        ),
    ],
    cxxLanguageStandard: .gnucxx11
)
