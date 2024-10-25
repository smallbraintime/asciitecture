const std = @import("std");
const at = @import("asciitecture");
const graphics = at.graphics;
const input = at.input;
const LinuxTty = at.LinuxTty;
const Input = input.Input;
const Key = input.Key;
const vec2 = at.math.vec2;

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
    var is_falling = false;
    var start_jump = false;

    const image =
        \\  XXX  
        \\  XXX  
        \\   X   
        \\XXXXXXX
        \\   X   
        \\  X X  
        \\ X   X 
        \\X     X
    ;

    while (true) {
        graphics.drawParticles(&term.screen, &vec2(-70, 15), 7, 7, 15, &.{ .char = '●', .fg = .{ .indexed = .black }, .bg = .{ .indexed = .default }, .attr = null });

        graphics.spriteFromStr(image).draw(&term.screen, &vec2(0, 27), 0, .none, .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } }, .{ .indexed = .default });

        graphics.drawLine(&term.screen, &vec2(50.0, 20.0), &vec2(-50.0, 20.0), &.{ .char = ' ', .fg = .{ .indexed = .default }, .bg = .{ .indexed = .red }, .attr = null });

        graphics.drawCubicSpline(&term.screen, &vec2(0, 0), &vec2(10, 50), &vec2(50, -30), &vec2(100, 25), &.{ .char = '●', .fg = .{ .rgb = .{ .r = 250, .g = 157, .b = 0 } }, .bg = .{ .indexed = .default }, .attr = null });

        graphics.drawRectangle(&term.screen, 10, 10, &vec2(rect_posx, 0.0), 45, &.{ .char = ' ', .fg = .{ .indexed = .default }, .bg = .{ .indexed = .cyan }, .attr = null }, false);

        graphics.drawPrettyRectangle(&term.screen, 10, 10, &vec2(-30.0, -5.0), .plain, .{ .indexed = .black });
        graphics.drawPrettyRectangle(&term.screen, 10, 10, &vec2(-20.0, -5.0), .thick, .{ .indexed = .black });
        graphics.drawPrettyRectangle(&term.screen, 10, 10, &vec2(-10.0, -5.0), .rounded, .{ .indexed = .black });
        graphics.drawPrettyRectangle(&term.screen, 10, 10, &vec2(0.0, -5.0), .double_line, .{ .indexed = .black });

        graphics.drawTriangle(&term.screen, .{ &vec2(100.0, 15.0), &vec2(80.0, 40.0), &vec2(120.0, 40.0) }, 0, &.{ .char = '●', .fg = .{ .indexed = .yellow }, .bg = .{ .indexed = .default }, .attr = null }, false);

        graphics.drawCircle(&term.screen, &vec2(-35.0, 2.0), 15, &.{ .char = '●', .fg = .{ .indexed = .magenta }, .bg = .{ .indexed = .default }, .attr = null }, false);

        graphics.drawText(&term.screen, "Goodbye, World!", &text_pos, .{ .indexed = .green }, .{ .indexed = .black }, null);

        term.screen.writeCell(3, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(4, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(5, 5, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(6, 5, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(5, 3, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(6, 3, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(7, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });
        term.screen.writeCell(8, 4, &.{ .bg = .{ .indexed = .black }, .fg = .{ .indexed = .default }, .char = ' ', .attr = null });

        graphics.drawLine(&term.screen, &view_pos, &vec2(view_pos.x(), view_pos.y() + 2), &.{ .char = ' ', .fg = .{ .indexed = .black }, .bg = .{ .indexed = .black }, .attr = null });
        term.screen.writeCellF(view_pos.x(), view_pos.y() - 1, &.{ .fg = .{ .indexed = .magenta }, .bg = .{ .indexed = .default }, .attr = null, .char = '@' });

        var buf1: [100]u8 = undefined;
        const delta_time = try std.fmt.bufPrint(&buf1, "delta_time:{d:.20}", .{term.delta_time});
        graphics.drawText(&term.screen, delta_time, &vec2(-20.0, 22.0), .{ .indexed = .white }, .{ .indexed = .black }, null);

        var buf2: [100]u8 = undefined;
        const fps = try std.fmt.bufPrint(&buf2, "fps:{d:.2}", .{term.fps});
        graphics.drawText(&term.screen, fps, &vec2(-20.0, 23.0), .{ .indexed = .white }, .{ .indexed = .black }, null);

        // const rot1 = vec2(50.0, 20.0).rotate(90, &vec2(0, 0));
        // const rot2 = vec2(-50.0, -20.0).rotate(90, &vec2(0, 0));

        // var buf3: [100]u8 = undefined;
        // const rot = try std.fmt.bufPrint(&buf3, "rot:{} {}", .{ rot1, rot2 });
        // graphics.drawText(&term.screen, rot, &vec2(-20.0, -16.0), .{ .indexed = .white }, .{ .indexed = .black }, null);

        // graphics.drawLine(&term.screen, &rot1, &rot2, &.{ .char = ' ', .fg = .{ .indexed = .default }, .bg = .{ .indexed = .green }, .attr = null });
        // graphics.drawLine(&term.screen, &vec2(-20.0, 50.0), &vec2(20.0, -50.0), &.{ .char = ' ', .fg = .{ .indexed = .default }, .bg = .{ .indexed = .green }, .attr = null });

        try term.draw();

        term.screen.setView(&view_pos);
        rect_posx += rect_speed;
        text_pos = text_pos.add(&text_speed);
        if (view_pos.y() <= max_jump) {
            is_falling = true;
            start_jump = false;
        }
        if (view_pos.y() == 17) {
            is_falling = false;
        }
        if (is_falling) {
            view_pos = view_pos.add(&vec2(0, 0.5));
            start_jump = false;
        }
        if (start_jump) {
            view_pos = view_pos.add(&vec2(0, -0.5));
        }

        const width: f32 = @floatFromInt(term.screen.ref_size.cols);
        const height: f32 = @floatFromInt(term.screen.ref_size.rows);
        if (text_pos.x() >= (width / 2) - 14.0 or text_pos.x() <= (-width / 2) + 1.0) text_speed = text_speed.mul(&vec2(-1.0, 1.0));
        if (text_pos.y() >= height / 2 or text_pos.y() <= (-height / 2) + 1.0) text_speed = text_speed.mul(&vec2(1.0, -1.0));
        if (rect_posx == 60) rect_speed *= -1.0;
        if (rect_posx == 0) rect_speed *= -1.0;

        const kevent = event.nextEvent();
        switch (kevent) {
            .press => |*kinput| {
                if (kinput.eql(&.{ .key = 'w' })) {
                    start_jump = true;
                }
                if (kinput.eql(&.{ .key = 'd' })) {
                    view_direction = 1;
                    view_is_moving = true;
                }
                if (kinput.eql(&.{ .key = 'a' })) {
                    view_direction = -1;
                    view_is_moving = true;
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
    }
}
