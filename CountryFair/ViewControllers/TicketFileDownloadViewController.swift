 //
//  TicketFileDownloadViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import UserNotifications
import QRCode
import ZBarSDK
import Alamofire
import AssetsLibrary
import Photos

class TicketFileDownloadViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TicketFileDownloadTableViewCellDelegate {
    
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    // set by parent vc
    lazy var downloadFileArr : [[String : Any]]! = [[String : Any]]()
    
    lazy var shoppingCartArr : NSArray! = NSArray()
    lazy var checkingCompleteArr : [Bool?] = []
    lazy var ticketSuccessArr : NSArray! = NSArray()
    lazy var ticketErrorArr : NSArray! = NSArray()
    
    var downloadCompleteFlg : Bool = false
    
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var updateTimer: Timer?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    var downloadedIndex = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkingCompleteArr = [Bool?](repeating: nil, count: self.downloadFileArr.count)
        for index in 0 ..< self.checkingCompleteArr.count {
            self.checkingCompleteArr[index] = false
        }
        
        let mutableDownloadFileArr = NSMutableArray()
        for var downloadItem in self.downloadFileArr{
            downloadItem["downloaded"] = false
            mutableDownloadFileArr.add(downloadItem)
        }
        self.downloadFileArr = mutableDownloadFileArr.copy() as! [[String : Any]]
        
        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        // download tickets
        
        downloadAllImages(range: downloadFileArr.count > 4 ? 0..<4 : 0..<downloadFileArr.count)
        
