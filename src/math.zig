const std = @import("std");

pub const Shape = union(enum) {
    point: Point,
    line: Line,
    rectangle: Rectangle,
    ellipse: Ellipse,
};

pub const Point = struct {
    p: Vec2,

    pub fn init(pos: Vec2) Point {
        return .{
            .p = pos,
        };
    }

    pub inline fn collidesWith(self: *const Point, shape: *const Shape) bool {
        switch (shape.*) {
            .point => |*p| return collisionPoints(self, p),
            .line => |*l| return collisionPointLine(self, l),
            .rectangle => |*r| return collisionPointRectangle(self, r),
            .ellipse => |*e| return collisionPointEllipse(self, e),
        }
    }
};

pub const Line = struct {
    p1: Vec2,
    p2: Vec2,

    pub fn init(p1: Vec2, p2: Vec2) Line {
        return .{
            .p1 = p1,
            .p2 = p2,
        };
    }

    pub inline fn collidesWith(self: *const Line, shape: *const Shape) bool {
        switch (shape.*) {
            .point => |*p| return collisionPointLine(p, self),
            .line => |*l| return collisionLines(self, l),
            .rectangle => |*r| return collisionLineRectangle(self, r),
            .ellipse => |*e| return collisionLineEllipse(self, e),
        }
    }
};

pub const Rectangle = struct {
    pos: Vec2,
    width: f32,
    height: f32,

    pub fn init(pos: Vec2, width: f32, height: f32) Rectangle {
        return .{
            .pos = pos,
            .width = width,
            .height = height,
        };
    }

    pub inline fn collidesWith(self: *const Rectangle, shape: *const Shape) bool {
        switch (shape.*) {
            .point => |*p| return collisionPointRectangle(p, self),
            .line => |*l| return collisionLineRectangle(l, self),
            .rectangle => |*r| return collisionRectangles(self, r),
            .ellipse => |*e| return collisionRectangleEllipse(self, e),
        }
    }
};

pub const Ellipse = struct {
    center: Vec2,
    radius: f32,

    pub fn init(center: Vec2, radius: f32) Ellipse {
        return .{
            .center = center,
            .radius = radius,
        };
    }

    pub inline fn collidesWith(self: *const Ellipse, shape: *const Shape) bool {
        switch (shape.*) {
            .point => |*p| return collisionPointEllipse(p, self),
            .line => |*l| return collisionLineEllipse(l, self),
            .rectangle => |*r| return collisionRectangleEllipse(r, self),
            .ellipse => |*e| return collisionEllipses(self, e),
        }
    }
};

inline fn collisionPoints(p1: *const Point, p2: *const Point) bool {
    return p1.p.x() == p2.p.x() and p1.p.y() == p2.p.y();
}

inline fn collisionPointLine(point: *const Point, line: *const Line) bool {
    var collision = false;

    const dxc = point.p.x() - line.p1.x();
    const dyc = point.p.y() - line.p1.y();
    const dxl = line.p2.x() - line.p1.x();
    const dyl = line.p2.y() - line.p1.y();
    const cross = dxc * dyl - dyc * dxl;

    if (@abs(cross) < 1e-6) {
        if (@abs(dxl) >= @abs(dyl)) {
            collision = if (dxl > 0)
                line.p1.x() <= point.p.x() and point.p.x() <= line.p2.x()
            else
                line.p2.x() <= point.p.x() and point.p.x() <= line.p1.x();
        } else {
            collision = if (dyl > 0)
                line.p1.y() <= point.p.y() and point.p.y() <= line.p2.y()
            else
                line.p2.y() <= point.p.y() and point.p.y() <= line.p1.y();
        }
    }

    return collision;
}

inline fn collisionPointRectangle(point: *const Point, rectangle: *const Rectangle) bool {
    var collision = false;

    if ((point.p.x() >= rectangle.pos.x()) and (point.p.x() < (rectangle.pos.x() + rectangle.width)) and (point.p.y() >= rectangle.pos.y()) and (point.p.y() < (rectangle.pos.y() + rectangle.height))) collision = true;

    return collision;
}

inline fn collisionPointEllipse(point: *const Point, ellipse: *const Ellipse) bool {
    const distance = point.p.distance(&ellipse.center);
    return distance <= ellipse.radius;
}

