//
//  KSCrashMonitor_User.c
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

#include "Raygun_KSCrashMonitor_User.h"
#include "Raygun_KSCrashMonitorContext.h"
#include "Raygun_KSID.h"
#include "Raygun_KSThread.h"
#include "Raygun_KSStackCursor_SelfThread.h"

//#define Raygun_KSLogger_LocalLevel TRACE
#include "Raygun_KSLogger.h"

#include <memory.h>
#include <stdlib.h>


/** Context to fill with crash information. */

static volatile bool g_isEnabled = false;


void raygun_kscm_reportUserException(const char* name,
                              const char* reason,
                              const char* language,
                              const char* lineOfCode,
                              const char* stackTrace,
                              bool logAllThreads,
                              bool terminateProgram)
{
    if(!g_isEnabled)
    {
        RAYGUN_KSLOG_WARN("User-reported exception monitor is not installed. Exception has not been recorded.");
    }
    else
    {
        if(logAllThreads)
        {
            raygun_ksmc_suspendEnvironment();
        }
        if(terminateProgram)
        {
            raygun_kscm_notifyFatalExceptionCaptured(false);
        }

        char eventID[37];
        raygun_ksid_generate(eventID);
        RAYGUN_KSMC_NEW_CONTEXT(machineContext);
        raygun_ksmc_getContextForThread(raygun_ksthread_self(), machineContext, true);
        Raygun_KSStackCursor stackCursor;
        raygun_kssc_initSelfThread(&stackCursor, 0);


        RAYGUN_KSLOG_DEBUG("Filling out context.");
        Raygun_KSCrash_MonitorContext context;
        memset(&context, 0, sizeof(context));
        context.crashType = Raygun_KSCrashMonitorTypeUserReported;
        context.eventID = eventID;
        context.offendingMachineContext = machineContext;
        context.registersAreValid = false;
        context.crashReason = reason;
        context.userException.name = name;
        context.userException.language = language;
        context.userException.lineOfCode = lineOfCode;
        context.userException.customStackTrace = stackTrace;
        context.stackCursor = &stackCursor;

        raygun_kscm_handleException(&context);

        if(logAllThreads)
        {
            raygun_ksmc_resumeEnvironment();
        }
        if(terminateProgram)
        {
            abort();
        }
    }
}

static void setEnabled(bool isEnabled)
{
    g_isEnabled = isEnabled;
}

static bool isEnabled()
{
    return g_isEnabled;
}

Raygun_KSCrashMonitorAPI* raygun_kscm_user_getAPI()
{
    static Raygun_KSCrashMonitorAPI api =
    {
        .setEnabled = setEnabled,
        .isEnabled = isEnabled
    };
    return &api;
}
