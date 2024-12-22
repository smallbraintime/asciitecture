const std = @import("std");
const at = @import("asciitecture");
const LinuxTty = at.LinuxTty;
const Input = at.input.Input;
const Key = at.input.Key;
const vec2 = at.math.vec2;
const extra = at.extra;
const widgets = at.widgets;

pub fn main() !void {
    // init
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak occured");

    var term = try at.Terminal(LinuxTty).init(gpa.allocator(), 75, 1);
    defer term.deinit() catch |err| @panic(@errorName(err));
    errdefer term.deinit() catch |err| @panic(@errorName(err));

    var painter = term.painter();

    var input = try Input.init(gpa.allocator());
    defer input.deinit() catch |err| @panic(@errorName(err));
    errdefer input.deinit() catch |err| @panic(@errorName(err));

    // game state
    var rect_posx: f32 = 0;
    var rect_speed: f32 = 0.5;
    var text_pos = vec2(0, 0);
    var text_speed = vec2(50, 50);
    var view_pos = vec2(0, 0);
    var view_direction: f32 = 1;
    var view_speed: f32 = 25;
    const max_jump: f32 = 0;
    var is_falling = false;
    var start_jump = false;
    var name: [30]u8 = undefined;
    var name_len: usize = 0;
    const idle =
        \\ o
        \\/|\
        \\/ \
    ;
    const walk_right =
        \\ o
        \\(|\
        \\/ )
    ;
    const walk_right2 =
        \\ o
        \\(|\
        \\ ) 
    ;
    const walk_right3 =
        \\ o
        \\\|(
        \\/ )
    ;
    const walk_left =
        \\ o
        \\/|)
        \\( \
    ;
    const walk_left2 =
        \\ o
        \\/|)
        \\ ( 
    ;
    const walk_left3 =
        \\ o
        \\)|/
        \\( \
    ;
    const jump =
        \\\o/
        \\ |
        \\/ \
    ;

    var anim_right = at.Animation.init(gpa.allocator());
    anim_right.setSpeed(2 * term.delta_time);
    defer anim_right.deinit();
    try anim_right.frames.append(&at.spriteFromStr(walk_right, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));
    try anim_right.frames.append(&at.spriteFromStr(walk_right2, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));
    try anim_right.frames.append(&at.spriteFromStr(walk_right3, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));

    var anim_left = at.Animation.init(gpa.allocator());
    anim_left.setSpeed(2 * term.delta_time);
    defer anim_left.deinit();
    try anim_left.frames.append(&at.spriteFromStr(walk_left, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));
    try anim_left.frames.append(&at.spriteFromStr(walk_left2, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));
    try anim_left.frames.append(&at.spriteFromStr(walk_left3, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));

    // menu list segment
    {
        var list = widgets.Menu.init(gpa.allocator(), &.{
            .width = 50,
            .height = 21,
            .orientation = .vertical,
            .padding = 1,
            .border = .{
                .border = .rounded,
                .style = .{
                    .fg = .{ .indexed = .white },
                },
            },
            .element = .{
                .style = .{
                    .fg = .{ .indexed = .white },
                },
            },
            .selection = .{
                .element_style = .{ .fg = .{ .indexed = .red } },
                .text_style = .{ .fg = .{ .indexed = .red } },
            },
            .text_style = .{ .fg = .{ .indexed = .white } },
        });
        defer list.deinit();

        try list.items.append("play");
        try list.items.append("exit");

        while (true) {
            list.draw(&painter, &vec2(-25, -12.5));
            try term.draw();
            if (input.nextEvent()) |key| {
                switch (key.key) {
                    .enter => {
                        switch (list.selected_item) {
                            0 => break,
                            1 => return,
                            else => {},
                        }
                    },
                    .escape => return,
                    .down => list.next(),
                    .up => list.previous(),
                    else => {},
                }
            }
        }
    }

    // text area segment
    {
        var text_entered = false;
        var text_area = try widgets.TextArea.init(gpa.allocator(), &.{
            .width = 10,
            .text_style = .{ .fg = .{ .indexed = .red }, .attr = .bold },
            .cursor_style = .{ .indexed = .green },
            .border = .plain,
            .border_style = .{ .fg = .{ .indexed = .magenta }, .attr = .bold },
        });
        defer text_area.deinit();

        while (!text_entered) {
            text_area.draw(&painter, &vec2(0, 0));
            try term.draw();
            if (input.nextEvent()) |key| {
                switch (key.key) {
                    .enter => {
                        const buffer = text_area.buffer();
                        name_len = buffer.len;
                        @memcpy(name[0..name_len], buffer);
                        text_entered = true;
                    },
                    .escape => return,
                    else => try text_area.input(&key),
                }
            }
        }
    }

    // main loop
    while (true) {
        // _ = extra.waveAnim(&painter, &view_pos, .{ .r = 0, .g = 0, .b = 255 });

        painter.setCell(&.{ .char = '●', .fg = .{ .indexed = .cyan } });
        painter.drawParticles(&vec2(-62, 17), 10, 5, 3);
        painter.setCell(&.{ .char = '●', .fg = .{ .indexed = .blue } });
        painter.drawParticles(&vec2(-70, 15), 15, 10, 5);
        painter.setCell(&.{ .char = '●', .fg = .{ .indexed = .red } });
        painter.drawParticles(&vec2(-75, 10), 30, 20, 2);

        painter.setCell(&.{ .bg = .{ .indexed = .red } });
        painter.drawLine(&vec2(50.0, 20.0), &vec2(-50.0, 20.0));

        painter.setCell(&.{ .char = '—', .fg = .{ .rgb = .{ .r = 250, .g = 157, .b = 0 } } });
        painter.drawCubicSpline(&vec2(0, 0), &vec2(10, 50), &vec2(50, -30), &vec2(100, 25));

        painter.setCell(&.{ .bg = .{ .indexed = .cyan } });
        painter.drawRectangle(10, 10, &vec2(rect_posx, 0.0), 0, .none);

        painter.setCell(&.{ .fg = .{ .indexed = .white } });
        painter.drawPrettyRectangle(10, 10, &vec2(-30.0, -5.0), .plain, .none);
        painter.drawPrettyRectangle(10, 10, &vec2(-20.0, -5.0), .thick, .none);
        painter.drawPrettyRectangle(10, 10, &vec2(-10.0, -5.0), .rounded, .none);
        painter.drawPrettyRectangle(10, 10, &vec2(0.0, -5.0), .double_line, .none);

        painter.setCell(&.{ .char = '●', .fg = .{ .indexed = .yellow } });
        painter.drawTriangle(&vec2(100.0, 15.0), &vec2(80.0, 40.0), &vec2(120.0, 40.0), 0, .none);

        painter.setCell(&.{ .char = '●', .fg = .{ .indexed = .magenta } });
        painter.drawCircle(&vec2(-35.0, 2.0), 15, .none);

        painter.setCell(&.{ .fg = .{ .indexed = .green } });
        painter.drawText("Goodbye, World!", &text_pos);

        painter.setCell(&.{ .fg = .{ .indexed = .bright_magenta }, .bg = .{ .indexed = .white } });
        painter.drawText(name[0..name_len], &view_pos.add(&vec2(-5, -2)));

        painter.setCell(&.{ .fg = .{ .indexed = .black }, .bg = .{ .indexed = .white } });
        var buf1: [100]u8 = undefined;
        const delta_time = try std.fmt.bufPrint(&buf1, "delta_time:{d:.20}", .{term.delta_time});
        painter.drawText(delta_time, &(vec2(-100.0, 25.0).add(&view_pos)));

        painter.setCell(&.{ .fg = .{ .indexed = .black }, .bg = .{ .indexed = .white } });
        var buf2: [100]u8 = undefined;
        const fps = try std.fmt.bufPrint(&buf2, "fps:{d:.2}", .{term.fps});
        painter.drawText(fps, &(vec2(-100.0, 26.0).add(&view_pos)));

        // const rot1 = vec2(50.0, 20.0).rotate(90, &vec2(0, 0));
        // const rot2 = vec2(-50.0, -20.0).rotate(90, &vec2(0, 0));

        // var buf3: [100]u8 = undefined;
        // const rot = try std.fmt.bufPrint(&buf3, "rot:{} {}", .{ rot1, rot2 });
        // painter.drawText(&term.screen, rot, &vec2(-20.0, -16.0), .{ .indexed = .black }, .{ .indexed = .black }, .none);

        // painter.drawLine(&term.screen, &rot1, &rot2, &.{ .char = ' ', .fg = .{ .indexed = .black }, .bg = .{ .indexed = .green }, .attr = .none });
        // painter.drawLine(&term.screen, &vec2(-20.0, 50.0), &vec2(20.0, -50.0), &.{ .char = ' ', .fg = .{ .indexed = .black }, .bg = .{ .indexed = .green }, .attr = .none });

        rect_posx += rect_speed;
        text_pos = text_pos.add(&text_speed.mul(&vec2(term.delta_time, term.delta_time)));
        const width: f32 = @floatFromInt(term.screen.ref_size.cols);
        const height: f32 = @floatFromInt(term.screen.ref_size.rows);
        if (text_pos.x() >= (width / 2) - 14.0 or text_pos.x() <= (-width / 2) + 1.0) text_speed = text_speed.mul(&vec2(-1.0, 1.0));
        if (text_pos.y() >= height / 2 or text_pos.y() <= (-height / 2) + 1.0) text_speed = text_speed.mul(&vec2(1.0, -1.0));
        if (@round(rect_posx) == 60.0 or @round(rect_posx) == 0.0) rect_speed *= -1.0;

        term.screen.setView(&view_pos);
        if (view_pos.y() <= max_jump) {
            is_falling = true;
            start_jump = false;
        }
        if (@floor(view_pos.y()) >= 17) {
            is_falling = false;
            view_speed = 25.0;
        }
        if (is_falling) {
            view_pos = view_pos.add(&vec2(0, 25.0 * term.delta_time));
            start_jump = false;
        }
        if (start_jump) {
            view_pos = view_pos.add(&vec2(0, -25.0 * term.delta_time));
            at.spriteFromStr(jump, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } }, .bg = .{ .indexed = .black } }).draw(&painter, &view_pos, 0);
        }

        if (!start_jump and (!input.contains(&.{ .key = .d }) and !input.contains(&.{ .key = .a }))) {
            at.spriteFromStr(idle, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } }, .bg = .{ .indexed = .black } }).draw(&painter, &view_pos, 0);
        }
        if (input.contains(&.{ .key = .d })) {
            view_direction = 1;
            view_pos = view_pos.add(&vec2(view_speed * view_direction * term.delta_time, 0));
            if (!start_jump) anim_right.draw(&painter, &view_pos, 0);
        }
        if (input.contains(&.{ .key = .a })) {
            view_direction = -1;
            view_pos = view_pos.add(&vec2(view_speed * view_direction * term.delta_time, 0));
            if (!start_jump) anim_left.draw(&painter, &view_pos, 0);
        }
        if (input.contains(&.{ .key = .space })) {
            start_jump = true;
            view_speed = 100.0;
        }
        if (input.contains(&.{ .key = .escape })) {
            break;
        }

        try term.draw();
    }
}
