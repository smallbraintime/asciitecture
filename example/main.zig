const std = @import("std");
const at = @import("asciitecture");
const Color = at.termBackend.Color;
const Attribute = at.termBackend.Attribute;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var term = try at.Terminal.init(gpa.allocator());
    defer term.deinit();

    var line = at.Line{
        .start = at.Vec2{ .x = 0, .y = 0 },
        .end = at.Vec2{ .x = term.buffer.width, .y = 0 },
        .style = at.Cell{ .char = " ", .fg = Color.white, .bg = Color.red, .attr = Attribute.reset },
    };

    var rectangle = at.Rectangle{
        .pos = at.Vec2{ .x = 10, .y = 10 },
        .width = 10,
        .height = 10,
        .style = at.Cell{
            .fg = .red,
            .bg = .cyan,
            .char = " ",
            .attr = Attribute.reset,
        },
        .filled = false,
    };

    // const circle = at.Circle{
    //     .pos = at.Vec2{ .x = 10, .y = 20 },
    //     .style = at.Cell{ .fg = .blue, .bg = .green, .char = '*', .attr = .normal },
    //     .radius = 5,
    //     .filled = false,
    // };

    var triangle = at.Triangle{
        .style = at.Cell{ .char = " ", .fg = .yellow, .bg = .yellow, .attr = Attribute.reset },
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
        .attr = Attribute.reset,
        .pos = .{ .x = 30, .y = term.buffer.height },
        .content = "Goodbye, world!",
    };

    var toggle = false;

    const running = true;
    while (running) {
        // std.time.sleep(50000000);

        line.render(&term.buffer);
        try rectangle.render(&term.buffer);
        // try circle.render(&term.buffer);
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

// const std = @import("std");
// const at = @import("asciitecture");
// const termBackend = at.termBackend;
// const TerminalBackend = termBackend.TerminalBackend;
// const Color = termBackend.Color;
//
// pub fn main() !void {
//     var term = try TerminalBackend.init();
//     try term.newScreen();
//     try term.rawMode();
//
//     try term.setCursor(5, 5);
//     try term.hideCursor();
//     try term.setFg(Color.green);
//     try term.setBg(Color.red);
//     try term.putChar("■");
//     try term.setFg(Color.cyan);
//     try term.setBg(Color.magenta);
//     try term.putChar("■");
//     _ = try term.screenSize();
//
//     // const c = try term.keyPoll();
//     // try term.setFgRgb(50, 50, 50);
//     // try term.setBgRgb(100, 100, 100);
//     // try std.io.getStdOut().writer().print("{s}", .{try c.fmt()});
//     std.time.sleep(1000000000);
//
//     try term.showCursor();
//     try term.normalMode();
//     try term.endScreen();
// }
