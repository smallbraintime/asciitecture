const std = @import("std");
const Painter = @import("Painter.zig");
const Vec2 = @import("math.zig").Vec2;
const Color = @import("style.zig").Color;
const Style = @import("style.zig").Style;

pub fn spriteFromStr(str: []const u8, style: *const Style) Sprite {
    return Sprite.init(str, style);
}

pub const Sprite = struct {
    image: []const u8,
    style: Style,

    pub fn init(str: []const u8, style: *const Style) Sprite {
        return .{ .image = str, .style = style.* };
    }

    pub fn draw(self: *const Sprite, painter: *Painter, position: *const Vec2) void {
        var x: f32 = 0.0;
        var y: f32 = 0.0;

        painter.setCell(&self.style.cell());
        for (self.image) |c| {
            if (c != ' ' and c != '\n') {
                painter.cell.char = @intCast(c);
                painter.drawCell(position.x() + x, position.y() + y);
            }

            if (c == '\n') {
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
    _speed: f32,
    _counter: f32,

    pub fn init(allocator: std.mem.Allocator, speed: f32, looping: bool) Animation {
        return .{
            .frames = std.ArrayList(*const Sprite).init(allocator),
            .looping = looping,
            ._speed = speed,
            ._counter = 0,
        };
    }

    pub fn deinit(self: *Animation) void {
        self.frames.deinit();
    }

    pub fn draw(self: *Animation, painter: *Painter, position: *const Vec2) void {
        if (self.frames.items.len == 0) return;

        if (self.looping) {
            const index: usize = @intFromFloat(@round(self._counter));
            self.frames.items[index].draw(painter, position);
            self._counter = @mod((self._counter + self._speed), @as(f32, @floatFromInt(self.frames.items.len - 1)));
        } else {
            const index: usize = @intFromFloat(@round(self._counter));
            if (index < self.frames.items.len) {
                self.frames.items[index].draw(painter, position);
                self._counter += self._speed;
            }
        }
    }
};
