//
//  KSCrashReport.m
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


#include "Raygun_KSCrashReport.h"

#include "Raygun_KSCrashReportFields.h"
#include "Raygun_KSCrashReportWriter.h"
#include "Raygun_KSDynamicLinker.h"
#include "Raygun_KSFileUtils.h"
#include "Raygun_KSJSONCodec.h"
#include "Raygun_KSCPU.h"
#include "Raygun_KSMemory.h"
#include "Raygun_KSMach.h"
#include "Raygun_KSThread.h"
#include "Raygun_KSObjC.h"
#include "Raygun_KSSignalInfo.h"
#include "Raygun_KSCrashMonitor_Zombie.h"
#include "Raygun_KSString.h"
#include "Raygun_KSCrashReportVersion.h"
#include "Raygun_KSStackCursor_Backtrace.h"
#include "Raygun_KSStackCursor_MachineContext.h"
#include "Raygun_KSSystemCapabilities.h"
#include "Raygun_KSCrashCachedData.h"

//#define Raygun_KSLogger_LocalLevel TRACE
#include "Raygun_KSLogger.h"

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


// ============================================================================
#pragma mark - Constants -
// ============================================================================

/** Default number of objects, subobjects, and ivars to record from a memory loc */
#define kDefaultMemorySearchDepth 15

/** How far to search the stack (in pointer sized jumps) for notable data. */
#define kStackNotableSearchBackDistance 20
#define kStackNotableSearchForwardDistance 10

/** How much of the stack to dump (in pointer sized jumps). */
#define kStackContentsPushedDistance 20
#define kStackContentsPoppedDistance 10
#define kStackContentsTotalDistance (kStackContentsPushedDistance + kStackContentsPoppedDistance)

/** The minimum length for a valid string. */
#define kMinStringLength 4


// ============================================================================
#pragma mark - JSON Encoding -
// ============================================================================

#define getJsonContext(REPORT_WRITER) ((Raygun_KSJSONEncodeContext*)((REPORT_WRITER)->context))

