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
tick: u64,
speed: u16,
deltaTime: i128,
previousTime: i128,
frameCount: u64,
fps: u64,
fpsTimer: i128,

pub fn init(allocator: std.mem.Allocator, backend: anytype, targetFps: u64, speed: u16) !Terminal {
    var backend_ = try backend.init();

    try backend_.newScreen();
    try backend_.rawMode();
    try backend_.hideCursor();

    const screenSize = try backend_.screenSize();

    var buf = try std.ArrayList(Cell).initCapacity(allocator, screenSize.x * screenSize.y);
    try buf.appendNTimes(
        .{
            .char = ' ',
            .fg = .default,
            .bg = .default,
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
        .tick = 1000000000 / targetFps,
        .speed = speed,
        .deltaTime = 0,
        .previousTime = std.time.nanoTimestamp(),
        .frameCount = 0,
        .fps = 0,
        .fpsTimer = 0,
    };
}

pub fn draw(self: *Terminal) !void {
    const currentTime = std.time.nanoTimestamp();
    self.deltaTime = currentTime - self.deltaTime;
    self.previousTime = currentTime;

    self.frameCount += 1;
    self.fpsTimer += self.deltaTime;

    if (self.fpsTimer >= 1000000000) {
        self.fps = self.frameCount;
        self.frameCount = 0;
        self.fpsTimer = 0;
    }

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

    if (self.deltaTime < self.tick) {
        std.time.sleep(@intCast(self.tick - self.deltaTime * self.speed));
        self.buffer.setCell(5, 15, .{ .fg = .green, .bg = .black, .attr = .reset, .char = 'd' });
    }
}

pub fn transition(animation: fn (*Buffer) void) void {
    _ = animation;
}

pub fn deinit(self: *Terminal) void {
    self.buffer.buf.deinit();
}