inline fn collisionLines(l1: *const Line, l2: *const Line) bool {
    var collision = false;

    const div = (l2.p2.y() - l2.p1.y()) * (l1.p2.x() - l1.p1.x()) -
        (l2.p2.x() - l2.p1.x()) * (l1.p2.y() - l1.p1.y());

    if (@abs(div) >= std.math.floatEps(f32)) {
        collision = true;

        const xi = ((l2.p1.x() - l2.p2.x()) * (l1.p1.x() * l1.p2.y() - l1.p1.y() * l1.p2.x()) -
            (l1.p1.x() - l1.p2.x()) * (l2.p1.x() * l2.p2.y() - l2.p1.y() * l2.p2.x())) / div;
        const yi = ((l2.p1.y() - l2.p2.y()) * (l1.p1.x() * l1.p2.y() - l1.p1.y() * l1.p2.x()) -
            (l1.p1.y() - l1.p2.y()) * (l2.p1.x() * l2.p2.y() - l2.p1.y() * l2.p2.x())) / div;

        if (((@abs(l1.p1.x() - l1.p2.x()) > std.math.floatEps(f32)) and
            (xi < @min(l1.p1.x(), l1.p2.x()) or xi > @max(l1.p1.x(), l1.p2.x()))) or
            ((@abs(l2.p1.x() - l2.p2.x()) > std.math.floatEps(f32)) and
            (xi < @min(l2.p1.x(), l2.p2.x()) or xi > @max(l2.p1.x(), l2.p2.x()))) or
            ((@abs(l1.p1.y() - l1.p2.y()) > std.math.floatEps(f32)) and
            (yi < @min(l1.p1.y(), l1.p2.y()) or yi > @max(l1.p1.y(), l1.p2.y()))) or
            ((@abs(l2.p1.y() - l2.p2.y()) > std.math.floatEps(f32)) and
            (yi < @min(l2.p1.y(), l2.p2.y()) or yi > @max(l2.p1.y(), l2.p2.y()))))
        {
            collision = false;
        }
    }

    return collision;
}

inline fn collisionLineRectangle(line: *const Line, rectangle: *const Rectangle) bool {
    const rect_top_left = vec2(rectangle.pos.x(), rectangle.pos.y());
    const rect_top_right = vec2(rectangle.pos.x() + rectangle.width, rectangle.pos.y());
    const rect_bottom_left = vec2(rectangle.pos.x(), rectangle.pos.y() + rectangle.height);
    const rect_bottom_right = vec2(rectangle.pos.x() + rectangle.width, rectangle.pos.y() + rectangle.height);

    if (collisionLines(line, &Line.init(rect_top_left, rect_top_right))) return true;
    if (collisionLines(line, &Line.init(rect_top_right, rect_bottom_right))) return true;
    if (collisionLines(line, &Line.init(rect_bottom_right, rect_bottom_left))) return true;
    if (collisionLines(line, &Line.init(rect_bottom_left, rect_top_left))) return true;

    return false;
}

inline fn collisionLineEllipse(line: *const Line, ellipse: *const Ellipse) bool {
    const d = line.p1.sub(&line.p2);
    if (@abs(d.x()) + @abs(d.y()) <= std.math.floatEps(f32)) return collisionEllipses(&Ellipse.init(line.p1, 0), ellipse);

    const sq_len = d.squaredLen();
    const dot = std.math.clamp(((ellipse.center.x() - line.p1.x()) * (line.p2.x() - line.p1.x()) +
        (ellipse.center.y() - line.p1.y()) * (line.p2.y() - line.p1.y())) / sq_len, 0, 1);

    const closest_x = line.p1.x() + dot * d.x();
    const closest_y = line.p1.y() + dot * d.y();

    const dx = closest_x - ellipse.center.x();
    const dy = closest_y - ellipse.center.y();
    const sq_dist = vec2(dx, dy).squaredLen();

    return sq_dist <= ellipse.radius * ellipse.radius;
}

