const backend = @import("backend/main.zig");

pub const Terminal = @import("Terminal.zig");
pub const Cell = @import("Cell.zig");
pub const Color = backend.Color;
pub const Attribute = backend.Attributes;

pub const graphics = @import("graphics.zig");

pub const TerminalBackend = backend.TerminalBackend;

pub const math = @import("math.zig");
