const std = @import("std");
const tbackend = @import("backend/main.zig");
const TerminalBackend = tbackend.TerminalBackend;
const Color = tbackend.Color;
const Attributes = tbackend.Attributes;
const Buffer = @import("Buffer.zig");
const Cell = @import("Cell.zig");

const Terminal = @This();

buffer: Buffer,
backend: TerminalBackend,
tick: u64,

pub fn init(allocator: std.mem.Allocator, tick: u64) !Terminal {
    var backend = try TerminalBackend.init();

    try backend.newScreen();
    try backend.rawMode();
    try backend.hideCursor();

    const screenSize = try backend.screenSize();
    const x = screenSize.x;
    const y = screenSize.y;

    var buf = try std.ArrayList(Cell).initCapacity(allocator, x * y);
    try buf.appendNTimes(
        .{
            .char = ' ',
            .fg = Color.default,
            .bg = Color.default,
            .attr = Attributes.reset,
        },
        y * x,
    );
    try buf.ensureTotalCapacity(y * x);

    const buffer = Buffer{
        .buf = buf,
        .height = y,
        .width = x,
    };

    return Terminal{
        .buffer = buffer,
        .backend = backend,
        .tick = tick,
    };
}

pub fn draw(self: *Terminal) !void {
    std.time.sleep(self.tick);
    const buf = &self.buffer;
    const backend = &self.backend;
    for (0..buf.height) |y| {
        for (0..buf.width) |x| {
            const cell = buf.buf.items[y * buf.width + x];
            try backend.setCursor(@intCast(x), @intCast(y));
            try backend.setFg(cell.fg);
            try backend.setBg(cell.bg);
            // try backend.setAttr(cell.attr);
            try backend.putChar(cell.char);
        }
    }

    try backend.flush();
    // try backend.clearScreen();
    self.buffer.clear();
}

pub fn transition(animation: fn (*Buffer) void) void {
    _ = animation;
}

pub fn deinit(self: *Terminal) void {
    self.buffer.buf.deinit();
}
