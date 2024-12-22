const std = @import("std");

pub const vec2 = Vec2.init;

pub const Vec2 = struct {
    v: @Vector(2, f32),

    pub inline fn init(xs: f32, ys: f32) Vec2 {
        return .{ .v = .{ xs, ys } };
    }

    pub inline fn fromInt(xs: usize, ys: usize) Vec2 {
        return .{ .v = .{ @floatFromInt(xs), @floatFromInt(ys) } };
    }

    pub inline fn x(self: *const Vec2) f32 {
        return self.v[0];
    }

    pub inline fn y(self: *const Vec2) f32 {
        return self.v[1];
    }

    pub inline fn add(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v + b.v };
    }

    pub inline fn sub(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v - b.v };
    }

    pub inline fn mul(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v * b.v };
    }

    pub inline fn div(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v / b.v };
    }

    pub inline fn translate(a: *const Vec2, b: *const Vec2) Vec2 {
        return a.add(b);
    }

    pub inline fn scale(a: *const Vec2, b: *const Vec2) Vec2 {
        return a.mul(b);
    }

    pub inline fn rotate(self: *const Vec2, angle: f32, around: *const Vec2) Vec2 {
        const radian_angle = std.math.degreesToRadians(angle);
        const c = @cos(radian_angle);
        const s = @sin(radian_angle);

        const origin = self.sub(around);

        const new_x = origin.x() * c - origin.y() * s;
        const new_y = origin.x() * s - origin.y() * c;

        return vec2(new_x, new_y).add(around);
    }

    pub inline fn len(self: *const Vec2, other: *const Vec2) f32 {
        const dx = other.x() - self.x();
        const dy = other.y() - self.y();
        return @sqrt(dx * dx + dy * dy);
    }

    pub inline fn lerp(self: *const Vec2, other: *const Vec2, amount: f32) Vec2 {
        return self.add(&other.sub(self).mul(&vec2(amount, amount)));
    }
};

pub const Point = struct {
    p: Vec2,
    velocity: f32,

    pub fn init(point: *const Point, velocity: f32) Point {
        return .{
            .p = point.*,
            .veloctiy = velocity,
        };
    }

    pub fn collisionPoint(self: *const Point, point: *const Point) bool {
        return collisionPoints(self, point);
    }

    pub fn collisionLine(self: *const Point, line: *const Line) bool {
        return collisionPointLine(self, line);
    }

    pub fn collisionRectangle(self: *const Point, rectangle: *const Rectangle) bool {
        return collisionPointRectangle(self, rectangle);
    }
};

pub const Line = struct {
    p1: Vec2,
    p2: Vec2,
    velocity: f32,

    pub fn init(p1: *const Vec2, p2: *const Vec2, velocity: f32) Line {
        return .{
            .p1 = p1.*,
            .p2 = p2.*,
            .veloctiy = velocity,
        };
    }

    pub fn collisionPoint(self: *const Line, point: *const Point) bool {
        return collisionPointLine(point, self);
    }

    pub fn collisionLine(self: *const Line, line: *const Line) bool {
        return collisionLines(self, line);
    }

    pub fn collisionRectangle(self: *const Line, rectangle: *const Rectangle) bool {
        return collisionLineRectangle(self, rectangle);
    }
};

pub const Rectangle = struct {
    pos: Vec2,
    width: f32,
    height: f32,
    velocity: f32,

    pub fn init(pos: *const Vec2, width: f32, height: f32, velocity: f32) Line {
        return .{
            .pos = pos.*,
            .width = width.*,
            .height = height.*,
            .veloctiy = velocity,
        };
    }

    pub fn collisionPoint(self: *const Rectangle, point: *const Point) bool {
        return collisionPointRectangle(point, self);
    }

    pub fn collisionLine(self: *const Rectangle, line: *const Line) bool {
        return collisionLineRectangle(line, self);
    }

    pub fn collisionRectangle(self: *const Rectangle, rectangle: *const Rectangle) bool {
        return collisionRectangle(self, rectangle);
    }
};

fn collisionPointLine(point: *const Point, line: *const Line) bool {
    var collision = false;

    const dxc = point.x() - line.p1.x();
    const dyc = point.y() - line.p1.y();
    const dxl = line.p2.x() - line.p1.x();
    const dyl = line.p2.y() - line.p1.y();
    const cross = dxc * dyl - dyc * dxl;

    if (@abs(cross) < 1e-6) {
        if (@abs(dxl) >= @abs(dyl)) {
            collision = if (dxl > 0)
                line.p1.x() <= point.x() and point.x <= line.p2.x()
            else
                line.p2.x() <= point.x() and point.x() <= line.p1.x();
        } else {
            collision = if (dyl > 0)
                line.p1.y() <= point.y() and point.y() <= line.p2.y()
            else
                line.p2.y() <= point.y() and point.y() <= line.p1.y();
        }
    }

    return collision;
}

fn collisionPointRectangle(point: *const Point, rectangle: *const Rectangle) bool {
    var collision = false;

    if ((point.x >= rectangle.pos.x()) and (point.x() < (rectangle.pos.x() + rectangle.width)) and (point.y() >= rectangle.pos.y()) and (point.y() < (rectangle.pos.y() + rectangle.height))) collision = true;

    return collision;
}