/** Used for writing hex string values. */
static const char g_hexNybbles[] =
{
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

// ============================================================================
#pragma mark - Runtime Config -
// ============================================================================

typedef struct
{
    /** If YES, introspect memory contents during a crash.
     * Any Objective-C objects or C strings near the stack pointer or referenced by
     * cpu registers or exceptions will be recorded in the crash report, along with
     * their contents.
     */
    bool enabled;
    
    /** List of classes that should never be introspected.
     * Whenever a class in this list is encountered, only the class name will be recorded.
     */
    const char** restrictedClasses;
    int restrictedClassesCount;
} KSCrash_IntrospectionRules;

static const char* g_userInfoJSON;
static KSCrash_IntrospectionRules g_introspectionRules;
static Raygun_KSReportWriteCallback g_userSectionWriteCallback;


#pragma mark Callbacks

static void addBooleanElement(const Raygun_KSCrashReportWriter* const writer, const char* const key, const bool value)
{
    raygun_ksjson_addBooleanElement(getJsonContext(writer), key, value);
}

static void addFloatingPointElement(const Raygun_KSCrashReportWriter* const writer, const char* const key, const double value)
{
    raygun_ksjson_addFloatingPointElement(getJsonContext(writer), key, value);
}

static void addIntegerElement(const Raygun_KSCrashReportWriter* const writer, const char* const key, const int64_t value)
{
    raygun_ksjson_addIntegerElement(getJsonContext(writer), key, value);
}

static void addUIntegerElement(const Raygun_KSCrashReportWriter* const writer, const char* const key, const uint64_t value)
{
    raygun_ksjson_addIntegerElement(getJsonContext(writer), key, (int64_t)value);
}

static void addStringElement(const Raygun_KSCrashReportWriter* const writer, const char* const key, const char* const value)
{
    raygun_ksjson_addStringElement(getJsonContext(writer), key, value, RAYGUN_KSJSON_SIZE_AUTOMATIC);
}

static void addTextFileElement(const Raygun_KSCrashReportWriter* const writer, const char* const key, const char* const filePath)
{
    const int fd = open(filePath, O_RDONLY);
    if(fd < 0)
    {
        RAYGUN_KSLOG_ERROR("Could not open file %s: %s", filePath, strerror(errno));
        return;
    }

    if(raygun_ksjson_beginStringElement(getJsonContext(writer), key) != RAYGUN_KSJSON_OK)
    {
        RAYGUN_KSLOG_ERROR("Could not start string element");
        goto done;
    }

    char buffer[512];
    int bytesRead;
    for(bytesRead = (int)read(fd, buffer, sizeof(buffer));
        bytesRead > 0;
        bytesRead = (int)read(fd, buffer, sizeof(buffer)))
    {
        if(raygun_ksjson_appendStringElement(getJsonContext(writer), buffer, bytesRead) != RAYGUN_KSJSON_OK)
        {
            RAYGUN_KSLOG_ERROR("Could not append string element");
            goto done;
        }
    }

done:
    raygun_ksjson_endStringElement(getJsonContext(writer));
    close(fd);
}

static void addDataElement(const Raygun_KSCrashReportWriter* const writer,
                           const char* const key,
                           const char* const value,
                           const int length)
{
    raygun_ksjson_addDataElement(getJsonContext(writer), key, value, length);
}

static void beginDataElement(const Raygun_KSCrashReportWriter* const writer, const char* const key)
{
    raygun_ksjson_beginDataElement(getJsonContext(writer), key);
}

static void appendDataElement(const Raygun_KSCrashReportWriter* const writer, const char* const value, const int length)
{
    raygun_ksjson_appendDataElement(getJsonContext(writer), value, length);
}

static void endDataElement(const Raygun_KSCrashReportWriter* const writer)
{
    raygun_ksjson_endDataElement(getJsonContext(writer));
}

static void addUUIDElement(const Raygun_KSCrashReportWriter* const writer, const char* const key, const unsigned char* const value)
{
    if(value == NULL)
    {
        ksjson_addNullElement(getJsonContext(writer), key);
    }
    else
    {
        char uuidBuffer[37];
        const unsigned char* src = value;
        char* dst = uuidBuffer;
        for(int i = 0; i < 4; i++)
        {
            *dst++ = g_hexNybbles[(*src>>4)&15];
            *dst++ = g_hexNybbles[(*src++)&15];
        }
        *dst++ = '-';
        for(int i = 0; i < 2; i++)
        {
            *dst++ = g_hexNybbles[(*src>>4)&15];
            *dst++ = g_hexNybbles[(*src++)&15];
        }
        *dst++ = '-';
        for(int i = 0; i < 2; i++)
        {
            *dst++ = g_hexNybbles[(*src>>4)&15];
            *dst++ = g_hexNybbles[(*src++)&15];
        }
        *dst++ = '-';
        for(int i = 0; i < 2; i++)
        {
            *dst++ = g_hexNybbles[(*src>>4)&15];
            *dst++ = g_hexNybbles[(*src++)&15];
        }
        *dst++ = '-';
        for(int i = 0; i < 6; i++)
        {
            *dst++ = g_hexNybbles[(*src>>4)&15];
            *dst++ = g_hexNybbles[(*src++)&15];
        }

        raygun_ksjson_addStringElement(getJsonContext(writer), key, uuidBuffer, (int)(dst - uuidBuffer));
    }
}

static void addJSONElement(const Raygun_KSCrashReportWriter* const writer,
                           const char* const key,
                           const char* const jsonElement,
                           bool closeLastContainer)
{
    int jsonResult = raygun_ksjson_addJSONElement(getJsonContext(writer),
                                           key,
                                           jsonElement,
                                           (int)strlen(jsonElement),
                                           closeLastContainer);
    if(jsonResult != RAYGUN_KSJSON_OK)
    {
        char errorBuff[100];
        snprintf(errorBuff,
                 sizeof(errorBuff),
                 "Invalid JSON data: %s",
                 raygun_ksjson_stringForError(jsonResult));
        raygun_ksjson_beginObject(getJsonContext(writer), key);
        raygun_ksjson_addStringElement(getJsonContext(writer),
                                Raygun_KSCrashField_Error,
                                errorBuff,
                                RAYGUN_KSJSON_SIZE_AUTOMATIC);
        raygun_ksjson_addStringElement(getJsonContext(writer),
                                Raygun_KSCrashField_JSONData,
                                jsonElement,
                                RAYGUN_KSJSON_SIZE_AUTOMATIC);
        raygun_ksjson_endContainer(getJsonContext(writer));
    }
}

static void addJSONElementFromFile(const Raygun_KSCrashReportWriter* const writer,
                                   const char* const key,
                                   const char* const filePath,
                                   bool closeLastContainer)
{
    raygun_ksjson_addJSONFromFile(getJsonContext(writer), key, filePath, closeLastContainer);
}

static void beginObject(const Raygun_KSCrashReportWriter* const writer, const char* const key)
{
    raygun_ksjson_beginObject(getJsonContext(writer), key);
}

static void beginArray(const Raygun_KSCrashReportWriter* const writer, const char* const key)
{
    raygun_ksjson_beginArray(getJsonContext(writer), key);
}

static void endContainer(const Raygun_KSCrashReportWriter* const writer)
{
    raygun_ksjson_endContainer(getJsonContext(writer));
}


static void addTextLinesFromFile(const Raygun_KSCrashReportWriter* const writer, const char* const key, const char* const filePath)
{
    char readBuffer[1024];
    Raygun_KSBufferedReader reader;
    if(!raygun_ksfu_openBufferedReader(&reader, filePath, readBuffer, sizeof(readBuffer)))
    {
        return;
    }
    char buffer[1024];
    beginArray(writer, key);
    {
        for(;;)
        {
            int length = sizeof(buffer);
            raygun_ksfu_readBufferedReaderUntilChar(&reader, '\n', buffer, &length);
            if(length <= 0)
            {
                break;
            }
            buffer[length - 1] = '\0';
            raygun_ksjson_addStringElement(getJsonContext(writer), NULL, buffer, RAYGUN_KSJSON_SIZE_AUTOMATIC);
        }
    }
    endContainer(writer);
    raygun_ksfu_closeBufferedReader(&reader);
}

static int addJSONData(const char* restrict const data, const int length, void* restrict userData)
{
    Raygun_KSBufferedWriter* writer = (Raygun_KSBufferedWriter*)userData;
    const bool success = raygun_ksfu_writeBufferedWriter(writer, data, length);
    return success ? RAYGUN_KSJSON_OK : RAYGUN_KSJSON_ERROR_CANNOT_ADD_DATA;
}


// ============================================================================
#pragma mark - Utility -
// ============================================================================

/** Check if a memory address points to a valid null terminated UTF-8 string.
 *
 * @param address The address to check.
 *
 * @return true if the address points to a string.
 */
static bool isValidString(const void* const address)
{
    if((void*)address == NULL)
    {
        return false;
    }

    char buffer[500];
    if((uintptr_t)address+sizeof(buffer) < (uintptr_t)address)
    {
        // Wrapped around the address range.
        return false;
    }
    if(!raygun_ksmem_copySafely(address, buffer, sizeof(buffer)))
    {
        return false;
    }
    return raygun_ksstring_isNullTerminatedUTF8String(buffer, kMinStringLength, sizeof(buffer));
}

/** Get the backtrace for the specified machine context.
 *
 * This function will choose how to fetch the backtrace based on the crash and
 * machine context. It may store the backtrace in backtraceBuffer unless it can
 * be fetched directly from memory. Do not count on backtraceBuffer containing
 * anything. Always use the return value.
 *
 * @param crash The crash handler context.
 *
 * @param machineContext The machine context.
 *
 * @param cursor The stack cursor to fill.
 *
 * @return True if the cursor was filled.
 */
static bool getStackCursor(const Raygun_KSCrash_MonitorContext* const crash,
                           const struct Raygun_KSMachineContext* const machineContext,
                           Raygun_KSStackCursor *cursor)
{
    if(raygun_ksmc_getThreadFromContext(machineContext) == raygun_ksmc_getThreadFromContext(crash->offendingMachineContext))
    {
        *cursor = *((Raygun_KSStackCursor*)crash->stackCursor);
        return true;
    }

    raygun_kssc_initWithMachineContext(cursor, KSSC_STACK_OVERFLOW_THRESHOLD, machineContext);
    return true;
}


// ============================================================================
#pragma mark - Report Writing -
// ============================================================================

/** Write the contents of a memory location.
 * Also writes meta information about the data.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param address The memory address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeMemoryContents(const Raygun_KSCrashReportWriter* const writer,
                                const char* const key,
                                const uintptr_t address,
                                int* limit);

/** Write a string to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeNSStringContents(const Raygun_KSCrashReportWriter* const writer,
                                  const char* const key,
                                  const uintptr_t objectAddress,
                                  __unused int* limit)
{
    const void* object = (const void*)objectAddress;
    char buffer[200];
    if(raygun_ksobjc_copyStringContents(object, buffer, sizeof(buffer)))
    {
        writer->addStringElement(writer, key, buffer);
    }
}

/** Write a URL to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeURLContents(const Raygun_KSCrashReportWriter* const writer,
                             const char* const key,
                             const uintptr_t objectAddress,
                             __unused int* limit)
{
    const void* object = (const void*)objectAddress;
    char buffer[200];
    if(raygun_ksobjc_copyStringContents(object, buffer, sizeof(buffer)))
    {
        writer->addStringElement(writer, key, buffer);
    }
}

/** Write a date to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeDateContents(const Raygun_KSCrashReportWriter* const writer,
                              const char* const key,
                              const uintptr_t objectAddress,
                              __unused int* limit)
{
    const void* object = (const void*)objectAddress;
    writer->addFloatingPointElement(writer, key, raygun_ksobjc_dateContents(object));
}

/** Write a number to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeNumberContents(const Raygun_KSCrashReportWriter* const writer,
                                const char* const key,
                                const uintptr_t objectAddress,
                                __unused int* limit)
{
    const void* object = (const void*)objectAddress;
    writer->addFloatingPointElement(writer, key, raygun_ksobjc_numberAsFloat(object));
}

/** Write an array to the report.
 * This will only print the first child of the array.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeArrayContents(const Raygun_KSCrashReportWriter* const writer,
                               const char* const key,
                               const uintptr_t objectAddress,
                               int* limit)
{
    const void* object = (const void*)objectAddress;
    uintptr_t firstObject;
    if(raygun_ksobjc_arrayContents(object, &firstObject, 1) == 1)
    {
        writeMemoryContents(writer, key, firstObject, limit);
    }
}

/** Write out ivar information about an unknown object.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param objectAddress The object's address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeUnknownObjectContents(const Raygun_KSCrashReportWriter* const writer,
                                       const char* const key,
                                       const uintptr_t objectAddress,
                                       int* limit)
{
    (*limit)--;
    const void* object = (const void*)objectAddress;
    Raygun_KSObjCIvar ivars[10];
    int8_t s8;
    int16_t s16;
    int sInt;
    int32_t s32;
    int64_t s64;
    uint8_t u8;
    uint16_t u16;
    unsigned int uInt;
    uint32_t u32;
    uint64_t u64;
    float f32;
    double f64;
    bool b;
    void* pointer;
    
    
    writer->beginObject(writer, key);
    {
        if(raygun_ksobjc_isTaggedPointer(object))
        {
            writer->addIntegerElement(writer, "tagged_payload", (int64_t)raygun_ksobjc_taggedPointerPayload(object));
        }
        else
        {
            const void* class = raygun_ksobjc_isaPointer(object);
            int ivarCount = raygun_ksobjc_ivarList(class, ivars, sizeof(ivars)/sizeof(*ivars));
            *limit -= ivarCount;
            for(int i = 0; i < ivarCount; i++)
            {
                Raygun_KSObjCIvar* ivar = &ivars[i];
                switch(ivar->type[0])
                {
                    case 'c':
                        raygun_ksobjc_ivarValue(object, ivar->index, &s8);
                        writer->addIntegerElement(writer, ivar->name, s8);
                        break;
                    case 'i':
                        raygun_ksobjc_ivarValue(object, ivar->index, &sInt);
                        writer->addIntegerElement(writer, ivar->name, sInt);
                        break;
                    case 's':
                        raygun_ksobjc_ivarValue(object, ivar->index, &s16);
                        writer->addIntegerElement(writer, ivar->name, s16);
                        break;
                    case 'l':
                        raygun_ksobjc_ivarValue(object, ivar->index, &s32);
                        writer->addIntegerElement(writer, ivar->name, s32);
                        break;
                    case 'q':
                        raygun_ksobjc_ivarValue(object, ivar->index, &s64);
                        writer->addIntegerElement(writer, ivar->name, s64);
                        break;
                    case 'C':
                        raygun_ksobjc_ivarValue(object, ivar->index, &u8);
                        writer->addUIntegerElement(writer, ivar->name, u8);
                        break;
                    case 'I':
                        raygun_ksobjc_ivarValue(object, ivar->index, &uInt);
                        writer->addUIntegerElement(writer, ivar->name, uInt);
                        break;
                    case 'S':
                        raygun_ksobjc_ivarValue(object, ivar->index, &u16);
                        writer->addUIntegerElement(writer, ivar->name, u16);
                        break;
                    case 'L':
                        raygun_ksobjc_ivarValue(object, ivar->index, &u32);
                        writer->addUIntegerElement(writer, ivar->name, u32);
                        break;
                    case 'Q':
                        raygun_ksobjc_ivarValue(object, ivar->index, &u64);
                        writer->addUIntegerElement(writer, ivar->name, u64);
                        break;
                    case 'f':
                        raygun_ksobjc_ivarValue(object, ivar->index, &f32);
                        writer->addFloatingPointElement(writer, ivar->name, f32);
                        break;
                    case 'd':
                        raygun_ksobjc_ivarValue(object, ivar->index, &f64);
                        writer->addFloatingPointElement(writer, ivar->name, f64);
                        break;
                    case 'B':
                        raygun_ksobjc_ivarValue(object, ivar->index, &b);
                        writer->addBooleanElement(writer, ivar->name, b);
                        break;
                    case '*':
                    case '@':
                    case '#':
                    case ':':
                        raygun_ksobjc_ivarValue(object, ivar->index, &pointer);
                        writeMemoryContents(writer, ivar->name, (uintptr_t)pointer, limit);
                        break;
                    default:
                        RAYGUN_KSLOG_DEBUG("%s: Unknown ivar type [%s]", ivar->name, ivar->type);
                }
            }
        }
    }
    writer->endContainer(writer);
}

static bool isRestrictedClass(const char* name)
{
    if(g_introspectionRules.restrictedClasses != NULL)
    {
        for(int i = 0; i < g_introspectionRules.restrictedClassesCount; i++)
        {
            if(strcmp(name, g_introspectionRules.restrictedClasses[i]) == 0)
            {
                return true;
            }
        }
    }
    return false;
}

static void writeZombieIfPresent(const Raygun_KSCrashReportWriter* const writer,
                                 const char* const key,
                                 const uintptr_t address)
{
#if RAYGUN_KSCRASH_HAS_OBJC
    const void* object = (const void*)address;
    const char* zombieClassName = raygun_kszombie_className(object);
    if(zombieClassName != NULL)
    {
        writer->addStringElement(writer, key, zombieClassName);
    }
#endif
}

static bool writeObjCObject(const Raygun_KSCrashReportWriter* const writer,
                            const uintptr_t address,
                            int* limit)
{
#if RAYGUN_KSCRASH_HAS_OBJC
    const void* object = (const void*)address;
    switch(raygun_ksobjc_objectType(object))
    {
        case Raygun_KSObjCTypeClass:
            writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashMemType_Class);
            writer->addStringElement(writer, Raygun_KSCrashField_Class, raygun_ksobjc_className(object));
            return true;
        case Raygun_KSObjCTypeObject:
        {
            writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashMemType_Object);
            const char* className = raygun_ksobjc_objectClassName(object);
            writer->addStringElement(writer, Raygun_KSCrashField_Class, className);
            if(!isRestrictedClass(className))
            {
                switch(raygun_ksobjc_objectClassType(object))
                {
                    case Raygun_KSObjCClassTypeString:
                        writeNSStringContents(writer, Raygun_KSCrashField_Value, address, limit);
                        return true;
                    case Raygun_KSObjCClassTypeURL:
                        writeURLContents(writer, Raygun_KSCrashField_Value, address, limit);
                        return true;
                    case Raygun_KSObjCClassTypeDate:
                        writeDateContents(writer, Raygun_KSCrashField_Value, address, limit);
                        return true;
                    case Raygun_KSObjCClassTypeArray:
                        if(*limit > 0)
                        {
                            writeArrayContents(writer, Raygun_KSCrashField_FirstObject, address, limit);
                        }
                        return true;
                    case Raygun_KSObjCClassTypeNumber:
                        writeNumberContents(writer, Raygun_KSCrashField_Value, address, limit);
                        return true;
                    case Raygun_KSObjCClassTypeDictionary:
                    case Raygun_KSObjCClassTypeException:
                        // TODO: Implement these.
                        if(*limit > 0)
                        {
                            writeUnknownObjectContents(writer, Raygun_KSCrashField_Ivars, address, limit);
                        }
                        return true;
                    case Raygun_KSObjCClassTypeUnknown:
                        if(*limit > 0)
                        {
                            writeUnknownObjectContents(writer, Raygun_KSCrashField_Ivars, address, limit);
                        }
                        return true;
                }
            }
            break;
        }
        case Raygun_KSObjCTypeBlock:
            writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashMemType_Block);
            const char* className = raygun_ksobjc_objectClassName(object);
            writer->addStringElement(writer, Raygun_KSCrashField_Class, className);
            return true;
        case Raygun_KSObjCTypeUnknown:
            break;
    }
#endif

    return false;
}

/** Write the contents of a memory location.
 * Also writes meta information about the data.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param address The memory address.
 *
 * @param limit How many more subreferenced objects to write, if any.
 */
static void writeMemoryContents(const Raygun_KSCrashReportWriter* const writer,
                                const char* const key,
                                const uintptr_t address,
                                int* limit)
{
    (*limit)--;
    const void* object = (const void*)address;
    writer->beginObject(writer, key);
    {
        writer->addUIntegerElement(writer, Raygun_KSCrashField_Address, address);
        writeZombieIfPresent(writer, Raygun_KSCrashField_LastDeallocObject, address);
        if(!writeObjCObject(writer, address, limit))
        {
            if(object == NULL)
            {
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashMemType_NullPointer);
            }
            else if(isValidString(object))
            {
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashMemType_String);
                writer->addStringElement(writer, Raygun_KSCrashField_Value, (const char*)object);
            }
            else
            {
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashMemType_Unknown);
            }
        }
    }
    writer->endContainer(writer);
}

