const math = @import("math.zig");
const Vec2 = math.Vec2;
const Shape = math.Shape;
const Gravity = @import("PhysicsEngine.zig").Gravity;
const vec2 = math.vec2;

const RigidBody = @This();

shape: Shape,
velocity: Vec2,
immovable: bool,

pub fn init(shape: *const Shape, velocity: *const Vec2, immovable: bool) RigidBody {
    return .{
        .shape = shape.*,
        .velocity = velocity.*,
        .immovable = immovable,
    };
}

pub inline fn applyGravity(self: *RigidBody, gravity: *const Gravity, delta_time: f32) void {
    self.velocity = self.velocity.add(&vec2(gravity.force * gravity.direction.x() * delta_time, gravity.force * gravity.direction.y() * delta_time));
}

pub inline fn updateMotion(self: *RigidBody, delta_time: f32) void {
    switch (self.shape) {
        .point => |*point| point.p = point.p.add(&vec2(self.velocity.x() * delta_time, self.velocity.x() * delta_time)),
        .line => |*line| {
            line.p1 = line.p1.add(&vec2(self.velocity.x() * delta_time, self.velocity.y() * delta_time));
            line.p2 = line.p2.add(&vec2(self.velocity.x() * delta_time, self.velocity.y() * delta_time));
        },
        .rectangle => |*rectangle| {
            rectangle.pos = rectangle.pos.add(&vec2(self.velocity.x() * delta_time, self.velocity.y() * delta_time));
        },
    }
}

pub inline fn resolveCollision(self: *RigidBody, object: *const RigidBody) void {
    switch (self.shape) {
        .point => |*point| if (point.collidesWith(&object.shape)) {},
        .line => |*line| if (line.collidesWith(&object.shape)) {},
        .rectangle => |*rectangle| if (rectangle.collidesWith(&object.shape)) {},
    }
}
