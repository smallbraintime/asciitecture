const std = @import("std");
const tbackend = @import("backend/main.zig");
const Tty = tbackend.Tty;
const Color = tbackend.Color;
const Attribute = tbackend.Attribute;
const Screen = @import("Screen.zig");
const Cell = @import("Cell.zig");
const ScreenSize = tbackend.ScreenSize;

const Terminal = @This();

screen: Screen,
backend: Tty,
targetDelta: f32,
deltaTime: f32,
speed: f32,
fps: f32,
minimized: bool,

_currentTime: i128,

pub fn init(allocator: std.mem.Allocator, backend: anytype, target_fps: f32, speed: f32) !Terminal {
    var backend_ = try backend.init();
    try backend_.newScreen();
    try backend_.rawMode();
    try backend_.hideCursor();
    const screen_size = try backend_.screenSize();
    const screen = try Screen.init(allocator, screen_size.width, screen_size.height);
    const delta = 1 / target_fps;

    return Terminal{
        .screen = screen,
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
    self.screen.buf.deinit();
    self.backend.endScreen() catch {};
}

pub fn draw(self: *Terminal) !void {
    try self.handle_resize();
    self.calcFps();
    if (!self.minimized) {
        try self.draw_screen();
    }
}

fn draw_screen(self: *Terminal) !void {
    const buf = &self.screen;
    const backend = &self.backend;
    for (0..buf.size.height) |y| {
        for (0..buf.size.width) |x| {
            const cell = buf.buf.items[y * buf.size.width + x];
            try backend.setCursor(@intCast(x), @intCast(y));
            try backend.setFg(cell.fg);
            try backend.setBg(cell.bg);
            // try backend.setAttr(cell.attr);
            try backend.putChar(cell.char);
        }
    }
    try backend.flush();
    self.screen.clear();

    const new_time = std.time.nanoTimestamp();
    const draw_time = @as(f32, @floatFromInt(new_time - self._currentTime)) / std.time.ns_per_s;
    self._currentTime = new_time;

    if (draw_time < self.targetDelta) {
        const delayTime = self.targetDelta - draw_time;
        std.time.sleep(@intFromFloat(delayTime * std.time.ns_per_s));
        self.deltaTime = draw_time + delayTime;
    } else {
        self.deltaTime = draw_time;
    }
}

fn handle_resize(self: *Terminal) !void {
    const screen_size = try self.backend.screenSize();
    if (!std.meta.eql(screen_size, self.screen.size)) {
        if (screen_size.width == 0 and screen_size.height == 0) {
            self.minimized = true;
        }
        try self.screen.resize(screen_size.width, screen_size.height);
        try self.backend.clearScreen();
    }
    self.minimized = false;
}

fn calcFps(self: *Terminal) void {
    self.fps = 1.0 / self.deltaTime;
}

pub fn transition(animation: fn (*Screen) void) void {
    _ = animation;
}
