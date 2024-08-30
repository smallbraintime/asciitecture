const std = @import("std");
const tbackend = @import("backend/main.zig");
const TerminalBackend = tbackend.TerminalBackend;
const Color = tbackend.Color;
const Attribute = tbackend.Attribute;
const Buffer = @import("Buffer.zig");
const Cell = @import("Cell.zig");

const Terminal = @This();

buffer: Buffer,
backend: TerminalBackend,
targetDelta: f32,
speed: f32,
deltaTime: f32,
fps: f32,

_currentTime: i128,
_ticks: u32,
_elapsedTime: f32,

pub fn init(allocator: std.mem.Allocator, backend: anytype, targetFps: f32, speed: f32) !Terminal {
    var backend_ = try backend.init();

    try backend_.newScreen();
    try backend_.rawMode();
    try backend_.hideCursor();

    const screenSize = try backend_.screenSize();

    var buf = try std.ArrayList(Cell).initCapacity(allocator, screenSize.x * screenSize.y);
    try buf.appendNTimes(
        .{
            .char = ' ',
            .fg = .{ .indexed = .default },
            .bg = .{ .indexed = .default },
            .attr = .reset,
        },
        screenSize.y * screenSize.x,
    );
    try buf.ensureTotalCapacity(screenSize.y * screenSize.x);

    const buffer = Buffer{
        .buf = buf,
        .height = screenSize.y,
        .width = screenSize.x,
    };

    return Terminal{
        .buffer = buffer,
        .backend = backend_,
        .targetDelta = 1 / targetFps,
        .speed = speed,
        .deltaTime = 0.0,
        .fps = 0,
        ._currentTime = std.time.nanoTimestamp(),
        ._ticks = 0,
        ._elapsedTime = 0,
    };
}

pub fn deinit(self: *Terminal) void {
    self.buffer.buf.deinit();
}

pub fn draw(self: *Terminal) !void {
    const newTime = std.time.nanoTimestamp();
    self.deltaTime = @as(f32, @floatFromInt(newTime - self._currentTime)) / std.time.ns_per_s;
    self._currentTime = newTime;

    self.calcFps();

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
    self.buffer.clear();

    if (self.deltaTime < self.targetDelta) {
        std.time.sleep(@intFromFloat((self.targetDelta - self.deltaTime * self.speed) * std.time.ns_per_s));
    }
}

pub fn transition(animation: fn (*Buffer) void) void {
    _ = animation;
}

fn calcFps(self: *Terminal) void {
    self._elapsedTime += self.deltaTime;
    self._ticks += 1;

    if (self._elapsedTime >= 1.0) {
        self.fps = @as(f32, @floatFromInt(self._ticks)) / self._elapsedTime;
        self._ticks = 0;
        self._elapsedTime = 0;
    }
}