static bool isValidPointer(const uintptr_t address)
{
    if(address == (uintptr_t)NULL)
    {
        return false;
    }

#if RAYGUN_KSCRASH_HAS_OBJC
    if(raygun_ksobjc_isTaggedPointer((const void*)address))
    {
        if(!raygun_ksobjc_isValidTaggedPointer((const void*)address))
        {
            return false;
        }
    }
#endif

    return true;
}

static bool isNotableAddress(const uintptr_t address)
{
    if(!isValidPointer(address))
    {
        return false;
    }
    
    const void* object = (const void*)address;

#if RAYGUN_KSCRASH_HAS_OBJC
    if(raygun_kszombie_className(object) != NULL)
    {
        return true;
    }

    if(raygun_ksobjc_objectType(object) != Raygun_KSObjCTypeUnknown)
    {
        return true;
    }
#endif

    if(isValidString(object))
    {
        return true;
    }

    return false;
}

/** Write the contents of a memory location only if it contains notable data.
 * Also writes meta information about the data.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param address The memory address.
 */
static void writeMemoryContentsIfNotable(const Raygun_KSCrashReportWriter* const writer,
                                         const char* const key,
                                         const uintptr_t address)
{
    if(isNotableAddress(address))
    {
        int limit = kDefaultMemorySearchDepth;
        writeMemoryContents(writer, key, address, &limit);
    }
}

