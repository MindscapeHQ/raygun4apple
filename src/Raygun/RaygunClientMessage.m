//
//  RaygunClientMessage.m
//  raygun4apple
//
//  Created by Mitchell Duncan on 11/09/17.
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

#import "RaygunClientMessage.h"

@implementation RaygunClientMessage

@synthesize name = _name;
@synthesize version = _version;
@synthesize clientUrl = _clientUrl;

- (id)init:(NSString *)name withVersion:(NSString *)version withUrl:(NSString *)url {
    if ((self = [super init])) {
        self.name = name;
        self.version = version;
        self.clientUrl = url;
    }
    
    return self;
}

-(NSDictionary *)convertToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if (_name) {
        dict[@"name"] = _name;
    }
    
    if (_version) {
        dict[@"version"] = _version;
    }
    
    if (_clientUrl) {
        dict[@"clientUrl"] = _clientUrl;
    }
    
    return dict;
}

@end
