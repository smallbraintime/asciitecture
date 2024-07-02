const std = @import("std");
const at = @import("asciitecture");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator());
    defer term.deinit();

    _ = at.Line{
        .start = at.Vec2{ .x = 0, .y = 0 },
        .end = at.Vec2{ .x = 5, .y = 0 },
        .style = at.Cell{ .char = '*', .fg = at.Color.white, .bg = at.Color.black, .attr = at.Attribute.normal },
    };

    var rectangle = at.Rectangle{
        .pos = at.Vec2{ .x = 10, .y = 10 },
        .width = 10,
        .height = 10,
        .style = at.Cell{
            .fg = at.Color.white,
            .bg = at.Color.black,
            .char = '*',
            .attr = at.Attribute.normal,
        },
        .filled = false,
    };

    // line.render(&term.buffer);

    while (true) {
        try rectangle.render(&term.buffer);
        term.draw();
        rectangle.pos.x += 1;
        std.time.sleep(50000000);
    }
}
