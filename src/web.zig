const helpers = @import("helpers.zig");

pub const stbtt_aligned_quad = struct {
    x0: f32,
    y0: f32,
    s0: f32,
    t0: f32,
    x1: f32,
    y1: f32,
    s1: f32,
    t1: f32,
};

pub const stbtt_bakedchar = struct {
    x0: u16,
    y0: u16,
    x1: u16,
    y1: u16,
    xoff: f32,
    yoff: f32,
    xadvance: f32,
};

// Types
pub const GLuint = c_uint;
pub const GLint = c_int;
pub const GLfloat = f32;

// Identifier constants pulled from WebGLRenderingContext
pub const GL_VERTEX_SHADER: c_uint = 35633;
pub const GL_FRAGMENT_SHADER: c_uint = 35632;
pub const GL_ARRAY_BUFFER: c_uint = 34962;
pub const GL_ELEMENT_ARRAY_BUFFER = 0x8893;
pub const GL_TRIANGLES: c_uint = 4;
pub const GL_TRIANGLE_STRIP = 5;
pub const GL_STATIC_DRAW: c_uint = 35044;
pub const GL_FLOAT: c_uint = 5126;
pub const GL_DEPTH_TEST: c_uint = 2929;
pub const GL_LEQUAL: c_uint = 515;
pub const GL_COLOR_BUFFER_BIT: c_uint = 16384;
pub const GL_DEPTH_BUFFER_BIT: c_uint = 256;
pub const GL_STENCIL_BUFFER_BIT = 1024;
pub const GL_TEXTURE_2D: c_uint = 3553;
pub const GL_RGBA: c_uint = 6408;
pub const GL_UNSIGNED_BYTE: c_uint = 5121;
pub const GL_TEXTURE_MAG_FILTER: c_uint = 10240;
pub const GL_TEXTURE_MIN_FILTER: c_uint = 10241;
pub const GL_NEAREST: c_uint = 9728;
pub const GL_TEXTURE0: c_uint = 33984;
pub const GL_BLEND: c_uint = 3042;
pub const GL_SRC_ALPHA: c_uint = 770;
pub const GL_ONE_MINUS_SRC_ALPHA: c_uint = 771;
pub const GL_ONE: c_uint = 1;
pub const GL_NO_ERROR = 0;
pub const GL_FALSE = 0;
pub const GL_TRUE = 1;
pub const GL_UNPACK_ALIGNMENT = 3317;
pub const GL_RED = 0x8229;
pub const GL_RED_OUT = 0x1903;
pub const GL_LINEAR = 9729;

pub const GL_TEXTURE_WRAP_S = 10242;
pub const GL_CLAMP_TO_EDGE = 33071;
pub const GL_TEXTURE_WRAP_T = 10243;
pub const GL_PACK_ALIGNMENT = 3333;
pub const GL_FRAMEBUFFER = 0x8D40;
pub const GL_DYNAMIC_DRAW = 0x88E8;
pub const GL_UNSIGNED_INT = 0x1405;

// Helpers
pub extern fn console_log(_: [*]const u8) void;
pub extern fn consoleLogS(_: [*]const u8, _: c_uint) void;
pub extern fn milliTimestamp() i64;
pub extern fn readWebFile(_: [*]const u8, _: [*]u8, _: c_uint) bool;
pub extern fn readWebFileSize(_: [*]const u8) c_int;
pub extern fn readStorageFile(_: [*]const u8, _: [*]u8, _: c_uint) bool;
pub extern fn readStorageFileSize(_: [*]const u8) c_int;
pub extern fn writeStorageFile(_: [*]const u8, _: [*]const u8) bool;

// GL
pub extern fn glViewport(_: c_int, _: c_int, _: c_int, _: c_int) void;
pub extern fn glClearColor(_: f32, _: f32, _: f32, _: f32) void;
pub extern fn glEnable(_: c_uint) void;
pub extern fn glDepthFunc(_: c_uint) void;
pub extern fn glBlendFunc(_: c_uint, _: c_uint) void;
pub extern fn glClear(_: c_uint) void;
pub extern fn glGetAttribLocation(_: c_uint, _: [*]const u8, _: c_uint) c_int;
pub extern fn glGetUniformLocation(_: c_uint, _: helpers.WasmText) c_int;
pub extern fn glUniform4fv(_: c_int, _: f32, _: f32, _: f32, _: f32) void;
pub extern fn glUniform1i(_: c_int, _: c_int) void;
pub extern fn glUniform1f(_: c_int, _: f32) void;
pub extern fn glUniformMatrix4fv(_: c_int, _: c_int, _: c_uint, _: [*]const f32) void;
pub extern fn glCreateVertexArray() c_uint;
pub extern fn glGenVertexArrays(_: c_int, [*c]c_uint) void;
pub extern fn glDeleteVertexArrays(_: c_int, [*c]c_uint) void;
pub extern fn glBindVertexArray(_: c_uint) void;
pub extern fn glCreateBuffer() c_uint;
pub extern fn glGenBuffers(_: c_int, _: [*c]c_uint) void;
pub extern fn glDeleteBuffers(_: c_int, _: [*c]c_uint) void;
pub extern fn glDeleteBuffer(_: c_uint) void;
pub extern fn glBindBuffer(_: c_uint, _: c_uint) void;
pub extern fn glBufferData(_: c_uint, _: c_uint, _: ?*const anyopaque, _: c_uint) void;
pub extern fn glPixelStorei(_: c_uint, _: c_int) void;
pub extern fn glShaderSource(_: c_uint, _: c_uint, _: [*]const u8, _: c_uint) void;
pub extern fn glCreateShader(_: c_uint) c_uint;
pub extern fn glCompileShader(_: c_uint) void;
pub extern fn glAttachShader(_: c_uint, _: c_uint) void;
pub extern fn glDetachShader(_: c_uint, _: c_uint) void;
pub extern fn glDeleteShader(_: c_uint) void;
pub extern fn glCreateProgram() c_uint;
pub extern fn glLinkProgram(_: c_uint) void;
pub extern fn glUseProgram(_: c_uint) void;
pub extern fn glDeleteProgram(_: c_uint) void;
pub extern fn glEnableVertexAttribArray(_: c_uint) void;
pub extern fn glVertexAttribPointer(_: c_uint, _: c_uint, _: c_uint, _: c_uint, _: c_uint, _: *allowzero const anyopaque) void;
pub extern fn glDrawArrays(_: c_uint, _: c_uint, _: c_uint) void;
pub extern fn glCreateTexture() c_uint;
pub extern fn glGenTextures(_: c_int, _: [*c]c_uint) void;
pub extern fn glDeleteTextures(_: c_int, _: [*c]const c_uint) void;
pub extern fn glDeleteTexture(_: c_uint) void;
pub extern fn glBindTexture(_: c_uint, _: c_uint) void;
pub extern fn glTexImage2D(_: c_uint, _: c_uint, _: c_uint, _: c_int, _: c_int, _: c_uint, _: c_uint, _: c_uint, _: *u8) void;
pub extern fn glTexParameteri(_: c_uint, _: c_uint, _: c_uint) void;
pub extern fn glActiveTexture(_: c_uint) void;
pub extern fn glGetError() c_int;
pub extern fn glBindFramebuffer(_: c_uint, _: c_uint) void;
pub extern fn glDrawElements(_: c_uint, _: c_int, _: c_uint, _: ?*const anyopaque) void;
