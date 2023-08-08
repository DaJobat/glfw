const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = if (target.isWindows()) "glfw3" else "glfw",
        .target = target,
        .optimize = optimize,
    });

    const t = lib.target_info.target;
    var flags = std.EnumSet(BuildFlags){};
    const flag_strings: []const []const u8 = flag_blk: { //setting build flags

        switch (t.os.tag) {
            .freebsd, .netbsd, .openbsd, .dragonfly, .linux => {
                flags.setPresent(
                    .x11,
                    b.option(bool, "x11", "include support for the x11 windowing system") orelse true,
                );
                flags.setPresent(
                    .wayland,
                    b.option(bool, "wayland", "include support for the wayland windowing system") orelse false,
                );
            },
            else => unreachable,
        }

        var flag_list = std.ArrayList([]const u8).init(b.allocator);
        var it = flags.iterator();
        while (it.next()) |flag| {
            if (FlagKeywords.get(flag)) |keywords| {
                flag_list.appendSlice(keywords) catch unreachable;
            }
        }

        break :flag_blk flag_list.toOwnedSlice() catch unreachable;
    };

    defer b.allocator.free(flag_strings);

    //source files shared by every target
    lib.addCSourceFiles(&base_sources, flag_strings);

    switch (t.os.tag) {
        .freebsd, .netbsd, .openbsd, .dragonfly, .linux => {
            if (flags.contains(.x11)) {
                lib.addCSourceFiles(&x11_sources, flag_strings);
            }
            if (t.os.tag == .linux) {
                lib.addCSourceFiles(&linux_sources, flag_strings);
            }
            lib.addCSourceFiles(&unix_sources, flag_strings);
            lib.addCSourceFiles(&posix_sources, flag_strings);
        },
        else => unreachable,
    }

    lib.addIncludePath(.{ .path = "src/" });
    lib.addIncludePath(.{ .path = "include/" });
    lib.installHeader("include/GLFW/glfw3native.h", "GLFW/glfw3native.h");
    lib.installHeader("include/GLFW/glfw3.h", "GLFW/glfw3.h");
    lib.linkLibC();

    b.installArtifact(lib);
}

const base_sources = .{
    "src/context.c",
    "src/init.c",
    "src/input.c",
    "src/monitor.c",
    "src/platform.c",
    "src/vulkan.c",
    "src/window.c",
    "src/egl_context.c",
    "src/osmesa_context.c",
    "src/null_init.c",
    "src/null_monitor.c",
    "src/null_window.c",
    "src/null_joystick.c",
};

const posix_sources = .{ "src/posix_module.c", "src/posix_thread.c", "src/posix_time.c" };
const windows_sources = .{
    "src/win32_init.c",
    "src/win32_joystick.c",
    "src/win32_monitor.c",
    "src/win32_window.c",
    "src/wgl_context.c",
};
const cocoa_sources = .{
    "src/cocoa_init.m",
    "src/cocoa_joystick.m",
    "src/cocoa_monitor.m",
    "src/cocoa_window.m",
    "src/nsgl_context.m",
};
const unix_sources = .{"src/posix_poll.c"};
const linux_sources = .{"src/linux_joystick.c"};
const x11_sources = .{ "src/x11_init.c", "src/x11_monitor.c", "src/x11_window.c", "src/xkb_unicode.c", "src/glx_context.c" };

const BuildFlags = enum {
    win32,
    cocoa,
    x11,
    wayland,
};

const FlagKeywords = std.EnumMap(BuildFlags, []const []const u8).init(.{
    .x11 = &.{"-D_GLFW_X11"},
    .wayland = &.{"-D_GLFW_WAYLAND"},
    .win32 = &.{ "-D_UNICODE", "-DUNICODE" },
});
