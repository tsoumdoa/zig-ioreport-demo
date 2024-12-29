const CF = @import("cf.zig");
const CFDictionaryRef = CF.CFDictionaryRef;
const CFStringRef = CF.CFStringRef;
const CFTypeRef = CF.CFTypeRef;
const CVoidRef = CF.CVoidRef;
const CFMutableDictionaryRef = CF.CFMutableDictionaryRef;

//IReport bindings
pub const IOReportSubscription = extern struct {
    _data: [*c]u8,
    _phantom: u8,
};
const IOReportSubscriptionRef = *const IOReportSubscription;
pub extern "objc" fn IOReportCopyAllChannels(a: u64, b: u64) CFDictionaryRef;
pub extern "objc" fn IOReportCopyChannelsInGroup(a: CFStringRef, b: CFStringRef, c: u64, d: u64, e: u64) CFDictionaryRef;
pub extern "objc" fn IOReportMergeChannels(a: CFDictionaryRef, b: CFDictionaryRef, nil: CFTypeRef) void;
pub extern "objc" fn IOReportCreateSubscription(a: CVoidRef, b: CFMutableDictionaryRef, c: *CFMutableDictionaryRef, d: u64, e: CFTypeRef) callconv(.C) IOReportSubscriptionRef;
pub extern "objc" fn IOReportCreateSamples(a: IOReportSubscriptionRef, b: CFMutableDictionaryRef, c: CFTypeRef) callconv(.C) CFDictionaryRef;
pub extern "objc" fn IOReportCreateSamplesDelta(a: CFDictionaryRef, b: CFDictionaryRef, c: CFTypeRef) CFDictionaryRef;
pub extern "objc" fn IOReportChannelGetGroup(a: CFDictionaryRef) CFStringRef;
pub extern "objc" fn IOReportChannelGetSubGroup(a: CFDictionaryRef) CFStringRef;
pub extern "objc" fn IOReportChannelGetChannelName(a: CFDictionaryRef) CFStringRef;
pub extern "objc" fn IOReportSimpleGetIntegerValue(a: CFDictionaryRef, b: i32) i64;
pub extern "objc" fn IOReportChannelGetUnitLabel(a: CFDictionaryRef) CFStringRef;
pub extern "objc" fn IOReportStateGetCount(a: CFDictionaryRef) i32;
pub extern "objc" fn IOReportStateGetNameForIndex(a: CFDictionaryRef, b: i32) CFStringRef;
pub extern "objc" fn IOReportStateGetResidency(a: CFDictionaryRef, b: i32) i64;
