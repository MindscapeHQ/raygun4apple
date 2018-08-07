//
//  RaygunCrashInstallation.h
//  raygun4apple
//
//  Created by raygundev on 7/31/18.
//

#import <Foundation/Foundation.h>
#import "KSCrash.h"
#import "KSCrashInstallation.h"

@interface RaygunCrashInstallation : KSCrashInstallation

- (void)sendAllReports;

@end
