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
const Point = math.Point;
const Line = math.Line;
const Rectangle = math.Rectangle;
const Circle = math.Circle;

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

pub inline fn drawCell(self: *Painter, x: f32, y: f32) void {
    self.screen.writeCellF(x, y, &self.cell);
}

pub fn drawLine(self: *Painter, p0: *const Vec2, p1: *const Vec2) void {
    var x0 = @round(p0.x());
    var y0 = @round(p0.y());
    const x1 = @round(p1.x());
    const y1 = @round(p1.y());

    const dx = @abs(x1 - x0);
    const dy = @abs(y1 - y0);
    const sx: f32 = if (x0 < x1) 1 else -1;
    const sy: f32 = if (y0 < y1) 1 else -1;
    var err = dx - dy;

    while (true) {
        self.drawCell(x0, y0);
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
        self.drawCell(x, y);
        t = t + inc_val;
    }
}

fn cubic_bezier(t: f32, p0: f32, p1: f32, p2: f32, p3: f32) f32 {
    return pow(1 - t, 3) * p0 + 3 * pow(1 - t, 2) * t * p1 + 3 * (1 - t) * pow(t, 2) * p2 + pow(t, 3) * p3;
}

pub fn drawRectangle(self: *Painter, width: f32, height: f32, position: *const Vec2, filled: bool) void {
    if (filled) {
        const x1 = position.x();
        const x2 = position.x() + width - 1;
        var y = position.y();
        while (y < position.y() + height) : (y += 1) {
            const filling_line_left = vec2(x1, y);
            const filling_line_right = vec2(x2, y);
            self.drawLine(&filling_line_left, &filling_line_right);
        }
    } else {
        const top_left = position;
        const top_right = vec2(position.x() + width - 1, position.y());
        const bottom_left = vec2(position.x(), position.y() + height - 1);
        const bottom_right = vec2(position.x() + width - 1, position.y() + height - 1);

        self.drawLine(top_left, &top_right);
        self.drawLine(&top_right, &bottom_right);
        self.drawLine(&bottom_right, &bottom_left);
        self.drawLine(&bottom_left, top_left);
    }
}

pub fn drawPrettyRectangle(self: *Painter, width: f32, height: f32, position: *const Vec2, borders: Border, filled: bool) void {
    if (width < 2 or height < 2) return;

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

    const top_left = vec2(@floor(position.x()), @floor(position.y()));
    const top_right = vec2(@floor(position.x() + width - 1), @floor(position.y()));
    const bottom_left = vec2(@floor(position.x()), @floor(position.y() + height - 1));
    const bottom_right = vec2(@floor(position.x() + width - 1), @floor(position.y() + height - 1));

    self.setCell(&horizontal_border);
    self.drawLine(&top_left.add(&vec2(1, 0)), &top_right.sub(&vec2(1, 0)));
    self.setCell(&vertical_border);
    self.drawLine(&top_right.add(&vec2(0, 1)), &bottom_right.sub(&vec2(0, 1)));
    self.setCell(&horizontal_border);
    self.drawLine(&bottom_right.sub(&vec2(1, 0)), &bottom_left.add(&vec2(1, 0)));
    self.setCell(&vertical_border);
    self.drawLine(&bottom_left.sub(&vec2(0, 1)), &top_left.add(&vec2(0, 1)));

    self.setCell(&top_left_edge);
    self.drawCell(top_left.x(), top_left.y());
    self.setCell(&top_right_edge);
    self.drawCell(top_right.x(), top_right.y());
    self.setCell(&bottom_left_edge);
    self.drawCell(bottom_left.x(), bottom_left.y());
    self.setCell(&bottom_right_edge);
    self.drawCell(bottom_right.x(), bottom_right.y());

    if (filled) {
        const interior_pos = top_left.add(&vec2(1, 1));
        self.cell.char = ' ';
        self.drawRectangle(width - 2, height - 2, &interior_pos, filled);
    }
}

