//
//  RaygunThread.m
//  raygun4apple
//
//  Created by raygundev on 8/2/18.
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

#import "RaygunThread.h"

@implementation RaygunThread

- (instancetype)init:(NSNumber *)threadIndex {
    self = [super init];
    if (self) {
        self.threadIndex = threadIndex;
    }
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                @"threadNumber":self.threadIndex,
                                                                                @"crashed":self.crashed?@YES:@NO,
                                                                                @"current":self.current?@YES:@NO
                                                                                }];
    
    if (self.name){
        dict[@"name"] = self.name;
    }
    
    NSMutableArray *frames = [NSMutableArray new];
    for (RaygunFrame *frame in self.frames) {
        NSDictionary *serialized = [frame convertToDictionary];
        if (serialized.allKeys.count > 0) {
            [frames addObject:serialized];
        }
    }
    dict[@"stackFrames"] = frames;
    
    return dict;
}

@end
