//
//  HomeViewController.swift
//  WifiClientChat
//
//  Created by Swayam Agrawal on 30/08/17.
//  Copyright © 2017 Avviotech. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    let bonjourService = ServiceManager.sharedServiceManager
    @IBOutlet weak var callButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func connectClerk(_ sender: Any) {
        bonjourService.startAdvertising(uuid: UUID().uuidString)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier :"waitingController") as! WaitingViewController
        
        self.navigationController?.pushViewController(viewController, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

   
    

}
