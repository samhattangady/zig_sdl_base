pub const web_build = @import("constants.zig").WEB_BUILD;

pub usingnamespace if (web_build) @import("web.zig") else @import("c.zig");
