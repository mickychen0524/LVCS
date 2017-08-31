//
//  ServiceManager.swift
//  WifiChat
//
//  Created by Swayam Agrawal on 25/08/17.
//  Copyright © 2017 Avviotech. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ServiceManagerProtocol {
    func connectedDevicesChanged(_ manager : ServiceManager, connectedDevices: [MCPeerID:DeviceModel])
    func receivedData(_ manager : ServiceManager, peerID : MCPeerID, responseString: String)
}


import Foundation

class ServiceManager : NSObject {
    static let sharedServiceManager = ServiceManager()
    fileprivate let serviceType = "webrtc-service"
    fileprivate let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    fileprivate let serviceAdvertiser : MCNearbyServiceAdvertiser
    fileprivate let serviceBrowser : MCNearbyServiceBrowser
    var selectedPeer:MCPeerID?
    var delegate : ServiceManagerProtocol?
    var allDevice = [MCPeerID:DeviceModel]()
    
    override init() {
        let dInfo:[String : String] = ["type":"client"]
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: dInfo, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        super.init()
        //startAdvertising(uuid: "")
    }
    
    func stopAdvertising()
    {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    
    func startAdvertising(uuid:String)
    {
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
        
    }
    
    
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
    
    
    func sendColor(_ colorName : String) {
        print("sendColor: \(colorName)")
        if session.connectedPeers.count > 0 {
            var error : NSError?
            do {
                try self.session.send(colorName.data(using: String.Encoding.utf8, allowLossyConversion: false)!, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
            } catch let error1 as NSError {
                error = error1
                print("Error \(error)")
            }
        }
    }
    
    
    func callRequest(_ recipient : String, index : MCPeerID) {
        
        if session.connectedPeers.count > 0 {
            var error : NSError?
            do {
                try self.session.send(recipient.data(using: String.Encoding.utf8, allowLossyConversion: false)!, toPeers: [index], with: MCSessionSendDataMode.reliable)
                self.selectedPeer = index
                print("connected peers --- > \(index)")
            } catch let error1 as NSError {
                error = error1
                print("\(error)")
            }
        }
        
    }
    
    func sendDataToSelectedPeer(_ json:Dictionary<String,AnyObject>){
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
            try self.session.send(jsonData, toPeers: [self.selectedPeer!], with: MCSessionSendDataMode.reliable)
            print("command \(json) --- > \(self.selectedPeer?.displayName)")
        } catch let error1 as NSError {
            print("\(error1)")
        }
    }
    
    
    
}

extension ServiceManager : MCNearbyServiceAdvertiserDelegate {
    @available(iOS 7.0, *)
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
    
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
    
}

extension ServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        print("invitePeer: \(peerID)")
        let type = info?["type"] as! String
        print("withDiscoveryInfo: \(type)")
        if type == "clerk"
        {
            let dm = DeviceModel(p:peerID,t: "Clerk",s:"Available")
            allDevice.updateValue(dm, forKey: peerID)
            self.delegate?.connectedDevicesChanged(self, connectedDevices: allDevice)
        }
        
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer: \(peerID)")
        allDevice.removeValue(forKey: peerID)
        self.delegate?.connectedDevicesChanged(self, connectedDevices: allDevice)
        
    }
    
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch(self) {
        case .notConnected: return "NotConnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        }
    }
    
}

extension ServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.stringValue())")
        self.delegate?.connectedDevicesChanged(self, connectedDevices: allDevice)
        print(session.connectedPeers.map({$0.displayName}))
        if allDevice.index(forKey: peerID) != nil{
            print("Updating Values")
            allDevice.updateValue(allDevice[peerID]!, forKey: peerID)
            self.delegate?.connectedDevicesChanged(self, connectedDevices: allDevice)
        }
        var arr:[String] = session.connectedPeers.map({$0.displayName})
        if arr.count > 0 {
            print(arr[0])
        }
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        print("didReceiveData: \(str) from \(peerID.displayName) bytes")
        //let peerId = peerID.displayName
        self.delegate?.receivedData(self, peerID: peerID, responseString: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceiveStream")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
}
