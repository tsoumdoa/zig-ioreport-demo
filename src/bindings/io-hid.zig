const cf = @import("cf.zig");
const CFMutableDictionaryRef = cf.CFMutableDictionaryRef;
const CFDictionaryRef = cf.CFDictionaryRef;
const CFAllocatorRef = cf.CFAllocatorRef;
const CFArrayRef = cf.CFArrayRef;
const CFStringRef = cf.CFStringRef;

const IOHIDServiceClient = anyopaque;
const IOHIDEventSystemClient = anyopaque;
const IOHIDEvent = anyopaque;

pub const IOHIDServiceClientRef = *const IOHIDServiceClient;
pub const IOHIDEventSystemClientRef = *const IOHIDEventSystemClient;
pub const IOHIDEventRef = *const IOHIDEvent;

// IOHID Bindings
pub extern "objc" fn IOHIDEventSystemClientCreate(allocator: CFAllocatorRef) IOHIDEventSystemClientRef;
pub extern "objc" fn IOHIDEventSystemClientSetMatching(a: IOHIDEventSystemClientRef, b: CFDictionaryRef) i32;
pub extern "objc" fn IOHIDEventSystemClientCopyServices(a: IOHIDEventSystemClientRef) CFArrayRef;
pub extern "objc" fn IOHIDServiceClientCopyProperty(a: IOHIDServiceClientRef, b: CFStringRef) CFStringRef;
pub extern "objc" fn IOHIDServiceClientCopyEvent(a: IOHIDServiceClientRef, v0: i64, v1: i32, v2: i64) IOHIDEventRef;
pub extern "objc" fn IOHIDEventGetFloatValue(event: IOHIDEventRef, field: i64) f64;
