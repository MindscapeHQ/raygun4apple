//
//  KSCrashMonitorType.h
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#ifndef RAYGUN_HDR_KSCrashMonitorType_h
#define RAYGUN_HDR_KSCrashMonitorType_h

#ifdef __cplusplus
extern "C" {
#endif


/** Various aspects of the system that can be monitored:
 * - Mach kernel exception
 * - Fatal signal
 * - Uncaught C++ exception
 * - Uncaught Objective-C NSException
 * - Deadlock on the main thread
 * - User reported custom exception
 */
typedef enum
{
    /* Captures and reports Mach exceptions. */
    Raygun_KSCrashMonitorTypeMachException      = 0x01,
    
    /* Captures and reports POSIX signals. */
    Raygun_KSCrashMonitorTypeSignal             = 0x02,
    
    /* Captures and reports C++ exceptions.
     * Note: This will slightly slow down exception processing.
     */
    Raygun_KSCrashMonitorTypeCPPException       = 0x04,
    
    /* Captures and reports NSExceptions. */
    Raygun_KSCrashMonitorTypeNSException        = 0x08,
    
    /* Detects and reports a deadlock in the main thread. */
    Raygun_KSCrashMonitorTypeMainThreadDeadlock = 0x10,
    
    /* Accepts and reports user-generated exceptions. */
    Raygun_KSCrashMonitorTypeUserReported       = 0x20,
    
    /* Keeps track of and injects system information. */
    Raygun_KSCrashMonitorTypeSystem             = 0x40,
    
    /* Keeps track of and injects application state. */
    Raygun_KSCrashMonitorTypeApplicationState   = 0x80,
    
    /* Keeps track of zombies, and injects the last zombie NSException. */
    Raygun_KSCrashMonitorTypeZombie             = 0x100,
} Raygun_KSCrashMonitorType;

#define Raygun_KSCrashMonitorTypeAll              \
(                                                 \
    Raygun_KSCrashMonitorTypeMachException      | \
    Raygun_KSCrashMonitorTypeSignal             | \
    Raygun_KSCrashMonitorTypeCPPException       | \
    Raygun_KSCrashMonitorTypeNSException        | \
    Raygun_KSCrashMonitorTypeMainThreadDeadlock | \
    Raygun_KSCrashMonitorTypeUserReported       | \
    Raygun_KSCrashMonitorTypeSystem             | \
    Raygun_KSCrashMonitorTypeApplicationState   | \
    Raygun_KSCrashMonitorTypeZombie               \
)

#define Raygun_KSCrashMonitorTypeExperimental     \
(                                                 \
    Raygun_KSCrashMonitorTypeMainThreadDeadlock   \
)

#define Raygun_KSCrashMonitorTypeDebuggerUnsafe   \
(                                                 \
    Raygun_KSCrashMonitorTypeMachException      | \
    Raygun_KSCrashMonitorTypeSignal             | \
    Raygun_KSCrashMonitorTypeCPPException       | \
    Raygun_KSCrashMonitorTypeNSException          \
)

#define Raygun_KSCrashMonitorTypeAsyncSafe        \
(                                                 \
    Raygun_KSCrashMonitorTypeMachException      | \
    Raygun_KSCrashMonitorTypeSignal               \
)

#define Raygun_KSCrashMonitorTypeOptional         \
(                                                 \
    Raygun_KSCrashMonitorTypeZombie               \
)
    
#define Raygun_KSCrashMonitorTypeAsyncUnsafe (Raygun_KSCrashMonitorTypeAll & (~Raygun_KSCrashMonitorTypeAsyncSafe))

/** Monitors that are safe to enable in a debugger. */
#define Raygun_KSCrashMonitorTypeDebuggerSafe (Raygun_KSCrashMonitorTypeAll & (~Raygun_KSCrashMonitorTypeDebuggerUnsafe))

/** Monitors that are safe to use in a production environment.
 * All other monitors should be considered experimental.
 */
#define Raygun_KSCrashMonitorTypeProductionSafe (Raygun_KSCrashMonitorTypeAll & (~Raygun_KSCrashMonitorTypeExperimental))

/** Production safe monitors, minus the optional ones. */
#define Raygun_KSCrashMonitorTypeProductionSafeMinimal (Raygun_KSCrashMonitorTypeProductionSafe & (~Raygun_KSCrashMonitorTypeOptional))

/** Monitors that are required for proper operation.
 * These add essential information to the reports, but do not trigger reporting.
 */
#define Raygun_KSCrashMonitorTypeRequired (Raygun_KSCrashMonitorTypeSystem | Raygun_KSCrashMonitorTypeApplicationState)

/** Effectively disables automatica reporting. The only way to generate a report
 * in this mode is by manually calling kscrash_reportUserException().
 */
#define Raygun_KSCrashMonitorTypeManual (Raygun_KSCrashMonitorTypeRequired | Raygun_KSCrashMonitorTypeUserReported)

#define Raygun_KSCrashMonitorTypeNone 0

const char* raygun_kscrashmonitortype_name(Raygun_KSCrashMonitorType monitorType);


#ifdef __cplusplus
}
#endif

#endif // HDR_KSCrashMonitorType_h
