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
};

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
