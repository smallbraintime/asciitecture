const std = @import("std");
const Cell = @import("Cell.zig");
const ScreenSize = @import("backend/main.zig").ScreenSize;

const RawScreen = @This();

buf: std.ArrayList(Cell),
size: ScreenSize,

pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !RawScreen {
    const capacity = width * height;
    var buf = try std.ArrayList(Cell).initCapacity(allocator, capacity);
    try buf.appendNTimes(
        .{
            .char = undefined,
            .fg = .{ .indexed = undefined },
            .bg = .{ .indexed = undefined },
            .attr = null,
        },
        capacity,
    );
    try buf.ensureTotalCapacity(capacity);

    return RawScreen{
        .buf = buf,
        .size = .{ .width = width, .height = height },
    };
}

pub fn replace(self: *RawScreen, buf: *[]const Cell) !void {
    @memcpy(self.buf.items, buf.*);
}

pub fn resize(self: *RawScreen, width: usize, height: usize) !void {
    self.size.width = width;
    self.size.height = height;
    try self.buf.resize(width * height);
    @memset(self.buf.items, Cell{
        .char = undefined,
        .fg = .{ .indexed = undefined },
        .bg = .{ .indexed = undefined },
        .attr = null,
    });
}

pub fn deinit(self: *RawScreen) !void {
    self.buf.deinit();
}
