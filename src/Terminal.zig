const std = @import("std");
const tbackend = @import("backend/main.zig");
const TerminalBackend = tbackend.TerminalBackend;
const Color = tbackend.Color;
const Attribute = tbackend.Attribute;
const Buffer = @import("Buffer.zig");
const Cell = @import("Cell.zig");
const ScreenSize = tbackend.ScreenSize;

const Terminal = @This();

buffer: Buffer,
backend: TerminalBackend,
targetDelta: f32,
deltaTime: f32,
speed: f32,
fps: f32,
minimized: bool,

_currentTime: i128,

pub fn init(allocator: std.mem.Allocator, backend: anytype, targetFps: f32, speed: f32) !Terminal {
    var backend_ = try backend.init();
    try backend_.newScreen();
    try backend_.rawMode();
    try backend_.hideCursor();
    const screenSize = try backend_.screenSize();

    var buffer = try Buffer.init(allocator, screenSize.width, screenSize.height);
    buffer.setViewport(0, 0, screenSize.width, screenSize.height);

    const delta = 1 / targetFps;
    return Terminal{
        .buffer = buffer,
        .backend = backend_,
        .targetDelta = delta,
        .deltaTime = delta,
        .speed = speed,
        .fps = 0.0,
        .minimized = false,
        ._currentTime = std.time.nanoTimestamp(),
    };
}

pub fn deinit(self: *Terminal) void {
    self.buffer.buf.deinit();
}

pub fn draw(self: *Terminal) !void {
    try self.handle_resize();
    self.calcFps();
    if (!self.minimized) {
        try self.render();
    }
}

fn render(self: *Terminal) !void {
    const buf = &self.buffer;
    const backend = &self.backend;
    for (buf.viewport.y..buf.viewport.height) |y| {
        for (buf.viewport.x..buf.viewport.width) |x| {
            const cell = buf.buf.items[y * buf.size.width + x];
            try backend.setCursor(@intCast(x), @intCast(y));
            try backend.setFg(cell.fg);
            try backend.setBg(cell.bg);
            // try backend.setAttr(cell.attr);
            try backend.putChar(cell.char);
        }
    }
    try backend.flush();
    self.buffer.clear();

    const newTime = std.time.nanoTimestamp();
    const drawTime = @as(f32, @floatFromInt(newTime - self._currentTime)) / std.time.ns_per_s;
    self._currentTime = newTime;

    if (drawTime < self.targetDelta) {
        const delayTime = self.targetDelta - drawTime;
        std.time.sleep(@intFromFloat(delayTime * std.time.ns_per_s));
        self.deltaTime = drawTime + delayTime;
    } else {
        self.deltaTime = drawTime;
    }
}

fn handle_resize(self: *Terminal) !void {
    const screenSize = try self.backend.screenSize();
    if (!std.meta.eql(screenSize, self.buffer.size)) {
        if (screenSize.width == 0 and screenSize.height == 0) {
            self.minimized = true;
        }
        try self.buffer.resize(screenSize.width, screenSize.height);
        try self.backend.clearScreen();
    }

    self.minimized = false;
}

fn calcFps(self: *Terminal) void {
    self.fps = 1.0 / self.deltaTime;
}

pub fn transition(animation: fn (*Buffer) void) void {
    _ = animation;
}