inline fn collisionRectangles(r1: *const Rectangle, r2: *const Rectangle) bool {
    var collision = false;
    if ((r1.pos.x() < (r2.pos.x() + r2.width) and (r1.pos.x() + r1.width) > r2.pos.x()) and
        (r1.pos.y() < (r2.pos.y() + r2.height) and (r1.pos.y() + r1.height) > r2.pos.y())) collision = true;

    return collision;
}

inline fn collisionRectangleEllipse(rectangle: *const Rectangle, ellipse: *const Ellipse) bool {
    const rec_center_x = rectangle.pos.x() + rectangle.width / 2;
    const rec_center_y = rectangle.pos.y() + rectangle.height / 2;

    const dx = @abs(ellipse.center.x() - rec_center_x);
    const dy = @abs(ellipse.center.y() - rec_center_y);

    if (dx > (rectangle.width / 2 + ellipse.radius)) return false;
    if (dy > (rectangle.height / 2 + ellipse.radius)) return false;

    if (dx <= (rectangle.width / 2)) return true;
    if (dy <= (rectangle.height / 2)) return true;

    const corner_distance_squared = (dx - rectangle.width / 2) * (dx - rectangle.width / 2) + (dy - rectangle.height / 2) * (dy - rectangle.height / 2);

    return corner_distance_squared <= (ellipse.radius * ellipse.radius);
}

inline fn collisionEllipses(c1: *const Ellipse, c2: *const Ellipse) bool {
    const distance = c1.center.distance(&c2.center);
    return distance <= c1.radius + c2.radius;
}

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

    pub inline fn splat(scalar: f32) Vec2 {
        return .{ .v = @splat(scalar) };
    }

    pub inline fn add(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v + b.v };
    }

    pub inline fn addScalar(self: *const Vec2, scalar: f32) Vec2 {
        return .{ .v = self.v + Vec2.splat(scalar).v };
    }

    pub inline fn sub(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v - b.v };
    }

    pub inline fn subScalar(self: *const Vec2, scalar: f32) Vec2 {
        return .{ .v = self.v - Vec2.splat(scalar).v };
    }

    pub inline fn mul(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v * b.v };
    }

    pub inline fn mulScalar(self: *const Vec2, scalar: f32) Vec2 {
        return .{ .v = self.v * Vec2.splat(scalar).v };
    }

    pub inline fn div(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v / b.v };
    }

    pub inline fn divScalar(self: *const Vec2, scalar: f32) Vec2 {
        return .{ .v = self.v / Vec2.splat(scalar).v };
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

    pub inline fn distance(self: *const Vec2, other: *const Vec2) f32 {
        return @sqrt(self.squaredDistance(other));
    }

    pub inline fn squaredDistance(self: *const Vec2, other: *const Vec2) f32 {
        const dx = other.x() - self.x();
        const dy = other.y() - self.y();
        return dx * dx + dy * dy;
    }

    pub inline fn len(self: *const Vec2) f32 {
        return @sqrt(self.squaredLen());
    }

    pub inline fn squaredLen(self: *const Vec2) f32 {
        return (self.x() * self.x()) + (self.y() * self.y());
    }

    pub inline fn dot(self: *const Vec2, other: *const Vec2) f32 {
        return @reduce(.Add, self.v * other.v);
    }

    pub inline fn lerp(self: *const Vec2, other: *const Vec2, amount: f32) Vec2 {
        return self.add(&other.sub(self).mul(&vec2(amount, amount)));
    }
};

test "Vec2.add" {
    try std.testing.expectEqual(vec2(15, 10), vec2(5, 1).add(&vec2(10, 9)));
}

test "Vec2.sub" {
    try std.testing.expectEqual(vec2(2, 5), vec2(5, 9).sub(&vec2(3, 4)));
}

test "Vec2.mul" {
    try std.testing.expectEqual(vec2(12, 25), vec2(3, 5).mul(&vec2(4, 5)));
}

test "Vec2.div" {
    try std.testing.expectEqual(vec2(3.5, 1.75), vec2(7, 5.25).div(&vec2(2, 3)));
}

test "Vec2.translate" {
    try std.testing.expectEqual(vec2(48.5, 23), vec2(30, 26).translate(&vec2(18.5, -3)));
}

test "Vec2.scale" {
    try std.testing.expectEqual(vec2(45, 25), vec2(9, 5).scale(&vec2(5, 5)));
}

