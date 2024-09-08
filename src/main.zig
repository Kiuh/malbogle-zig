const std = @import("std");
const clap = @import("clap");

const Allocator = std.mem.Allocator;
const max_file_size_bytes: usize = 5000;

const Trit = struct {
    data: [10]u3 = .{0} ** 10,

    pub fn set(self: *Trit, v: u8) void {
        var val = v;
        var pos_to_fill: u8 = 0;

        var temp_data: [10]u3 = .{0} ** 10;

        while (val >= 3) {
            const tail: u3 = @intCast(val % 3);
            temp_data[pos_to_fill] = tail;
            val = (val - tail) / 3;
            pos_to_fill += 1;
        }
        temp_data[pos_to_fill] = @intCast(val);
        pos_to_fill += 1;

        self.clear();

        for (0..pos_to_fill) |i| {
            self.data[9 - i] = temp_data[i];
        }

        //std.debug.print("In: {any} - {c}\n", .{ v, v });
        //std.debug.print("Res: {any}\n", .{self.data});
    }

    pub fn toU8(self: *Trit) u8 {
        var out: u8 = 0;
        var mul = 1;
        for (0..10) |i| {
            out += self.data[9 - i] * mul;
            mul *= 3;
        }
        return out;
    }

    pub fn toU16(self: *Trit) u16 {
        var out: u16 = 0;
        var mul = 1;
        for (0..10) |i| {
            out += self.data[9 - i] * mul;
            mul *= 3;
        }
        return out;
    }

    pub fn toOp(self: *Trit, pos: Trit) u8 {
        return (self.toU16() + pos.toU16()) % 94;
    }

    pub fn clear(self: *Trit) void {
        for (0..10) |i| {
            self.data[i] = 0;
        }
    }

    pub fn isValidOp(self: *Trit) bool {
        for (0..10) |i| {
            _ = i; // autofix
            const val = self.toU16();
            if (val == 4 or val == 5 or val == 23 or val == 39 or val == 40 or val == 62 or val == 68 or val == 81)
                return true;
        }
    }
};

const VM = struct {
    mem: [59_049]Trit = .{.{}} ** 59_049,
    a: Trit = .{},
    c: Trit = .{},
    d: Trit = .{},

    pub fn init() VM {
        return VM{};
    }

    pub fn loadProgram(self: *VM, program: []const u8) !void {
        std.debug.print("In program: \n\n{s}\n", .{program});
        for (program, 0..) |value, i| self.mem[i].set(value); // Fill with program
        for (program.len - 1..self.mem.len) |i| self.mem[i] = self.crz(i - 2, i - 1); // Fill rest with crazy op
        std.debug.print("Mem: \n\n{any}\n", .{self.mem});
    }

    fn validate(self: *VM) bool {
        _ = self; // autofix
        return true;
    }

    fn crz(self: *VM, in1: usize, in2: usize) Trit {
        const inT1 = self.mem[in1];
        const inT2 = self.mem[in2];
        var out = Trit{};
        for (0..10) |i| {
            out.data[i] = crz_one(inT1.data[i], inT2.data[i]);
        }
        return out;
    }

    fn crz_one(f: u3, s: u3) u3 {
        if (f == 0) {
            if (s == 0) {
                return 1;
            } else {
                return 0;
            }
        }

        if (f == 1) {
            if (s == 0) {
                return 1;
            } else if (s == 1) {
                return 0;
            } else {
                return 2;
            }
        }

        if (f == 2) {
            if (s == 0) {
                return 2;
            } else if (s == 1) {
                return 2;
            } else {
                return 0;
            }
        }

        return 0;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Init clap
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-f, --file <str>      Specify '.mb' file to execute.
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    // Process help argument
    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }

    if (res.args.file) |file_path| {
        std.debug.print("File path:\n{s}\n", .{file_path});
        const file = try std.fs.cwd().openFile(file_path, .{});

        const content = try file.readToEndAlloc(allocator, max_file_size_bytes);
        defer allocator.free(content);

        var vm = VM.init();
        try vm.loadProgram(content);
    } else {
        std.debug.print("There is no specified 'mb' file to execute.", .{});
    }
}
