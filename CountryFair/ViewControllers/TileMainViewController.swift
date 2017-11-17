//
//  TileMainViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import Alamofire
import SCLAlertView
import DatePickerDialog
import MobileCoreServices
import Localize_Swift
import Refresher
import Kingfisher
import AudioToolbox
import ImageIO
import QuartzCore
import CoreImage
import AVFoundation
import Social

class TileMainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: parameters
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var btnTicketCart: BadgeUIBarButtonItem!
    @IBOutlet weak var btnShoppingCart: BadgeUIBarButtonItem!
    @IBOutlet weak var btnQuestionCart: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var btnMain: UIButton!
    
    var playerData : [String: Any]! = [:]
    lazy var gameData: NSArray! = NSArray()
    lazy var prizeData: NSMutableArray! = NSMutableArray()
    lazy var brandsData: NSArray! = NSArray()
    lazy var channelGroupData: NSArray! = NSArray()
    lazy var shoppingCartData: [String:Any] = [:]
    lazy var shoppingCartItemsArr: NSArray! = NSArray()
    var i_wasBorn : Int = 0
    var str_wasBorn : String = ""
    var imgSelfieImage : UIImage?
    var socialImage : UIImage?
    var str_playerRegisterLisence : String = ""
    
    lazy var messageFrame = UIView()
    lazy var transprentView = UIView()
    lazy var activityIndicator = UIActivityIndicatorView()
    lazy var strLabel = UILabel()
    var config = GTStorage.sharedGTStorage
    lazy var refreshControl: UIRefreshControl! = UIRefreshControl()
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    let transition = PopAnimator()
    
    var uiBarButtonTicketSave = UIBarButtonItem()
    
    // json data getting url for temporary data

