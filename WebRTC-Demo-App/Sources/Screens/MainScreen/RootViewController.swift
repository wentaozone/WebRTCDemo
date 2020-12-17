//
//  RootViewController.swift
//  WebRTC-Demo
//
//  Created by 文涛 on 2020/11/27.
//  Copyright © 2020 Stas Seldin. All rights reserved.
//

import UIKit
import WebRTC

class RootViewController: UIViewController {

    @IBOutlet private var switchBtn: UISwitch!
    @IBOutlet private var clientIdTf: UITextField!
    @IBOutlet private var startBtn: UIButton!
    private let webRTCClient = WebRTCClient(iceServers: Config.default.webRTCIceServers)
    
    private let encoder = JSONEncoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }
}

extension RootViewController: SocketMangerDelegate {
    func socketManger(_ socketManger: SocketManger, didSearchResult: [ClientModel]) {
        // not call
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
