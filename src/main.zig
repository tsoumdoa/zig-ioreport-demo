const std = @import("std");
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

const IOKit = @import("io-kit.zig");
const cf = @import("cf.zig");
const IOReport = @import("io-report.zig");
const CFMutableDictionaryRef = cf.CFMutableDictionaryRef;
const CFDictionaryRef = cf.CFDictionaryRef;
const CFStringRef = cf.CFStringRef;
const CFTypeRef = cf.CFTypeRef;
const CVoidRef = cf.CVoidRef;
const IOReportCopyChannelsInGroup = IOReport.IOReportCopyChannelsInGroup;
const cfString = cf.cfString;
const CFRelease = cf.CFRelease;
const CFShow = cf.CFShow;
const CFDictionaryCreateMutableCopy = cf.CFDictionaryCreateMutableCopy;
const CFDictionaryGetCount = cf.CFDictionaryGetCount;
const IOReportCopyAllChannels = IOReport.IOReportCopyAllChannels;
const IOReportCreateSubscription = IOReport.IOReportCreateSubscription;
const IOReportCreateSamples = IOReport.IOReportCreateSamples;
const IOReportCreateSamplesDelta = IOReport.IOReportCreateSamplesDelta;
const kCFAllocatorDefault = cf.kCFAllocatorDefault;
const CFDictionaryGetValue = cf.CFDictionaryGetValue;
const IOReportStateGetNameForIndex = IOReport.IOReportStateGetNameForIndex;
const IOReportChannelGetGroup = IOReport.IOReportChannelGetGroup;

pub fn main() !void {
    const grp = cfString("Energy Model");
    // const sub_grp = cfString("CPU Core Performance States");
    const chan = IOReportCopyChannelsInGroup(grp, null, 0, 0, 0);
    const key = cfString("IOReportChannels");
    defer std.c.free(@as(?*anyopaque, @constCast(key)));
    const val = CFDictionaryGetValue(chan, key);
    assert(val != null);
    defer CFRelease(chan);

    const size = CFDictionaryGetCount(chan);
    const mut_chan = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, size, chan);

    var s: CFMutableDictionaryRef = @as(CFMutableDictionaryRef, undefined);
    const rs = IOReportCreateSubscription(undefined, mut_chan, &s, 0, undefined);

    const sample_1 = IOReportCreateSamples(rs, mut_chan, undefined);
    std.time.sleep(100 * std.time.ns_per_ms);
    const sample_2 = IOReportCreateSamples(rs, mut_chan, undefined);
    const d = IOReportCreateSamplesDelta(sample_1, sample_2, undefined);
    CFShow(d);
}