//    private let getAllChannelsUrl = "https://dev2lngmstr.blob.core.windows.net/templates/channels.json"
//    private let playerRegisterUrl = "https://dev2lngmstr.blob.core.windows.net/templates/playerregister.json"
    
    private let getAllChannelsUrl = Config.APIEndpoints.baseUrl + Config.APIEndpoints.getAllChannelsUrl
    private let playerRegisterUrl = Config.APIEndpoints.baseUrl + Config.APIEndpoints.playerRegisterUrl
    
    var prizeSaveFlg : Bool = false
    var numberOfLoop : Int = 0
    var fullDataCount : Int = 0
    var imageFileDownloadCount : Int = 0
    
    // background task
    var updateTimer: Timer?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    // MARK: start app
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.clipsToBounds = true
        
        self.uiBarButtonTicketSave = self.btnTicketCart
        
        self.setBadgeInShoppingCart()
        
        self.getRealDataFromServer()
        // start view
        self.initView()
        
        self.numberOfLoop = 0
        self.fullDataCount = 0
        
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        // register background task
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
    }
    
    // MARK: register background process
    deinit {
        print("main table view deinit")
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
        self.casheAndReplaceChannelImageData(data : self.channelGroupData)
        
        switch UIApplication.shared.applicationState {
        case .active:
            print("download table view active")
        case .background:
            print("Download Count: \(self.imageFileDownloadCount)")
            print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
        case .inactive:
            break
        }
    }
    
    // set menubutton action after checking the selfie and age
    func setMenuAction() {
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.rightRevealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
    
    
    // set badge count in shopping cart button
    @objc func setBadgeInShoppingCart() {
        // get all shopping cart data
        
        var totalPanelCount : Int = 0
        let midData: [String:Any] = self.appDelegate.getJSONDataFromLocal()
        self.shoppingCartData = midData["shoppingCarts"] as! [String:Any]
        self.shoppingCartItemsArr = self.shoppingCartData["items"] as! NSArray
        for item in self.shoppingCartItemsArr {
            let cartItem : [String : Any] = item as! [String : Any]
            totalPanelCount += Int(cartItem["panelCount"] as! Int)
        }
        
        if totalPanelCount > 0 {
            btnShoppingCart.addBadge(number: totalPanelCount, withOffset: CGPoint(x: 0, y: 5), andColor: .green, andFilled: true, fontColor: .red)
            btnShoppingCart.btn.addTarget(self, action: #selector(btnShoppingCartAction(_:)), for: .touchUpInside)
        }
        
        // get all ticket cart data
        let midArr: NSArray = self.appDelegate.getTicketJSONDataFromLocal()
        if midArr.count > 0 {
            btnTicketCart.addBadge(number: midArr.count, withOffset: CGPoint(x: 0, y: 5), andColor: .red, andFilled: true, fontColor: .green)
            btnTicketCart.btn.addTarget(self, action: #selector(btnTicketAction(_:)), for: .touchUpInside)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated) // No need for semicolon
        
    }
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    @IBAction func btnLogoAction(_ sender: AnyObject) {
        
    }
    
    @IBAction func btnTicketAction(_ sender: Any) {
        let midArr: NSArray = self.appDelegate.getTicketJSONDataFromLocal()
        if (midArr.count == 0) {
            self.view.makeToast("Oops! You don't have any tickets to view.".localized())
        } else {
            gotoMyTicketList()
        }
    }
    
    @IBAction func btnShoppingCartAction(_ sender: AnyObject) {
        if (self.shoppingCartItemsArr.count == 0) {
            self.view.makeToast("Add items to your shopping cart!".localized())
        } else {
            gotoCheckoutAction()
        }
    }
    
    func gotoMyTicketList() {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        if let vc = storyboard.instantiateViewController(withIdentifier: "ticketNavViewController") as? UINavigationController {
//            let revealController:SWRevealViewController = self.revealViewController()
//            revealController.setFront(vc, animated: true)
//        }
    }
    
    func gotoCheckoutAction() {
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let vc : ShoppingCartViewController = mainStoryboard.instantiateViewController(withIdentifier: "shoppingCartViewController") as? ShoppingCartViewController {
            vc.shoppingCartData = self.shoppingCartItemsArr
            self.present(vc, animated: true, completion: nil)
        }
 
    }
    
    @IBAction func btnQuestionCartAction(_ sender: AnyObject) {
        self.createOverlayView()
    }
    
    // initialize UIView at start
    func initView() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        // add table view refresher
        if let customSubview = Bundle.main.loadNibNamed("CustomSubview", owner: self, options: nil)?.first as? CustomSubview {
            tableView.addPullToRefreshWithAction({
                OperationQueue().addOperation {
                    //                    sleep(2)
                    OperationQueue.main.addOperation {
                        self.messageFrame.removeFromSuperview()
                        self.setBadgeInShoppingCart()
                        KingfisherManager.shared.cache.clearMemoryCache()
                        KingfisherManager.shared.cache.clearDiskCache()
                        //                        self.makeTempararyData()
                        // make temporary to test channel data
                        self.getRealDataFromServer()
                        self.tableView.stopPullToRefresh()
                    }
                }
            }, withAnimator: customSubview)

        }
        
        // set timer for check the badge
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.setBadgeInShoppingCart), userInfo: nil, repeats: true);
    }
    
    // Alamofire data getting section from server using GET url
    
    func getDrawListForGame(gameRefId : String) {
        
        AlamofireRequestAndResponse.sharedInstance.getDrawListForGame(gameRefId, success: { (res: [String: Any]) -> Void in
            
            let _ : NSArray = res["data"] as! NSArray
            
        },
          failure: { (error: [String: Any]) -> Void in
            //            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "DrawList getting error.", style: AlertStyle.error)
        })
    }
    
    func getRealDataFromServer() {
        getGameData()
    }
    
    func getGameData() {
        self.progressBarDisplayer("Loading...".localized(), true)
        let data : [String : Any] = [String : Any]()
        
        AlamofireRequestAndResponse.sharedInstance.getAllGameList(data, success: { (res: [String : Any]) -> Void in
            self.messageFrame.removeFromSuperview()
            if let serverArr = res["data"] as? NSArray {
                let resData: NSArray = serverArr
                if (resData.count != 0) {
                    let samItem : [String : Any] = resData[0] as! [String : Any]
                    let samGameRefId = samItem["gameRefId"] as! String
                    self.getDrawListForGame(gameRefId: samGameRefId)
                }
                let newGamemutableArr : NSMutableArray = self.casheAndReplaceGameImageData(data: resData)
                self.gameData = newGamemutableArr.copy() as! NSArray
                self.appDelegate.gameGlobalArr = self.gameData
                self.getBrandData()
            }
            
        },
          failure: { (error: Error!) -> Void in
            let alert = UIAlertController(title: "Error".localized(), message: "Oops! Our services are not responding, try back later.".localized(), preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default) {
                UIAlertAction in
                
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            self.messageFrame.removeFromSuperview()
        })
    }
    
    func getBrandData() {
        self.progressBarDisplayer("Loading...".localized(), true)
        let data : [String : Any] = [String : Any]()
        
        AlamofireRequestAndResponse.sharedInstance.getAllBrandsAndChannelgroupList(data, success: { (res: [String: Any]) -> Void in
            self.messageFrame.removeFromSuperview()
            
            if let serverArr = res["data"] as? NSArray {
                let resData: NSArray = serverArr
                self.brandsData = resData
                
                let newChannelGroupData = NSMutableArray()
                
                self.channelGroupData = NSArray()
                for item in self.brandsData{
                    var brandTemp = item as! [String : Any]
                    let groupChannel : [[String:Any]] = brandTemp["channelGroups"] as! [[String:Any]]
                    
                    let sortedArray = groupChannel.sorted { (obj1, obj2) -> Bool in
                        return (obj1["priority"] as! Int) < (obj2["priority"] as! Int)
                    }
                    
                    for item in sortedArray {
                        
                        var channelDataItem = item
                        channelDataItem["brandRefId"] = brandTemp["brandRefId"] as! String
                        newChannelGroupData.add(channelDataItem)
                    }
                    
                }
                
                self.channelGroupData = newChannelGroupData.copy() as! NSArray
                self.appDelegate.channelGroupGlobalArr = self.channelGroupData
                
                self.downloadImage()
                self.registerBackgroundTask()
                
                // check main view start state and display overlay
                if (!(self.config.getValue("channelHelpOverlayHasShown", fromStore: "settings") as! Bool)){
                    self.createOverlayView()
                } else {
                    self.tableView.reloadData()
                }
            }
            
        },
           failure: { (error: Error!) -> Void in
            let alert = UIAlertController(title: "Error".localized(), message: "Oops! Our services are not responding, try back later.".localized(), preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default) {
                UIAlertAction in
                
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            self.messageFrame.removeFromSuperview()
        })
    }
    
    //***************************************************/
    //*    get prizes data and sort by the amount
    //***************************************************/
    
    func makeAndSortAllPrizesData(data: NSArray) -> NSMutableArray{
        
        let newPrizeArr : NSMutableArray = NSMutableArray()
        for item1 in data {
            var maxPrizeObj : [String : Any] = [String : Any]()
            let gameItem : [String : Any] = item1 as! [String : Any]
            let prizesArr : NSArray = gameItem["prizes"] as! NSArray
            maxPrizeObj = prizesArr[0] as! [String : Any]
            for item2 in prizesArr {
                
                let prizeItem : [String : Any] = item2 as! [String : Any]
                let amountOfMaxPrize : Int = maxPrizeObj["sortOrder"] as! Int
                let amountOfNewPrize : Int = prizeItem["sortOrder"] as! Int
                if (amountOfNewPrize > amountOfMaxPrize) {
                    maxPrizeObj = prizeItem
                }
            }
            maxPrizeObj["gameRefId"] = gameItem["gameRefId"] as! String
            maxPrizeObj["gameName"] = gameItem["gameName"] as! String
            maxPrizeObj["logoUrl"] = gameItem["logoUrl"] as! String
            newPrizeArr.add(maxPrizeObj)
        }
        
        return newPrizeArr
    }
    
    //***************************************************/
    //* cashing the all images to local and replace game
    //***************************************************/
    
    func casheAndReplaceGameImageData(data: NSArray) -> NSMutableArray{
        
        let gameArr : NSMutableArray = NSMutableArray()
        
        for item1 in data {
            var gameItem : [String : Any] = item1 as! [String : Any]
            let urlStr = gameItem["logoUrl"] as! String
            let fileName = urlStr.components(separatedBy: "/").last
            let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
            
            Alamofire.download(urlStr, method: .get, parameters: nil, to: destination)
                .responseData { response in
                    self.numberOfLoop += 1
                    if let _ = response.result.value {
                        if (self.numberOfLoop == data.count && !self.prizeSaveFlg) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                self.prizeSaveFlg = true
                                self.prizeData = self.makeAndSortAllPrizesData(data: self.gameData)
                                self.appDelegate.savePrizeCartWithBase64Images(prizeCartArr: self.prizeData.copy() as! NSArray)
                            }
                        }
                    }
            }
            gameItem["logoUrl"] = fileName
            
            gameArr.add(gameItem)
            
        }
        return gameArr
    }
    
    //***************************************************/
    //* cashing the all images to local and replace cahnnel
    //***************************************************/
    
    func casheAndReplaceChannelImageData(data: NSArray){
        
        self.fullDataCount += data.count
        for item1 in data {
            
            var channelItem : [String : Any] = item1 as! [String : Any]
            let urlStr = channelItem["channelGroupLogoUrl"] as! String
            let fileName = urlStr.components(separatedBy: "/").last
            self.fileDownloadFromServer(fileUrl: urlStr, chItem :[String : Any](), chGroupItem :channelItem, fileName : fileName!, type : 1)
            
            let channelGroupData : NSArray = channelItem["channels"] as! NSArray
            
            for item2 in channelGroupData {
                
                self.fullDataCount += 1
                var channelGroupItem : [String : Any] = item2 as! [String : Any]
                var ticketTemplate : [String : Any] = channelGroupItem["ticketTemplate"] as! [String : Any]
                let ticketTemplateTileUrl : String = ticketTemplate["tileUrl"] as! String
                let ticketTileFileName = ticketTemplateTileUrl.components(separatedBy: "/").last
                
                self.fileDownloadFromServer(fileUrl: ticketTemplateTileUrl, chItem :channelGroupItem, chGroupItem :channelItem, fileName : ticketTileFileName!, type : 2)
                
            }
        }
        for item1 in data {
            
            var channelItem : [String : Any] = item1 as! [String : Any]
            let channelGroupData : NSArray = channelItem["channels"] as! NSArray
            
            for item2 in channelGroupData {
                
                self.fullDataCount += 1
                var channelGroupItem : [String : Any] = item2 as! [String : Any]
                var ticketTemplate : [String : Any] = channelGroupItem["ticketTemplate"] as! [String : Any]
                let ticketTemplateTileAnimatedUrl : String = ticketTemplate["tileAnimatedUrl"] as! String
                
                let ticketTileAnimatedFileName = ticketTemplateTileAnimatedUrl.components(separatedBy: "/").last
                self.fileDownloadFromServer(fileUrl: ticketTemplateTileAnimatedUrl, chItem :channelGroupItem, chGroupItem :channelItem, fileName : ticketTileAnimatedFileName!, type : 3)
            }
        }
    }
    
    func fileDownloadFromServer(fileUrl : String, chItem : [String : Any], chGroupItem : [String : Any], fileName : String, type : Int) {
        //        self.progressBarDisplayer("Downloading...", true)
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        Alamofire.download(fileUrl, method: .get, parameters: nil, to: destination)
            .responseData { response in
                
                self.imageFileDownloadCount += 1
                if let _ = response.result.value {
                    print("Download successed count: \(self.imageFileDownloadCount)")
                } else {
                    print("Download failed count: \(self.imageFileDownloadCount)")
                }
                
                self.messageFrame.removeFromSuperview()
                
                switch type {
                case 1:
                    
                    let channelArr : NSMutableArray = NSMutableArray()
                    
                    for item1 in self.channelGroupData {
                        
                        var channelItem : [String : Any] = item1 as! [String : Any]
                        if (chGroupItem["channelGroupRefId"] as! String == channelItem["channelGroupRefId"] as! String) {
                            channelItem["channelGroupLogoUrl"] = fileName
                            channelItem["localSavingState"] = true
                        }
                        channelArr.add(channelItem)
                        
                    }
                    
                    self.channelGroupData = channelArr.copy() as! NSArray
                    self.appDelegate.channelGroupGlobalArr = self.channelGroupData
                    
                    break
                    
                case 2:
                    let channelArr : NSMutableArray = NSMutableArray()
                    
                    for item1 in self.channelGroupData {
                        
                        let channelGroupArr : NSMutableArray = NSMutableArray()
                        var channelItem : [String : Any] = item1 as! [String : Any]
                        
                        let channelGroupData : NSArray = channelItem["channels"] as! NSArray
                        
                        for item2 in channelGroupData {
                            
                            var channelGroupItem : [String : Any] = item2 as! [String : Any]
                            var ticketTemplate : [String : Any] = channelGroupItem["ticketTemplate"] as! [String : Any]
                            if (chItem["channelRefId"] as! String == channelGroupItem["channelRefId"] as! String) {
                                ticketTemplate["tileUrl"] = fileName
                                channelGroupItem["ticketTemplate"] = ticketTemplate
                                channelGroupItem["localSavingStateStatic"] = true
                            }
                            
                            channelGroupArr.add(channelGroupItem)
                        }
                        channelItem["channels"] = channelGroupArr.copy() as! NSArray
                        channelArr.add(channelItem)
                        
                    }
                    self.channelGroupData = channelArr.copy() as! NSArray
                    self.appDelegate.channelGroupGlobalArr = self.channelGroupData
                    break
                    
                case 3:
                    let channelArr : NSMutableArray = NSMutableArray()
                    
                    for item1 in self.channelGroupData {
                        
                        let channelGroupArr : NSMutableArray = NSMutableArray()
                        var channelItem : [String : Any] = item1 as! [String : Any]
                        
                        let channelGroupData : NSArray = channelItem["channels"] as! NSArray
                        
                        for item2 in channelGroupData {
                            
                            var channelGroupItem : [String : Any] = item2 as! [String : Any]
                            var ticketTemplate : [String : Any] = channelGroupItem["ticketTemplate"] as! [String : Any]
                            if (chItem["channelRefId"] as! String == channelGroupItem["channelRefId"] as! String) {
                                ticketTemplate["tileAnimatedUrl"] = fileName
                                channelGroupItem["ticketTemplate"] = ticketTemplate
                                channelGroupItem["localSavingState"] = true
                            }
                            
                            channelGroupArr.add(channelGroupItem)
                        }
                        channelItem["channels"] = channelGroupArr.copy() as! NSArray
                        channelArr.add(channelItem)
                        
                    }
                    self.channelGroupData = channelArr.copy() as! NSArray
                    self.appDelegate.channelGroupGlobalArr = self.channelGroupData
                    break
                    
                default:
                    
                    break;
                    
                }
                if (self.imageFileDownloadCount == self.fullDataCount) {
                    self.imageFileDownloadCount = 0
                    self.fullDataCount = 0
                    if self.backgroundTask != UIBackgroundTaskInvalid {
                        self.endBackgroundTask()
                    }
                    self.tableView.reloadData()
                }
                
        }
    }
    
    // MARK: table helper functions
    /**************************************************************************************
     *
     *  UITable View Delegate Functions
     *
     **************************************************************************************/
    
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.channelGroupData.count
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row > -1 {
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tileMainTableViewCell", for: indexPath) as! TileMainTableViewCell
        let sampleData: [String : Any] = self.channelGroupData[indexPath.row] as! [String : Any]
        cell.gameList = self.gameData
        cell.brandList = self.brandsData
        
        cell.configWithData(item: sampleData)
        cell.selectionStyle = .none
        
        return cell
    }
    
    //Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
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
    
    // MARK: make temp data
    // get all data from local json file
    func makeTempararyData() {
        
        if let path = Bundle.main.path(forResource: "playerData", ofType: "json")
        {
            
            do {
                let jsonData = try NSData(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.mappedIfSafe)
                if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                {
                    
                    self.playerData! = jsonResult["data"] as! [String : Any]
                    self.gameData = playerData["games"] as! NSArray
                    self.brandsData = playerData["brands"] as! NSArray
                    self.channelGroupData = playerData["channelGroups"] as! NSArray
                    self.tableView.reloadData()
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
        }
    }
    
    // get all data from local json file
    func makeRegisterTempData() -> [String : Any]{
        
        if let path = Bundle.main.path(forResource: "registerTempData", ofType: "json")
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
    
    // MARK: additional view processing part
    //***************************************//
    //  Additional view creating section
    //***************************************//
    
    func progressBarDisplayer(_ msg:String, _ indicator:Bool ) {
        print(msg)
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 200, height: 50))
        strLabel.text = msg
        strLabel.textColor = UIColor.white
        messageFrame = UIView(frame: CGRect(x: view.frame.midX - 90, y: view.frame.midY - 25 , width: 180, height: 50))
        messageFrame.layer.cornerRadius = 15
        messageFrame.backgroundColor = Style.Colors.blackSemiTransparentColor
        if indicator {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.startAnimating()
            messageFrame.addSubview(activityIndicator)
        }
        messageFrame.addSubview(strLabel)
        view.addSubview(messageFrame)
    }
    
    func createOverlayView() {
        transprentView =  UIView(frame: UIScreen.main.bounds)
        
        transprentView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.removeOverlayFromSuperView))
        self.transprentView.addGestureRecognizer(tapGesture)
        // here add your Label, Image, etc, what ever you want
        // add label view to help
        
        let extractedExpr: CGRect = CGRect(x: 30, y: 30, width: UIScreen.main.bounds.maxX - 30,height: UIScreen.main.bounds.maxY - 30)
        let label = UILabel(frame: extractedExpr)
        label.textAlignment = .left
        label.layer.borderWidth = 0.0
        label.alpha = 0.0
        label.font = UIFont.systemFont(ofSize: 56.0)
        label.numberOfLines = 0
        label.textColor = UIColor.white
        label.text = "Channel View Help Overlay".localized()
        
        UIView.animate(withDuration: 1.5, animations: {
            label.alpha = 1.0
        })
        transprentView.addSubview(label)
        
        self.view.addSubview(transprentView)
    }
    
    @objc func removeOverlayFromSuperView() {
        config.writeValue(true as AnyObject!, forKey: "channelHelpOverlayHasShown", toStore: "settings")
        
        UIView.animate(withDuration: 1, animations: { self.transprentView.alpha = 0.0 }, completion: { Bool in
            self.transprentView.removeFromSuperview()
        })
    }

}
