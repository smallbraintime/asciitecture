const std = @import("std");
const builtin = @import("builtin");
const cell = @import("../cell.zig");
const util = @import("../util.zig");
const posix = std.posix;
const stdout = std.io.getStdOut();
const os = std.os;
const ScreenSize = util.ScreenSize;
const Color = cell.Color;
const IndexedColor = cell.IndexedColor;
const RgbColor = cell.RgbColor;
const Attribute = cell.Attribute;

const LinuxTty = @This();

handle: posix.fd_t,
orig_termios: posix.termios,
buf: std.io.BufferedWriter(4096, std.fs.File.Writer),

pub fn init() !LinuxTty {
    const handle = stdout.handle;

    return .{
        .orig_termios = try posix.tcgetattr(handle),
        .handle = handle,
        .buf = std.io.bufferedWriter(stdout.writer()),
    };
}

pub fn newScreen(self: *LinuxTty) !void {
    try self.buf.writer().print("\x1b[?1049h", .{});
}

pub fn endScreen(self: *LinuxTty) !void {
    try self.buf.writer().print("\x1b[?1049l", .{});
}

pub fn saveScreen(self: *LinuxTty) !void {
    try self.buf.writer().print("\x1b[?47h", .{});
}

pub fn restoreScreen(self: *LinuxTty) !void {
    try self.buf.writer().print("\x1b[?47l", .{});
}

pub fn clearScreen(self: *LinuxTty) !void {
    try self.buf.writer().print("\x1b[2J", .{});
}

pub inline fn flush(self: *LinuxTty) !void {
    try self.buf.flush();
}

pub inline fn screenSize(self: *const LinuxTty) !ScreenSize {
    var ws: posix.winsize = undefined;

    const err = std.os.linux.ioctl(self.handle, posix.T.IOCGWINSZ, @intFromPtr(&ws));
    if (posix.errno(err) != .SUCCESS) {
        return error.IoctlError;
    }

    return ScreenSize{ .cols = ws.ws_col, .rows = ws.ws_row };
}

pub fn enterRawMode(self: *LinuxTty) !void {
    const orig_termios = try posix.tcgetattr(self.handle);
    var termios = orig_termios;

    termios.iflag.IGNBRK = false;
    termios.iflag.BRKINT = false;
    termios.iflag.PARMRK = false;
    termios.iflag.ICRNL = false;
    termios.iflag.IGNCR = false;
    termios.iflag.INPCK = false;
    termios.iflag.ISTRIP = false;
    termios.iflag.IXON = false;
    termios.lflag.ECHO = false;
    termios.lflag.ECHONL = false;
    termios.lflag.ICANON = false;
    termios.lflag.IEXTEN = false;
    termios.lflag.ISIG = false;
    termios.cflag.CSIZE = .CS8;
    termios.cflag.PARENB = false;
    termios.oflag.OPOST = false;
    termios.cc[@intFromEnum(posix.V.MIN)] = 0;
    termios.cc[@intFromEnum(posix.V.TIME)] = 0;

    try posix.tcsetattr(self.handle, .FLUSH, termios);
    self.orig_termios = orig_termios;
}

pub fn exitRawMode(self: *const LinuxTty) !void {
    try posix.tcsetattr(self.handle, .FLUSH, self.orig_termios);
}

pub inline fn setCursor(self: *LinuxTty, x: u16, y: u16) !void {
    try self.buf.writer().print("\x1b[{d};{d}H", .{ y, x });
}

pub fn hideCursor(self: *LinuxTty) !void {
    try self.buf.writer().print("\x1b[?25l", .{});
}

pub fn showCursor(self: *LinuxTty) !void {
    try self.buf.writer().print("\x1b[?25h", .{});
}

pub inline fn putChar(self: *LinuxTty, char: u21) !void {
    var encoded_char: [4]u8 = undefined;
    const len = try std.unicode.utf8Encode(char, &encoded_char);
    try self.buf.writer().print("{s}", .{encoded_char[0..len]});
}

pub inline fn setFg(self: *LinuxTty, color: Color) !void {
    switch (color) {
        .indexed => |*indexed| try setIndexedFg(self, indexed.*),
        .rgb => |*rgb| try setRgbFg(self, rgb.*),
    }
}

pub inline fn setBg(self: *LinuxTty, color: Color) !void {
    switch (color) {
        .indexed => |*indexed| try setIndexedBg(self, indexed.*),
        .rgb => |*rgb| try setRgbBg(self, rgb.*),
    }
}

pub inline fn setIndexedFg(self: *LinuxTty, color: IndexedColor) !void {
    try self.buf.writer().print("\x1b[38;5;{d}m", .{@intFromEnum(color)});
}

pub inline fn setIndexedBg(self: *LinuxTty, color: IndexedColor) !void {
    try self.buf.writer().print("\x1b[48;5;{d}m", .{@intFromEnum(color)});
}

pub inline fn setRgbFg(self: *LinuxTty, color: RgbColor) !void {
    try self.buf.writer().print("\x1b[38;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
}

pub inline fn setRgbBg(self: *LinuxTty, color: RgbColor) !void {
    try self.buf.writer().print("\x1b[48;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
}

pub inline fn setAttr(self: *LinuxTty, attr: Attribute) !void {
    try self.buf.writer().print("\x1b[{d}m", .{@intFromEnum(attr)});
}
