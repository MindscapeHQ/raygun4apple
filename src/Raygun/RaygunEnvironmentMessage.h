//
//  RaygunEnvironmentMessage.h
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

#ifndef RaygunEnvironmentMessage_h
#define RaygunEnvironmentMessage_h

#import <Foundation/Foundation.h>

@interface RaygunEnvironmentMessage : NSObject

@property (nonatomic, readwrite, copy) NSNumber *processorCount;
@property (nonatomic, readwrite, copy) NSString *oSVersion;
@property (nonatomic, readwrite, copy) NSString *model;
@property (nonatomic, readwrite, copy) NSNumber *windowsBoundWidth;
@property (nonatomic, readwrite, copy) NSNumber *windowsBoundHeight;
@property (nonatomic, readwrite, copy) NSNumber *resolutionScale;
@property (nonatomic, readwrite, copy) NSString *cpu;
@property (nonatomic, readwrite, copy) NSNumber *utcOffset;
@property (nonatomic, readwrite, copy) NSString *locale;
@property (nonatomic, readwrite, copy) NSString *kernelVersion;
@property (nonatomic, readwrite, copy) NSNumber *memoryFree;
@property (nonatomic, readwrite, copy) NSNumber *memorySize;
@property (nonatomic, readwrite) BOOL jailBroken;

/**
 Creates and returns a dictionary with the classes properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the classes properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunEnvironmentMessage_h */
