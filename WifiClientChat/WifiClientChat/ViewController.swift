//
//  ViewController.swift
//  WifiChat
//
//  Created by Swayam Agrawal on 25/08/17.
//  Copyright © 2017 Avviotech. All rights reserved.
//

import UIKit
import MultipeerConnectivity
enum ResponseValue: String {
    case incomingCall = "incomingCall"
    case callAccepted = "callAccepted"
    case callRejected = "callRejected"
}
class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var connectionsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    // Differentiates caller and receiver
    var isInitiator = false
    var peerListArray : [MCPeerID:DeviceModel] = [MCPeerID:DeviceModel]()
    let bonjourService = ServiceManager.sharedServiceManager
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bonjourService.delegate = self
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "Cell")
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
            ServiceManager.sharedServiceManager.delegate = nil
        }
    }
    
    func showAlert(_ caller : MCPeerID) {
        let unownedSelf = self
        let alert = UIAlertController(title: "Incoming Call",
                                      message: caller.displayName,
                                      preferredStyle: .alert)
        //let idx = peerListArray.index(of: caller) //
        let acceptAction = UIAlertAction(title: "Accept",
                                         style: .default,
                                         handler: { (action:UIAlertAction) -> Void in
                                            unownedSelf.bonjourService.callRequest("callAccepted", index: caller)
                                            unownedSelf.isInitiator = false
                                            unownedSelf.startCallViewController()
        })
        let rejectAction = UIAlertAction(title: "Reject",
                                         style: .default) { (action: UIAlertAction) -> Void in
                                            unownedSelf.bonjourService.callRequest("callRejected", index: caller)
                                            
        }
        alert.addAction(acceptAction)
        alert.addAction(rejectAction)
        present(alert, animated: true, completion: nil)
    }
    
    func takeCall(_ caller : MCPeerID)
    {
        let unownedSelf = self
        //let idx = peerListArray.index(of: caller)
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
    
    // tableView
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return peerListArray.count
    }
    
    func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.text = peerListArray[indexPath.row].key.displayName
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bonjourService.callRequest("incomingCall", index: peerListArray[indexPath.row].key)
        self.isInitiator = true
    }
    
    
}

extension ViewController : ServiceManagerProtocol {
    
    func connectedDevicesChanged(_ manager: ServiceManager, connectedDevices: [MCPeerID:DeviceModel]) {
        let unownedSelf = self
        OperationQueue.main.addOperation { () -> Void in
            unownedSelf.connectionsLabel.text = "Me: \(UIDevice.current.name)"
            unownedSelf.peerListArray = connectedDevices
            unownedSelf.tableView.reloadData()
        }
    }
    
    func receivedData(_ manager: ServiceManager, peerID: MCPeerID, responseString: String) {
        let unownedSelf = self
        DispatchQueue.main.async {
            switch responseString {
            case ResponseValue.incomingCall.rawValue :
                print("incomingCall")
                unownedSelf.takeCall(peerID)
                //unownedSelf.showAlert(peerID)
            case ResponseValue.callAccepted.rawValue:
                print("callAccepted")
                unownedSelf.startCallViewController()
            case ResponseValue.callRejected.rawValue:
                print("callRejected")
            default:
                print("Unknown color value received: \(responseString)")
            }
        }
    }
}

