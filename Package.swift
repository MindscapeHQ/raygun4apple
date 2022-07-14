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
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "raygun4apple",
            targets: ["raygun4apple"]),
      //  .library(
//name: "raygun4apple_macOS",
      //      targets: ["raygun4apple-macos"]),
      //  .library(
       //     name: "raygun4apple_tvOS",
        //    targets: ["raygun4apple-tvos"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
//        .target(
//            name: "raygun4apple-core",
//            dependencies: ["raygun4apple-kscrash"],
 //           path: "Sources/Raygun",
//            exclude: ["NSViewController+RaygunRUM.h", "NSViewController+RaygunRUM.m","UIViewController+RaygunRUM.h","UIViewController+RaygunRUM.m"],
//            publicHeadersPath: "public",
 //           cxxSettings: [
 //               .headerSearchPath("."),
 //               .headerSearchPath("../Raygun_KSCrash/Recording"),
 //               .headerSearchPath("../Raygun_KSCrash/Recording/Tools"),
 //               .headerSearchPath("../Raygun_KSCrash/Reporting/Tools"),
 //           ]
  //      ),
 //       .target(
 //           name: "raygun4apple-ios",
  //          dependencies: ["raygun4apple-core"],
  //          path: "raygun4apple-iOS",
  //          exclude: [],
  //          publicHeadersPath: ".",
  //          cxxSettings: [
  //              .headerSearchPath("public")
  //          ]
  //      ),
  //      .target(
  //          name: "raygun4apple-macos",
  //          dependencies: ["raygun4apple-core"],
  //          path: "raygun4apple-macOS",
  //          exclude: [],
  //          publicHeadersPath: "public",
  //          cxxSettings: [
  //              .headerSearchPath(".")
   //         ]
   //     ),
   //     .target(
   //         name: "raygun4apple-tvos",
   //         dependencies: ["raygun4apple-core"],
    //        path: "raygun4apple-tvOS",
   //         exclude: [],
   //         publicHeadersPath: "public",
    //        cxxSettings: [
    //            .headerSearchPath(".")
    //        ]
    //    ),
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
