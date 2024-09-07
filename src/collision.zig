const graphics = @import("graphics.zig");
const Vec2 = graphics.Vec2;

pub const Rectangle = struct {
    position: Vec2,
    width: f32,
    height: f32,
};

pub const Triangle = struct {
    vericies: []const Vec2,
};

pub const Circle = struct {
    center: Vec2,
    radius: f32,
};

pub fn checkCollisionRecs(a: *const Rectangle, b: *const Rectangle) bool {
    _ = a;
    _ = b;
}

pub fn checkCollisionCircs(a: *const Circle, b: *const Circle) bool {
    _ = a;
    _ = b;
}

pub fn checkCollisionRecCirc(rec: *const Rectangle, circ: *const Circle) bool {
    _ = rec;
    _ = circ;
}

pub fn checkCollisionPtRec(p: *const Vec2, rec: *const Rectangle) bool {
    _ = p;
    _ = rec;
}

pub fn checkCollisionPtCirc(p: *const Vec2, circ: *const Circle) bool {
    _ = p;
    _ = circ;
}

pub fn checkCollisionPtTrian(p: *const Vec2, trian: *const Triangle) bool {
    _ = p;
    _ = trian;
}

pub fn checkCollisionPtLn(p: *const Vec2, ln_p0: Vec2, ln_p1: Vec2) bool {
    _ = p;
    _ = ln_p0;
    _ = ln_p1;
}

pub fn checkCollisionLines(a0: Vec2, a1: Vec2, b0: Vec2, b1: Vec2) bool {
    _ = a0;
    _ = a1;
    _ = b0;
    _ = b1;
}
