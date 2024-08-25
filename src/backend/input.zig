const std = @import("std");

pub const Input = struct {
    key: u21,
    ctrl: bool,
    shift: bool,
    alt: bool,

    const Self = @This();

    pub fn eql(other: @TypeOf(*Self)) bool {
        return std.meta.eql(other, @This());
    }

    pub fn fmt(self: *const Self) ![]const u8 {
        const allocator = std.heap.page_allocator;
        var keyStr = std.ArrayList(u8).init(allocator);

        if (self.ctrl) {
            try keyStr.appendSlice("ctrl+");
        }
        if (self.shift) {
            try keyStr.appendSlice("shift+");
        }
        if (self.alt) {
            try keyStr.appendSlice("alt+");
        }
        if (self.key > 0) {
            var buf: [4]u8 = undefined;
            _ = try std.unicode.utf8Encode(self.key, &buf);
            try keyStr.appendSlice(&buf);
        }

        return keyStr.items;
    }
};

pub const Key = struct {
    pub const backspace: u21 = 0x08;
    pub const tab: u21 = 0x09;
    pub const enter: u21 = 0x0D;
    pub const escape: u21 = 0x1B;
    pub const space: u21 = 0x20;
    pub const left_arrow: u21 = 0x25;
    pub const up_arrow: u21 = 0x26;
    pub const right_arrow: u21 = 0x27;
    pub const down_arrow: u21 = 0x28;
    pub const insert: u21 = 0x2D;
    pub const delete: u21 = 0x2E;

    pub const f1: u21 = 0x70;
    pub const f2: u21 = 0x71;
    pub const f3: u21 = 0x72;
    pub const f4: u21 = 0x73;
    pub const f5: u21 = 0x74;
    pub const f6: u21 = 0x75;
    pub const f7: u21 = 0x76;
    pub const f8: u21 = 0x77;
    pub const f9: u21 = 0x78;
    pub const f10: u21 = 0x79;
    pub const f11: u21 = 0x7A;
    pub const f12: u21 = 0x7B;
};
