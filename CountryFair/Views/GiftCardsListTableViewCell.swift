//
//  GiftCardsListTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 6/20/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import DropDown
import SCLAlertView
import Kingfisher
import QRCode
import SwiftGifOrigin

protocol GiftCardsTableViewCellDelegate: NSObjectProtocol {
    func didGiftCardImageClicked(_ giftCardImageUrl: String?, terms: String?)
}

class GiftCardsListTableViewCell: UITableViewCell {

    @IBOutlet weak var cardImg: UIImageView!
    @IBOutlet weak var lblCardName: UILabel!
    @IBOutlet weak var lblLowValue: UILabel!
    @IBOutlet weak var lblHighValue: UILabel!
    @IBOutlet weak var buyNowBtn: UIButton!
    
    var checkoutCoreRefID : String! = ""
    var giftCardObj : [String : Any]!
    var checkoutObj : [String : Any]!
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    let availableValues = DropDown()
    
    // checkout section
    lazy var giftCardDataArr : NSArray! = NSArray()
    lazy var couponDataArr : NSArray! = NSArray()
    var orgData: [String:Any] = [:]
    var checkoutResData: [String:Any] = [:]
    var loopCount: Int = 0
    var getStatusErrorLoopCount: Int = 0

    var checkoutDLG : SCLAlertView?
    var checkoutConfirmDLG : SCLAlertView?
    var checkoutGeneratingDLG : SCLAlertView?
    lazy var transprentView = UIView()
    lazy var imgCheckoutView = UIImageView()
    
    // background job stuff
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var updateTimer: Timer?
    
    // checkout button pressed flag
    var checkoutPressedFlag : Bool = false
    var cancelBtnPressed : Bool = false
    var checkoutGeneratingFlag : Bool = false
    var getCouponResultSateFlg : Bool = false
    
    var selfViewController : UIViewController!
    
    weak var delegate: GiftCardsTableViewCellDelegate?
    
    var buyNowAlertView: SCLAlertView!
    
    lazy var dropDowns: [DropDown] = {
        return [
            self.availableValues
        ]
    }()
    
    deinit {
        print("shopping cart deinit called")
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupDefaultDropDown() {
        DropDown.setupDefaultAppearance()
        
        dropDowns.forEach {
            $0.cellNib = UINib(nibName: "DropDownCell", bundle: Bundle(for: DropDownCell.self))
            $0.customCellConfiguration = nil
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        dropDowns.forEach { $0.dismissMode = .onTap }
        dropDowns.forEach { $0.direction = .bottom }
        setupDefaultDropDown()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // make table view cell using channel group data
    func configWithData(item: [String: Any]) {
        self.giftCardObj = item
        cardImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        cardImg.contentMode = UIViewContentMode.scaleAspectFit
        let orgUrlStr = item["merchandiseImageUrl"] as! String
        let urlString = orgUrlStr.replacingOccurrences(of: "https://demolngcdn.blob.core.windows.net", with: "https://dev2lngmstrasia.blob.core.windows.net")
        let logoUrl: URL = URL(string: urlString)!
        cardImg.sd_setImage(with: logoUrl)
        cardImg.isUserInteractionEnabled = true
        cardImg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleGiftCardImageTap(sender:))))
        
        self.lblCardName.text = item["merchantName"] as? String
        
        let rangesArr = item["ranges"] as! NSArray
        
        if (rangesArr.count != 0) {
            let rangeItem = rangesArr[0] as! [String : Any]
            var amountStrTemp: [String] = []
            self.lblLowValue.text = String.init(format: "$%d", rangeItem["low"] as! Int)
            self.lblHighValue.text = String.init(format: "$%d", rangeItem["high"] as! Int)
            for am in (rangeItem["low"] as! Int) ..< (rangeItem["high"] as! Int){
                amountStrTemp.append(String(format: "%d", am + 1))
            }
            self.availableValues.dataSource = amountStrTemp
        }
    }
    
    @IBAction func buyNowBtnAction(_ sender: Any) {
        
        // Create custom Appearance Configuration
        var numberInt: Int = 1
        
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: Style.Font.fontWithSize(size: 20),
            kTextFont: Style.Font.fontWithSize(size: 14),
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false,
            showCircularIcon: true,
            shouldAutoDismiss: false
        )

