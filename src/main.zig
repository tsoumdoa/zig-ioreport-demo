const std = @import("std");
const ArrayList = std.ArrayList;

const IOKit = @import("io-kit.zig");

const CfDic = @import("cf-dic.zig");
const CFMutableDictionaryRef = CfDic.CFMutableDictionaryRef;
const CFDictionaryRef = CfDic.CFDictionaryRef;
const CFStringRef = CfDic.CFStringRef;
const CFTypeRef = CfDic.CFTypeRef;
const CVoidRef = CfDic.CVoidRef;

const IOReportSubscription = extern struct {
    _data: [*c]u8,
    _phantom: u8,
};
// seems unncesary to do this
// const IOReportSubscriptionRef = *const IOReportSubscription;

//IReport bindings
pub extern "c" fn IOReportCopyAllChannels(a: u64, b: u64) CFDictionaryRef;
pub extern "c" fn IOReportCopyChannelsInGroup(a: CFStringRef, b: CFStringRef, c: u64, d: u64, e: u64) CFDictionaryRef;
pub extern "c" fn IOreportMergeChannels(a: CFDictionaryRef, b: CFDictionaryRef, nil: CFTypeRef) void;
pub extern "c" fn IOReportCreateSubscription(a: CVoidRef, b: CFMutableDictionaryRef, c: *CFMutableDictionaryRef, d: u64, e: CFTypeRef) callconv(.C) IOReportSubscription;
pub extern "c" fn IOReportCreateSamples(a: IOReportSubscription, b: CFMutableDictionaryRef, c: CFTypeRef) callconv(.C) CFDictionaryRef;
pub extern "c" fn IOReportCreateSamplesDelta(a: CFDictionaryRef, b: CFDictionaryRef) CFDictionaryRef;
pub extern "c" fn IOReportChannelGetGroup(a: CFDictionaryRef) CFStringRef;
pub extern "c" fn IOReportChannelGetSubGroup(a: CFDictionaryRef) CFStringRef;
pub extern "c" fn IOReportChannelGetChannelName(a: CFDictionaryRef) CFStringRef;
pub extern "c" fn IOReportSimpleGetIntegerValue(a: CFDictionaryRef, b: i32) i64;
pub extern "c" fn IOReportChannelGetUnitLabel(a: CFDictionaryRef) CFStringRef;
pub extern "c" fn IOReportStateGetCount(a: CFDictionaryRef) i32;
pub extern "c" fn IOReportStateGetNameForIndex(a: CFDictionaryRef, b: i32) CFStringRef;
pub extern "c" fn IOReportStateGetResidency(a: CFDictionaryRef, b: i32) i64;
pub extern "c" fn CFShow(obj: CFDictionaryRef) void;

const CFIndex = isize;
const CFAllocatorRef = *const anyopaque;
const CFStringEncoding = u32;

//CoreFoundation bindings
extern "c" fn CFDictionaryGetCount(theDict: CFDictionaryRef) CFIndex;
extern "c" fn CFDictionaryCreateMutableCopy(allocator: CFAllocatorRef, capacity: CFIndex, theDict: CFDictionaryRef) CFMutableDictionaryRef;
extern "c" fn CFRelease(cf: CFTypeRef) void;
extern "c" fn CFStringCreateWithBytesNoCopy(
    alloc: CFAllocatorRef,
    bytes: [*c]const u8,
    numBytes: CFIndex,
    encoding: CFStringEncoding,
    isExternalRepresentation: bool,
    contentsDeallocator: CFAllocatorRef,
) CFStringRef;
extern "c" fn CFDictionaryGetValue(theDict: CFDictionaryRef, key: CFStringRef) CFTypeRef;

const kCFAllocatorDefault: CFAllocatorRef = @as(*anyopaque, undefined);
const kCFStringEncodingUTF8: CFStringEncoding = 0x08000100;
const kCFAllocatorNull: CFAllocatorRef = @as(*anyopaque, undefined);

