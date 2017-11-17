//
//  CheckoutDownloadFileTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 6/22/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import KDCircularProgress
import AssetsLibrary
import Photos

protocol CheckoutDownloadFileTableViewCellDelegate {
    func giftCardSaveComplete(ticketStatus : Bool, fileIndex : Int, completeFlg : Bool)
    func giftCardDownloadStarted(fileIndex : Int)
}

class CheckoutDownloadFileTableViewCell: UITableViewCell {

    @IBOutlet weak var gameLogo: FLAnimatedImageView!
    @IBOutlet weak var lblState: UILabel!
    @IBOutlet weak var lblProgressPercent: UILabel!
    @IBOutlet weak var circlProgressView: KDCircularProgress!
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var cellDelegate : CheckoutDownloadFileTableViewCellDelegate?
    var updateTimer: Timer?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    var giftCardObj : [String : Any]!
    var fileIndex : Int = 0
    var fileUrl : String = ""
    var fileName : String = ""
    var isGiftCard: Bool!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        self.giftCardObj = [String : Any]()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    // MARK: register background process
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
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
    
    func downloadImage() {
        self.downloadCheckoutFile(fileUrl: self.fileUrl, fileName : self.fileName)
        
        switch UIApplication.shared.applicationState {
        case .active:
            print("download table view active")
        case .background:
            print("App is backgrounded. Next number = \(self.circlProgressView.angle)")
            print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
        case .inactive:
            break
        }
    }
    
    // make table view cell using channel group data
    func configWithData(item: [String: Any]) {
        
        var percentStr : String = item["progress"] as! String
        
        let downloadItem = DownloadItemManager.sharedManager.getDownloadItem(withName: item["fileName"] as! String)
        
        if let sasUrl = item["sasUri"] as? String {
            
            self.fileUrl = sasUrl
            if let fName:String = item["fileName"] as? String {
                self.fileName = fName
            }
            
            if let downloaded = item["downloaded"] as? Bool {
                if downloaded || (downloadItem != nil && (downloadItem?.isDownloading)!) {
                    self.lblState.text = "Download complete".localized()
                    percentStr = "100%"
                } else {
                    self.cellDelegate?.giftCardDownloadStarted(fileIndex: self.fileIndex)
                    downloadImage()
                    registerBackgroundTask()
                    self.lblState.text = "Started...".localized()
                    percentStr = "0%"
                }
            }
        } else {
            if let downloaded = item["downloaded"] as? Bool {
                if !downloaded {
                    self.cellDelegate?.giftCardDownloadStarted(fileIndex : self.fileIndex)
                }
            }
            self.lblState.text = "gift error"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                
                let notification = UILocalNotification()
                notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                notification.alertBody = "Oops, the checkout failed."
                notification.alertAction = "open"
                notification.hasAction = true
                notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
                UIApplication.shared.scheduleLocalNotification(notification)
                
                self.cellDelegate?.giftCardSaveComplete(ticketStatus: false, fileIndex: self.fileIndex, completeFlg : true)
            }
            
        }
        
        self.lblProgressPercent.text = percentStr
        circlProgressView.startAngle = -90
        circlProgressView.progressThickness = 0.2
        circlProgressView.trackThickness = 0.6
        circlProgressView.clockwise = true
        circlProgressView.gradientRotateSpeed = 2
        circlProgressView.roundedCorners = false
        circlProgressView.glowMode = .forward
        circlProgressView.glowAmount = 0.5
        circlProgressView.set(colors: UIColor.cyan ,UIColor.white, UIColor.magenta, UIColor.white, UIColor.orange)
        
        if percentStr == "100%" {
            self.circlProgressView.angle = 360.0
            self.lblProgressPercent.text = percentStr
            self.lblState.text = "Download complete".localized()
        }
        
        self.gameLogo.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        self.gameLogo.contentMode = UIViewContentMode.scaleAspectFit
        
        self.giftCardObj = item["giftItemObj"] as! [String : Any]
        self.gameLogo.sd_setImage(with: URL(string: self.giftCardObj["merchandiseImageUrl"] as! String))
        
        self.isGiftCard = item["isGiftCard"] as! Bool
    }
    
    func downloadCheckoutFile(fileUrl : String, fileName : String) {
        
        if DownloadItemManager.sharedManager.getDownloadItem(withName: fileName) == nil {
            _ = DownloadItemManager.sharedManager.addDownloadEntity(fileName, fileUrl)
        }
        
        DownloadItemManager.sharedManager.getDownloadedItem(fileName: fileName, progressClosure: { (progress) in
            self.circlProgressView.angle = 360 * progress
            self.lblState.text = "Downloading..."
            self.lblProgressPercent.text = String.init(format: "%.2f", 100 * progress) + "%"
            print("Download Progress: \(progress)")
        }, success: { (data) in

            let notification = UILocalNotification()
            notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
            notification.alertBody = "Hi Dear, the gift card \(self.fileIndex + 1) download was completed."
            notification.alertAction = "open"
            notification.hasAction = true
            notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
            UIApplication.shared.scheduleLocalNotification(notification)

            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath : String = String.init(format: "%@/%@", documentPath, fileName)
            self.updateTimer?.invalidate()
            self.lblState.text = "Saving..."
            self.updateTimer = nil
            
            if self.backgroundTask != UIBackgroundTaskInvalid {
                self.endBackgroundTask()
            }
            
            let isGift = self.isGiftCard
            
            let albumName = isGift! ? "My Gift Cards" : "My Coupons"
            
            let isImage = UIImage(data: data) != nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.lblState.text = "Download complete"
                self.cellDelegate?.giftCardSaveComplete(ticketStatus: true, fileIndex: self.fileIndex, completeFlg : true)
                PhotoAlbumManager.shared.save(isImage: isImage, path: filePath, albumName: albumName, completionHandler: nil)
            }
        }) { (error) in
            print("Error \(error)")
        }
    }
    
}
