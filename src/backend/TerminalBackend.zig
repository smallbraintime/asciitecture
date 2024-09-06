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

const TerminalBackend = @This();

handle: posix.fd_t,
orig_termios: posix.termios,
buf: std.io.BufferedWriter(4096, std.fs.File.Writer),

pub fn init() !TerminalBackend {
    switch (builtin.os.tag) {
        .linux => {
            const handle = stdout.handle;
            return TerminalBackend{
                .orig_termios = try posix.tcgetattr(handle),
                .handle = handle,
                .buf = std.io.bufferedWriter(stdout.writer()),
            };
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn newScreen(self: *TerminalBackend) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[?1049h", .{});
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn endScreen(self: *TerminalBackend) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[?1049l", .{});
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn clearScreen(self: *TerminalBackend) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[2J", .{});
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn flush(self: *TerminalBackend) !void {
    try self.buf.flush();
}

pub fn screenSize(self: *const TerminalBackend) !ScreenSize {
    switch (builtin.os.tag) {
        .linux => {
            var ws: posix.winsize = undefined;

            const err = std.os.linux.ioctl(self.handle, posix.T.IOCGWINSZ, @intFromPtr(&ws));
            if (posix.errno(err) != .SUCCESS) {
                return error.IoctlError;
            }

            return ScreenSize{ .width = ws.ws_col, .height = ws.ws_row };
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

pub fn setCursor(self: *TerminalBackend, x: u16, y: u16) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[{d};{d}H", .{ y, x });
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn hideCursor(self: *TerminalBackend) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[?25l", .{});
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn showCursor(self: *TerminalBackend) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[?25h", .{});
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn putChar(self: *TerminalBackend, char: u21) !void {
    switch (builtin.os.tag) {
        .linux => {
            var encodedChar: [4]u8 = undefined;
            const len = try std.unicode.utf8Encode(char, &encodedChar);
            try self.buf.writer().print("{s}", .{encodedChar[0..len]});
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn setFg(self: *TerminalBackend, color: Color) !void {
    switch (builtin.os.tag) {
        .linux => {
            switch (color) {
                .indexed => |*indexed| try setIndexedFg(self, indexed.*),
                .rgb => |*rgb| try setRgbFg(self, rgb.*),
            }
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn setBg(self: *TerminalBackend, color: Color) !void {
    switch (builtin.os.tag) {
        .linux => {
            switch (color) {
                .indexed => |*indexed| try setIndexedBg(self, indexed.*),
                .rgb => |*rgb| try setRgbBg(self, rgb.*),
            }
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn setIndexedFg(self: *TerminalBackend, color: IndexedColor) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[38;5;{d}m", .{@intFromEnum(color)});
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn setIndexedBg(self: *TerminalBackend, color: IndexedColor) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[48;5;{d}m", .{@intFromEnum(color)});
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn setRgbFg(self: *TerminalBackend, color: RgbColor) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[38;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn setRgbBg(self: *TerminalBackend, color: RgbColor) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[48;2;{d};{d};{d}m", .{ color.r, color.g, color.b });
        },
        else => @compileError("not implemented yet"),
    }
}

pub fn setAttr(self: *TerminalBackend, attr: Attribute) !void {
    switch (builtin.os.tag) {
        .linux => {
            try self.buf.writer().print("\x1b[{d}m", .{@intFromEnum(attr)});
        },
        else => @compileError("not implemented yet"),
    }
}
