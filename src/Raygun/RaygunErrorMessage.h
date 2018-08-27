//
//  RaygunErrorMessage.h
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

#ifndef RaygunErrorMessage_h
#define RaygunErrorMessage_h

#import <Foundation/Foundation.h>

@interface RaygunErrorMessage : NSObject

@property (nonatomic, readwrite, copy) NSString *className;
@property (nonatomic, readwrite, copy) NSString *message;
@property (nonatomic, readwrite, copy) NSString *signalName;
@property (nonatomic, readwrite, copy) NSString *signalCode;
@property (nonatomic, readwrite, strong) NSArray *stackTrace;

-(id) init:(NSString *)className withMessage:(NSString *)message
                              withSignalName:(NSString *)signalName
                              withSignalCode:(NSString *)signalCode
                              withStackTrace:(NSArray *)stacktrace;

/**
 Creates and returns a dictionary with the classes properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the classes properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunErrorMessage_h */
