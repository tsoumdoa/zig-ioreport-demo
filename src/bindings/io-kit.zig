const cf = @import("cf.zig");
const CFMutableDictionaryRef = cf.CFMutableDictionaryRef;
const CFDictionaryRef = cf.CFDictionaryRef;
const std = @import("std");

//IOKit bindings
pub extern "objc" fn IOServiceMatching(name: [*c]const u8) CFDictionaryRef;
pub extern "objc" fn IOServiceGetMatchingServices(mainPort: u32, matching: CFDictionaryRef, existing: *u32) i32;
pub extern "objc" fn IOIteratorNext(iterator: u32) u32;
pub extern "objc" fn IORegistryEntryGetName(entry: u32, name: *[128:0]i8) i32;
pub extern "objc" fn IORegistryEntryCreateCFProperties(entry: u32, properties: *CFMutableDictionaryRef, allocator: cf.CFAllocatorRef, options: u32) i32;
pub extern "objc" fn IOObjectRelease(obj: u32) u32;
pub extern "objc" fn IOServiceOpen(device: u32, a: u32, b: u32, c: *u32) callconv(.C) i32;
pub extern "objc" fn IOServiceClose(conn: u32) i32;
pub extern "objc" fn mach_task_self() callconv(.C) u32;
pub extern "objc" fn IOConnectCallStructMethod(conn: u32, selector: u32, ival: *const anyopaque, isize: usize, oval: *anyopaque, osize: *usize) callconv(.C) i32;
