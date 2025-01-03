const std = @import("std");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const style = @import("style.zig");
const Cell = style.Cell;
const RgbColor = style.RgbColor;
const Painter = @import("Painter.zig");
const randomRange = @import("util.zig").randomRange;
const clamp = std.math.clamp;

pub fn ParticleEmitter(comptime amount: usize) type {
    return struct {
        particle_pool: [amount]Particle,
        amount: usize,
        config: ParticleConfig,
        particle_count: usize,
        emit_counter: f32,
        time_elapsed: f32,

        pub fn init(config: *const ParticleConfig) ParticleEmitter(amount) {
            var self = ParticleEmitter(amount){
                .particle_pool = undefined,
                .amount = amount,
                .config = config.*,
                .particle_count = amount,
                .emit_counter = 0,
                .time_elapsed = 0,
            };

            for (&self.particle_pool) |*particle| {
                particle.cell.attr = .none;

                particle.cell.char = if (config.chars) |chars|
                    chars[randomRange(usize, 0, chars.len - 1)]
                else
                    randomRange(u21, 2, 1000);

                self.initParticle(particle);
                self.setParticleColor(particle);
            }

            return self;
        }

        pub fn draw(self: *ParticleEmitter(amount), painter: *Painter, delta_time: f32) void {
            self.update(delta_time);

            var current_index: usize = 0;
            while (current_index < self.particle_count) : (current_index += 1) {
                const particle = &self.particle_pool[current_index];
                painter.setCell(&particle.cell);
                painter.drawCell(particle.pos.x(), particle.pos.y());
            }
        }

        pub fn update(self: *ParticleEmitter(amount), delta_time: f32) void {
            self.time_elapsed += delta_time;
            if (self.time_elapsed > self.config.duration) return;

            if (self.config.emission_rate > 0) {
                const rate = 1 / self.config.emission_rate;
                self.emit_counter += delta_time;

                while (self.particle_count < self.particle_pool.len and self.emit_counter > rate) {
                    self.addParticle();
                    self.emit_counter -= rate;
                }
            }

            var current_index: usize = 0;
            while (current_index < self.particle_count) {
                const particle = &self.particle_pool[current_index];

                if (particle.life > 0) {
                    self.updateParticle(particle, delta_time);
                    current_index += 1;
                } else {
                    self.removeParticle(particle);
                }
            }
        }

        fn initParticle(self: *ParticleEmitter(amount), particle: *Particle) void {
            const life = @max(std.math.floatEps(f32), self.config.life + self.config.life_var * randomRange(f32, -1, 1));
            const speed = self.config.speed + self.config.speed_var * randomRange(f32, -1, 1);
            const angle = randomRange(f32, self.config.start_angle, self.config.end_angle);

            particle.pos = self.config.pos;
            particle.life = @max(0, life);
            particle.setVelocity(speed, angle);

            self.setParticleColor(particle);
        }

        fn addParticle(self: *ParticleEmitter(amount)) void {
            self.initParticle(&self.particle_pool[self.particle_count]);
            self.particle_count += 1;
        }

        fn removeParticle(self: *ParticleEmitter(amount), particle: *Particle) void {
            std.mem.swap(Particle, particle, &self.particle_pool[self.particle_count - 1]);
            self.particle_count -= 1;
        }

        fn updateParticle(self: *const ParticleEmitter(amount), particle: *Particle, delta_time: f32) void {
            particle.life -= delta_time;
            particle.pos = particle.pos.add(&vec2(particle.velocity.x() * delta_time, particle.velocity.y() * delta_time));
            particle.pos = particle.pos.add(&self.config.gravity.mul(&vec2(delta_time, delta_time)));
            if (particle.cell.fg != .none) {
                particle.cell.fg.rgb.r = @intFromFloat(clamp(@as(f32, @floatFromInt(particle.cell.fg.rgb.r)) + particle.delta_color_fg.r * delta_time, 0, 255));
                particle.cell.fg.rgb.g = @intFromFloat(clamp(@as(f32, @floatFromInt(particle.cell.fg.rgb.g)) + particle.delta_color_fg.g * delta_time, 0, 255));
                particle.cell.fg.rgb.b = @intFromFloat(clamp(@as(f32, @floatFromInt(particle.cell.fg.rgb.b)) + particle.delta_color_fg.b * delta_time, 0, 255));
            }
            if (particle.cell.bg != .none) {
                particle.cell.bg.rgb.r = @intFromFloat(clamp(@as(f32, @floatFromInt(particle.cell.bg.rgb.r)) + particle.delta_color_bg.r * delta_time, 0, 255));
                particle.cell.bg.rgb.g = @intFromFloat(clamp(@as(f32, @floatFromInt(particle.cell.bg.rgb.g)) + particle.delta_color_bg.g * delta_time, 0, 255));
                particle.cell.bg.rgb.b = @intFromFloat(clamp(@as(f32, @floatFromInt(particle.cell.bg.rgb.b)) + particle.delta_color_bg.b * delta_time, 0, 255));
            }
        }

        fn setParticleColor(self: *ParticleEmitter(amount), particle: *Particle) void {
            if (self.config.fg_color) |color| {
                var start_fg: RgbColor = undefined;
                {
                    const r: u8 = @intCast(clamp(@as(i16, @intCast(color.start.r)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    const g: u8 = @intCast(clamp(@as(i16, @intCast(color.start.g)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    const b: u8 = @intCast(clamp(@as(i16, @intCast(color.start.b)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    start_fg = .{ .r = r, .g = g, .b = b };
                }

                var end_fg: RgbColor = undefined;
                {
                    const r: u8 = @intCast(clamp(@as(i16, @intCast(color.end.r)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    const g: u8 = @intCast(clamp(@as(i16, @intCast(color.end.g)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    const b: u8 = @intCast(clamp(@as(i16, @intCast(color.end.b)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    end_fg = .{ .r = r, .g = g, .b = b };
                }

                particle.cell.fg = .{ .rgb = start_fg };
                const r = @as(f32, @floatFromInt(end_fg.r)) - @as(f32, @floatFromInt(start_fg.r)) / particle.life;
                const g = @as(f32, @floatFromInt(end_fg.g)) - @as(f32, @floatFromInt(start_fg.g)) / particle.life;
                const b = @as(f32, @floatFromInt(end_fg.b)) - @as(f32, @floatFromInt(start_fg.b)) / particle.life;
                particle.delta_color_fg = .{ .r = r, .g = g, .b = b };
            } else {
                particle.cell.fg = .none;
            }

            if (self.config.bg_color) |color| {
                var start_bg: RgbColor = undefined;
                {
                    const r: u8 = @intCast(clamp(@as(i16, @intCast(color.start.r)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    const g: u8 = @intCast(clamp(@as(i16, @intCast(color.start.g)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    const b: u8 = @intCast(clamp(@as(i16, @intCast(color.start.b)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    start_bg = .{ .r = r, .g = g, .b = b };
                }

                var end_bg: RgbColor = undefined;
                {
                    const r: u8 = @intCast(clamp(@as(i16, @intCast(color.end.r)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    const g: u8 = @intCast(clamp(@as(i16, @intCast(color.end.g)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    const b: u8 = @intCast(clamp(@as(i16, @intCast(color.end.b)) + @as(i16, @intCast(self.config.color_var)) * randomRange(i16, -1, 1), 0, 255));
                    end_bg = .{ .r = r, .g = g, .b = b };
                }

                particle.cell.bg = .{ .rgb = start_bg };
                const r = @as(f32, @floatFromInt(end_bg.r)) - @as(f32, @floatFromInt(start_bg.r)) / particle.life;
                const g = @as(f32, @floatFromInt(end_bg.g)) - @as(f32, @floatFromInt(start_bg.g)) / particle.life;
                const b = @as(f32, @floatFromInt(end_bg.b)) - @as(f32, @floatFromInt(start_bg.b)) / particle.life;
                particle.delta_color_bg = .{ .r = r, .g = g, .b = b };
            } else {
                particle.cell.bg = .none;
            }
        }
    };
}

pub const ColorRange = struct {
    start: RgbColor,
    end: RgbColor,
};

pub const ParticleConfig = struct {
    pos: Vec2,
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

const Particle = struct {
    cell: Cell,
    delta_color_fg: struct {
        r: f32,
        g: f32,
        b: f32,
    },
    delta_color_bg: struct {
        r: f32,
        g: f32,
        b: f32,
    },
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
