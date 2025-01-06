const std = @import("std");
const builtin = @import("builtin");
const style = @import("style.zig");
const util = @import("util.zig");
const Color = style.Color;
const IndexedColor = style.IndexedColor;
const RgbColor = style.RgbColor;
const Attribute = style.Attribute;

const LinuxTty = @This();

handle: std.posix.fd_t,
orig_termios: std.posix.termios,
buf: std.io.BufferedWriter(4096, std.fs.File.Writer),

pub fn init() !LinuxTty {
    if (builtin.os.tag != .linux) @panic("System not supported");

    const handle = std.io.getStdOut().handle;

    return .{
        .orig_termios = try std.posix.tcgetattr(handle),
        .handle = handle,
        .buf = std.io.bufferedWriter(std.io.getStdOut().writer()),
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

pub inline fn screenSize(self: *const LinuxTty, size: []usize) !void {
    var ws: std.posix.winsize = undefined;

    const err = std.os.linux.ioctl(self.handle, std.posix.T.IOCGWINSZ, @intFromPtr(&ws));
    if (std.posix.errno(err) != .SUCCESS) {
        return error.IoctlError;
    }

    size[0] = ws.ws_col;
    size[1] = ws.ws_row;
}

pub fn enterRawMode(self: *LinuxTty) !void {
    const orig_termios = try std.posix.tcgetattr(self.handle);
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
    termios.cc[@intFromEnum(std.posix.V.MIN)] = 0;
    termios.cc[@intFromEnum(std.posix.V.TIME)] = 0;

    try std.posix.tcsetattr(self.handle, .FLUSH, termios);
    self.orig_termios = orig_termios;
}

pub fn exitRawMode(self: *const LinuxTty) !void {
    try std.posix.tcsetattr(self.handle, .FLUSH, self.orig_termios);
}

pub inline fn setCursor(self: *LinuxTty, x: usize, y: usize) !void {
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

pub inline fn setIndexedFg(self: *LinuxTty, color: u8) !void {
    try self.buf.writer().print("\x1b[38;5;{d}m", .{color});
}

pub inline fn setIndexedBg(self: *LinuxTty, color: u8) !void {
    try self.buf.writer().print("\x1b[48;5;{d}m", .{color});
}

pub inline fn setRgbFg(self: *LinuxTty, r: u8, g: u8, b: u8) !void {
    try self.buf.writer().print("\x1b[38;2;{d};{d};{d}m", .{ r, g, b });
}

pub inline fn setRgbBg(self: *LinuxTty, r: u8, g: u8, b: u8) !void {
    try self.buf.writer().print("\x1b[48;2;{d};{d};{d}m", .{ r, g, b });
}

pub inline fn setAttr(self: *LinuxTty, attribute: u8) !void {
    try self.buf.writer().print("\x1b[{d}m", .{attribute});
}
