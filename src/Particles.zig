const std = @import("std");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const Cell = @import("style.zig").Cell;
const Painter = @import("Painter.zig");

pub const Particle = struct {
    cell: Cell,
    pos: Vec2,
    start_pos: Vec2,
    velocity: Vec2,
    life: f32,
    life_counter: f32,

    pub fn init(cell: *const Cell, start_pos: *const Vec2, life: f32, angle: f32, speed: f32) Particle {
        return .{
            .cell = cell.*,
            .pos = start_pos.*,
            .start_pos = start_pos.*,
            .velocity = vec2(
                speed * @cos(std.math.degreesToRadians(angle)),
                -speed * @sin(std.math.degreesToRadians(angle)),
            ),
            .life = life,
            .life_counter = life,
        };
    }

    pub fn update(self: *Particle, looping: bool, delta_time: f32) void {
        self.life_counter -= delta_time;
        if (self.life_counter > 0) {
            self.pos = self.pos.add(&vec2(self.velocity.x() * delta_time, self.velocity.y() * delta_time));
        } else {
            if (looping) {
                self.pos = self.start_pos;
                self.life_counter = self.life;
            }
        }
    }
};

const Particles = @This();

pos: Vec2,
particles: []Particle,
looping: bool,

pub fn init(pos: *const Vec2, looping: bool, particles: []Particle) Particles {
    return .{
        .pos = pos.*,
        .particles = particles,
        .looping = looping,
    };
}

pub fn draw(self: *Particles, painter: *Painter, delta_time: f32) void {
    self.update(self.looping, delta_time);
    for (self.particles) |particle| {
        painter.setCell(&particle.cell);
        painter.drawCell(particle.pos.x(), particle.pos.y());
    }
}

pub fn update(self: *Particles, looping: bool, delta_time: f32) void {
    for (self.particles) |*particle| {
        particle.update(looping, delta_time);
    }
}
