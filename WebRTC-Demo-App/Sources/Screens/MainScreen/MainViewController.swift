//
//  ViewController.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC

class MainViewController: UIViewController {

    private let signalClient: SignalingClient
    private let webRTCClient: WebRTCClient
    private lazy var videoViewController = VideoViewController(webRTCClient: self.webRTCClient)
    
    @IBOutlet private weak var speakerButton: UIButton?
    @IBOutlet private weak var signalingStatusLabel: UILabel?
    @IBOutlet private weak var localSdpStatusLabel: UILabel?
    @IBOutlet private weak var localCandidatesLabel: UILabel?
    @IBOutlet private weak var remoteSdpStatusLabel: UILabel?
    @IBOutlet private weak var remoteCandidatesLabel: UILabel?
    @IBOutlet private weak var muteButton: UIButton?
    @IBOutlet private weak var webRTCStatusLabel: UILabel?
    @IBOutlet private weak var clientLabel: UILabel!
    @IBOutlet private weak var otherClientTV: UITextView!
    @IBOutlet private weak var despLabel: UILabel!
    
    private var signalingConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.signalingConnected {
                    self.signalingStatusLabel?.text = "Connected"
                    self.signalingStatusLabel?.textColor = UIColor.green
                }
                else {
                    self.signalingStatusLabel?.text = "Not connected"
                    self.signalingStatusLabel?.textColor = UIColor.red
                }
            }
        }
    }
    
    private var hasLocalSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.localSdpStatusLabel?.text = self.hasLocalSdp ? "✅" : "❌"
            }
        }
    }
    
    private var localCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.localCandidatesLabel?.text = "\(self.localCandidateCount)"
            }
        }
    }
    
    private var hasRemoteSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.remoteSdpStatusLabel?.text = self.hasRemoteSdp ? "✅" : "❌"
            }
        }
    }
    
    private var remoteCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.remoteCandidatesLabel?.text = "\(self.remoteCandidateCount)"
            }
        }
    }
    
    private var speakerOn: Bool = false {
        didSet {
            let title = "Speaker: \(self.speakerOn ? "On" : "Off" )"
            self.speakerButton?.setTitle(title, for: .normal)
        }
    }
    
    private var mute: Bool = false {
        didSet {
            let title = "Mute: \(self.mute ? "on" : "off")"
            self.muteButton?.setTitle(title, for: .normal)
        }
    }
    
    init(signalClient: SignalingClient, webRTCClient: WebRTCClient) {
        self.signalClient = signalClient
        self.webRTCClient = webRTCClient
        super.init(nibName: String(describing: MainViewController.self), bundle: Bundle.main)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "WebRTC Demo"
        self.signalingConnected = false
        self.hasLocalSdp = false
        self.hasRemoteSdp = false
        self.localCandidateCount = 0
        self.remoteCandidateCount = 0
        self.speakerOn = false
        self.webRTCStatusLabel?.text = "New"
        
        self.webRTCClient.delegate = self
        self.signalClient.delegate = self
        self.signalClient.connect()
    }
    
    @IBAction private func offerDidTap(_ sender: UIButton) {
        self.webRTCClient.offer { (sdp) in
            self.hasLocalSdp = true
            self.signalClient.send(sdp: sdp)
        }
    }
    
    @IBAction private func answerDidTap(_ sender: UIButton?) {
        self.webRTCClient.answer { (localSdp) in
            self.hasLocalSdp = true
            self.signalClient.send(sdp: localSdp)
        }
    }
    
    @IBAction private func speakerDidTap(_ sender: UIButton) {
        if self.speakerOn {
            self.webRTCClient.speakerOff()
        }
        else {
            self.webRTCClient.speakerOn()
        }
        self.speakerOn = !self.speakerOn
    }
    
    @IBAction private func videoDidTap(_ sender: UIButton) {
        self.present(videoViewController, animated: true, completion: nil)
    }
    
    @IBAction private func muteDidTap(_ sender: UIButton) {
        self.mute = !self.mute
        if self.mute {
            self.webRTCClient.muteAudio()
        }
        else {
            self.webRTCClient.unmuteAudio()
        }
    }
    
    @IBAction func sendDataDidTap(_ sender: UIButton) {
//        let alert = UIAlertController(title: "Send a message to the other peer",
//                                      message: "This will be transferred over WebRTC data channel",
//                                      preferredStyle: .alert)
//        alert.addTextField { (textField) in
//            textField.placeholder = "Message to send"
//        }
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, unowned alert] _ in
//            guard let dataToSend = alert.textFields?.first?.text?.data(using: .utf8) else {
//                return
//            }
//            self?.webRTCClient.sendData(dataToSend)
//        }))
//        self.present(alert, animated: true, completion: nil)
        
        let md = MeasureData()
        if let jsonStr = md.toJSONString(), let resp = jsonStr.data(using: .utf8){
            self.webRTCClient.sendData(resp)
        }
    }
}

extension MainViewController: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        self.signalingConnected = false
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            self.hasRemoteSdp = true
            
            if sdp.type == .offer {
                self.answerDidTap(nil)
            }
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        print("Received remote candidate")
        self.remoteCandidateCount += 1
        self.webRTCClient.set(remoteCandidate: candidate)
    }
    func signalClient(_ signalClient: SignalingClient, didInited clientId: String) {
        self.clientLabel.text = clientId
    }
    func signalClient(_ signalClient: SignalingClient, didRecevied otherClientIds: [String]) {
        let ss = otherClientIds.reduce("") { (result, id) -> String in
            if result == "" {
                return result + id
            }else {
                return result + "\n" + id
            }
        }
        otherClientTV.text = ss
    }
}

extension MainViewController: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        self.localCandidateCount += 1
        self.signalClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        switch state {
        case .connected, .completed:
            textColor = .green
        case .disconnected:
            textColor = .orange
        case .failed, .closed:
            textColor = .red
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
        DispatchQueue.main.async {
            self.webRTCStatusLabel?.text = state.description.capitalized
            self.webRTCStatusLabel?.textColor = textColor
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
//        DispatchQueue.main.async {
//            let message = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
//            let alert = UIAlertController(title: "Message from WebRTC", message: message, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        }
        
        guard let str = String(data: data, encoding: .utf8) else {
            return
        }
        guard var recive = MeasureData.deserialize(from: str) else {
            print("收到数据 \(str)")
            return
        }
        
        func main(_   block:@escaping ()->Void){
            if Thread.isMainThread {
                block()
            }else{
                DispatchQueue.main.async {
                    block()
                }
            }
        }
        
        switch recive.type {
        case .resp:
            let time = Int(NSDate().timeIntervalSince1970 * 1000)
            let during = time - recive.time
            print("收到响应: \(recive.num) 耗时 \(during)ms  数据 \(str)")
            main {
                self.despLabel.text = "收到响应:\(recive.num) \(during)ms"
            }
            if recive.num > 100 {
                return
            }
            var md = MeasureData()
            md.num = recive.num + 1
            if let jsonStr = md.toJSONString(), let resp = jsonStr.data(using: .utf8){
                self.webRTCClient.sendData(resp)
            }
        case .req:
            print("收到请求 \(recive.num)")
            main {
                self.despLabel.text = "收到请求:\(recive.num)"
            }

            recive.type = .resp
            if let jsonStr = recive.toJSONString(), let resp = jsonStr.data(using: .utf8){
                self.webRTCClient.sendData(resp)
            }
        }
    }
}

