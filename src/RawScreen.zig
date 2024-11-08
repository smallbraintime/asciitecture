const std = @import("std");
const Cell = @import("cell.zig").Cell;
const ScreenSize = @import("util.zig").ScreenSize;

const RawScreen = @This();

buf: std.ArrayList(Cell),
size: ScreenSize,

pub fn init(allocator: std.mem.Allocator, cols: usize, rows: usize) !RawScreen {
    const capacity = cols * rows;
    var buf = try std.ArrayList(Cell).initCapacity(allocator, capacity);
    try buf.appendNTimes(
        .{
            .char = undefined,
            .style = .{
                .fg = .{ .indexed = undefined },
                .bg = .{ .indexed = undefined },
                .attr = .none,
            },
        },
        capacity,
    );
    try buf.ensureTotalCapacity(capacity);

    return RawScreen{
        .buf = buf,
        .size = .{
            .cols = cols,
            .rows = rows,
        },
    };
}

pub fn replace(self: *RawScreen, buf: *[]const Cell) !void {
    @memcpy(self.buf.items, buf.*);
}

pub fn resize(self: *RawScreen, cols: usize, rows: usize) !void {
    self.size.cols = cols;
    self.size.rows = rows;
    try self.buf.resize(cols * rows);
    @memset(self.buf.items, Cell{ .char = undefined, .style = .{
        .fg = .{ .indexed = undefined },
        .bg = .{ .indexed = undefined },
        .attr = .none,
    } });
}

pub fn deinit(self: *RawScreen) !void {
    self.buf.deinit();
}
