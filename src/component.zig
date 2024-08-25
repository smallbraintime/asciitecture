const std = @import("std");
const term = @import("terminal.zig");
const Cell = term.Cell;
const Buffer = term.Buffer;
const termBackend = @import("terminalBackend.zig");
const Color = termBackend.Color;
const Attribute = termBackend.Attribute;

pub const Vec2 = struct {
    x: u16,
    y: u16,
};

pub const StaticObject = struct {
    components: std.ArrayList(*Component),
    position: Vec2,

    pub fn init(allocator: std.mem.Allocator) StaticObject {
        return StaticObject{
            .components = std.ArrayList(Component).init(allocator),
            .position = Vec2{ .x = 0, .y = 0 },
        };
    }

    pub fn attach(self: *StaticObject, component: *Component) void {
        self.components.append(*component);
    }

    pub fn render(self: *StaticObject) void {
        for (self.components) |*component| {
            component.render();
        }
    }

    pub fn deinit(self: StaticObject) void {
        self.components.deinit();
    }
};

const Component = union(enum) {
    line: Line,
    rectange: Rectange,
    triangle: Triangle,
    circle: Circle,
    text: Text,
    particle: ParticleEffect,
    // canvas: Canvas,

    pub fn render(self: *const Component, buffer: *Buffer) void {
        switch (self.*) {
            inline else => |*case| return try case.render(*buffer),
        }
    }
};

pub fn from(ctx: *anyopaque, comptime T: type) Component {
    const ref: *T = @ptrCast(@alignCast(ctx));
    switch (T) {
        Line => return Component{ .line = ref.* },
        Rectange => return Component{ .rectange = ref.* },
        Triangle => return Component{ .triangle = ref.* },
        Circle => return Component{ .circle = ref.* },
        Text => return Component{ .text = ref.* },
        ParticleEffect => return Component{ .particle = ref.* },
        // Canvas => return Component{ .canvas = ref.* },
    }
}

pub const Line = struct {
    start: Vec2,
    end: Vec2,
    style: Cell,

    pub fn render(self: *const Line, buffer: *Buffer) void {
        drawLine(buffer, self.start, self.end, self.style);
    }
};

pub const Rectange = struct {
    width: u16,
    height: u16,
    pos: Vec2,
    style: Cell,
    filled: bool,

    pub fn render(self: *const Rectange, buffer: *Buffer) !void {
        const topLeft = self.pos;
        const topRight = Vec2{ .x = self.pos.x + self.width - 1, .y = self.pos.y };
        const bottomLeft = Vec2{ .x = self.pos.x, .y = self.pos.y + self.height - 1 };
        const bottomRight = Vec2{ .x = self.pos.x + self.width - 1, .y = self.pos.y + self.height - 1 };

        drawLine(buffer, topLeft, topRight, self.style);
        drawLine(buffer, topRight, bottomRight, self.style);
        drawLine(buffer, bottomRight, bottomLeft, self.style);
        drawLine(buffer, bottomLeft, topLeft, self.style);

        if (self.filled) {
            try fill(buffer, Vec2{ .x = topLeft.x + 1, .y = topLeft.y + 1 }, self.style);
        }
    }
};

pub const Triangle = struct {
    verticies: [3]Vec2,
    // pos: Vec2,
    style: Cell,
    filled: bool,

    pub fn render(self: *const Triangle, buffer: *Buffer) !void {
        const p1 = self.verticies[0];
        const p2 = self.verticies[1];
        const p3 = self.verticies[2];

        drawLine(buffer, p1, p2, self.style);
        drawLine(buffer, p2, p3, self.style);
        drawLine(buffer, p3, p1, self.style);

        if (self.filled) {
            try fill(buffer, Vec2{ .x = (p1.x + p2.x + p3.x) / 3, .y = (p1.y + p2.y + p3.y) / 3 }, self.style);
        }
    }
};

pub const Circle = struct {
    radius: u32,
    pos: Vec2,
    style: Cell,
    filled: bool,

    pub fn render(self: *const Circle, buffer: *Buffer) !void {
        drawCircle(buffer, self.pos, self.radius, self.style);

        if (self.filled) {
            try fill(buffer, self.pos, self.style);
        }
    }
};

pub const Text = struct {
    content: []const u8,
    fg: Color,
    bg: Color,
    attr: []const u8,
    pos: Vec2,

    pub fn render(self: *const Text, buffer: *Buffer) void {
        const x = self.pos.x;
        const y = self.pos.y;

        const style = Cell{
            .fg = self.fg,
            .bg = self.bg,
            .attr = self.attr,
            .char = self.content,
        };

        buffer.setCell(x, y, style);
    }
};

pub const Particle = struct {
    style: Cell,
    lifetime: f32,
    velocity: Vec2,
    pos: Vec2,

    pub fn render(self: *const Particle, buffer: *Buffer) void {
        _ = self;
        _ = buffer;
    }
};

pub const ParticleEffect = struct {
    particles: std.ArrayList(*Particle),
    duration: f32,
    elapsedTime: f32,
    emissionRate: f32,
    particleLifetime: f32,
    startStyle: Cell,
    endStyle: Cell,
    isActive: bool,
    pos: Vec2,

    pub fn render(self: *const ParticleEffect, buffer: *Buffer) void {
        _ = self;
        _ = buffer;
    }
};

