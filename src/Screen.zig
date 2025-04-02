const std = @import("std");
const math = @import("math.zig");
const style = @import("style.zig");
const Buffer = @import("Buffer.zig");
const ScreenSize = Buffer.ScreenSize;
const Cell = style.Cell;
const Color = style.Color;
const IndexedColor = style.IndexedColor;
const Attribute = style.Attribute;
const Vec2 = math.Vec2;
const vec2 = math.vec2;

const Screen = @This();

buffer: Buffer,
center: Vec2,
view: Vec2,
bg: Color,
_size_parity: packed struct {
    width: bool,
    height: bool,
    _padding: u6 = 0,
},

pub fn init(allocator: std.mem.Allocator, screen_size: ScreenSize) !Screen {
    const buf = try Buffer.init(allocator, screen_size);

    var screen = Screen{
        .buffer = buf,
        .center = Vec2.fromInt(screen_size.width, screen_size.height).div(&vec2(2, 2)),
        .view = undefined,
        .bg = IndexedColor.black,
        ._size_parity = undefined,
    };
    screen.setViewPos(&vec2(0, 0));
    screen.check_size_parity(screen_size.width, screen_size.width);

    return screen;
}

pub fn deinit(self: *Screen) void {
    self.buffer.deinit();
}

pub fn resize(self: *Screen, width: usize, height: usize) !void {
    self.check_size_parity(width, height);
    self.center = Vec2.fromInt(width, height).div(&vec2(2, 2));
    try self.buffer.resize(width, height);
}

pub inline fn setViewPos(self: *Screen, pos: *const Vec2) void {
    self.view = pos.*;
}

pub inline fn writeCellWorldSpace(self: *Screen, x: f32, y: f32, cell: *const Cell) void {
    const buffer_pos = vec2(self.center.x() + (x - self.view.x()), self.center.y() + (y - self.view.y()));
    self.writeCell(buffer_pos.x(), buffer_pos.y(), cell);
}

pub inline fn writeCellScreenSpace(self: *Screen, x: f32, y: f32, cell: *const Cell) void {
    const buffer_pos = vec2(self.center.x() + x, self.center.y() + y);
    self.writeCell(buffer_pos.x(), buffer_pos.y(), cell);
}

pub inline fn readCell(self: *const Screen, x: usize, y: usize) Cell {
    if (x < self.buffer.size.width and y < self.buffer.size.height) {
        return self.buffer.buf.items[y * self.buffer.size.width + x];
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

inline fn writeCell(self: *Screen, x: f32, y: f32, cell: *const Cell) void {
    if (x >= 0 and y >= 0) {
        // checking parity to avoid screen flickering
        var ix: usize = undefined;
        var iy: usize = undefined;
        if (self._size_parity.width) {
            ix = @intFromFloat(@round(x));
        } else {
            ix = @intFromFloat(@floor(x));
        }
        if (self._size_parity.height) {
            iy = @intFromFloat(@round(y));
        } else {
            iy = @intFromFloat(@floor(y));
        }

        const fit_to_screen = ix < self.buffer.size.width and iy < self.buffer.size.height;
        if (fit_to_screen) {
            const index = iy * self.buffer.size.width + ix;
            var new_cell = cell.*;
            if (new_cell.bg == null) new_cell.bg = self.buffer.buf.items[index].bg;
            self.buffer.buf.items[index] = new_cell;
        }
    }
}

fn check_size_parity(self: *Screen, width: usize, height: usize) void {
    self._size_parity.width = width % 2 == 0;
    self._size_parity.height = height % 2 == 0;
}
