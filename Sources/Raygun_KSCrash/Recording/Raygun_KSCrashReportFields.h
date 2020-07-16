//
//  KSCrashReportFields.h
//
//  Created by Karl Stenerud on 2012-10-07.
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


#ifndef RAYGUN_HDR_KSCrashReportFields_h
#define RAYGUN_HDR_KSCrashReportFields_h


#pragma mark - Report Types -

#define Raygun_KSCrashReportType_Minimal          "minimal"
#define Raygun_KSCrashReportType_Standard         "standard"
#define Raygun_KSCrashReportType_Custom           "custom"


#pragma mark - Memory Types -

#define Raygun_KSCrashMemType_Block               "objc_block"
#define Raygun_KSCrashMemType_Class               "objc_class"
#define Raygun_KSCrashMemType_NullPointer         "null_pointer"
#define Raygun_KSCrashMemType_Object              "objc_object"
#define Raygun_KSCrashMemType_String              "string"
#define Raygun_KSCrashMemType_Unknown             "unknown"


#pragma mark - Exception Types -

#define Raygun_KSCrashExcType_CPPException        "cpp_exception"
#define Raygun_KSCrashExcType_Deadlock            "deadlock"
#define Raygun_KSCrashExcType_Mach                "mach"
#define Raygun_KSCrashExcType_NSException         "nsexception"
#define Raygun_KSCrashExcType_Signal              "signal"
#define Raygun_KSCrashExcType_User                "user"


#pragma mark - Common -

#define Raygun_KSCrashField_Address               "address"
#define Raygun_KSCrashField_Contents              "contents"
#define Raygun_KSCrashField_Exception             "exception"
#define Raygun_KSCrashField_FirstObject           "first_object"
#define Raygun_KSCrashField_Index                 "index"
#define Raygun_KSCrashField_Ivars                 "ivars"
#define Raygun_KSCrashField_Language              "language"
#define Raygun_KSCrashField_Name                  "name"
#define Raygun_KSCrashField_UserInfo              "userInfo"
#define Raygun_KSCrashField_ReferencedObject      "referenced_object"
#define Raygun_KSCrashField_Type                  "type"
#define Raygun_KSCrashField_UUID                  "uuid"
#define Raygun_KSCrashField_Value                 "value"

#define Raygun_KSCrashField_Error                 "error"
#define Raygun_KSCrashField_JSONData              "json_data"


#pragma mark - Notable Address -

#define Raygun_KSCrashField_Class                 "class"
#define Raygun_KSCrashField_LastDeallocObject     "last_deallocated_obj"


#pragma mark - Backtrace -

#define Raygun_KSCrashField_InstructionAddr       "instruction_addr"
#define Raygun_KSCrashField_LineOfCode            "line_of_code"
#define Raygun_KSCrashField_ObjectAddr            "object_addr"
#define Raygun_KSCrashField_ObjectName            "object_name"
#define Raygun_KSCrashField_SymbolAddr            "symbol_addr"
#define Raygun_KSCrashField_SymbolName            "symbol_name"


#pragma mark - Stack Dump -

#define Raygun_KSCrashField_DumpEnd               "dump_end"
#define Raygun_KSCrashField_DumpStart             "dump_start"
#define Raygun_KSCrashField_GrowDirection         "grow_direction"
#define Raygun_KSCrashField_Overflow              "overflow"
#define Raygun_KSCrashField_StackPtr              "stack_pointer"


#pragma mark - Thread Dump -

#define Raygun_KSCrashField_Backtrace             "backtrace"
#define Raygun_KSCrashField_Basic                 "basic"
#define Raygun_KSCrashField_Crashed               "crashed"
#define Raygun_KSCrashField_CurrentThread         "current_thread"
#define Raygun_KSCrashField_DispatchQueue         "dispatch_queue"
#define Raygun_KSCrashField_NotableAddresses      "notable_addresses"
#define Raygun_KSCrashField_Registers             "registers"
#define Raygun_KSCrashField_Skipped               "skipped"
#define Raygun_KSCrashField_Stack                 "stack"


#pragma mark - Binary Image -

#define Raygun_KSCrashField_CPUSubType            "cpu_subtype"
#define Raygun_KSCrashField_CPUType               "cpu_type"
#define Raygun_KSCrashField_ImageAddress          "image_addr"
#define Raygun_KSCrashField_ImageVmAddress        "image_vmaddr"
#define Raygun_KSCrashField_ImageSize             "image_size"
#define Raygun_KSCrashField_ImageMajorVersion     "major_version"
#define Raygun_KSCrashField_ImageMinorVersion     "minor_version"
#define Raygun_KSCrashField_ImageRevisionVersion  "revision_version"


#pragma mark - Memory -

#define Raygun_KSCrashField_Free                  "free"
#define Raygun_KSCrashField_Usable                "usable"


#pragma mark - Error -

