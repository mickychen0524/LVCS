//
//  ShoppingCartTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

protocol ShoppingCardTableViewCellDelegate {
    func buttonClicked()
}

class ShoppingCartTableViewCell: UITableViewCell {

    @IBOutlet weak var channelImg: FLAnimatedImageView!
    @IBOutlet weak var logoImg: UIImageView!
    @IBOutlet weak var lblPlaysNumber: UILabel!
    @IBOutlet weak var lblChannelAmount: UILabel!
    @IBOutlet weak var btnShoppingCartitemAdd: UIButton!
    @IBOutlet weak var btnShoppingCartitemMinus: UIButton!
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var shoppingCartItem: [String: Any] = [:]
    var cellDelegate: ShoppingCardTableViewCellDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)!
    }
    
    // make table view cell using channel group data
    func configWithData(item: [String: Any]) {
        
        self.shoppingCartItem = item
        if let tileUrl = item["tileUrl"] as? String,
            let logoUrl = item["gameLogoUrl"] as? String {
            
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            var filePath = String.init(format: "%@/%@", documentPath, tileUrl)
            
            logoImg.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
            logoImg.contentMode = UIViewContentMode.scaleAspectFit
            if (item["animatedState"] as! Bool){
                self.channelImg.animatedImage = FLAnimatedImage.init(animatedGIFData: NSData(contentsOfFile:filePath) as Data!)
            } else {
                self.channelImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
                self.channelImg.contentMode = UIViewContentMode.scaleAspectFit
                self.channelImg.image = UIImage(contentsOfFile: filePath)
            }
            
            filePath = String.init(format: "%@/%@", documentPath, logoUrl)
            self.logoImg.image = UIImage.init(contentsOfFile: filePath)
        }
        
        self.lblChannelAmount.text = String.init(format: "$%.2f", item["playAmount"] as! Double)
        self.lblPlaysNumber.text = String.init(format: "%d", item["panelCount"] as! Int)
    }
    
    @IBAction func btnShoppingCartitemAddAction(_ sender: AnyObject) {
        let newCount: Int = (self.shoppingCartItem["panelCount"] as! Int) + 1
        self.shoppingCartItem["panelCount"] = newCount
        _ = self.appDelegate.updateShoppingCartToLocal(data: self.shoppingCartItem)
        self.lblPlaysNumber.text = String.init(format: "%d", newCount)
        self.cellDelegate?.buttonClicked()
    }
    
    @IBAction func btnShoppingCartitemMinusAction(_ sender: AnyObject) {
        if ((self.shoppingCartItem["panelCount"] as! Int) == 1) {
            _ = self.appDelegate.deleteOneItem(data: self.shoppingCartItem)
            self.lblPlaysNumber.text = String.init(format: "%d", self.shoppingCartItem["panelCount"] as! Int)
            let newCount: Int = (self.shoppingCartItem["panelCount"] as! Int) - 1
            self.shoppingCartItem["panelCount"] = newCount
            self.cellDelegate?.buttonClicked()
        } else if((self.shoppingCartItem["panelCount"] as! Int) < 1) {
            _ = SweetAlert().showAlert("Warning!".localized(), subTitle: "Please reload the table view.".localized(), style: AlertStyle.warning)
        } else {
            let newCount: Int = (self.shoppingCartItem["panelCount"] as! Int) - 1
            self.shoppingCartItem["panelCount"] = newCount
            _ = self.appDelegate.updateShoppingCartToLocal(data: self.shoppingCartItem)
            self.lblPlaysNumber.text = String.init(format: "%d", newCount)
            self.cellDelegate?.buttonClicked()
        }
        
    }
    

}
