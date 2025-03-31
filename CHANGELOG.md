# Changelog

## 2.1.3

- Don't add window sizing in background threads by
- Restore header visibility

## 2.1.2

- Adds include for missing ucontext64_t type

## 2.1.1

- Includes exception explicitly

## 2.0.1

- Falls back to thread stack trace if nil

## 2.0.0

- Creation of Package.swift file for the Swift package manager

## 1.5.1

- Adding missing static modifier for internal functions to avoid symbol collision with other libraries

## 1.5.0

- The API endpoint can now be configured through the Raygun client
- Fix: A bad access exception when logging response codes from the Raygun API

## 1.4.2

- Updated crash report property name for the stack trace
- Additional guards against the provider generating exceptions

## 1.4.1

- Prefixed KSCrash classes and methods to avoid conflicts with external sources
- The RaygunCrashReportConverter class is now public

## 1.4.0

- CocoaPods support
- New sample app projects
- Fix: UUID not being included by default for user/customer information

## 1.3.10

- Fix for anonymous user/customer information not being included in crash reports

## 1.3.9

- Additional guards against internal exceptions being thrown when setting custom data

## 1.3.8

- Additional guards against internal exceptions being thrown when logging information

## 1.3.7

- Fixed a crash within the internal crash reporter (KSCrash)

## 1.3.6

- Updated client API to explicitly state the types accepted. Signed frameworks and included simulator architectures

## 1.3.5

- Fresh rebuild without simulator architectures

## 1.3.4

- Fresh rebuild to resolve possible code signing issues

## 1.3.3

- Fresh rebuild to resolve possible code signing issues

## 1.3.2

- Removed code signing from all platforms

## 1.3.1

- Updated code signing to use distribution certificates. Lowered deployment targets to iOS 10 and tvOS 10

## 1.3.0

- Added macOS support and bug fixes affecting all platforms

## 1.2.1

- Minor bug fixes

## 1.2.0

- Added Swift support

## 1.1.0

- Added breadcrumb support

## 1.0.5

- Set the default number of stored reports allowed to 64 reports

## 1.0.4

- Store crash reports on the device when offline or when receiving a rate limited (429) status response

## 1.0.3

- Bitcode support for iOS & tvOS

## 1.0.2

- Minor bug fixes

## 1.0.1

- Minor bug fixes

## 1.0.0

- Initial release with basic functionality
