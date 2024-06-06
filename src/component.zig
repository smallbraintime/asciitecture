const std = @import("std");

const StaticObject = struct {
    components: @Vector(1, Component),
    position: Vec2,
    pub fn new() StaticObject {}
    pub fn attach(component: Component) void {}
    pub fn render() void {}
};

pub const Line = struct { point1: Vec2, point2: Vec2 };

pub const Rectange = struct {
    width: usize,
    height: usize,
    pub fn new() Rectange {}
    pub fn render() void {}
};

pub const Triangle = struct {
    points: [3]Vec2,
    pub fn new() Triangle {}
    pub fn render() void {}
};

pub const Circle = struct {
    radius: usize,
    pub fn new() Circle {}
    pub fn render() void {}
};

pub const Text = struct { content: []const u8 };

pub const Canvas = struct { width: usize, height: usize, buffer: std.ArrayList(u8) };

pub const Vec2 = struct { x: isize, y: isize };

pub const Component = struct {};
