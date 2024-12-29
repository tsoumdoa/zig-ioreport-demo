const c = @cImport({
    @cInclude("IOKit/IOKitLib.h");
    @cInclude("CoreFoundation/CoreFoundation.h");
});
const std = @import("std");
const Allocator = std.mem.Allocator;

pub const CFStringRef = c.CFStringRef;
pub const CFMutableDictionaryRef = c.CFMutableDictionaryRef;
pub const CFDictionaryRef = c.CFDictionaryRef;
pub const CFTypeRef = c.CFTypeRef;
pub const CVoidRef = *anyopaque;
pub const CFIndex = isize;
pub const CFAllocatorRef = *const anyopaque;
pub const CFStringEncoding = u32;
pub const CFArray = c.__CFArray;
pub const CFArrayRef = *const CFArray;

//CoreFoundation bindings
pub extern "objc" fn CFDictionaryGetCount(theDict: CFDictionaryRef) CFIndex;
pub extern "objc" fn CFDictionaryCreateMutableCopy(allocator: CFAllocatorRef, capacity: CFIndex, theDict: CFDictionaryRef) callconv(.C) CFMutableDictionaryRef;
pub extern "objc" fn CFRelease(cf: CFTypeRef) void;
pub extern "objc" fn CFArrayGetCount(theArray: CFArrayRef) CFIndex;
pub extern "objc" fn CFArrayGetValueAtIndex(theArray: CFArrayRef, index: CFIndex) CFTypeRef;
pub extern "objc" fn CFStringCreateWithBytesNoCopy(alloc: CFAllocatorRef, bytes: *const u8, numBytes: CFIndex, encoding: CFStringEncoding, isExternalRepresentation: bool, contentsDeallocator: CFAllocatorRef) CFStringRef;
pub extern "objc" fn CFStringCreateWithCharacters(alloc: CFAllocatorRef, chars: *const u16, numChars: CFIndex) CFStringRef;
pub extern "objc" fn CFDictionaryGetValue(theDict: CFDictionaryRef, key: CFStringRef) CFTypeRef;
pub extern "objc" fn CFShow(obj: CFTypeRef) void;
pub extern "objc" fn CFRetain(obj: CFTypeRef) void;
pub extern "objc" fn CFStringGetLength(theString: CFStringRef) CFIndex;
pub extern "objc" fn CFStringGetCString(theString: CFStringRef, buffer: *anyopaque, bufferSize: CFIndex, encoding: CFStringEncoding) callconv(.C) bool;
pub extern "objc" fn IOReportChannelGetGroup(a: CFDictionaryRef) CFStringRef;
pub extern "objc" fn IOReportChannelGetSubGroup(a: CFDictionaryRef) CFStringRef;
pub extern "objc" fn IOReportChannelGetChannelName(a: CFDictionaryRef) CFStringRef;
pub extern "objc" fn IOReportChannelGetUnitLabel(a: CFDictionaryRef) CFStringRef;

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
const CfioParseError = error{
    OutOfMemory,
    NullGroup,
    NullSubGroup,
    NullChannel,
    NullUnit,
};

pub inline fn decodeCfstr(cf_srt: CFStringRef, allocator: Allocator) ![]const u8 {
    const len = @as(usize, @intCast(CFStringGetLength(cf_srt)));
    var buffer: [128:0]u8 = undefined;
    const success = CFStringGetCString(cf_srt, &buffer, buffer.len, kCFStringEncodingUTF8);
    //todo check for success and return error
    _ = success;
    const alloc_buf = try allocator.alloc(u8, len);
    @memcpy(alloc_buf, buffer[0..len]);
    return alloc_buf;
}

pub inline fn cfioGetGroup(item: CFDictionaryRef, allocator: Allocator) CfioParseError![]const u8 {
    if (item == null) return CfioParseError.NullGroup;
    const cfstr = IOReportChannelGetGroup(item);
    defer CFRelease(cfstr);
    return decodeCfstr(cfstr, allocator);
}

pub inline fn cfioGetSubgroup(item: CFDictionaryRef, allocator: Allocator) CfioParseError![]const u8 {
    if (item == null) return CfioParseError.NullSubGroup;
    const subgroup = IOReportChannelGetSubGroup(item);
    if (subgroup == null) return "";
    const cfstr = IOReportChannelGetSubGroup(item);
    defer CFRelease(cfstr);
    return decodeCfstr(cfstr, allocator);
}

pub inline fn cfioGetChannel(item: CFDictionaryRef, allocator: Allocator) CfioParseError![]const u8 {
    if (item == null) return CfioParseError.NullChannel;
    const cfstr = IOReportChannelGetChannelName(item);
    defer CFRelease(cfstr);
    return decodeCfstr(cfstr, allocator);
}

pub inline fn cfioGetUnit(item: CFDictionaryRef, allocator: Allocator) CfioParseError![]const u8 {
    if (item == null) return CfioParseError.NullUnit;
    const cfstr = IOReportChannelGetUnitLabel(item);
    defer CFRelease(cfstr);
    return decodeCfstr(cfstr, allocator);
}
