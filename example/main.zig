const std = @import("std");
const at = @import("asciitecture");
const Color = at.Color;
const Attributes = at.Attributes;
const graphics = at.graphics;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator());
    defer term.deinit();

    var rectLocationX: u16 = 50;
    var toogleDirection = false;

    while (true) {
        std.time.sleep(5000000);

        graphics.drawLine(&term.buffer, .{ .x = 0, .y = 0 }, .{ .x = term.buffer.width, .y = term.buffer.height }, .{ .char = ' ', .fg = .red, .bg = .red, .attr = Attributes.reset });

        graphics.drawRectangle(&term.buffer, 10, 10, .{ .x = rectLocationX, .y = 10 }, 0, .{ .char = ' ', .fg = .red, .bg = .cyan, .attr = Attributes.reset }, false, false);

        graphics.drawTriangle(&term.buffer, .{ .{ .x = 10, .y = 5 }, .{ .x = 0, .y = 20 }, .{ .x = 20, .y = 20 } }, 0, .{ .char = ' ', .fg = .yellow, .bg = .yellow, .attr = Attributes.reset }, false);

        graphics.drawText(&term.buffer, .{ .x = 30, .y = 30 }, "Goodbye, World!", .magenta, .black, Attributes.reset);

        try term.draw();

        if (toogleDirection) {
            rectLocationX -= 1;
        } else {
            rectLocationX += 1;
        }

        if (rectLocationX > 100) {
            toogleDirection = true;
        } else if (rectLocationX <= 50) {
            toogleDirection = false;
        }
    }
}