#define Raygun_KSCrashField_Backtrace             "backtrace"
#define Raygun_KSCrashField_Code                  "code"
#define Raygun_KSCrashField_CodeName              "code_name"
#define Raygun_KSCrashField_CPPException          "cpp_exception"
#define Raygun_KSCrashField_ExceptionName         "exception_name"
#define Raygun_KSCrashField_Mach                  "mach"
#define Raygun_KSCrashField_NSException           "nsexception"
#define Raygun_KSCrashField_Reason                "reason"
#define Raygun_KSCrashField_Signal                "signal"
#define Raygun_KSCrashField_Subcode               "subcode"
#define Raygun_KSCrashField_UserReported          "user_reported"


#pragma mark - Process State -

#define Raygun_KSCrashField_LastDeallocedNSException "last_dealloced_nsexception"
#define Raygun_KSCrashField_ProcessState             "process"


#pragma mark - App Stats -

#define Raygun_KSCrashField_ActiveTimeSinceCrash  "active_time_since_last_crash"
#define Raygun_KSCrashField_ActiveTimeSinceLaunch "active_time_since_launch"
#define Raygun_KSCrashField_AppActive             "application_active"
#define Raygun_KSCrashField_AppInFG               "application_in_foreground"
#define Raygun_KSCrashField_BGTimeSinceCrash      "background_time_since_last_crash"
#define Raygun_KSCrashField_BGTimeSinceLaunch     "background_time_since_launch"
#define Raygun_KSCrashField_LaunchesSinceCrash    "launches_since_last_crash"
#define Raygun_KSCrashField_SessionsSinceCrash    "sessions_since_last_crash"
#define Raygun_KSCrashField_SessionsSinceLaunch   "sessions_since_launch"


#pragma mark - Report -

#define Raygun_KSCrashField_Crash                 "crash"
#define Raygun_KSCrashField_Debug                 "debug"
#define Raygun_KSCrashField_Diagnosis             "diagnosis"
#define Raygun_KSCrashField_ID                    "id"
#define Raygun_KSCrashField_ProcessName           "process_name"
#define Raygun_KSCrashField_Report                "report"
#define Raygun_KSCrashField_Timestamp             "timestamp"
#define Raygun_KSCrashField_Version               "version"

#pragma mark Minimal
#define Raygun_KSCrashField_CrashedThread         "crashed_thread"

#pragma mark Standard
#define Raygun_KSCrashField_AppStats              "application_stats"
#define Raygun_KSCrashField_BinaryImages          "binary_images"
#define Raygun_KSCrashField_System                "system"
#define Raygun_KSCrashField_Memory                "memory"
#define Raygun_KSCrashField_Threads               "threads"
#define Raygun_KSCrashField_User                  "user"
#define Raygun_KSCrashField_ConsoleLog            "console_log"

#pragma mark Incomplete
#define Raygun_KSCrashField_Incomplete            "incomplete"
#define Raygun_KSCrashField_RecrashReport         "recrash_report"

#pragma mark System
#define Raygun_KSCrashField_AppStartTime          "app_start_time"
#define Raygun_KSCrashField_AppUUID               "app_uuid"
#define Raygun_KSCrashField_BootTime              "boot_time"
#define Raygun_KSCrashField_BundleID              "CFBundleIdentifier"
#define Raygun_KSCrashField_BundleName            "CFBundleName"
#define Raygun_KSCrashField_BundleShortVersion    "CFBundleShortVersionString"
#define Raygun_KSCrashField_BundleVersion         "CFBundleVersion"
#define Raygun_KSCrashField_CPUArch               "cpu_arch"
#define Raygun_KSCrashField_CPUType               "cpu_type"
#define Raygun_KSCrashField_CPUSubType            "cpu_subtype"
#define Raygun_KSCrashField_BinaryCPUType         "binary_cpu_type"
#define Raygun_KSCrashField_BinaryCPUSubType      "binary_cpu_subtype"
#define Raygun_KSCrashField_DeviceAppHash         "device_app_hash"
#define Raygun_KSCrashField_Executable            "CFBundleExecutable"
#define Raygun_KSCrashField_ExecutablePath        "CFBundleExecutablePath"
#define Raygun_KSCrashField_Jailbroken            "jailbroken"
#define Raygun_KSCrashField_KernelVersion         "kernel_version"
#define Raygun_KSCrashField_Machine               "machine"
#define Raygun_KSCrashField_Model                 "model"
#define Raygun_KSCrashField_OSVersion             "os_version"
#define Raygun_KSCrashField_ParentProcessID       "parent_process_id"
#define Raygun_KSCrashField_ProcessID             "process_id"
#define Raygun_KSCrashField_ProcessName           "process_name"
#define Raygun_KSCrashField_Size                  "size"
#define Raygun_KSCrashField_Storage               "storage"
#define Raygun_KSCrashField_SystemName            "system_name"
#define Raygun_KSCrashField_SystemVersion         "system_version"
#define Raygun_KSCrashField_TimeZone              "time_zone"
#define Raygun_KSCrashField_BuildType             "build_type"

#endif
