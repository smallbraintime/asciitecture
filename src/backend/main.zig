pub const TerminalBackend = @import("TerminalBackend.zig");

pub const ScreenSize = struct {
    width: usize,
    height: usize,
};

pub const RgbColor = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub const IndexedColor = enum(u8) {
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

pub const Color = union(enum) {
    indexed: IndexedColor,
    rgb: RgbColor,
};

pub const Attribute = enum(u8) {
    reset = 0,
    bold = 1,
    noBold = 21,
    dim = 2,
    noDim = 22,
    italic = 3,
    noItalic = 23,
    underline = 4,
    noUnderline = 24,
    reverse = 7,
    noReverse = 27,
    hidden = 8,
    noHidden = 28,
};
