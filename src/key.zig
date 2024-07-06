const curses = @cImport(@cInclude("curses.h"));

pub const Key = struct {
    char: u21 = 0,
    alt: bool = false,

    pub fn matches(self: *const Key, key: Key) bool {
        return std.meta.eql(self.*, key);
    }
};

const std = @import("std");

pub fn getKey() Key {
    const ch = curses.getch();
    return switch (ch) {
        alt => {
            const nch = curses.getch();
            if (nch != -1) {
                return Key{ .alt = true, .char = @intCast(nch) };
            }

            return Key{ .alt = true };
        },
        else => {
            if (ch >= 0 and ch <= 255) {
                return Key{ .char = @intCast(ch) };
            }
            return Key{};
        },
    };
}

pub const esc = 27;
pub const key_up = 259;
pub const key_down = 258;
pub const key_left = 260;
pub const key_right = 261;
pub const backspace = 263;
pub const space = 32;

const alt = 27;
