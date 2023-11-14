const std = @import("std");

const zt = @import("ztrait");
const where = zt.where;
const implements = zt.implements;
const PointerChild = zt.PointerChild;

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
        comptime where(PointerChild(@TypeOf(handler)), implements(Handler));
        try self.server.pollSockets();
        while (self.server.getEvent()) |evt| {
            switch (evt) {
                .open => |handle| handler.onOpen(handle),
                .msg => |msg| handler.onMessage(msg.handle, msg.bytes),
                .close => |handle| handler.onClose(handle),
            }
        }
    }

    pub fn Handler(comptime Type: type) type {
        return struct {
            pub const onOpen = fn (*Type, Handle) void;
            pub const onMessage = fn (*Type, Handle, []const u8) void;
            pub const onClose = fn (*Type, Handle) void;
        };
    }
};