/** Look for a hex value in a string and try to write whatever it references.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param string The string to search.
 */
static void writeAddressReferencedByString(const Raygun_KSCrashReportWriter* const writer,
                                           const char* const key,
                                           const char* string)
{
    uint64_t address = 0;
    if(string == NULL || !raygun_ksstring_extractHexValue(string, (int)strlen(string), &address))
    {
        return;
    }
    
    int limit = kDefaultMemorySearchDepth;
    writeMemoryContents(writer, key, (uintptr_t)address, &limit);
}

#pragma mark Backtrace

/** Write a backtrace to the report.
 *
 * @param writer The writer to write the backtrace to.
 *
 * @param key The object key, if needed.
 *
 * @param stackCursor The stack cursor to read from.
 */
static void writeBacktrace(const Raygun_KSCrashReportWriter* const writer,
                           const char* const key,
                           Raygun_KSStackCursor* stackCursor)
{
    writer->beginObject(writer, key);
    {
        writer->beginArray(writer, Raygun_KSCrashField_Contents);
        {
            while(stackCursor->advanceCursor(stackCursor))
            {
                writer->beginObject(writer, NULL);
                {
                    if(stackCursor->symbolicate(stackCursor))
                    {
                        if(stackCursor->stackEntry.imageName != NULL)
                        {
                            writer->addStringElement(writer, Raygun_KSCrashField_ObjectName, raygun_ksfu_lastPathEntry(stackCursor->stackEntry.imageName));
                        }
                        writer->addUIntegerElement(writer, Raygun_KSCrashField_ObjectAddr, stackCursor->stackEntry.imageAddress);
                        if(stackCursor->stackEntry.symbolName != NULL)
                        {
                            writer->addStringElement(writer, Raygun_KSCrashField_SymbolName, stackCursor->stackEntry.symbolName);
                        }
                        writer->addUIntegerElement(writer, Raygun_KSCrashField_SymbolAddr, stackCursor->stackEntry.symbolAddress);
                    }
                    writer->addUIntegerElement(writer, Raygun_KSCrashField_InstructionAddr, stackCursor->stackEntry.address);
                }
                writer->endContainer(writer);
            }
        }
        writer->endContainer(writer);
        writer->addIntegerElement(writer, Raygun_KSCrashField_Skipped, 0);
    }
    writer->endContainer(writer);
}
                              

#pragma mark Stack

/** Write a dump of the stack contents to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the stack from.
 *
 * @param isStackOverflow If true, the stack has overflowed.
 */
static void writeStackContents(const Raygun_KSCrashReportWriter* const writer,
                               const char* const key,
                               const struct Raygun_KSMachineContext* const machineContext,
                               const bool isStackOverflow)
{
    uintptr_t sp = raygun_kscpu_stackPointer(machineContext);
    if((void*)sp == NULL)
    {
        return;
    }

    uintptr_t lowAddress = sp + (uintptr_t)(kStackContentsPushedDistance * (int)sizeof(sp) * raygun_kscpu_stackGrowDirection() * -1);
    uintptr_t highAddress = sp + (uintptr_t)(kStackContentsPoppedDistance * (int)sizeof(sp) * raygun_kscpu_stackGrowDirection());
    if(highAddress < lowAddress)
    {
        uintptr_t tmp = lowAddress;
        lowAddress = highAddress;
        highAddress = tmp;
    }
    writer->beginObject(writer, key);
    {
        writer->addStringElement(writer, Raygun_KSCrashField_GrowDirection, raygun_kscpu_stackGrowDirection() > 0 ? "+" : "-");
        writer->addUIntegerElement(writer, Raygun_KSCrashField_DumpStart, lowAddress);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_DumpEnd, highAddress);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_StackPtr, sp);
        writer->addBooleanElement(writer, Raygun_KSCrashField_Overflow, isStackOverflow);
        uint8_t stackBuffer[kStackContentsTotalDistance * sizeof(sp)];
        int copyLength = (int)(highAddress - lowAddress);
        if(raygun_ksmem_copySafely((void*)lowAddress, stackBuffer, copyLength))
        {
            writer->addDataElement(writer, Raygun_KSCrashField_Contents, (void*)stackBuffer, copyLength);
        }
        else
        {
            writer->addStringElement(writer, Raygun_KSCrashField_Error, "Stack contents not accessible");
        }
    }
    writer->endContainer(writer);
}

/** Write any notable addresses near the stack pointer (above and below).
 *
 * @param writer The writer.
 *
 * @param machineContext The context to retrieve the stack from.
 *
 * @param backDistance The distance towards the beginning of the stack to check.
 *
 * @param forwardDistance The distance past the end of the stack to check.
 */
static void writeNotableStackContents(const Raygun_KSCrashReportWriter* const writer,
                                      const struct Raygun_KSMachineContext* const machineContext,
                                      const int backDistance,
                                      const int forwardDistance)
{
    uintptr_t sp = raygun_kscpu_stackPointer(machineContext);
    if((void*)sp == NULL)
    {
        return;
    }

    uintptr_t lowAddress = sp + (uintptr_t)(backDistance * (int)sizeof(sp) * raygun_kscpu_stackGrowDirection() * -1);
    uintptr_t highAddress = sp + (uintptr_t)(forwardDistance * (int)sizeof(sp) * raygun_kscpu_stackGrowDirection());
    if(highAddress < lowAddress)
    {
        uintptr_t tmp = lowAddress;
        lowAddress = highAddress;
        highAddress = tmp;
    }
    uintptr_t contentsAsPointer;
    char nameBuffer[40];
    for(uintptr_t address = lowAddress; address < highAddress; address += sizeof(address))
    {
        if(raygun_ksmem_copySafely((void*)address, &contentsAsPointer, sizeof(contentsAsPointer)))
        {
            sprintf(nameBuffer, "stack@%p", (void*)address);
            writeMemoryContentsIfNotable(writer, nameBuffer, contentsAsPointer);
        }
    }
}


#pragma mark Registers

