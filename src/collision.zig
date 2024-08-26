const graphics = @import("graphics.zig");
const Vec2 = graphics.Vec2;

pub const RectangleCollider = struct {
    position: Vec2,
    width: u16,
    height: u16,
};

pub const TriangleCollider = struct {
    vericies: []const Vec2,
};

pub const CircleCollider = struct {
    center: Vec2,
    radius: u16,
};

pub fn checkCollisionRecs() bool {}

pub fn checkCollisionCircs() bool {}

pub fn checkCollisionRecCirc() bool {}

pub fn checkCollisionPtRec() bool {}

pub fn checkCollisionPtCirc() bool {}

pub fn checkCollisionPtTria() bool {}

pub fn checkCollisionPtLn() bool {}

pub fn checkCollisionLines() bool {}
