//
//  Config.swift
//  WebRTC-Demo
//
//  Created by Stasel on 30/01/2019.
//  Copyright © 2019 Stasel. All rights reserved.
//

import Foundation

// Set this to the machine's address which runs the signaling server

//fileprivate let defaultSignalingServerUrl = URL(string: "ws://10.0.0.15:8080")!
//fileprivate let defaultSignalingServerUrl = URL(string: "ws://10.1.3.40:8080")!

// We use Google's public stun servers. For production apps you should deploy your own stun/turn servers.
fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",
                                     "stun:stun3.l.google.com:19302",
                                     "stun:stun4.l.google.com:19302"]
let defalutTurnServers = ["turn:139.155.3.157"]
let defaultTurnUsername = "test"
let defaultTurnPassword = "test"

struct Config {
    let signalingServerUrl: URL
    let webRTCIceServers: [String]
    
    static let signalingType = SignalingServerType.socketIO
    
    static let webSocketURL = URL(string: "ws://10.1.3.40:8080")!
    
    static let host = "localhost"
    static let port = UInt16(3000)
    
//    static let socketIOURL = URL(string: "http://192.168.0.108:3000")!
    static let socketIOURL = URL(string: "http://139.155.3.157:3000")!
    
    static let `default` = Config(signalingServerUrl: webSocketURL, webRTCIceServers: defaultIceServers)
}
extension Config {
    enum SignalingServerType {
        case websocket
        case socket
        case socketIO
    }
}
