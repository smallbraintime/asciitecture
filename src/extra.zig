const Screen = @import("Screen.zig");
const graphics = @import("graphics.zig");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const cell = @import("cell.zig");
const Cell = cell.Cell;
const RgbColor = cell.RgbColor;

pub fn screenMeltingTransition(screen: *Screen) void {
    _ = screen;
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
    const counter2 = counter.n - 1;
    const counter3 = counter.n - 2;
    const style = Cell{ .bg = .{ .rgb = bg }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null };
    var style2 = style;
    style2.bg = .{ .rgb = .{ .r = @min(bg.r + @min(40, 255 - bg.r), 255), .g = @min(bg.g + @min(40, 255 - bg.g), 255), .b = @min(bg.b + @min(40, 255 - bg.b), 255) } };
    var style3 = style;
    style3.bg = .{ .rgb = .{ .r = @min(bg.r + @min(80, 255 - bg.r), 255), .g = @min(bg.g + @min(80, 255 - bg.g), 255), .b = @min(bg.b + @min(80, 255 - bg.b), 255) } };
    graphics.drawCircle(screen, position, counter.n, &style, false);
    if (counter2 > 0) graphics.drawCircle(screen, position, counter2, &style2, false);
    if (counter3 > 0) graphics.drawCircle(screen, position, counter3, &style3, false);
    if (counter.timer % 2 == 0) {
        counter.n += 1;
    }
    counter.timer += 1;
}

fn checkU8() void {}
