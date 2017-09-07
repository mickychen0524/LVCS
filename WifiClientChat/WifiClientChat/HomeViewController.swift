//
//  HomeViewController.swift
//  WifiClientChat
//
//  Created by Swayam Agrawal on 30/08/17.
//  Copyright © 2017 Avviotech. All rights reserved.
//

import UIKit
import MultipeerConnectivity
class HomeViewController: UIViewController {

    let bonjourService = ServiceManager.getManager(t: "client")
    @IBOutlet weak var callButton: UIButton!
    var isInitiator = false
    var peerListArray : [MCPeerID:DeviceModel] = [MCPeerID:DeviceModel]()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        callButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        bonjourService.delegate = self
        if self.bonjourService.getClerkList() != nil && self.bonjourService.getClerkList().count > 0
        {
            self.callButton.isEnabled = true
        }
        else{
            self.callButton.isEnabled = false
        }

    }

    @IBAction func connectClerk(_ sender: Any) {
        bonjourService.startAdvertising(type: "client")
        bonjourService.delegate = self
        callButton.isEnabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    

}

extension HomeViewController : ServiceManagerProtocol {
    
    func connectedDevicesChanged(_ manager: ServiceManager, connectedDevices: [MCPeerID:DeviceModel]) {
        print("connectedDevicesChanged" + String(self.bonjourService.getClerkList().count))
        if self.bonjourService.getClerkList() != nil && self.bonjourService.getClerkList().count > 0
        {
            self.callButton.isEnabled = true
        }
        else{
            self.callButton.isEnabled = false
        }
    }
    
    func receivedData(_ manager: ServiceManager, peerID: MCPeerID, responseString: String) {
        print("receivedData - " + responseString)
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
