const backend = @import("backend/main.zig");
const Color = backend.Color;
const Attribute = backend.Attribute;

const Cell = @This();

char: u21,
fg: Color,
bg: Color,
attr: Attribute,
