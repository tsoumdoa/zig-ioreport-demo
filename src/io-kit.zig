const CF = @import("cf-dic.zig");
const CFMutableDictionaryRef = CF.CFMutableDictionaryRef;

//IOKit bindings
pub extern "c" fn IOServiceMatching(name: [*:0]const u8) CFMutableDictionaryRef;
pub extern "c" fn IOServiceGetMatchingServices(mainPort: u32, matching: *const anyopaque, existing: *u32) i32;
pub extern "c" fn IOIteratorNext(iterator: u32) u32;
pub extern "c" fn IORegistryEntryGetName(entry: u32, name: *[*:0]u8) i32;
pub extern "c" fn IORegistryEntryCreateCFProperties(entry: u32, properties: *CFMutableDictionaryRef, allocator: u32, options: u32) i32;
pub extern "c" fn IOObjectRelease(obj: u32) u32;
