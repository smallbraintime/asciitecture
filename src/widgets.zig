const std = @import("std");
const math = @import("math.zig");
const style = @import("style.zig");
const Painter = @import("Painter.zig");
const Screen = @import("Screen.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const Color = style.Color;
const Border = style.Border;
const Style = style.Style;
const Cell = style.Cell;
const KeyInput = @import("input.zig").KeyInput;

pub const Paragraph = struct {
    pub const ParagraphConfig = struct {
        border_style: struct {
            border: Border,
            style: Style,
        },
        text_style: Style,
        filling: bool,
        animation: ?struct {
            speed: f32,
            looping: bool,
        },
    };

    config: ParagraphConfig,
    content: std.ArrayList([]const u8),
    _animation_state: struct {
        current_line: usize,
        current_index: f32,
    },

    pub fn init(
        allocator: std.mem.Allocator,
        content: []const []const u8,
        config: ParagraphConfig,
    ) !Paragraph {
        var self = Paragraph{
            .content = std.ArrayList([]const u8).init(allocator),
            .config = config,
            ._animation_state = .{
                .current_line = 0,
                .current_index = 0,
            },
        };
        if (content.len > 0) try self.content.appendSlice(content);
        return self;
    }

    pub fn deinit(self: *Paragraph) void {
        self.content.deinit();
    }

    pub fn draw(
        self: *Paragraph,
        painter: *Painter,
        pos: *const Vec2,
        delta_time: f32,
    ) !void {
        if (self.content.items.len == 0) return;

        var longest: usize = 0;
        for (self.content.items) |el| {
            if (el.len > longest) longest = el.len;
        }
        painter.setCell(&self.config.border_style.style.cell());
        painter.drawPrettyRectangle(
            @floatFromInt(longest + 2),
            @floatFromInt(self.content.items.len + 2),
            pos,
            self.config.border_style.border,
            self.config.filling,
        );

        var new_pos = pos.*.add(&vec2(1, 0));
        painter.setCell(&self.config.text_style.cell());
        if (self.config.animation) |anim| {
            if (anim.looping) {
                var current_index: usize = @intFromFloat(@round(self._animation_state.current_index));
                if (current_index > self.content.items[self._animation_state.current_line].len) {
                    self._animation_state.current_line += 1;
                    self._animation_state.current_index = 0;
                    current_index = 0;
                }
                if (self._animation_state.current_line >= self.content.items.len) {
                    self._animation_state.current_line = 0;
                    self._animation_state.current_index = 0;
                }

                for (0.., self.content.items) |line, el| {
                    new_pos = new_pos.add(&vec2(0, 1));
                    if (line < self._animation_state.current_line) {
                        try painter.drawText(el, &new_pos);
                    } else if (line == self._animation_state.current_line) {
                        try painter.drawText(el[0..current_index], &new_pos);
                    }
                }

                self._animation_state.current_index += anim.speed * delta_time;
            } else {
                var current_index: usize = @intFromFloat(@round(self._animation_state.current_index));
                if (self._animation_state.current_line != self.content.items.len - 1 or
                    current_index < self.content.items[self._animation_state.current_line].len)
                {
                    if (current_index >= self.content.items[self._animation_state.current_line].len) {
                        self._animation_state.current_line += 1;
                        self._animation_state.current_index = 0;
                        current_index = 0;
                    }
                    if (self._animation_state.current_line >= self.content.items.len) {
                        self._animation_state.current_line = 0;
                        self._animation_state.current_index = 0;
                    }

                    self._animation_state.current_index += anim.speed * delta_time;
                }

                for (0.., self.content.items) |line, el| {
                    new_pos = new_pos.add(&vec2(0, 1));
                    if (line < self._animation_state.current_line) {
                        try painter.drawText(el, &new_pos);
                    } else if (line == self._animation_state.current_line) {
                        try painter.drawText(el[0..current_index], &new_pos);
                    }
                }
            }
        } else {
            for (self.content.items) |el| {
                new_pos = new_pos.add(&vec2(0, 1));
                try painter.drawText(el, &new_pos);
            }
        }
    }

    pub fn reset(self: *Paragraph) void {
        self._animation_state.current_line = 0;
        self._animation_state.current_index = 0;
    }
};

pub const Menu = struct {
    pub const MenuConfig = struct {
        width: f32,
        height: f32,
        orientation: Orientantion,
        padding: f32,
        border: struct {
            style: Style,
            border: Border,
            filling: bool,
        },
        element: struct {
            style: Style,
            filling: bool,
        },
        selection: struct {
            element_style: Style,
            text_style: Style,
            filling: bool,
        },
        text_style: Style,
    };

    config: MenuConfig,
    items: std.ArrayList([]const u8),
    selected_item: i16,

    pub const Orientantion = enum {
        vertical,
        horizontal,
    };

    pub fn init(allocator: std.mem.Allocator, style_config: MenuConfig) Menu {
        return .{
            .config = style_config,
            .items = std.ArrayList([]const u8).init(allocator),
            .selected_item = 0,
        };
    }

    pub fn deinit(self: *Menu) void {
        self.items.deinit();
    }

    pub fn draw(self: *const Menu, painter: *Painter, pos: *const Vec2) !void {
        const items_len: f32 = @floatFromInt(self.items.items.len);

        if (items_len == 0) return;
        if (self.config.width < 3 + self.config.padding or
            self.config.height < 3 + self.config.padding) return;

        painter.setCell(&self.config.border.style.cell());
        painter.drawPrettyRectangle(
            self.config.width,
            self.config.height,
            pos,
            self.config.border.border,
            self.config.border.filling,
        );

        var element_width: f32 = undefined;
        var element_height: f32 = undefined;
        switch (self.config.orientation) {
            .vertical => {
                element_width = self.config.width - 2 * self.config.padding - 2;
                element_height =
                    @floor(((self.config.height - self.config.padding * items_len) - 3) / items_len);
            },
            .horizontal => {
                element_width =
                    @floor(((self.config.width - self.config.padding * items_len) - 3) / items_len);
                element_height = self.config.height - 2 * self.config.padding - 2;
            },
        }
        if (element_height < 3 or element_width < 3) return;

        const element_center_y = element_height / 2;

        var current_pos = pos.*.add(&vec2(self.config.padding + 1, self.config.padding + 1));
        for (0..self.items.items.len) |i| {
            var element_style: Cell = undefined;
            var text_style: Cell = undefined;
            var element_filling: bool = undefined;
            if (self.selected_item == i) {
                element_style = self.config.selection.element_style.cell();
                text_style = self.config.selection.text_style.cell();
                element_filling = self.config.selection.filling;
            } else {
                element_style = self.config.element.style.cell();
                text_style = self.config.text_style.cell();
                element_filling = self.config.element.filling;
            }

            painter.setCell(&element_style);
            painter.drawPrettyRectangle(
                element_width,
                element_height,
                &current_pos,
                self.config.border.border,
                element_filling,
            );

            const text_len: f32 = @floatFromInt(self.items.items[i].len);
            const text_y: f32 = @floor(current_pos.y() + element_center_y);
            painter.setCell(&text_style);
            if (text_len > element_width - 2) {
                const text_x = current_pos.x() + 1;
                try painter.drawText(
                    self.items.items[i][0..@as(usize, @intFromFloat(@round(element_width - 2)))],
                    &vec2(text_x, text_y),
                );
            } else {
                const text_x = current_pos.x() + (element_width - text_len) / 2;
                try painter.drawText(self.items.items[i], &vec2(text_x, text_y));
            }

            switch (self.config.orientation) {
                .vertical => current_pos =
                    current_pos.add(&vec2(0, element_height + self.config.padding)),
                .horizontal => current_pos =
                    current_pos.add(&vec2(element_width + self.config.padding, 0)),
            }
        }
    }

    pub fn next(self: *Menu) void {
        self.selected_item =
            @mod((self.selected_item + 1), @as(i16, @intCast(self.items.items.len)));
    }

    pub fn previous(self: *Menu) void {
        self.selected_item =
            @mod((self.selected_item - 1), @as(i16, @intCast(self.items.items.len)));
    }
};

pub const TextInput = struct {
    pub const TextInputConfig = struct {
        width: usize,
        text_style: Style,
        cursor_color: Color,
        border: Border,
        border_style: Style,
        filling: bool,
        hidden_cursor: bool = false,
        placeholder: ?struct {
            content: []const u8,
            style: Style,
        },
    };

    config: TextInputConfig,
    _buffer: std.ArrayList(u8),
    _cursor_pos: usize,
    _viewport: struct { begin: usize, end: usize },

    pub fn init(allocator: std.mem.Allocator, config: TextInputConfig) !TextInput {
        return .{
            .config = config,
            ._buffer = std.ArrayList(u8).init(allocator),
            ._cursor_pos = 0,
            ._viewport = .{ .begin = 0, .end = 0 },
        };
    }

    pub fn deinit(self: TextInput) void {
        self._buffer.deinit();
    }

    pub fn draw(self: *const TextInput, painter: *Painter, pos: *const Vec2) !void {
        painter.setCell(&self.config.border_style.cell());
        painter.drawPrettyRectangle(
            @floatFromInt(self.config.width),
            3,
            pos,
            self.config.border,
            self.config.filling,
        );
        var cursor_style = self.config.text_style;
        cursor_style.bg = self.config.cursor_color;

        if (self._buffer.items.len > 0) {
            painter.setCell(&self.config.text_style.cell());
            try painter.drawText(
                self._buffer.items[self._viewport.begin..self._viewport.end],
                &pos.add(&vec2(1, 1)),
            );
        } else {
            if (self.config.placeholder) |ph| {
                painter.setCell(&ph.style.cell());
                try painter.drawText(ph.content[0 .. self.config.width - 2], &pos.add(&vec2(1, 1)));
            }
        }

        if (!self.config.hidden_cursor) {
            if (self.config.placeholder == null or self._buffer.items.len > 0) {
                if (self._cursor_pos == self._viewport.end or self._viewport.end == 0) {
                    painter.setCell(&cursor_style.cell());
                    try painter.drawText(
                        " ",
                        &pos.add(&vec2(@floatFromInt(1 + self._cursor_pos - self._viewport.begin), 1)),
                    );
                } else {
                    painter.setCell(&cursor_style.cell());
                    try painter.drawText(
                        self._buffer.items[self._cursor_pos .. self._cursor_pos + 1],
                        &pos.add(&vec2(@floatFromInt(1 + self._cursor_pos - self._viewport.begin), 1)),
                    );
                }
            }
        }
    }

    pub inline fn buffer(self: *const TextInput) []const u8 {
        return self._buffer.items;
    }

    pub fn putChar(self: *TextInput, char: u8) !void {
        if (self._cursor_pos == 0 or self._cursor_pos > self._buffer.items.len) {
            try self._buffer.append(char);
        } else {
            try self._buffer.insert(self._cursor_pos, char);
        }
        if (self._cursor_pos == self._viewport.end) {
            if (self._viewport.end - self._viewport.begin < self.config.width - 2)
                self._viewport.end += 1;
            if (self._viewport.end - self._viewport.begin == self.config.width - 2)
                self._viewport.begin += 1;
        }
        if (self._cursor_pos < self._viewport.end) self._cursor_pos += 1;
    }

    pub fn delChar(self: *TextInput) void {
        if (self._cursor_pos > 0) {
            if (self._cursor_pos == self._viewport.begin or
                self._cursor_pos == self._viewport.end)
            {
                if (self._viewport.begin > 0) {
                    self._viewport.begin -= 1;
                    self._viewport.end -= 1;
                }
            }
            if (self._viewport.end == self._buffer.items.len)
                self._viewport.end -= 1;
            self._cursor_pos -= 1;
            _ = self._buffer.orderedRemove(self._cursor_pos);
        }
    }

    pub fn cursorLeft(self: *TextInput) void {
        if (self._cursor_pos > 0) {
            if (self._cursor_pos == self._viewport.begin) {
                if (self._viewport.begin > 0)
                    self._viewport.begin -= 1;
                if (self._viewport.end - self._viewport.begin - 1 == self.config.width - 2)
                    self._viewport.end -= 1;
            }
            self._cursor_pos -= 1;
        }
    }

    pub fn cursorRight(self: *TextInput) void {
        if (self._cursor_pos < self._buffer.items.len) {
            if (self._cursor_pos == self._viewport.end - 1) {
                if (self._viewport.end >= self.config.width - 2)
                    self._viewport.begin += 1;
                if (self._viewport.end != self._buffer.items.len)
                    self._viewport.end += 1;
            }
            self._cursor_pos += 1;
        }
    }

    pub fn input(self: *TextInput, key_input: *const KeyInput) !void {
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
