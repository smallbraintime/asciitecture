const std = @import("std");
const at = @import("asciitecture");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var term = at.Terminal.init(allocator);

    var line = at.Line{
        .start = at.Vec2{ .x = 0, .y = 0 },
        .end = at.Vec2{ .x = 5, .y = 0 },
        .style = at.Cell{ .char = '*', .fg = at.Color.white, .bg = at.Color.black, .attr = at.Attribute.normal },
    };

    while (true) {
        line.render(&term.buffer);
    }
}