test "Vec2.rotate" {
    const expected = vec2(2, 3);
    const tested = vec2(5, 2).rotate(90, &vec2(3, 1));
    try std.testing.expectApproxEqRel(expected.x(), tested.x(), 0.1);
    try std.testing.expectApproxEqRel(expected.y(), tested.y(), 0.1);
}

test "Vec2.distance" {
    try std.testing.expectEqual(5.0, vec2(1.0, 2.0).distance(&vec2(4.0, 6.0)));
}

test "Vec2.lerp" {
    try std.testing.expectEqual(vec2(20.0, 30.0), vec2(10.0, 20.0).lerp(&vec2(30.0, 40.0), 0.5));
}

test "Point.collisionPoint" {
    const point1 = Point.init(vec2(0, 0));
    const point2 = Point.init(vec2(0, 0));
    try std.testing.expect(point1.collidesWith(&.{ .point = point2 }));
}

test "Point.collisionLine" {
    const point = Point.init(vec2(1, 1));
    const line = Line.init(vec2(0, 0), vec2(2, 2));
    try std.testing.expect(point.collidesWith(&.{ .line = line }));
}

test "Point.collisionRectangle" {
    const point = Point.init(vec2(1, 1));
    const rectangle = Rectangle.init(vec2(0, 0), 3.0, 3.0);
    try std.testing.expect(point.collidesWith(&.{ .rectangle = rectangle }));
}

test "Line.collisionPoint" {
    const line = Line.init(vec2(0, 0), vec2(2, 2));
    const point = Point.init(vec2(1, 1));
    try std.testing.expect(line.collidesWith(&.{ .point = point }));
}

test "Line.collisionLine" {
    const line1 = Line.init(vec2(1, 1), vec2(5, 1));
    const line2 = Line.init(vec2(2.5, 5), vec2(2.5, -2));
    try std.testing.expect(line1.collidesWith(&.{ .line = line2 }));
}

test "Line.collisionRectangle" {
    const line = Line.init(vec2(0, 0), vec2(1, 1));
    const rectangle = Rectangle.init(vec2(0, 0), 3.0, 3.0);
    try std.testing.expect(line.collidesWith(&.{ .rectangle = rectangle }));
}

test "Rectangle.collisionPoint" {
    const rectangle = Rectangle.init(vec2(0, 0), 3.0, 3.0);
    const point = Point.init(vec2(1, 1));
    try std.testing.expect(rectangle.collidesWith(&.{ .point = point }));
}

test "Rectangle.collisionLine" {
    const rectangle = Rectangle.init(vec2(0, 0), 3.0, 3.0);
    const line = Line.init(vec2(-10, 3), vec2(10, 3));
    try std.testing.expect(rectangle.collidesWith(&.{ .line = line }));
}

test "Rectangle.collisionRectangle" {
    const rectangle1 = Rectangle.init(vec2(0, 0), 3.0, 3.0);
    const rectangle2 = Rectangle.init(vec2(2, 2), 3.0, 3.0);
    try std.testing.expect(rectangle1.collidesWith(&.{ .rectangle = rectangle2 }));
}

test "Ellipse.collisionPoint" {
    const ellipse = Ellipse.init(vec2(0, 0), 3.0);
    const point = Point.init(vec2(1, 1));
    try std.testing.expect(ellipse.collidesWith(&.{ .point = point }));
}

test "Ellipse.collisionLine" {
    const ellipse = Ellipse.init(vec2(0, 0), 3.0);
    const line = Line.init(vec2(0, 0), vec2(1, 1));
    try std.testing.expect(ellipse.collidesWith(&.{ .line = line }));
}

test "Ellipse.collisionRectangle" {
    const ellipse = Ellipse.init(vec2(0, 0), 3.0);
    const rectangle = Rectangle.init(vec2(2, 2), 3.0, 3.0);
    try std.testing.expect(ellipse.collidesWith(&.{ .rectangle = rectangle }));
}

test "Ellipse.collisionellipse" {
    const ellipse1 = Ellipse.init(vec2(0, 0), 3.0);
    const ellipse2 = Ellipse.init(vec2(2, 2), 3.0);
    try std.testing.expect(ellipse1.collidesWith(&.{ .ellipse = ellipse2 }));
}
