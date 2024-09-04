const std = @import("std");

pub const Vec2 = struct {
    v: @Vector(2, f32),

    pub fn init(xs: f32, ys: f32) Vec2 {
        return .{ .v = .{ xs, ys } };
    }

    pub fn x(self: *const Vec2) f32 {
        return self.v[0];
    }

    pub fn y(self: *const Vec2) f32 {
        return self.v[1];
    }

    pub fn add(self: *const Vec2, v: *const Vec2) void {
        self.v + v.v;
    }

    pub fn addX(self: *const Vec2, xs: f32) void {
        self.v[0] + xs;
    }

    pub fn addY(self: *const Vec2, ys: f32) void {
        self.v[1] + ys;
    }

    pub fn sub(self: *const Vec2, v: *const Vec2) void {
        self.v - v.v;
    }

    pub fn subX(self: *const Vec2, xs: f32) void {
        self.v[0] - xs;
    }

    pub fn subY(self: *const Vec2, ys: f32) void {
        self.v[1] - ys;
    }

    pub fn mul(self: *const Vec2, v: *const Vec2) void {
        self.v * v.v;
    }

    pub fn mulX(self: *const Vec2, xs: f32) void {
        self.v[0] * xs;
    }

    pub fn mulY(self: *const Vec2, ys: f32) void {
        self.v[1] * ys;
    }

    pub fn div(self: *const Vec2, v: *const Vec2) void {
        self.v / v.v;
    }

    pub fn divX(self: *const Vec2, xs: f32) void {
        self.v[0] / xs;
    }

    pub fn divY(self: *const Vec2, ys: f32) void {
        self.v[1] / ys;
    }
};

pub const vec2 = Vec2.init;

pub fn worldToScreen(v: *const Vec2, screenWidth: usize, screenHeight: usize, worldWidth: f32, worldHeight: f32) Vec2 {
    const fScreenWidth: f32 = @floatFromInt(screenWidth);
    const fScreenHeight: f32 = @floatFromInt(screenHeight);

    const scaleX = fScreenWidth / worldWidth;
    const scaleY = fScreenHeight / worldHeight;

    const centerX = fScreenWidth / 2;
    const centerY = fScreenHeight / 2;

    return vec2(centerX + v.x() * scaleX, centerY + v.y() * scaleY);
}
