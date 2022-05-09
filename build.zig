const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();
    const windows_build = if (b.option(bool, "windows", "Build for windows")) |w| w else true;

    const web_build = false;
    var options = b.addOptions();
    options.addOption(bool, "web_build", web_build);

    const exe = b.addExecutable("typeroo", "src/main.zig");
    exe.setTarget(target);
    exe.addOptions("build_options", options);
    exe.setBuildMode(mode);
    exe.addSystemIncludeDir("src");
    if (!web_build) {
        exe.addSystemIncludeDir("dependencies/gl");
        exe.addSystemIncludeDir("dependencies/stb_truetype-1.24");
        exe.addCSourceFile("dependencies/gl/glad.c", &[_][]const u8{"-std=c99"});
        exe.addCSourceFile("dependencies/stb_truetype-1.24/stb_truetype_impl.c", &[_][]const u8{"-std=c99"});
    }
    if (windows_build) {
        exe.addSystemIncludeDir("C:/SDL2/include");
        exe.addLibPath("C:/SDL2/lib/x64");
        exe.addLibPath("C:/Program Files (x86)/Windows Kits/10/Lib/10.0.18362.0/um/x64");
        b.installBinFile("C:/SDL2/lib/x64/SDL2.dll", "SDL2.dll");
    }
    exe.linkSystemLibrary("sdl2");
    if (windows_build) {
        exe.linkSystemLibrary("OpenGL32");
    } else {
        exe.linkSystemLibrary("OpenGL");
    }
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
