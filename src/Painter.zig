const std = @import("std");
const style = @import("style.zig");
const math = @import("math.zig");
const Screen = @import("Screen.zig");
const Cell = style.Cell;
const Color = style.Color;
const Style = style.Style;
const Border = style.Border;
const Attribute = style.Attribute;
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const pow = math.pow;
const Sprite = @import("sprite.zig");

const Painter = @This();

screen: *Screen,
cell: Cell,

pub fn init(screen: *Screen) Painter {
    return .{
        .screen = screen,
        .cell = .{ .fg = .{ .indexed = .white } },
    };
}

pub inline fn setCell(self: *Painter, new_cell: *const Cell) void {
    self.cell = new_cell.*;
}

pub inline fn writeCell(self: *Painter, x: f32, y: f32) void {
    self.screen.writeCellF(x, y, &self.cell);
}

pub fn drawLine(self: *Painter, p0: *const Vec2, p1: *const Vec2) void {
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
        self.writeCell(x0, y0);
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

pub fn drawCubicSpline(self: *Painter, p0: *const Vec2, p1: *const Vec2, p2: *const Vec2, p3: *const Vec2) void {
    const inc_val: f32 = 1.0 / 100.0;
    var t: f32 = 0;
    while (t <= 1.0) {
        const x = cubic_bezier(t, p0.x(), p1.x(), p2.x(), p3.x());
        const y = cubic_bezier(t, p0.y(), p1.y(), p2.y(), p3.y());
        self.writeCell(x, y);
        t = t + inc_val;
    }
}

fn cubic_bezier(t: f32, p0: f32, p1: f32, p2: f32, p3: f32) f32 {
    return pow(1 - t, 3) * p0 + 3 * pow(1 - t, 2) * t * p1 + 3 * (1 - t) * pow(t, 2) * p2 + pow(t, 3) * p3;
}

pub fn drawRectangle(self: *Painter, width: f32, height: f32, position: *const Vec2, rotation_angle: f32, filling: Color) void {
    // const origin = vec2(position.x() + width / 2, position.y() + height / 2);
    const top_left = position;
    const top_right = vec2(position.x() + width - 1, position.y());
    const bottom_left = vec2(position.x(), position.y() + height - 1);
    const bottom_right = vec2(position.x() + width - 1, position.y() + height - 1);

    self.drawLine(top_left, &top_right);
    self.drawLine(&top_right, &bottom_right);
    self.drawLine(&bottom_right, &bottom_left);
    self.drawLine(&bottom_left, top_left);

    _ = rotation_angle;
    _ = filling;
}

pub fn drawPrettyRectangle(self: *Painter, width: f32, height: f32, position: *const Vec2, borders: Border, filling: Color) void {
    const top_left = position;
    const top_right = vec2(position.x() + width - 1, position.y());
    const bottom_left = vec2(position.x(), position.y() + height - 1);
    const bottom_right = vec2(position.x() + width - 1, position.y() + height - 1);

    var horizontal_border = Cell{ .fg = self.cell.fg, .bg = self.cell.bg };
    var vertical_border = horizontal_border;
    var top_left_edge = horizontal_border;
    var top_right_edge = horizontal_border;
    var bottom_left_edge = horizontal_border;
    var bottom_right_edge = horizontal_border;

    switch (borders) {
        .plain => {
            horizontal_border.char = '─';
            vertical_border.char = '│';
            top_left_edge.char = '┌';
            top_right_edge.char = '┐';
            bottom_left_edge.char = '└';
            bottom_right_edge.char = '┘';
        },
        .thick => {
            horizontal_border.char = '━';
            vertical_border.char = '┃';
            top_left_edge.char = '┏';
            top_right_edge.char = '┓';
            bottom_left_edge.char = '┗';
            bottom_right_edge.char = '┛';
        },
        .double_line => {
            horizontal_border.char = '═';
            vertical_border.char = '║';
            top_left_edge.char = '╔';
            top_right_edge.char = '╗';
            bottom_left_edge.char = '╚';
            bottom_right_edge.char = '╝';
        },
        .rounded => {
            horizontal_border.char = '─';
            vertical_border.char = '│';
            top_left_edge.char = '╭';
            top_right_edge.char = '╮';
            bottom_left_edge.char = '╰';
            bottom_right_edge.char = '╯';
        },
    }

    self.setCell(&horizontal_border);
    self.drawLine(&top_left.add(&vec2(1, 0)), &top_right.sub(&vec2(1, 0)));
    self.setCell(&vertical_border);
    self.drawLine(&top_right.add(&vec2(0, 1)), &bottom_right.sub(&vec2(0, 1)));
    self.setCell(&horizontal_border);
    self.drawLine(&bottom_right.sub(&vec2(1, 0)), &bottom_left.add(&vec2(1, 0)));
    self.setCell(&vertical_border);
    self.drawLine(&bottom_left.sub(&vec2(0, 1)), &top_left.add(&vec2(0, 1)));

    self.setCell(&top_left_edge);
    self.writeCell(top_left.x(), top_left.y());
    self.setCell(&top_right_edge);
    self.writeCell(top_right.x(), top_right.y());
    self.setCell(&bottom_left_edge);
    self.writeCell(bottom_left.x(), bottom_left.y());
    self.setCell(&bottom_right_edge);
    self.writeCell(bottom_right.x(), bottom_right.y());

    _ = filling;
}

pub fn drawTriangle(self: *Painter, p1: *const Vec2, p2: *const Vec2, p3: *const Vec2, rotation: f32, filling: Color) void {
    self.drawLine(p1, p2);
    self.drawLine(p2, p3);
    self.drawLine(p3, p1);

    _ = rotation;
    _ = filling;
}

pub fn drawCircle(self: *Painter, position: *const Vec2, radius: f32, filling: Color) void {
    var x: f32 = 0;
    var y = radius;
    var d = 3 - 2 * radius;

    while (y > x) {
        self.writeCell(x + position.x(), y * 0.5 + position.y());
        self.writeCell(y + position.x(), x * 0.5 + position.y());
        self.writeCell(-y + position.x(), x * 0.5 + position.y());
        self.writeCell(-x + position.x(), y * 0.5 + position.y());
        self.writeCell(-x + position.x(), -y * 0.5 + position.y());
        self.writeCell(-y + position.x(), -x * 0.5 + position.y());
        self.writeCell(y + position.x(), -x * 0.5 + position.y());
        self.writeCell(x + position.x(), -y * 0.5 + position.y());

        if (d > 0) {
            d = d + 4 * (x - y) + 10;
            y -= 1;
        } else {
            d = d + 4 * x + 6;
        }

        x += 1;
    }

    _ = filling;
}

pub fn drawText(self: *Painter, content: []const u8, pos: *const Vec2) void {
    for (0..content.len) |i| {
        self.cell.char = content[i];
        self.writeCell(pos.x() + @as(f32, @floatFromInt(i)), pos.y());
    }
}

pub fn drawParticles(self: *Painter, position: *const Vec2, width: f32, height: f32, quantity: usize) void {
    var rn: [1]u8 = undefined;
    std.posix.getrandom(&rn) catch unreachable;
    var rng = std.rand.DefaultPrng.init(@intCast(rn[0]));
    var prng = rng.random();

    for (0..quantity) |_| {
        const x = prng.intRangeAtMost(i32, @intFromFloat(@trunc(position.x())), @intFromFloat(@trunc(position.x() + width)));
        const y = prng.intRangeAtMost(i32, @intFromFloat(@trunc(position.y())), @intFromFloat(@trunc(position.y() + height)));
        self.writeCell(@floatFromInt(x), @floatFromInt(y));
    }
}
