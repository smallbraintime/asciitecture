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
        _fixed_offset: ?ScreenSize,
        _term_size: ScreenSize,
        _backend: T,
        _prev_screen: Buffer,
        _screen: Screen,
        _minimized: bool,
        _current_time: i128,

        pub fn init(allocator: std.mem.Allocator, target_fps: f32, comptime size: ?ScreenSize) !Terminal(T) {
            var backend = try T.init();
            try backend.enterRawMode();
            try backend.hideCursor();
            try backend.newScreen();
            try backend.flush();

            var screen_size: [2]usize = undefined;
            try backend.screenSize(&screen_size);
            const term_size = ScreenSize{ .rows = screen_size[0], .cols = screen_size[1] };

            // if size of the screen is set fixed, then init fixed offset which is offset required to draw screen in the middle
            var screen: Screen = undefined;
            var fixed_offset: ?ScreenSize = undefined;
            if (size) |s| {
                if (screen_size[0] > s.cols and screen_size[1] > s.rows) {
                    fixed_offset = .{ .cols = (screen_size[0] - s.cols) / 2, .rows = (screen_size[1] - s.rows) / 2 };
                } else {
                    fixed_offset = .{ .cols = 0, .rows = 0 };
                }
                screen = try Screen.init(allocator, s);
                try backend.restoreColors();
                try backend.clearScreen();
                try backend.flush();
            } else {
                fixed_offset = null;
                screen = try Screen.init(allocator, .{ .cols = screen_size[0], .rows = screen_size[1] });
            }

            const delta = 1 / target_fps;

            return .{
                .delta_time = delta,
                .target_delta = delta,
                ._fixed_offset = fixed_offset,
                ._term_size = term_size,
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
            try self.handleResize();
        }

        pub fn setViewPos(self: *Terminal(T), pos: *const Vec2) void {
            self._screen.setViewPos(pos);
        }

        pub fn setBg(self: *Terminal(T), color: Color) void {
            self._screen.setBg(color);
        }

        fn drawFrame(self: *Terminal(T)) !void {
            var start_row: usize = 0;
            var start_col: usize = 0;
            if (self._fixed_offset) |offset| {
                start_row = offset.rows;
                start_col = offset.cols;
            }

            for (0..self._screen.buffer.size.rows) |y| {
                for (0..self._screen.buffer.size.cols) |x| {
                    const cell = &self._screen.buffer.buf.items[y * self._screen.buffer.size.cols + x];
                    const last_cell = &self._prev_screen.buf.items[y * self._prev_screen.size.cols + x];

                    if (!std.meta.eql(cell, last_cell)) {
                        try self._backend.setAttr(@intFromEnum(Attribute.reset));
                        try self._backend.setCursor(@intCast(x + start_col), @intCast(y + start_row));
                        if (cell.fg) |fg| {
                            try self._backend.setRgbFg(fg.r, fg.g, fg.b);
                        }
                        if (cell.bg) |bg| {
                            try self._backend.setRgbBg(bg.r, bg.g, bg.b);
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
            var screen_size: [2]usize = undefined;
            try self._backend.screenSize(&screen_size);

            if (screen_size[0] != self._term_size.cols or screen_size[1] != self._term_size.rows) {
                self._term_size.cols = screen_size[0];
                self._term_size.rows = screen_size[1];

                if (screen_size[0] == 0 and screen_size[1] == 0) {
                    self._minimized = true;
                }

                if (self._fixed_offset != null) {
                    if (screen_size[0] > self._screen.buffer.size.cols and screen_size[1] > self._screen.buffer.size.rows) {
                        self._fixed_offset = .{ .cols = (screen_size[0] - self._screen.buffer.size.cols) / 2, .rows = (screen_size[1] - self._screen.buffer.size.rows) / 2 };
                    } else {
                        self._fixed_offset = .{ .cols = 0, .rows = 0 };
                    }

                    // // temporary idea to solve this
                    // for (0..self._term_size.rows) |r| {
                    //     for (0..self._term_size.cols) |c| {
                    //         try self._backend.setCursor(r, c);
                    //         try self._backend.setIndexedFg(@intFromEnum(IndexedColor.black));
                    //         try self._backend.setIndexedBg(@intFromEnum(IndexedColor.black));
                    //     }
                    // }
                    try self._backend.restoreColors();
                    try self._backend.clearScreen();
                    try self._backend.flush();
                } else {
                    try self._screen.resize(screen_size[0], screen_size[1]);
                    try self._prev_screen.resize(screen_size[0], screen_size[1]);
                    try self._backend.clearScreen();
                    try self._backend.flush();
                }
            }
            self._minimized = false;
        }
    };
}
