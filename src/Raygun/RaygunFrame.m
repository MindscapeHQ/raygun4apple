//
//  RaygunFrame.m
//  raygun4apple
//
//  Created by raygundev on 8/2/18.
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

#import "RaygunFrame.h"

@implementation RaygunFrame

-(id)init {
    self = [super init];
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    dict[@"symbol"] = [NSMutableDictionary new];
    
    if (self.symbolName) {
        dict[@"symbol"][@"name"] = self.symbolName;
    }
    if (self.symbolAddress) {
        dict[@"symbol"][@"startAddress"] = self.symbolAddress;
    }
    if (self.instructionAddress) {
        dict[@"programCounter"] = self.instructionAddress;
    }
    
    return dict;
}

@end
