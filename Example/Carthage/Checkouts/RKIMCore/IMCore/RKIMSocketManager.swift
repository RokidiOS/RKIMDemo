//
//  RKIMSocketManager.swift
//  RKIM
//
//  Created by chzy on 2021/10/28.
//

import Foundation
import RKSocket
import RKLogger

protocol ImSocketDelegate: NSObjectProtocol {
    func identString() -> String
    func rkwebSocket(didReceiveMessageWith string: String)
    func rkwebSocketDidOpen()
    func rkwebSocket(didFailWithError error: Error)
    func rkwebSocket(didCloseWithCode code: Int, reason: String?, wasClean: Bool)
}

class RKIMSocketManager: NSObject {
    
    static let share = RKIMSocketManager()
    
    var delegateArray: [ImSocketDelegate] = []
    
    func addDelegate(_ newDelegate: ImSocketDelegate) {
        delegateArray.append(newDelegate)
    }
    
    func removeDelegate(_ newDelegate: ImSocketDelegate) {
        delegateArray.removeAll (where: { delegate in
            delegate.identString() == newDelegate.identString()
        })
    }
    
    //    wss://im-dev.rokid-inc.com/ws/
    func config(url: String, token: String) {
        RKSocket.share.config(url + token)
        RKSocket.share.delegate = self
    }
    
    /// 开启链接
    func openClient() {
        RKSocket.share.openClient()
    }
    
    /// 关闭连接
    func closeClient() {
        RKSocket.share.closeClient()
    }
    
    
    func sendBeat() {
        try? RKSocket.share.client?.send(string: "")
    }
}


extension RKIMSocketManager: RKSocketDelegate {
    public func rkwebSocket(_ webSocket: RKSocket, didFailWithError error: Error) {
        _ = self.delegateArray.map { delegate in
            delegate.rkwebSocket(didFailWithError: error)
        }
    }
    
    public func rkwebSocketDidOpen(_ webSocket: RKSocket) {
        _ = self.delegateArray.map { delegate in
            delegate.rkwebSocketDidOpen()
        }
    }
    
    public func rkwebSocket(_ webSocket: RKSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        _ = self.delegateArray.map { delegate in
            delegate.rkwebSocket(didCloseWithCode: code, reason: reason, wasClean: wasClean)
        }
    }
    
    public func rkwebSocket(_ webSocket: RKSocket, didReceiveMessage message: Any) {
        
    }
    
    public func rkwebSocket(_ webSocket: RKSocket, didReceiveMessageWith data: Data) {
        
    }
    
    public func rkwebSocket(_ webSocket: RKSocket, didReceiveMessageWith string: String) {
        RKLog("socekt didReceive" + string, .info)
        _ = self.delegateArray.map { delegate in
            delegate.rkwebSocket(didReceiveMessageWith: string)
        }
    }
    
    public func rkwebSocket(_ webSocket: RKSocket, didReceivePingWith data: Data?) {
        
    }
    
    public func rkwebSocket(_ webSocket: RKSocket, didReceivePong pongData: Data?) {
        
    }
    
    
}
