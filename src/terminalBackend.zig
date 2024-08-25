const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const stdout = std.io.getStdOut();
const os = std.os;

pub const TerminalBackend = struct {
    handle: posix.fd_t,
    orig_termios: posix.termios,
    tty: std.fs.File,

    pub fn init() !TerminalBackend {
        switch (builtin.os.tag) {
            .linux => {
                const handle = stdout.handle;
                return TerminalBackend{
                    .orig_termios = try posix.tcgetattr(handle),
                    .handle = handle,
                    .tty = try std.fs.openFileAbsolute("/dev/tty", .{ .mode = .read_write }),
                };
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn newScreen(_: *const TerminalBackend) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[?1049h", .{});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn endScreen(_: *const TerminalBackend) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[?1049l", .{});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn clearScreen(_: *const TerminalBackend) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[2J", .{});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn screenSize(self: *const TerminalBackend) !ScreenSize {
        switch (builtin.os.tag) {
            .linux => {
                var ws: posix.winsize = undefined;

                const err = std.os.linux.ioctl(self.handle, posix.T.IOCGWINSZ, @intFromPtr(&ws));
                if (posix.errno(err) != .SUCCESS) {
                    return error.IoctlError;
                }

                return ScreenSize{ .x = ws.ws_col, .y = ws.ws_row };
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn rawMode(self: *TerminalBackend) !void {
        switch (builtin.os.tag) {
            .linux => {
                var termios = try posix.tcgetattr(self.handle);

                termios.iflag.BRKINT = false;
                termios.iflag.ICRNL = false;
                termios.iflag.INPCK = false;
                termios.iflag.ISTRIP = false;
                termios.iflag.IXON = false;
                termios.oflag.OPOST = false;
                termios.cflag.CSIZE = .CS8;
                termios.lflag.ECHO = false;
                termios.lflag.ICANON = false;
                termios.lflag.IEXTEN = false;
                termios.lflag.ISIG = false;
                termios.cc[@intFromEnum(posix.V.MIN)] = 0;
                termios.cc[@intFromEnum(posix.V.TIME)] = 1;

                try posix.tcsetattr(self.handle, .FLUSH, termios);

                self.orig_termios = termios;
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn normalMode(self: *const TerminalBackend) !void {
        switch (builtin.os.tag) {
            .linux => {
                try posix.tcsetattr(self.handle, .FLUSH, self.orig_termios);
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn setCursor(_: *const TerminalBackend, x: u16, y: u16) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[{d};{d}H", .{ y, x });
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn hideCursor(_: *const TerminalBackend) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[?25l", .{});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn showCursor(_: *const TerminalBackend) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[?25h", .{});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn putChar(_: *const TerminalBackend, char: []const u8) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("{s}", .{char});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn setFg(_: *const TerminalBackend, color: Color) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[38;5;{d}m", .{@intFromEnum(color)});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn setBg(_: *const TerminalBackend, color: Color) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[48;5;{d}m", .{@intFromEnum(color)});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn setFgRgb(_: *const TerminalBackend, r: u8, g: u8, b: u8) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[38;2;{d};{d};{d}m", .{ r, g, b });
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn setBgRgb(_: *const TerminalBackend, r: u8, g: u8, b: u8) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[48;2;{d};{d};{d}m", .{ r, g, b });
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn setAttr(_: *const TerminalBackend, attr: []const u8) !void {
        switch (builtin.os.tag) {
            .linux => {
                try stdout.writer().print("\x1b[{s}", .{attr});
            },
            else => @compileError("not implemented yet"),
        }
    }

    pub fn keyPoll(self: *const TerminalBackend) !Input {
        var buf: [16]u8 = undefined;
        _ = try self.tty.read(&buf);
        return try parseKeyCode(&buf);
    }

    fn parseKeyCode(buf: []const u8) !Input {
        var input = Input{
            .key = 0,
            .ctrl = false,
            .shift = false,
            .alt = false,
        };
        var cpIter = (try std.unicode.Utf8View.init(buf)).iterator();
        while (cpIter.nextCodepoint()) |cp| {
            switch (cp) {
                0x41...0x5A => {
                    input.key = cp;
                    input.shift = true;
                },
                0x10 => {
                    input.shift = true;
                },
                0x11 => {
                    input.ctrl = true;
                },
                0x12 => {
                    input.alt = true;
                },
                else => {
                    input.key = cp;
                },
            }
        }
        return input;
    }
};

const ScreenSize = struct {
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

pub const Attribute = struct {
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
