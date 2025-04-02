const std = @import("std");
const style_ = @import("style.zig");
const Painter = @import("Painter.zig");
const Vec2 = @import("math.zig").Vec2;
const Color = style_.Color;
const Style = style_.Style;

pub fn spriteFromStr(str: []const u8, style: Style) Sprite {
    return Sprite.init(str, style);
}

pub const Sprite = struct {
    image: []const u8,
    style: Style,

    pub fn init(str: []const u8, style: Style) Sprite {
        return .{ .image = str, .style = style };
    }

    pub fn draw(self: *const Sprite, painter: *Painter, pos: *const Vec2) !void {
        var x: f32 = 0.0;
        var y: f32 = 0.0;
        const view = try std.unicode.Utf8View.init(self.image);
        var iter = view.iterator();
        painter.setCell(&self.style.cell());
        while (iter.nextCodepoint()) |cp| {
            if (cp != ' ' and cp != '\n') {
                painter.cell.char = cp;
                painter.drawCell(pos.x() + x, pos.y() + y);
            }
            if (cp == '\n') {
                y += 1.0;
                x = 0.0;
            } else {
                x += 1.0;
            }
        }
    }
};

pub const Animation = struct {
    frames: std.ArrayList(*const Sprite),
    looping: bool,
    speed: f32,
    stopped: bool,
    _counter: f32,

    pub fn init(allocator: std.mem.Allocator, speed: f32, looping: bool) Animation {
        return .{
            .frames = std.ArrayList(*const Sprite).init(allocator),
            .looping = looping,
            .speed = speed,
            .stopped = false,
            ._counter = 0,
        };
    }

    pub fn deinit(self: *Animation) void {
        self.frames.deinit();
    }

    pub fn draw(
        self: *Animation,
        painter: *Painter,
        position: *const Vec2,
        delta_time: f32,
    ) !void {
        if (self.frames.items.len == 0) return;

        if (self.looping) {
            const index: usize = @intFromFloat(@round(self._counter));
            try self.frames.items[index].draw(painter, position);
            if (!self.stopped) {
                self._counter = @mod(
                    (self._counter + self.speed * delta_time),
                    @as(f32, @floatFromInt(self.frames.items.len - 1)),
                );
            }
        } else {
            const index: usize = @intFromFloat(@round(self._counter));
            if (index < self.frames.items.len) {
                try self.frames.items[index].draw(painter, position);
                if (!self.stopped) {
                    self._counter += self.speed * delta_time;
                }
            }
        }
    }

    pub fn reset(self: *Animation) void {
        self._counter = 0;
    }

    pub fn stop(self: *Animation) void {
        self.stopped = true;
    }

    pub fn play(self: *Animation) void {
        self.stopped = false;
    }
};
