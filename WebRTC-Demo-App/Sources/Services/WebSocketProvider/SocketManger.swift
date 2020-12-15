//
//  SocketManger.swift
//  WebRTC-Demo
//
//  Created by butterfly on 2020/11/27.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import SocketIO
import WebRTC

protocol SocketMangerDelegate {
    func socketManger(_ socketManger: SocketManger, didSearchResult:[ClientModel])
    
    func socketManger(_ socketManger: SocketManger, didReceiveMessage: [String: AnyObject])
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
            guard let data = data.first as? [String: AnyObject] else {
                return
            }
            self.didReceiveMessage(dic: data, ack: ack)
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
    private func didReceiveMessage(dic: [String: AnyObject], ack: SocketAckEmitter){
        guard let delegate = self.delegate else {return}
        delegate.socketManger(self, didReceiveMessage: dic)
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
    
    func sendCandidate(to:String, from:String, iceCandidate:IceCandidate){
        var payload = [String: AnyObject]()
        payload["label"] = iceCandidate.sdpMLineIndex as AnyObject
        payload["id"] = iceCandidate.sdpMid as AnyObject
        payload["candidate"] = iceCandidate.sdp as AnyObject
        sendMessage(to: to, from: from, type: "candidate", payload: payload)
    }
    func sendSDP(from:String, to:String, sdp:SessionDescription){
        var payload = [String: AnyObject]()
        payload["type"] = sdp.type.rawValue as AnyObject
        payload["sdp"] = sdp.sdp as AnyObject
        sendMessage(to: to, from: from, type: sdp.type.rawValue.lowercased(), payload: payload)
    }
    private func sendMessage(to: String, from:String, type: String, payload: [String: AnyObject]){
        var dic = [String: AnyObject]()
        dic["to"] = to as AnyObject
        dic["type"] = type as AnyObject
        dic["payload"] = payload as AnyObject
        dic["from"] = from as AnyObject
        dic["clientType"] = Config.clientType.rawValue as AnyObject
        dic["group"] = Config.clientGroup as AnyObject
        
        socket.emit("message", dic)
    }
    
}



