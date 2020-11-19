//
//  Socket.swift
//  WebRTC-Demo
//
//  Created by 文涛 on 2020/11/18.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class Socket: NSObject, WebSocketProvider, GCDAsyncSocketDelegate {
    private var socket: GCDAsyncSocket!
    private var backQueue = DispatchQueue(label: "com.fiture.webRTC", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    private let host: String
    private let port: UInt16
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
        super.init()
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: backQueue)
    }
    
    
    
    var delegate: WebSocketProviderDelegate?
    
    
    //MARK: - WebSocketProviderDelegate
    func connect() {
        do {
            print("socket: 开始连接 \(host):\(port)")
            try self.socket.connect(toHost: host, onPort: port, withTimeout: 5)
        } catch let error {
            print("socket: 开始连接失败 \(error)")
        }
    }
    
    func send(data: Data) {
        socket.write(data, withTimeout: 5, tag: 1)
    }
    
    
    //MARK: - Socket
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("socket: \(#function)")
        self.delegate?.webSocketDidConnect(self)
        sock.readData(withTimeout: -1, tag: 0)
    }
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("socket: \(#function)")
        self.delegate?.webSocket(self, didReceiveData: data)
        sock.readData(withTimeout: -1, tag: tag)
    }
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("socket: \(#function) \(String(describing: err))")
        self.delegate?.webSocketDidDisconnect(self)
    }
    
}
