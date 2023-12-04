const std = @import("std");
const log = std.log.scoped(.log_server);

const run_example = @import("run_example.zig");

const genserver = @import("genserver");
const Server = genserver.zimpl_interfaces.Server;
const Handle = Server.Handle;

pub const LogHandler = struct {
    const Self = @This();

    count: usize = 0,

    pub fn onOpen(_: *Self, handle: Handle) void {
        log.info("connection {} opened", .{handle});
    }

    pub fn onMessage(self: *Self, handle: Handle, msg: []const u8) void {
        log.info("{d}: client {d} sent '{s}'", .{ self.count, handle, msg });
        self.count += 1;
    }

    pub fn onClose(_: *Self, handle: Handle) void {
        log.info("connection {} closed", .{handle});
    }
};

pub fn runServer(port: u16) !void {
    var server = Server{};
    var handler = LogHandler{};
    try server.listen(port);
    while (true) {
        try server.poll(&handler, .{});
    }
}

pub fn main() !void {
    try run_example.run(runServer, 8000);
}
