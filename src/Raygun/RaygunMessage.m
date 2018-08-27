//
//  RaygunMessage.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 11/09/17.
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

#import "RaygunMessage.h"

@implementation RaygunMessage

@synthesize occurredOn = _occurredOn;
@synthesize details    = _details;

- (id)init:(NSString *)occurredOn withDetails:(RaygunMessageDetails *)details {
    if ((self = [super init])) {
        self.occurredOn = occurredOn;
        self.details = details;
    }
    
    return self;
}

- (NSData *)convertToJson {
    NSMutableDictionary *report = [NSMutableDictionary dictionaryWithDictionary: @{ @"occurredOn": _occurredOn, @"details": [_details convertToDictionary] }];
    return [NSJSONSerialization dataWithJSONObject:report options:0 error:nil];
}

@end
