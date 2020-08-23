//
//  KSCrashMonitor.c
//
//  Created by Karl Stenerud on 2012-02-12.
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


#include "Raygun_KSCrashMonitor.h"
#include "Raygun_KSCrashMonitorContext.h"
#include "Raygun_KSCrashMonitorType.h"

#include "Raygun_KSCrashMonitor_Deadlock.h"
#include "Raygun_KSCrashMonitor_MachException.h"
#include "Raygun_KSCrashMonitor_CPPException.h"
#include "Raygun_KSCrashMonitor_NSException.h"
#include "Raygun_KSCrashMonitor_Signal.h"
#include "Raygun_KSCrashMonitor_System.h"
#include "Raygun_KSCrashMonitor_User.h"
#include "Raygun_KSCrashMonitor_AppState.h"
#include "Raygun_KSCrashMonitor_Zombie.h"
#include "Raygun_KSDebug.h"
#include "Raygun_KSThread.h"
#include "Raygun_KSSystemCapabilities.h"

#include <memory.h>

//#define Raygun_KSLogger_LocalLevel TRACE
#include "Raygun_KSLogger.h"


// ============================================================================
#pragma mark - Globals -
// ============================================================================

typedef struct
{
    Raygun_KSCrashMonitorType monitorType;
    Raygun_KSCrashMonitorAPI* (*getAPI)(void);
} Monitor;

static Monitor g_monitors[] =
{
#if RAYGUN_KSCRASH_HAS_MACH
    {
        .monitorType = Raygun_KSCrashMonitorTypeMachException,
        .getAPI = raygun_kscm_machexception_getAPI,
    },
#endif
#if RAYGUN_KSCRASH_HAS_SIGNAL
    {
        .monitorType = Raygun_KSCrashMonitorTypeSignal,
        .getAPI = raygun_kscm_signal_getAPI,
    },
#endif
#if RAYGUN_KSCRASH_HAS_OBJC
    {
        .monitorType = Raygun_KSCrashMonitorTypeNSException,
        .getAPI = raygun_kscm_nsexception_getAPI,
    },
    {
        .monitorType = Raygun_KSCrashMonitorTypeMainThreadDeadlock,
        .getAPI = raygun_kscm_deadlock_getAPI,
    },
    {
        .monitorType = Raygun_KSCrashMonitorTypeZombie,
        .getAPI = raygun_kscm_zombie_getAPI,
    },
#endif
    {
        .monitorType = Raygun_KSCrashMonitorTypeCPPException,
        .getAPI = raygun_kscm_cppexception_getAPI,
    },
    {
        .monitorType = Raygun_KSCrashMonitorTypeUserReported,
        .getAPI = raygun_kscm_user_getAPI,
    },
    {
        .monitorType = Raygun_KSCrashMonitorTypeSystem,
        .getAPI = raygun_kscm_system_getAPI,
    },
    {
        .monitorType = Raygun_KSCrashMonitorTypeApplicationState,
        .getAPI = raygun_kscm_appstate_getAPI,
    },
};
static int g_monitorsCount = sizeof(g_monitors) / sizeof(*g_monitors);

static Raygun_KSCrashMonitorType g_activeMonitors = Raygun_KSCrashMonitorTypeNone;

static bool g_handlingFatalException = false;
static bool g_crashedDuringExceptionHandling = false;
static bool g_requiresAsyncSafety = false;

static void (*g_onExceptionEvent)(struct Raygun_KSCrash_MonitorContext* monitorContext);

// ============================================================================
#pragma mark - API -
// ============================================================================

static inline Raygun_KSCrashMonitorAPI* getAPI(Monitor* monitor)
{
    if(monitor != NULL && monitor->getAPI != NULL)
    {
        return monitor->getAPI();
    }
    return NULL;
}

static inline void setMonitorEnabled(Monitor* monitor, bool isEnabled)
{
    Raygun_KSCrashMonitorAPI* api = getAPI(monitor);
    if(api != NULL && api->setEnabled != NULL)
    {
        api->setEnabled(isEnabled);
    }
}

static inline bool isMonitorEnabled(Monitor* monitor)
{
    Raygun_KSCrashMonitorAPI* api = getAPI(monitor);
    if(api != NULL && api->isEnabled != NULL)
    {
        return api->isEnabled();
    }
    return false;
}

