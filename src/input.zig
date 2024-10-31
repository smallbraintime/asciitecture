const std = @import("std");
const x11 = @cImport(@cInclude("X11/Xlib.h"));

pub const Input = struct {
    _backend: InputBackend,

    pub fn init() !Input {
        // if (std.posix.getenv("DISPLAY") != null) {
        if (false) {
            return Input{ ._backend = .{ .x11 = try X11Input.init() } };
        } else {
            return Input{ ._backend = .{ .std = StdInput.init() } };
        }
    }

    pub fn deinit(self: *Input) void {
        switch (self._backend) {
            .x11 => |*be| {
                be.deinit() catch {
                    @panic("Failed to deinit X11Input");
                };
            },
            else => {},
        }
    }

    pub fn nextEvent(self: *Input) KeyEvent {
        switch (self._backend) {
            .x11 => |*be| {
                return be.nextEvent() catch |err| {
                    @panic(@errorName(err));
                };
            },
            .std => |*be| {
                return be.nextEvent() catch |err| {
                    @panic(@errorName(err));
                };
            },
        }
    }
};

const InputBackend = union(enum) {
    x11: X11Input,
    std: StdInput,
};

pub const KeyEvent = union(enum) {
    press: KeyInput,
    release: KeyInput,
};

pub const KeyInput = struct {
    key: u21,
    ctrl: bool = false,
    shift: bool = false,
    alt: bool = false,

    pub fn eql(a: *const KeyInput, b: *const KeyInput) bool {
        return std.meta.eql(a.key, b.key);
    }
};

const X11Input = struct {
    _dpy: *x11.Display,
    _ev: x11.XEvent = undefined,

    pub fn init() !X11Input {
        var dpy: *x11.Display = undefined;
        if (x11.XOpenDisplay(null)) |new_dpy| {
            dpy = new_dpy;
        } else {
            return error.X11Error;
        }
        _ = x11.XAutoRepeatOff(dpy);
        if (x11.XGrabKeyboard(
            dpy,
            x11.DefaultRootWindow(dpy),
            x11.True,
            x11.GrabModeAsync,
            x11.GrabModeAsync,
            x11.CurrentTime,
        ) > 0) {
            return error.X11Error;
        }
        return X11Input{ ._dpy = dpy };
    }

    pub fn nextEvent(self: *X11Input) !KeyEvent {
        if (x11.XPending(self._dpy) > 0) {
            _ = x11.XNextEvent(self._dpy, &self._ev);
            switch (self._ev.type) {
                x11.KeyPress => {
                    const key_code = @as(*x11.XKeyPressedEvent, @ptrCast(&self._ev)).keycode;
                    const str_key = x11.XKeysymToString(x11.XKeycodeToKeysym(self._dpy, @intCast(key_code), 0));
                    return KeyEvent{ .press = .{ .key = try std.unicode.utf8Decode(std.mem.span(str_key)) } };
                },
                x11.KeyRelease => {
                    const key_code = @as(*x11.XKeyReleasedEvent, @ptrCast(&self._ev)).keycode;
                    const str_key = x11.XKeysymToString(x11.XKeycodeToKeysym(self._dpy, @intCast(key_code), 0));
                    return KeyEvent{ .release = .{ .key = try std.unicode.utf8Decode(std.mem.span(str_key)) } };
                },
                else => return KeyEvent{ .press = .{ .key = Key.none } },
            }
        } else {
            return KeyEvent{ .press = .{ .key = Key.none } };
        }
    }

    pub fn deinit(self: *X11Input) !void {
        _ = x11.XAutoRepeatOn(self._dpy);
        _ = x11.XUngrabKeyboard(self._dpy, x11.CurrentTime);
        _ = x11.XCloseDisplay(self._dpy);
    }
};

