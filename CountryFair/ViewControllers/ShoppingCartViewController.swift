//
//  ShoppingCartViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import Refresher
import Kingfisher
import SCLAlertView
import QRCode
import SwiftGifOrigin

class ShoppingCartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ShoppingCardTableViewCellDelegate {
    
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnCheckOut: UIButton!
    @IBOutlet weak var lblTotalAmount: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblShoppingCartItemCount: UILabel!
    
    var checkoutCoreRefID : String! = ""
    lazy var shoppingCartData : NSArray! = NSArray()
    var orgData: [String:Any] = [:]
    var checkoutResData: [String:Any] = [:]
    var totalPrice: Double = 0.0
    var loopCount: Int = 0
    var getStatusErrorLoopCount: Int = 0
    
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    lazy var messageFrame = UIView()
    var checkoutDLG : SCLAlertView?
    var checkoutConfirmDLG : SCLAlertView?
    var checkoutGeneratingDLG : SCLAlertView?
    lazy var transprentView = UIView()
    lazy var imgCheckoutView = UIImageView()
    lazy var activityIndicator = UIActivityIndicatorView()
    lazy var strLabel = UILabel()
    
    // background job stuff
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var updateTimer: Timer?
    
    // checkout button pressed flag
    var checkoutPressedFlag : Bool = false
    var cancelBtnPressed : Bool = false
    var checkoutGeneratingFlag : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.reloadAllData()
        
        self.tableView.separatorStyle = .none
        // add table view refresher
        if let customSubview = Bundle.main.loadNibNamed("CustomSubview", owner: self, options: nil)?.first as? CustomSubview {
            tableView.addPullToRefreshWithAction({
                OperationQueue().addOperation {
                    //                    sleep(2)
                    OperationQueue.main.addOperation {
                        self.reloadAllData()
                        self.tableView.stopPullToRefresh()
                    }
                }
            }, withAnimator: customSubview)
        }
        
        // check retailer and beacon state
        if (!(UserDefaults.standard.object(forKey: "retailerExistFlag") as! Bool)) {
            self.btnCheckOut.isEnabled = false
        }
        
