//
//  KSCrashC.c
//
//  Created by Karl Stenerud on 2012-01-28.
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


#include "Raygun_KSCrashC.h"

#include "Raygun_KSCrashCachedData.h"
#include "Raygun_KSCrashReport.h"
#include "Raygun_KSCrashReportFixer.h"
#include "Raygun_KSCrashReportStore.h"
#include "Raygun_KSCrashMonitor_Deadlock.h"
#include "Raygun_KSCrashMonitor_User.h"
#include "Raygun_KSFileUtils.h"
#include "Raygun_KSObjC.h"
#include "Raygun_KSString.h"
#include "Raygun_KSCrashMonitor_System.h"
#include "Raygun_KSCrashMonitor_Zombie.h"
#include "Raygun_KSCrashMonitor_AppState.h"
#include "Raygun_KSCrashMonitorContext.h"
#include "Raygun_KSSystemCapabilities.h"

//#define Raygun_KSLogger_LocalLevel TRACE
#include "Raygun_KSLogger.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


// ============================================================================
#pragma mark - Globals -
// ============================================================================

/** True if KSCrash has been installed. */
static volatile bool g_installed = 0;

static bool g_shouldAddConsoleLogToReport = false;
static bool g_shouldPrintPreviousLog = false;
static char g_consoleLogPath[RAYGUN_KSFU_MAX_PATH_LENGTH];
static Raygun_KSCrashMonitorType g_monitoring = Raygun_KSCrashMonitorTypeProductionSafeMinimal;
static char g_lastCrashReportFilePath[RAYGUN_KSFU_MAX_PATH_LENGTH];


// ============================================================================
#pragma mark - Utility -
// ============================================================================

static void printPreviousLog(const char* filePath)
{
    char* data;
    int length;
    if(raygun_ksfu_readEntireFile(filePath, &data, &length, 0))
    {
        printf("\nvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv Previous Log vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n\n");
        printf("%s\n", data);
        printf("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n\n");
        fflush(stdout);
    }
}


// ============================================================================
#pragma mark - Callbacks -
// ============================================================================

/** Called when a crash occurs.
 *
 * This function gets passed as a callback to a crash handler.
 */
static void onCrash(struct Raygun_KSCrash_MonitorContext* monitorContext)
{
    if (monitorContext->currentSnapshotUserReported == false) {
        RAYGUN_KSLOG_DEBUG("Updating application state to note crash.");
        raygun_kscrashstate_notifyAppCrash();
    }
    monitorContext->consoleLogPath = g_shouldAddConsoleLogToReport ? g_consoleLogPath : NULL;

    if(monitorContext->crashedDuringCrashHandling)
    {
        raygun_kscrashreport_writeRecrashReport(monitorContext, g_lastCrashReportFilePath);
    }
    else
    {
        char crashReportFilePath[RAYGUN_KSFU_MAX_PATH_LENGTH];
        raygun_kscrs_getNextCrashReportPath(crashReportFilePath);
        strncpy(g_lastCrashReportFilePath, crashReportFilePath, sizeof(g_lastCrashReportFilePath));
        raygun_kscrashreport_writeStandardReport(monitorContext, crashReportFilePath);
    }
}


// ============================================================================
#pragma mark - API -
// ============================================================================

Raygun_KSCrashMonitorType raygun_kscrash_install(const char* appName, const char* const installPath)
{
    RAYGUN_KSLOG_DEBUG("Installing crash reporter.");

    if(g_installed)
    {
        RAYGUN_KSLOG_DEBUG("Crash reporter already installed.");
        return g_monitoring;
    }
    g_installed = 1;

    char path[RAYGUN_KSFU_MAX_PATH_LENGTH];
    snprintf(path, sizeof(path), "%s/Reports", installPath);
    raygun_ksfu_makePath(path);
    raygun_kscrs_initialize(appName, path);

    snprintf(path, sizeof(path), "%s/Data", installPath);
    raygun_ksfu_makePath(path);
    snprintf(path, sizeof(path), "%s/Data/CrashState.json", installPath);
    raygun_kscrashstate_initialize(path);

    snprintf(g_consoleLogPath, sizeof(g_consoleLogPath), "%s/Data/ConsoleLog.txt", installPath);
    if(g_shouldPrintPreviousLog)
    {
        printPreviousLog(g_consoleLogPath);
    }
    raygun_kslog_setLogFilename(g_consoleLogPath, true);
    
    raygun_ksccd_init(60);

    raygun_kscm_setEventCallback(onCrash);
    Raygun_KSCrashMonitorType monitors = raygun_kscrash_setMonitoring(g_monitoring);

    RAYGUN_KSLOG_DEBUG("Installation complete.");
    return monitors;
}

