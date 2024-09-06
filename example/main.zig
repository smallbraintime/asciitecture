const std = @import("std");
const at = @import("asciitecture");
const graphics = at.graphics;
const vec2 = at.math.vec2;
const TerminalBackend = at.TerminalBackend;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator(), TerminalBackend, 75, 1);
    defer term.deinit();

    var rectLocationX: f32 = 0;
    var rectSpeedX: f32 = 1;
    var textPosition = vec2(0, 0);
    var textSpeed = vec2(1, 1);
    // var viewPos = vec2(0, 0);
    // var viewSpeedX: f32 = 1;

    while (true) {
        graphics.drawLine(&term.screen, &vec2(20.0, 20.0), &vec2(0.0, 0.0), &.{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .red }, .attr = .reset });

        graphics.drawRectangle(&term.screen, 10, 10, &vec2(rectLocationX, 0.0), 0, &.{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .cyan }, .attr = .reset }, false, false);

        graphics.drawTriangle(&term.screen, .{ &vec2(100.0, 15.0), &vec2(80.0, 40.0), &vec2(120.0, 40.0) }, 0, &.{ .char = '●', .fg = .{ .indexed = .yellow }, .bg = .{ .indexed = .default }, .attr = .reset }, false);

        graphics.drawText(&term.screen, "Goodbye, World!", &textPosition, .{ .indexed = .green }, .{ .indexed = .black }, .reset);

        term.screen.writeCell(3, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(4, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(5, 5, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(6, 5, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(5, 3, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(6, 3, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(7, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });
        term.screen.writeCell(8, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = .reset });

        var buf1: [100]u8 = undefined;
        const deltaTime = try std.fmt.bufPrint(&buf1, "deltaTime:{d:.20}", .{term.deltaTime});
        graphics.drawText(&term.screen, deltaTime, &vec2(-20.0, -20.0), .{ .indexed = .white }, .{ .indexed = .black }, .reset);

        var buf2: [100]u8 = undefined;
        const fps = try std.fmt.bufPrint(&buf2, "fps:{d:.2}", .{term.fps});
        graphics.drawText(&term.screen, fps, &vec2(-20.0, -19.0), .{ .indexed = .white }, .{ .indexed = .black }, .reset);

        try term.draw();

        // term.screen.setView(&viewPos);
        // viewPos = viewPos.add(&vec2(1 * viewSpeedX, 0));
        rectLocationX += rectSpeedX;
        textPosition = textPosition.add(&textSpeed);

        const width: f32 = @floatFromInt(term.screen.refSize.width);
        const height: f32 = @floatFromInt(term.screen.refSize.height);
        if (textPosition.x() >= (width / 2) - 14.0 or textPosition.x() <= (-width / 2) + 1.0) textSpeed = textSpeed.mul(&vec2(-1.0, 1.0));
        if (textPosition.y() >= height / 2 or textPosition.y() <= (-height / 2) + 1.0) textSpeed = textSpeed.mul(&vec2(1.0, -1.0));
        if (rectLocationX == 60) rectSpeedX *= -1.0;
        if (rectLocationX == 0) rectSpeedX *= -1.0;
        // if (viewPos.x() == 20) viewSpeedX *= -1.0;
        // if (viewPos.x() == -20) viewSpeedX *= -1.0;
    }
}
