const term = @import("terminal.zig");
pub const Terminal = term.Terminal;
pub const Cell = term.Cell;

const component = @import("component.zig");
pub const StaticObject = component.StaticObject;
pub const Component = component.Component;
pub const Vec2 = component.Vec2;
pub const Line = component.Line;
pub const Rectangle = component.Rectange;
pub const Triangle = component.Triangle;
pub const Circle = component.Circle;
pub const Text = component.Text;

pub const termBackend = @import("terminalBackend.zig");
