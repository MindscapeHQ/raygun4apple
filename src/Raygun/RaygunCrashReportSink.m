//
//  RaygunCrashReportSink.m
//  raygun4apple
//
//  Created by raygundev on 7/31/18.
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

#import "RaygunCrashReportSink.h"

#import "KSCrash.h"
#import "RaygunClient.h"
#import "RaygunMessage.h"
#import "RaygunCrashReportConverter.h"

@implementation RaygunCrashReportSink

- (void) filterReports:(NSArray *)reports onCompletion:(KSCrashReportFilterCompletion)onCompletion {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSMutableArray *sentReports = [NSMutableArray new];
        RaygunCrashReportConverter *converter = [[RaygunCrashReportConverter alloc] init];
        for (NSDictionary *report in reports) {
            if (nil != RaygunClient.sharedClient) {
                // Take the information from the KSCrash report and put it into our own format.
                RaygunMessage *message = [converter convertReportToMessage:report];
                
                // Send it to the Raygun API endpoint
                [RaygunClient.sharedClient sendMessage:message];
                [sentReports addObject:report];
            }
        }
        if (onCompletion) {
            onCompletion(sentReports, TRUE, nil);
        }
    });
}

@end
