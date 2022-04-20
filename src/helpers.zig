const std = @import("std");
const c = @import("c.zig");

const constants = @import("constants.zig");
pub const PI = std.math.pi;
pub const HALF_PI = PI / 2.0;
pub const TWO_PI = PI * 2.0;

pub const Vector2 = struct {
    const Self = @This();
    x: f32 = 0.0,
    y: f32 = 0.0,

    pub fn lerp(v1: Vector2, v2: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = lerpf(v1.x, v2.x, t),
            .y = lerpf(v1.y, v2.y, t),
        };
    }

    /// We assume that v lies along the line v1-v2 (can be outside the segment)
    /// So we don't check both x and y unlerp. We just return the first one that we find.
    pub fn unlerp(v1: Vector2, v2: Vector2, v: Vector2) f32 {
        if (v1.x != v2.x) {
            return unlerpf(v1.x, v2.x, v.x);
        } else if (v1.y != v2.y) {
            return unlerpf(v1.y, v2.y, v.y);
        } else {
            return 0;
        }
    }

    pub fn ease(v1: Vector2, v2: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = easeinoutf(v1.x, v2.x, t),
            .y = easeinoutf(v1.y, v2.y, t),
        };
    }

    pub fn add(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x + v2.x,
            .y = v1.y + v2.y,
        };
    }

    pub fn added(v1: *const Vector2, v2: Vector2) Vector2 {
        return Vector2.add(v1.*, v2);
    }

    pub fn add3(v1: Vector2, v2: Vector2, v3: Vector2) Vector2 {
        return Vector2{
            .x = v1.x + v2.x + v3.x,
            .y = v1.y + v2.y + v3.y,
        };
    }

    pub fn subtract(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x - v2.x,
            .y = v1.y - v2.y,
        };
    }

    pub fn distance(v1: Vector2, v2: Vector2) f32 {
        return @sqrt(((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y)));
    }

    pub fn distance_sqr(v1: Vector2, v2: Vector2) f32 {
        return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y));
    }

    pub fn distance_to_sqr(v1: *const Vector2, v2: Vector2) f32 {
        return ((v2.x - v1.x) * (v2.x - v1.x)) + ((v2.y - v1.y) * (v2.y - v1.y));
    }

    pub fn length(v1: Vector2) f32 {
        return @sqrt((v1.x * v1.x) + (v1.y * v1.y));
    }

    pub fn length_sqr(v1: Vector2) f32 {
        return (v1.x * v1.x) + (v1.y * v1.y);
    }

    pub fn scale(v1: Vector2, t: f32) Vector2 {
        return Vector2{
            .x = v1.x * t,
            .y = v1.y * t,
        };
    }

    pub fn scaled(v1: *const Vector2, t: f32) Vector2 {
        return Vector2{
            .x = v1.x * t,
            .y = v1.y * t,
        };
    }

    pub fn scale_anchor(v1: *const Vector2, anchor: Vector2, f: f32) Vector2 {
        const translated = Vector2.subtract(v1.*, anchor);
        return Vector2.add(anchor, Vector2.scale(translated, f));
    }

    pub fn scale_vec(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x * v2.x,
            .y = v1.y * v2.y,
        };
    }

    pub fn negated(v1: *const Vector2) Vector2 {
        return Vector2{
            .x = -v1.x,
            .y = -v1.y,
        };
    }

    pub fn subtract_half(v1: Vector2, v2: Vector2) Vector2 {
        return Vector2{
            .x = v1.x - (0.5 * v2.x),
            .y = v1.y - (0.5 * v2.y),
        };
    }

    pub fn normalize(v1: Vector2) Vector2 {
        const l = Vector2.length(v1);
        return Vector2{
            .x = v1.x / l,
            .y = v1.y / l,
        };
    }

    /// Gives the clockwise angle in radians from first vector to second vector
    /// Assumes vectors are normalized
    pub fn angle_cw(v1: Vector2, v2: Vector2) f32 {
        std.debug.assert(!v1.is_nan());
        std.debug.assert(!v2.is_nan());
        const dot_product = std.math.clamp(Vector2.dot(v1, v2), -1, 1);
        var a = std.math.acos(dot_product);
        std.debug.assert(!is_nanf(a));
        const winding = Vector2.cross_z(v1, v2);
        std.debug.assert(!is_nanf(winding));
        if (winding < 0) a = TWO_PI - a;
        return a;
    }

    pub fn dot(v1: Vector2, v2: Vector2) f32 {
        std.debug.assert(!is_nanf(v1.x));
        std.debug.assert(!is_nanf(v1.y));
        std.debug.assert(!is_nanf(v2.x));
        std.debug.assert(!is_nanf(v2.y));
        return v1.x * v2.x + v1.y * v2.y;
    }

    /// Returns the z element of the 3d cross product of the two vectors. Useful to find the
    /// winding of the points
    pub fn cross_z(v1: Vector2, v2: Vector2) f32 {
        return (v1.x * v2.y) - (v1.y * v2.x);
    }

    pub fn equals(v1: Vector2, v2: Vector2) bool {
        return v1.x == v2.x and v1.y == v2.y;
    }

    pub fn is_equal(v1: *const Vector2, v2: Vector2) bool {
        return v1.x == v2.x and v1.y == v2.y;
    }

    pub fn reflect(v1: Vector2, surface: Vector2) Vector2 {
        // Since we're reflecting off the surface, we first need to find the component
        // of v1 that is perpendicular to the surface. We then need to "reverse" that
        // component. Or we can just subtract double the negative of that from v1.
        // TODO (25 Apr 2021 sam): See if this can be done without normalizing. @@Performance
        const n_surf = Vector2.normalize(surface);
        const v1_par = Vector2.scale(n_surf, Vector2.dot(v1, n_surf));
        const v1_perp = Vector2.subtract(v1, v1_par);
        return Vector2.subtract(v1, Vector2.scale(v1_perp, 2.0));
    }

    pub fn from_int(x: i32, y: i32) Vector2 {
        return Vector2{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) };
    }

    pub fn from_usize(x: usize, y: usize) Vector2 {
        return Vector2{ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) };
    }

    pub fn rotate(v: Vector2, a: f32) Vector2 {
        const cosa = @cos(a);
        const sina = @sin(a);
        return Vector2{
            .x = (cosa * v.x) - (sina * v.y),
            .y = (sina * v.x) + (cosa * v.y),
        };
    }

    pub fn rotate_deg(v: Vector2, d: f32) Vector2 {
        const a = d * std.math.pi / 180.0;
        const cosa = @cos(a);
        const sina = @sin(a);
        return Vector2{
            .x = (cosa * v.x) - (sina * v.y),
            .y = (sina * v.x) + (cosa * v.y),
        };
    }

    /// If we have a line v1-v2, where v1 is 0 and v2 is 1, this function
    /// returns what value the point p has. It is assumed that p lies along
    /// the line.
    pub fn get_fraction(v1: Vector2, v2: Vector2, p: Vector2) f32 {
        const len = Vector2.distance(v1, v2);
        const p_len = Vector2.distance(v1, p);
        return p_len / len;
    }

    pub fn rotate_about_point(v1: Vector2, anchor: Vector2, a: f32) Vector2 {
        const adjusted = Vector2.subtract(v1, anchor);
        const rotated = Vector2.rotate(adjusted, a);
        return Vector2.add(anchor, rotated);
    }

    pub fn rotate_about_point_deg(v1: Vector2, anchor: Vector2, a: f32) Vector2 {
        const adjusted = Vector2.subtract(v1, anchor);
        const rotated = Vector2.rotate_deg(adjusted, a);
        return Vector2.add(anchor, rotated);
    }

    pub fn is_zero(v1: *const Vector2) bool {
        return v1.x == 0 and v1.y == 0;
    }

    pub fn is_nan(v1: *const Vector2) bool {
        return is_nanf(v1.x) or is_nanf(v1.y);
    }

    pub fn get_perp(v1: Vector2, v2: Vector2) Vector2 {
        const line = Vector2.subtract(v2, v1);
        const perp = Vector2.normalize(Vector2{ .x = line.y, .y = -line.x });
        return perp;
    }
};

