const std = @import("std");
const Painter = @import("Painter.zig");
const Screen = @import("Screen.zig");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const style = @import("style.zig");
const Color = style.Color;
const KeyInput = @import("input.zig").KeyInput;
const Border = style.Border;
const Style = @import("style.zig").Style;
const Cell = style.Cell;

pub const List = struct {
    selected_item: i16,
    items: std.ArrayList([]const u8),
    style: ListConfig,

    pub const ListConfig = struct {
        width: usize,
        height: usize,
        padding: usize,
        border: struct {
            style: Style,
            border: Border,
            filling: Color = .none,
        },
        element: struct {
            height: usize,
            style: Style,
            filling: Color = .none,
        },
        selection: struct {
            element_style: Style,
            text_style: Style,
            filling: Color = .none,
        },
        text_style: Style,
    };

    pub fn init(
        allocator: std.mem.Allocator,
        style_config: *const ListConfig,
    ) List {
        return .{
            .selected_item = 0,
            .items = std.ArrayList([]const u8).init(allocator),
            .style = style_config.*,
        };
    }

    pub fn deinit(self: *List) void {
        self.items.deinit();
    }

    pub fn draw(self: *const List, painter: *Painter, pos: *const Vec2) void {
        painter.setCell(&self.style.border.style.cell());
        painter.drawPrettyRectangle(@floatFromInt(self.style.width), @floatFromInt(self.style.height), pos, self.style.border.border, self.style.border.filling);

        var current_pos = pos.*.add(&vec2(@floatFromInt(self.style.padding + 1), @floatFromInt(self.style.padding + 1)));
        for (0..self.items.items.len) |i| {
            var element_style: Cell = undefined;
            var text_style: Cell = undefined;
            var element_filling: Color = undefined;
            if (self.selected_item == i) {
                element_style = self.style.selection.element_style.cell();
                text_style = self.style.selection.text_style.cell();
                element_filling = self.style.selection.filling;
            } else {
                element_style = self.style.element.style.cell();
                text_style = self.style.text_style.cell();
                element_filling = self.style.border.filling;
            }

            const element_width = self.style.width - 2 * self.style.padding - 2;
            if (element_width > 1) {
                painter.setCell(&element_style);
                painter.drawPrettyRectangle(@floatFromInt(element_width), @floatFromInt(self.style.element.height), &current_pos, self.style.border.border, element_filling);

                if (element_width > 2) {
                    painter.setCell(&text_style);
                    const text_len = self.items.items[i].len;
                    const text_y: f32 = current_pos.y() + @as(f32, @floatFromInt(self.style.element.height / 2));
                    if (text_len > element_width - 2) {
                        const text_x = current_pos.x() + 1.0;
                        painter.drawText(self.items.items[i][0 .. element_width - 2], &vec2(text_x, text_y));
                    } else {
                        const text_x = current_pos.x() + @as(f32, @floatFromInt(element_width - text_len)) / 2;
                        painter.drawText(self.items.items[i], &vec2(text_x, text_y));
                    }
                }
            }

            current_pos = current_pos.add(&vec2(0, @floatFromInt(self.style.element.height + self.style.padding)));
            if (current_pos.y() - pos.y() + @as(f32, @floatFromInt(self.style.element.height)) >= @as(f32, @floatFromInt(self.style.height))) break;
        }
    }

    pub fn next(self: *List) void {
        self.selected_item = @mod((self.selected_item + 1), @as(i16, @intCast(self.items.items.len)));
    }

    pub fn previous(self: *List) void {
        self.selected_item = @mod((self.selected_item - 1), @as(i16, @intCast(self.items.items.len)));
    }
};

