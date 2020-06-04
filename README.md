# Raygun4Apple

The worlds best iOS, tvOS & macOS Crash Reporting and Real User Monitoring solution

Supports iOS 10+, tvOS 10+ & macOS 10.10+

## Installation

### With package installer

The latest version can be downloaded [here](https://downloads.raygun.com/Raygun4Apple/latest/raygun4apple.pkg). Once downloaded, run the installer and follow the on-screen instructions. The frameworks will be installed onto your localk machine under  *Library > Frameworks > raygun4apple*.

Once installed, go to your app's target **General** settings and add the raygun4apple framework to the **Frameworks, Libraries, and Embedded Content** section. Ensure that the framework is set to **Embed & Sign**.

### With GitHub releases

The latest release can be found [here](https://github.com/MindscapeHQ/raygun4apple/releases). The frameworks are attached to each release as a zipped file. This can be downloaded, unzipped and included in you project directory.

Once included, go to your app's target **General** settings and add the raygun4apple framework to the **Frameworks, Libraries, and Embedded Content** section. Ensure that the framework is set to **Embed & Sign**.

## Configuring the Raygun client

In your AppDelegate class file, import the header for your target platform.

```
#import <raygun4apple/raygun4apple_iOS.h>
```

Initialize the Raygun client by adding the following snippet to your AppDelegate application:didFinishLaunchingWithOptions method:

```
[RaygunClient sharedInstanceWithApiKey:@"_API_KEY_"];
[RaygunClient.sharedInstance enableCrashReporting];
[RaygunClient.sharedInstance enableRealUserMonitoring];
[RaygunClient.sharedInstance enableNetworkPerformanceMonitoring]; // Optional
```

## Sending a test error event

To ensure that the Raygun client is correctly configured, try sending a test crash report with the following snippet.

```
[RaygunClient.sharedInstance sendException:@"Raygun has been successfully integrated!"
                                withReason:@"A test crash report from Raygun"
                                  withTags:@[@"Test"]
                            withCustomData:@{@"TestMessage":@"Hello World!"}];
```

## Set up unique user tracking

By default, each user will be identified as an anonymous user. However you can set more detailed user information with the following snippet.

```
RaygunUserInformation *userInfo = nil;
userInfo = [[RaygunUserInformation alloc] initWithIdentifier:@"ronald@raygun.com"
                                                   withEmail:@"ronald@raygun.com"
                                                withFullName:@"Ronald Raygun"
                                               withFirstName:@"Ronald"];
RaygunClient.sharedInstance.userInformation = userInfo;
```

## Documentation

For more information please visit our public documentation [here](https://raygun.com/documentation/language-guides/apple/).
