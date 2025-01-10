const std = @import("std");

pub const Cell = struct {
    fg: ?Color = null,
    bg: ?Color = null,
    char: u21 = ' ',
    attr: Attribute = .none,

    pub fn eql(self: Cell, cell: Cell) bool {
        if (!std.meta.eql(self.fg, cell.fg)) return false;
        if (!std.meta.eql(self.bg, cell.bg)) return false;
        if (self.char != cell.char) return false;
        if (self.attr != cell.attr) return false;
        return true;
    }
};

pub const Color = packed struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn eql(self: Color, color: Color) bool {
        if (self.r != color.r) return false;
        if (self.g != color.g) return false;
        if (self.b != color.b) return false;
        return true;
    }
};

pub const Style = struct {
    fg: ?Color = null,
    bg: ?Color = null,
    attr: Attribute = .none,

    pub fn cell(self: *const Style) Cell {
        return .{
            .fg = self.fg,
            .bg = self.bg,
            .attr = self.attr,
            .char = ' ',
        };
    }
};

pub const IndexedColor = struct {
    pub const black = Color{ .r = 0, .g = 0, .b = 0 };
    pub const red = Color{ .r = 255, .g = 0, .b = 0 };
    pub const green = Color{ .r = 0, .g = 255, .b = 0 };
    pub const yellow = Color{ .r = 255, .g = 255, .b = 0 };
    pub const blue = Color{ .r = 0, .g = 0, .b = 255 };
    pub const magenta = Color{ .r = 255, .g = 0, .b = 255 };
    pub const cyan = Color{ .r = 0, .g = 255, .b = 255 };
    pub const white = Color{ .r = 255, .g = 255, .b = 255 };
    pub const bright_black = Color{ .r = 85, .g = 85, .b = 85 };
    pub const bright_red = Color{ .r = 255, .g = 85, .b = 85 };
    pub const bright_green = Color{ .r = 85, .g = 255, .b = 85 };
    pub const bright_yellow = Color{ .r = 255, .g = 255, .b = 85 };
    pub const bright_blue = Color{ .r = 85, .g = 85, .b = 255 };
    pub const bright_magenta = Color{ .r = 255, .g = 85, .b = 255 };
    pub const bright_cyan = Color{ .r = 85, .g = 255, .b = 255 };
    pub const bright_white = Color{ .r = 255, .g = 255, .b = 255 };
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
    none = 255,
};

pub const Border = enum(u8) {
    plain,
    thick,
    double_line,
    rounded,
};
