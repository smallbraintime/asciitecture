const std = @import("std");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const style = @import("style.zig");
const Cell = style.Cell;
const Painter = @import("Painter.zig");
const rgb = style.rgb;

pub const Particle = struct {
    pub const ParticleConfig = struct {
        start_cell: Cell,
        start_pos: Vec2,
        life: f32,
        fading: bool,
        speed: f32,
        angle: f32,
    };

    config: ParticleConfig,
    cell: Cell,
    pos: Vec2,
    velocity: Vec2,
    life_counter: f32,

    pub fn init(config: *const ParticleConfig) Particle {
        return .{
            .config = config.*,
            .cell = config.start_cell,
            .pos = config.start_pos,
            .velocity = vec2(
                config.speed * @cos(std.math.degreesToRadians(config.angle)),
                -config.speed * @sin(std.math.degreesToRadians(config.angle)),
            ),
            .life_counter = config.life,
        };
    }

    pub fn update(self: *Particle, looping: bool, delta_time: f32) void {
        self.life_counter -= delta_time;
        if (self.life_counter > 0) {
            self.pos = self.pos.add(&vec2(self.velocity.x() * delta_time, self.velocity.y() * delta_time));
            if (self.config.fading) {
                if (self.config.start_cell.fg == .rgb) {
                    const age_ratio = self.life_counter / self.config.life;
                    const r: u8 = @intFromFloat(@as(f32, @floatFromInt(self.config.start_cell.fg.rgb.r)) * age_ratio);
                    const g: u8 = @intFromFloat(@as(f32, @floatFromInt(self.config.start_cell.fg.rgb.g)) * age_ratio);
                    const b: u8 = @intFromFloat(@as(f32, @floatFromInt(self.config.start_cell.fg.rgb.b)) * age_ratio);
                    self.cell.fg = rgb(r, g, b);
                }
            }
        } else {
            if (looping) {
                self.pos = self.config.start_pos;
                self.life_counter = self.config.life;
                if (self.config.fading) self.cell = self.config.start_cell;
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
