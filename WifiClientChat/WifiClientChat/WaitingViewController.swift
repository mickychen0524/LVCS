//
//  WaitingViewController.swift
//  WifiClientChat
//
//  Created by Swayam Agrawal on 31/08/17.
//  Copyright © 2017 Avviotech. All rights reserved.
//

import UIKit
import UIKit
import MultipeerConnectivity

class WaitingViewController: UIViewController{

    var isInitiator = false
    var peerListArray : [MCPeerID:DeviceModel] = [MCPeerID:DeviceModel]()
    let bonjourService = ServiceManager.getManager(t: "client")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bonjourService.delegate = self
        self.title = "Client"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bonjourService.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let unownedSelf = self
        if segue.destination.isKind(of: RTCVideoChatViewController.self){
            let destinationController:RTCVideoChatViewController = segue.destination as! RTCVideoChatViewController
            destinationController.isInitiator = unownedSelf.isInitiator
            bonjourService.delegate = nil
        }
    }
    
    func takeCall(_ caller : MCPeerID)
    {
        let unownedSelf = self
        unownedSelf.bonjourService.stopAdvertising()
        unownedSelf.bonjourService.callRequest("callAccepted", index: caller)
        unownedSelf.isInitiator = false
        unownedSelf.startCallViewController()
    }
    
    func startCallViewController(){
        let unownedSelf = self
        DispatchQueue.main.async {
            unownedSelf.performSegue(withIdentifier: "showVideoCall", sender: unownedSelf)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.bonjourService.stopAdvertising()
    }
    

}

extension WaitingViewController : ServiceManagerProtocol {
    
    func connectedDevicesChanged(_ manager: ServiceManager, connectedDevices: [MCPeerID:DeviceModel]) {
        
    }
    
    func receivedData(_ manager: ServiceManager, peerID: MCPeerID, responseString: String) {
        DispatchQueue.main.async {
            switch responseString {
            case ResponseValue.incomingCall.rawValue :
                print("incomingCall")
                self.takeCall(peerID)
            case ResponseValue.callAccepted.rawValue:
                print("callAccepted")
                self.startCallViewController()
            case ResponseValue.callRejected.rawValue:
                print("callRejected")
            default:
                print("Unknown color value received: \(responseString)")
            }
        }
    }
}
