pub const Cell = struct {
    fg: Color = .none,
    bg: Color = .none,
    char: u21 = ' ',
    attr: Attribute = .none,
};

pub const Color = union(enum) {
    indexed: IndexedColor,
    rgb: RgbColor,
    none,
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
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,
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

pub const Style = struct {
    fg: Color = .none,
    bg: Color = .none,
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