const StdInput = struct {
    stdin: std.fs.File.Reader,

    pub fn init() StdInput {
        return StdInput{
            .stdin = std.io.getStdIn().reader(),
        };
    }

    pub fn nextEvent(self: *StdInput) !KeyEvent {
        var buf: [4]u8 = undefined;
        const c = try self.stdin.read(&buf);
        const view = try std.unicode.Utf8View.init(buf[0..c]);
        var iter = view.iterator();

        var input = KeyInput{ .key = undefined };
        if (iter.nextCodepoint()) |c0| switch (c0) {
            '\x1b' => {
                if (iter.nextCodepoint()) |c1| switch (c1) {
                    '[' => {
                        switch (buf[2]) {
                            'A' => input.key = Key.up,
                            'B' => input.key = Key.down,
                            'C' => input.key = Key.right,
                            'D' => input.key = Key.left,
                            else => input.key = Key.none,
                        }
                    },
                    else => input.key = Key.none,
                } else {
                    input.key = Key.none;
                }
            },
            else => input.key = c0,
        } else {
            input.key = Key.none;
        }
        return KeyEvent{ .press = input };
    }
};

pub const Key = struct {
    pub const none: u8 = 0;
    pub const tab: u8 = 0x09;
    pub const enter: u8 = 0x0D;
    pub const escape: u8 = 0x1B;
    pub const space: u8 = 0x20;
    pub const backspace: u8 = 0x08;
    pub const insert: u8 = 0x2D;
    pub const delete: u8 = 0x2E;
    pub const left: u8 = 0x25;
    pub const right: u8 = 0x27;
    pub const up: u8 = 0x26;
    pub const down: u8 = 0x28;
    pub const page_up: u8 = 0x21;
    pub const page_down: u8 = 0x22;
    pub const home: u8 = 0x24;
    pub const end: u8 = 0x23;
    pub const caps_lock: u8 = 0x14;
    pub const scroll_lock: u8 = 0x91;
    pub const num_lock: u8 = 0x90;
    pub const print_screen: u8 = 0x2C;
    pub const pause: u8 = 0x13;
    pub const menu: u8 = 0x5D;
    pub const f1: u8 = 0x70;
    pub const f2: u8 = 0x71;
    pub const f3: u8 = 0x72;
    pub const f4: u8 = 0x73;
    pub const f5: u8 = 0x74;
    pub const f6: u8 = 0x75;
    pub const f7: u8 = 0x76;
    pub const f8: u8 = 0x77;
    pub const f9: u8 = 0x78;
    pub const f10: u8 = 0x79;
    pub const f11: u8 = 0x7A;
    pub const f12: u8 = 0x7B;
};

// deprecated and overkilled previous idea
const libudev = @cImport(@cInclude("libudev.h"));
fn findKeyboard() ?[]const u8 {
    var devnode: [*c]const u8 = undefined;
    var udev: *libudev.udev = undefined;
    var enumerate: *libudev.udev_enumerate = undefined;
    var devices: *libudev.udev_list_entry = undefined;
    var dev: *libudev.udev_device = undefined;

    if (libudev.udev_new()) |ud| udev = ud;
    if (libudev.udev_enumerate_new(udev)) |en| enumerate = en;
    _ = libudev.udev_enumerate_add_match_property(enumerate, "ID_INPUT_KEYBOARD", "1");
    _ = libudev.udev_enumerate_scan_devices(enumerate);
    if (libudev.udev_enumerate_get_list_entry(enumerate)) |devi| devices = devi;

    var entry: ?*libudev.udev_list_entry = devices;
    while (entry != null) {
        var path: [*c]const u8 = undefined;
        path = libudev.udev_list_entry_get_name(entry);
        if (libudev.udev_device_new_from_syspath(udev, path)) |de| dev = de;
        devnode = libudev.udev_device_get_devnode(dev);
        if (devnode != null) {
            break;
        }
        _ = libudev.udev_device_unref(dev);
        entry = libudev.udev_list_entry_get_next(entry);
    }

    _ = libudev.udev_enumerate_unref(enumerate);
    _ = libudev.udev_unref(udev);

    if (devnode == null) return null;
    return std.mem.span(devnode);
}
