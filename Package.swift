// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "raygun4apple",
        platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "raygun4apple",
            
            targets: ["raygun4appleCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "raygun4appleCore",
            dependencies: ["raygun4appleCoreSeeds","raygun4apple-iOS"],
            path: "./Sources/Raygun",
             exclude: [  ]
            ),        
        .target(
            name: "raygun4appleCoreSeeds",
            dependencies: [],
            path: "./Sources/Raygun_KSCrash",
             exclude: [  ]
            ),
        .target(
            name: "raygun4apple-iOS",
            dependencies: [],
            path: "./raygun4apple-iOS",
             exclude: [
                // "../Sources/Raygun_KSCrash/Recording/Tools/NSError+Raygun_SimpleConstructor.h",
              //   "../Sources/Raygun/UIViewController+RaygunRUM.h",
               //  "../Sources/Raygun/UIViewController+RaygunRUM.m"
               ]
            ),
        .testTarget(
            name: "raygun4appleTests",
            dependencies: ["raygun4appleCore"]),
    ]
)
