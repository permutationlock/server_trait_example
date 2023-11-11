const std = @import("std");
const BaseServer = @import("server.zig").Server;

pub const Server = struct {
    server: BaseServer = .{},

    const Self = @This();
    const Event = BaseServer.Event;

    pub const Handle = BaseServer.Handle;

    pub fn listen(self: *Self, port: u16) !void {
        try self.server.listen(port);
    }

    pub fn poll(
        self: *Self,
        handler: anytype,
        onOpen: fn (@TypeOf(handler), Handle) void,
        onMessage: fn (@TypeOf(handler), Handle, []const u8) void,
        onClose: fn (@TypeOf(handler), Handle) void,
    ) !void {
        try self.server.pollSockets();
        while (self.server.getEvent()) |evt| {
            switch (evt) {
                .open => |handle| onOpen(handler, handle),
                .msg => |msg| onMessage(handler, msg.handle, msg.bytes),
                .close => |handle| onClose(handler, handle),
            }
        }
    }
};
