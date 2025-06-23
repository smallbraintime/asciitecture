const std = @import("std");
const style = @import("style.zig");
const Screen = @import("Screen.zig");
const Buffer = @import("Buffer.zig");
const Cell = style.Cell;
const Attribute = style.Attribute;
const Color = style.Color;
const Painter = @import("Painter.zig");
const Vec2 = @import("math.zig").Vec2;
const ScreenSize = Buffer.ScreenSize;

pub fn Terminal(comptime T: type) type {
    return struct {
        delta_time: f32,
        target_delta: f32,
        win_size: ScreenSize,
        _win_offset: ?ScreenSize,
        _backend: T,
        _prev_screen: Buffer,
        _screen: Screen,
        _minimized: bool,
        _current_time: i128,

        pub fn init(
            allocator: std.mem.Allocator,
            target_fps: f32,
            comptime size: ?ScreenSize,
        ) !Terminal(T) {
            var backend = try T.init();
            try backend.enterRawMode();
            try backend.hideCursor();
            try backend.newScreen();
            try backend.flush();

            const ws = try backend.screenSize();
            const win_size = ScreenSize{ .height = ws[0], .width = ws[1] };

            // if size of the screen is set fixed,
            // then init fixed offset which is offset required to draw screen in the middle
            var screen: Screen = undefined;
            var win_offset: ?ScreenSize = undefined;
            if (size) |s| {
                if (win_size.width > s.width and win_size.height > s.height) {
                    win_offset = .{
                        .width = (win_size.width - s.width) / 2,
                        .height = (win_size.height - s.height) / 2,
                    };
                } else {
                    win_offset = .{ .width = 0, .height = 0 };
                }

                screen = try Screen.init(allocator, s);
                try backend.restoreColors();
                try backend.clearScreen();
                try backend.flush();
            } else {
                win_offset = null;
                screen = try Screen.init(
                    allocator,
                    .{ .width = win_size.width, .height = win_size.height },
                );
            }

            const delta = 1 / target_fps;

            return .{
                .delta_time = delta,
                .target_delta = delta,
                .win_size = win_size,
                ._win_offset = win_offset,
                ._backend = backend,
                ._screen = screen,
                ._prev_screen = try screen.buffer.clone(),
                ._minimized = false,
                ._current_time = std.time.nanoTimestamp(),
            };
        }

        pub fn deinit(self: *Terminal(T)) !void {
            self._screen.deinit();
            self._prev_screen.deinit();
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
            if (!self._minimized) {
                const new_time = std.time.nanoTimestamp();
                const draw_time =
                    @as(f32, @floatFromInt(new_time - self._current_time)) / std.time.ns_per_s;
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
            try self.handleResize();
        }

        pub fn setViewPos(self: *Terminal(T), pos: *const Vec2) void {
            self._screen.setViewPos(pos);
        }

        pub fn getViewPos(self: *Terminal(T)) Vec2 {
            return self._screen.view;
        }

        pub fn setBg(self: *Terminal(T), color: Color) void {
            self._screen.setBg(color);
        }

        fn drawFrame(self: *Terminal(T)) !void {
            var start_row: usize = 0;
            var start_col: usize = 0;

            if (self._win_offset) |offset| {
                start_row = offset.height;
                start_col = offset.width;
            }

            for (0..self._screen.buffer.size.height) |y| {
                for (0..self._screen.buffer.size.width) |x| {
                    const cell = self._screen.buffer.buf.items[y * self._screen.buffer.size.width + x];
                    const last_cell = self._prev_screen.buf.items[y * self._prev_screen.size.width + x];

                    if (!cell.eql(last_cell)) {
                        try self._backend.setAttr(@intFromEnum(Attribute.reset));

                        try self._backend.setCursor(@intCast(x + start_col), @intCast(y + start_row));

                        if (cell.fg) |fg| {
                            try self._backend.setFg(fg.r(), fg.g(), fg.b());
                        }

                        if (cell.bg) |bg| {
                            try self._backend.setBg(bg.r(), bg.g(), bg.b());
                        }

                        if (cell.attr != .none) {
                            try self._backend.setAttr(@intFromEnum(cell.attr));
                        }

                        try self._backend.putChar(cell.char);
                    }
                }
            }

            try self._prev_screen.replace(&self._screen.buffer.buf.items);
            try self._backend.flush();
            self._screen.clear();
        }

        // This can be handled by the signal
        fn handleResize(self: *Terminal(T)) !void {
            const ws = try self._backend.screenSize();

            if (ws[0] != self.win_size.width or ws[1] != self.win_size.height) {
                self.win_size.width = ws[0];
                self.win_size.height = ws[1];

                if (ws[0] == 0 and ws[1] == 0) self._minimized = true;

                if (self._win_offset) |*offset| {
                    if (ws[0] > self._screen.buffer.size.width) {
                        offset.width = (ws[0] - self._screen.buffer.size.width) / 2;
                    } else {
                        offset.width = 0;
                    }
                    if (ws[1] > self._screen.buffer.size.height) {
                        offset.height = (ws[1] - self._screen.buffer.size.height) / 2;
                    } else {
                        offset.height = 0;
                    }

                    try self._backend.restoreColors();
                    try self._backend.clearScreen();
                    try self._backend.flush();
                    self._prev_screen.clear();
                } else {
                    try self._screen.resize(ws[0], ws[1]);
                    try self._prev_screen.resize(ws[0], ws[1]);
                    try self._backend.clearScreen();
                    try self._backend.flush();
                }
            }
            self._minimized = false;
        }
    };
}
