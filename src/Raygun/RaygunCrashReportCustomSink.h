//
//  RaygunCrashReportCustomSink.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 24/08/18.
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

#ifndef RaygunCrashReportCustomSink_h
#define RaygunCrashReportCustomSink_h

#import <Foundation/Foundation.h>
#import "KSCrash.h"

@interface RaygunCrashReportCustomSink : NSObject <KSCrashReportFilter>

-(id)initWithTags:(NSArray *)tags withCustomData:(NSDictionary *)customData;

@end

#endif /* RaygunCrashReportCustomSink_h */
