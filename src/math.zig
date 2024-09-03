const std = @import("std");
const math = std.math;

pub const Vec2 = struct {
    const Vec = @This();
    pub const Scalar = f32;
    pub const n = 2;
    vec: @Vector(Scalar, n),

    pub inline fn init(xs: Scalar, ys: Scalar) Vec {
        return .{ .vec = .{ xs, ys } };
    }

    pub inline fn x(v: *const Vec) Scalar {
        return v.vec[0];
    }

    pub inline fn y(v: *const Vec) Scalar {
        return v.vec[1];
    }

    pub const Shared = SharedVec(Vec);
    pub const add = Shared.add;
    pub const sub = Shared.sub;
    pub const div = Shared.div;
    pub const mul = Shared.mul;
    pub const splat = Shared.splat;
    pub const dot = Shared.dot;
    pub const lenSquared = Shared.lenSquared;
    pub const len = Shared.len;
    pub const distSquared = Shared.distSquared;
    pub const dist = Shared.dist;
    pub const norm = Shared.norm;
    pub const inv = Shared.inv;
    pub const neg = Shared.neg;
    pub const eql = Shared.eql;
};

pub const vec2 = Vec2.init;

pub const Vec3 = struct {
    const Vec = @This();
    pub const Scalar = f32;
    pub const n = 3;
    vec: @Vector(Scalar, n),

    pub inline fn init(xs: Scalar, ys: Scalar, zs: Scalar) Vec {
        return .{ .vec = .{ xs, ys, zs } };
    }

    pub inline fn x(v: *const Vec) Scalar {
        return v.vec[0];
    }

    pub inline fn y(v: *const Vec) Scalar {
        return v.vec[1];
    }

    pub inline fn z(v: *const Vec) Scalar {
        return v.vec[2];
    }

    pub const Shared = SharedVec(Vec);
    pub const add = Shared.add;
    pub const sub = Shared.sub;
    pub const div = Shared.div;
    pub const mul = Shared.mul;
    pub const splat = Shared.splat;
    pub const dot = Shared.dot;
    pub const lenSquared = Shared.lenSquared;
    pub const len = Shared.len;
    pub const distSquared = Shared.distSquared;
    pub const dist = Shared.dist;
    pub const norm = Shared.norm;
    pub const inv = Shared.inv;
    pub const neg = Shared.neg;
    pub const eql = Shared.eql;
};

pub const vec3 = Vec3.init;

pub const Mat3x3 = struct {
    const Mat = @This();
    pub const Vec = Vec3;
    pub const Scalar = Vec.Scalar;
    pub const rows = 3;
    pub const cols = 3;
    mat: [cols]Vec,

    pub const ident = Mat.init(
        &Vec.init(1, 0, 0),
        &Vec.init(0, 1, 0),
        &Vec.init(0, 0, 1),
    );

    pub inline fn init(r0: Vec, r1: Vec, r2: Vec) Mat {
        return Mat.init(r0, r1, r2);
    }

    pub inline fn row(m: *const Mat, i: usize) Vec {
        return .{ .mat = .{ m.mat[0].vec[i], m.mat[1].vec[i], m.mat[2].vec[i] } };
    }

    pub inline fn col(m: *const Mat, i: usize) Vec {
        return .{ .mat = .{ m.mat[i].vec[0], m.mat[i].vec[1], m.mat[i].vec[2] } };
    }

    pub inline fn transpose(m: *const Mat) Mat {
        return .{ .v = [_]Vec{
            Vec.init(m.mat[0].vec[0], m.mat[1].vec[0], m.mat[2].vec[0]),
            Vec.init(m.mat[0].vec[1], m.mat[1].vec[1], m.mat[2].vec[1]),
            Vec.init(m.mat[0].vec[2], m.mat[1].vec[2], m.mat[2].vec[2]),
        } };
    }

    pub inline fn translate(v: Vec2) Mat {
        return init(
            &Vec2.init(1, 0, v.x()),
            &Vec2.init(0, 1, v.y()),
            &Vec2.init(0, 0, 1),
        );
    }

    pub inline fn translateScalar(s: Scalar) Mat {
        return translate(Vec2.splat(s));
    }

    pub inline fn scale(v: Vec2) Mat {
        return init(
            &Vec2.init(v.x(), 0, 0),
            &Vec2.init(0, v.y(), 0),
            &Vec2.init(0, 0, 1),
        );
    }

    pub inline fn scaleScalar(s: Scalar) Mat {
        return scale(Vec2.splat(s));
    }

    pub inline fn rotateScalar(s: Scalar) Mat {
        const cos = math.cos(s);
        const sin = math.sin(s);
        return init(
            &Vec.init(cos, -sin, 0),
            &Vec.init(sin, cos, 0),
            &Vec.init(0, 0, 1),
        );
    }

    pub inline fn mul(a: *const Mat, b: *const Mat) Mat {
        var result: Mat = undefined;
        inline for (0..Mat.rows) |r| {
            inline for (0..Mat.cols) |c| {
                var sum: Scalar = undefined;
                inline for (0..Vec.n) |i| {
                    sum += a[i].vec[r] * b[c].vec[i];
                }
                result[c].vec[r] = sum;
            }
        }
        return result;
    }

    pub inline fn mulVec(m: *const Mat, v: *const Vec) Mat {
        var result = [_]Vec{0} ** Vec.cols;
        inline for (0..Mat.rows) |r| {
            inline for (0..Vec.n) |c| {
                result[c] = m.mat[r].mat[c] * v.vec[r];
            }
        }
        return Vec{ .vec = result };
    }

    pub inline fn Projection2d(left: f32, right: f32, top: f32, bottom: f32) Mat {
        return init(
            &Vec.init(2.0 / (right - left), 0, -(right + left) / (right - left)),
            &Vec.init(0, 2.0 / (top - bottom), -(top + bottom) / (top - bottom)),
            &Vec.init(0, 0, 1),
        );
    }
};

