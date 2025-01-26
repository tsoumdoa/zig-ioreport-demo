const std = @import("std");
const ArrayList = std.ArrayList;
const cf = @import("../bindings/cf.zig");
const hid = @import("../bindings/io-hid.zig");
const cfStr = cf.cfString;
const cfNum = cf.cfNum;

const kHIDPage_AppleVendor: i32 = 0xff00;
const kHIDUsage_AppleVendor_TemperatureSensor: i32 = 0x0005;

pub inline fn getHidSensors() !cf.CFDictionaryRef {
    const cf_keys = .{ cfStr("PrimaryUsagePage"), cfStr("PrimaryUsage") };
    const cf_nums = .{ cfNum(&kHIDPage_AppleVendor), cfNum(&kHIDUsage_AppleVendor_TemperatureSensor) };
    const kCFTypeDictionaryKeyCallBacks = cf.CFDictionaryKeyCallBacks{ .version = undefined, .retain = undefined, .release = undefined, .copyDescription = undefined, .equal = undefined, .hash = undefined };
    const kCFTypeDictionaryValueCallBacks = cf.CFDictionaryValueCallBacks{ .version = undefined, .retain = undefined, .release = undefined, .copyDescription = undefined, .equal = undefined };

    const dic = cf.CFDictionaryCreate(cf.kCFAllocatorDefault, &cf_keys, &cf_nums, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    return dic;
}

const HIDSensorsReading = struct { key: []const u8, val: f32 };
const kIOHIDEventTypeTemperature: i64 = 15;

pub const HIDSensors = struct {
    hid_sensors: cf.CFDictionaryRef,
    pub inline fn init() !HIDSensors {
        return HIDSensors{ .hid_sensors = try getHidSensors() };
    }

    pub inline fn sample(self: *HIDSensors, alloc: std.mem.Allocator) ![]*HIDSensorsReading {
        const system = hid.IOHIDEventSystemClientCreate(cf.kCFAllocatorDefault);
        const match = hid.IOHIDEventSystemClientSetMatching(system, self.hid_sensors);
        _ = match;
        const services = hid.IOHIDEventSystemClientCopyServices(system);

        var sensor_readings = ArrayList(*HIDSensorsReading).init(alloc);
        const count = cf.CFArrayGetCount(services);
        for (0..@as(usize, @intCast(count))) |i| {
            const cast_i = @as(i32, @intCast(i));
            const v = cf.CFArrayGetValueAtIndex(services, cast_i);
            const v_cast = @as(hid.IOHIDServiceClientRef, @ptrCast(v));
            const b = cf.cfString("Product");
            const name = hid.IOHIDServiceClientCopyProperty(v_cast, b);
            if (name == null) continue;
            const name_str = try cf.decodeCfstr(name, alloc);

            const event = hid.IOHIDServiceClientCopyEvent(v_cast, kIOHIDEventTypeTemperature, 0, 0);
            const temp = hid.IOHIDEventGetFloatValue(event, kIOHIDEventTypeTemperature << 16);

            const item = try alloc.create(HIDSensorsReading);
            item.* = .{ .key = name_str, .val = @as(f32, @floatCast(temp)) };
            try sensor_readings.append(item);
            cf.CFRelease(event);
        }

        cf.CFRelease(services);
        cf.CFRelease(system);

        return sensor_readings.items;
    }
};
