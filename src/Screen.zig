const std = @import("std");
const math = @import("math.zig");
const style = @import("style.zig");
const Buffer = @import("Buffer.zig");
const ScreenSize = Buffer.ScreenSize;
const Cell = style.Cell;
const Color = style.Color;
const Attribute = style.Attribute;
const Vec2 = math.Vec2;
const vec2 = math.vec2;

const View = struct {
    pos: Vec2,
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,
};

const Screen = @This();

buffer: Buffer,
center: Vec2,
view: View,
bg: Color,

pub fn init(allocator: std.mem.Allocator, screen_size: ScreenSize) !Screen {
    const buf = try Buffer.init(allocator, screen_size);

    var screen = Screen{
        .buffer = buf,
        .center = Vec2.fromInt(screen_size.cols, screen_size.rows).div(&vec2(2, 2)),
        .view = undefined,
        .bg = .{ .indexed = .black },
    };
    screen.setViewPos(&vec2(0, 0));

    return screen;
}

pub fn deinit(self: *Screen) void {
    self.buffer.deinit();
}

pub fn resize(self: *Screen, cols: usize, rows: usize) !void {
    self.center = Vec2.fromInt(cols, rows).div(&vec2(2, 2));
    try self.buffer.resize(cols, rows);
}

pub inline fn setViewPos(self: *Screen, pos: *const Vec2) void {
    const size = pos.add(&vec2(self.center.x() / 2, self.center.y() / 2));
    self.view = View{
        .pos = pos.*,
        .left = -size.x(),
        .right = size.x(),
        .bottom = -size.y(),
        .top = size.y(),
    };
}

pub inline fn writeCell(self: *Screen, x: usize, y: usize, cell: *const Cell) void {
    const fit_to_screen = x >= 0 and x < self.buffer.size.cols and y >= 0 and y < self.buffer.size.rows;
    if (fit_to_screen) {
        var new_cell = cell.*;
        const index = y * self.buffer.size.cols + x;
        if (new_cell.bg == .none) new_cell.bg = self.buffer.buf.items[index].bg;
        self.buffer.buf.items[index] = new_cell;
    }
}

pub inline fn writeCellWorldSpace(self: *Screen, x: f32, y: f32, cell: *const Cell) void {
    const screen_pos = self.worldToScreen(&vec2(x, y));
    if (screen_pos.x() >= 0 and screen_pos.y() >= 0) {
        const ix: usize = @intFromFloat(@round(screen_pos.x()));
        const iy: usize = @intFromFloat(@round(screen_pos.y()));
        const fit_to_screen = ix < self.buffer.size.cols and iy < self.buffer.size.rows;
        if (fit_to_screen) {
            const index = iy * self.buffer.size.cols + ix;
            var new_cell = cell.*;
            if (new_cell.bg == .none) new_cell.bg = self.buffer.buf.items[index].bg;
            self.buffer.buf.items[index] = new_cell;
        }
    }
}

pub inline fn readCell(self: *const Screen, x: usize, y: usize) Cell {
    if (x >= 0 and x < self.buffer.size.cols and y >= 0 and y < self.buffer.size.rows) {
        return self.buffer.buf.items[y * self.buffer.size.cols + x];
    } else {
        @panic("Screen index out of bounds");
    }
}

pub inline fn setBg(self: *Screen, color: Color) void {
    self.bg = color;
}

pub inline fn clear(self: *Screen) void {
    @memset(self.buffer.buf.items, Cell{
        .fg = self.bg,
        .bg = self.bg,
    });
}

inline fn worldToScreen(self: *const Screen, pos: *const Vec2) Vec2 {
    return vec2(self.center.x() + (pos.x() - self.view.pos.x()), self.center.y() + (pos.y() - self.view.pos.y()));
}