Raygun_KSCrashMonitorType raygun_kscrash_setMonitoring(Raygun_KSCrashMonitorType monitors)
{
    g_monitoring = monitors;
    
    if(g_installed)
    {
        raygun_kscm_setActiveMonitors(monitors);
        return raygun_kscm_getActiveMonitors();
    }
    // Return what we will be monitoring in future.
    return g_monitoring;
}

void raygun_kscrash_setUserInfoJSON(const char* const userInfoJSON)
{
    raygun_kscrashreport_setUserInfoJSON(userInfoJSON);
}

void raygun_kscrash_setDeadlockWatchdogInterval(double deadlockWatchdogInterval)
{
#if RAYGUN_KSCRASH_HAS_OBJC
    raygun_kscm_setDeadlockHandlerWatchdogInterval(deadlockWatchdogInterval);
#endif
}

void raygun_kscrash_setIntrospectMemory(bool introspectMemory)
{
    raygun_kscrashreport_setIntrospectMemory(introspectMemory);
}

void raygun_kscrash_setDoNotIntrospectClasses(const char** doNotIntrospectClasses, int length)
{
    raygun_kscrashreport_setDoNotIntrospectClasses(doNotIntrospectClasses, length);
}

void raygun_kscrash_setCrashNotifyCallback(const Raygun_KSReportWriteCallback onCrashNotify)
{
    raygun_kscrashreport_setUserSectionWriteCallback(onCrashNotify);
}

void raygun_kscrash_setAddConsoleLogToReport(bool shouldAddConsoleLogToReport)
{
    g_shouldAddConsoleLogToReport = shouldAddConsoleLogToReport;
}

void raygun_kscrash_setPrintPreviousLog(bool shouldPrintPreviousLog)
{
    g_shouldPrintPreviousLog = shouldPrintPreviousLog;
}

void raygun_kscrash_setMaxReportCount(int maxReportCount)
{
    raygun_kscrs_setMaxReportCount(maxReportCount);
}

void raygun_kscrash_reportUserException(const char* name,
                                 const char* reason,
                                 const char* language,
                                 const char* lineOfCode,
                                 const char* stackTrace,
                                 bool logAllThreads,
                                 bool terminateProgram)
{
    raygun_kscm_reportUserException(name,
                             reason,
                             language,
                             lineOfCode,
                             stackTrace,
                             logAllThreads,
                             terminateProgram);
    if(g_shouldAddConsoleLogToReport)
    {
        raygun_kslog_clearLogFile();
    }
}

void raygun_kscrash_notifyAppActive(bool isActive)
{
    raygun_kscrashstate_notifyAppActive(isActive);
}

void raygun_kscrash_notifyAppInForeground(bool isInForeground)
{
    raygun_kscrashstate_notifyAppInForeground(isInForeground);
}

void raygun_kscrash_notifyAppTerminate(void)
{
    raygun_kscrashstate_notifyAppTerminate();
}

void raygun_kscrash_notifyAppCrash(void)
{
    raygun_kscrashstate_notifyAppCrash();
}

int raygun_kscrash_getReportCount()
{
    return raygun_kscrs_getReportCount();
}

int raygun_kscrash_getReportIDs(int64_t* reportIDs, int count)
{
    return raygun_kscrs_getReportIDs(reportIDs, count);
}

char* raygun_kscrash_readReport(int64_t reportID)
{
    if(reportID <= 0)
    {
        RAYGUN_KSLOG_ERROR("Report ID was %" PRIx64, reportID);
        return NULL;
    }

    char* rawReport = raygun_kscrs_readReport(reportID);
    if(rawReport == NULL)
    {
        RAYGUN_KSLOG_ERROR("Failed to load report ID %" PRIx64, reportID);
        return NULL;
    }

    char* fixedReport = raygun_kscrf_fixupCrashReport(rawReport);
    if(fixedReport == NULL)
    {
        RAYGUN_KSLOG_ERROR("Failed to fixup report ID %" PRIx64, reportID);
    }

    free(rawReport);
    return fixedReport;
}

int64_t raygun_kscrash_addUserReport(const char* report, int reportLength)
{
    return raygun_kscrs_addUserReport(report, reportLength);
}

void raygun_kscrash_deleteAllReports()
{
    raygun_kscrs_deleteAllReports();
}

void raygun_kscrash_deleteReportWithID(int64_t reportID)
{
    raygun_kscrs_deleteReportWithID(reportID);
}
