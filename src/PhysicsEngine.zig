const std = @import("std");
const math = @import("math.zig");
const RigidBody = @import("RigidBody.zig");
const Vec2 = math.Vec2;
const Line = math.Line;
const Rectangle = math.Rectangle;
const Point = math.Point;
const vec2 = math.vec2;

const PhysicsEngine = @This();

objects: std.AutoHashMap(u32, *RigidBody),
gravity: Gravity,
_id_counter: u32,

pub const Gravity = struct {
    direction: Vec2,
    force: f32,
};

pub fn init(allocator: std.mem.Allocator, gravity: *const Gravity) PhysicsEngine {
    return .{
        .objects = std.AutoHashMap(u32, *RigidBody).init(allocator),
        .gravity = gravity.*,
        ._id_counter = 0,
    };
}

pub fn deinit(self: *PhysicsEngine) void {
    self.objects.deinit();
}

pub fn addObject(self: *PhysicsEngine, object: *RigidBody) !u32 {
    const id = self.id_counter;
    try self.objects.put(id, object);
    self._id_counter += 1;
    return id;
}

pub fn update(self: *PhysicsEngine, delta_time: f32) void {
    self.resolveCollisions(delta_time);
    self.updateKinematics(delta_time);
}

fn updateKinematics(self: *PhysicsEngine, delta_time: f32) void {
    var it = self.objects.iterator();
    while (it.next()) |obj| {
        obj.value_ptr.*.applyGravity(&self.gravity, delta_time);
        obj.value_ptr.*.updateMotion(delta_time);
    }
}

fn resolveCollisions(self: *const PhysicsEngine, delta_time: f32) void {
    var it = self.objects.iterator();
    while (it.next()) |obj| {
        var l_it = self.objects.iterator();
        while (l_it.next()) |other| {
            obj.value_ptr.*.resolveCollision(other.value_ptr.*);
        }
    }
    _ = delta_time;
}

test "it just works" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak occured");
    var pe = PhysicsEngine.init(gpa.allocator(), &.{ .direction = vec2(0, 0), .force = 1 });
    defer pe.deinit();
    pe.update(0);
}
