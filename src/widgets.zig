const std = @import("std");
const graphics = @import("graphics.zig");
const Screen = @import("Screen.zig");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const cell = @import("cell.zig");
const Color = cell.Color;
const Style = cell.Style;
const KeyInput = @import("input.zig").KeyInput;

pub const List = struct {};

pub const TextArea = struct {
    area_pos: Vec2,
    width: usize,
    text_style: Style,
    cursor_style: Color,
    border: graphics.Border,
    border_style: Style,
    hidden_cursor: bool,
    _buffer: std.ArrayList(u8),
    _cursor_pos: usize,
    _viewport: struct { begin: usize, end: usize },

    pub fn init(
        allocator: std.mem.Allocator,
        config: struct {
            pos: Vec2,
            width: usize,
            text_style: Style,
            cursor_style: Color,
            border: graphics.Border,
            border_style: Style,
        },
    ) !TextArea {
        return .{
            .area_pos = config.pos,
            .width = config.width,
            .text_style = config.text_style,
            .cursor_style = config.cursor_style,
            .border = config.border,
            .border_style = config.border_style,
            .hidden_cursor = false,
            ._buffer = std.ArrayList(u8).init(allocator),
            ._cursor_pos = 0,
            ._viewport = .{ .begin = 0, .end = 0 },
        };
    }

    pub fn buffer(self: *const TextArea) []const u8 {
        return self._buffer.items;
    }

    pub fn cursorLeft(self: *TextArea) void {
        if (self._cursor_pos > 0) {
            if (self._cursor_pos == self._viewport.begin) {
                if (self._viewport.begin > 0)
                    self._viewport.begin -= 1;
                if (self._viewport.end - self._viewport.begin - 1 == self.width - 2)
                    self._viewport.end -= 1;
            }
            self._cursor_pos -= 1;
        }
    }

    pub fn cursorRight(self: *TextArea) void {
        if (self._cursor_pos < self._buffer.items.len) {
            if (self._cursor_pos == self._viewport.end - 1) {
                if (self._viewport.end >= self.width - 2)
                    self._viewport.begin += 1;
                if (self._viewport.end != self._buffer.items.len)
                    self._viewport.end += 1;
            }
            self._cursor_pos += 1;
        }
    }

    pub fn putChar(self: *TextArea, char: u8) !void {
        if (self._cursor_pos == 0 or self._cursor_pos > self._buffer.items.len)
            try self._buffer.append(char)
        else
            try self._buffer.insert(self._cursor_pos, char);
        if (self._cursor_pos == self._viewport.end) {
            if (self._viewport.end - self._viewport.begin < self.width - 2)
                self._viewport.end += 1;
            if (self._viewport.end - self._viewport.begin == self.width - 2)
                self._viewport.begin += 1;
        }
        if (self._cursor_pos < self._viewport.end) self._cursor_pos += 1;
    }

    pub fn delChar(self: *TextArea) void {
        if (self._cursor_pos > 0) {
            if (self._cursor_pos == self._viewport.begin or self._cursor_pos == self._viewport.end) {
                if (self._viewport.begin > 0)
                    self._viewport.begin -= 1;
            }
            self._viewport.end -= 1;
            self._cursor_pos -= 1;
            _ = self._buffer.orderedRemove(self._cursor_pos);
        }
    }

    pub fn hideCursor(self: *TextArea) void {
        self.cursor_hidden = true;
    }

    pub fn unhideCursor(self: *TextArea) void {
        self.cursor_hidden = false;
    }

    pub fn input(self: *TextArea, key_input: *const KeyInput) !void {
        if (key_input.mod.shift) {
            switch (key_input.key) {
                .a => try self.putChar('A'),
                .b => try self.putChar('B'),
                .c => try self.putChar('C'),
                .d => try self.putChar('D'),
                .e => try self.putChar('E'),
                .f => try self.putChar('F'),
                .g => try self.putChar('G'),
                .h => try self.putChar('H'),
                .i => try self.putChar('I'),
                .j => try self.putChar('J'),
                .k => try self.putChar('K'),
                .l => try self.putChar('L'),
                .m => try self.putChar('M'),
                .n => try self.putChar('N'),
                .o => try self.putChar('O'),
                .p => try self.putChar('P'),
                .q => try self.putChar('Q'),
                .r => try self.putChar('R'),
                .s => try self.putChar('S'),
                .t => try self.putChar('T'),
                .u => try self.putChar('U'),
                .v => try self.putChar('V'),
                .w => try self.putChar('W'),
                .x => try self.putChar('X'),
                .y => try self.putChar('Y'),
                .z => try self.putChar('Z'),
                else => {},
            }
            return;
        }
        switch (key_input.key) {
            .left => self.cursorLeft(),
            .right => self.cursorRight(),
            .backspace => self.delChar(),
            .space => try self.putChar(' '),
            .tab => for (0..3) |_| try self.putChar(' '),
            .a => try self.putChar('a'),
            .b => try self.putChar('b'),
            .c => try self.putChar('c'),
            .d => try self.putChar('d'),
            .e => try self.putChar('e'),
            .f => try self.putChar('f'),
            .g => try self.putChar('g'),
            .h => try self.putChar('h'),
            .i => try self.putChar('i'),
            .j => try self.putChar('j'),
            .k => try self.putChar('k'),
            .l => try self.putChar('l'),
            .m => try self.putChar('m'),
            .n => try self.putChar('n'),
            .o => try self.putChar('o'),
            .p => try self.putChar('p'),
            .q => try self.putChar('q'),
            .r => try self.putChar('r'),
            .s => try self.putChar('s'),
            .t => try self.putChar('t'),
            .u => try self.putChar('u'),
            .v => try self.putChar('v'),
            .w => try self.putChar('w'),
            .x => try self.putChar('x'),
            .y => try self.putChar('y'),
            .z => try self.putChar('z'),
            .zero => try self.putChar('0'),
            .one => try self.putChar('1'),
            .two => try self.putChar('2'),
            .three => try self.putChar('3'),
            .four => try self.putChar('4'),
            .five => try self.putChar('5'),
            .six => try self.putChar('6'),
            .seven => try self.putChar('7'),
            .eight => try self.putChar('8'),
            .nine => try self.putChar('9'),
            else => {},
        }
    }

    pub fn draw(self: *TextArea, screen: *Screen) void {
        graphics.drawPrettyRectangle(screen, @floatFromInt(self.width), 3, &self.area_pos, self.border, self.border_style.fg);
        var cursor_style = self.text_style;
        cursor_style.bg = self.cursor_style;

        if (self._buffer.items.len > 0)
            graphics.drawText(screen, self._buffer.items[self._viewport.begin..self._viewport.end], &self.area_pos.add(&vec2(1, 1)), &self.text_style);

        if (!self.hidden_cursor) {
            if (self._cursor_pos == self._viewport.end or self._viewport.end == 0)
                graphics.drawText(screen, " ", &self.area_pos.add(&vec2(@floatFromInt(1 + self._cursor_pos - self._viewport.begin), 1)), &cursor_style)
            else
                graphics.drawText(screen, self._buffer.items[self._cursor_pos .. self._cursor_pos + 1], &self.area_pos.add(&vec2(@floatFromInt(1 + self._cursor_pos - self._viewport.begin), 1)), &cursor_style);
        }
    }

    pub fn deinit(self: TextArea) void {
        self._buffer.deinit();
    }
};
