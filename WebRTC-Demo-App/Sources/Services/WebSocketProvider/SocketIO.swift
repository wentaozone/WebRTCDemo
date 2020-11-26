//
//  SocketIO.swift
//  WebRTC-Demo
//
//  Created by butterfly on 2020/11/19.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import Foundation
import SocketIO
import WebRTC

class SocketIO: NSObject, WebSocketProvider {
    var delegate: WebSocketProviderDelegate?
    
    private var url: URL
    private var socketManger: SocketManager?
    private var socket: SocketIOClient?
    
    private var fromUid = ""
    private var clientId = ""
    private let encoder = JSONEncoder()
    private var otherClientIds = [String]()

    init(url: URL) {
        self.url = url
        
        socketManger = SocketManager(socketURL: url, config: [.compress, .log(false)])
        socket = socketManger?.defaultSocket
    }
    
    
    //MARK: WebSocketProvider
    func connect() {
        socket?.on(clientEvent: .connect, callback: { (data, ack) in
            print("socketIO: 连接成功")
            self.delegate?.webSocketDidConnect(self)
        })
        socket?.on(clientEvent: .disconnect, callback: { (data, ack) in
            print("socketIO: 连接断开")
            self.otherClientIds.removeAll()
            self.delegate?.webSocket(self, didRecevied: self.otherClientIds)
            self.delegate?.webSocketDidDisconnect(self)
        })
        socket?.on("message", callback: { (array, ack) in
            guard let dic = array.first as? [String: AnyObject] else {
                return
            }
            guard let from = dic["from"] as? String,
                  let type = dic["type"] as? String else {
                return
            }
            
            print("socketIO: 收到from \(from) type: \(type)")
            self.fromUid = from
            
            if self.otherClientIds.contains(self.fromUid) {
                return
            }
            self.otherClientIds.append(self.fromUid)
            self.delegate?.webSocket(self, didRecevied: self.otherClientIds)
            
            var payload = [String: AnyObject]()
            if type != "init" {
                payload = dic["payload"] as! [String: AnyObject]
            }
            switch type {
            case "init":
                self.onReceiveInit(fromUid: from)
            case "offer":
                self.onReceiveOffer(fromUid: from, payload: payload)
            case "answer":
                self.onReceiveAnswer(fromUid: from, payload: payload)
            case "candidate":
                self.onReceiveCandidate(fromUid: from, payload: payload)
            default:
                print("xxx")
            }
        })
        socket?.on("id", callback: { (array, ack) in
            if let id = array.first as? String {
                print("socketIO: 收到clientId \(id)")
                self.clientId = id
                self.delegate?.webSocket(self, didInit: id)
            }
            
            self.socket?.emit("init", "")
        })
        
        socket?.connect()
    }
    
    private let decoder = JSONDecoder()
    func send(data: Data) {
        let message: Message
        do {
            message = try self.decoder.decode(Message.self, from: data)
        }
        catch {
            debugPrint("Warning: Could not decode incoming message: \(error)")
            return
        }
        
        switch message {
        case .candidate(let iceCandidate):
            print("send data candidate: \(iceCandidate)")
            var payload = [String: AnyObject]()
            payload["label"] = iceCandidate.sdpMLineIndex as AnyObject
            payload["id"] = iceCandidate.sdpMid as AnyObject
            payload["candidate"] = iceCandidate.sdp as AnyObject
            sendMessage(to: fromUid, type: "candidate", payload: payload)
        case .sdp(let sdp):
            print("send data sdp: \(sdp)")
            var payload = [String: AnyObject]()
            payload["type"] = sdp.type.rawValue as AnyObject
            payload["sdp"] = sdp.sdp as AnyObject
            sendMessage(to: fromUid, type: sdp.type.rawValue.lowercased(), payload: payload)
        }
    }
    
    private func sendMessage(to: String, type: String, payload: [String: AnyObject]){
        var dic = [String: AnyObject]()
        dic["to"] = to as AnyObject
        dic["type"] = type as AnyObject
        dic["payload"] = payload as AnyObject
        dic["from"] = clientId as AnyObject
        
        socket?.emit("message", dic)
    }
    
    
    
    private func onReceiveInit(fromUid: String){
        
    }
    private func onReceiveOffer(fromUid: String, payload: [String: AnyObject]){
        if let sdpDesp =  payload["sdp"] as? String{
            
            let rtcSdp = RTCSessionDescription(type: .offer, sdp: sdpDesp)
            let sdp  = SessionDescription(from: rtcSdp)
            let msg = Message.sdp(sdp)
            
            do {
                let dataMessage = try self.encoder.encode(msg)
                self.delegate?.webSocket(self, didReceiveData: dataMessage)
            } catch  {
                
            }
        }
    }
    private func onReceiveAnswer(fromUid: String, payload: [String: AnyObject]){
        if let sdpDesp =  payload["sdp"] as? String{
            
            let rtcSdp = RTCSessionDescription(type: .answer, sdp: sdpDesp)
            let sdp  = SessionDescription(from: rtcSdp)
            let msg = Message.sdp(sdp)
            
            do {
                let dataMessage = try self.encoder.encode(msg)
                self.delegate?.webSocket(self, didReceiveData: dataMessage)
            } catch  {
                
            }
        }
    }
    private func onReceiveCandidate(fromUid: String, payload: [String: AnyObject]){
        if let id = payload["id"] as? String,
           let label = payload["label"] as? Int32,
           let candidate =  payload["candidate"] as? String{

            let rtcIceCandiate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: label, sdpMid: id)
            let iceCandiate = IceCandidate(from: rtcIceCandiate)
            let msg = Message.candidate(iceCandiate)
            
            do {
                let dataMessage = try self.encoder.encode(msg)
                self.delegate?.webSocket(self, didReceiveData: dataMessage)
            } catch  {
                
            }
        }
    }
    
   
}