pub const mat3x3 = Mat3x3.init;

fn SharedVec(comptime Vec: type) type {
    return struct {
        const Scalar = f32;

        pub inline fn add(a: *const Vec, b: *const Vec) Vec {
            return .{ .vec = a.vec + b.vec };
        }

        pub inline fn sub(a: *const Vec, b: *const Vec) Vec {
            return .{ .vec = a.vec - b.vec };
        }

        pub inline fn mul(a: *const Vec, b: *const Vec) Vec {
            return .{ .vec = a.vec * b.vec };
        }

        pub inline fn div(a: *const Vec, b: *const Vec) Vec {
            return .{ .vec = a.vec / b.vec };
        }

        pub inline fn splat(s: Scalar) Vec {
            return .{ .vec = @splat(s) };
        }

        pub inline fn dot(a: *const Vec, b: *const Vec) Vec {
            return @reduce(.Add, a.vec * b.vec);
        }

        pub inline fn lenSquared(v: *const Vec) Scalar {
            return switch (Vec.n) {
                inline 2 => (v.x() * v.x()) + (v.y() * v.y()),
                inline 3 => (v.x() * v.x()) + (v.y() * v.y()) + (v.z() * v.z()),
                else => unreachable,
            };
        }

        pub inline fn len(v: *const Vec) Scalar {
            return math.sqrt(lenSquared(v));
        }

        pub inline fn distSquared(a: *const Vec, b: *const Vec) Scalar {
            return b.sub(a).len();
        }

        pub inline fn dist(a: *const Vec, b: *const Vec) Scalar {
            return math.sqrt(b.sub(a).lenSquared());
        }

        pub inline fn norm(v: *const Vec) Vec {
            const length = v.len();
            if (len > 0.0) {
                return .{ .vec = .{ v.x() / length, v.y() / length } };
            }
        }

        pub inline fn inv(v: *const Vec) Vec {
            return switch (Vec.n) {
                inline 2 => .{ .vec = (vec2(1, 1).vec / v.vec) },
                inline 3 => .{ .vec = (vec3(1, 1, 1).vec / v.vec) },
                else => unreachable,
            };
        }

        pub inline fn neg(v: *const Vec) Vec {
            return switch (Vec.n) {
                inline 2 => .{ .vec = .vec2(-1, -1).vec * v.vec },
                inline 3 => .{ .vec = vec3(-1, -1, -1).vec * v.vec },
                else => unreachable,
            };
        }

        pub inline fn eql(a: *const Vec, b: *const Vec) bool {
            return std.meta.eql(a, b);
        }
    };
}
