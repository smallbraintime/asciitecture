const std = @import("std");
const termBackend = @import("backend/main.zig");
const Terminal = @import("Terminal.zig");
const Cell = @import("Cell.zig");
const Screen = @import("Screen.zig");
const Color = termBackend.Color;
const Attribute = termBackend.Attribute;
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;

pub fn drawLine(screen: *Screen, p0: *const Vec2, p1: *const Vec2, style: *const Cell) void {
    var x0 = p0.x();
    var y0 = p0.y();
    const x1 = p1.x();
    const y1 = p1.y();

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

pub fn drawBezierCurve(screen: *Screen, start: Vec2, end: Vec2, style: Cell) void {
    _ = screen;
    _ = start;
    _ = end;
    _ = style;
}

pub fn drawRectangle(screen: *Screen, width: f32, height: f32, position: *const Vec2, rotation_angle: f32, style: *const Cell, fill: bool) void {
    const top_left = position.rotate(rotation_angle);
    const top_right = vec2(position.x() + width - 1, position.y()).rotate(rotation_angle);
    const bottom_left = vec2(position.x(), position.y() + height - 1).rotate(rotation_angle);
    const bottom_right = vec2(position.x() + width - 1, position.y() + height - 1).rotate(rotation_angle);

    if (fill) {} else {
        drawLine(screen, &top_left, &top_right, style);
        drawLine(screen, &top_right, &bottom_right, style);
        drawLine(screen, &bottom_right, &bottom_left, style);
        drawLine(screen, &bottom_left, &top_left, style);
    }

    //TODO:Fix rotation
}

pub const Border = enum {
    thick,
    double_line,
    rounded,
};

pub fn drawPrettyRectangle(screen: *Screen, width: f32, height: f32, position: *const Vec2, borders: Border) void {
    _ = screen;
    _ = width;
    _ = height;
    _ = position;
    _ = borders;
}

pub fn drawTriangle(screen: *Screen, verticies: [3]*const Vec2, rotation: f32, style: *const Cell, filling: bool) void {
    const p1 = verticies[0];
    const p2 = verticies[1];
    const p3 = verticies[2];

    drawLine(screen, p1, p2, style);
    drawLine(screen, p2, p3, style);
    drawLine(screen, p3, p1, style);

    _ = rotation;
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

    _ = filling;
}

pub fn drawText(screen: *Screen, content: []const u8, pos: *const Vec2, fg: Color, bg: Color, attr: Attribute) void {
    var style = Cell{
        .fg = fg,
        .bg = bg,
        .attr = attr,
        .char = ' ',
    };

    for (0..content.len) |i| {
        style.char = content[i];
        screen.writeCellF(pos.x() + @as(f32, @floatFromInt(i)), pos.y(), &style);
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
