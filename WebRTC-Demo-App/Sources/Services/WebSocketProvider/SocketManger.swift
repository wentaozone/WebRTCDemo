//
//  SocketManger.swift
//  WebRTC-Demo
//
//  Created by butterfly on 2020/11/27.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import SocketIO

protocol SocketMangerDelegate {
    func socketManger(_ socketManger: SocketManger, didSearchResult:[ClientModel])
}

class SocketManger {
    static let share = SocketManger()
    
    private var socketManger = SocketIO.SocketManager(socketURL: Config.socketIOURL, config: [SocketIOClientOption.compress, .log(false)])
    private var socket: SocketIOClient
    private var socketId = ""
    var delegate: SocketMangerDelegate?
    
    init() {
        socket = socketManger.defaultSocket
        setupHandloer()
    }
    
    func connect(){
        socket.connect()
    }
    
    private func setupHandloer(){
        socket.on(clientEvent: .connect, callback: { (data, ack) in
            print("socket: 连接成功")
            self.didConnected(data: data, ack: ack)
        })
        
        socket.on(clientEvent: .disconnect, callback: { (data, ack) in
            print("socket: 连接断开")
            self.didDisconnected(data: data, ack: ack)
        })
        socket.on("id", callback: { (data, ack) in
            if let id = data.first as? String {
                print("socket: 收到clientId \(id)")
                self.socketId = id
//                self.sendInit()
            }
        })
        socket.on("message", callback: { (data, ack) in
            guard let jsonString = data.first as? String else {
                return
            }
            self.didReceiveMessage(jsonString: jsonString, ack: ack)
        })
        socket.on("searchResult", callback: { (data, ack) in
            guard let jsonString = data.first as? String else {
                return
            }
            self.handleSearchResult(jsonString: jsonString, ack: ack)
        })
    }
    private func didConnected(data: [Any], ack: SocketAckEmitter){
        
    }
    private func didDisconnected(data: [Any], ack: SocketAckEmitter){
        
    }
    private func didReceiveMessage(jsonString: String, ack: SocketAckEmitter){
        
    }
    private func handleSearchResult(jsonString: String, ack: SocketAckEmitter){
        guard let array = [ClientModel].deserialize(from: jsonString) else {
            return
        }
        let items = array.compactMap({$0})
        self.delegate?.socketManger(self, didSearchResult: items)
    }
    
    
    func sendInit(){
        var dic = [String: String]()
        dic["group"] = Config.clientGroup
        dic["clientType"] = Config.clientType.rawValue
        dic["clientId"] = Config.clientId
        self.socket.emit("init", dic)
    }
    
    func searchVirgo() {
        var dic = [String: String]()
        dic["group"] = Config.clientGroup
        dic["clientId"] = Config.clientId
        dic["clientType"] = Config.clientType.rawValue
        socket.emit("search", dic)
    }
    
}



