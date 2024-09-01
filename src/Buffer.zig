const std = @import("std");
const Cell = @import("Cell.zig");
const backend = @import("backend/main.zig");
const Color = backend.Color;
const Attribute = backend.Attribute;
const ScreenSize = backend.ScreenSize;

const Buffer = @This();

buf: std.ArrayList(Cell),
size: ScreenSize,
ratio: f32,
viewport: Viewport,

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
        .ratio = @floatFromInt(width / height),
        .viewport = undefined,
    };
}

pub fn resize(self: *Buffer, width: usize, height: usize) !void {
    self.size.width = width;
    self.size.height = height;
    const newCapacity = width * height;
    try self.buf.resize(newCapacity);
    self.viewport.width = width;
    self.viewport.height = height;
}

pub fn setViewport(self: *Buffer, x: usize, y: usize, width: usize, height: usize) void {
    self.viewport = Viewport{
        .x = x,
        .y = y,
        .width = width,
        .height = height,
    };
}

pub fn writeCell(self: *Buffer, x: usize, y: usize, style: Cell) void {
    if (x >= 0 and x < self.size.width and y >= 0 and y < self.size.height) {
        self.buf.items[y * self.size.width + x] = style;
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

const Viewport = struct {
    x: usize,
    y: usize,
    width: usize,
    height: usize,
};
