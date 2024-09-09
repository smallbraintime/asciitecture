const std = @import("std");
const at = @import("asciitecture");
const graphics = at.graphics;
const vec2 = at.math.vec2;
const Tty = at.Tty;
const Input = at.Input;
const Key = at.Key;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator(), Tty, 75, 1);
    defer term.deinit();

    var rect_posx: f32 = 0;
    var rect_speed: f32 = 1;
    var text_pos = vec2(0, 0);
    var text_speed = vec2(1, 1);
    var view_pos = vec2(0, 0);

    var textpos2 = vec2(0, 0);

    const max_jump: f32 = 0;
    var player_y: f32 = 17;
    var is_falling = false;
    var start_jump = false;

    while (true) {
        graphics.drawLine(&term.screen, &vec2(50.0, 20.0), &vec2(-50.0, 20.0), &.{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .red }, .attr = .reset });

        graphics.drawRectangle(&term.screen, 10, 10, &vec2(rect_posx, 0.0), 0, &.{ .char = ' ', .fg = .{ .indexed = .red }, .bg = .{ .indexed = .cyan }, .attr = .reset }, false);

        graphics.drawTriangle(&term.screen, .{ &vec2(100.0, 15.0), &vec2(80.0, 40.0), &vec2(120.0, 40.0) }, 0, &.{ .char = '●', .fg = .{ .indexed = .yellow }, .bg = .{ .indexed = .default }, .attr = .reset }, false);

        graphics.drawText(&term.screen, "Goodbye, World!", &text_pos, .{ .indexed = .green }, .{ .indexed = .black }, .reset);

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

        graphics.drawLine(&term.screen, &vec2(view_pos.x(), player_y), &vec2(view_pos.x(), player_y + 2), &.{ .char = ' ', .fg = .{ .indexed = .black }, .bg = .{ .indexed = .black }, .attr = .reset });
        term.screen.writeCellF(view_pos.x(), player_y - 1, &.{ .fg = .{ .indexed = .magenta }, .bg = .{ .indexed = .default }, .attr = .reset, .char = '@' });
        term.screen.setView(&view_pos);
        rect_posx += rect_speed;
        text_pos = text_pos.add(&text_speed);
        if (player_y <= max_jump) {
            is_falling = true;
            start_jump = false;
        }
        if (player_y == 17) {
            is_falling = false;
        }
        if (is_falling) {
            player_y = vec2(0, player_y).add(&vec2(0, 0.5)).y();
            start_jump = false;
        }
        if (start_jump) {
            player_y = vec2(0, player_y).add(&vec2(0, -1)).y();
        }

        const width: f32 = @floatFromInt(term.screen.refSize.width);
        const height: f32 = @floatFromInt(term.screen.refSize.height);
        if (text_pos.x() >= (width / 2) - 14.0 or text_pos.x() <= (-width / 2) + 1.0) text_speed = text_speed.mul(&vec2(-1.0, 1.0));
        if (text_pos.y() >= height / 2 or text_pos.y() <= (-height / 2) + 1.0) text_speed = text_speed.mul(&vec2(1.0, -1.0));
        if (rect_posx == 60) rect_speed *= -1.0;
        if (rect_posx == 0) rect_speed *= -1.0;

        const input = try term.backend.getInput();
        if (input.eql(&Input{ .key = Key.up })) {
            // textpos2 = textpos2.add(&vec2(0, -1));
            start_jump = true;
        }
        if (input.eql(&Input{ .key = Key.down })) {
            // textpos2 = textpos2.add(&vec2(0, 1));
        }
        if (input.eql(&Input{ .key = Key.right })) {
            // textpos2 = textpos2.add(&vec2(1, 0));
            view_pos = view_pos.add(&vec2(1, 0));
        }
        if (input.eql(&Input{ .key = Key.left })) {
            // textpos2 = textpos2.add(&vec2(-1, 0));
            view_pos = view_pos.add(&vec2(-1, 0));
        }
        if (input.eql(&Input{ .key = Key.space })) {
            graphics.drawText(&term.screen, "something", &vec2(-20, -17), .{ .indexed = .white }, .{ .indexed = .black }, .reset);
        }
        if (input.eql(&Input{ .key = 'q' })) break;
        var b: [100]u8 = undefined;
        var uni: [20]u8 = undefined;
        _ = try std.unicode.utf8Encode(input.key, &uni);
        const in = try std.fmt.bufPrint(&b, "input: {s}", .{uni});
        graphics.drawText(&term.screen, in, &textpos2, .{ .indexed = .white }, .{ .indexed = .black }, .reset);
    }
}
