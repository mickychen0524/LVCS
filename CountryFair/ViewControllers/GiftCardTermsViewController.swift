//
//  GiftCardTermsViewController.swift
//  CountryFair
//
//  Created by Administrator on 8/30/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class GiftCardTermsViewController: UIViewController {
    
    @IBOutlet weak var giftCardImageView: UIImageView!
    @IBOutlet weak var termsTextView: UITextView!
    
    var giftCardImageUrl: String?
    var terms: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        termsTextView.isEditable = false
        if let url = giftCardImageUrl {
            giftCardImageView.sd_setImage(with: URL(string: url))
        }
        termsTextView.text = terms
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