/** Write the contents of all regular registers to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void writeBasicRegisters(const Raygun_KSCrashReportWriter* const writer,
                                const char* const key,
                                const struct Raygun_KSMachineContext* const machineContext)
{
    char registerNameBuff[30];
    const char* registerName;
    writer->beginObject(writer, key);
    {
        const int numRegisters = raygun_kscpu_numRegisters();
        for(int reg = 0; reg < numRegisters; reg++)
        {
            registerName = raygun_kscpu_registerName(reg);
            if(registerName == NULL)
            {
                snprintf(registerNameBuff, sizeof(registerNameBuff), "r%d", reg);
                registerName = registerNameBuff;
            }
            writer->addUIntegerElement(writer, registerName,
                                       raygun_kscpu_registerValue(machineContext, reg));
        }
    }
    writer->endContainer(writer);
}

/** Write the contents of all exception registers to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void writeExceptionRegisters(const Raygun_KSCrashReportWriter* const writer,
                                    const char* const key,
                                    const struct Raygun_KSMachineContext* const machineContext)
{
    char registerNameBuff[30];
    const char* registerName;
    writer->beginObject(writer, key);
    {
        const int numRegisters = raygun_kscpu_numExceptionRegisters();
        for(int reg = 0; reg < numRegisters; reg++)
        {
            registerName = raygun_kscpu_exceptionRegisterName(reg);
            if(registerName == NULL)
            {
                snprintf(registerNameBuff, sizeof(registerNameBuff), "r%d", reg);
                registerName = registerNameBuff;
            }
            writer->addUIntegerElement(writer,registerName,
                                       raygun_kscpu_exceptionRegisterValue(machineContext, reg));
        }
    }
    writer->endContainer(writer);
}

/** Write all applicable registers.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void writeRegisters(const Raygun_KSCrashReportWriter* const writer,
                           const char* const key,
                           const struct Raygun_KSMachineContext* const machineContext)
{
    writer->beginObject(writer, key);
    {
        writeBasicRegisters(writer, Raygun_KSCrashField_Basic, machineContext);
        if(raygun_ksmc_hasValidExceptionRegisters(machineContext))
        {
            writeExceptionRegisters(writer, Raygun_KSCrashField_Exception, machineContext);
        }
    }
    writer->endContainer(writer);
}

/** Write any notable addresses contained in the CPU registers.
 *
 * @param writer The writer.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void writeNotableRegisters(const Raygun_KSCrashReportWriter* const writer,
                                  const struct Raygun_KSMachineContext* const machineContext)
{
    char registerNameBuff[30];
    const char* registerName;
    const int numRegisters = raygun_kscpu_numRegisters();
    for(int reg = 0; reg < numRegisters; reg++)
    {
        registerName = raygun_kscpu_registerName(reg);
        if(registerName == NULL)
        {
            snprintf(registerNameBuff, sizeof(registerNameBuff), "r%d", reg);
            registerName = registerNameBuff;
        }
        writeMemoryContentsIfNotable(writer,
                                     registerName,
                                     (uintptr_t)raygun_kscpu_registerValue(machineContext, reg));
    }
}

#pragma mark Thread-specific

/** Write any notable addresses in the stack or registers to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param machineContext The context to retrieve the registers from.
 */
static void writeNotableAddresses(const Raygun_KSCrashReportWriter* const writer,
                                  const char* const key,
                                  const struct Raygun_KSMachineContext* const machineContext)
{
    writer->beginObject(writer, key);
    {
        writeNotableRegisters(writer, machineContext);
        writeNotableStackContents(writer,
                                  machineContext,
                                  kStackNotableSearchBackDistance,
                                  kStackNotableSearchForwardDistance);
    }
    writer->endContainer(writer);
}

/** Write information about a thread to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param crash The crash handler context.
 *
 * @param machineContext The context whose thread to write about.
 *
 * @param shouldWriteNotableAddresses If true, write any notable addresses found.
 */
static void writeThread(const Raygun_KSCrashReportWriter* const writer,
                        const char* const key,
                        const Raygun_KSCrash_MonitorContext* const crash,
                        const struct Raygun_KSMachineContext* const machineContext,
                        const int threadIndex,
                        const bool shouldWriteNotableAddresses)
{
    bool isCrashedThread = raygun_ksmc_isCrashedContext(machineContext);
    KSThread thread = raygun_ksmc_getThreadFromContext(machineContext);
    RAYGUN_KSLOG_DEBUG("Writing thread %x (index %d). is crashed: %d", thread, threadIndex, isCrashedThread);

    Raygun_KSStackCursor stackCursor;
    bool hasBacktrace = getStackCursor(crash, machineContext, &stackCursor);

    writer->beginObject(writer, key);
    {
        if(hasBacktrace)
        {
            writeBacktrace(writer, Raygun_KSCrashField_Backtrace, &stackCursor);
        }
        if(raygun_ksmc_canHaveCPUState(machineContext))
        {
            writeRegisters(writer, Raygun_KSCrashField_Registers, machineContext);
        }
        writer->addIntegerElement(writer, Raygun_KSCrashField_Index, threadIndex);
        const char* name = raygun_ksccd_getThreadName(thread);
        if(name != NULL)
        {
            writer->addStringElement(writer, Raygun_KSCrashField_Name, name);
        }
        name = raygun_ksccd_getQueueName(thread);
        if(name != NULL)
        {
            writer->addStringElement(writer, Raygun_KSCrashField_DispatchQueue, name);
        }
        writer->addBooleanElement(writer, Raygun_KSCrashField_Crashed, isCrashedThread);
        writer->addBooleanElement(writer, Raygun_KSCrashField_CurrentThread, thread == raygun_ksthread_self());
        if(isCrashedThread)
        {
            writeStackContents(writer, Raygun_KSCrashField_Stack, machineContext, stackCursor.state.hasGivenUp);
            if(shouldWriteNotableAddresses)
            {
                writeNotableAddresses(writer, Raygun_KSCrashField_NotableAddresses, machineContext);
            }
        }
    }
    writer->endContainer(writer);
}

/** Write information about all threads to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param crash The crash handler context.
 */
static void writeAllThreads(const Raygun_KSCrashReportWriter* const writer,
                            const char* const key,
                            const Raygun_KSCrash_MonitorContext* const crash,
                            bool writeNotableAddresses)
{
    const struct Raygun_KSMachineContext* const context = crash->offendingMachineContext;
    KSThread offendingThread = raygun_ksmc_getThreadFromContext(context);
    int threadCount = raygun_ksmc_getThreadCount(context);
    RAYGUN_KSMC_NEW_CONTEXT(machineContext);

    // Fetch info for all threads.
    writer->beginArray(writer, key);
    {
        RAYGUN_KSLOG_DEBUG("Writing %d threads.", threadCount);
        for(int i = 0; i < threadCount; i++)
        {
            KSThread thread = raygun_ksmc_getThreadAtIndex(context, i);
            if(thread == offendingThread)
            {
                writeThread(writer, NULL, crash, context, i, writeNotableAddresses);
            }
            else
            {
                raygun_ksmc_getContextForThread(thread, machineContext, false);
                writeThread(writer, NULL, crash, machineContext, i, writeNotableAddresses);
            }
        }
    }
    writer->endContainer(writer);
}

#pragma mark Global Report Data

/** Write information about a binary image to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param index Which image to write about.
 */
static void writeBinaryImage(const Raygun_KSCrashReportWriter* const writer,
                             const char* const key,
                             const int index)
{
    Raygun_KSBinaryImage image = {0};
    if(!raygun_ksdl_getBinaryImage(index, &image))
    {
        return;
    }

    writer->beginObject(writer, key);
    {
        writer->addUIntegerElement(writer, Raygun_KSCrashField_ImageAddress, image.address);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_ImageVmAddress, image.vmAddress);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_ImageSize, image.size);
        writer->addStringElement(writer, Raygun_KSCrashField_Name, image.name);
        writer->addUUIDElement(writer, Raygun_KSCrashField_UUID, image.uuid);
        writer->addIntegerElement(writer, Raygun_KSCrashField_CPUType, image.cpuType);
        writer->addIntegerElement(writer, Raygun_KSCrashField_CPUSubType, image.cpuSubType);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_ImageMajorVersion, image.majorVersion);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_ImageMinorVersion, image.minorVersion);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_ImageRevisionVersion, image.revisionVersion);
    }
    writer->endContainer(writer);
}

/** Write information about all images to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 */
static void writeBinaryImages(const Raygun_KSCrashReportWriter* const writer, const char* const key)
{
    const int imageCount = raygun_ksdl_imageCount();

    writer->beginArray(writer, key);
    {
        for(int iImg = 0; iImg < imageCount; iImg++)
        {
            writeBinaryImage(writer, NULL, iImg);
        }
    }
    writer->endContainer(writer);
}

