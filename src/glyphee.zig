// File to store all the information about text and things like that one.
const std = @import("std");
const c = @import("platform.zig");
const constants = @import("constants.zig");

pub const FontType = enum {
    /// Font for debug purposes and things.
    debug,
    /// Font for large headers and such. Harder to read. Legible only at larger sizes.
    display,
    /// Font for large amounts of text. Easier to read. Legible at small sizes
    info,
};
const DEBUG_FONT_FILE = @embedFile("../data/fonts/JetBrainsMono/ttf/JetBrainsMono-Light.ttf");
const DISPLAY_FONT_FILE = @embedFile("../data/fonts/Leander/Leander.ttf");
const INFO_FONT_FILE = @embedFile("../data/fonts/Goudy/goudy_bookletter_1911.otf");
const NUM_FONTS = @typeInfo(FontType).Enum.fields.len;
const FONT_FILES = [NUM_FONTS][:0]const u8{
    DEBUG_FONT_FILE,
    DISPLAY_FONT_FILE,
    INFO_FONT_FILE,
};
const DEFAULT_FONT: FontType = .debug;
pub const FONT_TEX_SIZE = 512;
const GLYPH_CAPACITY = 2048;
const FONT_SIZE = 24.0;

const helpers = @import("helpers.zig");
const Camera = helpers.Camera;
const Vector2 = helpers.Vector2;
const Vector4_gl = helpers.Vector4_gl;
const BLACK: Vector4_gl = .{ .x = 24.0 / 255.0, .y = 24.0 / 255.0, .z = 24.0 / 255.0, .w = 1.0 };

const GlyphData = struct {
    glyphs: [96 * NUM_FONTS]c.stbtt_bakedchar = undefined,
};

const FontData = struct {
    type_: FontType = DEFAULT_FONT,
    start_glyph_index: usize = 0,
    start_row: usize = 0,
    num_rows: usize = 0,
};

const Glyph = struct {
    char: u8,
    font: FontType,
    color: Vector4_gl,
    quad: c.stbtt_aligned_quad,
    z: f32,
};

