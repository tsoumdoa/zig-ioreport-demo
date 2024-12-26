const c = @cImport({
    @cInclude("IOKit/IOKitLib.h");
    @cInclude("CoreFoundation/CoreFoundation.h");
});
const std = @import("std");

pub const CFStringRef = c.CFStringRef;
pub const CFMutableDictionaryRef = c.CFMutableDictionaryRef;
pub const CFDictionaryRef = c.CFMutableDictionaryRef;
pub const CFTypeRef = c.CFTypeRef;
pub const CVoidRef = *anyopaque;
