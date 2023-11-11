const std = @import("std");
const builtin = @import("builtin");

const poll = if (builtin.os.tag == .windows) std.os.windows.poll
    else std.os.poll;
const POLLIN = if (builtin.os.tag == .windows)
    (std.os.windows.POLL.RDNORM | std.os.windows.POLL.RDBAND)
else
    std.os.POLL.IN;
const INV_SOCKET = if (builtin.os.tag == .windows)
    std.os.windows.ws2_32.INVALID_SOCKET
else
    -1;
const inv_pollfd: std.os.pollfd = .{
    .fd = INV_SOCKET,
    .events = 0,
    .revents = 0,
};

const max_conns = 4;

pub const Server = struct {
    pollfds: [max_conns + 1]std.os.pollfd =
        [1]std.os.pollfd{ inv_pollfd } ** (max_conns + 1),
    index: u32 = 0,
    events: usize = 0,
    buffer: [256]u8 = undefined,

    const Self = @This();
    
    const Connection = struct {
        open: bool,
        socket: std.os.socket_t,
    };

    pub const Handle = u32;

    pub const Event = union(enum) {
        open: Handle,
        msg: struct { handle: Handle, bytes: []const u8 },
        close: Handle,
    };

    fn close(self: *Self, handle: Handle) void {
        if (self.pollfds[handle].fd == INV_SOCKET) {
            return;
        }
        std.os.closeSocket(self.pollfds[handle].fd);
        self.pollfds[handle].fd = INV_SOCKET;
    }

    pub fn pollSockets(self: *Self) !void {
        self.events = try poll(&self.pollfds, 0);
        self.index = 0;
    }

    pub fn getEvent(self: *Self) ?Event {
        var index = self.index;
        while (index < self.pollfds.len) : (index += 1) {
            if (self.events == 0) {
                return null;
            }
            if (self.pollfds[index].fd != INV_SOCKET) {
                if (self.pollfds[index].revents == 0) {
                    continue;
                }
                self.events -= 1;
                if (self.pollfds[index].revents & POLLIN != 0) {
                    break;
                }
                self.close(index);
            }
        }
        self.index = index + 1;

        if (index >= self.pollfds.len) {
            return null;
        }        

        if (index == self.pollfds.len - 1) {
            var next_handle: Handle = 0;
            for (self.pollfds[0..(self.pollfds.len-1)]) |*pfd| {
                if (pfd.fd == INV_SOCKET) {
                    break;
                }
                next_handle += 1;
            }
            var dest: std.os.sockaddr = undefined;
            var socksize: std.os.socklen_t = 0;
            const socket = std.os.accept(
                self.pollfds[self.pollfds.len - 1].fd,
                &dest,
                &socksize,
                0
            ) catch return null;

            if (next_handle == self.pollfds.len - 1) {
                std.os.closeSocket(socket);
                return null;
            }

            self.pollfds[next_handle] = .{
                .fd = socket,
                .events = POLLIN,
                .revents = 0,
            };
            return .{ .open = next_handle };
        }

        const len = std.os.recv(self.pollfds[index].fd, &self.buffer, 0)
            catch 0;

        if (len == 0) {
            self.close(index);
            return .{ .close = index };
        }

        return .{
            .msg = .{ .handle = index, .bytes = self.buffer[0..len], },
        };
    }

    pub fn listen(self: *Self, port: u16) !void {
        var addr = (std.net.Ip4Address.parse("0.0.0.0", port)
            catch unreachable).sa;
        const ls = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
        errdefer std.os.closeSocket(ls);

        try std.os.bind(ls, @ptrCast(&addr), @sizeOf(std.os.sockaddr));
        try std.os.listen(ls, @truncate(32));
        self.pollfds[self.pollfds.len - 1] = .{
            .fd = ls,
            .events = POLLIN,
            .revents = 0,
        };
    }
};

test {
    std.testing.refAllDecls(@This());
}
