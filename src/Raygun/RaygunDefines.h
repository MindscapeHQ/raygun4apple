//
//  RaygunDefines.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 27/08/18.
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

#ifndef RaygunDefines_h
#define RaygunDefines_h

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS || TARGET_OS_TV
#define RAYGUN_CAN_USE_UIDEVICE 1
#else
#define RAYGUN_CAN_USE_UIDEVICE 0
#endif

#if RAYGUN_CAN_USE_UIDEVICE
#define RAYGUN_CAN_USE_UIKIT 1
#else
#define RAYGUN_CAN_USE_UIKIT 0
#endif

@class RaygunMessage;

/**
 * Block can be used to modify the crash report before it is sent to Raygun.
 */
typedef BOOL (^RaygunBeforeSendMessage)(RaygunMessage *message);

typedef enum {
    ViewLoaded,
    NetworkCall
} RaygunEventType;

#endif /* RaygunDefines_h */

