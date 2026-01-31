const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = .ReleaseSmall;

    const exe = b.addExecutable(.{
        .name = "zig-dos-like-voxel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/voxel.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const dos = b.dependency("dos", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = exe.root_module;

    mod.addCSourceFile(.{
        .file = dos.path("source/dos.c"),
    });

    mod.addIncludePath(dos.path("source"));

    mod.linkSystemLibrary("SDL2", .{});
    mod.linkSystemLibrary("GLEW", .{});
    mod.linkSystemLibrary("pthread", .{});

    if (target.result.os.tag == .macos) {
        mod.linkFramework("OpenGL", .{});
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
