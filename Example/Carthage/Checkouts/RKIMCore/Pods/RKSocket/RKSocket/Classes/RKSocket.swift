//
//  RKSocket.swift
//  SwiftSocket
//
//  Created by chzy on 2021/10/28.
//

import Foundation
import SocketRocket

public protocol RKSocketDelegate: NSObjectProtocol {
//   @objc optional
    /// 初始化失败
    func rkwebSocket(_ webSocket: RKSocket, didFailWithError error: Error)
    
    /// 连接成功回调
    func rkwebSocketDidOpen(_ webSocket: RKSocket)
    
    ///断开链接
    func rkwebSocket(_ webSocket: RKSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool)
    
    /// 收到meesage消息
    func rkwebSocket(_ webSocket: RKSocket, didReceiveMessage message: Any)

    /// 收到 data 消息
    func rkwebSocket(_ webSocket: RKSocket, didReceiveMessageWith data: Data)
    
    /// 收到string 消息
    func rkwebSocket(_ webSocket: RKSocket, didReceiveMessageWith string: String)
    
    /// 收到ping data
    func rkwebSocket(_ webSocket: RKSocket, didReceivePingWith data: Data?)
    
    /// 收到pong data
    func rkwebSocket(_ webSocket: RKSocket, didReceivePong pongData: Data?)
    
}

public class RKSocket: NSObject {
    /// socket回调用
    public weak var delegate: RKSocketDelegate?
    
    public static let share = RKSocket()
    /// client 客户端
    public var client: SRWebSocket?
    
    /// 配置Socket ws url
    /// - Parameter requestString: 请求url （string）
    public func config(_ requestString: String) {
        let url = URL(string: requestString)
        guard let url = url else { return }
        client = SRWebSocket(url: url)
        client?.delegate = self
    }
    
    /// 开启链接
    public func openClient() {
        client?.open()
    }
    
    /// 关闭连接
    public func closeClient() {
        client?.close()
    }
    
    
}

extension RKSocket: SRWebSocketDelegate {
    /// 初始化失败
    public func webSocket(_ webSocket: SRWebSocket, didFailWithError error: Error) {
        delegate?.rkwebSocket(self, didFailWithError: error)
    }
    
    /// 连接成功回调
    public func webSocketDidOpen(_ webSocket: SRWebSocket) {
        delegate?.rkwebSocketDidOpen(self)
    }
    
    ///断开链接
    public func webSocket(_ webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        delegate?.rkwebSocket(self, didCloseWithCode: code, reason: reason, wasClean: wasClean)
    }
    
    /// 收到meesage消息
    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessage message: Any) {
        delegate?.rkwebSocket(self, didReceiveMessage: message)
    }

    /// 收到 data 消息
    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessageWith data: Data) {
        delegate?.rkwebSocket(self, didReceiveMessageWith: data)
    }
    
    /// 收到string 消息
    public func webSocket(_ webSocket: SRWebSocket, didReceiveMessageWith string: String) {
        delegate?.rkwebSocket(self, didReceiveMessageWith: string)
    }
    /// 发送消息时 文本帧是否转换为string default YES
    public func webSocketShouldConvertTextFrameToString(_ webSocket: SRWebSocket) -> Bool {
        return true
    }
    
    /// 收到ping data
    public func webSocket(_ webSocket: SRWebSocket, didReceivePingWith data: Data?) {
        delegate?.rkwebSocket(self, didReceivePingWith: data)
    }
    /// 收到pong data
    public func webSocket(_ webSocket: SRWebSocket, didReceivePong pongData: Data?) {
        delegate?.rkwebSocket(self, didReceivePong: pongData)
    }
    
}

