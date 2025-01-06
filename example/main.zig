const std = @import("std");
const at = @import("asciitecture");
const LinuxTty = at.LinuxTty;
const Terminal = at.Terminal;
const Painter = at.Painter;
const Input = at.input.Input;
const Vec2 = at.math.Vec2;
const vec2 = at.math.vec2;
const Shape = at.math.Shape;
const ParticleEmitter = at.ParticleEmitter;
const Animation = at.sprite.Animation;
const spriteFromStr = at.sprite.spriteFromStr;
const Style = at.style.Style;
const Paragraph = at.widgets.Paragraph;
const Menu = at.widgets.Menu;
const TextArea = at.widgets.TextArea;
const Line = at.math.Line;
const Sprite = at.sprite.Sprite;
const Rectangle = at.math.Rectangle;

pub fn main() !void {
    // init
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) @panic("memory leak occured");

    var term = try Terminal(LinuxTty).init(gpa.allocator(), 75);
    defer term.deinit() catch |err| @panic(@errorName(err));
    errdefer term.deinit() catch |err| @panic(@errorName(err));

    var painter = term.painter();

    var input = try Input.init();
    defer input.deinit() catch |err| @panic(@errorName(err));
    errdefer input.deinit() catch |err| @panic(@errorName(err));

    var emmiter = try ParticleEmitter.init(gpa.allocator(), &.{
        .pos = vec2(0, 19),
        .amount = 100,
        .chars = &[_]u21{' '},
        .fg_color = null,
        .bg_color = .{
            .start = .{ .r = 190, .g = 60, .b = 30 },
            .end = .{ .r = 0, .g = 0, .b = 0 },
        },
        .color_var = 0,
        .start_angle = 30,
        .end_angle = 150,
        .life = 2,
        .life_var = 1,
        .speed = 10,
        .speed_var = 5,
        .emission_rate = 100 / 3,
        .gravity = vec2(0, 0),
        .duration = std.math.inf(f32),
    });
    defer emmiter.deinit();

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

    var anim_right = Animation.init(gpa.allocator(), 2, true);
    defer anim_right.deinit();
    try anim_right.frames.append(&spriteFromStr(walk_right, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));
    try anim_right.frames.append(&spriteFromStr(walk_right2, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));
    try anim_right.frames.append(&spriteFromStr(walk_right3, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));

    var anim_left = Animation.init(gpa.allocator(), 2, true);
    defer anim_left.deinit();
    try anim_left.frames.append(&spriteFromStr(walk_left, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));
    try anim_left.frames.append(&spriteFromStr(walk_left2, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));
    try anim_left.frames.append(&spriteFromStr(walk_left3, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }));

    var paragraph = try Paragraph.init(gpa.allocator(), &[_][]const u8{ "something", "goes", "wrong" }, &.{
        .border_style = .{
            .border = .rounded,
            .style = .{
                .fg = .{ .indexed = .blue },
            },
        },
        .text_style = .{
            .fg = .{ .rgb = .{ .r = 255, .g = 165, .b = 0 } },
        },
        .filling = false,
        .animation = .{
            .speed = 5,
            .looping = false,
        },
    });
    defer paragraph.deinit();

    // menu list segment
    {
        var list = Menu.init(gpa.allocator(), &.{
            .width = 50,
            .height = 21,
            .orientation = .vertical,
            .padding = 1,
            .border = .{
                .border = .rounded,
                .style = .{
                    .fg = .{ .indexed = .white },
                },
                .filled = false,
            },
            .element = .{
                .style = .{
                    .fg = .{ .indexed = .white },
                },
                .filled = false,
            },
            .selection = .{
                .element_style = .{
                    .fg = .{ .indexed = .red },
                },
                .text_style = .{
                    .fg = .{ .indexed = .red },
                },
                .filled = false,
            },
            .text_style = .{
                .fg = .{ .indexed = .white },
                .bg = .{ .indexed = .black },
            },
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
        var text_area = try TextArea.init(gpa.allocator(), &.{
            .width = 20,
            .text_style = .{ .fg = .{ .indexed = .red }, .attr = .bold },
            .cursor_style = .{ .indexed = .green },
            .border = .plain,
            .border_style = .{ .fg = .{ .indexed = .magenta }, .attr = .bold },
            .filled = false,
            .placeholder = .{
                .content = "Type your nickname here...",
                .style = .{
                    .fg = .{ .indexed = .bright_black },
                },
            },
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
        emmiter.draw(&painter, term.delta_time);

        painter.setCell(&.{ .fg = .{ .indexed = .red } });
        paragraph.draw(&painter, &vec2(-12, 0), term.delta_time);

        painter.setCell(&.{ .bg = .{ .indexed = .red } });
        painter.drawLine(&vec2(100.0, 20.0), &vec2(-100.0, 20.0));

        painter.setCell(&.{ .char = '—', .fg = .{ .rgb = .{ .r = 250, .g = 157, .b = 0 } } });
        painter.drawCubicSpline(&vec2(0, 0), &vec2(10, 50), &vec2(50, -30), &vec2(100, 25));

        painter.setCell(&.{ .bg = .{ .indexed = .cyan } });
        painter.drawRectangle(10, 10, &vec2(rect_posx, 24), true);

        painter.setCell(&.{ .fg = .{ .indexed = .white } });
        painter.drawPrettyRectangle(10, 10, &vec2(0.0, -5.0), .plain, false);
        painter.setCell(&.{ .fg = .{ .indexed = .white } });
        painter.drawPrettyRectangle(10, 10, &vec2(10.0, -5.0), .thick, false);
        painter.setCell(&.{ .fg = .{ .indexed = .white } });
        painter.drawPrettyRectangle(10, 10, &vec2(20.0, -5.0), .rounded, false);
        painter.setCell(&.{ .fg = .{ .indexed = .red }, .bg = .{ .indexed = .bright_blue } });
        painter.drawPrettyRectangle(10, 10, &vec2(30.0, -5.0), .double_line, true);

        painter.setCell(&.{ .char = '#', .fg = .{ .indexed = .yellow } });
        painter.drawTriangle(&vec2(90.0, 15.0), &vec2(70.0, 40.0), &vec2(110.0, 20.0), true);

        painter.setCell(&.{ .char = ' ', .bg = .{ .indexed = .magenta } });
        painter.drawEllipse(&vec2(-50.0, 2.0), 15, &vec2(0, 0.5), true);

        painter.setCell(&.{ .bg = .{ .indexed = .bright_black } });
        painter.drawLine(&vec2(-3, 19), &vec2(3, 19));

        painter.setCell(&.{ .fg = .{ .indexed = .green } });
        painter.drawText("Goodbye, World!", &text_pos);

        painter.setCell(&.{ .fg = .{ .indexed = .bright_magenta }, .bg = .{ .indexed = .white } });
        painter.drawText(name[0..name_len], &view_pos.add(&vec2(-5, -2)));

        painter.setCell(&.{ .fg = .{ .indexed = .black }, .bg = .{ .indexed = .white } });
        var buf1: [50]u8 = undefined;
        const delta_time = try std.fmt.bufPrint(&buf1, "delta_time:{d:.20}", .{term.delta_time});
        painter.drawText(delta_time, &(vec2(-100.0, 25.0).add(&view_pos)));

        var buf2: [50]u8 = undefined;
        const fps = try std.fmt.bufPrint(&buf2, "fps:{d:.2}", .{1.0 / term.delta_time});
        painter.drawText(fps, &(vec2(-100.0, 26.0).add(&view_pos)));

        rect_posx += rect_speed;
        text_pos = text_pos.add(&text_speed.mul(&vec2(term.delta_time, term.delta_time)));
        const width: f32 = @floatFromInt(term._screen.buffer.size.cols);
        const height: f32 = @floatFromInt(term._screen.buffer.size.rows);
        if (text_pos.x() >= (width / 2) - 14.0 or text_pos.x() <= (-width / 2) + 1.0) text_speed = text_speed.mul(&vec2(-1.0, 1.0));
        if (text_pos.y() >= height / 2 or text_pos.y() <= (-height / 2) + 1.0) text_speed = text_speed.mul(&vec2(1.0, -1.0));
        if (@round(rect_posx) == 60.0 or @round(rect_posx) == 0.0) rect_speed *= -1.0;

        term._screen.setViewPos(&view_pos);
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
            spriteFromStr(jump, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }).draw(&painter, &view_pos);
        }

        if (!start_jump and (!input.contains(.d) and !input.contains(.a) and !input.contains(.lshift))) {
            spriteFromStr(idle, &.{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } }).draw(&painter, &view_pos);
        }
        if (input.contains(.d) and input.contains(.lshift)) {
            view_direction = 1;
            view_pos = view_pos.add(&vec2(view_speed * 2 * view_direction * term.delta_time, 0));
            if (!start_jump) anim_right.draw(&painter, &view_pos, term.delta_time);
        } else if (input.contains(.d)) {
            view_direction = 1;
            view_pos = view_pos.add(&vec2(view_speed * view_direction * term.delta_time, 0));
            if (!start_jump) anim_right.draw(&painter, &view_pos, term.delta_time);
        }
        if (input.contains(.a) and input.contains(.lshift)) {
            view_direction = -1;
            view_pos = view_pos.add(&vec2(view_speed * 2 * view_direction * term.delta_time, 0));
            if (!start_jump) anim_left.draw(&painter, &view_pos, term.delta_time);
        } else if (input.contains(.a)) {
            view_direction = -1;
            view_pos = view_pos.add(&vec2(view_speed * view_direction * term.delta_time, 0));
            if (!start_jump) anim_left.draw(&painter, &view_pos, term.delta_time);
        }
        if (input.contains(.space)) {
            start_jump = true;
            view_speed = 100.0;
        }
        if (input.contains(.escape)) {
            break;
        }

        try term.draw();
    }
}
