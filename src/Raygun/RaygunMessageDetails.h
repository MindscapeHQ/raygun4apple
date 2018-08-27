//
//  RaygunMessageDetails.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 11/09/17.
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

#ifndef RaygunMessageDetails_h
#define RaygunMessageDetails_h

#import "RaygunClientMessage.h"
#import "RaygunEnvironmentMessage.h"
#import "RaygunErrorMessage.h"
#import "RaygunUserInformation.h"
#import "RaygunThread.h"
#import "RaygunBinaryImage.h"

@interface RaygunMessageDetails : NSObject

@property (nonatomic, readwrite, copy) NSString *groupingKey;
@property (nonatomic, readwrite, copy) NSString *machineName;
@property (nonatomic, readwrite, copy) NSString *version;
@property (nonatomic, readwrite, strong) RaygunClientMessage *client;
@property (nonatomic, readwrite, strong) RaygunEnvironmentMessage *environment;
@property (nonatomic, readwrite, strong) RaygunErrorMessage *error;
@property (nonatomic, readwrite, strong) RaygunUserInformation *user;
@property (nonatomic, readwrite, strong) NSArray *tags;
@property (nonatomic, readwrite, strong) NSDictionary *customData;
@property (nonatomic, strong) NSArray<RaygunThread *> *threads;
@property (nonatomic, strong) NSArray<RaygunBinaryImage *> *binaryImages;

/**
 Creates and returns a dictionary with the classes properties and their values.
 Used when constructing the crash report that is sent to Raygun.
 
 @return a new Dictionary with the classes properties and their values.
 */
-(NSDictionary *)convertToDictionary;

@end

#endif /* RaygunMessageDetails_h */