pub const TextArea = struct {
    style: TextAreaConfig,
    _buffer: std.ArrayList(u8),
    _cursor_pos: usize,
    _viewport: struct { begin: usize, end: usize },

    pub const TextAreaConfig = struct {
        width: usize,
        text_style: Style,
        cursor_style: Color,
        border: Border,
        border_style: Style,
        filling: Color = .none,
        hidden_cursor: bool = false,
    };

    pub fn init(
        allocator: std.mem.Allocator,
        style_config: *const TextAreaConfig,
    ) !TextArea {
        return .{
            .style = style_config.*,
            ._buffer = std.ArrayList(u8).init(allocator),
            ._cursor_pos = 0,
            ._viewport = .{ .begin = 0, .end = 0 },
        };
    }

    pub fn deinit(self: TextArea) void {
        self._buffer.deinit();
    }

    pub fn draw(self: *const TextArea, painter: *Painter, pos: *const Vec2) void {
        painter.setCell(&self.style.border_style.cell());
        painter.drawPrettyRectangle(@floatFromInt(self.style.width), 3, pos, self.style.border, self.style.filling);
        var cursor_style = self.style.text_style;
        cursor_style.bg = self.style.cursor_style;

        if (self._buffer.items.len > 0) {
            painter.setCell(&self.style.text_style.cell());
            painter.drawText(self._buffer.items[self._viewport.begin..self._viewport.end], &pos.add(&vec2(1, 1)));
        }

        if (!self.style.hidden_cursor) {
            if (self._cursor_pos == self._viewport.end or self._viewport.end == 0) {
                painter.setCell(&cursor_style.cell());
                painter.drawText(" ", &pos.add(&vec2(@floatFromInt(1 + self._cursor_pos - self._viewport.begin), 1)));
            } else {
                painter.setCell(&cursor_style.cell());
                painter.drawText(self._buffer.items[self._cursor_pos .. self._cursor_pos + 1], &pos.add(&vec2(@floatFromInt(1 + self._cursor_pos - self._viewport.begin), 1)));
            }
        }
    }

    pub fn buffer(self: *const TextArea) []const u8 {
        return self._buffer.items;
    }

    pub fn putChar(self: *TextArea, char: u8) !void {
        if (self._cursor_pos == 0 or self._cursor_pos > self._buffer.items.len)
            try self._buffer.append(char)
        else
            try self._buffer.insert(self._cursor_pos, char);
        if (self._cursor_pos == self._viewport.end) {
            if (self._viewport.end - self._viewport.begin < self.style.width - 2)
                self._viewport.end += 1;
            if (self._viewport.end - self._viewport.begin == self.style.width - 2)
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

    pub fn cursorLeft(self: *TextArea) void {
        if (self._cursor_pos > 0) {
            if (self._cursor_pos == self._viewport.begin) {
                if (self._viewport.begin > 0)
                    self._viewport.begin -= 1;
                if (self._viewport.end - self._viewport.begin - 1 == self.style.width - 2)
                    self._viewport.end -= 1;
            }
            self._cursor_pos -= 1;
        }
    }

    pub fn cursorRight(self: *TextArea) void {
        if (self._cursor_pos < self._buffer.items.len) {
            if (self._cursor_pos == self._viewport.end - 1) {
                if (self._viewport.end >= self.style.width - 2)
                    self._viewport.begin += 1;
                if (self._viewport.end != self._buffer.items.len)
                    self._viewport.end += 1;
            }
            self._cursor_pos += 1;
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
                .exclamation => try self.putChar('!'),
                .at => try self.putChar('@'),
                .hash => try self.putChar('#'),
                .dollar => try self.putChar('$'),
                .percent => try self.putChar('%'),
                .caret => try self.putChar('^'),
                .ampersand => try self.putChar('&'),
                .asterisk => try self.putChar('*'),
                .paren_left => try self.putChar('('),
                .paren_right => try self.putChar(')'),
                .underscore => try self.putChar('_'),
                .plus => try self.putChar('+'),
                .brace_left => try self.putChar('{'),
                .brace_right => try self.putChar('}'),
                .bar => try self.putChar('|'),
                .colon => try self.putChar(':'),
                .double_quote => try self.putChar('"'),
                .less => try self.putChar('<'),
                .greater => try self.putChar('>'),
                .question => try self.putChar('?'),
                .tilde => try self.putChar('~'),
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
            .minus => try self.putChar('-'),
            .equal => try self.putChar('='),
            .bracket_left => try self.putChar('['),
            .bracket_right => try self.putChar(']'),
            .backslash => try self.putChar('\\'),
            .semicolon => try self.putChar(';'),
            .apostrophe => try self.putChar('\''),
            .comma => try self.putChar(','),
            .period => try self.putChar('.'),
            .slash => try self.putChar('/'),
            .grave => try self.putChar('`'),
            .nine => try self.putChar('9'),
            else => {},
        }
    }
};
