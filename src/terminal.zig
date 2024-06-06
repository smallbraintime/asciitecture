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

        const buf = try allocator.alloc(Cell, @intCast(max_y * max_x));
        const buffer = Buffer{ .buf = buf, .height = max_y, .width = max_x };

        return Terminal{ .buffer = buffer };
    }

    pub fn render(_: Terminal, updateBuffer: fn (buff: *Buffer) void) void {
        updateBuffer();
    }

    fn draw(self: Terminal) void {
        const buf = self.buffer;
        for (0..buf.height) |y| {
            for (0..buf.width) |x| {
                const cell = buf.buf[y * buf.width + x];
                const char = cell.char;
                const fg = colorToCurses(cell.fg);
                const bg = colorToCurses(cell.bg);
                const attr = attrToCurses(cell.mod);
                const pairIndex: c_short = y * buf.width + x;

                curses.init_pair(pairIndex, fg, bg);
                curses.attron(curses.COLOR_PAIR(pairIndex));
                curses.attron(attr);
                curses.mvaddch(y, x, char);
                curses.attroff(attr);
                curses.attroff(curses.COLOR_PAIR(pairIndex));
            }
        }
        curses.refresh();
    }

    pub fn deinit(self: Terminal, allocator: *std.mem.Allocator) void {
        allocator.free(self.buffer);
        curses.endwin();
    }
};

pub const Buffer = struct {
    buf: []Cell,
    height: usize,
    width: usize,
};

pub const Cell = struct { char: u8, fg: Color, bg: Color, mod: Attribute };

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

pub fn colorToCurses(color: Color) u16 {
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

pub fn attrToCurses(mod: Attribute) u16 {
    switch (mod) {
        Attribute.normal => curses.A_NORMAL,
        Attribute.standout => curses.A_STANDOUT,
        Attribute.underline => curses.A_UNDERLINE,
        Attribute.reverse => curses.A_REVERSE,
        Attribute.blink => curses.A_BLINK,
        Attribute.dim => curses.A_BLINK,
        Attribute.bold => curses.A_BOLD,
        Attribute.protect => curses.A_PROTECT,
        Attribute.invis => curses.A_INVIS,
        Attribute.altcharset => curses.A_ALTCHARSET,
        Attribute.italic => curses.A_ITALIC,
    }
}