pub const Camera = struct {
    const Self = @This();
    size_updated: bool = true,
    origin: Vector2 = .{},
    window_size: Vector2 = .{ .x = constants.DEFAULT_WINDOW_WIDTH * constants.DEFAULT_USER_WINDOW_SCALE, .y = constants.DEFAULT_WINDOW_HEIGHT * constants.DEFAULT_USER_WINDOW_SCALE },
    zoom_factor: f32 = 1.0,
    window_scale: f32 = constants.DEFAULT_USER_WINDOW_SCALE,
    // This is used to store the window scale in case the user goes full screen and wants
    // to come back to windowed.
    user_window_scale: f32 = constants.DEFAULT_USER_WINDOW_SCALE,

    pub fn world_pos_to_screen(self: *const Self, pos: Vector2) Vector2 {
        const tmp1 = Vector2.subtract(pos, self.origin);
        // TODO (20 Oct 2021 sam): Why is this zoom_factor? and not combined
        return Vector2.scale(tmp1, self.zoom_factor);
    }

    pub fn screen_pos_to_world(self: *const Self, pos: Vector2) Vector2 {
        // TODO (10 Jun 2021 sam): I wish I knew why this were the case. But I have no clue. Jiggle and
        // test method got me here for the most part.
        // pos goes from (0,0) to (x,y) where x and y are the actual screen
        // sizes. (pixel size on screen as per OS)
        // we need to map this to a rect where the 0,0 maps to origin
        // and x,y maps to origin + w/zoom*scale
        const scaled = Vector2.scale(pos, 1.0 / (self.zoom_factor * self.combined_zoom()));
        return Vector2.add(scaled, self.origin);
    }

    pub fn render_size(self: *const Self) Vector2 {
        // TODO (27 Apr 2021 sam): See whether this causes any performance issues? Is it better to store
        // as a member variable, or is it okay to calculate as a method everytime? @@Performance
        return Vector2.scale(self.window_size, 1.0 / self.combined_zoom());
    }

    pub fn combined_zoom(self: *const Self) f32 {
        return self.zoom_factor * self.window_scale;
    }

    pub fn world_size_to_screen(self: *const Self, size: Vector2) Vector2 {
        return Vector2.scale(size, self.zoom_factor);
    }

    pub fn screen_size_to_world(self: *const Self, size: Vector2) Vector2 {
        return Vector2.scale(size, 1.0 / (self.zoom_factor * self.zoom_factor));
    }

    // TODO (10 May 2021 sam): There is some confusion here when we move from screen to world. In some
    // cases, we want to maintain the positions for rendering, in which case we need the zoom_factor
    // squared. In other cases, we don't need that. This is a little confusing to me, so we need to
    // sort it all out properly.
    // (02 Jun 2021 sam): I think it has something to do with window_scale and combined_zoom as well.
    // In some cases, we want to use zoom factor, in other cases, combined_zoom, and that needs to be
    // properly understood as well.
    pub fn screen_vec_to_world(self: *const Self, size: Vector2) Vector2 {
        return Vector2.scale(size, 1.0 / self.zoom_factor);
    }

    pub fn ui_pos_to_world(self: *const Self, pos: Vector2) Vector2 {
        const scaled = Vector2.scale(pos, 1.0 / (self.zoom_factor * self.zoom_factor));
        return Vector2.add(scaled, self.origin);
    }

    pub fn world_units_to_screen(self: *const Self, unit: f32) f32 {
        return unit * self.zoom_factor;
    }

    pub fn screen_units_to_world(self: *const Self, unit: f32) f32 {
        return unit / self.zoom_factor;
    }
};

