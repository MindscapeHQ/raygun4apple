//
//  RaygunNetworkLogger.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 17/10/16.
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

#ifndef Raygun4iOS_RaygunNetworkLogger_h
#define Raygun4iOS_RaygunNetworkLogger_h

@interface RaygunNetworkLogger : NSObject

- (void)setEnabled:(bool)enabled;
- (void)ignoreURLs:(NSArray *)urls;

@end

@interface RaygunSessionTaskDelegate: NSObject

@end

#endif
