const std = @import("std");
const backend = @import("backend/main.zig");
const math = @import("math.zig");
const Cell = @import("Cell.zig");
const Color = backend.Color;
const Attribute = backend.Attribute;
const ScreenSize = backend.ScreenSize;
const Vec2 = math.Vec2;
const vec2 = math.vec2;

const Buffer = @This();

buf: std.ArrayList(Cell),
size: ScreenSize,
view: View,
worldSize: Vec2,

pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Buffer {
    const capacity = width * height;

    var buf = try std.ArrayList(Cell).initCapacity(allocator, capacity);
    try buf.appendNTimes(
        .{
            .char = ' ',
            .fg = .{ .indexed = .default },
            .bg = .{ .indexed = .default },
            .attr = .reset,
        },
        capacity,
    );

    return Buffer{
        .buf = buf,
        .size = .{
            .width = width,
            .height = height,
        },
        .view = undefined,
        .worldSize = vec2(@as(f32, @floatFromInt(width)), @as(f32, @floatFromInt(height))),
    };
}

pub fn resize(self: *Buffer, width: usize, height: usize) !void {
    self.size.width = width;
    self.size.height = height;
    const newCapacity = width * height;
    try self.buf.resize(newCapacity);
}

pub fn setViewport(self: *Buffer, x: usize, y: usize) void {
    self.view = View{
        .x = x,
        .y = y,
    };
}

pub fn writeCell(self: *Buffer, x: usize, y: usize, style: Cell) void {
    if (x >= 0 and x < self.size.width and y >= 0 and y < self.size.height) {
        self.buf.items[y * self.size.width + x] = style;
    }
}

pub fn writeCellF(self: *Buffer, x: f32, y: f32, style: Cell) void {
    const screenPos = math.worldToScreen(&vec2(x, y), self.size.width, self.size.height, self.worldSize.x(), self.worldSize.y());
    const ix: usize = @intFromFloat(@round(screenPos.x()));
    const iy: usize = @intFromFloat(@round(screenPos.y()));
    if (ix >= 0 and ix < self.size.width and iy >= 0 and iy < self.size.height) {
        self.buf.items[iy * self.size.width + ix] = style;
    }
}

pub fn readCell(self: *Buffer, x: usize, y: usize) Cell {
    if (x >= 0 and x < self.size.width and y >= 0 and y < self.size.height) {
        return self.buf.items[y * self.size.width + x];
    } else {
        unreachable;
    }
}

pub fn clear(self: *Buffer) void {
    @memset(self.buf.items, Cell{
        .char = ' ',
        .fg = .{ .indexed = .default },
        .bg = .{ .indexed = .default },
        .attr = .reset,
    });
}

const View = struct {
    x: usize,
    y: usize,
};
