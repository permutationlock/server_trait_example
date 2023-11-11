const std = @import("std");

pub fn run(comptime runServer: anytype, comptime port: u16) !void {
    const server_thread = try std.Thread.spawn(.{}, runServer, .{ port });
    server_thread.detach();

    var addr = (std.net.Ip4Address.parse("127.0.0.1", port)
        catch unreachable).sa;
    const msg = "ground control to major tom";
    const socket = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
    errdefer std.os.closeSocket(socket);
    var connected: bool = false;

    var last = std.time.Instant.now() catch unreachable;
    while (true) { 
        var current = std.time.Instant.now() catch unreachable;
        if (current.since(last) > 1000 * 1000 * 1000) {
            if (!connected) {
                try std.os.connect(
                    socket,
                    @ptrCast(&addr),
                    @sizeOf(std.os.sockaddr.in)
                );
                connected = true;
            }

            const len = try std.os.send(socket, msg, 0);
            if (len < msg.len) {
                return error.SendFailed;
            }

            last = current;
        }
    }
}
