const std = @import("std");
const Cell = @import("Cell.zig");
const backend = @import("backend/main.zig");
const Color = backend.Color;
const Attribute = backend.Attribute;

const Buffer = @This();

buf: std.ArrayList(Cell),
height: u16,
width: u16,

pub fn setCell(self: *Buffer, x: u16, y: u16, style: Cell) void {
    if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
        self.buf.items[y * self.width + x] = style;
    }
}

pub fn getCell(self: *Buffer, x: u16, y: u16) Cell {
    if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
        return self.buf.items[y * self.width + x];
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
