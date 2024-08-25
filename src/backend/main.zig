pub const TerminalBackend = @import("TerminalBackend.zig");

pub const ScreenSize = struct {
    x: u16,
    y: u16,
};

pub const Color = enum(u8) {
    black = 0,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    default,
};

pub const Attribute = []const u8;

pub const Attributes = struct {
    pub const reset = "\x1b[0m";
    pub const bold = "\x1b[1m";
    pub const noBold = "\x1b[22m";
    pub const dim = "\x1b[2m";
    pub const noDim = "\x1b[22m";
    pub const italic = "\x1b[3m";
    pub const noItalic = "\x1b[23m";
    pub const underline = "\x1b[4m";
    pub const noUnderline = "\x1b[24m";
    pub const reverse = "\x1b[7m";
    pub const noReverse = "\x1b[27m";
    pub const invisible = "\x1b[8m";
    pub const noInvisible = "\x1b[28m";
};
