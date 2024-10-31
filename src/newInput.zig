const std = @import("std");

pub const Input = struct {
    stdin: std.fs.File.Reader,
    key_map: std.AutoHashMap(KeyInput, i128),

    pub fn init(allocator: std.mem.Allocator) Input {
        return Input{
            .stdin = std.io.getStdIn().reader(),
            .key_map = std.AutoHashMap(KeyInput, i128).init(allocator),
        };
    }

    pub fn deinit(self: *Input) void {
        self.key_map.deinit();
    }

    pub fn contains(self: *Input, key: *const KeyInput) bool {
        self.key_map.put(self.nextEvent() catch unreachable, std.time.nanoTimestamp()) catch unreachable;
        if (self.key_map.get(key.*)) |tp| {
            return std.time.nanoTimestamp() - tp <= 500_000_000;
        }
        return false;
    }

    fn nextEvent(self: *Input) !KeyInput {
        var buf: [4]u8 = undefined;
        const c = try self.stdin.read(&buf);
        const view = try std.unicode.Utf8View.init(buf[0..c]);
        var iter = view.iterator();

        var input = KeyInput{ .key = undefined };
        if (iter.nextCodepoint()) |c0| switch (c0) {
            '\x1b' => {
                if (iter.nextCodepoint()) |c1| switch (c1) {
                    '[' => {
                        switch (buf[2]) {
                            'A' => input.key = Key.up,
                            'B' => input.key = Key.down,
                            'C' => input.key = Key.right,
                            'D' => input.key = Key.left,
                            else => input.key = Key.none,
                        }
                    },
                    else => input.key = Key.none,
                } else {
                    input.key = Key.none;
                }
            },
            else => input.key = c0,
        } else {
            input.key = Key.none;
        }
        return input;
    }
};

pub const KeyEvent = union(enum) {
    press: KeyInput,
    release: KeyInput,
};

pub const KeyInput = struct {
    key: u21,
    ctrl: bool = false,
    shift: bool = false,
    alt: bool = false,

    pub fn eql(a: *const KeyInput, b: *const KeyInput) bool {
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
