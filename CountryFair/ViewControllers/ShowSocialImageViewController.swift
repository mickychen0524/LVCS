//
//  ShowSocialImageViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/3/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class ShowSocialImageViewController: UIViewController {

    @IBOutlet weak var socialImg: UIImageView!
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath : String = String.init(format: "%@/social.png", documentPath)
        
        self.socialImg.image = UIImage(contentsOfFile: filePath)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneBtnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
