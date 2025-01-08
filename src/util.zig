const std = @import("std");
const Painter = @import("Painter.zig");
const Vec2 = @import("math.zig").Vec2;

pub fn randomRange(comptime T: type, a: T, b: T) T {
    var rn: [1]u8 = undefined;
    std.posix.getrandom(&rn) catch unreachable;
    var rng = std.rand.DefaultPrng.init(@intCast(rn[0]));

    switch (@typeInfo(T)) {
        .Int => return rng.random().intRangeAtMost(T, a, b),
        .Float => return switch (T) {
            f32 => return @floatFromInt(rng.random().intRangeAtMost(i32, @intFromFloat(a), @intFromFloat(b))),
            f64 => return @floatFromInt(rng.random().intRangeAtMost(i64, @intFromFloat(a), @intFromFloat(b))),
            else => unreachable,
        },
        else => unreachable,
    }
}

test "randomRange" {
    _ = randomRange(u8, 0.0, 2.0);
    _ = randomRange(i32, 0.0, 2.0);
    _ = randomRange(u21, 0.0, 2.0);
    _ = randomRange(f32, 0.0, 2.0);
    _ = randomRange(f64, 0.0, 2.0);
}
