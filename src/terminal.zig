const std = @import("std");
const term = @import("terminalBackend.zig");
const TerminalBackend = term.TerminalBackend;

pub const Terminal = struct {
    buffer: Buffer,
    backend: TerminalBackend,

    pub fn init(allocator: std.mem.Allocator) !Terminal {
        var backend = try TerminalBackend.init();

        try backend.newScreen();
        try backend.rawMode();
        try backend.hideCursor();

        const screenSize = try backend.screenSize();
        const x = screenSize.x;
        const y = screenSize.y;

        var buf = try std.ArrayList(Cell).initCapacity(allocator, x * y);
        try buf.appendNTimes(
            .{
                .char = ' ',
                .fg = term.Color.default,
                .bg = term.Color.default,
                .attr = term.Attribute.reset,
            },
            y * x,
        );
        try buf.ensureTotalCapacity(y * x);

        const buffer = Buffer{
            .buf = buf,
            .height = y,
            .width = x,
        };

        return Terminal{
            .buffer = buffer,
            .backend = backend,
        };
    }

    pub fn render(self: *Terminal, updateBuffer: fn (buff: *Buffer) void) void {
        updateBuffer();
        self.draw();
    }

    pub fn draw(self: *Terminal) !void {
        const buf = &self.buffer;
        const backend = &self.backend;
        for (0..buf.height) |y| {
            for (0..buf.width) |x| {
                const cell = buf.buf.items[y * buf.width + x];
                try backend.setCursor(@intCast(x), @intCast(y));
                try backend.setFg(cell.fg);
                try backend.setBg(cell.bg);
                // try backend.setAttr(cell.attr);
                try backend.putChar(cell.char);
            }
        }

        // try backend.clearScreen();
        self.buffer.clear();
    }

    pub fn deinit(self: *Terminal) void {
        self.buffer.buf.deinit();
    }
};

pub const Buffer = struct {
    buf: std.ArrayList(Cell),
    height: u16,
    width: u16,

    pub fn setCell(self: *Buffer, x: u16, y: u16, style: Cell) void {
        if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
            self.buf.items[y * self.width + x] = style;
        }
    }

    pub fn getCell(self: *Buffer, x: u16, y: u16) Cell {
        if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
            return self.buf.items[y * self.width + x];
        } else {
            unreachable;
        }
    }

    pub fn clear(self: *Buffer) void {
        @memset(self.buf.items, Cell{
            .char = ' ',
            .fg = term.Color.default,
            .bg = term.Color.default,
            .attr = term.Attribute.reset,
        });
    }
};

pub const Cell = struct {
    char: u21,
    fg: term.Color,
    bg: term.Color,
    attr: []const u8,
};
