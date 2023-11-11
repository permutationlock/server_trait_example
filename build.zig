const std = @import("std");
const Builder = std.build.Builder;

const Example = struct { name: []const u8, path: []const u8 };
const paths = [_]Example{
    .{ .name = "duck_typing", .path = "examples/duck_typing.zig" },
    .{ .name = "function_parameters", .path = "examples/function_parameters.zig" },
    .{ .name = "traits", .path = "examples/traits.zig" },
    .{ .name = "interfaces", .path = "examples/interfaces.zig" },
    .{ .name = "interface_parameters", .path = "examples/interface_parameters.zig" },
};

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ztrait = b.dependency("ztrait", .{}).module("ztrait");
    const genserver = b.addModule("genserver", .{
        .source_file = .{ .path = "src/genserver.zig" },
        .dependencies = &.{
            .{ .name = "ztrait", .module = ztrait },
        },
    });

    inline for (paths) |example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = .{ .path = example.path },
            .target = target,
            .optimize = optimize
        });
        exe.addModule("ztrait", ztrait);
        exe.addModule("genserver", genserver);
        const run_step = b.step(example.name, &.{});
        run_step.dependOn(&b.addRunArtifact(exe).step);
        b.installArtifact(exe);
    }
}