pub const Vector2_gl = extern struct {
    x: c.GLfloat = 0.0,
    y: c.GLfloat = 0.0,
};

pub const Vector3_gl = extern struct {
    x: c.GLfloat = 0.0,
    y: c.GLfloat = 0.0,
    z: c.GLfloat = 0.0,
};

pub const Vector4_gl = extern struct {
    const Self = @This();
    x: c.GLfloat = 0.0,
    y: c.GLfloat = 0.0,
    z: c.GLfloat = 0.0,
    w: c.GLfloat = 0.0,

    pub fn lerp(v1: Vector4_gl, v2: Vector4_gl, t: f32) Vector4_gl {
        return Vector4_gl{
            .x = lerpf(v1.x, v2.x, t),
            .y = lerpf(v1.y, v2.y, t),
            .z = lerpf(v1.z, v2.z, t),
            .w = lerpf(v1.w, v2.w, t),
        };
    }

    pub fn equals(v1: Vector4_gl, v2: Vector4_gl) bool {
        return v1.x == v2.x and v1.y == v2.y and v1.z == v2.z and v1.w == v2.w;
    }

    /// Returns black and white version of the color
    pub fn bw(v1: *const Vector4_gl) Vector4_gl {
        const col = (v1.x + v1.y + v1.z) / 3.0;
        return Vector4_gl{
            .x = col,
            .y = col,
            .z = col,
            .w = v1.w,
        };
    }

    pub fn with_alpha(v1: *const Vector4_gl, a: f32) Vector4_gl {
        return Vector4_gl{ .x = v1.x, .y = v1.y, .z = v1.z, .w = a };
    }

    pub fn is_equal_to(v1: *const Vector4_gl, v2: Vector4_gl) bool {
        return Vector4_gl.equals(v1.*, v2);
    }
};

