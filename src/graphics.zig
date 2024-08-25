const std = @import("std");
const term = @import("terminal.zig");
const Cell = term.Cell;
const Buffer = term.Buffer;
const termBackend = @import("terminalBackend.zig");
const Color = termBackend.Color;
const Attribute = termBackend.Attribute;

pub const Vec2 = struct {
    x: u16,
    y: u16,
};

pub fn drawLine(buffer: *Buffer, start: Vec2, end: Vec2, style: Cell) void {
    var x0: i32 = @intCast(start.x);
    var y0: i32 = @intCast(start.y);
    const x1: i32 = @intCast(end.x);
    const y1: i32 = @intCast(end.y);

    const dx: i32 = @intCast(@abs(x1 - x0));
    const dy: i32 = @intCast(@abs(y1 - y0));
    const sx: i32 = if (x0 < x1) 1 else -1;
    const sy: i32 = if (y0 < y1) 1 else -1;
    var err = dx - dy;

    while (true) {
        buffer.setCell(@intCast(x0), @intCast(y0), style);
        if (x0 == x1 and y0 == y1) break;
        const e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x0 += sx;
        }
        if (e2 < dx) {
            err += dx;
            y0 += sy;
        }
    }
}

pub fn drawRectangle(buffer: *Buffer, width: u16, height: u16, pos: Vec2, style: Cell, filling: bool, rounding: bool) !void {
    const topLeft = pos;
    const topRight = Vec2{ .x = pos.x + width - 1, .y = pos.y };
    const bottomLeft = Vec2{ .x = pos.x, .y = pos.y + height - 1 };
    const bottomRight = Vec2{ .x = pos.x + width - 1, .y = pos.y + height - 1 };

    drawLine(buffer, topLeft, topRight, style);
    drawLine(buffer, topRight, bottomRight, style);
    drawLine(buffer, bottomRight, bottomLeft, style);
    drawLine(buffer, bottomLeft, topLeft, style);

    if (filling) {
        try fill(buffer, Vec2{ .x = topLeft.x + 1, .y = topLeft.y + 1 }, style);
    }

    _ = rounding; //TODO: Add border rounding
}

pub fn drawTriangle(buffer: *Buffer, verticies: [3]Vec2, style: Cell, filling: bool) !void {
    const p1 = verticies[0];
    const p2 = verticies[1];
    const p3 = verticies[2];

    drawLine(buffer, p1, p2, style);
    drawLine(buffer, p2, p3, style);
    drawLine(buffer, p3, p1, style);

    if (filling) {
        try fill(buffer, Vec2{ .x = (p1.x + p2.x + p3.x) / 3, .y = (p1.y + p2.y + p3.y) / 3 }, style);
    }
}

pub fn drawCircle(buffer: *Buffer, pos: Vec2, radius: u32, style: Cell, filling: bool) void {
    var x: u32 = 0;
    var y = radius;
    var d: i64 = @intCast(3 - 2 * radius);

    putCircleCells(buffer, pos, Vec2{ .x = x, .y = radius }, style);

    while (y >= x) {
        x += 1;

        if (d > 0) {
            y -= 1;
            d = d + (4 * @as(i64, @intCast(x)) - @as(i64, @intCast(y)) + 10);
        } else {
            d = d + (4 * @as(i64, x) + 6);
        }

        putCircleCells(buffer, pos, Vec2{ .x = x, .y = y }, style);
    }

    if (filling) {
        try fill(buffer, pos, style);
    }
}

pub const Text = struct {
    content: []const u8,
    fg: Color,
    bg: Color,
    attr: []const u8,
    pos: Vec2,

    pub fn render(self: *const Text, buffer: *Buffer) void {
        const x = self.pos.x;
        const y = self.pos.y;

        var style = Cell{
            .fg = self.fg,
            .bg = self.bg,
            .attr = self.attr,
            .char = ' ',
        };

        for (0..self.content.len) |i| {
            style.char = self.content[i];
            buffer.setCell(@intCast(x + i), y, style);
        }
    }
};

pub const Particle = struct {
    style: Cell,
    lifetime: f32,
    velocity: Vec2,
    pos: Vec2,

    pub fn render(self: *const Particle, buffer: *Buffer) void {
        _ = self;
        _ = buffer;
    }
};

pub const ParticleEffect = struct {
    particles: std.ArrayList(*Particle),
    duration: f32,
    elapsedTime: f32,
    emissionRate: f32,
    particleLifetime: f32,
    startStyle: Cell,
    endStyle: Cell,
    isActive: bool,
    pos: Vec2,

    pub fn render(self: *const ParticleEffect, buffer: *Buffer) void {
        _ = self;
        _ = buffer;
    }
};

pub const Canvas = struct {};

fn fill(buffer: *Buffer, startPos: Vec2, newStyle: Cell) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var visited = std.ArrayList(Vec2).init(gpa.allocator());
    defer _ = visited.deinit();

    try flood_fill(
        buffer,
        startPos,
        newStyle,
        buffer.buf.items[startPos.y * buffer.width + startPos.x],
        &visited,
    );
}

fn flood_fill(
    buffer: *Buffer,
    startPos: Vec2,
    newStyle: Cell,
    oldStyle: Cell,
    visited: *std.ArrayList(Vec2),
) !void {
    const rowInBounds = startPos.x >= 0 and startPos.x < buffer.height;
    const colInBounds = startPos.y >= 0 and startPos.y < buffer.width;

    if (!rowInBounds or !colInBounds) return;
    for (try visited.toOwnedSlice()) |pos| {
        if (pos.x == startPos.x and pos.y == startPos.y) {
            return;
        }
    }
    if (std.meta.eql(buffer.getCell(startPos.x, startPos.y), oldStyle)) return;

    try visited.append(startPos);
    buffer.setCell(startPos.x, startPos.y, newStyle);

    var startPos1 = startPos;
    startPos1.x += 1;
    try flood_fill(
        buffer,
        startPos1,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos2 = startPos;
    startPos2.x -= 1;
    try flood_fill(
        buffer,
        startPos2,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos3 = startPos;
    startPos3.y += 1;
    try flood_fill(
        buffer,
        startPos3,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos4 = startPos;
    startPos4.y -= 1;
    try flood_fill(
        buffer,
        startPos4,
        newStyle,
        oldStyle,
        visited,
    );
}

fn putCircleCells(buffer: *Buffer, pos: Vec2, edge: Vec2, style: Cell) void {
    buffer.setCell(pos.x + edge.x, pos.y + edge.y, style);
    buffer.setCell(pos.x - edge.x, pos.y + edge.y, style);
    buffer.setCell(pos.x + edge.x, pos.y - edge.y, style);
    buffer.setCell(pos.x - edge.x, pos.y - edge.y, style);
    buffer.setCell(pos.x + edge.x, pos.y + edge.y, style);
    buffer.setCell(pos.x - edge.x, pos.y + edge.y, style);
    buffer.setCell(pos.x + edge.x, pos.y - edge.y, style);
    buffer.setCell(pos.x - edge.x, pos.y - edge.y, style);
}
