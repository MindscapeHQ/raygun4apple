//
//  RaygunErrorFormatter.h
//  Raygun4iOS
//
//  Created by Martin on 27/09/13.
//
//

#import <Foundation/Foundation.h>
#import "RaygunMessage.h"

@interface RaygunErrorFormatter : NSObject

@property (nonatomic, readwrite) bool omitMachineName;

- (RaygunMessage *)formatCrashReport:(NSData *)crashReport withData:(NSData *)data withManagedErrorInfromation:(NSString *)managedErrorInformation;

@end
