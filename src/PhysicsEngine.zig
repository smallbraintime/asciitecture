const std = @import("std");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const Line = math.Line;
const Rectangle = math.Rectangle;
const Point = math.Point;

const PhysicsEngine = @This();

objects: std.AutoHashMap(u32, *Object),
id_counter: u32,

const Object = union(enum) {
    point: Point,
    line: Line,
    rectangle: Rectangle,
};

pub fn init(allocator: std.mem.Allocator) void {
    return .{
        .objects = std.AutoHashMap(u32, Object).init(allocator),
        .id_counter = 0,
    };
}

pub fn deinit(self: *PhysicsEngine) void {
    self.objects.deinit();
}

pub fn addObject(self: *PhysicsEngine, object: *Object) !u32 {
    const id = self.id_counter;
    try self.objects.put(id, object);
    self.id_counter += 1;
    return id;
}

pub fn update(self: *PhysicsEngine, delta_time: f32) void {
    _ = self;
    _ = delta_time;
}