pub const TypeSetter = struct {
    const Self = @This();
    glyph_data: GlyphData = .{},
    texture_data: []u8 = undefined,
    allocator: std.mem.Allocator,
    glyphs: std.ArrayList(Glyph),
    camera: *const Camera,
    fonts_data: [NUM_FONTS]FontData = undefined,

    pub fn init(self: *Self, camera: *const Camera, allocator: std.mem.Allocator) !void {
        self.allocator = allocator;
        self.camera = camera;
        self.glyphs = std.ArrayList(Glyph).initCapacity(self.allocator, GLYPH_CAPACITY) catch unreachable;
        try self.load_font_data();
    }

    pub fn deinit(self: *Self) void {
        self.glyphs.deinit();
    }

    pub fn reset(self: *Self) void {
        self.glyphs.shrinkRetainingCapacity(0);
    }

    fn load_font_data(self: *Self) !void {
        // We load all the fonts into the same texture.
        // TODO (29 Jul 2021 sam): See if we should be using different API for text loading. The simple
        // one doesn't support multiple fonts easily, and we've had to jump through some hoops.
        self.texture_data = try self.allocator.alloc(u8, FONT_TEX_SIZE * FONT_TEX_SIZE);
        // @@UnimplementedTrueType
        var row: usize = 0;
        var glyphs_used: usize = 0;
        var i: usize = 0;
        while (i < NUM_FONTS) : (i += 1) {
            const bitmap_index = row * FONT_TEX_SIZE;
            const glyph_index = glyphs_used;
            // TODO (09 Nov 2021 sam): Figure out the failure conditions on this.
            const num_rows_used = c.stbtt_BakeFontBitmap(FONT_FILES[i], 0, FONT_SIZE, &self.texture_data[bitmap_index], FONT_TEX_SIZE, FONT_TEX_SIZE - @intCast(c_int, row), 32, 96, &self.glyph_data.glyphs[glyph_index]);
            self.fonts_data[i].type_ = @intToEnum(FontType, @intCast(u2, i));
            self.fonts_data[i].start_row = row;
            self.fonts_data[i].start_glyph_index = glyph_index;
            row += @intCast(usize, num_rows_used);
            glyphs_used += 96;
        }
    }

    pub fn free_texture_data(self: *Self) void {
        self.allocator.free(self.texture_data);
    }

    pub fn draw_char_world(self: *Self, pos: Vector2, char: u8) Vector2 {
        return self.draw_char(self.camera.world_pos_to_screen(pos), char, self.camera);
    }

    pub fn get_char_offset(self: *Self, char: u8) Vector2 {
        return self.get_char_offset_font(char, DEFAULT_FONT);
    }

    pub fn get_char_offset_font(self: *Self, char: u8, font: FontType) Vector2 {
        const glyph = self.get_char_glyph(char, font);
        return Vector2{ .x = glyph.xadvance };
    }

    pub fn draw_char(self: *Self, pos: Vector2, char: u8, camera: *const Camera) Vector2 {
        return self.draw_char_color(pos, char, 0.9, camera, BLACK);
    }

    pub fn draw_char_color(self: *Self, pos: Vector2, char: u8, z: f32, camera: *const Camera, color: Vector4_gl) Vector2 {
        return self.draw_char_color_font(pos, char, z, camera, color, DEFAULT_FONT);
    }

    pub fn get_char_glyph(self: *Self, char: u8, font: FontType) c.stbtt_bakedchar {
        const font_data = self.fonts_data[@enumToInt(font)];
        const char_index = if (char < 32 or char > (32 + 96)) 32 else char;
        return self.glyph_data.glyphs[font_data.start_glyph_index + @intCast(usize, char_index) - 32];
    }

    // TODO (07 May 2021 sam): Text also scales with the zoom. We don't want that to be the case.
    pub fn draw_char_color_font(self: *Self, pos: Vector2, char: u8, z: f32, camera: *const Camera, color: Vector4_gl, font: FontType) Vector2 {
        if (constants.WEB_BUILD) return .{};
        _ = z;
        // TODO (20 Sep 2021 sam): Should we be using/saving camera somewhere here?
        _ = camera;
        const font_data = self.fonts_data[@enumToInt(font)];
        const glyph = self.get_char_glyph(char, font);
        const inv_tex_width = 1.0 / @intToFloat(f32, FONT_TEX_SIZE);
        const inv_tex_height = 1.0 / @intToFloat(f32, FONT_TEX_SIZE - font_data.start_row);
        const round_x = @floor((pos.x + glyph.xoff) + 0.5);
        const round_y = @floor((pos.y + glyph.yoff) + 0.5);
        var quad: c.stbtt_aligned_quad = .{
            .x0 = round_x,
            .y0 = round_y,
            .x1 = round_x + @intToFloat(f32, glyph.x1 - glyph.x0),
            .y1 = round_y + @intToFloat(f32, glyph.y1 - glyph.y0),
            .s0 = @intToFloat(f32, glyph.x0) * inv_tex_width,
            .t0 = @intToFloat(f32, glyph.y0) * inv_tex_height,
            .s1 = @intToFloat(f32, glyph.x1) * inv_tex_width,
            .t1 = @intToFloat(f32, glyph.y1) * inv_tex_height,
        };
        // TODO (29 Jul 2021 sam): This could be cleaner if we understand the stbtt glyph.y values
        quad.t0 = helpers.tex_remap(quad.t0, (FONT_TEX_SIZE - font_data.start_row), font_data.start_row);
        quad.t1 = helpers.tex_remap(quad.t1, (FONT_TEX_SIZE - font_data.start_row), font_data.start_row);
        // These lines fix the size to be constant regardless of the size of the window.
        // But the offset of the letters gets affected, so maybe it isn't the best way to do this.
        // It should ideally be done a level higher.
        // quad.x1 = quad.x0 + ((quad.x1 - quad.x0) / camera.combined_zoom());
        // quad.y1 = quad.y0 + ((quad.y1 - quad.y0) / camera.combined_zoom());
        // return Vector2{ .x = glyph.xadvance / camera.combined_zoom() };
        const new_glyph = Glyph{
            .char = char,
            .color = color,
            .font = font,
            .quad = quad,
            .z = z,
        };
        self.glyphs.append(new_glyph) catch unreachable;
        return Vector2{ .x = glyph.xadvance };
    }

    pub fn draw_text_world(self: *Self, pos: Vector2, text: []const u8) void {
        self.draw_text_world_font(pos, text, DEFAULT_FONT);
    }

    pub fn draw_text_world_font(self: *Self, pos: Vector2, text: []const u8, font: FontType) void {
        self.draw_text_width_font(self.camera.world_pos_to_screen(pos), text, self.camera, 1000000.0, font);
    }

    pub fn draw_text_world_font_color(self: *Self, pos: Vector2, text: []const u8, font: FontType, color: Vector4_gl) void {
        // TODO (30 Jul 2021 sam): Do we need to do world_pos_to_screen here?
        self.draw_text_width_color_font(pos, text, self.camera, 1000000.0, color, font);
    }

    pub fn draw_text_world_centered(self: *Self, pos: Vector2, text: []const u8) void {
        self.draw_text_world_centered_font(pos, text, DEFAULT_FONT);
    }

    pub fn draw_text_world_centered_font(self: *Self, pos: Vector2, text: []const u8, font: FontType) void {
        self.draw_text_world_centered_font_color(pos, text, font, BLACK);
    }

    pub fn draw_text_world_centered_font_color(self: *Self, pos: Vector2, text: []const u8, font: FontType, color: Vector4_gl) void {
        const width = self.get_text_width_font(text, font);
        const c_pos = Vector2.subtract(pos, width.scaled(0.5));
        self.draw_text_world_font_color(c_pos, text, font, color);
    }

    pub fn draw_text_width_world(self: *Self, pos: Vector2, text: []const u8, width: f32) void {
        self.draw_text_width(self.camera.world_pos_to_screen(pos), text, self.camera, width);
    }

    pub fn draw_text_width_camera(self: *Self, pos: Vector2, text: []const u8, width: f32, camera: *const Camera) void {
        self.draw_text_width(camera.world_pos_to_screen(pos), text, camera, width);
    }

    pub fn draw_text_width_world_color(self: *Self, pos: Vector2, text: []const u8, width: f32, color: Vector4_gl) void {
        self.draw_text_width_color(self.camera.world_pos_to_screen(pos), text, self.camera, width, color);
    }

    pub fn draw_text(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera) void {
        self.draw_text_width(pos, text, camera, 1000000.0);
    }

    pub fn draw_text_width(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera, width: f32) void {
        self.draw_text_width_font(pos, text, camera, width, DEFAULT_FONT);
    }

    pub fn draw_text_width_font_world(self: *Self, pos: Vector2, text: []const u8, width: f32, font: FontType) void {
        self.draw_text_width_color_font(self.camera.world_pos_to_screen(pos), text, self.camera, width, BLACK, font);
    }

    pub fn draw_text_width_font(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera, width: f32, font: FontType) void {
        self.draw_text_width_color_font(pos, text, camera, width, BLACK, font);
    }

    pub fn draw_text_width_color(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera, width: f32, color: Vector4_gl) void {
        self.draw_text_width_color_font(pos, text, camera, width, color, DEFAULT_FONT);
    }

    pub fn draw_text_width_color_font(self: *Self, pos: Vector2, text: []const u8, camera: *const Camera, width: f32, color: Vector4_gl, font: FontType) void {
        if (constants.WEB_BUILD) return .{};
        var offsets = Vector2{};
        var new_line = false;
        for (text) |char| {
            const char_offset = self.draw_char_color_font(Vector2.add(pos, offsets), char, 1, camera, color, font);
            offsets = Vector2.add(offsets, char_offset);
            if (offsets.x > width) new_line = true;
            if (char == '\n' or (new_line and char == ' ')) {
                offsets.x = 0.0;
                offsets.y += FONT_SIZE * 1.2;
                new_line = false;
            }
        }
    }

    pub fn get_text_width(self: *Self, text: []const u8) Vector2 {
        return self.get_text_width_font(text, DEFAULT_FONT);
    }

    pub fn get_text_width_font(self: *Self, text: []const u8, font: FontType) Vector2 {
        if (constants.WEB_BUILD) return .{};
        var width: f32 = 0.0;
        for (text) |char| {
            const glyph = self.get_char_glyph(char, font);
            width += glyph.xadvance;
        }
        return Vector2{ .x = width };
    }

    pub fn get_text_offset(self: *Self, text: []const u8, width: f32, camera: *const Camera) Vector2 {
        if (constants.WEB_BUILD) return .{};
        var offsets = Vector2{};
        var new_line = false;
        for (text) |char| {
            const char_offset = self.get_char_offset(char);
            offsets = Vector2.add(offsets, char_offset);
            if (offsets.x > width) new_line = true;
            if (char == '\n' or (new_line and char == ' ')) {
                offsets.x = 0.0;
                offsets.y += FONT_SIZE * 1.2;
                new_line = false;
            }
        }
        return camera.screen_vec_to_world(offsets);
    }

    // TODO (21 Sep 2021 sam): This could maybe be cleaned up a bit. I've just copy pasted another
    // function here, and it looks like we are overriding the things in most cases...
    pub fn get_text_bounding_box(self: *Self, text: []const u8, width: f32, camera: *const Camera) Vector2 {
        if (constants.WEB_BUILD) return .{};
        var num_lines: f32 = 1;
        var offsets = Vector2{};
        var new_line = false;
        for (text) |char| {
            const char_offset = self.get_char_offset(char);
            offsets = Vector2.add(offsets, char_offset);
            if (offsets.x > width) new_line = true;
            if (char == '\n' or (new_line and char == ' ')) {
                offsets.x = 0.0;
                new_line = false;
                num_lines += 1;
            }
        }
        if (num_lines > 1) offsets.x = width;
        offsets.y = FONT_SIZE * 1.2 * num_lines;
        return camera.screen_vec_to_world(offsets);
    }
};
