const std = @import("std");
const ArrayList = std.ArrayList;
const assert = std.debug.assert;

const IOKit = @import("io-kit.zig");
const cf = @import("cf.zig");
const ior = @import("io-report.zig");
const CFMutableDictionaryRef = cf.CFMutableDictionaryRef;
const CFDictionaryRef = cf.CFDictionaryRef;
const CFStringRef = cf.CFStringRef;
const CFTypeRef = cf.CFTypeRef;
const CVoidRef = cf.CVoidRef;
const CFArrayRef = cf.CFArrayRef;
const cfString = cf.cfString;
const CFRelease = cf.CFRelease;
const CFArrayGetCount = cf.CFArrayGetCount;
const CFShow = cf.CFShow;
const CFRetain = cf.CFRetain;

const IOReportIterator = struct {
    report: CFArrayRef,
    index: usize,
    length: usize,
    fn init(report: CFArrayRef) IOReportIterator {
        return IOReportIterator{
            .report = report,
            .index = 0,
            .length = @as(usize, @intCast(CFArrayGetCount(report))),
        };
    }
    fn next(self: *IOReportIterator) void {
        self.index += 1;
    }
};
const IorData = struct {
    group: []const u8,
    subgroup: []const u8,
    channel: []const u8,
    unit: []const u8,
    item: CFDictionaryRef,
};

const IO_REPORTS = .{ .{ "Energy Model", "" }, .{ "CPU Stats", "CPU Core Performance States" }, .{ "CPU Stats", "CPU Core Performance States" }, .{ "GPU Stats", "GPU Performance States" } };

pub inline fn sampleIOR(rs: *const ior.IOReportSubscription, mut_chan: cf.CFMutableDictionaryRef) CFArrayRef {
    const sample_1 = ior.IOReportCreateSamples(rs, mut_chan, undefined);
    std.time.sleep(10 * std.time.ns_per_ms);
    const sample_2 = ior.IOReportCreateSamples(rs, mut_chan, undefined);
    const d = ior.IOReportCreateSamplesDelta(sample_1, sample_2, undefined);
    CFRelease(sample_1);
    CFRelease(sample_2);
    assert(d != null);
    const key_ior_chan = cfString("IOReportChannels");
    const io_arry = @as(CFArrayRef, @ptrCast(cf.CFDictionaryGetValue(d, key_ior_chan)));
    CFRelease(key_ior_chan);
    return io_arry;
}

pub fn main() !void {
    var gpa_impl: std.heap.GeneralPurposeAllocator(.{}) = .{};
    const gpa = gpa_impl.allocator();

    var chan_dicts = ArrayList(CFDictionaryRef).init(gpa);

    inline for (IO_REPORTS) |report| {
        const grp = cfString(report[0]);
        const sub_grp = if (report[1].len == 0) null else cfString(report[1]);
        const chan = ior.IOReportCopyChannelsInGroup(grp, sub_grp, 0, 0, 0);
        CFRelease(grp);
        if (sub_grp) |s| CFRelease(s);
        try chan_dicts.append(chan);
    }

    const chan = chan_dicts.items[0];

    for (chan_dicts.items[1..]) |c| {
        ior.IOReportMergeChannels(chan, c, undefined);
        CFRelease(c);
    }
    chan_dicts.deinit();
    const key_ior_chan = cfString("IOReportChannels");
    const val = cf.CFDictionaryGetValue(chan, key_ior_chan);
    assert(val != null);
    CFRelease(key_ior_chan);

    const size = cf.CFDictionaryGetCount(chan);
    const mut_chan = cf.CFDictionaryCreateMutableCopy(cf.kCFAllocatorDefault, size, chan);
    CFRelease(chan);

    var s: CFMutableDictionaryRef = @as(CFMutableDictionaryRef, undefined);
    const rs = ior.IOReportCreateSubscription(undefined, mut_chan, &s, 0, undefined);
    CFRelease(s);

    defer CFRelease(mut_chan);
    defer CFRelease(rs);

    var itter: usize = 0;

    while (true) : (itter += 1) {
        var arena_impl = std.heap.ArenaAllocator.init(gpa);
        const arena = arena_impl.allocator();
        var iors = std.ArrayList(*IorData).init(arena);

        const io_arry = sampleIOR(rs, mut_chan);
        var io_it = IOReportIterator.init(io_arry);

        while (io_it.index < io_it.length) : (io_it.next()) {
            const cf_val = cf.CFArrayGetValueAtIndex(io_it.report, @as(isize, @intCast(io_it.index)));
            const item = @as(CFDictionaryRef, @ptrCast(cf_val));

            // no need to CFRelease cfstr
            const group_cfstr = ior.IOReportChannelGetGroup(item);
            const group = try cf.decodeCfstr(group_cfstr, arena);

            const subgroup_cfstr = ior.IOReportChannelGetSubGroup(item);
            const subgroup = try cf.decodeCfstr(subgroup_cfstr, arena);

            const channel_cfstr = ior.IOReportChannelGetChannelName(item);
            const channel = try cf.decodeCfstr(channel_cfstr, arena);

            const unit_cfstr = ior.IOReportChannelGetUnitLabel(item);
            const unit = try cf.decodeCfstr(unit_cfstr, arena);

            const ior_data = IorData{
                .group = group,
                .subgroup = subgroup,
                .channel = channel,
                .unit = unit,
                .item = item,
            };
            const value = try arena.create(IorData);
            value.* = ior_data;
            try iors.append(value);
        }
        for (iors.items) |item| {
            std.debug.print("group: {s}, subgroup: {s}, channel: {s}, unit: {s}, item:{any}\n", .{ item.group, item.subgroup, item.channel, item.unit, item.item });
        }
        // this stops memory leaks but crashes
        CFRelease(io_arry);
        arena_impl.deinit();
    }
}
