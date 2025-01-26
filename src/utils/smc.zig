const std = @import("std");
const mem = std.mem;
const ArrayList = std.ArrayList;
const eq = std.mem.eql;
const ioci = @import("./ioc-iterator.zig");
const IocIterator = ioci.IocIterator;
const iokit = @import("../bindings/io-kit.zig");
const AutoHashMap = std.AutoHashMap;

pub inline fn initSmc(alloc: std.mem.Allocator) !SmcInfo {
    var smc = try Smc.init(alloc);
    var smc_cpu_keys = ArrayList([]u8).init(alloc);
    var smc_gpu_keys = ArrayList([]u8).init(alloc);
    // read all keys
    const all_keys = try smc.readAllKeys();
    _ = all_keys;

    // iterate over all keys to get the data size and data type

    // if Tp add to cpu_keys
    // if Tg add to gpu_keys
    return SmcInfo{ .smc = smc, .smc_cpu_keys = &smc_cpu_keys, .smc_gpu_keys = &smc_gpu_keys };
}

const KeyDataVer = struct { major: u8, minor: u8, build: u8, reserved: u8, release: u16 };
const PLimitData = struct { length: u16, version: u16, cpu_p_limit: u32, gpu_p_limit: u32, mem_p_limit: u32 };
const KeyData = struct {
    key: u32,
    vers: KeyDataVer,
    p_limit_data: PLimitData,
    key_info: KeyInfo,
    result: u8,
    status: u8,
    data8: u8,
    data32: u32,
    bytes: [32]u8,
};
const SmcInfo = struct { smc: Smc, smc_cpu_keys: *ArrayList([]u8), smc_gpu_keys: *ArrayList([]u8) };
const KeyInfo = struct { data_size: u32, data_type: u32, data_attributes: u8 };
pub const Smc = struct {
    conn: u32,
    keyHashMap: *AutoHashMap(u32, KeyInfo),

    pub inline fn init(alloc: std.mem.Allocator) !Smc {
        var ioc_iterator = try IocIterator.init("AppleSMC");
        var val = try ioc_iterator.next();
        var conn: u32 = 0;

        while (val != .End) : ({
            val = try ioc_iterator.next();
        }) {
            const v = val.Ok;
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
            const device = ioc_iterator.next_val;
            if (eq(u8, name, "AppleSMCKeysEndpoint")) {
                const task = iokit.mach_task_self();
                const rs = iokit.IOServiceOpen(device, task, 0, &conn);
                if (rs != 0) {
                    std.debug.panic("failed to open connection\n", .{});
                }
            }
        }

        var hash_map = AutoHashMap(u32, KeyInfo).init(alloc);
        return Smc{
            .conn = conn,
            .keyHashMap = &hash_map,
        };
    }

    pub fn deinit(self: *Smc) void {
        self.keyHashMap.deinit();
        const rs = iokit.IOServiceClose(self.conn);
        _ = rs;
    }

    pub fn readAllKeys(self: *Smc) !void {
        // [][]u8
        const val = try self.readVal("#KEY");
        _ = val;
        // let val = self.read_val("#KEY")?;
        // let val = u32::from_be_bytes(val.data[0..4].try_into().unwrap());
        //todo
        //return slices of string
        // return;
    }

    pub fn readVal(self: *Smc, key: [*:0]const u8) !void {
        const key_info = try self.readKeyInfo(key);
        _ = key_info;
        //todo
    }

    pub fn read(self: *Smc, ival: *const KeyData) !KeyData {
        const i_len = @as(usize, @sizeOf(KeyData));
        var oval = KeyData{
            .status = undefined,
            .key = undefined,
            .vers = KeyDataVer{ .major = undefined, .minor = undefined, .build = undefined, .reserved = undefined, .release = undefined },
            .p_limit_data = PLimitData{ .length = undefined, .version = undefined, .cpu_p_limit = undefined, .gpu_p_limit = undefined, .mem_p_limit = undefined },
            .key_info = KeyInfo{ .data_size = undefined, .data_type = undefined, .data_attributes = undefined },
            .data8 = undefined,
            .bytes = undefined,
            .result = undefined,
            .data32 = undefined,
        };
        var oval_len = @as(usize, @sizeOf(KeyData));
        // std.debug.print("conn: {any}\n", .{self.conn});
        // std.debug.print("ival: {any}\n", .{ival});
        // std.debug.print("i_len: {any}\n", .{i_len});
        std.debug.print("oval: {any}\n", .{oval});
        // std.debug.print("oval_len: {any}\n", .{oval_len});
        const rs = iokit.IOConnectCallStructMethod(self.conn, 2, ival, i_len, &oval, &oval_len);

        if (rs != 0) {
            std.debug.panic("IOConnectCallStructMethod: {}", .{rs});
        }
        if (oval.result == 132) {
            std.debug.panic("SMC key not found", .{});
        }

        //
        // if oval.result != 0 {
        //   return Err(format!("SMC error: {}", oval.result).into());
        // }
        //
        // Ok(oval)
        return oval;
    }

    pub fn readKeyInfo(self: *Smc, key: [*:0]const u8) !KeyInfo {
        const len = mem.len(key);
        // SMC key must be 4 bytes long
        std.debug.assert(len == 4);
        // cast key to FourCC
        var key_fcc: u32 = 0;
        for (key[0..len]) |x| {
            key_fcc = (key_fcc << 8) + @as(u32, @intCast(x));
        }

        const v = self.keyHashMap.get(key_fcc);
        if (v != null) return v.?;

        const ival = KeyData{
            .data8 = 9,
            .key = key_fcc,
            .vers = KeyDataVer{ .major = undefined, .minor = undefined, .build = undefined, .reserved = undefined, .release = undefined },
            .p_limit_data = PLimitData{ .length = undefined, .version = undefined, .cpu_p_limit = undefined, .gpu_p_limit = undefined, .mem_p_limit = undefined },
            .key_info = KeyInfo{ .data_size = undefined, .data_type = undefined, .data_attributes = undefined },
            .result = undefined,
            .status = undefined,
            .data32 = undefined,
            .bytes = undefined,
        };

        const oval = try self.read(&ival);
        _ = oval;

        return KeyInfo{ .data_size = 0, .data_type = 0, .data_attributes = 0 };
        //todo
        // if key.len() != 4 {
        //   return Err("SMC key must be 4 bytes long".into());
        // }
        //
        // key is FourCC
        // let key = key.bytes().fold(0, |acc, x| (acc << 8) + x as u32);
        // if let Some(ki) = self.keys.get(&key) {
        //   // println!("cache hit for {}", key);
        //   return Ok(ki.clone());
        // }
        //
        // let ival = KeyData { data8: 9, key, ..Default::default() };
        // let oval = self.read(&ival)?;
        // self.keys.insert(key, oval.key_info);
        // Ok(oval.key_info)
    }

    // pub inline fn sample(self: *HIDSensors) !void {
    // }
};
