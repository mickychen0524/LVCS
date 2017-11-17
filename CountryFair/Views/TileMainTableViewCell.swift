//
//  TileMainTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import Kingfisher
import SCLAlertView
import DatePickerDialog
import MobileCoreServices
import Alamofire
import DropDown

class TileMainTableViewCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var gameLogoImage: UIImageViewAligned!
    @IBOutlet weak var brandLogoImage: UIImageViewAligned!
    var gameList: NSArray = []
    var brandList: NSArray = []
    var drawList: NSArray = []
    var channelData: NSArray! = NSArray()
    var channelGroupData: [String:Any] = [:]
    var shoppingCartData: [String:Any] = [:]
    var shoppingCartItemsArr: NSArray = []
    var gameRefID:String = ""
    var brandRefID:String = ""
    var channelRefID:String = ""
    var templateRefId:String = ""
    
    var drawRefID:String = ""
    var channelGroupRefID: String = ""
    
    var gameLogoStr: String = ""
    var gameLogoUrl: URL = URL(string:"http://")!
    var brandLogoStr: String = ""
    var brandLogoUrl: URL = URL(string:"http://")!
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    
    // dropdown menu constants
    let drawDateDropDown = DropDown()
    let playAmountDropDown = DropDown()
    let playerNumberDropDown = DropDown()
    var transprentView = UIView()
    
    var messageFrame = UIView()
    var agreeToTermsDLG : SCLAlertView?
    var claimCompleteDLG : SCLAlertView?
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    
    // local flags
    var tileClickedFlg : Bool = false
    
    lazy var dropDowns: [DropDown] = {
        return [
            self.drawDateDropDown,
            self.playAmountDropDown,
            self.playerNumberDropDown
        ]
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.gameList = []
        self.brandList = []
        self.channelData = NSArray()
        self.channelGroupData = [:]
        self.collectionView.delegate = self
        
        dropDowns.forEach { $0.dismissMode = .onTap }
        dropDowns.forEach { $0.direction = .bottom }
        setupDefaultDropDown()
        
    }
    
    func setupDefaultDropDown() {
        DropDown.setupDefaultAppearance()
        
        dropDowns.forEach {
            $0.cellNib = UINib(nibName: "DropDownCell", bundle: Bundle(for: DropDownCell.self))
            $0.customCellConfiguration = nil
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)!
    }
    
    // make table view cell using channel group data
    func configWithData(item: [String: Any]) {
        
        self.channelGroupData = item
        self.channelData = item["channels"] as! NSArray
        
        let gameId = (item["gameRefId"] as? String) ?? ""
        self.gameRefID = gameId
        
        // check demo data or real data
        let brandId = (item["brandRefId"] as? String) ?? ""
        self.brandRefID = brandId
        
        self.channelGroupRefID = item["channelGroupRefId"] as! String
        
        self.gameLogoStr = findGameAndBrandImageurl(id: gameId, type: 1)
        if (self.gameLogoStr == "") {
            self.gameLogoStr = Config.APIEndpoints.vaLotteryAppImageStr
        }
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var filePath = String.init(format: "%@/%@", documentPath, self.gameLogoStr)
        
        self.gameLogoImage.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
        self.gameLogoImage.contentMode = UIViewContentMode.scaleAspectFit
        gameLogoImage.image = UIImage.init(contentsOfFile: filePath)
        gameLogoImage.alignLeft = true
        
        self.brandLogoStr = findGameAndBrandImageurl(id: brandId, type: 2)
        if (self.brandLogoStr == "") {
            self.brandLogoStr = Config.APIEndpoints.vaLotteryAppImageStr
        }
        
        self.brandLogoImage.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth]
        self.brandLogoImage.contentMode = UIViewContentMode.scaleAspectFit
        self.brandLogoImage.alignRight = true
        
        filePath = String.init(format: "%@/%@", documentPath, self.brandLogoStr)
        brandLogoImage.image = UIImage.init(contentsOfFile: filePath)
        
        self.collectionView.reloadData()
        
    }
    
    // find game and brand logo image url using identiy of data
    func findGameAndBrandImageurl(id:String, type: Int) -> String {
        switch(type) {
        case 1:
            for game in gameList {
                let item = game as! [String: Any]
                if (item["gameRefId"] as! String == id){
                    let amountArrTemp:[NSNumber] = item["panelPrices"] as! Array
                    var amountStrTemp: [String] = []
                    for am in amountArrTemp{
                        amountStrTemp.append(am.stringValue)
                    }
                    self.playAmountDropDown.dataSource = amountStrTemp
                    
                    amountStrTemp = []
                    var maxAmount:Int = 0
                    // check demo data or real data
                    if (self.config.getValue("demoDataFlag", fromStore: "settings") as! Bool) {
                        maxAmount = item["panelsPerDrawMax"] as! Int
                    } else {
                        maxAmount = item["panelsMax"] as! Int
                    }
                    if (maxAmount == 0) {
                        maxAmount = 10
                    }
                    for am in 0 ..< maxAmount{
                        amountStrTemp.append(String(format: "%d", am + 1))
                    }
                    self.playerNumberDropDown.dataSource = amountStrTemp
                    
                    return item["logoUrl"] as! String
                }
            }
            return ""
        case 2:
            for brand in brandList {
                let item = brand as! [String: Any]
                if (item["brandRefId"] as! String == id){
                    var returnUrlForBrand: String = item["logoUrl"] as! String
                    if let title = self.channelGroupData["channelGroupLogoUrl"] as? String{
                        if (title != ""){
                            returnUrlForBrand = title
                        }
                    }
                    return returnUrlForBrand
                }
            }
            return ""
        default:
            return ""
        }
    }
    
    // return count of channel data
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.channelData.count
    }
    
    // make loading(indicator) view for image loading time
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gameCell", for: indexPath) as! TileMainCollectionViewCell
        
        cell.imageView.kf.indicatorType = .activity
        if indexPath.row < gameList.count, let game = gameList[indexPath.row] as? [String: Any], let gameName = game["gameName"] as? String {
            cell.gameLabel.text = gameName
        }
        
        var urlType: Bool = false
        let item = channelData[indexPath.row] as! [String:Any]
        
        // check demo data or real data
        var template = [String : Any]()
        if (self.config.getValue("demoDataFlag", fromStore: "settings") as! Bool) {
            template = item["ticketTemplate"] as! [String : Any]
        } else {
            template = item["template"] as! [String : Any]
        }
        
        var image_url:String = template["tileUrl"] as! String
        
        if (config.getValue("powerSavingState", fromStore: "settings") as! Bool) {
            print("power saving is on...")
        } else {
            if let title = template["tileAnimatedUrl"] as? String{
                if (title != ""){
                    urlType = true
                    image_url = title
                }
            }
        }
        
        if (image_url == "") {
            image_url = Config.APIEndpoints.vaLotteryAppImageStr
        }
        
        var url = URL(string:image_url)
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var filePath = "\(documentPath)/\(image_url)"
        if (self.config.getValue("demoDataFlag", fromStore: "settings") as! Bool) {
            if let _ = item["localSavingState"] as? Bool {
                DispatchQueue.global().async {
                    if urlType == true, let data = NSData(contentsOfFile: filePath) as Data? {
                        DispatchQueue.main.async {
                            cell.imageView.animatedImage = FLAnimatedImage.init(animatedGIFData: data)
                            cell.gameLabel.isHidden = true
                        }
                    } else {
                        DispatchQueue.main.async {
                            cell.imageView.image = UIImage.init(contentsOfFile: filePath)
                            cell.gameLabel.isHidden = true
                        }
                    }
                }
            } else {
                if let _ = item["localSavingStateStatic"] as? Bool {
                    image_url = template["tileUrl"] as! String
                    filePath = "\(documentPath)/\(image_url)"
                    cell.imageView.image = UIImage.init(contentsOfFile: filePath)
                    cell.gameLabel.isHidden = true
                } else {
                    image_url = template["tileUrl"] as! String
                    url = URL(string:image_url)
                    cell.imageView.kf.setImage(with: url, placeholder: nil, options: [.transition(ImageTransition.fade(1))], progressBlock: nil, completionHandler: { (image, error, cacheType, url) in
                        cell.gameLabel.isHidden = true
                    })
                }
            }
        } else {
            DispatchQueue.global().async {
                if urlType {
                    do {
                        let data = try Data(contentsOf:url!)
                        DispatchQueue.main.async {
                            cell.imageView.animatedImage = FLAnimatedImage.init(animatedGIFData: data)
                            cell.gameLabel.isHidden = true
                        }
                    } catch { }
                } else {
                    DispatchQueue.main.async {
                        cell.imageView.kf.setImage(with: url, placeholder: nil, options: [.transition(ImageTransition.fade(1))], progressBlock: nil, completionHandler: { (image, error, cacheType, url) in
                            cell.gameLabel.isHidden = true
                        })
                    }
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // This will cancel all unfinished downloading task when the cell disappearing.
        //        (cell as! PlayerCollectionViewCell).imageView.kf.cancelDownloadTask()
    }
    
    // click event for each collection view cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!tileClickedFlg) {
            tileClickedFlg = true
            self.collectionView.reloadItems(at: [indexPath])
            // if there is no any draw data please show the error message
            if (self.playerNumberDropDown.dataSource.count == 0) {
                _ = SweetAlert().showAlert("Warning!".localized(), subTitle: "Oops! No Draws! \n Try again in a few minutes.".localized(), style: AlertStyle.warning)
                self.tileClickedFlg = false
            } else {
                self.getDrawListForGame(channelData : channelData[indexPath.row] as! [String:Any])
            }
        }
    }
    
    // make custoimzed dialog view using logo url and channel data
    func addToCartDialog(item: [String : Any]) {
        
        // Create custom Appearance Configuration
        var numberInt: Int = 1
        var amountDlb: Double = 0.0
        var animatedState: Bool = false
        
        // check demo data or real data
        var template = [String : Any]()
        if (self.config.getValue("demoDataFlag", fromStore: "settings") as! Bool) {
            template = item["ticketTemplate"] as! [String : Any]
            self.templateRefId = template["ticketTemplateRefId"] as! String
            self.channelRefID = item["channelRefId"] as! String
        } else {
            template = item["template"] as! [String : Any]
            self.templateRefId = template["templateRefId"] as! String
            self.channelRefID = item["channelRefId"] as! String
        }
        
        var image_url:String = template["tileUrl"] as! String
        
        if (image_url == "") {
            image_url = Config.APIEndpoints.vaLotteryAppImageStr
        }
        
        if (config.getValue("powerSavingState", fromStore: "settings") as! Bool) {
            print("power saving is on...")
        } else {
            if let title = template["tileAnimatedUrl"] as? String{
                if (title != ""){
                    animatedState = true
                    image_url = title
                }
            }
        }
        var url = URL(string:image_url)
        
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: Style.Font.fontWithSize(size: 20),
            kTextFont: Style.Font.fontWithSize(size: 14),
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false,
            shouldAutoDismiss : false
        )
        
        // Initialize SCLAlertView using custom Appearance
        let alert = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 250))
        let x = (subview.frame.width - 210) / 2
        
        // Add draw button
        let drawBtn = DropDownButton(frame: CGRect(x: x,y: 10,width: 210,height: 25))
        drawBtn.layer.borderColor = UIColor.lightGray.cgColor
        drawBtn.layer.borderWidth = 0.5
        drawBtn.layer.cornerRadius = 3
        drawBtn.setTitle("Draw   ".localized() + self.drawDateDropDown.dataSource[0], for: .normal)
        drawBtn.setTitleColor(UIColor.black, for: .normal)
        drawBtn.contentHorizontalAlignment = .left
        drawBtn.titleLabel!.font = UIFont.systemFont(ofSize: 12.0)
        drawBtn.addTarget(self, action: #selector(self.chooseDrawDate(_:)), for: .touchUpInside)
        subview.addSubview(drawBtn)
        self.drawDateDropDown.anchorView = drawBtn
        self.drawDateDropDown.bottomOffset = CGPoint(x: 0, y: 30)
        
        // Add amount button
        let amountBtn = DropDownButton(frame: CGRect(x: x,y: drawBtn.frame.maxY + 10,width: 130,height: 25))
        amountBtn.layer.borderColor = UIColor.lightGray.cgColor
        amountBtn.layer.borderWidth = 0.5
        amountBtn.layer.cornerRadius = 3
        amountDlb = Double(self.playAmountDropDown.dataSource[0])!
        amountBtn.setTitle("Play Amount $".localized() + self.playAmountDropDown.dataSource[0], for: .normal)
        amountBtn.setTitleColor(UIColor.black, for: .normal)
        amountBtn.contentHorizontalAlignment = .left
        amountBtn.titleLabel!.font = UIFont.systemFont(ofSize: 12.0)
        amountBtn.addTarget(self, action: #selector(self.choosePlayAmount(_:)), for: .touchUpInside)
        subview.addSubview(amountBtn)
        self.playAmountDropDown.anchorView = amountBtn
        self.playAmountDropDown.bottomOffset = CGPoint(x: 0, y: 30)
        
        // Add number of button
        let numberOfBtn = DropDownButton(frame: CGRect(x: x,y: amountBtn.frame.maxY + 10,width: 130,height: 25))
        numberOfBtn.layer.borderColor = UIColor.lightGray.cgColor
        numberOfBtn.layer.borderWidth = 0.5
        numberOfBtn.layer.cornerRadius = 3
        numberInt = Int(self.playerNumberDropDown.dataSource[0])!
        numberOfBtn.setTitle("Number Of Plays ".localized() + self.playerNumberDropDown.dataSource[0], for: .normal)
        numberOfBtn.setTitleColor(UIColor.black, for: .normal)
        numberOfBtn.contentHorizontalAlignment = .left
        numberOfBtn.titleLabel!.font = UIFont.systemFont(ofSize: 12.0)
        numberOfBtn.addTarget(self, action: #selector(self.chooseNumberOfPlayers(_:)), for: .touchUpInside)
        subview.addSubview(numberOfBtn)
        self.playerNumberDropDown.anchorView = numberOfBtn
        self.playerNumberDropDown.bottomOffset = CGPoint(x: 0, y: 30)
        
        // Add label
        let label = UILabel(frame: CGRect(x: numberOfBtn.frame.maxX + 5, y: amountBtn.frame.maxY + 10, width: 80,height: 25))
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.textAlignment = .left
        label.layer.borderWidth = 0.5
        label.layer.cornerRadius = 3
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "Total $".localized() + String(format: "%.1f", amountDlb * Double(numberInt))
        subview.addSubview(label)
        let selectedDrawItem: [String : Any] = self.drawList[0] as! [String : Any]
        self.drawRefID = selectedDrawItem["drawRefId"] as! String
        // Action triggered on selection
        drawDateDropDown.selectionAction = {(index, item) in
            drawBtn.setTitle("Draw   ".localized() + item, for: .normal)
            let selectedDrawItem: [String : Any] = self.drawList[index] as! [String : Any]
            self.drawRefID = selectedDrawItem["drawRefId"] as! String
            
        }
        
        playAmountDropDown.selectionAction = {(index, item) in
            amountBtn.setTitle("Play Amount $".localized() + item, for: .normal)
            amountDlb = Double(item)!
            if (Double(numberInt) == 0.0) {
                amountBtn.layer.borderColor = UIColor.red.cgColor
                label.layer.borderColor = UIColor.red.cgColor
            } else {
                amountBtn.layer.borderColor = UIColor.lightGray.cgColor
                label.layer.borderColor = UIColor.lightGray.cgColor
            }
            label.text = "Total $".localized() + String(format: "%.1f", amountDlb * Double(numberInt))
        }
        
        playerNumberDropDown.selectionAction = {(index, item) in
            numberOfBtn.setTitle("Number of Plays ".localized() + item, for: .normal)
            numberInt = Int(item)!
            if (numberInt == 0) {
                numberOfBtn.layer.borderColor = UIColor.red.cgColor
                label.layer.borderColor = UIColor.red.cgColor
            } else {
                numberOfBtn.layer.borderColor = UIColor.lightGray.cgColor
                label.layer.borderColor = UIColor.lightGray.cgColor
            }
            label.text = "Total $".localized() + String(format: "%.1f", amountDlb * Double(numberInt))
        }
        
        // Add tile image
        
        //        let tileImg = FLAnimatedImageView(frame: CGRect(x: x, y: numberOfBtn.frame.maxY + 10, width: 100,height: 130))
        
        let tileImg = FLAnimatedImageView(frame: CGRect(x: x, y: numberOfBtn.frame.maxY + 10, width: 100,height: 130))
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var filePath = "\(documentPath)/\(image_url)"
        if (self.config.getValue("demoDataFlag", fromStore: "settings") as! Bool) {
            
            if let _ = item["localSavingState"] as? Bool {
                if (animatedState) {
                    if let data = NSData(contentsOfFile: filePath) as Data? {
                        tileImg.animatedImage = FLAnimatedImage.init(animatedGIFData:data)
                    }
                } else {
                    tileImg.image = UIImage.init(contentsOfFile: filePath)
                }
            } else {
                if let _ = item["localSavingStateStatic"] as? Bool {
                    image_url = template["tileUrl"] as! String
                    filePath = "\(documentPath)/\(image_url)"
                    tileImg.image = UIImage.init(contentsOfFile: filePath)
                    
                } else {
                    image_url = template["tileUrl"] as! String
                    url = URL(string:image_url)
                    tileImg.kf.setImage(with: url,
                                        placeholder: nil,
                                        options: [.transition(ImageTransition.fade(1))],
                                        progressBlock: { receivedSize, totalSize in
                                            
                                            //                                    print("\(indexPath.row + 1): \(receivedSize)/\(totalSize)")
                    },
                                        completionHandler: { image, error, cacheType, imageURL in
                                            //                                    print("\(indexPath.row + 1): Finished")
                    })
                }
            }
            
        } else {
            if (animatedState) {
                
                do {
                    tileImg.animatedImage = try FLAnimatedImage.init(animatedGIFData: Data(contentsOf:url!))
                } catch let error as NSError {
                    print(error)
                }
                
            } else {
                tileImg.kf.setImage(with: url,
                                    placeholder: nil,
                                    options: [.transition(ImageTransition.fade(1))],
                                    progressBlock: { receivedSize, totalSize in
                                        
                                        //                                    print("\(indexPath.row + 1): \(receivedSize)/\(totalSize)")
                },
                                    completionHandler: { image, error, cacheType, imageURL in
                                        //                                    print("\(indexPath.row + 1): Finished")
                })
            }
        }
        
        
        subview.addSubview(tileImg)
        
        // Add app logo image
//        let logoImg = UIImageView(frame: CGRect(x: tileImg.frame.maxX + 10, y: numberOfBtn.frame.maxY + 10, width: 100,height: 60))
//        logoImg.image = UIImage(named: "valogovertical_logo")
//        subview.addSubview(logoImg)
        
        // Add game logo image
        let gameLogoImg = UIImageView(frame: CGRect(x: tileImg.frame.maxX + 10, y: numberOfBtn.frame.maxY + 10, width: 100,height: 60))
        gameLogoImg.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        gameLogoImg.contentMode = UIViewContentMode.scaleAspectFit
        
        filePath = String.init(format: "%@/%@", documentPath, self.gameLogoStr)
        gameLogoImg.image = UIImage.init(contentsOfFile: filePath)
        subview.addSubview(gameLogoImg)
        
        // check main view start state and display overlay
        if (!(config.getValue("addToCartHelpOverlayHasShown", fromStore: "settings") as! Bool)){
            self.createOverlayView(superView: alert.view)
        }
        
        // Add the subview to the alert's UI property
        alert.customSubview = subview
        
        let _ = alert.addButton("Add to Cart".localized()) {
//            if (amountDlb * Double(numberInt) != 0.0) {
            
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = DateFormatter.Style.full
                let convertedDate = dateFormatter.string(from: currentDate)
                
                var sendData = [String: Any]()
                sendData["gameRefId"] = self.gameRefID
                sendData["brandRefId"] = self.brandRefID
                sendData["drawRefId"] = self.drawRefID
                sendData["channelGroupRefId"] = self.channelGroupRefID
                sendData["channelRefId"] = self.channelRefID
                sendData["playAmount"] = amountDlb
                sendData["panelCount"] = numberInt
                sendData["addedOn"] = convertedDate
                sendData["tileUrl"] = image_url
                sendData["animatedState"] = animatedState
                sendData["gameLogoUrl"] = self.gameLogoStr
                sendData["templateRefId"] = self.templateRefId
                sendData["channelTemplateData"] = item
                
                if (self.appDelegate.saveShoppingCartToLocal(data: sendData)){
                    self.tileClickedFlg = false
                    print("shopping cart saving is ok")
                    UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut, animations: {
                        var viewFrame = alert.view.frame
                        viewFrame.origin.y -= viewFrame.size.height
                        
                        alert.view.frame = viewFrame
                    }, completion: { finished in
                        tileImg.removeFromSuperview()
                        alert.hideView()
                    })
                    
                }
                
//            }
            
        }
        
        // Add Button with Duration Status and custom Colors
        _ = alert.addButton("Cancel".localized(), backgroundColor: Style.Colors.pureYellowColor, textColor: Style.Colors.darkLimeGreenColor) {
            self.tileClickedFlg = false
            alert.hideView()
        }
        
        _ = alert.showSuccess("Add to Cart".localized(), subTitle: "")
        
    }
    
    // action function for the selecting of birthdate
    @objc func choosePlayAmount(_ sender: Any) {
        self.playAmountDropDown.show()
    }
    
    @objc func chooseDrawDate(_ sender: Any) {
        self.drawDateDropDown.show()
    }
    
    @objc func chooseNumberOfPlayers(_ sender: Any) {
        self.playerNumberDropDown.show()
    }
    
    // create additional view
    func createOverlayView(superView: UIView) {
        transprentView =  UIView(frame: superView.frame)
        
        transprentView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.removeOverlayFromSuperView))
        self.transprentView.addGestureRecognizer(tapGesture)
        // here add your Label, Image, etc, what ever you want
        // add label view to help
        
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: superView.frame.maxX - 10,height: superView.frame.maxY - 10))
        label.textAlignment = .left
        label.layer.borderWidth = 0.0
        label.font = UIFont.systemFont(ofSize: 56.0)
        label.numberOfLines = 0
        label.textColor = UIColor.white
        label.text = "Add to Cart View Help Overlay".localized()
        transprentView.addSubview(label)
        UIView.animate(withDuration: 1.5, animations: {
            label.alpha = 1.0
        })
        superView.addSubview(transprentView)
    }
    
    @objc func removeOverlayFromSuperView() {
        config.writeValue(true as AnyObject!, forKey: "addToCartHelpOverlayHasShown", toStore: "settings")
        UIView.animate(withDuration: 1, animations: { self.transprentView.alpha = 0.0 }, completion: { Bool in
            self.transprentView.removeFromSuperview()
        })
    }
    
    // ************************************************
    //  alamofire api to get draw list data
    // ************************************************
    
    func getDrawListForGame(channelData : [String : Any]) {
        self.progressBarDisplayer("Loading...".localized(), true)
        AlamofireRequestAndResponse.sharedInstance.getDrawListForGame(self.gameRefID, success: { (res: [String: Any]) -> Void in
            
            self.messageFrame.removeFromSuperview()
            self.drawList = res["data"] as! NSArray
            let drawDropList : NSMutableArray = NSMutableArray()
            if (self.drawList.count != 0) {
                for item in self.drawList {
                    let drawItem: [String : Any] = item as! [String : Any]
                    drawDropList.add(drawItem["closeScheduledOn"] as! String)
                }
                self.drawDateDropDown.dataSource = drawDropList.copy() as! [String]
                self.addToCartDialog(item: channelData)
            } else {
                _ = SweetAlert().showAlert("Warning!".localized(), subTitle: "Oops! No Draws! \n Try again in a few minutes.".localized(), style: AlertStyle.warning)
                self.tileClickedFlg = false
            }
            
        },
          failure: { (error: [String: Any]) -> Void in
            self.messageFrame.removeFromSuperview()
            self.tileClickedFlg = false
            self.superview?.makeToast("get draw list error.".localized())
        })
    }
    
    // MARK: additional view section
    
    func progressBarDisplayer(_ msg:String, _ indicator:Bool ) {
        print(msg)
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 200, height: 50))
        strLabel.text = msg
        strLabel.textColor = UIColor.white
        messageFrame = UIView(frame: CGRect(x: (self.superview?.frame.midX)! - 90, y: (self.superview?.frame.midY)! - 25 , width: 180, height: 50))
        messageFrame.layer.cornerRadius = 15
        messageFrame.backgroundColor = UIColor(white: 0, alpha: 0.7)
        if indicator {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.startAnimating()
            messageFrame.addSubview(activityIndicator)
        }
        messageFrame.addSubview(strLabel)
        self.superview?.addSubview(messageFrame)
    }

}
