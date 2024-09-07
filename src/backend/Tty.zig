const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const stdout = std.io.getStdOut();
const os = std.os;
const backendMain = @import("main.zig");
const ScreenSize = backendMain.ScreenSize;
const Color = backendMain.Color;
const IndexedColor = backendMain.IndexedColor;
const RgbColor = backendMain.RgbColor;
const Attribute = backendMain.Attribute;

const Tty = @This();

handle: posix.fd_t,
orig_termios: posix.termios,
buf: std.io.BufferedWriter(4096, std.fs.File.Writer),

pub fn init() !Tty {
    const handle = stdout.handle;
    return Tty{
        .orig_termios = try posix.tcgetattr(handle),
        .handle = handle,
        .buf = std.io.bufferedWriter(stdout.writer()),
    };
}

pub fn newScreen(self: *Tty) !void {
    try self.buf.writer().print("\x1b[?1049h", .{});
}

pub fn endScreen(self: *Tty) !void {
    try self.buf.writer().print("\x1b[?1049l", .{});
}

pub fn clearScreen(self: *Tty) !void {
    try self.buf.writer().print("\x1b[2J", .{});
}

pub fn flush(self: *Tty) !void {
    try self.buf.flush();
}

pub fn screenSize(self: *const Tty) !ScreenSize {
    var ws: posix.winsize = undefined;

    const err = std.os.linux.ioctl(self.handle, posix.T.IOCGWINSZ, @intFromPtr(&ws));
    if (posix.errno(err) != .SUCCESS) {
        return error.IoctlError;
    }

    return ScreenSize{ .width = ws.ws_col, .height = ws.ws_row };
}

pub fn rawMode(self: *Tty) !void {
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
}

pub fn normalMode(self: *const Tty) !void {
    try posix.tcsetattr(self.handle, .FLUSH, self.orig_termios);
}

pub fn setCursor(self: *Tty, x: u16, y: u16) !void {
    try self.buf.writer().print("\x1b[{d};{d}H", .{ y, x });
}

pub fn hideCursor(self: *Tty) !void {
    try self.buf.writer().print("\x1b[?25l", .{});
}

pub fn showCursor(self: *Tty) !void {
    try self.buf.writer().print("\x1b[?25h", .{});
}

pub fn putChar(self: *Tty, char: u21) !void {
    var encoded_char: [4]u8 = undefined;
    const len = try std.unicode.utf8Encode(char, &encoded_char);
    try self.buf.writer().print("{s}", .{encoded_char[0..len]});
}

pub fn setFg(self: *Tty, color: Color) !void {
    switch (color) {
        .indexed => |*indexed| try setIndexedFg(self, indexed.*),
        .rgb => |*rgb| try setRgbFg(self, rgb.*),
    }
}

pub fn setBg(self: *Tty, color: Color) !void {
    switch (color) {
        .indexed => |*indexed| try setIndexedBg(self, indexed.*),
        .rgb => |*rgb| try setRgbBg(self, rgb.*),
    }
}

pub fn setIndexedFg(self: *Tty, color: IndexedColor) !void {
    try self.buf.writer().print("\x1b[38;5;{d}m", .{@intFromEnum(color)});
}

pub fn setIndexedBg(self: *Tty, color: IndexedColor) !void {
    try self.buf.writer().print("\x1b[48;5;{d}m", .{@intFromEnum(color)});
}

pub fn setRgbFg(self: *Tty, color: RgbColor) !void {
    try self.buf.writer().print("\x1b[38;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
}

pub fn setRgbBg(self: *Tty, color: RgbColor) !void {
    try self.buf.writer().print("\x1b[48;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
}

pub fn setAttr(self: *Tty, attr: Attribute) !void {
    try self.buf.writer().print("\x1b[{d}m", .{@intFromEnum(attr)});
}

pub fn pollInput(self: *const Tty) ![]const u8 {
    _ = self;
    var buf: [1]u8 = undefined;
    while (try std.posix.read(std.posix.STDIN_FILENO, &buf) == 0) {}
    return &buf;
}
