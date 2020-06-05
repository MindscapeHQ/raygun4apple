//
//  CrashGenerator.h
//  CrashGenerator iOS
//
//  Created by Mitchell Duncan on 15/04/19.
//

#ifndef CrashGenerator_h
#define CrashGenerator_h

/**
 Generates native errors for testing Raygun's Crash Reporting.
 
 ```objc
 import "CrashGenerator.h"
 ```
 */
@interface CrashGenerator : NSObject

/**
 Generates a NSException exception and raises it.
 
 ```objc
 import "CrashGenerator.h"
 ...
 
 [CrashGenerator throwGenericException];
 ```
 */
+ (void)throwGenericException;

@end


#endif /* CrashGenerator_h */
