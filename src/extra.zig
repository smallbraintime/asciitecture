const Screen = @import("Screen.zig");
const graphics = @import("graphics.zig");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const cell = @import("cell.zig");
const Cell = cell.Cell;
const RgbColor = cell.RgbColor;
const std = @import("std");

pub fn screenMeltingTransition(screen: *Screen, allocator: std.mem.Allocator) void {
    _ = screen;
    _ = allocator;
}

pub fn waveAnim(screen: *Screen, position: *const Vec2, bg: RgbColor) void {
    const counter = struct {
        var n: f32 = 1;
        var timer: u32 = 0;
    };
    if (@as(usize, @intFromFloat(counter.n)) > screen.size.cols * 2 or @as(usize, @intFromFloat(counter.n)) > screen.size.rows * 2) {
        counter.n = 1;
        counter.timer = 0;
    }
    var style = Cell{ .bg = .{ .rgb = bg }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null };
    var layer: f32 = 0;
    var brightness: u8 = 0;
    while (layer <= 24) {
        const radius = counter.n - 1;
        if (radius > 0) {
            style.bg = .{ .rgb = .{ .r = @min(bg.r + @min(brightness, 255 - bg.r), 255), .g = @min(bg.g + @min(brightness, 255 - bg.g), 255), .b = @min(bg.b + @min(brightness, 255 - bg.b), 255) } };
            graphics.drawCircle(screen, position, counter.n - layer, &style, false);
        }
        layer += 1;
        brightness += 10;
    }
    if (counter.timer % 2 == 0) {
        counter.n += 1;
    }
    counter.timer += 1;
}
