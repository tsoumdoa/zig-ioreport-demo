const c = @cImport({
    @cInclude("IOKit/IOKitLib.h");
    @cInclude("CoreFoundation/CoreFoundation.h");
});

pub const CFStringRef = c.CFStringRef;
pub const CFMutableDictionaryRef = c.CFMutableDictionaryRef;
pub const CFDictionaryRef = c.CFMutableDictionaryRef;
pub const CFTypeRef = c.CFTypeRef;
pub const CVoidRef = *anyopaque;
