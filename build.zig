const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    // const lib = b.addStaticLibrary(.{
    //     .name = "zig-ioreport",
    //     .root_source_file = b.path("src/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "zig-ioreport",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.linkSystemLibrary("IOReport");
    exe.linkFramework("IOKit");
    exe.linkFramework("CoreFoundation");
    exe.root_module.addImport("objc", b.dependency("zig-objc", .{
        .target = target,
        .optimize = optimize,
    }).module("objc"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_unit_tests.linkSystemLibrary("IOReport");
    exe_unit_tests.linkFramework("IOKit");
    exe_unit_tests.linkFramework("CoreFoundation");
    exe_unit_tests.root_module.addImport("objc", b.dependency("zig-objc", .{
        .target = target,
        .optimize = optimize,
    }).module("objc"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
