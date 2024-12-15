const std = @import("std");
const Cell = @import("style.zig").Cell;
const ScreenSize = @import("util.zig").ScreenSize;

const Buffer = @This();

buf: std.ArrayList(Cell),
size: ScreenSize,

pub fn init(allocator: std.mem.Allocator, cols: usize, rows: usize) !Buffer {
    const capacity = cols * rows;
    var buf = try std.ArrayList(Cell).initCapacity(allocator, capacity);
    try buf.appendNTimes(
        .{
            .char = undefined,
            .fg = .{ .indexed = undefined },
            .bg = .{ .indexed = undefined },
            .attr = .none,
        },
        capacity,
    );
    try buf.ensureTotalCapacity(capacity);

    return .{
        .buf = buf,
        .size = .{
            .cols = cols,
            .rows = rows,
        },
    };
}

pub fn clone(self: *const Buffer) !Buffer {
    return .{ .buf = try self.buf.clone(), .size = self.size };
}

pub fn replace(self: *Buffer, buf: *[]const Cell) !void {
    @memcpy(self.buf.items, buf.*);
}

pub fn resize(self: *Buffer, cols: usize, rows: usize) !void {
    self.size.cols = cols;
    self.size.rows = rows;
    try self.buf.resize(cols * rows);
    @memset(self.buf.items, Cell{
        .char = undefined,
        .fg = .{ .indexed = undefined },
        .bg = .{ .indexed = undefined },
        .attr = .none,
    });
}

pub fn deinit(self: *Buffer) void {
    self.buf.deinit();
}
