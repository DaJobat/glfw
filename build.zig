const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "glfw3",
        .target = target,
        .optimize = optimize,
    });

    lib.addCSourceFiles(&.{
        "src/cocoa_time.c",
        "src/context.c",
        "src/egl_context.c",
        "src/glx_context.c",
        "src/init.c",
        "src/input.c",
        "src/linux_joystick.c",
        "src/monitor.c",
        "src/null_init.c",
        "src/null_joystick.c",
        "src/null_monitor.c",
        "src/null_window.c",
        "src/osmesa_context.c",
        "src/platform.c",
        "src/posix_module.c",
        "src/posix_poll.c",
        "src/posix_thread.c",
        "src/posix_time.c",
        "src/vulkan.c",
        "src/wgl_context.c",
        "src/win32_init.c",
        "src/win32_joystick.c",
        "src/win32_module.c",
        "src/win32_monitor.c",
        "src/win32_thread.c",
        "src/win32_time.c",
        "src/win32_window.c",
        "src/window.c",
        "src/wl_init.c",
        "src/wl_monitor.c",
        "src/wl_window.c",
        "src/x11_init.c",
        "src/x11_monitor.c",
        "src/x11_window.c",
        "src/xkb_unicode.c",
    }, &.{});

    lib.installHeader("include/GLFW/glfw3native.h", "GLFW/glfw3native.h");
    lib.installHeader("include/GLFW/glfw3.h", "GLFW/glfw3.h");

    lib.linkLibC();

    b.installArtifact(lib);
}
