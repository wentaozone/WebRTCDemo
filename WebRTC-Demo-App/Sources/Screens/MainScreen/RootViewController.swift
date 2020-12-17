//
//  RootViewController.swift
//  WebRTC-Demo
//
//  Created by 文涛 on 2020/11/27.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit
import WebRTC
import Toast_Swift
import IQKeyboardManagerSwift

class RootViewController: UIViewController {

    @IBOutlet private var switchBtn: UISwitch!
    @IBOutlet private var clientIdTf: UITextField!
    @IBOutlet private var startBtn: UIButton!
    private let webRTCClient = WebRTCClient(iceServers: Config.default.webRTCIceServers)
    @IBOutlet private var statusLabel: UILabel!
    @IBOutlet private var dataLabel: UILabel!
    
    private var taurusData: ClientModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IQKeyboardManager.shared.enable = true
        SocketManger.share.connect()
    }


    @IBAction func start(_ sender:UIButton){
        Config.clientId = clientIdTf.text!
        Config.clientType = switchBtn.isOn ? .taurus : .virgo
        SocketManger.share.sendInit()
        
        switch Config.clientType {
        case .taurus:
            intoTaurus()
        case .virgo:
            intoVirgo()
        }
        
    }
    
    private func intoTaurus(){
        let vc = VirgoListViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func intoVirgo(){
        startBtn.setTitle("Virgo准备就绪", for: .normal)
        SocketManger.share.delegate = self
        webRTCClient.delegate = self
        webRTCClient.speakerOff()
    }
}

extension RootViewController: SocketMangerDelegate {
    func socketManger(_ socketManger: SocketManger, didSearchResult: [ClientModel]) {
        // not call
    }
    func socketManger(_ socketManger: SocketManger, didReceiveMessage: [String : AnyObject]) {
        let dic = didReceiveMessage
        guard let from = dic["from"] as? String,
              let type = dic["type"] as? String,
              let __temp = dic["clientType"] as? String,
              let clientType = ClientModel.ClientType(rawValue: __temp),
              let group = dic["group"] as? String else {
            return
        }
        guard let payload = dic["payload"] as? [String: AnyObject] else {
            return
        }
        
        taurusData = ClientModel()
        taurusData?.groupId = group
        taurusData?.id = from
        taurusData?.type = clientType
        
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

extension RootViewController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        guard let other = taurusData else {
            print("taurus 不存在")
            self.view.makeToast("Taurus 不存在")
            return
        }
        let iceCandidate = IceCandidate(from: candidate)
        SocketManger.share.sendCandidate(to: other.id, from: Config.clientId , iceCandidate: iceCandidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
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
        
        statusLabel.text = str
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        guard let str = String(data: data, encoding: .utf8) else {
            return
        }
        
        DispatchQueue.main.async {
            self.dataLabel.text = str
        }
        
        let resString = "魔镜回复: "+str
        guard let resData = resString.data(using: .utf8) else {
            return
        }
        webRTCClient.sendData(resData)
    }
}
