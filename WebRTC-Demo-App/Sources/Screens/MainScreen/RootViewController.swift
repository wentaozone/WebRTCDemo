//
//  RootViewController.swift
//  WebRTC-Demo
//
//  Created by 文涛 on 2020/11/27.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    @IBOutlet private var switchBtn: UISwitch!
    @IBOutlet private var clientIdTf: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    @IBAction func start(_ sender:UIButton){
        Config.clientId = clientIdTf.text!
        Config.clientType = switchBtn.isOn ? .taurus : .virgo
        self.buildMainViewController()
    }
    
    private func buildMainViewController() {
        let webRTCClient = WebRTCClient(iceServers: Config.default.webRTCIceServers)
        let signalClient = self.buildSignalingClient()
        let mainViewController = MainViewController(signalClient: signalClient, webRTCClient: webRTCClient)
        
        self.navigationController?.pushViewController(mainViewController, animated: true)
    }
    
    private func buildSignalingClient() -> SignalingClient {
        
        // iOS 13 has native websocket support. For iOS 12 or lower we will use 3rd party library.
        let webSocketProvider: WebSocketProvider
        
        switch Config.signalingType {
        case .websocket:
            if #available(iOS 13.0, *) {
                webSocketProvider = NativeWebSocket(url: Config.default.signalingServerUrl)
            } else {
                webSocketProvider = StarscreamWebSocket(url: Config.default.signalingServerUrl)
            }
        case .socket:
            webSocketProvider = Socket(host: Config.host, port: Config.port)
        case .socketIO:
            webSocketProvider = SocketIO(url: Config.socketIOURL)
        }
        
        return SignalingClient(webSocket: webSocketProvider)
    }
}
