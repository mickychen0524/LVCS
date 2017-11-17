//
//  RedeemTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 6/20/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import ZBarSDK

class RedeemTableViewCell: UITableViewCell {

    @IBOutlet weak var cardImg: UIImageView!
    @IBOutlet weak var redeemBtn: UIButton!
    @IBOutlet weak var lblAmount: UILabel!
    @IBOutlet weak var expirayLabel: UILabel!
    
    var item: [String: Any]!
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // make table view cell using channel group data
    func configWithData(item: [String: Any]) {
        self.item = item
        
//        self.cardImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
//        self.cardImg.contentMode = UIViewContentMode.scaleAspectFit
        
//        let giftItemFromList : [String : Any] = item["giftItemObj"] as! [String : Any]
//        let orgUrlStr = giftItemFromList["merchandiseImageUrl"] as! String
//        let urlString = orgUrlStr.replacingOccurrences(of: "https://demolngcdn.blob.core.windows.net", with: "https://dev2lngmstrasia.blob.core.windows.net")
//        let logoUrl: URL = URL(string: urlString)!
//        
//        DispatchQueue.global().async  {
//            self.cardImg.sd_setImage(with: logoUrl)
//        }
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        guard let fileName : String = item["fileName"] as? String else {
            return
        }
        let filePath = String.init(format: "%@/%@", documentPath, fileName)
        let sFileExists = FileManager.default.fileExists(atPath: filePath)
//        let fileMngr = FileManager.default;
//        let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        // List all contents of directory and return as [String] OR nil if failed
//        print (try? fileMngr.contentsOfDirectory(atPath:docs))
        var img = UIImage.init(contentsOfFile: filePath)
        if img == nil {
            img = UIImage()
//            let downloaditem = DownloadItemManager.shared.getDownloadItem(withName: fileName)
            if sFileExists == true {
                img = img?.getThumbnailFrom(path: URL.init(fileURLWithPath: filePath))
            }
        }
        self.cardImg.image = img
        
        self.lblAmount.text = String.init(format: "$%.2f", item["value"] as? Float ?? 0)
        if let expiry = item["claimExpireOn"] as? String {
            //2017-11-12T21:02:57.6497562+00:00
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = dateFormatter.date(from: expiry) {
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let timeStamp = dateFormatter.string(from: date)
                expirayLabel.text = "Expires \(timeStamp)"
            } else {
                expirayLabel.text = "Expires"
            }
        } else {
            expirayLabel.text = "Expires"
        }
        
    }
    
    @IBAction func redeemBtnAction(_ sender: Any) {
        if let isGift = self.item["isGiftCard"] as? Bool, isGift {
            let redeemAmountAlertView = RedeemAmountAlertView(giftCard: item)
            redeemAmountAlertView.delegate = self
            redeemAmountAlertView.show()
        } else {
            didRedeemButtonClicked(0)
        }
    }

}

extension RedeemTableViewCell: RedeemAmountAlertViewDelegate {
    func didRedeemButtonClicked(_ redeemAmount: Float!) {
        var params: [String: Any] = [:]
        var data: [String: Any] = [:]
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.superview, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Applying..."
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.full
        let convertedDate = dateFormatter.string(from: Date())
        
        params["createdOn"] = convertedDate
        
        AlamofireRequestAndResponse.sharedInstance.addCoordinateToParams(&params)
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileName : String = item["fileName"] as! String
        let filePath = String(format: "%@/%@", documentPath, fileName)
        let image = UIImage(contentsOfFile: filePath)
        let imageFile = ZBarImage(cgImage: image?.cgImage)
        let zbarImageScanner = ZBarImageScanner()
        let resultNumber = zbarImageScanner.scanImage(imageFile)
        if (resultNumber > 0) {
            let zbarResult : ZBarSymbolSet = zbarImageScanner.results
            var symbolFound : ZBarSymbol?
            for symbol in zbarResult {
                symbolFound = symbol as? ZBarSymbol
                break
            }
            data["validationCode"] = symbolFound?.data
        } else {
            MBProgressHUD.hideAllHUDs(for: self.superview, animated: true)
            let alertController = UIAlertController(title: "Error!".localized(), message: "Oops! Invalid Coupon. Please try again.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            UIApplication.topMostViewController?.present(alertController, animated: true, completion: nil)
            return
        }
        if let mediaSize = item["mediaSize"] as? Int {
            let mediaSizeStrSHA1 : String = String(mediaSize).sha1()
            let binaryData = mediaSizeStrSHA1.dataFromHexadecimalString()
            let base64String : String = (binaryData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))!
            data["mediaHash"] = base64String
        } else {
            //FIXME:HARDCODE mediaHash
            data["mediaHash"] = "ZpjZ0teUckKD3Lf8JHS2o8R4kZg="
        }
        data["somethingIKnowCredentialCypherText"] = "8CB2237D0679CA88DB6464EAC60DA96345513964"
        
        if let isGift = self.item["isGiftCard"] as? Bool, isGift {
            data["amountClaimed"] = redeemAmount
            params["data"] = data
            AlamofireRequestAndResponse.sharedInstance.applyRedeemAmount(params, success: { (response) in
                MBProgressHUD.hideAllHUDs(for: self.superview, animated: true)
                if let data = response["data"] as? [String: Any], let claimCode = data["claimCode"] as? String {
                    let redeemQRCodeAlertView = RedeemQRCodeAlertView(giftCard: self.item, visualCode: "", qrCode: claimCode)
                    redeemQRCodeAlertView.delegate = self
                    redeemQRCodeAlertView.show()
                }
            }) { (error) in
                MBProgressHUD.hideAllHUDs(for: self.superview, animated: true)
            }
        } else {
            params["data"] = data
            AlamofireRequestAndResponse.sharedInstance.applyRedeemCoupon(params, success: { (response) in
                MBProgressHUD.hideAllHUDs(for: self.superview, animated: true)
                if let data = response["data"] as? [String: Any], let claimCode = data["claimCode"] as? String {
                    let redeemQRCodeAlertView = RedeemQRCodeAlertView(giftCard: self.item, visualCode: "", qrCode: claimCode)
                    redeemQRCodeAlertView.delegate = self
                    redeemQRCodeAlertView.show()
                }
            }) { (error) in
                MBProgressHUD.hideAllHUDs(for: self.superview, animated: true)
            }
        }
        
    }
}

extension UIApplication {
    static var topMostViewController: UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController?.visibleViewController
    }
}

extension UIViewController {
    var visibleViewController: UIViewController? {
        if let navigationController = self as? UINavigationController {
            return navigationController.topViewController?.visibleViewController
        } else if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.visibleViewController
        } else if let presentedViewController = presentedViewController {
            return presentedViewController.visibleViewController
        } else {
            return self
        }
    }
}
