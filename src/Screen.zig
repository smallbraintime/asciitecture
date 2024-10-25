const std = @import("std");
const math = @import("math.zig");
const cell = @import("cell.zig");
const ScreenSize = @import("util.zig").ScreenSize;
const Cell = cell.Cell;
const Color = cell.Color;
const Attribute = cell.Attribute;
const Vec2 = math.Vec2;
const vec2 = math.vec2;

const Screen = @This();

buf: std.ArrayList(Cell),
size: ScreenSize,
ref_size: ScreenSize,
scale_vec: Vec2,
center: Vec2,
view: View,

pub fn init(allocator: std.mem.Allocator, cols: usize, rows: usize) !Screen {
    const capacity = rows * cols;
    var buf = try std.ArrayList(Cell).initCapacity(allocator, capacity);
    try buf.appendNTimes(
        .{
            .char = ' ',
            .fg = .{ .indexed = .default },
            .bg = .{ .indexed = .default },
            .attr = null,
        },
        capacity,
    );
    try buf.ensureTotalCapacity(capacity);

    var screen = Screen{
        .buf = buf,
        .size = .{
            .cols = cols,
            .rows = rows,
        },
        .ref_size = ScreenSize{ .cols = cols, .rows = rows },
        .scale_vec = vec2(1, 1),
        .center = Vec2.fromInt(cols, rows).div(&vec2(2, 2)),
        .view = undefined,
    };
    screen.setView(&vec2(0, 0));

    return screen;
}

pub fn resize(self: *Screen, cols: usize, rows: usize) !void {
    self.size.cols = cols;
    self.size.rows = rows;
    self.center = Vec2.fromInt(cols, rows).div(&vec2(2, 2));
    self.scale_vec = Vec2.fromInt(cols, rows).div(&Vec2.fromInt(self.ref_size.cols, self.ref_size.rows));
    try self.buf.resize(cols * rows);
}

pub inline fn setView(self: *Screen, pos: *const Vec2) void {
    const size = pos.add(&vec2(self.center.x() / 2, self.center.y() / 2));
    self.view = View{
        .pos = pos.*,
        .left = -size.x(),
        .right = size.x(),
        .bottom = -size.y(),
        .top = size.y(),
    };
}

pub inline fn writeCell(self: *Screen, x: usize, y: usize, style: *const Cell) void {
    const fit_to_screen = x >= 0 and x < self.size.cols and y >= 0 and y < self.size.rows;
    if (fit_to_screen) {
        self.buf.items[y * self.size.cols + x] = style.*;
    }
}

pub inline fn writeCellF(self: *Screen, x: f32, y: f32, style: *const Cell) void {
    const screen_pos = self.worldToScreen(&vec2(x, y));
    const fit_to_screen = screen_pos.x() >= 0 and screen_pos.x() <= @as(f32, @floatFromInt(self.size.cols - 1)) and screen_pos.y() >= 0 and screen_pos.y() < @as(f32, @floatFromInt(self.size.rows - 1));
    if (fit_to_screen) {
        const ix: usize = @intFromFloat(@round(screen_pos.x()));
        const iy: usize = @intFromFloat(@round(screen_pos.y()));
        self.buf.items[iy * self.size.cols + ix] = style.*;
    }
}

pub inline fn readCell(self: *const Screen, x: usize, y: usize) Cell {
    if (x >= 0 and x < self.size.cols and y >= 0 and y < self.size.rows) {
        return self.buf.items[y * self.size.cols + x];
    } else {
        @panic("Screen index out of bound");
    }
}

pub inline fn clear(self: *Screen) void {
    @memset(self.buf.items, Cell{
        .char = ' ',
        .fg = .{ .indexed = .default },
        .bg = .{ .indexed = .default },
        .attr = null,
    });
}

inline fn worldToScreen(self: *const Screen, pos: *const Vec2) Vec2 {
    return vec2(self.center.x() + (pos.x() - self.view.pos.x()) * self.scale_vec.x(), self.center.y() + (pos.y() - self.view.pos.y()) * self.scale_vec.y());
}

const View = struct {
    pos: Vec2,
    left: f32,
    right: f32,
    bottom: f32,
    top: f32,
};
