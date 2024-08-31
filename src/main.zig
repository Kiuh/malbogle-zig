const std = @import("std");
const clap = @import("clap");

const Allocator = std.mem.Allocator;
const max_file_size_bytes: usize = 5000;

pub fn execute(allocator: Allocator, file: std.fs.File) !void {
    const content = try file.readToEndAlloc(allocator, max_file_size_bytes);
    defer allocator.free(content);
    std.debug.print("\nFile content:\n{s}\n", .{content});
    std.debug.print("File content:\n{any}\n", .{content});
}

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
        try execute(allocator, file);
    } else {
        std.debug.print("There is no specified 'mb' file to execute.", .{});
    }
}
