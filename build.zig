const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const asciitecture_mod = b.addModule("asciitecture", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    asciitecture_mod.linkSystemLibrary("ncursesw", .{});
    asciitecture_mod.linkSystemLibrary("c", .{});
    const options = b.addOptions();
    const options_mod = options.createModule();
    asciitecture_mod.addImport("build_options", options_mod);

    const example = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("example/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    example.root_module.addImport("asciitecture", asciitecture_mod);
    const example_run = b.addRunArtifact(example);
    const example_step = b.step("example", "Run example");
    example_step.dependOn(&example_run.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
