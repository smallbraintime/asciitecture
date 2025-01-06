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
const Color = at.style.Color;
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

    var term = try Terminal(LinuxTty).init(gpa.allocator(), 75, .{ .rows = 35, .cols = 105 });
    defer term.deinit() catch |err| @panic(@errorName(err));
    errdefer term.deinit() catch |err| @panic(@errorName(err));

    var painter = term.painter();

    var input = try Input.init();
    defer input.deinit() catch |err| @panic(@errorName(err));
    errdefer input.deinit() catch |err| @panic(@errorName(err));

    // game state
    var player_pos = vec2(0, (35 / 2) - 4);
    var player_velocity = vec2(0, 0);
    var name: [30]u8 = undefined;
    var name_len: usize = undefined;
    var player_collider = Shape{ .rectangle = Rectangle.init(&player_pos, 3, 3) };
    var floor_collider = Shape{ .line = Line.init(&vec2(-105 / 2, (35 / 2) - 1), &vec2(105 / 2, (35 / 2) - 1)) };
    const box_collider = Shape{ .rectangle = Rectangle.init(&vec2(-30, (35 / 2) - 6), 10, 5) };
    const colliders = [_]*const Shape{ &floor_collider, &box_collider };
    const gravity = vec2(0, 1);
    var grounded = true;

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
    // const jump =
    //     \\\o/
    //     \\ |
    //     \\/ \
    // ;

    const player_style = Style{ .fg = .{ .rgb = .{ .r = 127, .g = 176, .b = 5 } } };

    var anim_right = Animation.init(gpa.allocator(), 2, true);
    defer anim_right.deinit();
    try anim_right.frames.append(&spriteFromStr(walk_right, &player_style));
    try anim_right.frames.append(&spriteFromStr(walk_right2, &player_style));
    try anim_right.frames.append(&spriteFromStr(walk_right3, &player_style));

    var anim_left = Animation.init(gpa.allocator(), 2, true);
    defer anim_left.deinit();
    try anim_left.frames.append(&spriteFromStr(walk_left, &player_style));
    try anim_left.frames.append(&spriteFromStr(walk_left2, &player_style));
    try anim_left.frames.append(&spriteFromStr(walk_left3, &player_style));

    const idle_sprite = spriteFromStr(idle, &player_style);

    var paragraph = try Paragraph.init(gpa.allocator(), &[_][]const u8{"ASCIItecture"}, &.{
        .border_style = .{
            .border = .rounded,
            .style = .{
                .fg = .{ .indexed = .cyan },
                .attr = .bold,
            },
        },
        .text_style = .{
            .fg = .{ .indexed = .magenta },
            .attr = .bold,
        },
        .filling = false,
        .animation = .{
            .speed = 5,
            .looping = true,
        },
    });
    defer paragraph.deinit();

    var emmiter = try ParticleEmitter.init(gpa.allocator(), &.{
        .pos = vec2(18, (35 / 2) - 2),
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

    // menu list
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

    // text area
    {
        var text_entered = false;
        var color = Color{ .indexed = .magenta };
        var text_area = try TextArea.init(gpa.allocator(), &.{
            .width = 20,
            .text_style = .{ .fg = color, .attr = .bold },
            .cursor_style = .{ .indexed = .green },
            .border = .plain,
            .border_style = .{ .fg = color, .attr = .bold },
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
            text_area.draw(&painter, &vec2(-10, 0));
            try term.draw();
            if (input.nextEvent()) |key| {
                switch (key.key) {
                    .enter => {
                        const buffer = text_area.buffer();
                        name_len = buffer.len;
                        if (name_len < name.len) {
                            @memcpy(name[0..name_len], buffer);
                            text_entered = true;
                        }
                    },
                    .escape => return,
                    else => try text_area.input(&key),
                }
            }
            if (text_area.buffer().len > 31) {
                color = .{ .indexed = .red };
            } else {
                color = .{ .indexed = .magenta };
            }
            text_area.config.text_style.fg = color;
            text_area.config.border_style.fg = color;
        }
    }

    player_pos.v[1] -= 1;

    // main loop
    while (true) {
        // input handling
        {
            if (input.contains(.a)) {
                player_velocity.v[0] = -20;
            } else if (input.contains(.d)) {
                player_velocity.v[0] = 20;
            } else {
                player_velocity.v[0] = 0;
            }
            if (input.contains(.escape)) {
                break;
            }
        }

        // update game state
        {
            for (&colliders) |collider| {
                switch (collider.*) {
                    .line => {
                        if (player_collider.rectangle.collidesWith(collider)) {
                            player_velocity.v[1] = 0;
                            grounded = true;
                        } else {
                            grounded = false;
                        }
                    },
                    .rectangle => {
                        if (player_collider.rectangle.collidesWith(collider)) {
                            player_velocity.v[0] = 0;
                            if (player_velocity.x() > 0) {
                                player_pos.v[0] -= 0.033;
                            } else {
                                player_pos.v[0] += 0.033;
                            }
                        }
                    },
                    else => {},
                }
            }

            term.setViewPos(&player_pos.add(&vec2(0, (-35 / 2) + 4)));
            player_collider.rectangle.pos = player_pos;
            floor_collider.line.p1 = vec2(player_pos.x(), floor_collider.line.p1.y()).add(&vec2(-105 / 2, 0));
            floor_collider.line.p2 = vec2(player_pos.x(), floor_collider.line.p2.y()).add(&vec2(105 / 2, 0));
            player_velocity.v[1] = gravity.y() * term.delta_time;
            player_pos = player_pos.add(&player_velocity.mul(&vec2(term.delta_time, term.delta_time)));
        }

        // drawing
        {
            // pyramide
            painter.setCell(&.{ .char = ' ', .bg = .{ .indexed = .yellow } });
            painter.drawTriangle(&vec2(-105 / 2, (35 / 2) - 1), &vec2(105 / 2, (35 / 2) - 1), &vec2(0, -4), true);

            // moon
            painter.setCell(&.{ .char = ' ', .bg = .{ .indexed = .bright_black } });
            painter.drawEllipse(&vec2(-30, -2), 7, &vec2(0, 0.5), true);

            // logo
            painter.setCell(&.{ .fg = .{ .indexed = .red } });
            paragraph.draw(&painter, &vec2(-6, 5), term.delta_time);

            // bonfire
            emmiter.draw(&painter, term.delta_time);
            painter.setCell(&.{ .bg = .{ .indexed = .bright_black } });
            painter.drawLine(&vec2(15, (35 / 2) - 2), &vec2(21, (35 / 2) - 2));

            // floor
            painter.setCell(&.{ .bg = .{ .indexed = .bright_black } });
            painter.drawLineShape(&floor_collider.line);

            // box
            painter.setCell(&.{ .bg = .{ .indexed = .bright_red } });
            painter.drawRectangleShape(&box_collider.rectangle, true);

            // player
            if (player_velocity.x() > 0) {
                anim_right.draw(&painter, &player_pos, term.delta_time);
            } else if (player_velocity.x() < 0) {
                anim_left.draw(&painter, &player_pos, term.delta_time);
            } else {
                idle_sprite.draw(&painter, &player_pos);
            }
            painter.setCell(&.{ .fg = .{ .indexed = .red }, .bg = .{ .indexed = .white } });
            painter.drawText(name[0..name_len], &player_pos.add(&vec2(-@as(f32, @floatFromInt(name_len / 2)), -2)));

            // overlay
            painter.setCell(&.{ .fg = .{ .indexed = .black }, .bg = .{ .indexed = .white } });
            var buf1: [50]u8 = undefined;
            const delta_time = try std.fmt.bufPrint(&buf1, "dt:{d:.5}", .{term.delta_time});
            var buf2: [50]u8 = undefined;
            const fps = try std.fmt.bufPrint(&buf2, "fps:{d:.2}", .{1.0 / term.delta_time});
            painter.drawText(delta_time, &player_pos.add(&vec2((105 / 2) - 10, -30)));
            painter.drawText(fps, &(vec2((105 / 2) - 10, -29).add(&player_pos)));
        }

        try term.draw();
    }
}
