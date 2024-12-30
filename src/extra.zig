const Screen = @import("Screen.zig");
const Painter = @import("Painter.zig");
const math = @import("math.zig");
const Vec2 = math.Vec2;
const vec2 = math.vec2;
const style = @import("style.zig");
const Cell = style.Cell;
const RgbColor = style.RgbColor;
const std = @import("std");

pub fn screenMeltingTransition(screen: *Screen, old_buffer: []const Cell, new_buffer: []const Cell, allocator: std.mem.Allocator) !void {
    // init part
    const state = struct {
        var unused_cols: ?std.ArrayList(usize) = null;
        var falling_cols: ?std.DynamicBitSet = null;
        var col_positions: ?std.ArrayList(usize) = null;
    };
    if (state.unused_cols) |uc| {
        uc = try std.ArrayList(usize).initCapacity(allocator, screen.size.cols);
        for (0..screen.size.cols) |i| try state.unused_cols.append(i);
    }
    if (state.falling_cols) |fc| {
        fc = try std.DynamicBitSet.initFull(allocator, screen.buf.items.len);
        fc.setRangeValue(.{ .start = 0, .end = screen.size.cols }, false);
    }
    if (state.col_positions) |cp| {
        cp = try std.ArrayList(usize).initCapacity(allocator, screen.size.cols);
        @memset(cp.items, 0);
    }

    // rand part
    var rng = std.rand.DefaultPrng.init(std.time.nanoTimestamp());
    var prng = rng.random();
    for (0..5) |_| {
        const index = prng.intRangeAtMost(usize, 0, state.unused_cols.?.items.len);
        const col = state.unused_cols.?.swapRemove(index);
        state.falling_cols.?.set(col);
    }

    // old buffer drawing part
    for (0..screen.size.cols) |col| {
        if (state.falling_cols.?.isSet(col)) {
            var counter = screen.size.cols;
            while (counter <= 0 or state.col_positions.?.items[col] > screen.size.cols) {
                const c = old_buffer[counter - 1 * screen.size.rows + col];
                screen.writeCell(counter, col, c);
                counter -= 1;
            }
            state.col_positions.?.items[col] += 1;
            if (state.col_positions.?.items[col] > screen.size.cols) {
                state.falling_cols.?.unset(col);
            }
        }
    }

    // new buffer drawing part
    for (state.col_positions.?.items, 0..) |pos, col| {
        for (0..pos) |row| {
            screen.writeCell(row, col, new_buffer[row * screen.size.rows + col]);
        }
    }

    for (state.col_positions.?.items) |pos| {
        if (pos <= screen.size.rows) {
            return;
        }
    }

    state.unused_cols.?.deinit();
    state.falling_cols.?.deinit();
    state.cols_positions.?.deinit();
    state.unused_cols = null;
    state.falling_cols = null;
    state.cols_positions = null;
}
