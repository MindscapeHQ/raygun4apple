//
//  RaygunThread.h
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

#ifndef RaygunThread_h
#define RaygunThread_h

#import <Foundation/Foundation.h>
#import "RaygunFrame.h"

@interface RaygunThread : NSObject

@property(nonatomic, readwrite, copy) NSNumber *threadIndex;
@property(nonatomic, readwrite, copy) NSString *name;
@property(nonatomic, strong) NSArray<RaygunFrame *> *frames;
@property(nonatomic, readwrite) BOOL crashed;
@property(nonatomic, readwrite) BOOL current;

/**
 * Initializes a RaygunThread with its index

 * @return RaygunThread
 */
- (id)init:(NSNumber *)threadIndex;

/**
 Creates and returns a dictionary with the thread properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the thread properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunThread_h */
