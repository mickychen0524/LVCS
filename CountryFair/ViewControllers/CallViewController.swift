//
//  CallViewController.swift
//  CountryFair
//
//  Created by Administrator on 9/6/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import FSDK

class CallViewController: ViewController {
    
    @IBOutlet weak var remoteView: RTCEAGLVideoView!
    @IBOutlet weak var localView: RTCEAGLVideoView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var buttonContainerView: UIView!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var hangupButton: UIButton!
    @IBOutlet weak var remoteViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var remoteViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var remoteViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var remoteViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var localViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var localViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var localViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var localViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerViewLeftConstraint: NSLayoutConstraint!
    
    var fconstraint: NSLayoutConstraint?
    
    var roomUrl: String?
    var _roomName = ""
    var roomName: NSString?
    var localVideoTrack: RTCVideoTrack?
    var remoteVideoTrack: RTCVideoTrack?
    var localVideoSize: CGSize?
    var remoteVideoSize: CGSize?
    var isZoom = false
    let serviceManager = ServiceManager.getManager(t: "client")
    let webrtcManager = WebrtcManager()
    var isInitiator = false

    override func viewDidLoad() {
        super.viewDidLoad()

        serviceManager.delegate = self
        webrtcManager.delegate = self
        webrtcManager.initiator = isInitiator
        webrtcManager.startWebrtcConnection()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action:#selector(toggleButtonContainer)))
        
        let tgr = UITapGestureRecognizer(target: self, action:#selector(zoomRemote))
        tgr.numberOfTapsRequired = 2
        view.addGestureRecognizer(tgr)
        
        remoteView?.delegate = self
        localView?.delegate = self
        
        fconstraint = NSLayoutConstraint(item: footerView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 100)
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_: )), name: NSNotification.Name(rawValue: "UIDeviceOrientationDidChangeNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground(notification: )), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        localViewBottomConstraint?.constant = 0.0
        localViewRightConstraint?.constant = 0.0
        localViewHeightConstraint?.constant = view.frame.size.height
        localViewWidthConstraint?.constant = view.frame.size.width
        footerViewBottomConstraint?.constant = 0.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appMovedToBackground(notification: NSNotification) {
        let state = UIApplication.shared.applicationState
        if state == .inactive {
            print("App in active")
        }
        
        print("App moved to background!")
        hangupButtonPressed(nil)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        disconnect()
    }
    
    @objc func orientationChanged(_ notification: Notification) {
        if localVideoSize != nil {
            videoView(localView!, didChangeVideoSize: localVideoSize!)
        }
        
        if remoteVideoSize != nil {
            videoView(remoteView!, didChangeVideoSize: remoteVideoSize!)
        }
    }
    
    @objc func toggleButtonContainer() {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            if (self.buttonContainerViewLeftConstraint!.constant <= -40.0) {
                self.buttonContainerViewLeftConstraint!.constant = 20.0
                self.buttonContainerView!.alpha = 1.0;
            } else {
                self.buttonContainerViewLeftConstraint!.constant = -40.0;
                self.buttonContainerView!.alpha = 0.0;
            }
            
            self.view.layoutIfNeeded();
        })
    }
    
    @objc func zoomRemote() {
        isZoom = !isZoom
        videoView(self.remoteView!, didChangeVideoSize: remoteVideoSize!)
    }
    
    func disconnect() {
        localVideoTrack?.remove(localView)
        remoteVideoTrack?.remove(remoteView)
        localView?.renderFrame(nil)
        remoteView?.renderFrame(nil)
        localVideoTrack = nil
        remoteVideoTrack = nil
        webrtcManager.disconnect()
    }
    
    func remoteDisconnected() {
        remoteVideoTrack?.remove(remoteView)
        remoteView?.renderFrame(nil)
        if localVideoSize != nil {
            videoView(localView!, didChangeVideoSize: localVideoSize!)
        }
    }
    
    func sendDisconnectToPeer() {
        let json: Dictionary<String, AnyObject> = ["disconnect":"disconnect" as AnyObject]
        serviceManager.sendDataToSelectedPeer(json)
    }
    
    func convertStringToDictionary(_ text: String) -> [String:AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        
        return nil
    }
    
    @IBAction func audioButtonPressed(_ sender: UIButton!) {
        if !sender.isSelected {
            webrtcManager.removeAudio()
        } else {
            self.webrtcManager.addAudio()
        }
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func videoButtonPressed(_ sender: UIButton!) {
        if !sender.isSelected {
            self.webrtcManager.swapBackVideo()
        } else {
            self.webrtcManager.swapFrontVideo()
        }
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func hangupButtonPressed(_ sender:UIButton!) {
        sendDisconnectToPeer()
        disconnect()
        serviceManager.stopAdvertising()
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension CallViewController: WebrtcManagerProtocol {
    
    func offerSDPCreated(_ sdp: RTCSessionDescription) {
        let json = ["offerSDP": sdp.jsonDictionary()]
        serviceManager.sendDataToSelectedPeer(json as Dictionary<String, AnyObject>)
    }
    
    func answerSDPCreated(_ sdp:RTCSessionDescription) {
        let json = ["answerSDP": sdp.jsonDictionary()]
        serviceManager.sendDataToSelectedPeer(json as Dictionary<String, AnyObject>)
        
    }
    
    func iceCandidatesCreated(_ iceCandidate: RTCICECandidate) {
        let json = ["iceCandidate":iceCandidate.jsonDictionary()]
        serviceManager.sendDataToSelectedPeer(json as Dictionary<String, AnyObject>)
    }
    
    func localStreamAvailable(_ stream: RTCMediaStream) {
        guard let videoTrack = stream.videoTracks[0] as? RTCVideoTrack else { return }
        
        DispatchQueue.main.async {
            self.localVideoTrack?.remove(self.localView)
            self.localView?.renderFrame(nil)
            self.localVideoTrack = videoTrack
            self.localVideoTrack?.add(self.localView)
        }
    }
    
    func remoteStreamAvailable(_ stream: RTCMediaStream) {
        guard let videoTrack = stream.videoTracks[0] as? RTCVideoTrack else { return }
        
        DispatchQueue.main.async {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
            } catch {
                print("Audio Port Error");
            }
            self.remoteVideoTrack = videoTrack
            self.remoteVideoTrack?.add(self.remoteView)
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                self.localViewBottomConstraint?.constant = 28.0
                self.localViewRightConstraint?.constant = 28.0
                self.localViewHeightConstraint?.constant = self.view.frame.size.height / 4
                self.localViewWidthConstraint?.constant = self.view.frame.size.width / 4
                self.footerView.backgroundColor = UIColor.black
                self.view.addConstraint(self.fconstraint!)
            })
        }
    }
    
    func dataReceivedInChannel(_ data: Data) {
        let dataAsString = String(data: data, encoding: String.Encoding.utf8)
        let alert = UIAlertController(title: "", message: dataAsString, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
        self.present(alert, animated: true)
    }
}

extension CallViewController: ServiceManagerProtocol {
    
    func connectedDevicesChanged(_ manager : ServiceManager, connectedDevices: [MCPeerID: DeviceModel]) {
        
    }
    
    func receivedData(_ manager : ServiceManager, peerID : MCPeerID, responseString: String) {
        let dictionary = convertStringToDictionary(responseString)
        guard let keyValue = dictionary?.keys.first else { return }
        
        if keyValue == "offerSDP" {
            let description = dictionary!["offerSDP"] as! [String:AnyObject]
            let offerSDP = RTCSessionDescription.init(fromJSONDictionary: description)
            webrtcManager.remoteSDP = offerSDP
            webrtcManager.createAnswer()
        } else if keyValue == "answerSDP"{
            let description = dictionary!["answerSDP"] as! [String:AnyObject]
            let offerSDP = RTCSessionDescription.init(fromJSONDictionary: description )
            webrtcManager.remoteSDP = offerSDP
            webrtcManager.setAnswerSDP()
        } else if keyValue == "iceCandidate"{
            let description = dictionary!["iceCandidate"] as! [String:AnyObject]
            let iceCandidate = RTCICECandidate(fromJSONDictionary: description)
            webrtcManager.setICECandidates(iceCandidate!)
        } else if keyValue == "disconnect" {
            DispatchQueue.main.async {
                self.hangupButtonPressed(self.hangupButton!)
            }
        }
    }
}

extension CallViewController: RTCEAGLVideoViewDelegate {
    
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        DispatchQueue.main.async {
            let orientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                let containerWidth: CGFloat = self.view.frame.size.width
                let containerHeight: CGFloat = self.view.frame.size.height
                let defaultAspectRatio: CGSize = CGSize(width: 4, height: 3)
                
                if videoView == self.localView {
                    self.localVideoSize = size
                    let aspectRatio: CGSize = size.equalTo(CGSize.zero) ? defaultAspectRatio : size
                    print("Aspect Ratio" , aspectRatio)
                    var videoRect: CGRect = self.view.bounds
                    if self.remoteVideoTrack != nil {
                        videoRect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width / 4.0, height: self.view.frame.size.height / 4.0)
                        if orientation == UIInterfaceOrientation.landscapeLeft || orientation == UIInterfaceOrientation.landscapeRight {
                            videoRect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.height / 4.0, height: self.view.frame.size.width / 4.0)
                        }
                    }
                    let videoFrame: CGRect = AVMakeRect(aspectRatio: aspectRatio, insideRect: videoRect)
                    self.localViewWidthConstraint!.constant = videoFrame.size.width
                    self.localViewHeightConstraint!.constant = videoFrame.size.height
                    if self.remoteVideoTrack != nil {
                        self.localViewBottomConstraint!.constant = 28.0
                        self.localViewRightConstraint!.constant = 28.0
                    } else {
                        self.localViewBottomConstraint!.constant = containerHeight / 2.0 - videoFrame.size.height / 2.0
                        self.localViewRightConstraint!.constant = containerWidth / 2.0 - videoFrame.size.width / 2.0
                    }
                } else if videoView == self.remoteView {
                    self.remoteVideoSize = size
                    let aspectRatio: CGSize = size.equalTo(CGSize.zero) ? defaultAspectRatio : size
                    print("Aspect Ratio",aspectRatio)
                    let videoRect: CGRect = self.view.bounds
                    var videoFrame: CGRect = AVMakeRect(aspectRatio: aspectRatio, insideRect: videoRect)
                    if self.isZoom {
                        let scale: CGFloat = max(containerWidth / videoFrame.size.width, containerHeight / videoFrame.size.height)
                        videoFrame.size.width *= scale
                        videoFrame.size.height *= scale
                        self.footerViewBottomConstraint.constant = -80
                    } else {
                        self.footerViewBottomConstraint.constant = 0
                        self.footerView.backgroundColor = UIColor.black
                        self.view.addConstraint(self.fconstraint!)
                    }
                    self.remoteViewTopConstraint!.constant = (containerHeight - videoFrame.size.height) / 2.0
                    self.remoteViewBottomConstraint!.constant = (containerHeight - videoFrame.size.height) / 2.0
                    self.remoteViewLeftConstraint!.constant = (containerWidth - videoFrame.size.width) / 2.0
                    self.remoteViewRightConstraint!.constant = (containerWidth - videoFrame.size.width) / 2.0
                }
                self.view.layoutIfNeeded()
            })
        }
    }
}
