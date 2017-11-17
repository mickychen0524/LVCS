//
//  HomeViewController.swift
//  
//
//  Created by MyMac on 6/13/17.
//
//

import UIKit
import SCLAlertView
import AudioToolbox
import ImageIO
import QuartzCore
import CoreImage
import AVFoundation
import Social
import BlinkReceipt
import FSDK
import MultipeerConnectivity
import HockeySDK
import SwiftyJSON

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIWebViewDelegate, BRScanResultsDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var homeWebView: UIWebView!
    @IBOutlet weak var feedbackButton: UIButton!
    @IBOutlet weak var scanReceiptBtn: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var feedbackBage: UILabel!
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    var socialImage : UIImage?
    var receiptImage : UIImage?
    var receiptId: String?
    var correlationId: String?
    var sasUri: String?
    var rawOcr: String?
    var receiptBody: [String:Any]?

    lazy var str_playerRegisterLisence : String = ""
    
    lazy var allowLoad : Bool = true
    lazy var showOverLayFlg : Bool = false
    
    lazy var transprentView = UIView()
    
    let serviceManager = ServiceManager.getManager(t: "client")
    var waiting = false
    
    var playerRegisterRetry = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        BRScanManager.shared().licenseKey = "HJH3AXDB-TUHDEDSF-UW7JFDU6-JYKN35FB-6Z6FWIIV-7L5PV6X2-7L5PUWVM-2GNXVFQ6"
        
        
        scanReceiptBtn.isEnabled = false
        
        let day_url = URL(string: "http://common.content.32point6.com/templates/cofairapplanding.html")
        let day_url_request = URLRequest(url: day_url!,
                                         cachePolicy:NSURLRequest.CachePolicy.returnCacheDataElseLoad,
                                         timeoutInterval: 60*60*60*24)
        
        homeWebView.loadRequest(day_url_request)
        homeWebView.delegate = self
        checkRegisterState()
        
        // Do any additional setup after loading the view.
        
        feedbackButton.layer.borderColor = UIColor(hexString: "A00910").cgColor
        feedbackButton.layer.borderWidth = 1
        feedbackBage.layer.masksToBounds = true
        feedbackBage.layer.cornerRadius = feedbackBage.frame.width / 2
    }
    
    override func awakeFromNib() {
        let homeOverlayTimes = config.getValue("homeOverlayTimes", fromStore: "settings") as! Int
        
        if appDelegate.globalStartCount < homeOverlayTimes && !appDelegate.overlayPopped {
            viewCreatOverLay()
            appDelegate.overlayPopped = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        serviceManager.delegate = self
        chatButton.isEnabled = serviceManager.getClerkList().count > 0
        waiting = false
    }
    
    func viewCreatOverLay() {
        if allowLoad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.viewCreatOverLay()
            }
        } else {
            self.createOverlayView(state : 1)
        }
    }
    
    func cleanReceipt() {
        self.rawOcr = nil
        self.receiptBody = nil
        self.receiptImage = nil
    }
    
    @IBAction func offerFeedbackBtnAction(_ sender: Any) {
        BITHockeyManager.shared().feedbackManager.showFeedbackComposeView()
        feedbackBage.isHidden = true
    }
    
    @IBAction func scanReceiptBtnAction(_ sender: Any) {

        self.cleanReceipt()
        
        let scanOptions: BRScanOptions = BRScanOptions()
        scanOptions.storeUserFrames = true
        scanOptions.retailerId = WFRetailerId.unknown
        scanOptions.returnRawText = true
        BRScanManager.shared().startStaticCamera(from: self, scanOptions: scanOptions, with: self)
        
    }
    
    @IBAction func startCall(_ sender: Any) {
        serviceManager.playSound()
        serviceManager.startAdvertising(type: "client")
        serviceManager.delegate = self
        chatButton.isEnabled = false
        waiting = true
    }
    
    func didOutputRawText(_ rawText: String!) {
        print("raw ocr text:", rawText)
        self.rawOcr = rawText
    }
    
    func didCancelScanning(_ cameraViewController: UIViewController!) {
        cameraViewController.dismiss(animated: true, completion: nil)
    }
    
    func didFinishScanning(_ cameraViewController: UIViewController!, with scanResults: BRScanResults!) {
        cameraViewController.dismiss(animated: true, completion: nil)
        
        var receipt = [String:Any]()
        
        if (scanResults.retailerId != WFRetailerId.unknown) {
            receipt["retailerId"] = String(describing: scanResults.retailerId.rawValue)
        }
        
        receipt["brandId"] = scanResults.registerId
        receipt["receiptId"] = scanResults.transactionId
        receipt["brandName"] = scanResults.storeName
        receipt["createdOn"] = String(format:"%@ %@", scanResults.receiptDate ?? "", scanResults.receiptTime ?? "")
//        receipt["ocrRaw"] = self.rawOcr
        
        if (scanResults.receiptDate == nil && scanResults.receiptTime == nil) {
            receipt["createdOn"] = nil
        }
        
        guard let _ = self.rawOcr else {
            print("There is no OCR Raw Text")
            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! Scan failed. Please try again", style: AlertStyle.error)
            return
        }
        
        if scanResults.products.count > 0 {
            var lineItems: [Dictionary<String, Any>] = []
            
            for product in scanResults.products {
                var productDict = [String:Any]()
                
                productDict["lineItemText"] = product.productDescription
                productDict["quantity"] = product.quantity
                productDict["amount"] = product.unitPrice
                lineItems.insert(productDict, at: 0)
                
                print("Scanned Product", product)
                
            }
            
            receipt["lineItems"] = lineItems
            
            print("Scanned receipt", receipt)
            
            let json = JSON.init(receipt)
            let receiptObject = Receipt.init(json)
            Receipt.save(receiptObject)
            
            self.receiptBody = receipt
            
            let imagePath: String? = BRScanManager.shared().userFramesFilepaths?.popLast()
            
            if (imagePath != nil) {
                if let image = UIImage(contentsOfFile: imagePath!) {
                    self.receiptImage = image;
                }
            }
            
            if self.validateReceipt() {
                self.getUploadingUrl(imageData: UIImagePNGRepresentation(self.receiptImage!)!)
                
            } else {
                //            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Receipt image uploading error", style: AlertStyle.error)
            }
        } else {
            print("There is no line items")
            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! Scan failed. Please try again", style: AlertStyle.error)
        }
    }
    
    func validateReceipt() -> Bool {
        if self.receiptImage == nil {
            return false
        }
        
        if self.receiptBody == nil {
            return false
        }
        
        
        return true
        
    }
    
    func getUploadingUrl(imageData : Data) {

        self.view.makeToast("Uploading Receipt ", duration: 2.0, position: .center)
        
        let value = [String: Any]()
        AlamofireRequestAndResponse.sharedInstance.getReceiptUploadUrl(value, success: { (res: [String: Any]) -> Void in
            print("res: ", res)
            if let data = res["data"] as? Dictionary<String, String>{
                if let sasUri = data["sasUri"] {
                    print("sasUri: ", sasUri)
                    if let refId = data["receiptRefId"] {
                        if let correlationId = res["correlationRefId"] as? String {
                            self.sasUri = sasUri
                            
                            DispatchQueue.main.async() {
                                self.uploadReceiptImg(toStorage: sasUri, refId: refId, correlationId: correlationId, imageData : imageData, ocrBody: self.receiptBody!)
                            }
                            
                            return
                        }
                    }
                }
            }

            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Receipt image uploading error", style: AlertStyle.error)
            
        },
                                                                       failure: { (error: [String: Any]!) -> Void in
                                                                        
                                                                        _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Receipt image uploading error", style: AlertStyle.error)
        })
        
    
    }

    func uploadReceiptImg(toStorage : String, refId: String, correlationId: String, imageData : Data, ocrBody: [String:Any]) {
        print("ocr Body: ", ocrBody)
        AlamofireRequestAndResponse.sharedInstance.uploadReceiptImage(toStorage, data: imageData, success: { (res: [String: Any]) -> Void in
            print("Response: ", res)
//            var ocrRawText: String = ""
            
            AlamofireRequestAndResponse.sharedInstance.putReceiptOCRBody(refId, ocrRaw:self.rawOcr!, correlationRefId: correlationId, receipt: ocrBody, success: { (res: [String: Any]) -> Void in

                    _ = SweetAlert().showAlert("Success!".localized(), subTitle: "Receipt image uploading success", style: AlertStyle.success)
                    print("Response: ", res)
                }, failure: { (error: [String: Any]!) -> Void in
                    MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                    _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! Failed to update.", style: AlertStyle.error)
                })
            
        },
          failure: { (error: Error!) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! Failed to upload.", style: AlertStyle.error)
        })
    }

    @IBAction func showStoreLocator(_ sender: Any) {
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        if let storeLocatorViewController = homeStoryboard.instantiateViewController(withIdentifier: "StoreLocatorViewController") as? StoreLocatorViewController {
            present(storeLocatorViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func showStar(_ sender: Any) {
        let homeStoryboard = UIStoryboard(name: "Home", bundle: nil)
        if let starViewController = homeStoryboard.instantiateViewController(withIdentifier: "StarViewController") as? StarViewController {
            present(starViewController, animated: true, completion: nil)
        }
    }

    
    // MARK : Web View delegate
    
    func webViewDidStartLoad(_ webView: UIWebView) {
//        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
//        loadingNotification?.mode = MBProgressHUDMode.indeterminate
//        loadingNotification?.labelText = "Homepage Loading..."
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        scanReceiptBtn.isEnabled = true
//        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        allowLoad = false
        registerPushNotification()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return allowLoad
    }
    
    func checkRegisterState() {
        let userRegisterState = self.config.getValue("userRegisterState", fromStore: "settings") as! Bool
        if (!userRegisterState) {
            registerUser()
        } else { // check social image download
            let downloaded = config.getValue("socialConnectionImageDownload", fromStore: "settings") as! Bool
            if !downloaded {
                var playToken = ""
                if self.config.getValue("devEndpoint", fromStore: "settings") as! Bool {
                    playToken = self.config.getValue("devPlayToken", fromStore: "settings") as! String
                } else {
                    playToken = self.config.getValue("playToken", fromStore: "settings") as! String
                }
                let correlationRefId = self.config.getValue("devPlayToken", fromStore: "settings") as! String
                downloadSocialConnectImage(code: playToken, coRefID: correlationRefId)
            }
        }
        registerPushNotification()
    }
    
    // register player to the server
    func registerUser() {
        
        var data = [String: Any]()
        var middleData = [String: Any]()
        
        var userData = [String: Any]()
        
        userData["Key"] = "age"
        userData["value"] = 30
        
        middleData["languageCode"] = "en"
        middleData["countryCode"] = "US"
        middleData["selfieBase64"] = ""
        
        middleData["data"] = [userData]
        
        data = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
        print(self.appDelegate.JSONStringify(data))
        
        AlamofireRequestAndResponse.sharedInstance.registerWithUserImage(data as NSDictionary, success: { (res: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            let resData: [String: Any] = res["data"] as! [String: Any]
            print(self.appDelegate.JSONStringify(resData))
            self.str_playerRegisterLisence = resData["playerLicenseCode"] as! String
            if (self.config.getValue("devEndpoint", fromStore: "settings") as! Bool) {
                self.config.writeValue(self.str_playerRegisterLisence as AnyObject!, forKey: "devPlayToken", toStore: "settings")
            } else {
                self.config.writeValue(self.str_playerRegisterLisence as AnyObject!, forKey: "playToken", toStore: "settings")
            }
            NotificationCenter.default.post(Notification.init(name: Notification.Name(rawValue: "PlayTokenUpdatedNotification")))
            self.config.writeValue(true as AnyObject!, forKey: "userRegisterState", toStore: "settings")
            self.downloadSocialConnectImage(code: self.str_playerRegisterLisence, coRefID : res["correlationRefId"] as! String)
            
            self.registerPushNotification()
            self.appDelegate.getAllRetailers()
        },
         failure: { (error: [String: Any]) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.config.writeValue(false as AnyObject!, forKey: "ageCertificationHasOccured", toStore: "settings")
            self.config.writeValue(false as AnyObject!, forKey: "selfieHasBeenTaken", toStore: "settings")
            
            self.playerRegisterRetry += 1
            if self.playerRegisterRetry == 5 {
                self.showPlayerRegisterFailPopup()
            } else {
                self.registerUser()
            }
        })
    }
    
    func showPlayerRegisterFailPopup() {
        let alert = UIAlertController(title: "Error", message: "Oops! It's not you, it's me! I can't call home just now. Please close the app and try again later.", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            UIAlertAction in
            self.showPlayerRegisterFailPopup()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // register player to the server
    func registerPushNotification() {
        var playToken = ""
        if self.config.getValue("devEndpoint", fromStore: "settings") as! Bool {
            playToken = self.config.getValue("devPlayToken", fromStore: "settings") as! String
        } else {
            playToken = self.config.getValue("playToken", fromStore: "settings") as! String
        }
        
        if playToken.length == 0 {
            return
        }
        
        var data = [String: Any]()
        var middleData = [String: Any]()
        
        middleData["app"] = "plyr"
        middleData["platform"] = "apns"
        if let deviceToken = UserDefaults.standard.object(forKey: "deviceTokenForPush") as? String {
            middleData["handle"] = deviceToken
        } else {
            middleData["handle"] = ""
        }
        
        data = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
        AlamofireRequestAndResponse.sharedInstance.registerPushNotification(data as NSDictionary, success: { () -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            print("push registeration success")
        },
        failure: { () -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            print("push registeration failed")
            self.view.makeToast("Oops! We failed to register Push Notifications. Restart the App.")
            
        })
    }
    
    // download social image from server
    func downloadSocialConnectImage(code : String, coRefID : String){
        
        var data = [String: Any]()
        data["playerLicenseCode"] = code
        data["correlationRefId"] = coRefID
        
        AlamofireRequestAndResponse.sharedInstance.downloadSocialPhoto(data as NSDictionary, success: { (res: UIImage) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            
            let resData : UIImage = res
            self.socialImage = resData
            
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath : String = String.init(format: "%@/social.png", documentPath)
            do {
                try UIImagePNGRepresentation(resData)?.write(to: URL(fileURLWithPath: filePath))
            } catch {
                print(error)
            }
            
            self.view.endEditing(true)
            UIImageWriteToSavedPhotosAlbum(resData, self, nil, nil)
            let appearance = SCLAlertView.SCLAppearance(
                showCloseButton: false
            )
            
            let alertView = SCLAlertView(appearance: appearance)
            let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 250))
            let x = (subview.frame.width - 210) / 2
            
            // Add app logo image
            let logoImg = UIImageView(frame: CGRect(x: x, y: 5, width: 120,height: 200))
            logoImg.image = resData
            subview.addSubview(logoImg)
            
            // Add label
            let label = UILabel(frame: CGRect(x: logoImg.frame.maxX + 10,y: 5,width: 80,height: 220))
            label.layer.borderColor = UIColor.green.cgColor
            label.textAlignment = .left
            label.layer.borderWidth = 0
            label.layer.cornerRadius = 0
            label.numberOfLines = 0
            label.font = UIFont.systemFont(ofSize: 14.0)
            label.text = "We have downloaded this image to you Photos folder... \n\n Share online to earn gifts!"
            label.textAlignment = NSTextAlignment.left
            subview.addSubview(label)
            alertView.customSubview = subview
            
            let doneButton : SCLButton = alertView.addButton("Done") {
                let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let vc : ScanSocialQRCodeViewController = mainStoryboard.instantiateViewController(withIdentifier: "scanSocialQRCodeViewController") as? ScanSocialQRCodeViewController {
                    MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.present(vc, animated: true, completion: nil)
                    }
                }
            }
            
            var btnFrame = doneButton.frame
            btnFrame.size.height = 90.0
            doneButton.frame = btnFrame
            
            alertView.showSuccess("", subTitle: "")

            let showFacebook = self.config.getValue("socialConnectionImageDownload", fromStore: "settings") as? Bool
            if showFacebook == false {
                DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: {
                    if let vc = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
                        self.config.writeValue(true as AnyObject!, forKey: "socialConnectionImageDownload", toStore: "settings")
                        vc.setInitialText("Post to Facebook now")
                        vc.add(logoImg.image!)
                        vc.add(URL(string: Config.Share.appURL))
                        self.present(vc, animated: true)
                    }
                })
            }
        },
        failure: { (error: Error!) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.downloadSocialConnectImage(code: code, coRefID: coRefID)
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        
        if error == nil
        {
            //            _ = SweetAlert().showAlert("Success!".localized(), subTitle: "Your selfie saved successfuly.", style: AlertStyle.success)
        }
        else
        {
            //            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Your selfie save error.", style: AlertStyle.error)
        }
    }

    func createOverlayView(state : Int) {

        var displayFlg : Bool = false
        let img = UIImageView(frame: CGRect(x: 15, y: 15, width: UIScreen.main.bounds.maxX - 30,height: UIScreen.main.bounds.maxY - 30))
        img.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        img.contentMode = UIViewContentMode.scaleAspectFit
        switch state {
        case 1:
            if (!(config.getValue("topViewHasShown", fromStore: "settings") as! Bool)) {
                img.image = UIImage(named: "hand_top")
                displayFlg = true
            }
            
            break
        case 2:
            if (!(config.getValue("leftViewHasShown", fromStore: "settings") as! Bool)) {
                img.image = UIImage(named: "hand_left")
                displayFlg = true
            }
            
            break
        case 3:
            if (!(config.getValue("rightViewHasShown", fromStore: "settings") as! Bool)) {
                img.image = UIImage(named: "hand_right")
                displayFlg = true
            }
            
            break
        default:
            break
        }
        
        if displayFlg {
            transprentView =  UIView(frame: UIScreen.main.bounds)
            transprentView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            UIView.animate(withDuration: 1.5, animations: {
                img.alpha = 1.0
            })
            transprentView.addSubview(img)
            
            self.view.addSubview(transprentView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                UIView.animate(withDuration: 0.5, animations: { self.transprentView.alpha = 0.0 }, completion: { Bool in
                    self.transprentView.removeFromSuperview()
                    if ( (state > 0) && (state < 3)) {
                        self.createOverlayView(state: state + 1)
                    }
                })
            }
        } else {
            if (state < 3) {
                self.createOverlayView(state: state + 1)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if UIDevice.current.orientation.isLandscape {
            print("landscape state")
        } else {
            print("portrite state")
        }
    }
}

extension HomeViewController {
    
    func takeCall(_ caller: MCPeerID) {
        serviceManager.stopSound()
        serviceManager.stopAdvertising()
        serviceManager.callRequest("callAccepted", index: caller)
        startCall()
    }
    
    func startCall() {
        let homeStorybard = UIStoryboard(name: "Home", bundle: nil)
        if let callViewController = homeStorybard.instantiateViewController(withIdentifier: "CallViewController") as? CallViewController {
            present(callViewController, animated: true, completion: nil)
        }
    }
}

extension HomeViewController: ServiceManagerProtocol {
    
    func connectedDevicesChanged(_ manager: ServiceManager, connectedDevices: [MCPeerID : DeviceModel]) {
        DispatchQueue.main.async {
            if !self.waiting {
                self.chatButton.isEnabled = self.serviceManager.getClerkList().count > 0
            }
        }
    }
    
    func receivedData(_ manager: ServiceManager, peerID: MCPeerID, responseString: String) {
        DispatchQueue.main.async {
            switch responseString {
            case ResponseValue.incomingCall.rawValue:
                print("incomingCall")
                self.takeCall(peerID)
            case ResponseValue.callAccepted.rawValue:
                print("callAccepted")
                self.startCall()
            case ResponseValue.callRejected.rawValue:
                print("callRejected")
            default:
                print("Unknown status received: \(responseString)")
            }
        }
    }
}

extension HomeViewController: BITFeedbackManagerDelegate {
    
    func allowAutomaticFetchingForNewFeedback(for feedbackManager: BITFeedbackManager) -> Bool {
        return true
    }
    
    func feedbackManagerDidReceiveNewFeedback(_ feedbackManager: BITFeedbackManager) {
        feedbackBage.isHidden = false
    }
}
