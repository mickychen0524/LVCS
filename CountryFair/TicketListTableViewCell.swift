//
//  TicketListTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 6/24/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import MGSwipeTableCell

protocol TicketListTableViewCellDelegate {
    func buttonClicked()
}

class TicketListTableViewCell: MGSwipeTableCell {

    @IBOutlet weak var tileImage: FLAnimatedImageView!
    @IBOutlet weak var brandLogoImg: UIImageView!
    @IBOutlet weak var lblTicketDate: UILabel!
    @IBOutlet weak var ticketPreview: UIView!
    @IBOutlet weak var lblTicketRedeemState: UILabel!
    @IBOutlet weak var ticketPreviewImage: UIImageView!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var claimBtn: UIButton!
    
    var selfViewController : UIViewController!
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var cellDelegate: TicketListTableViewCellDelegate?
    
    var ticketSampleItem : [String : Any]! = [String : Any]()
    
    var avPlayer: AVPlayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)!
    }
    
    func configWithData(item: [String: Any]) {
        
        deleteBtn.layer.borderWidth = 1
        deleteBtn.layer.borderColor = UIColor(hexString: "A00910").cgColor
        
        self.ticketSampleItem = item
        self.brandLogoImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        self.brandLogoImg.contentMode = UIViewContentMode.scaleAspectFit
        
        if (!(item["isCompleted"] as! Bool)) {
            self.claimBtn.isEnabled = true
        } else {
            self.claimBtn.isEnabled = false
        }
        
        let gameData : [String : Any] = item["gameData"] as! [String : Any]
        self.lblTicketDate.text = item["ticketDownloadDate"] as? String
        let tileUrl = gameData["tileUrl"] as! String
        let animatedTileUrl = gameData["animatedTileUrl"] as! String
        let logoUrl = gameData["gameLogoUrl"] as! String
        let ticketClaimState : Bool = item["isClaimed"] as! Bool
        if (ticketClaimState) {
            self.lblTicketRedeemState.backgroundColor = UIColor.green
        } else {
            self.lblTicketRedeemState.backgroundColor = UIColor.clear
        }
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var filePath = String.init(format: "%@/%@", documentPath, tileUrl)
        DispatchQueue.global().async  {
            
            if (self.config.getValue("powerSavingState", fromStore: "settings") as! Bool) {
                
                if let _ = gameData["localSavingStateStatic"] as? Bool {
                    filePath = String.init(format: "%@/%@", documentPath, tileUrl)
                    self.tileImage.image = UIImage.init(contentsOfFile: filePath)
                } else {
                    self.tileImage.sd_setImage(with: URL(string: tileUrl)!)
                }
                
            } else {
                if (self.config.getValue("ticketRecentFlag", fromStore: "settings") as! Bool) {
                    if let _ = gameData["localSavingState"] as? Bool {
                        filePath = String.init(format: "%@/%@", documentPath, animatedTileUrl)
                        self.tileImage.animatedImage = FLAnimatedImage.init(animatedGIFData: NSData(contentsOfFile:filePath) as Data!)
                    } else {
                        do {
                            self.tileImage.animatedImage = try FLAnimatedImage.init(animatedGIFData: Data(contentsOf:URL(string : tileUrl)!))
                        } catch let error as NSError {
                            print(error)
                        }
                    }
                    
                } else {
                    if let _ = gameData["localSavingStateStatic"] as? Bool {
                        filePath = String.init(format: "%@/%@", documentPath, tileUrl)
                        self.tileImage.image = UIImage.init(contentsOfFile: filePath)
                    } else {
                        self.tileImage.sd_setImage(with: URL(string: tileUrl)!)
                    }
                }
            }
            
        }
        
        filePath = String.init(format: "%@/%@", documentPath, logoUrl)
        self.brandLogoImg.image = UIImage.init(contentsOfFile: filePath)
        
        let fileName : String = item["fileName"] as! String
        filePath = ""
        filePath = String.init(format: "%@/%@", documentPath, fileName)
        if fileName.range(of: "mp4") == nil {
            self.ticketPreviewImage.autoresizingMask = [.flexibleHeight]
            self.ticketPreviewImage.contentMode = UIViewContentMode.scaleAspectFit
            self.ticketPreviewImage.image = UIImage.init(contentsOfFile: filePath)
        } else {
            //            let videoURL = NSURL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
            let videoURL = NSURL(fileURLWithPath: filePath)
            
            let asset = AVURLAsset(url: videoURL as URL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            let timestamp = CMTime(seconds: 10, preferredTimescale: 60)
            
            do {
                let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
                self.ticketPreviewImage.autoresizingMask = [.flexibleHeight]
                self.ticketPreviewImage.contentMode = UIViewContentMode.scaleAspectFit
                self.ticketPreviewImage.image = UIImage(cgImage: imageRef)
            }
            catch let error as NSError
            {
                print("Image generation failed with error \(error)")
                
            }
            //            avPlayer = AVPlayer(url: videoURL as URL)
            //            let playerLayer = AVPlayerLayer(player: avPlayer)
            //            playerLayer.frame = self.preview.layer.bounds
            //            self.preview.layer.addSublayer(playerLayer)
        }
        
        
    }
    @IBAction func deleteBtnAction(_ sender: Any) {
        self.validateTicketWithHash(ticketData: ticketSampleItem, type : 2)
    }
    @IBAction func claimBtnAction(_ sender: Any) {
        self.validateTicketWithHash(ticketData: ticketSampleItem, type : 1)
    }
    
    // MARK: alamofire api section
    func validateTicketWithHash(ticketData: [String : Any], type : Int) {
        
        var data = [String: Any]()
        var middleData = [String: Any]()
        
        let mediaSizeStrSHA1 : String = String(ticketData["mediaSize"] as! Int).sha1()
        let binaryData = mediaSizeStrSHA1.dataFromHexadecimalString()
        let base64String : String = (binaryData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))!
        
        middleData["mediaHash"] = base64String
        middleData["validationLicenseCypherText"] = ticketData["licenseCypherText"] as! String
        
        data = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.selfViewController.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading...".localized()
        
        AlamofireRequestAndResponse.sharedInstance.ticketValidateApi(data, success: { (res: [String: Any]!) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.selfViewController.view, animated: true)
            var resData: [String : Any] = res["data"] as! [String : Any]
            let awardsArr : NSArray = resData["awards"] as! NSArray
            
            switch type {
            case 1:
                if (awardsArr.count == 0 && resData["nonDrawnPanels"] as! Int > 0) {
                    _ = SweetAlert().showAlert("Warning!".localized(), subTitle: "Oops! Some Draws have not completed yet! Try back after they are completed.".localized(), style: AlertStyle.warning)
                } else if (awardsArr.count == 0 && resData["nonDrawnPanels"] as! Int == 0) {
                    _ = SweetAlert().showAlert("Warning!".localized(), subTitle: "No winners.".localized(), style: AlertStyle.warning)
                } else if (awardsArr.count > 0) {
                    
                    let claimLicenseCode = resData["claimLicenseCode"] as! String
                    var totalAmount = 0.0
                    for item in awardsArr {
                        let awardItem : [String : Any] = item as! [String :Any]
                        totalAmount += awardItem["prizeAwardAmount"] as! Double
                        //                            totalAmount += awardItem["amountDueFromPlayer"] as! Double
                    }
                    
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                    let vc : ValidationViewController = mainStoryboard.instantiateViewController(withIdentifier: "validationViewController") as! ValidationViewController
                    
                    if (resData["nonDrawnPanels"] as! Int == 0) {
                        var newTicketData: [String : Any] = ticketData
                        newTicketData["isValid"] = true
                        vc.claimTicketData = newTicketData
                    } else {
                        vc.claimTicketData = ticketData
                    }
                    vc.totalAmount = totalAmount
                    vc.claimLicenseCode = claimLicenseCode
                    self.cellDelegate?.buttonClicked()
                    
                    self.selfViewController.present(vc, animated: true, completion: nil)
                    
                }
                break;
            case 2:
                if (awardsArr.count > 0 || resData["nonDrawnPanels"] as! Int > 0) {
                    _ = SweetAlert().showAlert("Warning!".localized(), subTitle: "Oops! You have unclaimed awards! Please Claim Ticket.".localized(), style: AlertStyle.warning)
                } else if (awardsArr.count == 0 && resData["nonDrawnPanels"] as! Int == 0) {
                    SweetAlert().showAlert("Warning!".localized(), subTitle: "We have confirmed you have no awards on this Ticket, are you sure you want to delete it? You will not be able to recover it.".localized(), style: .warning, buttonTitle:"No", buttonColor: UIColor(hexString:"0xD0D0D0"), otherButtonTitle:  "Yes", otherButtonColor: UIColor(hexString:"0xDD6B55")) { (isOtherButton) -> Void in
                        if isOtherButton == false {
                            
                            _ = self.appDelegate.deleteOneTicketItem(data: ticketData, fileName: ticketData["fileName"] as! String)
                            if let assetIdentifier = ticketData["assetIdentifier"] as? String {
                                PhotoAlbumManager.shared.delete(assetIdentifier: assetIdentifier, completionHandler: nil)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.cellDelegate?.buttonClicked()
                            }
                            
                        }
                    }
                    
                }
                break;
            default:
                
                break;
            }
            
            
        }, failure: { (_ error: NSError!, _ statusCode: Int!) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.selfViewController.view, animated: true)
            if statusCode == 500 {
                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! We could not read the QrCode. Please try again OR take you ticket(s) to a retailer location.".localized(), style: AlertStyle.error)
            } else {
                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! We seem to be having a problem connecting. \n Please try again later.".localized(), style: AlertStyle.error)
            }
        })
    }
    
}
