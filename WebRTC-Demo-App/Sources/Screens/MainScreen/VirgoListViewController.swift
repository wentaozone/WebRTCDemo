//
//  VirgoListViewController.swift
//  WebRTC-Demo
//
//  Created by 文涛 on 2020/11/27.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit
import HandyJSON
import WebRTC
import Toast_Swift

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
    private var peerData: ClientModel?
    
    private var status = RTCIceConnectionState.count
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var sendDataBtn: UIButton!
    @IBOutlet private var sendTextView: UITextView!
    @IBOutlet private var respStatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        SocketManger.share.delegate = self
        SocketManger.share.searchVirgo()
        webRTCClient.delegate = self
        webRTCClient.speakerOff()
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
        sendTextView.layer.borderWidth = 1
        sendTextView.layer.borderColor = UIColor.black.cgColor
    }
    
    @IBAction private func sendData(){
        guard status == .connected else {
            self.view.makeToast("未处于连接状态")
            return
        }
        guard let str = sendTextView.text else {
            return
        }
        guard str.count > 0 else {
            self.view.makeToast("内容不能为空")
            return
        }
        guard let data = str.data(using: .utf8) else {
            return
        }
        webRTCClient.sendData(data)
        respStatusLabel.text = "已发送,等待答复"
    }
}

extension VirgoListViewController: SocketMangerDelegate {
    func socketManger(_ socketManger: SocketManger, didSearchResult: [ClientModel]) {
        self.dataArray = didSearchResult
        tableView.reloadData()
    }
    
    func socketManger(_ socketManger: SocketManger, didReceiveMessage: [String : AnyObject]) {
        let dic = didReceiveMessage
        guard let from = dic["from"] as? String,
              let type = dic["type"] as? String
//              let __temp = dic["clientType"] as? String,
//              let clientType = ClientModel.ClientType(rawValue: __temp),
//              let group = dic["group"] as? String
        else {
            return
        }
        
        guard let payload = dic["payload"] as? [String: AnyObject] else {
            return
        }
        
        switch type {
        case "offer":
            onReceiveOffer(fromUid: from, payload: payload)
        case "answer":
            onReceiveAnswer(fromUid: from, payload: payload)
        case "candidate":
            onReceiveCandidate(fromUid: from, payload: payload)
        default:
            break
        }
    }
    
    private func answerToOffer(to:String) {
        self.webRTCClient.answer { (localSdp) in
            let sdp = SessionDescription(from: localSdp)
            SocketManger.share.sendSDP(from: Config.clientId, to: to, sdp: sdp)
        }
    }
    private func onReceiveOffer(fromUid: String, payload: [String: AnyObject]){
        if let sdpDesp =  payload["sdp"] as? String{
            
            let sdp = RTCSessionDescription(type: .offer, sdp: sdpDesp)
            webRTCClient.set(remoteSdp: sdp) { (error) in
                if sdp.type == .offer {
                    self.answerToOffer(to: fromUid)
                }
            }
        }
    }
    private func onReceiveAnswer(fromUid: String, payload: [String: AnyObject]){
        if let sdpDesp =  payload["sdp"] as? String{
            
            let rtcSdp = RTCSessionDescription(type: .answer, sdp: sdpDesp)
            webRTCClient.set(remoteSdp: rtcSdp) { (error) in
                
            }
        }
    }
    private func onReceiveCandidate(fromUid: String, payload: [String: AnyObject]){
        if let id = payload["id"] as? String,
           let label = payload["label"] as? Int32,
           let candidate =  payload["candidate"] as? String{
            
            let rtcIceCandiate = RTCIceCandidate(sdp: candidate, sdpMLineIndex: label, sdpMid: id)
            webRTCClient.set(remoteCandidate: rtcIceCandiate)
        }
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
        peerData = item
        webRTCClient.offer { (rtcSdp) in
            let sdp = SessionDescription(from: rtcSdp)
            SocketManger.share.sendSDP(from: Config.clientId, to: item.id, sdp: sdp)
        }
    }
}


extension VirgoListViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        guard let other = peerData else {
            return
        }
        let iceCandidate = IceCandidate(from: candidate)
        SocketManger.share.sendCandidate(to: other.id, from: Config.clientId , iceCandidate: iceCandidate)
    }
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        status = state
        var str = "未知"
        switch state {
        case .connected:
            str = "已连接"
            print("已连接")
        case .checking:
            str = "checking"
            print("checking")
        case .count:
            str = "count"
            print("count")
        case .new:
            str = "new"
            print("new")
        case .disconnected:
            str = "连接已断开"
            print("连接已断开")
        case .completed:
            str = "completed"
            print("completed")
        case .failed:
            str = "failed"
            print("failed")
        case .closed:
            str = "closed"
            print("closed")
        @unknown default:
            break
        }
        DispatchQueue.main.async {
            self.statusLabel.text = str
        }
    }
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        guard let str = String(data: data, encoding: .utf8) else {
            return
        }
        print("收到数据: \(str)")
        DispatchQueue.main.async {
            self.respStatusLabel.text = "收到Virgo答复"
        }
    }
}
