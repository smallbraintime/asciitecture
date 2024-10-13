const std = @import("std");
const at = @import("asciitecture");
const graphics = at.graphics;
const vec2 = at.math.vec2;
const input = at.input;
const LinuxTty = at.LinuxTty;
const Input = input.Input;
const Key = input.Key;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const result = gpa.deinit();
        if (result == .leak) {
            @panic("memory leak occured");
        }
    }

    var term = try at.Terminal(LinuxTty).init(gpa.allocator(), 75, 1);
    defer {
        term.deinit() catch |err| {
            @panic(@errorName(err));
        };
    }
    errdefer {
        term.deinit() catch |err| {
            @panic(@errorName(err));
        };
    }

    var event = try Input.init();
    defer event.deinit();

    var rect_posx: f32 = 0;
    var rect_speed: f32 = 1;
    var text_pos = vec2(0, 0);
    var text_speed = vec2(1, 1);
    var view_pos = vec2(0, 0);
    var view_direction: f32 = 1;
    var view_is_moving = false;
    const max_jump: f32 = 0;
    var player_y: f32 = 17;
    var is_falling = false;
    var start_jump = false;

    while (true) {
        graphics.drawLine(&term.screen, &vec2(50.0, 20.0), &vec2(-50.0, 20.0), &.{ .char = ' ', .fg = .{ .indexed = .default }, .bg = .{ .indexed = .red }, .attr = null });

        graphics.drawRectangle(&term.screen, 10, 10, &vec2(rect_posx, 0.0), 45, &.{ .char = ' ', .fg = .{ .indexed = .default }, .bg = .{ .indexed = .cyan }, .attr = null }, false);

        graphics.drawPrettyRectangle(&term.screen, 10, 10, &vec2(-30.0, -5.0), .plain, .{ .indexed = .black });
        graphics.drawPrettyRectangle(&term.screen, 10, 10, &vec2(-20.0, -5.0), .thick, .{ .indexed = .black });
        graphics.drawPrettyRectangle(&term.screen, 10, 10, &vec2(-10.0, -5.0), .rounded, .{ .indexed = .black });
        graphics.drawPrettyRectangle(&term.screen, 10, 10, &vec2(0.0, -5.0), .double_line, .{ .indexed = .black });

        graphics.drawTriangle(&term.screen, .{ &vec2(100.0, 15.0), &vec2(80.0, 40.0), &vec2(120.0, 40.0) }, 0, &.{ .char = '●', .fg = .{ .indexed = .yellow }, .bg = .{ .indexed = .default }, .attr = null }, false);

        graphics.drawText(&term.screen, "Goodbye, World!", &text_pos, .{ .indexed = .green }, .{ .indexed = .black }, null);

        term.screen.writeCell(3, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(4, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(5, 5, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(6, 5, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(5, 3, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(6, 3, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(7, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(8, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });

        graphics.drawLine(&term.screen, &vec2(view_pos.x(), player_y), &vec2(view_pos.x(), player_y + 2), &.{ .char = ' ', .fg = .{ .indexed = .black }, .bg = .{ .indexed = .black }, .attr = null });
        term.screen.writeCellF(view_pos.x(), player_y - 1, &.{ .fg = .{ .indexed = .magenta }, .bg = .{ .indexed = .default }, .attr = null, .char = '@' });

        var buf1: [100]u8 = undefined;
        const delta_time = try std.fmt.bufPrint(&buf1, "delta_time:{d:.20}", .{term.delta_time});
        graphics.drawText(&term.screen, delta_time, &vec2(-20.0, -20.0), .{ .indexed = .white }, .{ .indexed = .black }, null);

        var buf2: [100]u8 = undefined;
        const fps = try std.fmt.bufPrint(&buf2, "fps:{d:.2}", .{term.fps});
        graphics.drawText(&term.screen, fps, &vec2(-20.0, -19.0), .{ .indexed = .white }, .{ .indexed = .black }, null);

        const rot1 = vec2(50.0, 20.0).rotate(90, &vec2(0, 0));
        const rot2 = vec2(-50.0, -20.0).rotate(90, &vec2(0, 0));

        var buf3: [100]u8 = undefined;
        const rot = try std.fmt.bufPrint(&buf3, "rot:{} {}", .{ rot1, rot2 });
        graphics.drawText(&term.screen, rot, &vec2(-20.0, -16.0), .{ .indexed = .white }, .{ .indexed = .black }, null);

        // graphics.drawLine(&term.screen, &rot1, &rot2, &.{ .char = ' ', .fg = .{ .indexed = .default }, .bg = .{ .indexed = .green }, .attr = null });
        // graphics.drawLine(&term.screen, &vec2(-20.0, 50.0), &vec2(20.0, -50.0), &.{ .char = ' ', .fg = .{ .indexed = .default }, .bg = .{ .indexed = .green }, .attr = null });

        try term.draw();

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

        const width: f32 = @floatFromInt(term.screen.ref_size.width);
        const height: f32 = @floatFromInt(term.screen.ref_size.height);
        if (text_pos.x() >= (width / 2) - 14.0 or text_pos.x() <= (-width / 2) + 1.0) text_speed = text_speed.mul(&vec2(-1.0, 1.0));
        if (text_pos.y() >= height / 2 or text_pos.y() <= (-height / 2) + 1.0) text_speed = text_speed.mul(&vec2(1.0, -1.0));
        if (rect_posx == 60) rect_speed *= -1.0;
        if (rect_posx == 0) rect_speed *= -1.0;

        const kevent = event.nextEvent();
        switch (kevent) {
            .press => |*kinput| {
                if (kinput.eql(&.{ .key = 'w' })) {
                    // textpos2 = textpos2.add(&vec2(0, -1));
                    start_jump = true;
                }
                if (kinput.eql(&.{ .key = Key.down })) {
                    // textpos2 = textpos2.add(&vec2(0, 1));
                }
                if (kinput.eql(&.{ .key = 'd' })) {
                    // textpos2 = textpos2.add(&vec2(1, 0));
                    // view_pos = view_pos.add(&vec2(1, 0));
                    view_direction = 1;
                    view_is_moving = true;
                }
                if (kinput.eql(&.{ .key = 'a' })) {
                    // textpos2 = textpos2.add(&vec2(-1, 0));
                    // view_pos = view_pos.add(&vec2(-1, 0));
                    view_direction = -1;
                    view_is_moving = true;
                }
                if (kinput.eql(&.{ .key = Key.space })) {
                    graphics.drawText(&term.screen, "something", &vec2(-20, -17), .{ .indexed = .white }, .{ .indexed = .black }, null);
                }
                if (kinput.eql(&.{ .key = 'q' })) break;
            },
            .release => |*kinput| {
                if (kinput.eql(&.{ .key = 'd' })) {
                    view_is_moving = false;
                }
                if (kinput.eql(&.{ .key = 'a' })) {
                    view_is_moving = false;
                }
            },
        }
        if (view_is_moving) {
            view_pos = view_pos.add(&vec2(1 * view_direction, 0));
        }

        // var b: [100]u8 = undefined;
        // var uni: [20]u8 = undefined;
        // const c = try std.unicode.utf8Encode(input.key, &uni);
        // const in = try std.fmt.bufPrint(&b, "input: {s}", .{uni[0..c]});
        // graphics.drawText(&term.screen, in, &textpos2, .{ .indexed = .white }, .{ .indexed = .black }, null);
    }
}

// const input = @import("asciitecture").input;
//
// pub fn main() !void {
//     var in = input.Input.init();
//     while (true) {
//         switch (in.nextEvent()) {
//             .press => |*kevent| {
//                 var buf: [20]u8 = undefined;
//                 const n = try std.unicode.utf8Encode(kevent.key, &buf);
//                 std.debug.print("{s}", .{buf[0..n]});
//             },
//             .release => {},
//         }
//     }
// }