        // Initialize SCLAlertView using custom Appearance
        buyNowAlertView = SCLAlertView(appearance: appearance)
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 150))
        let x = (subview.frame.width - 210) / 2
        
        // Add label
        let label = UILabel(frame: CGRect(x: x,y: 10, width: 210,height: 25))
        label.layer.borderColor = UIColor.black.cgColor
        label.textAlignment = .left
        label.font = Style.Font.boldFontWithSize(size: 16)
        label.text = "Gift Card Amount?"
        subview.addSubview(label)
        
        // Add draw button
        let avBtn = DropDownButton(frame: CGRect(x: x,y: label.frame.maxY + 10,width: 210,height: 25))
        avBtn.layer.borderColor = UIColor.lightGray.cgColor
        avBtn.layer.borderWidth = 0.5
        avBtn.layer.cornerRadius = 3
        avBtn.setTitle("$" + self.availableValues.dataSource[0], for: .normal)
        numberInt = Int(self.availableValues.dataSource[0])!
        avBtn.setTitleColor(UIColor.black, for: .normal)
        avBtn.contentHorizontalAlignment = .left
        avBtn.titleLabel!.font = UIFont.systemFont(ofSize: 12.0)
        avBtn.addTarget(self, action: #selector(GiftCardsListTableViewCell.chooseValue(_:)), for: .touchUpInside)
        subview.addSubview(avBtn)
        self.availableValues.anchorView = avBtn
        self.availableValues.bottomOffset = CGPoint(x: 0, y: 30)

        // Action triggered on selection
        availableValues.selectionAction = {(index, item) in
            avBtn.setTitle("$" + item, for: .normal)
            numberInt = Int(item)!
        }
        
        // Disclaimer label
        let disclaimerLabel = UILabel(frame: CGRect(x: x, y: avBtn.frame.maxY + 10, width: 100,height: 130))
        disclaimerLabel.font = UIFont.systemFont(ofSize: 12)
        disclaimerLabel.numberOfLines = 0
        if let merchandiseDisclaimer = giftCardObj["merchantDisclaimer"] as? String {
            disclaimerLabel.text = merchandiseDisclaimer
        } else {
            disclaimerLabel.text = ""
        }
        subview.addSubview(disclaimerLabel)
        
        // Add app logo image
        let logoImg = UIImageView(frame: CGRect(x: avBtn.frame.maxX - 100, y: avBtn.frame.maxY + 10, width: 100, height: 60))
        logoImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        logoImg.contentMode = UIViewContentMode.scaleAspectFit
        logoImg.sd_setImage(with: URL(string:self.giftCardObj["merchandiseImageUrl"] as! String))
        logoImg.isUserInteractionEnabled = true
        subview.addSubview(logoImg)
        
        // Add game logo image
        let giftLogoImg = UIImageView(frame: CGRect(x: avBtn.frame.minX, y: avBtn.frame.maxY + 10, width: 100,height: 60))
        giftLogoImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        giftLogoImg.contentMode = .left
        giftLogoImg.image = UIImage(named: "cf_icon_60")
        subview.addSubview(giftLogoImg)
        
        // Add the subview to the alert's UI property
        buyNowAlertView.customSubview = subview
        
        let _ = buyNowAlertView.addButton("Checkout") {
            if (numberInt != 0) {
                
                self.checkoutObj = [String : Any]()
                self.checkoutObj["merchantRefId"] = self.giftCardObj["merchandiseRefId"] as! String
                self.checkoutObj["Value"] = numberInt
                
                UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut, animations: {
                    var viewFrame = self.buyNowAlertView.view.frame
                    viewFrame.origin.y -= viewFrame.size.height
                    self.buyNowAlertView.view.frame = viewFrame
                }, completion: { finished in
                    self.buyNowAlertView.hideView()
                    self.checkoutWithAPI()
                    // initialization background stuff
                    // background task registering and playing
                    NotificationCenter.default.addObserver(self, selector: #selector(self.reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
                })
            }
            
        }
        
        // Add Button with Duration Status and custom Colors
        _ = buyNowAlertView.addButton("Cancel", backgroundColor: Style.Colors.pureYellowColor, textColor: Style.Colors.darkLimeGreenColor) {
            self.buyNowAlertView.hideView()
        }
        _ = buyNowAlertView.showSuccess("Checkout".localized(), subTitle: "")

    }
    
    @objc func chooseValue(_ sender: Any) {
        self.availableValues.show()
    }
    
    // background stuff
    
    @objc func reinstateBackgroundTask() {
        if updateTimer != nil && (backgroundTask == UIBackgroundTaskInvalid) {
            registerBackgroundTask()
        }
    }
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    // MARK: alamofire api section
    func checkoutWithAPI() {
        
        self.cancelBtnPressed = false
        
        var data = [String: Any]()
        var middleData = [String: Any]()
        let giftCardSelectionObjeArr = NSMutableArray()
        
        var giftCardSelections = [String: Any]()

        giftCardSelections["merchantRefId"] = self.checkoutObj["merchantRefId"]
        giftCardSelections["Value"] = self.checkoutObj["Value"]
        
        giftCardSelectionObjeArr.add(giftCardSelections)
        
        middleData["retailerRefId"] = self.appDelegate.retailerRefIdStr
        middleData["simulationType"] = self.config.getValue("isSystemGenerated", fromStore: "settings") as! Bool ? 9 : 0
        middleData["SocialXGetYLicenseCodes"] = self.config.getValue("SocialXGetYLicenseCodes", fromStore: "settings") as! String
        middleData["simulationLicenseCypherText"] = ""
        middleData["trainingLicenseCypherText"] = ""
        middleData["giftCardSelections"] = giftCardSelectionObjeArr.copy()
        middleData["panelSelelections"] = []
        middleData["couponSelections"] = []
        middleData["somethingIKnowCredentialCypherText"] = "8CB2237D0679CA88DB6464EAC60DA96345513964"
        middleData["somethingIHaveCredentialCypherText"] = ""
        middleData["somethingIAmCredentialImageEncoded"] = ""
        middleData["isSomethingIAmCredentialImageDisplayed"] = false
        middleData["socialCheckoutLicenseCodes"] = ""
        
        data = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
        print(self.appDelegate.JSONStringify(data))
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.superview, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Waiting on Clerk..."
        
        AlamofireRequestAndResponse.sharedInstance.checkoutWithShoppingCart(data, success: { (res: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.superview, animated: true)
            self.checkoutPressedFlag = false
            let resData: [String: Any] = res["data"] as! [String: Any]
            self.checkoutResData = resData
            self.checkoutCoreRefID = res["correlationRefId"] as! String
            self.createCheckoutDlg(checkoutRes: resData)
            
        },
        failure: { (error: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.superview, animated: true)
            self.checkoutPressedFlag = false
            self.endBackgroundTask()
            let notification = UILocalNotification()
            notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
            notification.alertBody = "Oops! We seem to be having a problem connecting.\n Please try again later."
            notification.alertAction = "open"
            notification.hasAction = true
            notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
            UIApplication.shared.scheduleLocalNotification(notification)
            
            if let errorData: [String: Any] = error["error"] as? [String: Any] {
                let errorDescription = errorData["message"] as! String
                _ = SweetAlert().showAlert("Error!", subTitle: "Checkout error. \n \(errorDescription)", style: AlertStyle.error)
            } else {
                _ = SweetAlert().showAlert("Error!", subTitle: "Oops! We seem to be having a problem connecting.\n Please try again later.", style: AlertStyle.error)
            }
        })
    }
    
    
    // MARK: additional view creating section
    // add sdditional overlay view
    
    func createCheckoutDlg(checkoutRes : [String : Any]) {
        // Create custom Appearance Configuration

        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false,
            showCircularIcon: true
        )
        
        // Initialize SCLAlertView using custom Appearance
        self.checkoutDLG = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 290))
        subview.backgroundColor = UIColor(hexString: (checkoutRes["visualIdentifierColor"] as! String?)!)
        subview.layer.borderColor = UIColor.black.cgColor
        subview.layer.borderWidth = 1.0
        let x = (subview.frame.width - 210) / 2
        
        // make label font color based the background color
        let lblFontColor : UIColor = UIColor.contrastColor(color: subview.backgroundColor!)
        
        // Add code number labeel
        let lblCode = UILabel(frame: CGRect(x: x,y: 5,width: 210,height: 35))
        lblCode.layer.borderWidth = 0.0
        lblCode.numberOfLines = 1
        lblCode.text = checkoutRes["visualIdentifierCode"] as! String?
        lblCode.font = Style.Font.boldFontWithSize(size: 34)
        lblCode.textColor = lblFontColor
        lblCode.textAlignment = NSTextAlignment.center
        subview.addSubview(lblCode)
        
        // Add qrcode image
        let qrcodeImg = UIImageView(frame: CGRect(x: x + 15, y: lblCode.frame.maxY + 5, width: 180,height: 180))
        let resQRCode = QRCode((checkoutRes["licenseCypherText"] as! String?)!)
        qrcodeImg.image = resQRCode?.image
        subview.addSubview(qrcodeImg)
        
        // Add instruction labeel
        let lblInstruction = UILabel(frame: CGRect(x: x + 15,y: qrcodeImg.frame.maxY + 5,width: 180,height: 45))
        lblInstruction.layer.borderWidth = 0.0
        lblInstruction.numberOfLines = 0
        lblInstruction.text = "OK, Show this code to your cashier"
        lblInstruction.font = UIFont.systemFont(ofSize: 14.0)
        lblInstruction.textColor = lblFontColor
        lblInstruction.textAlignment = NSTextAlignment.left
        subview.addSubview(lblInstruction)
        
        // Add the subview to the alert's UI property
        self.checkoutDLG?.customSubview = subview
        _ = self.checkoutDLG?.addButton("Cancel", backgroundColor: Style.Colors.darkLimeGreenColor, textColor: UIColor.white) {
            self.cancelCheckout(checkoutRes: checkoutRes)
        }
        
        _ = self.checkoutDLG?.showSuccess("Checkout".localized(), subTitle: "")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.getCheckoutStatus()
            self.registerBackgroundTask()
            self.checkoutDLG?.view.makeToast("Checkout completed. Creating item(s)...")
        }
        
    }
    
    func createCheckouGeneratingtDlg(checkoutRes : [String : Any]) {
        
        // Create custom Appearance Configuration
        
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        
        // Initialize SCLAlertView using custom Appearance
        self.checkoutGeneratingDLG = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 278))
        subview.backgroundColor = UIColor(hexString: (checkoutRes["visualIdentifierColor"] as! String?)!)
        subview.layer.borderColor = UIColor.black.cgColor
        subview.layer.borderWidth = 1.0
        let x = (subview.frame.width - 210) / 2
        
        // make label font color based the background color
        let lblFontColor : UIColor = UIColor.contrastColor(color: subview.backgroundColor!)
        
        // Add code number labeel
        let lblCode = UILabel(frame: CGRect(x: x,y: 5,width: 210,height: 35))
        lblCode.layer.borderWidth = 0.0
        lblCode.numberOfLines = 1
        lblCode.text = checkoutRes["visualIdentifierCode"] as! String?
        lblCode.font = Style.Font.boldFontWithSize(size: 34)
        lblCode.textColor = lblFontColor
        lblCode.textAlignment = NSTextAlignment.center
        subview.addSubview(lblCode)
        
        // Add qrcode image
        let gearsImg = UIImageView(frame: CGRect(x: x + 15, y: lblCode.frame.maxY + 20, width: 180,height: 127))
        gearsImg.loadGif(name: "gears-0")
        
        subview.addSubview(gearsImg)
        
        // Add instruction labeel
        let lblInstruction = UILabel(frame: CGRect(x: x + 15,y: gearsImg.frame.maxY + 20,width: 180,height: 65))
        lblInstruction.layer.borderWidth = 0.0
        lblInstruction.numberOfLines = 0
        lblInstruction.text = "OK, We've recorded your transaction and are creating your Item(s)!"
        lblInstruction.font = UIFont.systemFont(ofSize: 14.0)
        lblInstruction.textColor = lblFontColor
        lblInstruction.textAlignment = NSTextAlignment.left
        subview.addSubview(lblInstruction)
        
        // Add the subview to the alert's UI property
        self.checkoutGeneratingDLG?.customSubview = subview
        _ = self.checkoutGeneratingDLG?.addButton("Cancel", backgroundColor: Style.Colors.darkLimeGreenColor, textColor: UIColor.white) {
//            self.cancelCheckout(checkoutRes: checkoutRes)
        }

        _ = self.checkoutGeneratingDLG?.showSuccess("Checkout".localized(), subTitle: "")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.checkoutGeneratingDLG?.view.makeToast("Item(s) created. Generating item(s)...")
        }
        
    }
    // get checkout calling status api
    
    func getCheckoutStatus() {
        if (!self.cancelBtnPressed) {
            
            let checkoutRes = self.checkoutResData
            
            let sessionStr: String = checkoutRes["checkoutSessionRefId"] as! String
            let coreRefID: String = self.checkoutCoreRefID
            let licenseCypherText : String = checkoutRes["licenseCypherText"] as! String
            let couponArr: NSArray = checkoutRes["couponSelections"] as! NSArray
            
            if (couponArr.count > 0) {
                getCouponCheckoutStatus()
            } else {
                self.couponDataArr = NSArray()
                self.getCouponResultSateFlg = true
            }
            
            print(licenseCypherText)

            if (checkoutGeneratingFlag) {
                let loadingNotification = MBProgressHUD.showAdded(to: (self.checkoutGeneratingDLG?.view)!, animated: true)
                loadingNotification?.mode = MBProgressHUDMode.indeterminate
                loadingNotification?.labelText = "Waiting on Clerk..."
            } else {
                let loadingNotification = MBProgressHUD.showAdded(to: (self.checkoutDLG?.view)!, animated: true)
                loadingNotification?.mode = MBProgressHUDMode.indeterminate
                loadingNotification?.labelText = "Waiting on Clerk..."
            }
            
            AlamofireRequestAndResponse.sharedInstance.getStatusWithCheckoutSessionGetMethodForGlobal(sessionStr, lisenceCode : licenseCypherText, coreRefID: coreRefID, success: { (res: [String: Any]) -> Void in
                
                if (self.checkoutGeneratingFlag) {
                    MBProgressHUD.hideAllHUDs(for: self.checkoutGeneratingDLG?.view, animated: true)
                } else {
                    MBProgressHUD.hideAllHUDs(for: self.checkoutDLG?.view, animated: true)
                }
                
                var resObjData: [String: Any] = (res["data"] as! [String: Any]?)!
                var resData: NSArray = (resObjData["giftCardStatuses"] as! NSArray?)!
                let resCouponData: NSArray = (resObjData["couponStatuses"] as! NSArray?)!
                
                var couponStateFlg : Bool = false
                
                if (couponArr.count != 0) {
                    if ((resCouponData.count != 0) && (resData.count != 0)) {
                        couponStateFlg = true
                    }
                } else {
                    if (resData.count != 0) {
                        couponStateFlg = true
                    }
                }
                
                if (couponStateFlg){ // check checkout ticket count
                    // change checkout dlg to generating dlg
                    if (!self.checkoutGeneratingFlag) {
                        UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut, animations: {
                            var viewFrame = self.checkoutDLG!.view.frame
                            viewFrame.origin.y += viewFrame.size.height
                            
                            self.checkoutDLG!.view.frame = viewFrame
                        }, completion: { finished in
                            self.checkoutDLG!.hideView()
                            self.createCheckouGeneratingtDlg(checkoutRes: self.checkoutResData)
                            self.checkoutGeneratingFlag = true
                            
                        })
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            self.getCheckoutStatus()
                        }
                        self.loopCount += 1
                    } else {
                        var sasUriFlg : Bool = true
                        let newResData : NSMutableArray = NSMutableArray()
                        print(self.appDelegate.JSONStringify(res))
                        
                        for item in resData {
                            
                            var checkItem = item as! [String : Any]
                            let imageName: String = checkItem["fileName"] as! String
                            
                            switch(checkItem["templateType"] as! Int) {
                            case 1:
//                                checkItem["fileName"] = String.init(format: "%@.giftcard.lazlo.jpeg", imageName)
                                checkItem["fileName"] = imageName
                                break
                            case 2:
                                checkItem["fileName"] = String.init(format: "%@.mp4", imageName)
                                break
                            case 3:
                                checkItem["fileName"] = String.init(format: "%@.mp4", imageName)
                                break
                            default:
                                break
                            }
                            checkItem["isGiftCard"] = true
                            newResData.insert(checkItem, at: 0)
                        }
                        
                        for item in resCouponData {
                            
                            var checkItem = item as! [String : Any]
                            let imageName: String = checkItem["fileName"] as! String
                            
                            switch(checkItem["templateType"] as! Int) {
                            case 1:
//                                checkItem["fileName"] = String.init(format: "%@.coupon.lazlo.jpg", imageName)
                                checkItem["fileName"] = imageName
                                break
                            case 2:
                                checkItem["fileName"] = String.init(format: "%@.mp4", imageName)
                                break
                            case 3:
                                checkItem["fileName"] = String.init(format: "%@.mp4", imageName)
                                break
                            default:
                                break
                            }
                            checkItem["isGiftCard"] = false
                            newResData.insert(checkItem, at: 0)
                        }
                        
                        if let tempArray = (newResData.copy() as! NSArray) as? [[String : Any]] {
                            let sortedArray = tempArray.sorted { (obj1, obj2) -> Bool in
                                return (obj1["mediaSize"] as! Float) < (obj2["mediaSize"] as! Float)
                            }
                            resData = sortedArray as NSArray
                        }
                        
                        for item in resData {
                            var checkItem = item as! [String : Any]
                            if let _ = checkItem["sasUri"] as? String {
                                sasUriFlg = true
                            } else {
                                sasUriFlg = false
                                break
                            }
                        }
                        
                        if sasUriFlg{ // check the checkout file url is null or not
                            
                            let savingTicketArr : NSMutableArray = NSMutableArray()
                            
                            for item in resData{
                                var checkItem = item as! [String : Any]
                                
                                let currentDate = Date()
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "MM/dd/YYYY hh:mm a"
                                let convertedDate = dateFormatter.string(from: currentDate)
                                checkItem["giftDownloadDate"] = convertedDate
                                checkItem["checkoutSessionRefId"] = sessionStr
                                checkItem["licenseCypherText"] = licenseCypherText
                                checkItem["giftItemObj"] = self.giftCardObj
                                checkItem["isValid"] = false
                                checkItem["isCompleted"] = false
                                checkItem["isClaimed"] = false
                                
                                if let _ = checkItem["sasUri"] as? String {
                                    savingTicketArr.add(checkItem)
                                }
                            }
                            
                            let copyTickArr : NSArray = savingTicketArr.copy() as! NSArray
                            
                            // after 0.5 seconds dismiss the dialog view and push the file download view
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.endBackgroundTask()
                                let notification = UILocalNotification()
                                notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                                notification.alertBody = "Hi Dear, You're Country Fair download is complete!"
                                notification.alertAction = "open"
                                notification.hasAction = true
                                notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
                                UIApplication.shared.scheduleLocalNotification(notification)
                                UIView.animate(withDuration: 1, animations: {
                                    if (self.checkoutGeneratingDLG != nil) {
                                        self.checkoutGeneratingDLG!.view.alpha = 0.0
                                    }
                                }, completion: { Bool in
                                    if (self.checkoutGeneratingDLG != nil) {
                                        self.checkoutGeneratingDLG?.hideView()
                                    }
                                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                                    
                                    let checkoutDownloadVC = storyBoard.instantiateViewController(withIdentifier: "checkoutDownloadView") as! CheckoutFileDownloadViewController
//                                    checkoutDownloadVC.downloadFileArr = resData as! [[String : Any]]
                                    checkoutDownloadVC.downloadFileArr = copyTickArr as! [[String : Any]]
                                    checkoutDownloadVC.giftSuccessArr = copyTickArr
//                                    self.superview.present(checkoutDownloadVC, animated: true, completion: nil)
                                    self.selfViewController.present(checkoutDownloadVC, animated: true, completion: nil)
                                })
                            }
                        } else {
                            
                            // repeat while getting all sass url from server
                            if (self.loopCount < 50) { // if there is no any file url(sasUrl) replay the checkout status getting call
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    self.getCheckoutStatus()
                                }
                                self.loopCount += 1
                            } else {
                                if (self.checkoutGeneratingFlag) {
                                    MBProgressHUD.hideAllHUDs(for: self.checkoutGeneratingDLG?.view, animated: true)
                                } else {
                                    MBProgressHUD.hideAllHUDs(for: self.checkoutDLG?.view, animated: true)
                                }
                                self.checkoutGeneratingDLG?.hideView()
                                
                                let savingTicketErrorArr : NSMutableArray = NSMutableArray()
                                let savingTicketArr : NSMutableArray = NSMutableArray()
                                
                                for item in resData{
                                    var checkItem = item as! [String : Any]
                                    
                                    let currentDate = Date()
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "MM/dd/YYYY hh:mm a"
                                    let convertedDate = dateFormatter.string(from: currentDate)
                                    checkItem["giftDownloadDate"] = convertedDate
                                    checkItem["checkoutSessionRefId"] = sessionStr
                                    checkItem["licenseCypherText"] = licenseCypherText
                                    checkItem["giftItemObj"] = self.giftCardObj
                                    checkItem["isValid"] = false
                                    checkItem["isCompleted"] = false
                                    checkItem["isClaimed"] = false
                                    
                                    if let _ = checkItem["sasUri"] as? String {
                                        savingTicketArr.add(checkItem)
                                    } else {
                                        savingTicketErrorArr.add(checkItem)
                                    }
                                }
                                
                                let copyErrorArr : NSArray = savingTicketErrorArr.copy() as! NSArray
                                let copyTickArr : NSArray = savingTicketArr.copy() as! NSArray
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.endBackgroundTask()
                                    let notification = UILocalNotification()
                                    notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                                    notification.alertBody = "Oops! The download failed."
                                    notification.alertAction = "open"
                                    notification.hasAction = true
                                    notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
                                    UIApplication.shared.scheduleLocalNotification(notification)
                                    UIView.animate(withDuration: 1, animations: {
                                        if (self.checkoutGeneratingDLG != nil) {
                                            self.checkoutGeneratingDLG!.view.alpha = 0.0
                                        }
                                    }, completion: { Bool in
                                        if (self.checkoutGeneratingDLG != nil) {
                                            self.checkoutGeneratingDLG?.hideView()
                                        }
                                        
                                        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                                        let checkoutDownloadVC = storyBoard.instantiateViewController(withIdentifier: "checkoutDownloadView") as! CheckoutFileDownloadViewController
                                        checkoutDownloadVC.downloadFileArr = copyTickArr as! [[String : Any]]
                                        checkoutDownloadVC.giftSuccessArr = copyTickArr
                                        checkoutDownloadVC.giftErrorArr = copyErrorArr
                                        self.selfViewController.present(checkoutDownloadVC, animated: true, completion: nil)
                                    })
                                }
                                self.loopCount = 0
                            }
                        }
                    }
                    
                } else {
                    // if there is no any checkout ticket data retry the checkout status getting api
                    if (self.loopCount < 50) { // if there is no any file url(sasUrl) replay the checkout status getting call
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.getCheckoutStatus()
                        }
                        self.loopCount += 1
                    } else {
                        
                        if (self.checkoutGeneratingFlag) {
                            MBProgressHUD.hideAllHUDs(for: self.checkoutGeneratingDLG?.view, animated: true)
                        } else {
                            MBProgressHUD.hideAllHUDs(for: self.checkoutDLG?.view, animated: true)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.endBackgroundTask()
                            let notification = UILocalNotification()
                            notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                            notification.alertBody = "Hi Dear, You're Country Fair download is complete!"
                            notification.alertAction = "open"
                            notification.hasAction = true
                            notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
                            UIApplication.shared.scheduleLocalNotification(notification)
                            UIView.animate(withDuration: 1, animations: { self.checkoutDLG!.view.alpha = 0.0 }, completion: { Bool in
                                self.checkoutDLG?.hideView()
                                _ = SweetAlert().showAlert("Error!", subTitle: "Oops! We seem to be having a problem checking out. \n Please try again later.", style: AlertStyle.error)
                            })
                        }
                        self.loopCount = 0
                    }
                    
                }
                
            },
             failure: { (error: [String: Any]) -> Void in
                
                if (self.checkoutGeneratingFlag) {
                    MBProgressHUD.hideAllHUDs(for: self.checkoutGeneratingDLG?.view, animated: true)
                } else {
                    MBProgressHUD.hideAllHUDs(for: self.checkoutDLG?.view, animated: true)
                }
                
                if (self.getStatusErrorLoopCount < 5) {
                    self.getStatusErrorLoopCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.getStatusErrorLoopCount)) {
                        self.getCheckoutStatus()
                    }
                } else {
                    
                    self.endBackgroundTask()
                    let notification = UILocalNotification()
                    notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                    notification.alertBody = "Oops! We seem to be having a problem connecting. \n Please try again later."
                    notification.alertAction = "open"
                    notification.hasAction = true
                    notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
                    UIApplication.shared.scheduleLocalNotification(notification)
                    
                    self.checkoutDLG?.hideView()
                    if let errorData: [String: Any] = error["error"] as? [String: Any] {
                        let errorDescription = errorData["message"] as! String
                        _ = SweetAlert().showAlert("Error!", subTitle: "Checkout error. \n \(errorDescription)", style: AlertStyle.error)
                    } else {
                        _ = SweetAlert().showAlert("Error!", subTitle: "Oops! We seem to be having a problem connecting. \n Please try again later.", style: AlertStyle.error)
                    }
                    self.getStatusErrorLoopCount = 0
                }
            })
            
        } else {
            self.cancelBtnPressed = false
        }
    }
    
    
    func getCouponCheckoutStatus() {
        let checkoutRes = self.checkoutResData
        
        let sessionStr: String = checkoutRes["checkoutSessionRefId"] as! String
        let licenseCypherText : String = checkoutRes["licenseCypherText"] as! String
        
        if (checkoutGeneratingFlag) {
            let loadingNotification = MBProgressHUD.showAdded(to: (self.checkoutGeneratingDLG?.view)!, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.labelText = "Generating..."
        } else {
            let loadingNotification = MBProgressHUD.showAdded(to: (self.checkoutDLG?.view)!, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.labelText = "Creating..."
        }
        
        AlamofireRequestAndResponse.sharedInstance.getStatusWithCheckoutSessionGetMethodForCoupons(sessionStr, lisenceCode : licenseCypherText,success: { (res: [String: Any]) -> Void in
            let resData: NSArray = (res["data"] as! NSArray?)!
            if (resData.count != 0){ // check checkout ticket count
                print(self.appDelegate.JSONStringify(res))
                self.couponDataArr = resData
                self.getCouponResultSateFlg = true
            }
            
        },
        failure: { (error: [String: Any]) -> Void in
            
        })
    }
    // checkout cancel api calling
    
    func cancelCheckout(checkoutRes : [String : Any]) {
        if (self.checkoutGeneratingFlag) {
            MBProgressHUD.hideAllHUDs(for: self.checkoutGeneratingDLG?.view, animated: true)
        } else {
            MBProgressHUD.hideAllHUDs(for: self.checkoutDLG?.view, animated: true)
        }
        self.endBackgroundTask()
        self.cancelBtnPressed = true
        var data = [String: Any]()
        var middleData = [String: Any]()
        
        middleData["checkoutSessionLicenseCode"] = checkoutRes["licenseCypherText"] as! String
        
        data = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
//        print(self.appDelegate.JSONStringify(data))
        
        if (checkoutGeneratingFlag) {
            let loadingNotification = MBProgressHUD.showAdded(to: (self.checkoutGeneratingDLG?.view)!, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.labelText = "Loading..."
        } else {
            let loadingNotification = MBProgressHUD.showAdded(to: (self.checkoutDLG?.view)!, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.labelText = "Loading..."
        }
        AlamofireRequestAndResponse.sharedInstance.cancelCheckoutWithSession(data, success: { (res: [String: Any]) -> Void in
            self.checkoutGeneratingFlag = false
            if (self.checkoutGeneratingFlag) {
                MBProgressHUD.hideAllHUDs(for: self.checkoutGeneratingDLG?.view, animated: true)
            } else {
                MBProgressHUD.hideAllHUDs(for: self.checkoutDLG?.view, animated: true)
            }
            self.endBackgroundTask()
            let resData = res["data"] as! Bool
            if (resData) {
                _ = SweetAlert().showAlert("Cancelled!", subTitle: "Your checkout was cancelled", style: AlertStyle.success)
            }
            print(resData)
        },
         failure: { (error: Error!) -> Void in
            if (self.checkoutGeneratingFlag) {
                MBProgressHUD.hideAllHUDs(for: self.checkoutGeneratingDLG?.view, animated: true)
            } else {
                MBProgressHUD.hideAllHUDs(for: self.checkoutDLG?.view, animated: true)
            }
            self.checkoutGeneratingFlag = false
            self.endBackgroundTask()
            SweetAlert().showAlert("Oops! Cancel failed. Try again?", subTitle: "", style: AlertStyle.warning, buttonTitle:"No Thanks", buttonColor:UIColor.init(hexString: "#D0D0D0") , otherButtonTitle:  "Try Again", otherButtonColor: UIColor.init(hexString: "#DD6B55")) { (isOtherButton) -> Void in
                if isOtherButton == true {
                    print("Cancel Button  Pressed")
                }
                else {
                    self.cancelCheckout(checkoutRes: checkoutRes)
                }
            }
            
        })
    }
    
    @objc func handleGiftCardImageTap(sender: UITapGestureRecognizer) {
        let terms = self.giftCardObj["merchantTerms"] as? String
        let url = self.giftCardObj["merchandiseImageUrl"] as? String
        self.delegate?.didGiftCardImageClicked(url, terms: terms)
    }

}