/** Write information about system memory to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 */
static void writeMemoryInfo(const Raygun_KSCrashReportWriter* const writer,
                            const char* const key,
                            const Raygun_KSCrash_MonitorContext* const monitorContext)
{
    writer->beginObject(writer, key);
    {
        writer->addUIntegerElement(writer, Raygun_KSCrashField_Size, monitorContext->System.memorySize);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_Usable, monitorContext->System.usableMemory);
        writer->addUIntegerElement(writer, Raygun_KSCrashField_Free, monitorContext->System.freeMemory);
    }
    writer->endContainer(writer);
}

/** Write information about the error leading to the crash to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param crash The crash handler context.
 */
static void writeError(const Raygun_KSCrashReportWriter* const writer,
                       const char* const key,
                       const Raygun_KSCrash_MonitorContext* const crash)
{
    writer->beginObject(writer, key);
    {
#if RAYGUN_KSCRASH_HOST_APPLE
        writer->beginObject(writer, Raygun_KSCrashField_Mach);
        {
            const char* machExceptionName = raygun_ksmach_exceptionName(crash->mach.type);
            const char* machCodeName = crash->mach.code == 0 ? NULL : raygun_ksmach_kernelReturnCodeName(crash->mach.code);
            writer->addUIntegerElement(writer, Raygun_KSCrashField_Exception, (unsigned)crash->mach.type);
            if(machExceptionName != NULL)
            {
                writer->addStringElement(writer, Raygun_KSCrashField_ExceptionName, machExceptionName);
            }
            writer->addUIntegerElement(writer, Raygun_KSCrashField_Code, (unsigned)crash->mach.code);
            if(machCodeName != NULL)
            {
                writer->addStringElement(writer, Raygun_KSCrashField_CodeName, machCodeName);
            }
            writer->addUIntegerElement(writer, Raygun_KSCrashField_Subcode, (unsigned)crash->mach.subcode);
        }
        writer->endContainer(writer);
#endif
        writer->beginObject(writer, Raygun_KSCrashField_Signal);
        {
            const char* sigName = raygun_kssignal_signalName(crash->signal.signum);
            const char* sigCodeName = raygun_kssignal_signalCodeName(crash->signal.signum, crash->signal.sigcode);
            writer->addUIntegerElement(writer, Raygun_KSCrashField_Signal, (unsigned)crash->signal.signum);
            if(sigName != NULL)
            {
                writer->addStringElement(writer, Raygun_KSCrashField_Name, sigName);
            }
            writer->addUIntegerElement(writer, Raygun_KSCrashField_Code, (unsigned)crash->signal.sigcode);
            if(sigCodeName != NULL)
            {
                writer->addStringElement(writer, Raygun_KSCrashField_CodeName, sigCodeName);
            }
        }
        writer->endContainer(writer);

        writer->addUIntegerElement(writer, Raygun_KSCrashField_Address, crash->faultAddress);
        if(crash->crashReason != NULL)
        {
            writer->addStringElement(writer, Raygun_KSCrashField_Reason, crash->crashReason);
        }

        // Gather specific info.
        switch(crash->crashType)
        {
            case Raygun_KSCrashMonitorTypeMainThreadDeadlock:
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashExcType_Deadlock);
                break;
                
            case Raygun_KSCrashMonitorTypeMachException:
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashExcType_Mach);
                break;

            case Raygun_KSCrashMonitorTypeCPPException:
            {
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashExcType_CPPException);
                writer->beginObject(writer, Raygun_KSCrashField_CPPException);
                {
                    writer->addStringElement(writer, Raygun_KSCrashField_Name, crash->CPPException.name);
                }
                writer->endContainer(writer);
                break;
            }
            case Raygun_KSCrashMonitorTypeNSException:
            {
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashExcType_NSException);
                writer->beginObject(writer, Raygun_KSCrashField_NSException);
                {
                    writer->addStringElement(writer, Raygun_KSCrashField_Name, crash->NSException.name);
                    writer->addStringElement(writer, Raygun_KSCrashField_UserInfo, crash->NSException.userInfo);
                    writeAddressReferencedByString(writer, Raygun_KSCrashField_ReferencedObject, crash->crashReason);
                }
                writer->endContainer(writer);
                break;
            }
            case Raygun_KSCrashMonitorTypeSignal:
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashExcType_Signal);
                break;

            case Raygun_KSCrashMonitorTypeUserReported:
            {
                writer->addStringElement(writer, Raygun_KSCrashField_Type, Raygun_KSCrashExcType_User);
                writer->beginObject(writer, Raygun_KSCrashField_UserReported);
                {
                    writer->addStringElement(writer, Raygun_KSCrashField_Name, crash->userException.name);
                    if(crash->userException.language != NULL)
                    {
                        writer->addStringElement(writer, Raygun_KSCrashField_Language, crash->userException.language);
                    }
                    if(crash->userException.lineOfCode != NULL)
                    {
                        writer->addStringElement(writer, Raygun_KSCrashField_LineOfCode, crash->userException.lineOfCode);
                    }
                    if(crash->userException.customStackTrace != NULL)
                    {
                        writer->addJSONElement(writer, Raygun_KSCrashField_Backtrace, crash->userException.customStackTrace, true);
                    }
                }
                writer->endContainer(writer);
                break;
            }
            case Raygun_KSCrashMonitorTypeSystem:
            case Raygun_KSCrashMonitorTypeApplicationState:
            case Raygun_KSCrashMonitorTypeZombie:
                RAYGUN_KSLOG_ERROR("Crash monitor type 0x%x shouldn't be able to cause events!", crash->crashType);
                break;
        }
    }
    writer->endContainer(writer);
}

/** Write information about app runtime, etc to the report.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param monitorContext The event monitor context.
 */
static void writeAppStats(const Raygun_KSCrashReportWriter* const writer,
                          const char* const key,
                          const Raygun_KSCrash_MonitorContext* const monitorContext)
{
    writer->beginObject(writer, key);
    {
        writer->addBooleanElement(writer, Raygun_KSCrashField_AppActive, monitorContext->AppState.applicationIsActive);
        writer->addBooleanElement(writer, Raygun_KSCrashField_AppInFG, monitorContext->AppState.applicationIsInForeground);

        writer->addIntegerElement(writer, Raygun_KSCrashField_LaunchesSinceCrash, monitorContext->AppState.launchesSinceLastCrash);
        writer->addIntegerElement(writer, Raygun_KSCrashField_SessionsSinceCrash, monitorContext->AppState.sessionsSinceLastCrash);
        writer->addFloatingPointElement(writer, Raygun_KSCrashField_ActiveTimeSinceCrash, monitorContext->AppState.activeDurationSinceLastCrash);
        writer->addFloatingPointElement(writer, Raygun_KSCrashField_BGTimeSinceCrash, monitorContext->AppState.backgroundDurationSinceLastCrash);

        writer->addIntegerElement(writer, Raygun_KSCrashField_SessionsSinceLaunch, monitorContext->AppState.sessionsSinceLaunch);
        writer->addFloatingPointElement(writer, Raygun_KSCrashField_ActiveTimeSinceLaunch, monitorContext->AppState.activeDurationSinceLaunch);
        writer->addFloatingPointElement(writer, Raygun_KSCrashField_BGTimeSinceLaunch, monitorContext->AppState.backgroundDurationSinceLaunch);
    }
    writer->endContainer(writer);
}

