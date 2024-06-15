const std = @import("std");
const at = @import("asciitecture");

pub fn main() void {
    const arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const term = at.Terminal.init(allocator);

    const line = at.Line{
        .start = at.Vec2{ .x = 0, .y = 0 },
        .end = at.Vec2{ .x = 5, .y = 0 },
        .style = at.Cell{ .char = "-", .fg = at.Color.White },
    };

    while (true) {
        line.render(&term.buffer);
    }
}