static inline void addContextualInfoToEvent(Monitor* monitor, struct Raygun_KSCrash_MonitorContext* eventContext)
{
    Raygun_KSCrashMonitorAPI* api = getAPI(monitor);
    if(api != NULL && api->addContextualInfoToEvent != NULL)
    {
        api->addContextualInfoToEvent(eventContext);
    }
}

void raygun_kscm_setEventCallback(void (*onEvent)(struct Raygun_KSCrash_MonitorContext* monitorContext))
{
    g_onExceptionEvent = onEvent;
}

void raygun_kscm_setActiveMonitors(Raygun_KSCrashMonitorType monitorTypes)
{
    if(raygun_ksdebug_isBeingTraced() && (monitorTypes & Raygun_KSCrashMonitorTypeDebuggerUnsafe))
    {
        static bool hasWarned = false;
        if(!hasWarned)
        {
            hasWarned = true;
            RAYGUN_KSLOGBASIC_WARN("    ************************ Crash Handler Notice ************************");
            RAYGUN_KSLOGBASIC_WARN("    *     App is running in a debugger. Masking out unsafe monitors.     *");
            RAYGUN_KSLOGBASIC_WARN("    * This means that most crashes WILL NOT BE RECORDED while debugging! *");
            RAYGUN_KSLOGBASIC_WARN("    **********************************************************************");
        }
        monitorTypes &= Raygun_KSCrashMonitorTypeDebuggerSafe;
    }
    if(g_requiresAsyncSafety && (monitorTypes & Raygun_KSCrashMonitorTypeAsyncUnsafe))
    {
        RAYGUN_KSLOG_DEBUG("Async-safe environment detected. Masking out unsafe monitors.");
        monitorTypes &= Raygun_KSCrashMonitorTypeAsyncSafe;
    }

    RAYGUN_KSLOG_DEBUG("Changing active monitors from 0x%x tp 0x%x.", g_activeMonitors, monitorTypes);

    Raygun_KSCrashMonitorType activeMonitors = Raygun_KSCrashMonitorTypeNone;
    for(int i = 0; i < g_monitorsCount; i++)
    {
        Monitor* monitor = &g_monitors[i];
        bool isEnabled = monitor->monitorType & monitorTypes;
        setMonitorEnabled(monitor, isEnabled);
        if(isMonitorEnabled(monitor))
        {
            activeMonitors |= monitor->monitorType;
        }
        else
        {
            activeMonitors &= ~monitor->monitorType;
        }
    }

    RAYGUN_KSLOG_DEBUG("Active monitors are now 0x%x.", activeMonitors);
    g_activeMonitors = activeMonitors;
}

Raygun_KSCrashMonitorType raygun_kscm_getActiveMonitors()
{
    return g_activeMonitors;
}


// ============================================================================
#pragma mark - Private API -
// ============================================================================

bool raygun_kscm_notifyFatalExceptionCaptured(bool isAsyncSafeEnvironment)
{
    g_requiresAsyncSafety |= isAsyncSafeEnvironment; // Don't let it be unset.
    if(g_handlingFatalException)
    {
        g_crashedDuringExceptionHandling = true;
    }
    g_handlingFatalException = true;
    if(g_crashedDuringExceptionHandling)
    {
        RAYGUN_KSLOG_INFO("Detected crash in the crash reporter. Uninstalling KSCrash.");
        raygun_kscm_setActiveMonitors(Raygun_KSCrashMonitorTypeNone);
    }
    return g_crashedDuringExceptionHandling;
}

void raygun_kscm_handleException(struct Raygun_KSCrash_MonitorContext* context)
{
    context->requiresAsyncSafety = g_requiresAsyncSafety;
    if(g_crashedDuringExceptionHandling)
    {
        context->crashedDuringCrashHandling = true;
    }
    for(int i = 0; i < g_monitorsCount; i++)
    {
        Monitor* monitor = &g_monitors[i];
        if(isMonitorEnabled(monitor))
        {
            addContextualInfoToEvent(monitor, context);
        }
    }

    g_onExceptionEvent(context);

    if (context->currentSnapshotUserReported) {
        g_handlingFatalException = false;
    } else {
        if(g_handlingFatalException && !g_crashedDuringExceptionHandling) {
            RAYGUN_KSLOG_DEBUG("Exception is fatal. Restoring original handlers.");
            raygun_kscm_setActiveMonitors(Raygun_KSCrashMonitorTypeNone);
        }
    }
}
