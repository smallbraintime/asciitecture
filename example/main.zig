const std = @import("std");
const at = @import("asciitecture");
const TerminalBackend = at.TerminalBackend;
const graphics = at.graphics;
const Vec2 = graphics.Vec2;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator(), TerminalBackend, 75, 1);
    defer term.deinit();

    var rectLocationX: f32 = 0;
    var changeDirection = false;
    var textPosition = Vec2{ .x = 0, .y = 0 };
    var textSpeed = Vec2{ .x = 1, .y = 1 };

    while (true) {
        graphics.drawLine(&term.screen, .{ .x = 30, .y = 30 }, .{ .x = 0, .y = 0 }, .{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .red }, .attr = .reset });

        graphics.drawRectangle(&term.screen, 10, 10, .{ .x = rectLocationX, .y = 0 }, 0, .{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .cyan }, .attr = .reset }, false, false);

        graphics.drawTriangle(&term.screen, .{ .{ .x = 100, .y = 15 }, .{ .x = 80, .y = 40 }, .{ .x = 120, .y = 40 } }, 0, .{ .char = '●', .fg = .{ .indexed = .yellow }, .bg = .{ .indexed = .default }, .attr = .reset }, false);

        graphics.drawText(&term.screen, "Goodbye, World!", textPosition, .{ .indexed = .green }, .{ .indexed = .black }, .reset);

        term.screen.writeCell(3, 4, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(4, 4, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(5, 5, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(6, 5, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(5, 3, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(6, 3, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(7, 4, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(8, 4, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });

        var buf1: [100]u8 = undefined;
        const deltaTime = try std.fmt.bufPrint(&buf1, "deltaTime:{d:.20}", .{term.deltaTime});
        graphics.drawText(&term.screen, deltaTime, .{ .x = -20, .y = -20 }, .{ .indexed = .white }, .{ .indexed = .black }, .reset);
        var buf2: [100]u8 = undefined;
        const fps = try std.fmt.bufPrint(&buf2, "fps:{d:.2}", .{term.fps});
        graphics.drawText(&term.screen, fps, .{ .x = -20, .y = -19 }, .{ .indexed = .white }, .{ .indexed = .black }, .reset);

        try term.draw();

        if (changeDirection) {
            rectLocationX -= 1;
        } else {
            rectLocationX += 1;
        }

        if (rectLocationX > 60) {
            changeDirection = true;
        } else if (rectLocationX <= 0) {
            changeDirection = false;
        }

        textPosition.x += textSpeed.x;
        textPosition.y += textSpeed.y;

        const width: f32 = @as(f32, @floatFromInt(term.screen.size.width));
        const height: f32 = @as(f32, @floatFromInt(term.screen.size.height));
        if (textPosition.x >= (width / 2) - 14 or textPosition.x <= (-width / 2) + 1) textSpeed.x *= -1.0;
        if (textPosition.y >= height / 2 or textPosition.y <= (-height / 2) + 1) textSpeed.y *= -1.0;
    }
}