        // initialization background stuff
        // background task registering and playing
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        // Do any additional setup after loading the view.
    }
    
    // MARK: background service part
    
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
    
    func checkUserSelfie() -> Bool{
        return config.getValue("selfieHasBeenTaken", fromStore: "settings") as! Bool
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadAllData() {
        
        // get all shopping cart data
        self.totalPrice = 0.0
        var totalCount : Int = 0
        let midData: [String:Any] = self.appDelegate.getJSONDataFromLocal()
        self.orgData = midData["shoppingCarts"] as! [String:Any]
        self.shoppingCartData = self.orgData["items"] as! NSArray
        for item in shoppingCartData {
            var midData = item as! [String : Any]
            let amountDlb = midData["playAmount"] as! Double
            let numberOfPlays = midData["panelCount"] as! Int
            totalCount = totalCount + numberOfPlays
            self.imgCheckoutView.sd_setImage(with: URL(string: midData["tileUrl"] as! String))
            self.totalPrice = self.totalPrice + (amountDlb * Double(numberOfPlays))
        }
        
        self.lblShoppingCartItemCount.text = "\(totalCount)"
        self.lblTotalAmount.text = String.init(format: "Total : $%.2f", self.totalPrice)
        self.tableView.reloadData()
        // check main view start state and display overlay
        if (!(config.getValue("shoppingCartHelpOverlayHasShown", fromStore: "settings") as! Bool)){
            self.createOverlayView()
        }
        
    }
    
    /**************************************************************************************
     *
     *  UITable View Delegate Functions
     *
     **************************************************************************************/
    
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.shoppingCartData.count
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > -1 {}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :ShoppingCartTableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "shoppingCartTableViewCell") as? ShoppingCartTableViewCell
        let sampleData: [String : Any] = self.shoppingCartData[indexPath.row] as! [String : Any]
        
        cell?.configWithData(item: sampleData)
        cell?.selectionStyle = .none
        cell?.cellDelegate = self
        return cell!
    }
    
    //Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            let item = self.shoppingCartData[indexPath.row] as! [String : Any]
            _ = self.appDelegate.deleteOneItem(data: item)
            self.reloadAllData()
        }
        delete.backgroundColor = UIColor.lightGray
        
        let deleteAll = UITableViewRowAction(style: .normal, title: "Delete All") { action, index in
            _ = self.appDelegate.saveInitJsonData()
            self.reloadAllData()
            
        }
        deleteAll.backgroundColor = UIColor.orange
        
        return [delete, deleteAll]
    }
    
    //Override to support custom section headers.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0;
    }
    
    // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    // end table view helper //
    
    @IBAction func btnBackAction(_ sender: AnyObject) {
        //        _ = navigationController?.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnCheckoutAction(_ sender: AnyObject) {
        //check battery level
        if !UIDevice.current.isSimulator {
            UIDevice.current.isBatteryMonitoringEnabled = true
            print(UIDevice.current.batteryLevel)
            if UIDevice.current.batteryLevel < 0.05 {
                _ = SweetAlert().showAlert("Oops!".localized(), subTitle: "Your battery is too low to complete a checkout. Please connect to a charger and try again.".localized(), style: AlertStyle.warning)
                return
            }
        }
        
        if (!checkoutPressedFlag) {
            self.checkoutPressedFlag = true
            self.btnCheckOut.isEnabled = false
            if (self.shoppingCartData.count == 0){
                _ = SweetAlert().showAlert("Warning!".localized(), subTitle: "There is no any checkout data.".localized(), style: AlertStyle.warning)
            } else {
                self.checkoutWithAPI()
            }
        }
    }
    
    // MARK: alamofire api section
    func checkoutWithAPI() {
        self.cancelBtnPressed = false
        
        var data = [String: Any]()
        var middleData = [String: Any]()
        let panelSelectionObjeArr = NSMutableArray()
        var panelSelection = [String: Any]()
        
        for cartItem in self.shoppingCartData {
            
            let shoppingCartItem = cartItem as! [String :Any]
            
            panelSelection["externalPanelId"] = nil
            panelSelection["brandRefId"] = shoppingCartItem["brandRefId"]
            panelSelection["ticketTemplateRefId"] = shoppingCartItem["templateRefId"]
            panelSelection["channelRefId"] = shoppingCartItem["channelRefId"]
            panelSelection["gameRefId"] = nil
            panelSelection["drawRefId"] = shoppingCartItem["drawRefId"]
            panelSelection["playAmount"] = shoppingCartItem["playAmount"]
            panelSelection["componentSelections"] = nil
            panelSelection["isSystemGenerated"] = true
            
            // simulate data for testing
            var componentData: [String : Any] = [String : Any]()
            componentData["componentRefId"] = ""
            componentData["optionRefId"] = ""
            
            panelSelection["data"] = nil
            
            for _ in 0..<(shoppingCartItem["panelCount"] as! Int) {
                panelSelectionObjeArr.add(panelSelection)
            }
            
        }
        
        //        let imageData = UIImageJPEGRepresentation(imgCheckoutView.image!, 1.0)
        //        let strBase64:String = imageData!.base64EncodedString(options: .lineLength64Characters)
        
        //        print(self.appDelegate.retailerRefIdStr)
        middleData["retailerRefId"] = self.appDelegate.retailerRefIdStr
        middleData["simulationType"] = self.config.getValue("isSystemGenerated", fromStore: "settings") as! Bool ? 9 : 0
        middleData["simulationLicenseCypherText"] = nil
        middleData["trainingLicenseCypherText"] = ""
        middleData["panelSelections"] = panelSelectionObjeArr.copy()
        middleData["somethingIKnowCredentialCypherText"] = "8CB2237D0679CA88DB6464EAC60DA96345513964"
        if (config.getValue("pinEnableState", fromStore: "settings") as! Bool) {
            middleData["somethingIKnowCredentialCypherText"] = config.getValue("pinHashValue", fromStore: "settings") as! String
        }
        middleData["somethingIHaveCredentialCypherText"] = ""
        if (self.checkUserSelfie()) {
            let userImageStr = (UserDefaults.standard.object(forKey: "userSelfieImage")) as! String
            middleData["somethingIAmCredentialImageEncoded"] = userImageStr
            middleData["isSomethingIAmCredentialImageDisplayed"] = true
        } else {
            middleData["somethingIAmCredentialImageEncoded"] = ""
            middleData["isSomethingIAmCredentialImageDisplayed"] = false
        }
        middleData["socialCheckoutLicenseCodes"] = nil
        
        data = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
        //        if (!(self.config.getValue("demoDataFlag", fromStore: "settings") as! Bool)) {
        //            data = self.makeTempararyData()
        //        }
        print(self.appDelegate.JSONStringify(data))
        
        self.progressBarDisplayer("Waiting on Clerk...".localized(), true, self.view)
        
        AlamofireRequestAndResponse.sharedInstance.checkoutWithShoppingCart(data, success: { (res: [String: Any]) -> Void in
            self.checkoutPressedFlag = false
            self.btnCheckOut.isEnabled = true
            self.messageFrame.removeFromSuperview()
            let resData: [String: Any] = res["data"] as! [String: Any]
            self.checkoutCoreRefID = res["correlationRefId"] as! String
            self.checkoutResData = resData
            self.createCheckoutDlg(checkoutRes: resData)
        }, failure: { (error: [String: Any]) -> Void in
            self.checkoutPressedFlag = false
            self.btnCheckOut.isEnabled = true
            self.endBackgroundTask()
            let notification = UILocalNotification()
            notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
            notification.alertBody = "Oops! We seem to be having a problem connecting.\n Please try again later."
            notification.alertAction = "open"
            notification.hasAction = true
            notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
            UIApplication.shared.scheduleLocalNotification(notification)
            
            self.messageFrame.removeFromSuperview()
            if let errorData: [String: Any] = error["error"] as? [String: Any] {
                let errorDescription = errorData["message"] as! String
                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Checkout error. \n \(errorDescription)", style: AlertStyle.error)
            } else {
                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! We seem to be having a problem connecting.\n Please try again later.".localized(), style: AlertStyle.error)
            }
        })
    }
    
    // get checkout calling status api
    
    func getCheckoutStatus() {
        if (!self.cancelBtnPressed) {
            let checkoutRes = self.checkoutResData
            
            let sessionStr: String = checkoutRes["checkoutSessionRefId"] as! String
            let coreRefID: String = self.checkoutCoreRefID
            let licenseCypherText : String = checkoutRes["licenseCypherText"] as! String
            let _: NSArray = checkoutRes["couponSelections"] as! NSArray
            let giftArr: NSArray = checkoutRes["giftCardSelections"] as! NSArray
            
            print(licenseCypherText)
            if (checkoutGeneratingFlag) {
                self.progressBarDisplayer("Waiting on Clerk...".localized(), true, (self.checkoutGeneratingDLG?.view)!)
            } else {
                self.progressBarDisplayer("Waiting on Clerk...".localized(), true, (self.checkoutDLG?.view)!)
            }
            
            AlamofireRequestAndResponse.sharedInstance.getStatusWithCheckoutSessionGetMethodForGlobal(sessionStr, lisenceCode : licenseCypherText, coreRefID : coreRefID, success: { (res: [String: Any]) -> Void in
                self.messageFrame.removeFromSuperview()
                
                var resObjData: [String: Any] = (res["data"] as! [String: Any]?)!
                var resData: NSArray = (resObjData["ticketStatuses"] as! NSArray?)!
                let resGiftData: NSArray = (resObjData["giftCardStatuses"] as! NSArray?)!
                var _: NSArray = (resObjData["couponStatuses"] as! NSArray?)!
//                var couponStateFlg = false
//
//                if (giftArr.count != 0) {
//                    if ((resGiftData.count != 0) && (resData.count != 0)) {
//                        couponStateFlg = true
//                    }
//                } else {
//                    if (resData.count != 0) {
//                        couponStateFlg = true
//                    }
//                }
                
                if (resData.count != 0){ // check checkout ticket count
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
                            let imageName: String = checkItem["ticketRefId"] as! String
                            
                            switch(checkItem["ticketTemplateType"] as! Int) {
                            case 1:
                                checkItem["fileName"] = String.init(format: "%@.ticket.lazlo.jpg", imageName)
                                break;
                            case 2:
                                checkItem["fileName"] = String.init(format: "%@.ticket.lazlo.mp4", imageName)
                                break;
                            case 3:
                                checkItem["fileName"] = String.init(format: "%@.ticket.lazlo.mp4", imageName)
                                break;
                            default:
                                break;
                            }
                            checkItem["isGiftCard"] = false
                            newResData.insert(checkItem, at: 0)
                        }
                        
                        for item in resGiftData {
                            
                            var checkItem = item as! [String : Any]
                            //                            let imageName: String = checkItem["ticketRefId"] as! String
                            let imageName: String = checkItem["fileName"] as! String
                            
                            switch(checkItem["templateType"] as! Int) {
                            case 1:
                                //                                checkItem["fileName"] = String.init(format: "%@.giftcard.lazlo.jpeg", imageName)
                                checkItem["fileName"] = imageName
                                break
                            case 2:
                                checkItem["fileName"] = String.init(format: "%@.giftcard.lazlo.mp4", imageName)
                                break;
                            case 3:
                                checkItem["fileName"] = String.init(format: "%@.giftcard.lazlo.mp4", imageName)
                                break;
                            default:
                                break;
                            }
                            checkItem["isGiftCard"] = true
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
                                
                                let returnedChannelRefId = checkItem["channelRefId"] as! String
                                
                                for item1 in self.appDelegate.channelGroupGlobalArr {
                                    let channelGroupItem = item1 as! [String : Any]
                                    let channels = channelGroupItem["channels"] as! NSArray
                                    for item2 in channels {
                                        var channelItem = item2 as! [String : Any]
                                        
                                        if (channelItem["channelRefId"] as! String == returnedChannelRefId) {
                                            
                                            let ticketTemplateData = channelItem["ticketTemplate"] as! [String : Any]
                                            let gameRefId = channelGroupItem["gameRefId"] as! String
                                            for item3 in self.appDelegate.gameGlobalArr {
                                                let gameItem = item3 as! [String : Any]
                                                if (gameItem["gameRefId"] as! String == gameRefId){
                                                    channelItem["gameRefId"] = gameRefId
                                                    channelItem["gameLogoUrl"] = gameItem["logoUrl"] as! String
                                                    channelItem["animatedState"] = true
                                                    channelItem["tileUrl"] = ticketTemplateData["tileUrl"] as! String
                                                    channelItem["animatedTileUrl"] = ticketTemplateData["tileAnimatedUrl"] as! String
                                                    break
                                                }
                                            }
                                            
                                            checkItem["gameData"] = channelItem
                                        }
                                    }
                                }
                                //                                for item1 in self.shoppingCartData {
                                //                                    let channelGroupItem = item1 as! [String : Any]
                                //                                    if (channelGroupItem["channelRefId"] as! String == returnedChannelRefId) {
                                //                                        checkItem["gameData"] = channelGroupItem
                                //                                    }
                                //                                }
                                
                                let currentDate = Date()
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "MM/dd/YYYY hh:mm a"
                                let convertedDate = dateFormatter.string(from: currentDate)
                                checkItem["ticketDownloadDate"] = convertedDate
                                checkItem["checkoutSessionRefId"] = sessionStr
                                checkItem["licenseCypherText"] = licenseCypherText
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
                                notification.alertBody = "Yes! Item has downloaded!"
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
                                    
                                    let checkoutDownloadVC = storyBoard.instantiateViewController(withIdentifier: "ticketFileDownloadView") as! TicketFileDownloadViewController
                                    checkoutDownloadVC.downloadFileArr = resData as! [[String : Any]]
                                    checkoutDownloadVC.ticketSuccessArr = copyTickArr
                                    checkoutDownloadVC.shoppingCartArr = self.shoppingCartData
                                    self.present(checkoutDownloadVC, animated: true, completion: nil)
                                })
                            }
                        } else {
                            
                            // repeat while getting all sass url from server
                            if (self.loopCount < 100) { // if there is no any file url(sasUrl) replay the checkout status getting call
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    self.getCheckoutStatus()
                                }
                                self.loopCount += 1
                            } else {
                                
                                self.messageFrame.removeFromSuperview()
                                self.checkoutGeneratingDLG?.hideView()
                                
                                let savingTicketErrorArr : NSMutableArray = NSMutableArray()
                                let savingTicketArr : NSMutableArray = NSMutableArray()
                                
                                for item in resData{
                                    var checkItem = item as! [String : Any]
                                    
                                    let returnedChannelRefId = checkItem["channelRefId"] as! String
                                    
                                    for item1 in self.appDelegate.channelGroupGlobalArr {
                                        let channelGroupItem = item1 as! [String : Any]
                                        let channels = channelGroupItem["channels"] as! NSArray
                                        for item2 in channels {
                                            var channelItem = item2 as! [String : Any]
                                            
                                            if (channelItem["channelRefId"] as! String == returnedChannelRefId) {
                                                
                                                let ticketTemplateData = channelItem["ticketTemplate"] as! [String : Any]
                                                let gameRefId = channelGroupItem["gameRefId"] as! String
                                                for item3 in self.appDelegate.gameGlobalArr {
                                                    let gameItem = item3 as! [String : Any]
                                                    if (gameItem["gameRefId"] as! String == gameRefId){
                                                        channelItem["gameRefId"] = gameRefId
                                                        channelItem["gameLogoUrl"] = gameItem["logoUrl"] as! String
                                                        channelItem["animatedState"] = true
                                                        channelItem["tileUrl"] = ticketTemplateData["tileUrl"] as! String
                                                        channelItem["animatedTileUrl"] = ticketTemplateData["tileAnimatedUrl"] as! String
                                                        break
                                                    }
                                                }
                                                
                                                checkItem["gameData"] = channelItem
                                            }
                                        }
                                    }
                                    
                                    let currentDate = Date()
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "MM/dd/YYYY hh:mm a"
                                    let convertedDate = dateFormatter.string(from: currentDate)
                                    checkItem["ticketDownloadDate"] = convertedDate
                                    checkItem["checkoutSessionRefId"] = sessionStr
                                    checkItem["licenseCypherText"] = licenseCypherText
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
                                        
                                        let checkoutDownloadVC = storyBoard.instantiateViewController(withIdentifier: "ticketFileDownloadView") as! TicketFileDownloadViewController
                                        checkoutDownloadVC.downloadFileArr = resData as! [[String : Any]]
                                        checkoutDownloadVC.ticketSuccessArr = copyTickArr
                                        checkoutDownloadVC.ticketErrorArr = copyErrorArr
                                        
                                        checkoutDownloadVC.shoppingCartArr = self.shoppingCartData
                                        self.present(checkoutDownloadVC, animated: true, completion: nil)
                                    })
                                }
                                self.loopCount = 0
                            }
                        }
                    }
                    
                } else {
                    // if there is no any checkout ticket data retry the checkout status getting api
                    if (self.loopCount < 100) { // if there is no any file url(sasUrl) replay the checkout status getting call
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.getCheckoutStatus()
                        }
                        self.loopCount += 1
                    } else {
                        
                        self.messageFrame.removeFromSuperview()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.endBackgroundTask()
                            let notification = UILocalNotification()
                            notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                            notification.alertBody = "Oops! The download failed."
                            notification.alertAction = "open"
                            notification.hasAction = true
                            notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
                            UIApplication.shared.scheduleLocalNotification(notification)
                            UIView.animate(withDuration: 1, animations: { self.checkoutDLG!.view.alpha = 0.0 }, completion: { Bool in
                                self.checkoutDLG?.hideView()
                                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! We seem to be having a problem checking out. \n Please try again later.".localized(), style: AlertStyle.error)
                            })
                        }
                        self.loopCount = 0
                    }
                    
                }
                
            },
                                                                                                      failure: { (error: [String: Any]) -> Void in
                                                                                                        
                                                                                                        self.messageFrame.removeFromSuperview()
                                                                                                        
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
                                                                                                                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Checkout error. \n \(errorDescription)", style: AlertStyle.error)
                                                                                                            } else {
                                                                                                                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! We seem to be having a problem connecting. \n Please try again later.".localized(), style: AlertStyle.error)
                                                                                                            }
                                                                                                            self.getStatusErrorLoopCount = 0
                                                                                                        }
            })
            
        } else {
            self.cancelBtnPressed = false
        }
    }
    
    // checkout cancel api calling
    
    func cancelCheckout(checkoutRes : [String : Any]) {
        self.messageFrame.removeFromSuperview()
        self.endBackgroundTask()
        self.cancelBtnPressed = true
        
        var data = [String: Any]()
        var middleData = [String: Any]()
        
        middleData["checkoutSessionLicenseCode"] = checkoutRes["licenseCypherText"] as! String
        
        data = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
        //        print(self.appDelegate.JSONStringify(data))
        
        if (checkoutGeneratingFlag) {
            self.progressBarDisplayer("Loading...".localized(), true, (self.checkoutGeneratingDLG?.view)!)
        } else {
            self.progressBarDisplayer("Loading...".localized(), true, (self.checkoutDLG?.view)!)
        }
        
        AlamofireRequestAndResponse.sharedInstance.cancelCheckoutWithSession(data, success: { (res: [String: Any]) -> Void in
            self.checkoutGeneratingFlag = false
            self.messageFrame.removeFromSuperview()
            self.endBackgroundTask()
            let resData = res["data"] as! Bool
            if (resData) {
                _ = SweetAlert().showAlert("Cancelled!".localized(), subTitle: "Your checkout was cancelled".localized(), style: AlertStyle.success)
            }
            print(resData)
        },
                                                                             failure: { (error: Error!) -> Void in
                                                                                self.messageFrame.removeFromSuperview()
                                                                                self.checkoutGeneratingFlag = false
                                                                                self.endBackgroundTask()
                                                                                SweetAlert().showAlert("Oops! Cancel failed. Try again?".localized(), subTitle: "", style: AlertStyle.warning, buttonTitle:"No Thanks".localized(), buttonColor:UIColor.init(hexString: "#D0D0D0") , otherButtonTitle:  "Try Again".localized(), otherButtonColor: UIColor.init(hexString: "#DD6B55")) { (isOtherButton) -> Void in
                                                                                    if isOtherButton == true {
                                                                                        print("Cancel Button  Pressed")
                                                                                    }
                                                                                    else {
                                                                                        self.cancelCheckout(checkoutRes: checkoutRes)
                                                                                    }
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
        _ = self.checkoutDLG?.addButton("Cancel".localized(), backgroundColor: Style.Colors.darkLimeGreenColor, textColor: UIColor.white) {
            self.cancelCheckout(checkoutRes: checkoutRes)
        }
        
        _ = self.checkoutDLG?.showSuccess("Checkout".localized(), subTitle: "")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.getCheckoutStatus()
            self.registerBackgroundTask()
            self.checkoutDLG?.view.makeToast("Checkout completed. Creating item(s)...".localized())
        }
        
    }
    
    func createCheckouGeneratingtDlg(checkoutRes : [String : Any]) {
        
        // Create custom Appearance Configuration
        
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false,
            showCircularIcon: true
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
        lblInstruction.text = "OK, We've recorded your transaction and are creating your Item(s)!".localized()
        lblInstruction.font = UIFont.systemFont(ofSize: 14.0)
        lblInstruction.textColor = lblFontColor
        lblInstruction.textAlignment = NSTextAlignment.left
        subview.addSubview(lblInstruction)
        
        // Add the subview to the alert's UI property
        self.checkoutGeneratingDLG?.customSubview = subview
        _ = self.checkoutGeneratingDLG?.addButton("Cancel".localized()) {
            self.cancelCheckout(checkoutRes: checkoutRes)
        }
        
        _ = self.checkoutGeneratingDLG?.showSuccess("Checkout".localized(), subTitle: "")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.checkoutGeneratingDLG?.view.makeToast("Item(s) created. Generating item(s)...".localized())
        }
        
    }
    
    func createOverlayView() {
        transprentView =  UIView(frame: UIScreen.main.bounds)
        
        transprentView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ShoppingCartViewController.removeOverlayFromSuperView))
        self.transprentView.addGestureRecognizer(tapGesture)
        // here add your Label, Image, etc, what ever you want
        // add label view to help
        
        let label = UILabel(frame: CGRect(x: 30, y: 30, width: UIScreen.main.bounds.maxX - 30,height: UIScreen.main.bounds.maxY - 30))
        label.textAlignment = .left
        label.layer.borderWidth = 0.0
        label.font = UIFont.systemFont(ofSize: 56.0)
        label.numberOfLines = 0
        label.textColor = UIColor.white
        label.text = "Shopping Cart View Help Overlay".localized()
        transprentView.addSubview(label)
        UIView.animate(withDuration: 1.5, animations: {
            label.alpha = 1.0
        })
        self.view.addSubview(transprentView)
    }
    
    @objc func removeOverlayFromSuperView() {
        config.writeValue(true as AnyObject!, forKey: "shoppingCartHelpOverlayHasShown", toStore: "settings")
        UIView.animate(withDuration: 1, animations: { self.transprentView.alpha = 0.0 }, completion: { Bool in
            self.transprentView.removeFromSuperview()
        })
    }
    
    func progressBarDisplayer(_ msg:String, _ indicator:Bool,  _ basedView:UIView ) {
        print(msg)
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 250, height: 50))
        strLabel.text = msg
        strLabel.textColor = UIColor.white
        messageFrame = UIView(frame: CGRect(x: view.frame.midX - 120, y: view.frame.midY - 25 , width: 240, height: 50))
        messageFrame.layer.cornerRadius = 15
        messageFrame.backgroundColor = Style.Colors.blackSemiTransparentColor
        if indicator {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.startAnimating()
            messageFrame.addSubview(activityIndicator)
        }
        messageFrame.addSubview(strLabel)
        basedView.addSubview(messageFrame)
    }
    // MARK: shopping cart cell delegate
    func buttonClicked() {
        self.reloadAllData()
    }
    
    func makeTempararyData() -> [String : Any]{
        
        if let path = Bundle.main.path(forResource: "checkoutMocData", ofType: "json")
        {
            
            do {
                let jsonData = try NSData(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.mappedIfSafe)
                if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                {
                    return jsonResult as! [String : Any]
                }
            } catch let error as NSError {
                print(error.localizedDescription)
                return [String : Any]()
            }
            
        }
        return [String : Any]()
    }
}