pub fn drawLine(self: *Buffer, start: Vec2, end: Vec2, style: Cell) void {
    var x0: i32 = @intCast(start.x);
    var y0: i32 = @intCast(start.y);
    const x1: i32 = @intCast(end.x);
    const y1: i32 = @intCast(end.y);

    const dx: i32 = @intCast(@abs(x1 - x0));
    const dy: i32 = @intCast(@abs(y1 - y0));
    const sx: i32 = if (x0 < x1) 1 else -1;
    const sy: i32 = if (y0 < y1) 1 else -1;
    var err = dx - dy;

    while (true) {
        self.setCell(@intCast(x0), @intCast(y0), style);
        if (x0 == x1 and y0 == y1) break;
        const e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x0 += sx;
        }
        if (e2 < dx) {
            err += dx;
            y0 += sy;
        }
    }
}

pub fn drawCircle(buffer: *Buffer, pos: Vec2, radius: u32, style: Cell) void {
    var x: u32 = 0;
    var y = radius;
    var d: i64 = @intCast(3 - 2 * radius);

    putCircleCells(buffer, pos, Vec2{ .x = x, .y = radius }, style);

    while (y >= x) {
        x += 1;

        if (d > 0) {
            y -= 1;
            d = d + (4 * @as(i64, @intCast(x)) - @as(i64, @intCast(y)) + 10);
        } else {
            d = d + (4 * @as(i64, x) + 6);
        }

        putCircleCells(buffer, pos, Vec2{ .x = x, .y = y }, style);
    }
}

fn putCircleCells(buffer: *Buffer, pos: Vec2, edge: Vec2, style: Cell) void {
    buffer.setCell(pos.x + edge.x, pos.y + edge.y, style);
    buffer.setCell(pos.x - edge.x, pos.y + edge.y, style);
    buffer.setCell(pos.x + edge.x, pos.y - edge.y, style);
    buffer.setCell(pos.x - edge.x, pos.y - edge.y, style);
    buffer.setCell(pos.x + edge.x, pos.y + edge.y, style);
    buffer.setCell(pos.x - edge.x, pos.y + edge.y, style);
    buffer.setCell(pos.x + edge.x, pos.y - edge.y, style);
    buffer.setCell(pos.x - edge.x, pos.y - edge.y, style);
}

pub fn fill(buffer: *Buffer, startPos: Vec2, newStyle: Cell) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var visited = std.ArrayList(Vec2).init(gpa.allocator());
    defer _ = visited.deinit();

    try flood_fill(
        buffer,
        startPos,
        newStyle,
        buffer.buf.items[startPos.y * buffer.width + startPos.x],
        &visited,
    );
}

pub fn flood_fill(
    buffer: *Buffer,
    startPos: Vec2,
    newStyle: Cell,
    oldStyle: Cell,
    visited: *std.ArrayList(Vec2),
) !void {
    const rowInBounds = startPos.x >= 0 and startPos.x < buffer.height;
    const colInBounds = startPos.y >= 0 and startPos.y < buffer.width;

    if (!rowInBounds or !colInBounds) return;
    for (try visited.toOwnedSlice()) |pos| {
        if (pos.x == startPos.x and pos.y == startPos.y) {
            return;
        }
    }
    if (std.meta.eql(buffer.getCell(startPos.x, startPos.y), oldStyle)) return;

    try visited.append(startPos);
    buffer.setCell(startPos.x, startPos.y, newStyle);

    var startPos1 = startPos;
    startPos1.x += 1;
    try flood_fill(
        buffer,
        startPos1,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos2 = startPos;
    startPos2.x -= 1;
    try flood_fill(
        buffer,
        startPos2,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos3 = startPos;
    startPos3.y += 1;
    try flood_fill(
        buffer,
        startPos3,
        newStyle,
        oldStyle,
        visited,
    );

    var startPos4 = startPos;
    startPos4.y -= 1;
    try flood_fill(
        buffer,
        startPos4,
        newStyle,
        oldStyle,
        visited,
    );
}

// pub const Canvas = struct {
//     width: usize,
//     height: usize,
//     buffer: ?[]const Cell,
//     renderFunc: ?fn (*Buffer) void,
//     pos: Vec2,
//
//     pub fn fromString(self: *Canvas, comptime str: []const u8) void {
//         var it = std.mem.window(u8, str, 1, 2);
//         for (it, 0..) |slice, i| {
//             if (slice != " ") {}
//         }
//     }
//
//     fn drawBuffer(self: *Canvas, buffer: *Buffer) void {
//         for (self.buffer) |*cell| {}
//     }
//
//     pub fn set_rendering(self: *Canvas, renderFunc: fn (*Buffer) void) void {
//         self.renderFunc = renderFunc;
//     }
//
//     pub fn render(self: *Canvas, buffer: *Buffer) void {
//         if (self.renderFunc.?) {
//             self.renderFunc(*buffer);
//         } else {
//             self.drawBuffer(*buffer);
//         }
//     }
// };
