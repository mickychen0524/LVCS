//
//  ValidationViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SCLAlertView
import QRCode

class ValidationViewController: UIViewController {
    
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var lblAwardsAmount: UILabel!
    @IBOutlet weak var qrcodeImg: UIImageView!
    @IBOutlet weak var lblRedeemAmount: UILabel!
    @IBOutlet weak var claimBtn: UIButton!
    @IBOutlet weak var clerckLogo: UIImageView!

    // class parameters
    var claimTicketData : [String : Any]!
    var totalAmount : Double!
    var claimLicenseCode : String!
    var termsString : String!
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clerckLogo.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        self.clerckLogo.contentMode = UIViewContentMode.scaleAspectFit
        self.clerckLogo.image = UIImage(named: "clerklogo")
        self.lblAwardsAmount.text = String.init(format: "$%.2f Award!", self.totalAmount)
        //        self.lblRedeemAmount.text = String.init(format: "Redeem your $%.2f NOW", self.totalAmount)
        let resQRCode = QRCode(self.claimLicenseCode)
        self.qrcodeImg.image = resQRCode?.image
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnClaimAction(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : CardsViewController = mainStoryboard.instantiateViewController(withIdentifier: "cardViewController") as! CardsViewController
        vc.claimTicketData = claimTicketData
        vc.totalAmount = totalAmount
        vc.claimLicenseCode = claimLicenseCode
        self.present(vc, animated: true, completion: nil)
    }

}
