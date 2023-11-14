const std = @import("std");

const zt = @import("ztrait");
const Interface = zt.Interface;
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

    pub fn poll(
        self: *Self,
        handler: anytype,
        handler_ifc: Interface(PointerChild(@TypeOf(handler)), Handler)
    ) !void {
        try self.server.pollSockets();
        while (self.server.getEvent()) |evt| {
            switch (evt) {
                .open => |handle| handler_ifc.onOpen(handler, handle),
                .msg => |msg| handler_ifc.onMessage(handler, msg.handle, msg.bytes),
                .close => |handle| handler_ifc.onClose(handler, handle),
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