pub fn lerpf(start: f32, end: f32, t: f32) f32 {
    return (start * (1.0 - t)) + (end * t);
}

pub fn unlerpf(start: f32, end: f32, t: f32) f32 {
    // TODO (09 Jun 2021 sam): This should work even if start > end
    if (end == t) return 1.0;
    return (t - start) / (end - start);
}

pub fn is_nanf(f: f32) bool {
    return f != f;
}

pub fn easeinoutf(start: f32, end: f32, t: f32) f32 {
    // Bezier Blend as per StackOverflow : https://stackoverflow.com/a/25730573/5453127
    // t goes between 0 and 1.
    const x = t * t * (3.0 - (2.0 * t));
    return start + ((end - start) * x);
}

pub const SingleInput = struct {
    is_down: bool = false,
    is_clicked: bool = false, // For one frame when key is pressed
    is_released: bool = false, // For one frame when key is released
    down_from: u32 = 0,

    pub fn reset(self: *SingleInput) void {
        self.is_clicked = false;
        self.is_released = false;
    }

    pub fn set_down(self: *SingleInput, ticks: u32) void {
        self.is_down = true;
        self.is_clicked = true;
        self.down_from = ticks;
    }

    pub fn set_release(self: *SingleInput) void {
        self.is_down = false;
        self.is_released = true;
    }
};

