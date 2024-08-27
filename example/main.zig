const std = @import("std");
const at = @import("asciitecture");
const Color = at.Color;
const Attributes = at.Attributes;
const graphics = at.graphics;
const Vec2 = graphics.Vec2;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator(), 6000000);
    defer term.deinit();

    var rectLocationX: u16 = 120;
    var changeDirection = false;
    const textPath = [_]Vec2{ .{ .x = 20, .y = 30 }, .{ .x = 60, .y = 30 }, .{ .x = 60, .y = 50 }, .{ .x = 20, .y = 50 } };
    var pathIndex: u16 = 0;
    var textLocation = Vec2{ .x = textPath[0].x, .y = textPath[0].y };
    var frameDelimeter: u16 = 0;

    while (true) {
        graphics.drawLine(&term.buffer, .{ .x = 0, .y = 0 }, .{ .x = term.buffer.width, .y = term.buffer.height }, .{ .char = ' ', .fg = .red, .bg = .red, .attr = Attributes.reset });

        graphics.drawRectangle(&term.buffer, 10, 10, .{ .x = rectLocationX, .y = 10 }, 0, .{ .char = ' ', .fg = .red, .bg = .cyan, .attr = Attributes.reset }, false, false);

        graphics.drawTriangle(&term.buffer, .{ .{ .x = 100, .y = 15 }, .{ .x = 80, .y = 40 }, .{ .x = 120, .y = 40 } }, 0, .{ .char = ' ', .fg = .yellow, .bg = .yellow, .attr = Attributes.reset }, false);

        graphics.drawText(&term.buffer, textLocation, "Goodbye, World!", .white, .black, Attributes.reset);

        try term.draw();

        if (changeDirection) {
            rectLocationX -= 1;
        } else {
            rectLocationX += 1;
        }

        if (rectLocationX > 180) {
            changeDirection = true;
        } else if (rectLocationX <= 120) {
            changeDirection = false;
        }

        if (pathIndex >= textPath.len) {
            pathIndex = 0;
        }

        if (frameDelimeter >= 2) {
            frameDelimeter = 0;
            if (textLocation.x < textPath[pathIndex].x) {
                textLocation.x += 1;
            } else if (textLocation.x > textPath[pathIndex].x) {
                textLocation.x -= 1;
            } else if (textLocation.y < textPath[pathIndex].y) {
                textLocation.y += 1;
            } else if (textLocation.y > textPath[pathIndex].y) {
                textLocation.y -= 1;
            } else {
                pathIndex += 1;
            }
        }

        frameDelimeter += 1;
    }
}
