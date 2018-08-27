//
//  RaygunFrame.h
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

#ifndef RaygunFrame_h
#define RaygunFrame_h

#import <Foundation/Foundation.h>

@interface RaygunFrame : NSObject

@property(nonatomic, readwrite, copy) NSNumber *symbolAddress;
@property(nonatomic, readwrite, copy) NSNumber *instructionAddress;
@property(nonatomic, readwrite, copy) NSString *symbolName;

- (id)init;

/**
 Creates and returns a dictionary with the frame properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the frame properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunFrame_h */
