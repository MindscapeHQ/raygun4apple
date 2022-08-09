# Raygun4Apple

[Raygun](https://raygun.com/) provider for iOS, tvOS & macOS supporting Crash Reporting and Real User Monitoring.

Supports:
- iOS 10+
- tvOS 10+
- macOS 10.10+

## Installation

### Using the Swift Package Manager

To integrate Raygun into an SPM managed application, update your Package.swift file to include raygun4apple as a dependency. 

Here is an example of a macOS CLI application which uses raygun4apple as a dependency

```swift
import PackageDescription

let package = Package(
    name: "macos-cli",
    dependencies: [
        //Note - the version must be atleast 2.0.0 as this is earliest release of this package through SPM.
        .package(url: "https://github.com/MindscapeHQ/raygun4apple.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "macos-cli",
            dependencies: ["raygun4apple"])
    ]
)
```

### Configuring the Raygun client

The configuration step is slightly different if installed from via the Swift package manager. Rather than importing the specific header for the target application, simply import `raygun4apple`.

Here is an example which imports raygun4apple, initializes the provider, and sends a test exception.

```swift
import raygun4apple

let raygunClient = RaygunClient.sharedInstance(apiKey: "DURNOeq9qWCtVTbZaadOXA")
raygunClient.enableCrashReporting()
raygunClient.send(exception: NSException.init(name: NSExceptionName.illegalSelectorException, reason: "This is a macOS error!"))
```

### With CocoaPods

To integrate Raygun using CocoaPods, update your Podfile to include:

```bash
pod 'raygun4apple'
```

Once updated you can run `pod install` from Terminal.

### With GitHub releases

The latest release can be found [here](https://github.com/MindscapeHQ/raygun4apple/releases). The frameworks are attached to each release as a zipped file. This can be downloaded, unzipped and included in you project directory.

Once included, go to your app's target **General** settings and add the raygun4apple framework to the **Frameworks, Libraries, and Embedded Content** section. Ensure that the framework is set to **Embed & Sign**.

## Configuring the Raygun client

In your AppDelegate class file, import the header for your target platform.

```objective-c
#import <raygun4apple/raygun4apple_iOS.h>
```

Initialize the Raygun client by adding the following snippet to your AppDelegate application:didFinishLaunchingWithOptions method:

```objective-c
[RaygunClient sharedInstanceWithApiKey:@"_INSERT_API_KEY_"];
[RaygunClient.sharedInstance enableCrashReporting];
[RaygunClient.sharedInstance enableRealUserMonitoring];
[RaygunClient.sharedInstance enableNetworkPerformanceMonitoring]; // Optional
```

## Sending a test error event

To ensure that the Raygun client is correctly configured, try sending a test crash report with the following snippet.

```objective-c
[RaygunClient.sharedInstance sendException:@"Raygun has been successfully integrated!"
                                withReason:@"A test crash report from Raygun"
                                  withTags:@[@"Test"]
                            withCustomData:@{@"TestMessage":@"Hello World!"}];
```

## Set up Customers

By default, each user will be identified as an anonymous user/customers. However you can set more detailed customer information with the following snippet.

```objective-c
RaygunUserInformation *userInfo = nil;
userInfo = [[RaygunUserInformation alloc] initWithIdentifier:@"ronald@raygun.com"
                                                   withEmail:@"ronald@raygun.com"
                                                withFullName:@"Ronald Raygun"
                                               withFirstName:@"Ronald"];
RaygunClient.sharedInstance.userInformation = userInfo;
```

## Documentation

For more information please visit our public documentation [here](https://raygun.com/documentation/language-guides/apple/).
