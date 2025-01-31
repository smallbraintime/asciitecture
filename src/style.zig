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

pub const Color = struct {
    rgb: [3]u8,

    pub fn r(self: Color) u8 {
        return self.rgb[0];
    }

    pub fn g(self: Color) u8 {
        return self.rgb[1];
    }

    pub fn b(self: Color) u8 {
        return self.rgb[2];
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
    pub const black = Color{ .rgb = .{ 0, 0, 0 } };
    pub const red = Color{ .rgb = .{ 255, 0, 0 } };
    pub const green = Color{ .rgb = .{ 0, 255, 0 } };
    pub const yellow = Color{ .rgb = .{ 255, 255, 0 } };
    pub const blue = Color{ .rgb = .{ 0, 0, 255 } };
    pub const magenta = Color{ .rgb = .{ 255, 0, 255 } };
    pub const cyan = Color{ .rgb = .{ 0, 255, 255 } };
    pub const white = Color{ .rgb = .{ 255, 255, 255 } };
    pub const bright_black = Color{ .rgb = .{ 85, 85, 85 } };
    pub const bright_red = Color{ .rgb = .{ 255, 85, 85 } };
    pub const bright_green = Color{ .rgb = .{ 85, 255, 85 } };
    pub const bright_yellow = Color{ .rgb = .{ 255, 255, 85 } };
    pub const bright_blue = Color{ .rgb = .{ 85, 85, 255 } };
    pub const bright_magenta = Color{ .rgb = .{ 255, 85, 255 } };
    pub const bright_cyan = Color{ .rgb = .{ 85, 255, 255 } };
    pub const bright_white = Color{ .rgb = .{ 255, 255, 255 } };
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