fn collisionLineRectangle(line: *const Line, rectangle: *const Rectangle) bool {
    const rect_top_left = vec2(rectangle.pos.x(), rectangle.pos.y());
    const rect_top_right = vec2(rectangle.pos.x() + rectangle.width, rectangle.pos.y());
    const rect_bottom_left = vec2(rectangle.pos.x(), rectangle.pos.y() + rectangle.height);
    const rect_bottom_right = vec2(rectangle.pos.x() + rectangle.width, rectangle.pos.y() + rectangle.height);

    if (collisionLines(line, &Line.init(rect_top_left, rect_top_right, 0))) return true;
    if (collisionLines(line, &Line.init(rect_top_right, rect_bottom_right))) return true;
    if (collisionLines(line, &Line.init(rect_bottom_right, rect_bottom_left))) return true;
    if (collisionLines(line, &Line.init(rect_bottom_left, rect_top_left))) return true;

    return false;
}

fn collisionPoints(p1: *const Point, p2: *const Point) bool {
    return p1.p.x() == p2.p.x() and p1.p.y() == p2.p.y();
}

fn collisionLines(l1: *const Line, l2: *const Line) bool {
    var collision = false;

    const div = (l2.p2.y - l2.p1.y) * (l1.p2.x - l1.p1.x) - (l2.p2.x - l2.p1.x) * (l1.p2.y - l1.p1.y);

    if (@abs(div) >= @as(f32, 1e-6)) {
        collision = true;

        const xi = ((l1.p1.x - l1.p2.x) * (l1.p1.x * l1.p2.y - l1.p1.y * l1.p2.x) - (l2.p1.x - l2.p2.x) * (l2.p1.x * l2.p2.y - l2.p1.y * l2.p2.x)) / div;
        const yi = ((l2.p1.y - l2.p2.y) * (l1.p1.x * l1.p2.y - l1.p1.y * l1.p2.x) - (l1.p1.y - l1.p2.y) * (l2.p1.x * l2.p2.y - l2.p1.y * l2.p2.x)) / div;

        if (((@abs(l1.p1.x - l1.p2.x) > @as(f32, 1e-6)) and (xi < @min(l1.p1.x, l1.p2.x) or xi > @max(l1.p1.x, l1.p2.x))) or
            ((@abs(l2.p1.x - l2.p2.x) > @as(f32, 1e-6)) and (xi < @min(l2.p1.x, l2.p2.x) or xi > @max(l2.p1.x, l2.p2.x))) or
            ((@abs(l1.p1.y - l1.p2.y) > @as(f32, 1e-6)) and (yi < @min(l1.p1.y, l1.p2.y) or yi > @max(l1.p1.y, l1.p2.y))) or
            ((@abs(l2.p1.y - l2.p2.y) > @as(f32, 1e-6)) and (yi < @min(l2.p1.y, l2.p2.y) or yi > @max(l2.p1.y, l2.p2.y))))
        {
            collision = false;
        }
    }

    return collision;
}

fn collisionRectangles(r1: *const Rectangle, r2: *const Rectangle) bool {
    var collision = false;
    if ((r1.pos.x() < (r2.x() + r2.width) and (r1.pos.x() + r1.width) > r2.pos.x()) and
        (r1.pos.y() < (r2.pos.y() + r2.height) and (r1.pos.y() + r1.height) > r2.pos.y())) collision = true;

    return collision;
}

pub fn pow(x: f32, n: f32) f32 {
    return std.math.pow(f32, x, n);
}

test "addition" {
    try std.testing.expectEqual(vec2(15, 10), vec2(5, 1).add(&vec2(10, 9)));
}
test "substruction" {
    try std.testing.expectEqual(vec2(2, 5), vec2(5, 9).sub(&vec2(3, 4)));
}
test "multipication" {
    try std.testing.expectEqual(vec2(12, 25), vec2(3, 5).mul(&vec2(4, 5)));
}
test "division" {
    try std.testing.expectEqual(vec2(3.5, 1.75), vec2(7, 5.25).div(&vec2(2, 3)));
}
test "translation" {
    try std.testing.expectEqual(vec2(48.5, 23), vec2(30, 26).translate(&vec2(18.5, -3)));
}
test "scaling" {
    try std.testing.expectEqual(vec2(45, 25), vec2(9, 5).scale(&vec2(5, 5)));
}
test "rotation" {
    const expected = vec2(2, 3);
    const tested = vec2(5, 2).rotate(90, &vec2(3, 1));
    try std.testing.expectApproxEqRel(expected.x(), tested.x(), 0.1);
    try std.testing.expectApproxEqRel(expected.y(), tested.y(), 0.1);
}
test "len" {
    try std.testing.expectEqual(5.0, vec2(1.0, 2.0).len(&vec2(4.0, 6.0)));
}
test "lerp" {
    try std.testing.expectEqual(vec2(20.0, 30.0), vec2(10.0, 20.0).lerp(&vec2(30.0, 40.0), 0.5));
}
