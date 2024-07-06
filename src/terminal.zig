const std = @import("std");
const curses = @cImport(@cInclude("curses.h"));
const cstdio = @cImport(@cInclude("stdio.h"));

pub const Terminal = struct {
    buffer: Buffer,

    pub fn init(allocator: std.mem.Allocator) !Terminal {
        const stdscr: *curses.WINDOW = curses.initscr();

        _ = curses.raw();
        _ = curses.noecho();
        _ = curses.keypad(stdscr, true);
        _ = curses.clearok(stdscr, true);
        _ = curses.curs_set(0);
        _ = curses.keypad(stdscr, true);
        _ = curses.start_color();
        _ = curses.nodelay(stdscr, true);
        _ = curses.refresh();

        const max_y: u32 = @intCast(curses.getmaxy(stdscr));
        const max_x: u32 = @intCast(curses.getmaxx(stdscr));

        var buf = try std.ArrayList(Cell).initCapacity(allocator, max_y * max_x);
        try buf.appendNTimes(
            .{
                .char = ' ',
                .fg = Color.black,
                .bg = Color.black,
                .attr = Attribute.normal,
            },
            max_y * max_x,
        );
        try buf.ensureTotalCapacity(max_y * max_x);

        const buffer = Buffer{
            .buf = buf,
            .height = max_y,
            .width = max_x,
        };

        return Terminal{ .buffer = buffer };
    }

    pub fn render(self: *Terminal, updateBuffer: fn (buff: *Buffer) void) void {
        updateBuffer();
        self.draw();
    }

    pub fn draw(self: *Terminal) void {
        const buf = &self.buffer;
        for (0..buf.height) |y| {
            for (0..buf.width) |x| {
                const cell = buf.buf.items[y * buf.width + x];
                const char = cell.char;
                const fg = colorToCurses(cell.fg);
                const bg = colorToCurses(cell.bg);
                const attr = attrToCurses(cell.attr);
                const pairIndex: c_short = @intCast(fg | bg);

                _ = curses.init_pair(pairIndex, @intCast(fg), @intCast(bg));
                _ = curses.attron(@intCast(attr));
                _ = curses.mvaddch(@intCast(y), @intCast(x), @intCast(char | curses.COLOR_PAIR(pairIndex)));
                _ = curses.free_pair(curses.COLOR_PAIR(pairIndex));
                // _ = curses.attroff(@intCast(attr));
            }
        }

        _ = curses.refresh();
        self.buffer.clear();
    }

    pub fn deinit(self: *Terminal) void {
        self.buffer.buf.deinit();
        _ = curses.endwin();
    }
};

pub const Buffer = struct {
    buf: std.ArrayList(Cell),
    height: u32,
    width: u32,

    pub fn setCell(self: *Buffer, x: u32, y: u32, style: Cell) void {
        if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
            self.buf.items[y * self.width + x] = style;
        }
    }

    pub fn getCell(self: *Buffer, x: u32, y: u32) Cell {
        if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
            return self.buf.items[y * self.width + x];
        } else {
            unreachable;
        }
    }

    pub fn clear(self: *Buffer) void {
        @memset(self.buf.items, Cell{
            .char = ' ',
            .fg = Color.black,
            .bg = Color.black,
            .attr = Attribute.normal,
        });
    }
};

pub const Cell = struct { char: u8, fg: Color, bg: Color, attr: Attribute };

pub const Color = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
};

pub const Attribute = enum {
    normal,
    standout,
    underline,
    reverse,
    blink,
    dim,
    bold,
    protect,
    invis,
    altcharset,
    italic,
};

fn colorToCurses(color: Color) u32 {
    switch (color) {
        Color.black => return curses.COLOR_BLACK,
        Color.red => return curses.COLOR_RED,
        Color.green => return curses.COLOR_GREEN,
        Color.yellow => return curses.COLOR_YELLOW,
        Color.blue => return curses.COLOR_BLUE,
        Color.magenta => return curses.COLOR_MAGENTA,
        Color.cyan => return curses.COLOR_CYAN,
        Color.white => return curses.COLOR_WHITE,
    }
}

fn attrToCurses(mod: Attribute) u32 {
    switch (mod) {
        Attribute.normal => return curses.A_NORMAL,
        Attribute.standout => return curses.A_STANDOUT,
        Attribute.underline => return curses.A_UNDERLINE,
        Attribute.reverse => return curses.A_REVERSE,
        Attribute.blink => return curses.A_BLINK,
        Attribute.dim => return curses.A_BLINK,
        Attribute.bold => return curses.A_BOLD,
        Attribute.protect => return curses.A_PROTECT,
        Attribute.invis => return curses.A_INVIS,
        Attribute.altcharset => return curses.A_ALTCHARSET,
        Attribute.italic => return curses.A_ITALIC,
    }
}
