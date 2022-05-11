const std = @import("std");
const c = @import("platform.zig");
const App = @import("app.zig").App;
const Renderer = @import("renderer.zig").Renderer;
const helpers = @import("helpers.zig");
const constants = @import("constants.zig");

var app: App = undefined;
var renderer: Renderer = undefined;
var web_allocator = if (constants.WEB_BUILD) std.heap.GeneralPurposeAllocator(.{}){} else void;
var web_start_ticks = @as(i64, 0);

pub fn main() anyerror!void {
    if (constants.WEB_BUILD) return;
    // TODO (14 Jul 2021 sam): Figure out how to handle this safety flag.
    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
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
    {
        const message = "hello from zig";
        c.consoleLogS(message, message.len);
    }
    var loading_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    app = App.new(web_allocator.allocator(), loading_arena.allocator());
    {
        const message = "app new done";
        c.consoleLogS(message, message.len);
    }
    app.init() catch unreachable;
    {
        const message = "app init done";
        c.consoleLogS(message, message.len);
    }
    // defer app.deinit();
    renderer = Renderer.init(&app.typesetter, &app.camera, web_allocator.allocator(), "typeroo") catch unreachable;
    {
        const message = "renderer init done";
        c.consoleLogS(message, message.len);
    }
    // defer renderer.deinit();
    web_start_ticks = c.milliTimestamp();
    {
        var buffer: [100]u8 = undefined;
        const message = std.fmt.bufPrint(&buffer, "web_start = {d}", .{web_start_ticks}) catch unreachable;
        c.consoleLogS(message.ptr, message.len);
    }
}

export fn web_render() void {
    const ticks = @intCast(u32, c.milliTimestamp() - web_start_ticks);
    var frame_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer frame_allocator.deinit();
    app.update(ticks, frame_allocator.allocator());
    renderer.render_app(ticks, &app);
    app.end_frame();
}

export fn mouse_motion(x: c_int, y: c_int) void {
    const event = helpers.MouseEvent{
        .movement = helpers.Vector2i{ .x = x, .y = y },
    };
    app.inputs.mouse.web_handle_input(event, app.ticks, &app.camera);
}

export fn mouse_down(button: c_int) void {
    if (false) {
        var buffer: [100]u8 = undefined;
        const message = std.fmt.bufPrint(&buffer, "mouse_down = {d}", .{button}) catch unreachable;
        c.consoleLogS(message.ptr, message.len);
    }
    const event = helpers.MouseEvent{
        .button_down = helpers.MouseButton.from_js(button),
    };
    app.inputs.mouse.web_handle_input(event, app.ticks, &app.camera);
}

export fn mouse_up(button: c_int) void {
    if (false) {
        var buffer: [100]u8 = undefined;
        const message = std.fmt.bufPrint(&buffer, "mouse_up = {d}", .{button}) catch unreachable;
        c.consoleLogS(message.ptr, message.len);
    }
    const event = helpers.MouseEvent{
        .button_up = helpers.MouseButton.from_js(button),
    };
    app.inputs.mouse.web_handle_input(event, app.ticks, &app.camera);
}
