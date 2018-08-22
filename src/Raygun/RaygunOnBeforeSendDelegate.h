//
//  RaygunOnBeforeSendDelegate.h
//  raygun4apple
//
//  Created by Mitchell Duncan on 17/08/18.
//

#ifndef RaygunOnBeforeSendDelegate_h
#define RaygunOnBeforeSendDelegate_h

@protocol RaygunOnBeforeSendDelegate
/**
 A protocol to receive a callback before a crash report is sent to Raygun.
 The message can then be inspected and modified as needed before being sent.
 
 @param message The crash report to be sent to Raygun.
 
 @return Yes to send the message or NO to cancel sending the message.
 */
- (bool)onBeforeSend:(RaygunMessage *)message;
@end

#endif /* RaygunOnBeforeSendDelegate_h */
