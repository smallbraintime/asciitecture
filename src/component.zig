const std = @import("std");
const Cell = @import("terminal.zig").Cell;

pub const StaticObject = struct {
    components: std.ArrayList(*Component),
    position: Vec2,

    pub fn init(allocator: std.mem.Allocator) StaticObject {
        return StaticObject{
            .components = std.ArrayList(Component).init(allocator),
            .position = Vec2{ .x = 0, .y = 0 },
        };
    }

    pub fn attach(self: *StaticObject, component: *Component) void {
        self.components.append(component);
    }

    pub fn render(self: *StaticObject) void {
        for (self.components) |component| {
            component.render();
        }
    }

    pub fn deinit(self: StaticObject) void {
        self.components.deinit();
    }
};

pub const Line = struct {
    point1: Vec2,
    point2: Vec2,
    pos: Vec2,
    style: Cell,
    component: Component = Component{ .renderFunc = render },

    pub fn render(component: *Component) void {}
};

pub const Rectange = struct {
    width: usize,
    height: usize,
    pos: Vec2,
    style: Cell,
    component: Component = Component{ .renderFunc = render },

    pub fn new() Rectange {}

    pub fn render(component: *Component) void {}
};

pub const Triangle = struct {
    points: [3]Vec2,
    pos: Vec2,
    style: Cell,
    component: Component = Component{ .renderFunc = render },

    pub fn new() Triangle {}

    pub fn render(component: *Component) void {}
};

pub const Circle = struct {
    radius: usize,
    pos: Vec2,
    style: Cell,
    component: Component = Component{ .renderFunc = render },

    pub fn new() Circle {}

    pub fn render(component: *Component) void {}
};

pub const Text = struct {
    content: []const u8,
    pos: Vec2,
    style: Cell,
    component: Component = Component{ .renderFunc = render },

    pub fn render(component: *Component) void {}
};

pub const Canvas = struct {
    width: usize,
    height: usize,
    buffer: []const Cell,
    pos: Vec2,
    component: Component = Component{ .renderFunc = render },

    pub fn render(component: *Component) void {}
};

pub const Particle = struct {
    style: Cell,
    lifetime: f32,
    velocity: Vec2,
    pos: Vec2,
    component: Component = Component{ .renderFunc = render },

    pub fn render(component: *Component) void {}
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
    pos: Vec2,
    component: Component = Component{ .renderFunc = render },

    pub fn render(component: *Component) void {}
};

pub const Vec2 = struct {
    x: isize,
    y: isize,
};

pub const Component = struct {
    renderFunc: *const fn (*const Component) void,

    pub fn render(self: *const Component) void {
        self.renderFunc(self);
    }
};