        print(downloadFileArr.map({$0["fileName"]}))
        print(downloadFileArr.map({$0["sasUri"]}))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.endBackgroundTask()
    }
    
    func runInMainThread(method: @escaping () -> Swift.Void) {
        if Thread.isMainThread {
            method()
        } else {
            DispatchQueue.main.async {
                method()
            }
        }
    }
    
    func downloadAllImages(range: Range<Int>) {
        for i in 0..<range.upperBound {
            downloadImage(index:i)
        }
    }
    
    func downloadImage(index:Int) {
        
        let intexPathToUpdate = IndexPath(row: index, section: 0)
        var item = self.downloadFileArr[index]
        item.updateValue("", forKey: "StateText")
        item.updateValue("0%", forKey: "ProgressPercent")
        item.updateValue(0.0, forKey: "ProgressViewAngle")
        self.downloadFileArr[index] = item
        
        if let downloaded = item["downloaded"] as? Bool {
            if downloaded {
                item["StateText"] = "Download complete".localized()
                item["ProgressPercent"] = "100%"
                self.runInMainThread {
                    self.tableView.reloadRows(at: [intexPathToUpdate], with: .none)
                }
            } else {
                item["StateText"] = "Started...".localized()
                item["ProgressPercent"] = "0%"
                
                self.runInMainThread {
                    self.tableView.reloadRows(at: [intexPathToUpdate], with: .none)
                }
                
                let fileName = item["fileName"] as? String ?? ""
                let fileUrl = item["sasUri"] as? String ?? ""
                
                if DownloadItemManager.sharedManager.getDownloadItem(withName: fileName) == nil {
                    _ = DownloadItemManager.sharedManager.addDownloadEntity(fileName, fileUrl)
                }
                
                DownloadItemManager.sharedManager.getDownloadedItem(fileName: fileName, progressClosure: { (progress) in
                    item["ProgressViewAngle"] = 360 * progress
                    item["ProgressPercent"] = String.init(format: "%.2f", 100 * progress) + "%"
                    item["StateText"] = "Downloading...".localized()
                    self.downloadFileArr[index] = item
                    
                    let reloadIndexPath = IndexPath(row: index, section: 0)
                    
                    self.runInMainThread {
                        self.tableView.reloadRows(at: [reloadIndexPath], with: .none)
                    }
                }, success: { (data) in
                    self.downloadedIndex += 1
                    
                    let max = 3 + self.downloadedIndex
                    if max < self.downloadFileArr.count {
                        self.downloadImage(index: max)
                    }
                    
                    let notification = UILocalNotification()
                    notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                    notification.alertBody = "Yes! Item \(self.downloadedIndex)  has downloaded!"
                    notification.alertAction = "open"
                    notification.hasAction = true
                    notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
                    
                    self.runInMainThread {
                        UIApplication.shared.scheduleLocalNotification(notification)
                    }
                    
                    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let filePath : String = String.init(format: "%@/%@", documentPath, fileName)
                    print("filePath, \(filePath)")
                    
                    self.updateTimer?.invalidate()
                    
                    item["StateText"] = "Saving...".localized()
                    self.downloadFileArr[index] = item
                    
                    let reloadIndexPath = IndexPath(row: index, section: 0)
                    
                    self.runInMainThread {
                        self.tableView.reloadRows(at: [reloadIndexPath], with: .none)
                    }
                    
                    self.updateTimer = nil
                    
                    if self.backgroundTask != UIBackgroundTaskInvalid {
                        self.endBackgroundTask()
                    }
                    
                    let isImage = UIImage(data:data) != nil
                    let albumName = "My Raffle/Lottery Tickets"
                    
                    PhotoAlbumManager.shared.save(isImage: isImage, path: filePath, albumName: albumName, completionHandler: { (success, error, assetIdentifier) in
                        item["StateText"] = "Download complete".localized()
                        item["assetIdentifier"] = assetIdentifier
                        self.downloadFileArr[index] = item
                        
                        let reloadIndexPath = IndexPath(row: index, section: 0)
                        
                        self.runInMainThread {
                            self.tableView.beginUpdates()
                            self.tableView.reloadRows(at: [reloadIndexPath], with: .none)
                            self.tableView.endUpdates()
                        }
                        self.videoSaveComplete(ticketStatus: true, fileIndex: index, completeFlg : true)
                        print(isImage ? "Photo downloaded" : "Video download")
                    })
                }, failed: { (error) in
                    print("Error \(error)")
                })
            }
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
        return self.downloadFileArr.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :TicketFileDownloadTableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "ticketFileDownloadTableViewCell") as? TicketFileDownloadTableViewCell
        if let sampleData = self.downloadFileArr[indexPath.row] as? [String : Any] {
            cell?.configWithData(item: sampleData)
        }
        
        cell?.fileIndex = indexPath.row
        cell?.selectionStyle = .none
        cell?.cellDelegate = self
        
        return cell!    
    }
    
    //Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return nil
    }
    
    //Override to support custom section headers.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    // end table view helper //
    
    
    
    @IBAction func btnBackAction(_ sender: AnyObject) {
        
        _ = navigationController?.popToRootViewController(animated: true)
    }
    
    func videoSaveComplete(ticketStatus: Bool, fileIndex: Int, completeFlg : Bool) {
        self.view.makeToast("Your item \(self.downloadedIndex) is ready!")
        
        if (completeFlg) {
            self.checkingCompleteArr[fileIndex] = completeFlg
        }
        
        for boolItem in self.checkingCompleteArr {
            if (boolItem)! {
                self.downloadCompleteFlg = true
            } else {
                self.downloadCompleteFlg = false
                break
            }
        }
        
        let ticketItem = self.downloadFileArr[fileIndex]
        let ticketRefId = ticketItem["ticketRefId"] as! String
        if ticketStatus {
            for item in self.ticketSuccessArr {
                var ticketSSItem = item as! [String : Any]
                if (ticketSSItem["ticketRefId"] as! String == ticketRefId) {
                    ticketSSItem["assetIdentifier"] = ticketItem["assetIdentifier"]
                    _ = self.appDelegate.saveOneTicketToLocal(data: ticketSSItem)
                    
                    let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let fileName : String = ticketSSItem["fileName"] as! String
                    let filePath = String.init(format: "%@/%@", documentPath, fileName)
                    if fileName.range(of: "mp4") == nil {
                        
                        let imageFile = ZBarImage.init(cgImage: UIImage.init(contentsOfFile: filePath)?.cgImage)
                        let zbarImageScanner : ZBarImageScanner = ZBarImageScanner()
                        let resultNumber = zbarImageScanner.scanImage(imageFile)
                        if (resultNumber > 0) {
                            let zbarResult : ZBarSymbolSet = zbarImageScanner.results
                            var symbolFound : ZBarSymbol?
                            for symbol in zbarResult{
                                symbolFound = symbol as? ZBarSymbol
                                break
                            }
                            ticketSSItem["licenseCypherText"] = NSString(string: symbolFound!.data) as String
                            _ = self.appDelegate.updateTicketToLocal(data: ticketSSItem, style: 2)
                        }
                        
                    } else {
                        
                        let audioURL: CFURL = CFURLCreateWithString(kCFAllocatorDefault, filePath as CFString!, nil)
                        var audioFile: AudioFileID? = nil
                        var theErr: OSStatus? = nil
                        
                        let hint: AudioFileTypeID = 0
                        
                        
                        
                        // TODO: revisit
                        //                            theErr = AudioFileOpenURL(audioURL, AudioFilePermissions(rawValue: 1)!, hint, &audioFile)
                        
                        //                            assert(theErr == OSStatus(noErr))
                        
                        //                            var outDataSize: UInt32 = 0
                        //                            var isWritable: UInt32 = 0
                        //                            theErr = AudioFileGetPropertyInfo(audioFile!, UInt32(kAudioFilePropertyInfoDictionary), &outDataSize, &isWritable)
                        //                            assert(theErr == OSStatus(noErr))
                        
                        var dictionaryCF: CFDictionary? = nil
                        
                        //                            theErr = AudioFileGetProperty(audioFile!, UInt32(kAudioFilePropertyInfoDictionary), &outDataSize, &dictionaryCF)
                        //                            assert(theErr == OSStatus(noErr))
                        
                        
                        if let dict = dictionaryCF as? [String: AnyObject] {
                            if let lisenceStr = dict["comments"] as? String {
                                ticketSSItem["licenseCypherText"] = lisenceStr
                                _ = self.appDelegate.updateTicketToLocal(data: ticketSSItem, style: 2)
                            }
                        }
                    }
                    
                    break
                }
            }
        } else {
            for item in self.ticketErrorArr {
                let ticketEEItem = item as! [String : Any]
                if (ticketEEItem["ticketRefId"] as! String == ticketRefId) {
                    _ = self.appDelegate.saveOneTicketErrorItemToLocal(data: ticketEEItem)
                    break
                }
            }
        }
        
        if (self.downloadCompleteFlg) {
            _ = self.appDelegate.saveInitJsonData()
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc : SnapContainerViewController = mainStoryboard.instantiateViewController(withIdentifier: "snapContainerViewController") as? SnapContainerViewController {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.present(vc, animated: true, completion: nil)
                }
            }
        }
    }
    
    func ticketDownloadStarted (fileIndex : Int) {
        
        var fileItem : [String : Any] = self.downloadFileArr[fileIndex]
        fileItem["downloaded"] = true
        self.downloadFileArr[fileIndex] = fileItem
        
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
    
}
