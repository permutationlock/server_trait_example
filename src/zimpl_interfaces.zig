const std = @import("std");

const zimpl = @import("zimpl");
const Impl = zimpl.Impl;

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
        handler_impl: Impl(@TypeOf(handler), Handler),
    ) !void {
        try self.server.pollSockets();
        while (self.server.getEvent()) |evt| {
            switch (evt) {
                .open => |handle| handler_impl.onOpen(handler, handle),
                .msg => |msg| handler_impl.onMessage(
                    handler,
                    msg.handle,
                    msg.bytes,
                ),
                .close => |handle| handler_impl.onClose(handler, handle),
            }
        }
    }

    pub fn Handler(comptime Type: type) type {
        return struct {
            onOpen: fn (Type, Handle) void,
            onMessage: fn (Type, Handle, []const u8) void,
            onClose: fn (Type, Handle) void,
        };
    }
};
