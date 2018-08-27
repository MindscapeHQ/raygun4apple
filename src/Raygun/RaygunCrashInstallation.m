//
//  RaygunCrashInstallation.m
//  raygun4apple
//
//  Created by raygundev on 7/31/18.
//  Copyright © 2018 Raygun. All rights reserved.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "RaygunCrashInstallation.h"
#import "RaygunCrashReportSink.h"

#import "KSCrash.h"
#import "KSCrashInstallation+Private.h"

@implementation RaygunCrashInstallation

- (id)init {
    return [super initWithRequiredProperties:[NSArray new]];
}

- (id<KSCrashReportFilter>)sink {
    return [[RaygunCrashReportSink alloc] init];
}

- (void)sendAllReports {
    [self sendAllReportsWithCompletion:nil];
}

- (void)sendAllReportsWithCompletion:(KSCrashReportFilterCompletion)onCompletion {
    [super sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if (error != nil) {
            NSLog(@"Error sending: %@", [error localizedDescription]);
        }
        NSLog(@"%@", [NSString stringWithFormat:@"Sent %lu crash report(s)", (unsigned long)filteredReports.count]);
        if (completed && onCompletion) {
            onCompletion(filteredReports, completed, error);
        }
    }];
}

- (void)sendAllReportsWithSink:(id<KSCrashReportFilter>)sink {
    [self sendAllReportsWithSink:sink withCompletion:nil];
}

- (void)sendAllReportsWithSink:(id<KSCrashReportFilter>)sink withCompletion:(KSCrashReportFilterCompletion)onCompletion {
    [super sendAllReportsWithSink:sink withCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
        if (error != nil) {
            NSLog(@"Error sending: %@", [error localizedDescription]);
        }
        NSLog(@"%@", [NSString stringWithFormat:@"Sent %lu crash report(s)", (unsigned long)filteredReports.count]);
        if (completed && onCompletion) {
            onCompletion(filteredReports, completed, error);
        }
    }];
}

@end
