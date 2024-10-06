const std = @import("std");
const tbackend = @import("backend/main.zig");
const LinuxTty = tbackend.LinuxTty;
const Color = tbackend.Color;
const Attribute = tbackend.Attribute;
const Screen = @import("Screen.zig");
const Cell = @import("Cell.zig");
const ScreenSize = tbackend.ScreenSize;

pub fn Terminal(comptime T: type) type {
    return struct {
        screen: Screen,
        backend: T,
        target_delta: f32,
        delta_time: f32,
        speed: f32,
        fps: f32,
        minimized: bool,

        _current_time: i128,

        pub fn init(allocator: std.mem.Allocator, target_fps: f32, speed: f32) !Terminal(T) {
            var backend_ = try T.init();
            try backend_.rawMode();
            try backend_.hideCursor();
            try backend_.newScreen();
            try backend_.flush();
            const screen_size = try backend_.screenSize();
            const screen = try Screen.init(allocator, screen_size.width, screen_size.height);
            const delta = 1 / target_fps;

            return .{
                .screen = screen,
                .backend = backend_,
                .target_delta = delta,
                .delta_time = delta,
                .speed = speed,
                .fps = 0.0,
                .minimized = false,
                ._current_time = std.time.nanoTimestamp(),
            };
        }

        pub fn deinit(self: *Terminal(T)) !void {
            try self.backend.normalMode();
            try self.backend.showCursor();
            try self.backend.clearScreen();
            try self.backend.endScreen();
            try self.backend.flush();
            self.screen.buf.deinit();
        }

        pub fn draw(self: *Terminal(T)) !void {
            try self.handleResize();
            self.calcFps();
            if (!self.minimized) {
                try self.drawFrame();
            }
        }

        fn drawFrame(self: *Terminal(T)) !void {
            const buf = &self.screen;
            const backend = &self.backend;
            for (0..buf.size.height) |y| {
                for (0..buf.size.width) |x| {
                    const cell = buf.buf.items[y * buf.size.width + x];
                    try backend.setCursor(@intCast(x), @intCast(y));
                    try backend.setFg(cell.fg);
                    try backend.setBg(cell.bg);
                    if (cell.attr) |attr| {
                        try backend.setAttr(attr);
                    }
                    try backend.putChar(cell.char);
                }
            }
            try backend.flush();
            self.screen.clear();

            const new_time = std.time.nanoTimestamp();
            const draw_time = @as(f32, @floatFromInt(new_time - self._current_time)) / std.time.ns_per_s;
            self._current_time = new_time;

            if (draw_time < self.target_delta) {
                const delayTime = self.target_delta - draw_time;
                std.time.sleep(@intFromFloat(delayTime * std.time.ns_per_s));
                self.delta_time = draw_time + delayTime;
            } else {
                self.delta_time = draw_time;
            }
        }

        fn handleResize(self: *Terminal(T)) !void {
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

        fn calcFps(self: *Terminal(T)) void {
            self.fps = 1.0 / self.delta_time;
        }

        pub fn transition(self: *Terminal(T), animation: fn (*Screen) void) void {
            _ = self;
            _ = animation;
        }
    };
}

test "frame draw benchmark" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const result = gpa.deinit();
        if (result == .leak) {
            @panic("memory leak occured");
        }
    }
    var term = try Terminal(LinuxTty).init(gpa.allocator(), 999, 1);

    const graphics = @import("graphics.zig");
    const math = @import("math.zig");
    graphics.drawLine(&term.screen, &math.vec2(50.0, 20.0), &math.vec2(-50.0, 20.0), &.{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .red }, .attr = null });
    graphics.drawRectangle(&term.screen, 10, 10, &math.vec2(0.0, 0.0), 0, &.{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .cyan }, .attr = null }, false);
    graphics.drawRectangle(&term.screen, 10, 10, &math.vec2(-20, -20), 0, &.{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .cyan }, .attr = null }, false);

    const start = std.time.milliTimestamp();
    try term.draw();
    const end = std.time.milliTimestamp();
    const result = end - start;
    try term.deinit();
    std.debug.print("benchmark result: {d} ms", .{result});
}