pub fn drawTriangle(self: *Painter, p1: *const Vec2, p2: *const Vec2, p3: *const Vec2, filled: bool) void {
    if (filled) {
        const miny = @min(@min(p1.y(), p2.y()), p3.y());
        const maxy = @max(@max(p1.y(), p2.y()), p3.y());

        var y: f32 = miny;
        while (y <= maxy) : (y += 1.0) {
            var x_min: ?f32 = null;
            var x_max: ?f32 = null;

            checkEdge(p1, p2, y, &x_min, &x_max);
            checkEdge(p2, p3, y, &x_min, &x_max);
            checkEdge(p3, p1, y, &x_min, &x_max);

            if (x_min != null and x_max != null) {
                self.drawLine(&vec2(x_min.?, y), &vec2(x_max.?, y));
            }
        }
    } else {
        self.drawLine(p1, p2);
        self.drawLine(p2, p3);
        self.drawLine(p3, p1);
    }
}

fn checkEdge(p1: *const Vec2, p2: *const Vec2, y: f32, x_min: *?f32, x_max: *?f32) void {
    if ((y < @min(p1.y(), p2.y())) or (y > @max(p1.y(), p2.y()))) return;

    const edgex = if (p1.y() == p2.y()) p1.x() else p1.x() + (y - p1.y()) * (p2.x() - p1.x()) / (p2.y() - p1.y());

    if (x_min.* == null or edgex < x_min.*.?) {
        x_min.* = edgex;
    }
    if (x_max.* == null or edgex > x_max.*.?) {
        x_max.* = edgex;
    }
}

pub fn drawCircle(self: *Painter, position: *const Vec2, radius: f32, stretch: *const Vec2, filled: bool) void {
    const stretch_x = if (stretch.x() == 0) 1 else stretch.x();
    const stretch_y = if (stretch.y() == 0) 1 else stretch.y();

    var x: f32 = 0;
    var y = radius;
    var d = 3 - 2 * radius;

    while (y > x) {
        self.drawCell(x * stretch_x + position.x(), y * stretch_y + position.y());
        self.drawCell(y * stretch_x + position.x(), x * stretch_y + position.y());
        self.drawCell(-y * stretch_x + position.x(), x * stretch_y + position.y());
        self.drawCell(-x * stretch_x + position.x(), y * stretch_y + position.y());
        self.drawCell(-x * stretch_x + position.x(), -y * stretch_y + position.y());
        self.drawCell(-y * stretch_x + position.x(), -x * stretch_y + position.y());
        self.drawCell(y * stretch_x + position.x(), -x * stretch_y + position.y());
        self.drawCell(x * stretch_x + position.x(), -y * stretch_y + position.y());

        if (d > 0) {
            d = d + 4 * (x - y) + 10;
            y -= 1;
        } else {
            d = d + 4 * x + 6;
        }

        x += 1;
    }

    if (filled) {
        var dy: f32 = -radius;
        while (dy <= radius) : (dy += 1) {
            const adjusted_y = dy * stretch_y;
            const line_length = @sqrt(radius * radius - dy * dy);
            var dx: f32 = -line_length;
            while (dx <= line_length) : (dx += 1) {
                const adjusted_x = dx * stretch_x;
                self.drawCell(adjusted_x + position.x(), adjusted_y + position.y());
            }
        }
    }
}

pub inline fn drawPointShape(self: *Painter, point: *const Point) void {
    self.drawCell(point.p.x(), point.p.y());
}

pub inline fn drawLineShape(self: *Painter, line: *const Line) void {
    self.drawLine(&line.p1, &line.p2);
}

pub inline fn drawRectangleShape(self: *Painter, rectangle: *const Rectangle, filled: bool) void {
    self.drawRectangle(rectangle.width, rectangle.height, &rectangle.pos, filled);
}

pub inline fn drawPrettyRectangleShape(self: *Painter, rectangle: *const Rectangle, border: Border, filled: bool) void {
    self.drawPrettyRectangle(rectangle.width, rectangle.height, &rectangle.pos, border, filled);
}

pub inline fn drawCircleShape(self: *Painter, circle: *const Circle, stretch: *const Vec2, filled: bool) void {
    self.drawCircle(&circle.center, circle.radius, stretch, filled);
}

pub fn drawText(self: *Painter, content: []const u8, pos: *const Vec2) void {
    for (0..content.len) |i| {
        self.cell.char = content[i];
        self.drawCell(pos.x() + @as(f32, @floatFromInt(i)), pos.y());
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
        self.drawCell(@floatFromInt(x), @floatFromInt(y));
    }
}
