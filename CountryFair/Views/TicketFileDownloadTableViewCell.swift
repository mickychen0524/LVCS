//
//  TicketFileDownloadTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import KDCircularProgress
import Alamofire
import AssetsLibrary
import Photos

protocol TicketFileDownloadTableViewCellDelegate {
    func videoSaveComplete(ticketStatus : Bool, fileIndex : Int, completeFlg : Bool)
    func ticketDownloadStarted(fileIndex : Int)
}

class TicketFileDownloadTableViewCell: UITableViewCell, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var gameLogo: FLAnimatedImageView!
    @IBOutlet weak var circlProgressView: KDCircularProgress!
    @IBOutlet weak var lblState: UILabel!
    @IBOutlet weak var lblProgressPercent: UILabel!
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var cellDelegate : TicketFileDownloadTableViewCellDelegate?
    
    var fileIndex : Int = 0
    var fileUrl : String = ""
    var fileName : String = ""
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if self.gameLogo != nil {
//            self.gameLogo.layer.shouldRasterize = true
//            self.gameLogo.layer.rasterizationScale = UIScreen.main.scale
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        circlProgressView.angle = 0
        lblState.text = "Downloading..."
        lblProgressPercent.text = "0.0%"
    }
    
    // MARK: register background process
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // load table view cell
    func configWithData(item: [String: Any]) {
    
        if let stateText = item["StateText"] as? String {
            self.lblState.text = stateText
        }

        if let progressPercent = item["ProgressPercent"] as? String {
            self.lblProgressPercent.text = progressPercent
        }
        
        circlProgressView.angle = 0
        
        if let angle = item["ProgressViewAngle"] as? Double {
            circlProgressView.angle = angle
        }

        circlProgressView.startAngle = -90
        circlProgressView.progressThickness = 0.2
        circlProgressView.trackThickness = 0.6
        circlProgressView.clockwise = true
        circlProgressView.gradientRotateSpeed = 2
        circlProgressView.roundedCorners = false
        circlProgressView.glowMode = .forward
        circlProgressView.glowAmount = 0.5
        circlProgressView.set(colors: UIColor.cyan ,UIColor.white, UIColor.magenta, UIColor.white, UIColor.orange)

        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        var chLogoUrl = ""
        if let channelRefId : String = item["channelRefId"] as? String {
            chLogoUrl = self.getTileUrl(channelRefId: channelRefId)
        }
        
        if let overlayUrl = item["ticketTemplateOverlayUrl"] as? String {
            if (overlayUrl == "") {
                if (chLogoUrl != "") {
                    DispatchQueue.global().async  {
                        let filePath = String.init(format: "%@/%@", documentPath, chLogoUrl)
                        self.gameLogo.animatedImage = FLAnimatedImage.init(animatedGIFData: NSData(contentsOfFile:filePath) as Data!)
                    }
                }
            } else {
                if let logoUrl = URL(string: overlayUrl) {
                    DispatchQueue.global().async  {
                        self.gameLogo.sd_setImage(with: logoUrl)
                    }
                }
            }
        } else {
            if (chLogoUrl != "") {
                DispatchQueue.global().async  {
                    let filePath = String.init(format: "%@/%@", documentPath, chLogoUrl)
                    self.gameLogo.animatedImage = FLAnimatedImage.init(animatedGIFData: NSData(contentsOfFile:filePath) as Data!)
                }
            }
        }
        
    }
    
    func getTileUrl(channelRefId : String) -> String {
        var returnStr = ""
        for item1 in self.appDelegate.channelGroupGlobalArr {
            let channelGroupItem = item1 as! [String : Any]
            let channels = channelGroupItem["channels"] as! NSArray
            for item2 in channels {
                var channelItem = item2 as! [String : Any]
                
                if (channelItem["channelRefId"] as! String == channelRefId) {
                    
                    let ticketTemplateData = channelItem["ticketTemplate"] as! [String : Any]
                    
                    returnStr = ticketTemplateData["tileAnimatedUrl"] as! String
                    break
                }
            }
        }
        return returnStr
    }
    

}
