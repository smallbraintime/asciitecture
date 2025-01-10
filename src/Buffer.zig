const std = @import("std");
const style = @import("style.zig");
const Cell = style.Cell;
const Color = style.Color;

pub const ScreenSize = struct {
    width: usize,
    height: usize,
};

const Buffer = @This();

buf: std.ArrayList(Cell),
size: ScreenSize,

pub fn init(allocator: std.mem.Allocator, screen_size: ScreenSize) !Buffer {
    const capacity = screen_size.width * screen_size.height;
    var buf = try std.ArrayList(Cell).initCapacity(allocator, capacity);
    try buf.appendNTimes(.{}, capacity);
    try buf.ensureTotalCapacity(capacity);

    return .{
        .buf = buf,
        .size = screen_size,
    };
}

pub fn clone(self: *const Buffer) !Buffer {
    return .{ .buf = try self.buf.clone(), .size = self.size };
}

pub fn replace(self: *Buffer, buf: *[]const Cell) !void {
    @memcpy(self.buf.items, buf.*);
}

pub fn resize(self: *Buffer, width: usize, height: usize) !void {
    self.size.width = width;
    self.size.height = height;
    try self.buf.resize(width * height);
    @memset(self.buf.items, Cell{
        .fg = null,
    });
}

pub fn clear(self: *Buffer) void {
    @memset(self.buf.items, Cell{
        .fg = null,
        .bg = null,
    });
}

pub fn deinit(self: *Buffer) void {
    self.buf.deinit();
}
