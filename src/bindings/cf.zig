const c = @cImport({
    @cInclude("IOKit/IOKitLib.h");
    @cInclude("CoreFoundation/CoreFoundation.h");
});
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CFHashCode = usize;
pub const CFStringRef = c.CFStringRef;
pub const CFNumberRef = *const c.__CFNumber;
pub const CFNumberType = u32;
pub const CFMutableDictionaryRef = c.CFMutableDictionaryRef;
pub const CFDictionaryRef = c.CFDictionaryRef;
pub const CFTypeRef = c.CFTypeRef;
pub const CVoidRef = *anyopaque;
pub const CFIndex = isize;
pub const CFAllocatorRef = *const anyopaque;
pub const CFStringEncoding = u32;
pub const CFArray = c.__CFArray;
pub const CFArrayRef = *const CFArray;
pub const CFDataRef = *const c.__CFData;
pub const CFRange = extern struct {
    location: CFIndex,
    length: CFIndex,
};

// members of enum CFNumberType
pub const kCFNumberSInt8Type: CFNumberType = 1;
pub const kCFNumberSInt16Type: CFNumberType = 2;
pub const kCFNumberSInt32Type: CFNumberType = 3;
pub const kCFNumberSInt64Type: CFNumberType = 4;
pub const kCFNumberFloat32Type: CFNumberType = 5;
pub const kCFNumberFloat64Type: CFNumberType = 6;
pub const kCFNumberCharType: CFNumberType = 7;
pub const kCFNumberShortType: CFNumberType = 8;
pub const kCFNumberIntType: CFNumberType = 9;
pub const kCFNumberLongType: CFNumberType = 10;
pub const kCFNumberLongLongType: CFNumberType = 11;
pub const kCFNumberFloatType: CFNumberType = 12;
pub const kCFNumberDoubleType: CFNumberType = 13;
pub const kCFNumberCFIndexType: CFNumberType = 14;
pub const kCFNumberNSIntegerType: CFNumberType = 15;
pub const kCFNumberCGFloatType: CFNumberType = 16;
pub const kCFNumberMaxType: CFNumberType = 16;

pub const CFDictionaryRetainCallBack = fn (allocator: CFAllocatorRef, value: *const anyopaque) callconv(.C) void;
pub const CFDictionaryReleaseCallBack = fn (allocator: CFAllocatorRef, value: *const anyopaque) callconv(.C) void;
pub const CFDictionaryCopyDescriptionCallBack = fn (allocator: CFAllocatorRef, value: *const anyopaque) callconv(.C) CFStringRef;
pub const CFDictionaryEqualCallBack = fn (allocator: CFAllocatorRef, value1: *const anyopaque, value2: *const anyopaque) callconv(.C) bool;
pub const CFDictionaryHashCallBack = fn (value: *const anyopaque) callconv(.C) CFHashCode;
pub const CFDictionaryKeyCallBacks = struct {
    version: *const CFIndex,
    retain: *const CFDictionaryRetainCallBack,
    release: *const CFDictionaryReleaseCallBack,
    copyDescription: *const CFDictionaryCopyDescriptionCallBack,
    equal: *const CFDictionaryEqualCallBack,
    hash: *const CFDictionaryHashCallBack,
};

pub const CFDictionaryValueCallBacks = struct {
    version: *const *const CFIndex,
    retain: *const CFDictionaryRetainCallBack,
    release: *const CFDictionaryReleaseCallBack,
    copyDescription: *const CFDictionaryCopyDescriptionCallBack,
    equal: *const CFDictionaryEqualCallBack,
};

//CoreFoundation bindings
pub extern "objc" fn CFDictionaryGetCount(theDict: CFDictionaryRef) CFIndex;

pub extern "objc" fn CFDictionaryCreate(
    allocator: CFAllocatorRef,
    keys: *const anyopaque,
    values: *const anyopaque,
    numValues: CFIndex,
    keyCallBacks: *const CFDictionaryKeyCallBacks,
    valueCallBacks: *const CFDictionaryValueCallBacks,
) CFDictionaryRef;
pub extern "objc" fn CFDictionaryCreateMutableCopy(allocator: CFAllocatorRef, capacity: CFIndex, theDict: CFDictionaryRef) callconv(.C) CFMutableDictionaryRef;
pub extern "objc" fn CFRelease(cf: CFTypeRef) void;
pub extern "objc" fn CFRetain(obj: CFTypeRef) void;
pub extern "objc" fn CFGetRetainCount(obj: CFTypeRef) CFIndex;
pub extern "objc" fn CFMakeCollectable(obj: CFTypeRef) CFTypeRef;
pub extern "objc" fn CFArrayGetCount(theArray: CFArrayRef) CFIndex;
pub extern "objc" fn CFArrayGetValueAtIndex(theArray: CFArrayRef, index: CFIndex) CFTypeRef;
pub extern "objc" fn CFStringCreateWithBytesNoCopy(alloc: CFAllocatorRef, bytes: *const u8, numBytes: CFIndex, encoding: CFStringEncoding, isExternalRepresentation: bool, contentsDeallocator: CFAllocatorRef) CFStringRef;
pub extern "objc" fn CFStringCreateWithCharacters(alloc: CFAllocatorRef, chars: *const u16, numChars: CFIndex) CFStringRef;
pub extern "objc" fn CFDictionaryGetValue(theDict: CFDictionaryRef, key: CFStringRef) CFTypeRef;
pub extern "objc" fn CFShow(obj: CFTypeRef) void;
pub extern "objc" fn CFStringGetLength(theString: CFStringRef) CFIndex;
pub extern "objc" fn CFStringGetCString(theString: CFStringRef, buffer: *anyopaque, bufferSize: CFIndex, encoding: CFStringEncoding) callconv(.C) bool;
pub extern "objc" fn CFDataGetLength(theData: CFDataRef) CFIndex;
pub extern "objc" fn CFDataGetBytes(theData: CFDataRef, range: CFRange, buffer: *u8) callconv(.C) void;
pub extern "objc" fn CFNumberCreate(allocator: CFAllocatorRef, theType: CFNumberType, valuePtr: *const i32) callconv(.C) CFNumberRef;

pub const kCFAllocatorDefault: CFAllocatorRef = @as(*anyopaque, undefined);
pub const kCFStringEncodingUTF8: CFStringEncoding = 0x08000100;
pub const kCFAllocatorNull: CFAllocatorRef = @as(*anyopaque, undefined);

//helper functios
pub inline fn cfString(str: []const u8) CFStringRef {
    const unicode = std.unicode.utf8ToUtf16LeStringLiteral(str);
    return CFStringCreateWithCharacters(
        kCFAllocatorDefault,
        @as([*c]const u16, @ptrCast(unicode.ptr)),
        @as(isize, @intCast(unicode.len)),
    );
}
pub inline fn cfNum(val: *const i32) CFNumberRef {
    return CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, val);
}

const CfioParseError = error{
    OutOfMemory,
    NullGroup,
    NullSubGroup,
    NullChannel,
    NullUnit,
};

pub inline fn decodeCfstr(cf_srt: CFStringRef, allocator: Allocator) ![]const u8 {
    if (cf_srt == null) return "";
    const len = @as(usize, @intCast(CFStringGetLength(cf_srt)));
    var buffer: [128:0]u8 = undefined;
    const success = CFStringGetCString(cf_srt, &buffer, buffer.len, kCFStringEncodingUTF8);
    _ = success;

    const alloc_buf = try allocator.alloc(u8, len);
    @memcpy(alloc_buf, buffer[0..len]);
    return alloc_buf;
}
