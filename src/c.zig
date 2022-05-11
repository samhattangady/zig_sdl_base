pub usingnamespace @cImport({
    @cInclude("glad/glad.h");
    @cInclude("SDL.h");
    @cInclude("stb_truetype.h");
});

pub const milliTimestamp = @import("std").time.milliTimestamp;
