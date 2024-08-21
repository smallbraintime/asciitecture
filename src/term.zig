const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const stdout = std.io.getStdOut();
const os = std.os;

var orig_termios: ?posix.termios = null;
var handle: posix.fd_t = stdout.handle;

pub fn newScreen() !void {
    switch (builtin.os.tag) {
        .linux => {
            try stdout.writer().print("\x1b[?1049h", .{});
        },
        .windows => @compileError("not implemented yet"),
        else => @compileError("os not supported"),
    }
}

pub fn endScreen() !void {
    switch (builtin.os.tag) {
        .linux => {
            try stdout.writer().print("\x1b[?1049l", .{});
        },
        .windows => @compileError("not implemented yet"),
        else => @compileError("os not supported"),
    }
}

pub fn clearScreen() !void {
    switch (builtin.os.tag) {
        .linux => {
            stdout.writer().print("\x1b[H\x1b[2J", .{});
        },
        .windows => @compileError("not implemented yet"),
        else => @compileError("os not supported"),
    }
}

pub fn screenSize() !std.meta.Tuple(&.{ u16, u16 }) {
    switch (builtin.os.tag) {
        .linux => {
            var ws: posix.winsize = undefined;

            const err = std.os.linux.ioctl(handle, posix.T.IOCGWINSZ, @intFromPtr(&ws));
            if (posix.errno(err) != .SUCCESS) {
                return error.IoctlError;
            }

            return std.meta.Tuple(.{ ws.ws_col, ws.ws_row });
        },
        .windows => @compileError("not implemented yet"),
        else => @compileError("os not supported"),
    }
}

pub fn rawMode() !void {
    switch (builtin.os.tag) {
        .linux => {
            var termios = try posix.tcgetattr(handle);

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

            try posix.tcsetattr(handle, .FLUSH, termios);

            orig_termios = termios;
        },
        .windows => @compileError("not implemented yet"),
        else => @compileError("os not supported"),
    }
}

pub fn normalMode() !void {
    if (orig_termios == null) {
        @panic("termios uninitialized, enter raw mode first");
    }

    try posix.tcsetattr(handle, .FLUSH, orig_termios.?);
}

pub fn setCursor(x: u16, y: u16) !void {
    try stdout.writer().print("\x1b[{d};{d}H", .{ y, x });
}

pub fn hideCursor() !void {
    try stdout.writer().print("\x1b[?251", .{});
}

pub fn showCursor() !void {
    try stdout.writer().print("\x1b[?25h", .{});
}

pub fn writeSymbol(symbol: []const u8) !void {
    try stdout.writer().print("{s}", .{symbol});
}

pub fn writeFg(color: Color) !void {
    try stdout.writer().print("\x1b[38;5;{d}m", .{@intFromEnum(color)});
}

pub fn writeBg(color: Color) !void {
    try stdout.writer().print("\x1b[48;5;{d}m", .{@intFromEnum(color)});
}

pub fn writeAttr(attr: Attribute) !void {
    try stdout.writer().print("\x1b[{s}", .{attr});
}

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

pub fn Input(char: u21, ctrl: bool, shift: bool, alt: bool) !Input {
    return struct {
        char: u21 = char,
        ctrl: bool = ctrl,
        shift: bool = shift,
        alt: bool = alt,
    };
}

fn poll(msTimeout: i32) !Input {
    const stdin = std.io.getStdIn().reader();

    const pollFd = [1]posix.pollfd{.{
        .fd = stdin,
        .events = posix.POLL.IN,
    }};

    if (try posix.poll(pollFd[0], msTimeout)) {
        return Input(0, false, false, false);
    }

    var buffer: [20]u8 = undefined;
    try stdin.read(&buffer);
    return Input(); // TODO: Make codepoint iterator
}
