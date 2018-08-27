//
//  RaygunBinaryImage.m
//  raygun4apple
//
//  Created by raygundev on 8/3/18.
//  Copyright © 2018 Raygun Limited. All rights reserved.
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
#import "RaygunBinaryImage.h"

@implementation RaygunBinaryImage

- (id)initWithUuId:(NSString *)uuid
          withName:(NSString *)name
       withCpuType:(NSNumber *)cpuType
    withCpuSubType:(NSNumber *)cpuSubType
  withImageAddress:(NSNumber *)imageAddress
     withImageSize:(NSNumber *)imageSize
{
    if ((self = [super init])) {
        self.uuid = uuid;
        self.name = name;
        self.cpuType = cpuType;
        self.cpuSubtype = cpuSubType;
        self.imageAddress = imageAddress;
        self.imageSize= imageSize;
    }
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    dict[@"processor"] = [NSMutableDictionary new];
    
    if (self.uuid) {
        dict[@"uuid"] = self.uuid;
    }
    if (self.name) {
        dict[@"name"] = self.name;
    }
    if (self.cpuType) {
        dict[@"processor"][@"type"] = self.cpuType;
    }
    if (self.cpuSubtype) {
        dict[@"processor"][@"subType"] = self.cpuSubtype;
    }
    if (self.imageAddress) {
        dict[@"baseAddress"] = self.imageAddress;
    }
    if (self.imageSize) {
        dict[@"size"] = self.imageSize;
    }
    
    return dict;
}

@end
