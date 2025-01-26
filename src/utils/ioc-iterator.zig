const std = @import("std");
const iok = @import("../bindings/io-kit.zig");
const cf = @import("../bindings/cf.zig");
const Tag = enum { Ok, End };

const IocIteratorResult = union(Tag) {
    Ok: [*c]const u8,
    End: void,
};

pub const IocIterator = struct {
    io_services: cf.CFDictionaryRef,
    existing_val: u32,
    next_val: u32,

    pub fn init(service_name: []const u8) !IocIterator {
        const io_services = iok.IOServiceMatching(@as([*c]const u8, @ptrCast(service_name)));
        var existing: u32 = 0;
        if (iok.IOServiceGetMatchingServices(0, io_services, &existing) != 0) std.debug.panic("no services found", .{});
        return IocIterator{
            .io_services = io_services,
            .existing_val = existing,
            .next_val = 0,
        };
    }

    pub fn next(self: *IocIterator) !IocIteratorResult {
        self.next_val = iok.IOIteratorNext(self.existing_val);
        var buffer: [128:0]i8 = undefined;
        if (iok.IORegistryEntryGetName(self.next_val, &buffer) != 0) {
            return IocIteratorResult{ .End = undefined };
        } else {
            const casted = @as([*c]u8, @ptrCast(buffer[0..]));
            return IocIteratorResult{ .Ok = casted };
        }
    }
};