pub const MouseState = struct {
    const Self = @This();
    current_pos: Vector2 = .{},
    previous_pos: Vector2 = .{},
    l_down_pos: Vector2 = .{},
    r_down_pos: Vector2 = .{},
    m_down_pos: Vector2 = .{},
    l_button: SingleInput = .{},
    r_button: SingleInput = .{},
    m_button: SingleInput = .{},
    wheel_y: i32 = 0,

    pub fn reset_mouse(self: *Self) void {
        self.previous_pos = self.current_pos;
        self.l_button.reset();
        self.r_button.reset();
        self.m_button.reset();
        self.wheel_y = 0;
    }

    pub fn l_single_pos_click(self: *Self) bool {
        if (self.l_button.is_released == false) return false;
        if (self.l_down_pos.distance_to_sqr(self.current_pos) == 0) return true;
        return false;
    }

    pub fn l_moved(self: *Self) bool {
        return (self.l_down_pos.distance_to_sqr(self.current_pos) > 0);
    }

    pub fn movement(self: *Self) Vector2 {
        return Vector2.subtract(self.previous_pos, self.current_pos);
    }

    pub fn handle_input(self: *Self, event: c.SDL_Event, ticks: u32, camera: *Camera) void {
        switch (event.@"type") {
            c.SDL_MOUSEBUTTONDOWN, c.SDL_MOUSEBUTTONUP => {
                const button = switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => &self.l_button,
                    c.SDL_BUTTON_RIGHT => &self.r_button,
                    c.SDL_BUTTON_MIDDLE => &self.m_button,
                    else => &self.l_button,
                };
                const pos = switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => &self.l_down_pos,
                    c.SDL_BUTTON_RIGHT => &self.r_down_pos,
                    c.SDL_BUTTON_MIDDLE => &self.m_down_pos,
                    else => &self.l_down_pos,
                };
                if (event.@"type" == c.SDL_MOUSEBUTTONDOWN) {
                    // This specific line just feels a bit off. I don't intuitively get it yet.
                    pos.* = self.current_pos;
                    self.l_down_pos = self.current_pos;
                    button.is_down = true;
                    button.is_clicked = true;
                    button.down_from = ticks;
                }
                if (event.@"type" == c.SDL_MOUSEBUTTONUP) {
                    button.is_down = false;
                    button.is_released = true;
                }
            },
            c.SDL_MOUSEWHEEL => {
                self.wheel_y = event.wheel.y;
            },
            c.SDL_MOUSEMOTION => {
                self.current_pos = camera.screen_pos_to_world(Vector2.from_int(event.motion.x, event.motion.y));
            },
            else => {},
        }
    }
};

pub const EditableText = struct {
    const Self = @This();
    text: std.ArrayList(u8),
    is_active: bool = false,
    position: Vector2 = .{},
    size: Vector2 = .{ .x = 300 },
    cursor_index: usize = 0,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .text = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn set_text(self: *Self, str: []const u8) void {
        self.text.shrinkRetainingCapacity(0);
        self.text.appendSlice(str) catch unreachable;
        self.cursor_index = str.len;
    }

    pub fn deinit(self: *Self) void {
        self.text.deinit();
    }

    pub fn handle_inputs(self: *Self, keys: []u8) void {
        for (keys) |k| {
            switch (k) {
                8 => {
                    if (self.cursor_index > 0) {
                        _ = self.text.orderedRemove(self.cursor_index - 1);
                        self.cursor_index -= 1;
                    }
                },
                127 => {
                    if (self.cursor_index < self.text.items.len) {
                        _ = self.text.orderedRemove(self.cursor_index);
                    }
                },
                128 => {
                    if (self.cursor_index > 0) {
                        self.cursor_index -= 1;
                    }
                },
                129 => {
                    if (self.cursor_index < self.text.items.len) {
                        self.cursor_index += 1;
                    }
                },
                else => {
                    self.text.insert(self.cursor_index, k) catch unreachable;
                    self.cursor_index += 1;
                },
            }
        }
    }
};

// We load multiple fonts into the same texture, but the API doesn't process that perfectly,
// and treats it as a smaller / narrower texture instead. So we have to wrangle the t0 and t1
// values a little bit.
pub fn tex_remap(y_in: f32, y_height: usize, y_padding: usize) f32 {
    const pixel = @floatToInt(usize, y_in * @intToFloat(f32, y_height));
    const total_height = y_height + y_padding;
    return @intToFloat(f32, pixel + y_padding) / @intToFloat(f32, total_height);
}
