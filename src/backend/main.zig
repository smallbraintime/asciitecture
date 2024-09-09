pub const std = @import("std");

pub const Tty = @import("Tty.zig");

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

pub const Input = struct {
    key: u21 = undefined,
    ctrl: bool = false,
    shift: bool = false,
    alt: bool = false,

    pub fn eql(a: *const Input, b: *const Input) bool {
        return std.meta.eql(a.key, b.key);
    }
};

pub const Key = struct {
    pub const none: u8 = 0;
    pub const tab: u8 = 0x09;
    pub const enter: u8 = 0x0D;
    pub const escape: u8 = 0x1B;
    pub const space: u8 = 0x20;
    pub const backspace: u8 = 0x08;
    pub const insert: u8 = 0x2D;
    pub const delete: u8 = 0x2E;
    pub const left: u8 = 0x25;
    pub const right: u8 = 0x27;
    pub const up: u8 = 0x26;
    pub const down: u8 = 0x28;
    pub const page_up: u8 = 0x21;
    pub const page_down: u8 = 0x22;
    pub const home: u8 = 0x24;
    pub const end: u8 = 0x23;
    pub const caps_lock: u8 = 0x14;
    pub const scroll_lock: u8 = 0x91;
    pub const num_lock: u8 = 0x90;
    pub const print_screen: u8 = 0x2C;
    pub const pause: u8 = 0x13;
    pub const menu: u8 = 0x5D;
    pub const f1: u8 = 0x70;
    pub const f2: u8 = 0x71;
    pub const f3: u8 = 0x72;
    pub const f4: u8 = 0x73;
    pub const f5: u8 = 0x74;
    pub const f6: u8 = 0x75;
    pub const f7: u8 = 0x76;
    pub const f8: u8 = 0x77;
    pub const f9: u8 = 0x78;
    pub const f10: u8 = 0x79;
    pub const f11: u8 = 0x7A;
    pub const f12: u8 = 0x7B;
};
