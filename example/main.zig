const std = @import("std");
const at = @import("asciitecture");
const TerminalBackend = at.TerminalBackend;
const graphics = at.graphics;
const Vec2 = graphics.Vec2;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator(), TerminalBackend, 1, 1);
    defer term.deinit();

    var rectLocationX: u16 = 120;
    var changeDirection = false;
    const textPath = [_]Vec2{ .{ .x = 20, .y = 30 }, .{ .x = 60, .y = 30 }, .{ .x = 60, .y = 50 }, .{ .x = 20, .y = 50 } };
    var pathIndex: u16 = 0;
    var textLocation = Vec2{ .x = textPath[0].x, .y = textPath[0].y };
    var frameDelimeter: u16 = 0;

    while (true) {
        graphics.drawLine(&term.buffer, .{ .x = 0, .y = 0 }, .{ .x = term.buffer.width, .y = term.buffer.height }, .{ .char = ' ', .fg = .red, .bg = .red, .attr = .reset });

        graphics.drawRectangle(&term.buffer, 10, 10, .{ .x = rectLocationX, .y = 10 }, 0, .{ .char = ' ', .fg = .red, .bg = .cyan, .attr = .reset }, false, false);

        graphics.drawTriangle(&term.buffer, .{ .{ .x = 100, .y = 15 }, .{ .x = 80, .y = 40 }, .{ .x = 120, .y = 40 } }, 0, .{ .char = ' ', .fg = .yellow, .bg = .yellow, .attr = .reset }, false);

        graphics.drawText(&term.buffer, textLocation, "Goodbye, World!", .white, .black, .reset);

        var buf1: [100]u8 = undefined;
        const deltaTime = try std.fmt.bufPrint(&buf1, "deltaTime:{}                           ", .{term.deltaTime});
        graphics.drawText(&term.buffer, .{ .x = 1, .y = 10 }, deltaTime, .white, .black, .reset);
        var buf: [100]u8 = undefined;
        const time = try std.fmt.bufPrint(&buf, "previousTime:{}", .{term.previousTime});
        graphics.drawText(&term.buffer, .{ .x = 1, .y = 11 }, time, .white, .black, .reset);
        var buf2: [100]u8 = undefined;
        const fps = try std.fmt.bufPrint(&buf2, "fps:{}", .{term.fps});
        graphics.drawText(&term.buffer, .{ .x = 1, .y = 12 }, fps, .white, .black, .reset);

        term.buffer.setCell(3, 4, .{ .bg = .black, .fg = .default, .char = ' ', .attr = .reset });
        term.buffer.setCell(4, 4, .{ .bg = .black, .fg = .default, .char = ' ', .attr = .reset });
        term.buffer.setCell(5, 5, .{ .bg = .black, .fg = .default, .char = ' ', .attr = .reset });
        term.buffer.setCell(6, 5, .{ .bg = .black, .fg = .default, .char = ' ', .attr = .reset });
        term.buffer.setCell(5, 3, .{ .bg = .black, .fg = .default, .char = ' ', .attr = .reset });
        term.buffer.setCell(6, 3, .{ .bg = .black, .fg = .default, .char = ' ', .attr = .reset });
        term.buffer.setCell(7, 4, .{ .bg = .black, .fg = .default, .char = ' ', .attr = .reset });
        term.buffer.setCell(8, 4, .{ .bg = .black, .fg = .default, .char = ' ', .attr = .reset });

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
