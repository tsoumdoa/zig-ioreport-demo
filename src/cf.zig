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
    if (cf_srt == null) return "";
    const len = @as(usize, @intCast(CFStringGetLength(cf_srt)));
    var buffer: [128:0]u8 = undefined;
    const success = CFStringGetCString(cf_srt, &buffer, buffer.len, kCFStringEncodingUTF8);
    _ = success;

    const alloc_buf = try allocator.alloc(u8, len);
    @memcpy(alloc_buf, buffer[0..len]);
    return alloc_buf;
}
