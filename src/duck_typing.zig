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

    pub fn poll(self: *Self, handler: anytype) !void {
        try self.server.pollSockets();
        while (self.server.getEvent()) |evt| {
            switch (evt) {
                .open => |handle| handler.onOpen(handle),
                .msg => |msg| handler.onMessage(msg.handle, msg.bytes),
                .close => |handle| handler.onClose(handle),
            }
        }
    }
};
