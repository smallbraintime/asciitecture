const std = @import("std");
const at = @import("asciitecture");
const Color = at.Color;
const Attributes = at.Attributes;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator());
    defer term.deinit();

    var line = at.Line{
        .start = at.Vec2{ .x = 0, .y = 0 },
        .end = at.Vec2{ .x = term.buffer.width, .y = 0 },
        .style = at.Cell{ .char = ' ', .fg = Color.white, .bg = Color.red, .attr = Attributes.reset },
    };

    var rectangle = at.Rectangle{
        .pos = at.Vec2{ .x = 10, .y = 10 },
        .width = 10,
        .height = 10,
        .style = at.Cell{
            .fg = .red,
            .bg = .cyan,
            .char = ' ',
            .attr = Attributes.reset,
        },
        .filled = false,
    };

    var triangle = at.Triangle{
        .style = at.Cell{ .char = ' ', .fg = .yellow, .bg = .yellow, .attr = Attributes.reset },
        .verticies = .{
            at.Vec2{ .x = 10, .y = 80 },
            at.Vec2{ .x = 0, .y = 100 },
            at.Vec2{ .x = 20, .y = 100 },
        },
        .filled = false,
    };

    var text = at.Text{
        .fg = .magenta,
        .bg = .black,
        .attr = Attributes.reset,
        .pos = .{ .x = 30, .y = term.buffer.height },
        .content = "Goodbye, world!",
    };

    var toggle = false;

    const running = true;
    while (running) {
        // std.time.sleep(50000000);

        line.render(&term.buffer);
        try rectangle.render(&term.buffer);
        try triangle.render(&term.buffer);
        text.render(&term.buffer);
        try term.draw();

        if (!toggle) {
            rectangle.pos.x += 1;
        } else {
            rectangle.pos.x -= 1;
        }

        if (!toggle) {
            line.end.y += 1;
        } else {
            line.end.y -= 1;
        }

        if (triangle.verticies[0].y != 0) {
            triangle.verticies[0].y -= 1;

            triangle.verticies[1].y -= 1;

            triangle.verticies[2].y -= 1;
        }

        if (!toggle) {
            text.pos.y -= 1;
        } else {
            text.pos.y += 1;
        }

        if (rectangle.pos.x == term.buffer.width or text.pos.y == term.buffer.height or text.pos.y == 0 or rectangle.pos.x == 0) {
            toggle = !toggle;
        }
    }
}
