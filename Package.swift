// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "raygun4apple",
    platforms: [
        .iOS(.v10),
        .tvOS(.v10),
        .macOS(.v10_10)
    ],
    products: [
        .library(
            name: "raygun4apple",
            targets: ["raygun4apple"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "raygun4apple",
            dependencies: [],
            path: "Sources",
            publicHeadersPath: "public",
            cxxSettings: [
                .define("GCC_ENABLE_CPP_EXCEPTIONS", to: "YES"),
                .headerSearchPath("Raygun_KSCrash/Installations"),
                .headerSearchPath("Raygun_KSCrash/llvm/ADT"),
                .headerSearchPath("Raygun_KSCrash/llvm/Config"),
                .headerSearchPath("Raygun_KSCrash/llvm/Support"),
                .headerSearchPath("Raygun_KSCrash/Recording/Monitors"),
                .headerSearchPath("Raygun_KSCrash/Recording/Tools"),
                .headerSearchPath("Raygun_KSCrash/Recording"),
                .headerSearchPath("Raygun_KSCrash/Reporting/Filters/Tools"),
                .headerSearchPath("Raygun_KSCrash/Reporting/Filters"),
                .headerSearchPath("Raygun_KSCrash/Reporting/Tools"),
                .headerSearchPath("Raygun_KSCrash/Reporting"),
                .headerSearchPath("Raygun_KSCrash/swift/Basic"),
                .headerSearchPath("Raygun_KSCrash/swift"),
                .headerSearchPath("Raygun")
            ]
        ),
    ],
    cxxLanguageStandard: .gnucxx11
)
