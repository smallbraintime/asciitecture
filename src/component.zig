const std = @import("std");
const term = @import("terminal.zig").Cell;
const Cell = term.Cell;
const Buffer = term.Buffer;
const Color = term.Color;
const Modifier = term.Modifier;

pub const Vec2 = struct {
    x: isize,
    y: isize,
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

    pub fn render(self: *Component, buffer: *Buffer) void {
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

    pub fn render(self: *Line, buffer: *Buffer) void {
        drawLine(*buffer, self.start, self.end, self.style);
    }
};

pub const Rectange = struct {
    width: usize,
    height: usize,
    pos: Vec2,
    style: Cell,
    fill: bool,

    pub fn render(self: *Rectange, buffer: *Buffer) void {
        const topLeft = self.pos;
        const topRight = Vec2{ .x = self.pos.x + self.width - 1, .y = self.pos.y };
        const bottomLeft = Vec2{ .x = self.pos.x, .y = self.pos.y + self.height - 1 };
        const bottomRight = Vec2{ .x = self.pos.x + self.width - 1, .y = self.pos.y + self.height - 1 };

        buffer.drawLine(topLeft, topRight, self.style);
        buffer.drawLine(topRight, bottomRight, self.style);
        buffer.drawLine(bottomRight, bottomLeft, self.style);
        buffer.drawLine(bottomLeft, topLeft, self.style);

        if (self.fill) {}
    }
};

pub const Triangle = struct {
    points: [3]Vec2,
    pos: Vec2,
    style: Cell,
    fill: bool,

    pub fn render(self: *Triangle, buffer: *Buffer) void {
        if (self.fill) {}
    }
};

pub const Circle = struct {
    radius: usize,
    pos: Vec2,
    style: Cell,
    fill: bool,

    pub fn render(self: *Circle, buffer: *Buffer) void {
        if (self.fill) {}
    }
};

pub const Text = struct {
    content: []const u8,
    fg: Color,
    bg: Color,
    mod: Modifier,
    pos: Vec2,

    pub fn render(self: *Text, buffer: *Buffer) void {
        const x = self.pos.x;
        const y = self.pos.y;

        var style = Cell{
            .fg = self.fg,
            .bg = self.bg,
            .mod = self.mod,
        };

        for (0..self.spans.len) |i| {
            style.char = self.content[i];
            buffer.setCell(x + i, y, style);
        }
    }
};

pub const Particle = struct {
    style: Cell,
    lifetime: f32,
    velocity: Vec2,
    pos: Vec2,

    pub fn render(self: *Particle, buffer: *Buffer) void {}
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

    pub fn render(self: *ParticleEffect, buffer: *Buffer) void {}
};

pub fn drawLine(self: *Buffer, start: Vec2, end: Vec2, style: Cell) void {
    var x0 = start.x;
    var y0 = start.y;
    const x1 = end.x;
    const y1 = end.y;

    const dx = @abs(x1 - x0);
    const dy = @abs(y1 - y0);
    const sx = if (x0 < x1) 1 else -1;
    const sy = if (y0 < y1) 1 else -1;
    var err = dx - dy;

    while (true) {
        self.setCell(x0, y0, style);
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

pub fn flood_fill(x: Vec2, y: Vec2, style: Cell) void {}

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
