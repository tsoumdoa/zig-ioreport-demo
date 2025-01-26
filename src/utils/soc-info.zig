const std = @import("std");
const iok = @import("../bindings/io-kit.zig");
const cf = @import("../bindings/cf.zig");
const ioci = @import("./ioc-iterator.zig");
const IocIterator = ioci.IocIterator;
const ArrayList = std.ArrayList;
const debug = std.debug;
const eq = std.mem.eql;
const fmt = std.fmt;
const SocInfo = struct {
    mac_model: []const u8,
    chip_name: []const u8,
    memory_gb: u8,
    ecpu_cores: u8,
    pcpu_cores: u8,
    ecpu_freqs: ArrayList(u32),
    pcpu_freqs: ArrayList(u32),
    gpu_cores: u8,
    gpu_freqs: ArrayList(u32),
};
const DvfsMhz = struct {
    voltage: ArrayList(u32),
    frequency: ArrayList(u32),
};
const SPHardwareDataType = struct {
    chip_type: []const u8,
    machine_model: []const u8,
    physical_memory: []const u8,
    number_processors: []const u8,
};
const SPDisplaysDataType = struct {
    sppci_cores: []const u8,
};
const ProfilerResJson = struct {
    SPDisplaysDataType: []SPDisplaysDataType,
    SPHardwareDataType: []SPHardwareDataType,
};

//System on Chip (SOC) Info
pub inline fn getSocInfo(alloc: std.mem.Allocator) !*SocInfo {
    var ioc_iterator = try IocIterator.init("AppleARMIODevice");
    var val = try ioc_iterator.next();
    const profiler = try runSystemProfiler(alloc);
    var soc_info = try alloc.create(SocInfo);

    soc_info.mac_model = profiler.SPHardwareDataType[0].machine_model;
    const physical_memory = profiler.SPHardwareDataType[0].physical_memory;
    soc_info.memory_gb = fmt.parseInt(u8, std.mem.trim(u8, physical_memory, " GB"), 10) catch 0;
    const gpu_cores = profiler.SPDisplaysDataType[0].sppci_cores;
    soc_info.gpu_cores = fmt.parseInt(u8, gpu_cores, 10) catch 0;
    const cpu_cores = profiler.SPHardwareDataType[0].number_processors;
    var cpu_slices = std.mem.split(u8, cpu_cores, ":");
    const total_cores = fmt.parseInt(u8, cpu_slices.next().?, 10) catch 0;
    _ = total_cores;
    soc_info.pcpu_cores = fmt.parseInt(u8, cpu_slices.next().?, 10) catch 0;
    soc_info.ecpu_cores = fmt.parseInt(u8, cpu_slices.next().?, 10) catch 0;

    var is_pre_m4 = true;
    {
        const chip_type = profiler.SPHardwareDataType[0].chip_type;
        soc_info.chip_name = chip_type;
        var cpu_name_itter = std.mem.split(u8, chip_type, " ");
        var c = cpu_name_itter.next();
        while (c != null) : (c = cpu_name_itter.next()) {
            if (eq(u8, c.?, "M4")) {
                is_pre_m4 = false;
                break;
            }
        }
    }
    // MHz before M4, KHz after
    const cpu_scale: u32 = if (is_pre_m4) 1000 * 1000 else 1000;
    //MhZ
    const gpu_scale: u32 = 1000 * 1000;

    while (val != .End) : ({
        val = try ioc_iterator.next();
    }) {
        const v = val.Ok;
        const entry = ioc_iterator.next_val;
        const v_cast = @as([*:0]const u8, @ptrCast(v));
        var buffer: [128:0]u8 = undefined;
        @memcpy(buffer[0..], v_cast);

        var index: usize = 0;
        var needle = buffer[index];
        while (needle != 0) {
            index += 1;
            needle = buffer[index];
        }
        const name = buffer[0..index];
        if (eq(u8, name, "pmgr")) {
            var props: cf.CFMutableDictionaryRef = undefined;
            if (iok.IORegistryEntryCreateCFProperties(entry, &props, cf.kCFAllocatorDefault, 0) != 0) {
                std.debug.panic("failed to create properties {s}", .{name});
            }
            const ecpu_dvfs = try getDvfsMhz(alloc, props, "voltage-states1-sram", cpu_scale);
            const pcpu_dvfs = try getDvfsMhz(alloc, props, "voltage-states5-sram", cpu_scale);
            const gpu_dvfs = try getDvfsMhz(alloc, props, "voltage-states9", gpu_scale);

            soc_info.ecpu_freqs = ecpu_dvfs.frequency;
            soc_info.pcpu_freqs = pcpu_dvfs.frequency;
            soc_info.gpu_freqs = gpu_dvfs.frequency;
        }
    }
    return soc_info;
}

//Dynamic Voltage and Frequency Scaling (DVFS)
inline fn getDvfsMhz(alloc: std.mem.Allocator, props: cf.CFMutableDictionaryRef, key: []const u8, scale: u32) !DvfsMhz {
    const cfk = cf.cfString(key);
    const obj = @as(cf.CFDataRef, @ptrCast(cf.CFDictionaryGetValue(props, cfk)));
    const obj_len = cf.CFDataGetLength(obj);
    const range = cf.CFRange{
        .location = 0,
        .length = obj_len,
    };
    const len_u = @as(usize, @intCast(obj_len));

    var b = try alloc.alloc(u8, len_u);
    cf.CFDataGetBytes(obj, range, &b[0]);

    const count = b.len / 8;
    var voltage = try ArrayList(u32).initCapacity(alloc, count);
    var frequency = try ArrayList(u32).initCapacity(alloc, count);

    var i: usize = 0;
    while (i < b.len) : (i += 8) {
        try voltage.append(std.mem.bytesToValue(u32, b[i + 4 .. i + 8]));
        try frequency.append(std.mem.bytesToValue(u32, b[i .. i + 4]) / scale);
    }
    return DvfsMhz{
        .voltage = voltage,
        .frequency = frequency,
    };
}

inline fn runSystemProfiler(alloc: std.mem.Allocator) !ProfilerResJson {
    const o = try std.process.Child.run(.{
        .allocator = alloc,
        .argv = &[_][]const u8{ "system_profiler", "SPHardwareDataType", "SPDisplaysDataType", "-json" },
    });
    //probably need to do some error handling here
    //it throws an error if the json is invalid (not having the same shape as struct above)
    const parsed = try std.json.parseFromSlice(ProfilerResJson, alloc, o.stdout, .{ .ignore_unknown_fields = true });
    return parsed.value;
}
