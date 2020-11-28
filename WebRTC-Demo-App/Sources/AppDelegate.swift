//
//  AppDelegate.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    internal var window: UIWindow?
    private let config = Config.default
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = self.buildMainViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    
    private func buildMainViewController() -> UIViewController {
        let vc = RootViewController()
//        let webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
//        let signalClient = self.buildSignalingClient()
//        let mainViewController = MainViewController(signalClient: signalClient, webRTCClient: webRTCClient)
        let navViewController = UINavigationController(rootViewController: vc)
        if #available(iOS 11.0, *) {
            navViewController.navigationBar.prefersLargeTitles = true
        }
        else {
            navViewController.navigationBar.isTranslucent = false
        }
        return navViewController
    }
    
    private func buildSignalingClient() -> SignalingClient {
        
        // iOS 13 has native websocket support. For iOS 12 or lower we will use 3rd party library.
        let webSocketProvider: WebSocketProvider
        
        switch Config.signalingType {
        case .websocket:
            if #available(iOS 13.0, *) {
                webSocketProvider = NativeWebSocket(url: self.config.signalingServerUrl)
            } else {
                webSocketProvider = StarscreamWebSocket(url: self.config.signalingServerUrl)
            }
        case .socket:
            webSocketProvider = GCDSocket(host: Config.host, port: Config.port)
        case .socketIO:
            webSocketProvider = IOSocket(url: Config.socketIOURL)
        }
        
        return SignalingClient(webSocket: webSocketProvider)
    }
}

