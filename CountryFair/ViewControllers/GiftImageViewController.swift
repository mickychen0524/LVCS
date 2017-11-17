//
//  GiftImageViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/13/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SCLAlertView
import AudioToolbox
import ImageIO
import QuartzCore
import CoreImage
import AVFoundation
import Social

class GiftImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    var socialImage : UIImage?
    lazy var str_playerRegisterLisence : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkRegisterState()
        // Do any additional setup after loading the view.
    }
    
    func checkRegisterState() {
        let botRegisterState = self.config.getValue("botRegisterState", fromStore: "settings") as! Bool
        if (!botRegisterState) {
            botRegister()
            
        }
    }
    
    func botRegister() {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Bot Registering..."
        AlamofireRequestAndResponse.sharedInstance.registerBotApiToTheServer([String : Any](), success: { (res: [String: Any]) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.config.writeValue(true as AnyObject, forKey: "botRegisterState", toStore: "settings")
            self.config.writeValue(self.appDelegate.JSONStringify(res) as AnyObject, forKey: "botRegisteredData", toStore: "settings")
            self.view.makeToast("Register success")
            
        },
         failure: { (error: Error!) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Register failed. \n Please restart after exit.", style: AlertStyle.error)
            
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        
        if error == nil
        {
//            _ = SweetAlert().showAlert("Success!".localized(), subTitle: "Your selfie saved successfuly.", style: AlertStyle.success)
        }
        else
        {
//            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Your selfie save error.", style: AlertStyle.error)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