/** Write information about this process.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 */
static void writeProcessState(const Raygun_KSCrashReportWriter* const writer,
                              const char* const key,
                              const Raygun_KSCrash_MonitorContext* const monitorContext)
{
    writer->beginObject(writer, key);
    {
        if(monitorContext->ZombieException.address != 0)
        {
            writer->beginObject(writer, Raygun_KSCrashField_LastDeallocedNSException);
            {
                writer->addUIntegerElement(writer, Raygun_KSCrashField_Address, monitorContext->ZombieException.address);
                writer->addStringElement(writer, Raygun_KSCrashField_Name, monitorContext->ZombieException.name);
                writer->addStringElement(writer, Raygun_KSCrashField_Reason, monitorContext->ZombieException.reason);
                writeAddressReferencedByString(writer, Raygun_KSCrashField_ReferencedObject, monitorContext->ZombieException.reason);
            }
            writer->endContainer(writer);
        }
    }
    writer->endContainer(writer);
}

/** Write basic report information.
 *
 * @param writer The writer.
 *
 * @param key The object key, if needed.
 *
 * @param type The report type.
 *
 * @param reportID The report ID.
 */
static void writeReportInfo(const Raygun_KSCrashReportWriter* const writer,
                            const char* const key,
                            const char* const type,
                            const char* const reportID,
                            const char* const processName)
{
    writer->beginObject(writer, key);
    {
        writer->addStringElement(writer, Raygun_KSCrashField_Version, RAYGUN_KSCRASH_REPORT_VERSION);
        writer->addStringElement(writer, Raygun_KSCrashField_ID, reportID);
        writer->addStringElement(writer, Raygun_KSCrashField_ProcessName, processName);
        writer->addIntegerElement(writer, Raygun_KSCrashField_Timestamp, time(NULL));
        writer->addStringElement(writer, Raygun_KSCrashField_Type, type);
    }
    writer->endContainer(writer);
}

static void writeRecrash(const Raygun_KSCrashReportWriter* const writer,
                         const char* const key,
                         const char* crashReportPath)
{
    writer->addJSONFileElement(writer, key, crashReportPath, true);
}


#pragma mark Setup

/** Prepare a report writer for use.
 *
 * @oaram writer The writer to prepare.
 *
 * @param context JSON writer contextual information.
 */
static void prepareReportWriter(Raygun_KSCrashReportWriter* const writer, Raygun_KSJSONEncodeContext* const context)
{
    writer->addBooleanElement = addBooleanElement;
    writer->addFloatingPointElement = addFloatingPointElement;
    writer->addIntegerElement = addIntegerElement;
    writer->addUIntegerElement = addUIntegerElement;
    writer->addStringElement = addStringElement;
    writer->addTextFileElement = addTextFileElement;
    writer->addTextFileLinesElement = addTextLinesFromFile;
    writer->addJSONFileElement = addJSONElementFromFile;
    writer->addDataElement = addDataElement;
    writer->beginDataElement = beginDataElement;
    writer->appendDataElement = appendDataElement;
    writer->endDataElement = endDataElement;
    writer->addUUIDElement = addUUIDElement;
    writer->addJSONElement = addJSONElement;
    writer->beginObject = beginObject;
    writer->beginArray = beginArray;
    writer->endContainer = endContainer;
    writer->context = context;
}


// ============================================================================
#pragma mark - Main API -
// ============================================================================

void raygun_kscrashreport_writeRecrashReport(const Raygun_KSCrash_MonitorContext* const monitorContext, const char* const path)
{
    char writeBuffer[1024];
    Raygun_KSBufferedWriter bufferedWriter;
    static char tempPath[RAYGUN_KSFU_MAX_PATH_LENGTH];
    strncpy(tempPath, path, sizeof(tempPath) - 10);
    strncpy(tempPath + strlen(tempPath) - 5, ".old", 5);
    RAYGUN_KSLOG_INFO("Writing recrash report to %s", path);

    if(rename(path, tempPath) < 0)
    {
        RAYGUN_KSLOG_ERROR("Could not rename %s to %s: %s", path, tempPath, strerror(errno));
    }
    if(!raygun_ksfu_openBufferedWriter(&bufferedWriter, path, writeBuffer, sizeof(writeBuffer)))
    {
        return;
    }

    raygun_ksccd_freeze();

    Raygun_KSJSONEncodeContext jsonContext;
    jsonContext.userData = &bufferedWriter;
    Raygun_KSCrashReportWriter concreteWriter;
    Raygun_KSCrashReportWriter* writer = &concreteWriter;
    prepareReportWriter(writer, &jsonContext);

    raygun_ksjson_beginEncode(getJsonContext(writer), true, addJSONData, &bufferedWriter);

    writer->beginObject(writer, Raygun_KSCrashField_Report);
    {
        writeRecrash(writer, Raygun_KSCrashField_RecrashReport, tempPath);
        raygun_ksfu_flushBufferedWriter(&bufferedWriter);
        if(remove(tempPath) < 0)
        {
            RAYGUN_KSLOG_ERROR("Could not remove %s: %s", tempPath, strerror(errno));
        }
        writeReportInfo(writer,
                        Raygun_KSCrashField_Report,
                        Raygun_KSCrashReportType_Minimal,
                        monitorContext->eventID,
                        monitorContext->System.processName);
        raygun_ksfu_flushBufferedWriter(&bufferedWriter);

        writer->beginObject(writer, Raygun_KSCrashField_Crash);
        {
            writeError(writer, Raygun_KSCrashField_Error, monitorContext);
            raygun_ksfu_flushBufferedWriter(&bufferedWriter);
            int threadIndex = raygun_ksmc_indexOfThread(monitorContext->offendingMachineContext,
                                                 raygun_ksmc_getThreadFromContext(monitorContext->offendingMachineContext));
            writeThread(writer,
                        Raygun_KSCrashField_CrashedThread,
                        monitorContext,
                        monitorContext->offendingMachineContext,
                        threadIndex,
                        false);
            raygun_ksfu_flushBufferedWriter(&bufferedWriter);
        }
        writer->endContainer(writer);
    }
    writer->endContainer(writer);

    raygun_ksjson_endEncode(getJsonContext(writer));
    raygun_ksfu_closeBufferedWriter(&bufferedWriter);
    raygun_ksccd_unfreeze();
}

