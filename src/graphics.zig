const std = @import("std");
const termBackend = @import("backend/main.zig");
const Terminal = @import("Terminal.zig");
const Cell = @import("Cell.zig");
const Screen = @import("Screen.zig");
const Color = termBackend.Color;
const Attribute = termBackend.Attribute;

pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub fn screenMeltingTransition(screen: *Screen) void {
    _ = screen;
}

pub fn drawLine(screen: *Screen, start: Vec2, end: Vec2, style: Cell) void {
    var x0 = start.x;
    var y0 = start.y;
    const x1 = end.x;
    const y1 = end.y;

    const dx = @abs(x1 - x0);
    const dy = @abs(y1 - y0);
    const sx: f32 = if (x0 < x1) 1 else -1;
    const sy: f32 = if (y0 < y1) 1 else -1;
    var err = dx - dy;

    while (true) {
        screen.writeCellF(x0, y0, style);
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

pub fn drawLineStrip(screen: *Screen, points: []const Vec2, style: Cell) void {
    _ = screen;
    _ = points;
    _ = style;
}

pub fn drawBezierLine(screen: *Screen, start: Vec2, end: Vec2, style: Cell) void {
    _ = screen;
    _ = start;
    _ = end;
    _ = style;
}

pub fn drawSpline(screen: *Screen, points: []const Vec2, style: Cell) void {
    _ = screen;
    _ = points;
    _ = style;
}

pub fn drawRectangle(screen: *Screen, width: f32, height: f32, position: Vec2, rotation: f32, style: Cell, filling: bool, rounding: bool) void {
    const topLeft = position;
    const topRight = Vec2{ .x = position.x + width - 1, .y = position.y };
    const bottomLeft = Vec2{ .x = position.x, .y = position.y + height - 1 };
    const bottomRight = Vec2{ .x = position.x + width - 1, .y = position.y + height - 1 };

    drawLine(screen, topLeft, topRight, style);
    drawLine(screen, topRight, bottomRight, style);
    drawLine(screen, bottomRight, bottomLeft, style);
    drawLine(screen, bottomLeft, topLeft, style);

    // if (filling) {
    // try fill(screen, Vec2{ .x = topLeft.x + 1, .y = topLeft.y + 1 }, style);
    // }

    _ = rounding; //TODO: Add border rounding and rotation
    _ = rotation;
    _ = filling;
}

pub fn drawTriangle(screen: *Screen, verticies: [3]Vec2, rotation: f32, style: Cell, filling: bool) void {
    const p1 = verticies[0];
    const p2 = verticies[1];
    const p3 = verticies[2];

    drawLine(screen, p1, p2, style);
    drawLine(screen, p2, p3, style);
    drawLine(screen, p3, p1, style);

    // if (filling) {
    // try fill(screen, Vec2{ .x = (p1.x + p2.x + p3.x) / 3, .y = (p1.y + p2.y + p3.y) / 3 }, style);
    // }

    _ = rotation; //TODO: Make rotation
    _ = filling;
}

pub fn drawCircle(screen: *Screen, position: Vec2, radius: f32, style: Cell, filling: bool) void {
    var x: f32 = 0;
    var y = radius;
    var d = 3 - 2 * radius;

    drawCirc(screen, position, .{ .x = x, .y = y }, style);

    while (y >= x) {
        if (d > 0) {
            y -= 1;
            d = d + 4 * (x - y) + 10;
        } else {
            d = d + 4 * x + 6;
        }

        x += 1;

        drawCirc(screen, position, .{ .x = x, .y = y }, style);
    }

    // if (filling) {
    //     try fill(screen, position, style);
    // }
    _ = filling;
}

pub fn drawText(screen: *Screen, content: []const u8, position: Vec2, fg: Color, bg: Color, attr: Attribute) void {
    var style = Cell{
        .fg = fg,
        .bg = bg,
        .attr = attr,
        .char = ' ',
    };

    for (0..content.len) |i| {
        style.char = content[i];
        screen.writeCellF(position.x + @as(f32, @floatFromInt(i)), position.y, style);
    }
}

pub const Particle = struct {
    style: Cell,
    lifetime: f32,
    velocity: Vec2,
    position: Vec2,

    pub fn render(self: *const Particle, screen: *Screen) void {
        _ = self;
        _ = screen;
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
    postion: Vec2,

    pub fn render(self: *const ParticleEffect, screen: *Screen) void {
        _ = self;
        _ = screen;
    }
};

pub fn image(content: []const u8) Image {
    _ = content;
}

pub const Flip = enum(u3) {
    vertical,
    horizontal,
    none,
};

pub const Image = struct {
    pub fn draw(screen: *Screen, position: Vec2, rotation: f32, flip: Flip, style: Cell) void {
        _ = screen;
        _ = position;
        _ = rotation;
        _ = style;
        _ = flip;
    }
};

fn fill(screen: *Screen, startPos: Vec2, newStyle: Cell) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var visited = std.ArrayList(Vec2).init(gpa.allocator());
    defer _ = visited.deinit();

    try flood_fill(
        screen,
        startPos,
        newStyle,
        screen.buf.items[startPos.y * screen.width + startPos.x],
        &visited,
    );
}

fn flood_fill(
    screen: *Screen,
    startPos: Vec2,
    newStyle: Cell,
    oldStyle: Cell,
    visited: *std.ArrayList(Vec2),
) !void {
    const rowInBounds = startPos.x >= 0 and startPos.x < screen.height;
    const colInBounds = startPos.y >= 0 and startPos.y < screen.width;

    if (!rowInBounds or !colInBounds) return;
    for (try visited.toOwnedSlice()) |pos| {
        if (pos.x == startPos.x and pos.y == startPos.y) {
            return;
        }
    }
    if (std.meta.eql(screen.getCell(startPos.x, startPos.y), oldStyle)) return;

    try visited.append(startPos);
    screen.writeCell(startPos.x, startPos.y, newStyle);

    var startPos1 = startPos;
    startPos1.x += 1;
    try flood_fill(
        screen,
        startPos1,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos2 = startPos;
    startPos2.x -= 1;
    try flood_fill(
        screen,
        startPos2,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos3 = startPos;
    startPos3.y += 1;
    try flood_fill(
        screen,
        startPos3,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos4 = startPos;
    startPos4.y -= 1;
    try flood_fill(
        screen,
        startPos4,
        newStyle,
        oldStyle,
        visited,
    );
}

fn drawCirc(screen: *Screen, pos: Vec2, edge: Vec2, style: Cell) void {
    screen.writeCell(@intFromFloat(@round(pos.x + edge.x)), @intFromFloat(@round(pos.y + edge.y)), style);
    screen.writeCell(@intFromFloat(@round(pos.x - edge.x)), @intFromFloat(@round(pos.y + edge.y)), style);
    screen.writeCell(@intFromFloat(@round(pos.x + edge.x)), @intFromFloat(@round(pos.y - edge.y)), style);
    screen.writeCell(@intFromFloat(@round(pos.x - edge.x)), @intFromFloat(@round(pos.y - edge.y)), style);
    screen.writeCell(@intFromFloat(@round(pos.x + edge.x)), @intFromFloat(@round(pos.y + edge.y)), style);
    screen.writeCell(@intFromFloat(@round(pos.x - edge.x)), @intFromFloat(@round(pos.y + edge.y)), style);
    screen.writeCell(@intFromFloat(@round(pos.x + edge.x)), @intFromFloat(@round(pos.y - edge.y)), style);
    screen.writeCell(@intFromFloat(@round(pos.x - edge.x)), @intFromFloat(@round(pos.y - edge.y)), style);
}
