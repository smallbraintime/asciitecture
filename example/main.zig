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

    var rectLocationX: f32 = 120;
    var changeDirection = false;
    var textPosition = Vec2{ .x = @as(f32, @floatFromInt(term.buffer.size.width)) / 2, .y = @as(f32, @floatFromInt(term.buffer.size.height)) / 2 };
    var textSpeed = Vec2{ .x = 1, .y = 1 };

    while (true) {
        graphics.drawLine(&term.buffer, .{ .x = 0, .y = 0 }, .{ .x = @floatFromInt(term.buffer.size.width), .y = @floatFromInt(term.buffer.size.height) }, .{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .red }, .attr = .reset });

        graphics.drawRectangle(&term.buffer, 10, 10, .{ .x = rectLocationX, .y = 10 }, 0, .{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .cyan }, .attr = .reset }, false, false);

        graphics.drawTriangle(&term.buffer, .{ .{ .x = 100, .y = 15 }, .{ .x = 80, .y = 40 }, .{ .x = 120, .y = 40 } }, 0, .{ .char = '●', .fg = .{ .indexed = .yellow }, .bg = .{ .indexed = .default }, .attr = .reset }, false);

        graphics.drawText(&term.buffer, "Goodbye, World!", textPosition, .{ .indexed = .green }, .{ .indexed = .black }, .reset);

        term.buffer.writeCell(3, 4, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.buffer.writeCell(4, 4, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.buffer.writeCell(5, 5, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.buffer.writeCell(6, 5, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.buffer.writeCell(5, 3, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.buffer.writeCell(6, 3, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.buffer.writeCell(7, 4, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.buffer.writeCell(8, 4, .{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });

        var buf1: [100]u8 = undefined;
        const deltaTime = try std.fmt.bufPrint(&buf1, "deltaTime:{d:.20}", .{term.deltaTime});
        graphics.drawText(&term.buffer, deltaTime, .{ .x = 1, .y = 10 }, .{ .indexed = .white }, .{ .indexed = .black }, .reset);
        var buf2: [100]u8 = undefined;
        const fps = try std.fmt.bufPrint(&buf2, "fps:{d:.2}", .{term.fps});
        graphics.drawText(&term.buffer, fps, .{ .x = 1, .y = 11 }, .{ .indexed = .white }, .{ .indexed = .black }, .reset);

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

        textPosition.x += textSpeed.x;
        textPosition.y += textSpeed.y;

        if (term.buffer.ratio >= @as(f32, @floatFromInt(term.buffer.size.width - 14)) or textPosition.x <= 1) textSpeed.x *= -1.0;
        if (term.buffer.ratio >= @as(f32, @floatFromInt(term.buffer.size.height)) or textPosition.y <= 1) textSpeed.y *= -1.0;
    }
}
