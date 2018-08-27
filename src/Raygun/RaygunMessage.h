//
//  RaygunMessage.h
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

#ifndef RaygunMessage_h
#define RaygunMessage_h

#import "RaygunMessageDetails.h"

@interface RaygunMessage : NSObject

@property (nonatomic, readwrite, copy) NSString *occurredOn;
@property (nonatomic, readwrite, strong) RaygunMessageDetails *details;

- (id)init:(NSString *)occurredOn withDetails:(RaygunMessageDetails *)details;

/**
 Creates and returns the json payload to be sent to Raygun.
 
 @return a data object containing the RaygunMessage properties in a json format.
 */
- (NSData *)convertToJson;

@end

#endif /* RaygunMessage_h */
