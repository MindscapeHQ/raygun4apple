//
//  RaygunClient.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 27/08/18.
//  Copyright © 2018 Mindscape. All rights reserved.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "RaygunDefines.h"

@class RaygunUserInformation, RaygunMessage;

@interface RaygunClient : NSObject

@property(nonatomic, readonly, copy) NSString *apiKey;
@property(nonatomic, readwrite, copy) NSString *applicationVersion;
@property(nonatomic, strong) NSArray *tags;
@property(nonatomic, strong) NSDictionary<NSString *, id> *customData;
@property(nonatomic, strong) RaygunUserInformation *userInformation;
@property(nonatomic, copy) RaygunBeforeSendMessage beforeSendMessage;

+ (id)sharedClient;
+ (id)sharedClientWithApiKey:(NSString *)apiKey;

- (id)initWithApiKey:(NSString *)apiKey;

// Crash Reporting

- (void)enableCrashReporting;
- (void)sendException:(NSException *)exception;
- (void)sendException:(NSException *)exception withTags:(NSArray *)tags;
- (void)sendException:(NSException *)exception withTags:(NSArray *)tags withCustomData:(NSDictionary *)customData;
- (void)sendException:(NSString *)exceptionName withReason:(NSString *)reason withTags:(NSArray *)tags withCustomData:(NSDictionary *)customData;
- (void)sendError:(NSError *)error withTags:(NSArray *)tags withCustomData:(NSDictionary *)customData;
- (void)sendMessage:(RaygunMessage *)message;
- (void)crash;

// Real User Monitoring (RUM)

- (void)enableRealUserMonitoring;
- (void)enableAutomaticNetworkLogging:(bool)networkLogging;
- (void)ignoreViews:(NSArray *)viewNames;
- (void)ignoreURLs:(NSArray *)urls;
- (void)sendTimingEvent:(RaygunEventType)eventType withName:(NSString *)name withDuration:(int)milliseconds;

// Unique User Tracking

- (void)identifyWithIdentifier:(NSString *)identifier;
- (void)identifyWithUserInformation:(RaygunUserInformation *)userInformation;

@end