inline fn cfString(str: []const u8) CFStringRef {
    const str_len = str.len;
    const quo = str_len / 8;
    const mod = str_len % 8;
    const aligned_len = 8 * (quo + (if (mod == 0) 0 else 1));

    return CFStringCreateWithBytesNoCopy(
        kCFAllocatorDefault,
        @as([*c]const u8, @ptrCast((str.ptr))),
        @as(isize, @intCast(aligned_len)),
        kCFStringEncodingUTF8,
        false,
        kCFAllocatorNull,
    );
}

pub fn main() !void {
    const grp = "CPU Stats";
    const sub_grp = "CPU Core Performance States";
    const grp_cf = cfString(grp);
    const sub_grp_cf = cfString(sub_grp);

    std.debug.print("grp: {any}\n", .{grp_cf});
    std.debug.print("sub_grp: {any}\n", .{sub_grp_cf});
    const all_chan = IOReportCopyChannelsInGroup(grp_cf, sub_grp_cf, 0, 0, 0);
    // const all_chan = IOReportCopyAllChannels(0, 0);
    const mut_chan = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, CFDictionaryGetCount(all_chan), all_chan);
    // CFRelease(grp_cf);
    // CFRelease(sub_grp_cf);

    // const size = CFDictionaryGetCount(chan);
    // const mut_chan = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, size, chan);
    CFRelease(mut_chan);
    CFShow(mut_chan);

    // std.debug.print("mut_chan: {*}\n", .{mut_chan});

    const key = cfString("IOReportChannels");
    // defer std.c.free(key);
    const val = CFDictionaryGetValue(mut_chan, key);

    std.debug.print("count: {any}\n", .{val});
    // const count = CFDictionaryGetCount(chan);
    // std.debug.print("count: {d}\n", .{count});
    // CFShow(chan);
    // std.debug.print("kv_pair: {any}_{any}\n", .{ key, val });
    // _ = key;
    // _ = val;
    // std.debug.print("val: {any}\n", .{val});
    // std.debug.print("val: {any}\n", .{count});
    const show = CFShow(mut_chan);
    _ = show;

    // var s: CFMutableDictionaryRef = @as(CFMutableDictionaryRef, undefined);
    // const rs = IOReportCreateSubscription(undefined, mut_chan, &s, 0, undefined);
    // _ = rs;
    // const show = CFShow(rs);
    // _ = show;
    // std.debug.print("{any},{any}, size{d}\n", .{ rs, chan, size });

    // const sample_1 = IOReportCreateSamples(rs, mut_chan, undefined);
    // const sample_2 = IOReportCreateSamples(rs, mut_chan, undefined);

    // std.debug.print("ioreport: {any}\n", .{sample_2});
    // const d = IOReportCreateSamplesDelta(sample_1, sample_2);
    // std.debug.print("ioreport: {any}\n", .{d});
    // std.debug.print(" size{any}\n", .{mut_chan});
}

// test "IOKit" {
//     var cf_mutable_dictionary_ref = IOKit.IOServiceMatching("AppleSMC");
//
//     const io_iterator_next = IOKit.IOIteratorNext(0);
//     _ = io_iterator_next;
//
//     var existing: u32 = 0;
//     const io_service_get_matching_services = IOKit.IOServiceGetMatchingServices(0, cf_mutable_dictionary_ref, &existing);
//     _ = io_service_get_matching_services;
//
//     var name: [*:0]u8 = undefined;
//     const io_registry_entry_get_name = IOKit.IORegistryEntryGetName(0, &name);
//     _ = io_registry_entry_get_name;
//
//     const io_registry_entry_create_cf_properties = IOKit.IORegistryEntryCreateCFProperties(0, &cf_mutable_dictionary_ref, 0, 0);
//     _ = io_registry_entry_create_cf_properties;
//
//     const io_object_release = IOKit.IOObjectRelease(0);
//     _ = io_object_release;
// }
//
// test "IOReport" {}
