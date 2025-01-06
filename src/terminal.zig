const std = @import("std");
const style = @import("style.zig");
const Screen = @import("Screen.zig");
const Buffer = @import("Buffer.zig");
const Cell = style.Cell;
const Attribute = style.Attribute;
const Color = style.Color;
const IndexedColor = style.IndexedColor;
const Painter = @import("Painter.zig");
const Vec2 = @import("math.zig").Vec2;
const ScreenSize = Buffer.ScreenSize;

pub fn Terminal(comptime T: type) @TypeOf(T) {
    return struct {
        delta_time: f32,
        target_delta: f32,
        _backend: T,
        _last_screen: Buffer,
        _screen: Screen,
        _minimized: bool,
        _current_time: i128,
        _accumulator: f32,

        pub fn init(allocator: std.mem.Allocator, target_fps: f32) !Terminal(T) {
            var backend = try T.init();
            try backend.enterRawMode();
            try backend.hideCursor();
            try backend.newScreen();
            try backend.flush();

            var screen_size: [2]usize = undefined;
            try backend.screenSize(&screen_size);

            const screen = try Screen.init(allocator, .{ .cols = screen_size[0], .rows = screen_size[1] });
            const delta = 1 / target_fps;

            return .{
                .delta_time = delta,
                .target_delta = delta,
                ._backend = backend,
                ._screen = screen,
                ._last_screen = try screen.buffer.clone(),
                ._minimized = false,
                ._current_time = std.time.nanoTimestamp(),
                ._accumulator = 0.0,
            };
        }

        pub fn deinit(self: *Terminal(T)) !void {
            self._screen.deinit();
            self._last_screen.deinit();
            try self._backend.exitRawMode();
            try self._backend.showCursor();
            try self._backend.clearScreen();
            try self._backend.endScreen();
            try self._backend.flush();
        }

        pub fn painter(self: *Terminal(T)) Painter {
            return Painter.init(&self._screen);
        }

        pub fn draw(self: *Terminal(T)) !void {
            try self.handleResize();
            if (!self._minimized) {
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

                try self.drawFrame();
            }
        }

        pub fn setViewPos(self: *Terminal(T), pos: *const Vec2) void {
            self.screen.setView(pos);
        }

        pub fn setBg(self: *Terminal(T), color: Color) void {
            self._screen.setBg(color);
        }

        fn drawFrame(self: *Terminal(T)) !void {
            for (0..self._screen.buffer.size.rows) |y| {
                for (0..self._screen.buffer.size.cols) |x| {
                    const cell = &self._screen.buffer.buf.items[y * self._screen.buffer.size.cols + x];
                    const last_cell = &self._last_screen.buf.items[y * self._last_screen.size.cols + x];

                    if (!std.meta.eql(cell, last_cell)) {
                        try self._backend.setAttr(@intFromEnum(Attribute.reset));
                        try self._backend.setCursor(@intCast(x), @intCast(y));
                        switch (cell.fg) {
                            .indexed => |*indexed| try self._backend.setIndexedFg(@intFromEnum(indexed.*)),
                            .rgb => |*rgb| try self._backend.setRgbFg(rgb.r, rgb.g, rgb.b),
                            else => {},
                        }
                        switch (cell.bg) {
                            .indexed => |*indexed| try self._backend.setIndexedBg(@intFromEnum(indexed.*)),
                            .rgb => |*rgb| try self._backend.setRgbBg(rgb.r, rgb.g, rgb.b),
                            else => {},
                        }
                        if (cell.attr != .none) {
                            try self._backend.setAttr(@intFromEnum(cell.attr));
                        }
                        try self._backend.putChar(cell.char);
                    }
                }
            }
            try self._last_screen.replace(&self._screen.buffer.buf.items);
            try self._backend.flush();
            self._screen.clear();
        }

        // This can be handled by the signal
        fn handleResize(self: *Terminal(T)) !void {
            var screen_size: [2]usize = undefined;
            try self._backend.screenSize(&screen_size);
            if (screen_size[0] != self._screen.buffer.size.cols or screen_size[0] != self._screen.buffer.size.cols) {
                if (screen_size[0] == 0 and screen_size[1] == 0) {
                    self._minimized = true;
                }
                try self._screen.resize(screen_size[0], screen_size[1]);
                try self._last_screen.resize(screen_size[0], screen_size[1]);
                try self._backend.clearScreen();
            }
            self._minimized = false;
        }
    };
}
