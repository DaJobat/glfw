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
                    .incl_x11,
                    b.option(bool, "x11", "include support for the x11 windowing system") orelse true,
                );
                flags.setPresent(
                    .incl_wayland,
                    b.option(bool, "wayland", "include support for the wayland windowing system") orelse false,
                );
            },
            else => unreachable,
        }

        var flag_list = std.ArrayList([]const u8).init(b.allocator);
        var it = flags.iterator();
        while (it.next()) |flag| {
            flag_list.append(FlagKeywords.get(flag)) catch unreachable;
        }

        break :flag_blk flag_list.toOwnedSlice() catch unreachable;
    };

    defer b.allocator.free(flag_strings);

    //source files shared by every target
    lib.addCSourceFiles(&base_sources, flag_strings);

    switch (t.os.tag) {
        .freebsd, .netbsd, .openbsd, .dragonfly, .linux => {
            if (flags.contains(.incl_x11)) {
                lib.addCSourceFiles(&x11_sources, flag_strings);
            }
            lib.addCSourceFiles(&linux_extra_sources, flag_strings);
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

const UnixWindowing = enum { x11, wayland };

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

const x11_sources = .{
    "src/x11_init.c",
    "src/x11_monitor.c",
    "src/x11_window.c",
    "src/xkb_unicode.c",
    "src/glx_context.c",
};
const linux_extra_sources = .{ "src/linux_joystick.c", "src/posix_poll.c" };

const BuildFlags = enum {
    incl_x11,
    incl_wayland,
};

const FlagKeywords = std.EnumArray(BuildFlags, []const u8).init(.{
    .incl_x11 = "-D_GLFW_X11",
    .incl_wayland = "-D_GLFW_WAYLAND",
});
