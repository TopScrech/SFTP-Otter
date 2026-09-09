import Foundation
import NIOCore
import NIOPosix
import OSLog

// NIO confines this handler's mutable state to its channel's event loop
nonisolated final class SSHNegotiationLogger: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = ByteBuffer
    
    private static let logger = Logger(subsystem: "SFTPOtter", category: "Connection")
    private let requestID: String
    private var timeout: Scheduled<Void>?
    private var buffer = ByteBuffer()
    private var receivedVersion = false
    private var finished = false
    
    init(requestID: String) {
        self.requestID = requestID
    }
    
    static func inspect(host: String, port: Int, requestID: String) async {
        do {
            let channel = try await ClientBootstrap(group: MultiThreadedEventLoopGroup.singleton)
                .connectTimeout(.seconds(5))
                .channelInitializer { channel in
                    channel.pipeline.addHandler(SSHNegotiationLogger(requestID: requestID))
                }
                .connect(host: host, port: port).get()
            try await channel.closeFuture.get()
        } catch {
            logger.error("event=server_ssh_probe_failed request_id=\(requestID, privacy: .public) error_type=\(String(reflecting: type(of: error)), privacy: .public)")
        }
    }
    
    func channelActive(context: ChannelHandlerContext) {
        let channel = context.channel
        timeout = context.eventLoop.scheduleTask(in: .seconds(5)) {
            channel.close(promise: nil)
        }
        var version = context.channel.allocator.buffer(capacity: 32)
        version.writeString("SSH-2.0-SFTPOtter_Diagnostics\r\n")
        context.writeAndFlush(NIOAny(version), promise: nil)
        context.fireChannelActive()
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        timeout?.cancel()
        context.fireChannelInactive()
    }
    
    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        context.close(promise: nil)
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard !finished else { return }
        let incoming = unwrapInboundIn(data)
        guard buffer.readableBytes + incoming.readableBytes <= 65_536 else {
            finished = true
            return
        }
        buffer.writeImmutableBuffer(incoming)
        if !receivedVersion {
            while let newline = buffer.readableBytesView.firstIndex(of: 10) {
                let length = buffer.readableBytesView.distance(from: buffer.readableBytesView.startIndex, to: newline) + 1
                guard let line = buffer.readString(length: length) else { return }
                if line.hasPrefix("SSH-") {
                    receivedVersion = true
                    break
                }
            }
        }
        guard receivedVersion else { return }
        while let length: UInt32 = buffer.getInteger(at: buffer.readerIndex) {
            guard length >= 2, length <= 65_532 else { finished = true; return }
            guard buffer.readableBytes >= Int(length) + 4 else { return }
            buffer.moveReaderIndex(forwardBy: 4)
            guard let padding: UInt8 = buffer.readInteger(),
                  Int(padding) + 2 <= Int(length),
                  var payload = buffer.readSlice(length: Int(length) - Int(padding) - 1) else {
                finished = true
                return
            }
            buffer.moveReaderIndex(forwardBy: Int(padding))
            guard payload.readInteger(as: UInt8.self) == 20 else { continue }
            finished = true
            guard payload.readBytes(length: 16) != nil else { return }
            var lists: [String] = []
            for _ in 0..<10 {
                guard let count: UInt32 = payload.readInteger(), count <= 32_768,
                      let names = payload.readString(length: Int(count)) else { return }
                // Algorithm identifiers only, never credentials or later encrypted traffic
                lists.append(String(names.filter { $0.isASCII && ($0.isLetter || $0.isNumber || "-_.@,+=".contains($0)) }.prefix(2_048)))
            }
            Self.logger.notice("event=server_ssh_algorithms request_id=\(self.requestID, privacy: .public) kex=\(lists[0], privacy: .public) host_key=\(lists[1], privacy: .public) cipher_in=\(lists[3], privacy: .public) cipher_out=\(lists[2], privacy: .public) mac_in=\(lists[5], privacy: .public) mac_out=\(lists[4], privacy: .public)")
            buffer.clear()
            context.close(promise: nil)
            return
        }
    }
}
