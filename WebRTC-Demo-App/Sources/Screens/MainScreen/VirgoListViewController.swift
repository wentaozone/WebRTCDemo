//
//  VirgoListViewController.swift
//  WebRTC-Demo
//
//  Created by 文涛 on 2020/11/27.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit
import HandyJSON

struct ClientModel: HandyJSON {
    
    var groupId = ""
    var type = ClientType.taurus
    var id = ""
    
    
    enum ClientType: String, HandyJSONEnum {
        case virgo
        case taurus
    }
}

class VirgoListViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    private var dataArray = [ClientModel]()
    private let webRTCClient = WebRTCClient(iceServers: Config.default.webRTCIceServers)
    private var signalClient: SignalingClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        signalClient = buildSignalingClient()
        SocketManger.share.delegate = self
        SocketManger.share.searchVirgo()
    }
    deinit {
        self.removeObservers()
    }
    
    private var observers = [NSObjectProtocol]()
    private func addObservers(){
        NotificationCenter.default.addObserver(forName: Notification_webRTCClieentDidDiscovery, object: nil, queue: nil) { [weak self] (notify) in
            guard let self = self else {return}
            self.setupUI()
            
        }
    }
    private func removeObservers(){
        for token in observers {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    
    private func setupUI(){
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    
    private func buildSignalingClient() -> SignalingClient {
        let webSocketProvider: WebSocketProvider
        
        switch Config.signalingType {
        case .websocket:
            if #available(iOS 13.0, *) {
                webSocketProvider = NativeWebSocket(url: Config.default.signalingServerUrl)
            } else {
                webSocketProvider = StarscreamWebSocket(url: Config.default.signalingServerUrl)
            }
        case .socket:
            webSocketProvider = GCDSocket(host: Config.host, port: Config.port)
        case .socketIO:
            webSocketProvider = IOSocket(url: Config.socketIOURL)
        }
        
        return SignalingClient(webSocket: webSocketProvider)
    }
}

extension VirgoListViewController: SocketMangerDelegate {
    func socketManger(_ socketManger: SocketManger, didSearchResult: [ClientModel]) {
        self.dataArray = didSearchResult
        tableView.reloadData()
    }
    
    func socketManger(_ socketManger: SocketManger, didReceiveMessage: [String : AnyObject]) {
        
        
        
    }
}

extension VirgoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = self.dataArray[indexPath.row]
        
        cell.textLabel?.text = item.id
        return cell
    }
}
extension VirgoListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.dataArray[indexPath.row]
        webRTCClient.offer { (rtcSdp) in
            let sdp = SessionDescription(from: rtcSdp)
            SocketManger.share.sendSDP(from: Config.clientId, to: item.id, sdp: sdp)
        }
    }
}
