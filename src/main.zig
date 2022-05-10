const std = @import("std");
const c = @import("platform.zig");
const App = @import("app.zig").App;
const Renderer = @import("renderer.zig").Renderer;
const helpers = @import("helpers.zig");
const constants = @import("constants.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
var app: App = undefined;
var renderer: Renderer = undefined;
pub fn main() anyerror!void {
    if (constants.WEB_BUILD) return;
    // TODO (14 Jul 2021 sam): Figure out how to handle this safety flag.
    gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer {
        _ = gpa.deinit();
    }
    if (constants.WEB_BUILD) {} else {
        if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }
        defer c.SDL_Quit();
    }
    var loading_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    app = App.new(gpa.allocator(), loading_arena.allocator());
    try app.init();
    defer app.deinit();
    renderer = try Renderer.init(&app.typesetter, &app.camera, gpa.allocator(), "typeroo");
    defer renderer.deinit();
    loading_arena.deinit();
    var event: c.SDL_Event = undefined;
    const start_ticks = std.time.milliTimestamp();
    while (!app.quit) {
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                c.SDL_QUIT => app.quit = true,
                else => app.handle_inputs(event),
            }
        }
        var frame_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const ticks = @intCast(u32, std.time.milliTimestamp() - start_ticks);
        app.update(ticks, frame_allocator.allocator());
        renderer.render_app(ticks, &app);
        frame_allocator.deinit();
        app.end_frame();
    }
}

export fn web_init() void {
    if (!constants.WEB_BUILD) return;
    const message = "hello from zig";
    c.consoleLogS(message, message.len);
}

pub fn _start() void {}