static void writeSystemInfo(const Raygun_KSCrashReportWriter* const writer,
                            const char* const key,
                            const Raygun_KSCrash_MonitorContext* const monitorContext)
{
    writer->beginObject(writer, key);
    {
        writer->addStringElement(writer, Raygun_KSCrashField_SystemName, monitorContext->System.systemName);
        writer->addStringElement(writer, Raygun_KSCrashField_SystemVersion, monitorContext->System.systemVersion);
        writer->addStringElement(writer, Raygun_KSCrashField_Machine, monitorContext->System.machine);
        writer->addStringElement(writer, Raygun_KSCrashField_Model, monitorContext->System.model);
        writer->addStringElement(writer, Raygun_KSCrashField_KernelVersion, monitorContext->System.kernelVersion);
        writer->addStringElement(writer, Raygun_KSCrashField_OSVersion, monitorContext->System.osVersion);
        writer->addBooleanElement(writer, Raygun_KSCrashField_Jailbroken, monitorContext->System.isJailbroken);
        writer->addStringElement(writer, Raygun_KSCrashField_BootTime, monitorContext->System.bootTime);
        writer->addStringElement(writer, Raygun_KSCrashField_AppStartTime, monitorContext->System.appStartTime);
        writer->addStringElement(writer, Raygun_KSCrashField_ExecutablePath, monitorContext->System.executablePath);
        writer->addStringElement(writer, Raygun_KSCrashField_Executable, monitorContext->System.executableName);
        writer->addStringElement(writer, Raygun_KSCrashField_BundleID, monitorContext->System.bundleID);
        writer->addStringElement(writer, Raygun_KSCrashField_BundleName, monitorContext->System.bundleName);
        writer->addStringElement(writer, Raygun_KSCrashField_BundleVersion, monitorContext->System.bundleVersion);
        writer->addStringElement(writer, Raygun_KSCrashField_BundleShortVersion, monitorContext->System.bundleShortVersion);
        writer->addStringElement(writer, Raygun_KSCrashField_AppUUID, monitorContext->System.appID);
        writer->addStringElement(writer, Raygun_KSCrashField_CPUArch, monitorContext->System.cpuArchitecture);
        writer->addIntegerElement(writer, Raygun_KSCrashField_CPUType, monitorContext->System.cpuType);
        writer->addIntegerElement(writer, Raygun_KSCrashField_CPUSubType, monitorContext->System.cpuSubType);
        writer->addIntegerElement(writer, Raygun_KSCrashField_BinaryCPUType, monitorContext->System.binaryCPUType);
        writer->addIntegerElement(writer, Raygun_KSCrashField_BinaryCPUSubType, monitorContext->System.binaryCPUSubType);
        writer->addStringElement(writer, Raygun_KSCrashField_TimeZone, monitorContext->System.timezone);
        writer->addStringElement(writer, Raygun_KSCrashField_ProcessName, monitorContext->System.processName);
        writer->addIntegerElement(writer, Raygun_KSCrashField_ProcessID, monitorContext->System.processID);
        writer->addIntegerElement(writer, Raygun_KSCrashField_ParentProcessID, monitorContext->System.parentProcessID);
        writer->addStringElement(writer, Raygun_KSCrashField_DeviceAppHash, monitorContext->System.deviceAppHash);
        writer->addStringElement(writer, Raygun_KSCrashField_BuildType, monitorContext->System.buildType);
        writer->addIntegerElement(writer, Raygun_KSCrashField_Storage, (int64_t)monitorContext->System.storageSize);

        writeMemoryInfo(writer, Raygun_KSCrashField_Memory, monitorContext);
        writeAppStats(writer, Raygun_KSCrashField_AppStats, monitorContext);
    }
    writer->endContainer(writer);

}

static void writeDebugInfo(const Raygun_KSCrashReportWriter* const writer,
                            const char* const key,
                            const Raygun_KSCrash_MonitorContext* const monitorContext)
{
    writer->beginObject(writer, key);
    {
        if(monitorContext->consoleLogPath != NULL)
        {
            addTextLinesFromFile(writer, Raygun_KSCrashField_ConsoleLog, monitorContext->consoleLogPath);
        }
    }
    writer->endContainer(writer);
    
}

void raygun_kscrashreport_writeStandardReport(const Raygun_KSCrash_MonitorContext* const monitorContext, const char* const path)
{
    RAYGUN_KSLOG_INFO("Writing crash report to %s", path);
    char writeBuffer[1024];
    Raygun_KSBufferedWriter bufferedWriter;

    if(!raygun_ksfu_openBufferedWriter(&bufferedWriter, path, writeBuffer, sizeof(writeBuffer)))
    {
        return;
    }

    raygun_ksccd_freeze();
    
    Raygun_KSJSONEncodeContext jsonContext;
    jsonContext.userData = &bufferedWriter;
    Raygun_KSCrashReportWriter concreteWriter;
    Raygun_KSCrashReportWriter* writer = &concreteWriter;
    prepareReportWriter(writer, &jsonContext);

    raygun_ksjson_beginEncode(getJsonContext(writer), true, addJSONData, &bufferedWriter);

    writer->beginObject(writer, Raygun_KSCrashField_Report);
    {
        writeReportInfo(writer,
                        Raygun_KSCrashField_Report,
                        Raygun_KSCrashReportType_Standard,
                        monitorContext->eventID,
                        monitorContext->System.processName);
        raygun_ksfu_flushBufferedWriter(&bufferedWriter);

        writeBinaryImages(writer, Raygun_KSCrashField_BinaryImages);
        raygun_ksfu_flushBufferedWriter(&bufferedWriter);

        writeProcessState(writer, Raygun_KSCrashField_ProcessState, monitorContext);
        raygun_ksfu_flushBufferedWriter(&bufferedWriter);

        writeSystemInfo(writer, Raygun_KSCrashField_System, monitorContext);
        raygun_ksfu_flushBufferedWriter(&bufferedWriter);

        writer->beginObject(writer, Raygun_KSCrashField_Crash);
        {
            writeError(writer, Raygun_KSCrashField_Error, monitorContext);
            raygun_ksfu_flushBufferedWriter(&bufferedWriter);
            writeAllThreads(writer,
                            Raygun_KSCrashField_Threads,
                            monitorContext,
                            g_introspectionRules.enabled);
            raygun_ksfu_flushBufferedWriter(&bufferedWriter);
        }
        writer->endContainer(writer);

        if(g_userInfoJSON != NULL)
        {
            addJSONElement(writer, Raygun_KSCrashField_User, g_userInfoJSON, false);
            raygun_ksfu_flushBufferedWriter(&bufferedWriter);
        }
        else
        {
            writer->beginObject(writer, Raygun_KSCrashField_User);
        }
        if(g_userSectionWriteCallback != NULL)
        {
            raygun_ksfu_flushBufferedWriter(&bufferedWriter);
            if (monitorContext->currentSnapshotUserReported == false) {
                g_userSectionWriteCallback(writer);
            }
        }
        writer->endContainer(writer);
        raygun_ksfu_flushBufferedWriter(&bufferedWriter);

        writeDebugInfo(writer, Raygun_KSCrashField_Debug, monitorContext);
    }
    writer->endContainer(writer);
    
    raygun_ksjson_endEncode(getJsonContext(writer));
    raygun_ksfu_closeBufferedWriter(&bufferedWriter);
    raygun_ksccd_unfreeze();
}



void raygun_kscrashreport_setUserInfoJSON(const char* const userInfoJSON)
{
    static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    RAYGUN_KSLOG_TRACE("set userInfoJSON to %p", userInfoJSON);

    pthread_mutex_lock(&mutex);
    if(g_userInfoJSON != NULL)
    {
        free((void*)g_userInfoJSON);
    }
    if(userInfoJSON == NULL)
    {
        g_userInfoJSON = NULL;
    }
    else
    {
        g_userInfoJSON = strdup(userInfoJSON);
    }
    pthread_mutex_unlock(&mutex);
}

void raygun_kscrashreport_setIntrospectMemory(bool shouldIntrospectMemory)
{
    g_introspectionRules.enabled = shouldIntrospectMemory;
}

void raygun_kscrashreport_setDoNotIntrospectClasses(const char** doNotIntrospectClasses, int length)
{
    const char** oldClasses = g_introspectionRules.restrictedClasses;
    int oldClassesLength = g_introspectionRules.restrictedClassesCount;
    const char** newClasses = NULL;
    int newClassesLength = 0;
    
    if(doNotIntrospectClasses != NULL && length > 0)
    {
        newClassesLength = length;
        newClasses = malloc(sizeof(*newClasses) * (unsigned)newClassesLength);
        if(newClasses == NULL)
        {
            RAYGUN_KSLOG_ERROR("Could not allocate memory");
            return;
        }
        
        for(int i = 0; i < newClassesLength; i++)
        {
            newClasses[i] = strdup(doNotIntrospectClasses[i]);
        }
    }
    
    g_introspectionRules.restrictedClasses = newClasses;
    g_introspectionRules.restrictedClassesCount = newClassesLength;
    
    if(oldClasses != NULL)
    {
        for(int i = 0; i < oldClassesLength; i++)
        {
            free((void*)oldClasses[i]);
        }
        free(oldClasses);
    }
}

void raygun_kscrashreport_setUserSectionWriteCallback(const Raygun_KSReportWriteCallback userSectionWriteCallback)
{
    RAYGUN_KSLOG_TRACE("Set userSectionWriteCallback to %p", userSectionWriteCallback);
    g_userSectionWriteCallback = userSectionWriteCallback;
}
