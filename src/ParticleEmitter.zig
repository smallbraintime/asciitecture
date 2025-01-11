const std = @import("std");
const math = @import("math.zig");
const style = @import("style.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const Cell = style.Cell;
const Color = style.Color;
const Painter = @import("Painter.zig");
const randomRange = @import("util.zig").randomRange;

const Particle = struct {
    cell: Cell,
    delta_color_fg: DeltaColor,
    delta_color_bg: DeltaColor,
    pos: Vec2,
    velocity: Vec2,
    life: f32,

    pub fn setVelocity(self: *Particle, speed: f32, angle: f32) void {
        self.velocity = vec2(
            speed * @cos(std.math.degreesToRadians(angle)),
            -speed * @sin(std.math.degreesToRadians(angle)),
        );
    }
};

const DeltaColor = struct {
    r: f32,
    g: f32,
    b: f32,
};

pub const ParticleConfig = struct {
    pos: Vec2,
    amount: usize,
    chars: ?[]const u21,
    fg_color: ?ColorRange,
    bg_color: ?ColorRange,
    color_var: u8,
    start_angle: f32,
    end_angle: f32,
    life: f32,
    life_var: f32,
    speed: f32,
    speed_var: f32,
    emission_rate: f32,
    gravity: Vec2,
    duration: f32,
};

pub const ColorRange = struct {
    start: Color,
    end: Color,
};

pub const ParticleEmitter = @This();

config: ParticleConfig,
_particle_pool: std.ArrayList(Particle),
_particle_count: usize,
_emit_counter: f32,
_time_elapsed: f32,

pub fn init(allocator: std.mem.Allocator, config: ParticleConfig) !ParticleEmitter {
    var self = ParticleEmitter{
        .config = config,
        ._particle_pool = try std.ArrayList(Particle).initCapacity(allocator, config.amount),
        ._particle_count = 0,
        ._emit_counter = 0,
        ._time_elapsed = 0,
    };

    var current_index: usize = 0;
    while (current_index < self.config.amount) : (current_index += 1) {
        var particle: Particle = undefined;
        particle.cell.attr = .none;

        particle.cell.char = if (config.chars) |chars|
            chars[randomRange(usize, 0, chars.len - 1)]
        else
            randomRange(u21, 2, 1000);

        self.initParticle(&particle);
        self.setParticleColor(&particle);

        try self._particle_pool.append(particle);
    }

    return self;
}

pub fn deinit(self: *ParticleEmitter) void {
    self._particle_pool.deinit();
}

pub fn draw(self: *ParticleEmitter, painter: *Painter, delta_time: f32) void {
    self.update(delta_time);

    var current_index: usize = 0;
    while (current_index < self._particle_count) : (current_index += 1) {
        const particle = &self._particle_pool.items[current_index];
        painter.setCell(&particle.cell);
        painter.drawCell(particle.pos.x(), particle.pos.y());
    }
}

fn update(self: *ParticleEmitter, delta_time: f32) void {
    self._time_elapsed += delta_time;
    if (self._time_elapsed > self.config.duration) return;

    if (self.config.emission_rate > 0) {
        const rate = 1 / self.config.emission_rate;
        self._emit_counter += delta_time;

        while (self._particle_count < self._particle_pool.items.len and self._emit_counter > rate) {
            self.addParticle();
            self._emit_counter -= rate;
        }
    }

    var current_index: usize = 0;
    while (current_index < self._particle_count) {
        const particle = &self._particle_pool.items[current_index];

        if (particle.life > 0) {
            self.updateParticle(particle, delta_time);
            current_index += 1;
        } else {
            self.removeParticle(particle);
        }
    }
}

fn initParticle(self: *ParticleEmitter, particle: *Particle) void {
    const life = @max(std.math.floatEps(f32), self.config.life + self.config.life_var * randomRange(f32, -1, 1));
    const speed = self.config.speed + self.config.speed_var * randomRange(f32, -1, 1);
    const angle = randomRange(f32, self.config.start_angle, self.config.end_angle);

    particle.pos = self.config.pos;
    particle.life = @max(0, life);
    particle.setVelocity(speed, angle);

    self.setParticleColor(particle);
}

fn addParticle(self: *ParticleEmitter) void {
    self.initParticle(&self._particle_pool.items[self._particle_count]);
    self._particle_count += 1;
}

fn removeParticle(self: *ParticleEmitter, particle: *Particle) void {
    std.mem.swap(Particle, particle, &self._particle_pool.items[self._particle_count - 1]);
    self._particle_count -= 1;
}

fn updateParticle(self: *const ParticleEmitter, particle: *Particle, delta_time: f32) void {
    particle.life -= delta_time;
    particle.pos = particle.pos.add(&vec2(particle.velocity.x() * delta_time, particle.velocity.y() * delta_time));
    particle.pos = particle.pos.add(&self.config.gravity.mul(&vec2(delta_time, delta_time)));
    if (particle.cell.fg) |*fg| {
        fg.r = @intFromFloat(std.math.clamp(@as(f32, @floatFromInt(fg.r)) + particle.delta_color_fg.r * delta_time, 0, 255));
        fg.g = @intFromFloat(std.math.clamp(@as(f32, @floatFromInt(fg.g)) + particle.delta_color_fg.g * delta_time, 0, 255));
        fg.b = @intFromFloat(std.math.clamp(@as(f32, @floatFromInt(fg.b)) + particle.delta_color_fg.b * delta_time, 0, 255));
    }
    if (particle.cell.bg) |*bg| {
        bg.r = @intFromFloat(std.math.clamp(@as(f32, @floatFromInt(bg.r)) + particle.delta_color_bg.r * delta_time, 0, 255));
        bg.g = @intFromFloat(std.math.clamp(@as(f32, @floatFromInt(bg.g)) + particle.delta_color_bg.g * delta_time, 0, 255));
        bg.b = @intFromFloat(std.math.clamp(@as(f32, @floatFromInt(bg.b)) + particle.delta_color_bg.b * delta_time, 0, 255));
    }
}

fn setParticleColor(self: *ParticleEmitter, particle: *Particle) void {
    if (self.config.fg_color) |color| {
        const colors = calcColors(&color, self.config.color_var, particle.life);
        particle.cell.fg = colors.start_color;
        particle.delta_color_fg = colors.delta_color;
    } else {
        particle.cell.fg = null;
    }

    if (self.config.bg_color) |color| {
        const colors = calcColors(&color, self.config.color_var, particle.life);
        particle.cell.bg = colors.start_color;
        particle.delta_color_bg = colors.delta_color;
    } else {
        particle.cell.bg = null;
    }
}

fn calcColors(color: *const ColorRange, color_var: u8, life: f32) struct { start_color: Color, delta_color: DeltaColor } {
    var sr: f32 = @floatFromInt(color.start.r);
    var sg: f32 = @floatFromInt(color.start.g);
    var sb: f32 = @floatFromInt(color.start.b);
    var er: f32 = @floatFromInt(color.end.r);
    var eg: f32 = @floatFromInt(color.end.g);
    var eb: f32 = @floatFromInt(color.end.b);
    const cvar: f32 = @floatFromInt(color_var);

    sr = std.math.clamp(sr + cvar * randomRange(f32, -1, 1), 0, 255);
    sg = std.math.clamp(sg + cvar * randomRange(f32, -1, 1), 0, 255);
    sb = std.math.clamp(sb + cvar * randomRange(f32, -1, 1), 0, 255);

    er = std.math.clamp(er + cvar * randomRange(f32, -1, 1), 0, 255);
    eg = std.math.clamp(eg + cvar * randomRange(f32, -1, 1), 0, 255);
    eb = std.math.clamp(eb + cvar * randomRange(f32, -1, 1), 0, 255);

    const delta_r = (er - sr) / life;
    const delta_g = (eg - sg) / life;
    const delta_b = (eb - sb) / life;

    return .{
        .start_color = .{ .r = @intFromFloat(sr), .g = @intFromFloat(sg), .b = @intFromFloat(sb) },
        .delta_color = .{ .r = delta_r, .g = delta_g, .b = delta_b },
    };
}
