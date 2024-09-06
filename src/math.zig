const std = @import("std");
const ScreenSize = @import("backend/main.zig").ScreenSize;

pub const Vec2 = struct {
    v: @Vector(2, f32),

    pub fn init(xs: f32, ys: f32) Vec2 {
        return .{ .v = .{ xs, ys } };
    }

    pub fn fromInt(xs: usize, ys: usize) Vec2 {
        return .{ .v = .{ @floatFromInt(xs), @floatFromInt(ys) } };
    }

    pub fn x(self: *const Vec2) f32 {
        return self.v[0];
    }

    pub fn y(self: *const Vec2) f32 {
        return self.v[1];
    }

    pub fn add(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v + b.v };
    }

    pub fn sub(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v - b.v };
    }

    pub fn mul(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v * b.v };
    }

    pub fn div(a: *const Vec2, b: *const Vec2) Vec2 {
        return .{ .v = a.v / b.v };
    }

    pub fn translate(a: *const Vec2, b: *const Vec2) Vec2 {
        return a.add(&b);
    }

    pub fn scale(a: *const Vec2, b: *const Vec2) Vec2 {
        return a.mul(&b);
    }

    pub fn rotate(self: *const Vec2, angle: f32) Vec2 {
        const xs = self.x();
        const ys = self.y();
        const cos = std.math.cos(angle);
        const sin = std.math.sin(angle);
        return init(xs * cos - ys * sin, xs * sin - ys * cos);
    }
};

pub const vec2 = Vec2.init;
