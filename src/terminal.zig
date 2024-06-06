const std = @import("std");
const curses = @cImport({
    @cInclude("curses.h");
});

pub const Terminal = struct {
    buffer: Buffer,
    pub fn init(allocator: *std.mem.Allocator) Terminal {
        const stdscr: *curses.WINDOW = curses.initscr();

        curses.raw();
        curses.newterm(null, std.stdout, std.stdin);
        curses.clearok(stdscr, true);
        curses.refresh();

        const max_y = curses.getmaxy(stdscr);
        const max_x = curses.getmaxx(stdscr);

        const buf = try allocator.alloc(CharPixel, @intCast(max_y * max_x));
        const buffer = Buffer{ .buf = buf };

        return Terminal{ .buffer = buffer };
    }
    pub fn render(self: Terminal, updateFn: fn (buff: *Buffer) void) void {
        curses.clear();
        updateFn();
    }
    pub fn deinit(self: Terminal, allocator: *std.mem.Allocator) void {
        allocator.free(self.buffer);
        curses.endwin();
    }
};

pub const Buffer = struct {
    buf: []CharPixel,
    height: usize,
    width: usize,
};

pub const CharPixel = struct { char: u8, fg_color: Color, bg_color: Color };

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};
