//
//  CheckoutFileDownloadViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/22/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import UserNotifications

class CheckoutFileDownloadViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CheckoutDownloadFileTableViewCellDelegate, DownloadItemDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    lazy var downloadFileArr : [[String : Any]]! = [[String : Any]]()
    
    lazy var checkingCompleteArr : [Bool?] = []
    
    lazy var giftSuccessArr : NSArray! = NSArray()
    lazy var giftErrorArr : NSArray! = NSArray()
    
    var downloadCompleteFlg : Bool = false
    
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    override func viewDidLoad() {
        super.viewDidLoad()
        self.checkingCompleteArr = [Bool?](repeating: nil, count: self.downloadFileArr.count)
        for index in 0 ..< self.checkingCompleteArr.count {
            self.checkingCompleteArr[index] = false
        }
        
        let mutableDownloadFileArr = NSMutableArray()
        for var downloadItem in self.downloadFileArr{
            downloadItem["downloaded"] = false
            downloadItem["progress"] = 0.description
            mutableDownloadFileArr.add(downloadItem)
        }
        self.downloadFileArr = mutableDownloadFileArr.copy() as! [[String : Any]]
        
        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        // Do any additional setup after loading the view.
//        DownloadItemManager.shared.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: notification part

    // Remove the LCLLanguageChangeNotification on viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DownloadItemManager.sharedManager.downloadItems.forEach{findCellIdByName(fileName: $0.fileName!)}
    }
    
    deinit {
        DownloadItemManager.sharedManager.delegateManager = nil
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
        if indexPath.row > -1 {}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :CheckoutDownloadFileTableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "checkoutDownloadTableViewCell") as? CheckoutDownloadFileTableViewCell
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
        return 0;
    }
    
    // Override to support conditional rearranging of the table view.
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    // end table view helper //

    // MARK: Cell delegate function
    
    func giftCardSaveComplete(ticketStatus: Bool, fileIndex: Int, completeFlg : Bool) {
        self.view.makeToast("Your gift card \(fileIndex + 1) is ready!")
        
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
        
        let giftItem = self.downloadFileArr[fileIndex]
        let giftName = giftItem["fileName"] as! String
        if ticketStatus {
            for item in self.giftSuccessArr {
                var giftSSItem = item as! [String : Any]
                if (giftSSItem["fileName"] as! String == giftName) {
                    if (giftSSItem["isGiftCard"] as! Bool) {
                        _ = self.appDelegate.saveOneRedeemCardItemToLocal(data: giftSSItem)
                    } else {
                        _ = self.appDelegate.saveOneCouponItemToLocal(data: giftSSItem)
                    }
                    break
                }
            }
        } 
        
        if (self.downloadCompleteFlg) {
            self.appDelegate.giftCardDownloadFlg = true
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc : SnapContainerViewController = storyboard.instantiateViewController(withIdentifier: "snapContainerViewController") as? SnapContainerViewController {
                self.navigationController?.pushViewController(vc, animated: true)
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func giftCardDownloadStarted (fileIndex : Int) {
        var fileItem : [String : Any] = self.downloadFileArr[fileIndex]
        fileItem["downloaded"] = true
        self.downloadFileArr[fileIndex] = fileItem
        
    }
    //MARK: DownloadItemDelegate
    
    func downloadProgress(progress: Double, fileName:String) {
        let fileIndex = getFileIndex(for: fileName)
        if fileIndex != -1 {
            var fileItem : [String : Any] = self.downloadFileArr[fileIndex]
            fileItem["progress"] = progress.description
            self.downloadFileArr[fileIndex] = fileItem
        }
        findCellIdByName(fileName: fileName)
    }
    
    func downloadSuccess(entityData: Data, fileName:String) {
        let fileIndex = getFileIndex(for: fileName)
        if fileIndex != -1 {
            var fileItem : [String : Any] = self.downloadFileArr[fileIndex]
            fileItem["progress"] = 100.description
            self.downloadFileArr[fileIndex] = fileItem
        }
        findCellIdByName(fileName: fileName)
    }
    
    func downloadFailed(error: Error, fileName:String) {
        print("Error \(error) in fileName \(fileName)")
    }
    
    func findCellIdByName(fileName: String) {
        let fileIndex = getFileIndex(for: fileName)
        if fileIndex != -1 {
            reloadCells(fileName: fileName, fileIndex: fileIndex)
        }
    }
    
    func getFileIndex(for fileName:String) -> Int {
        let fileIndex:Int = -1
        for i in 0..<self.downloadFileArr.count {
            let item = self.downloadFileArr[i]
            if let currentItemName = item["fileName"] as? String, currentItemName == fileName {
                return i;
            }
        }
        return fileIndex;
    }
    
    func reloadCells(fileName: String, fileIndex:Int) {
        let downloadItem = DownloadItemManager.sharedManager.getDownloadItem(withName: fileName)
        if downloadItem != nil, downloadItem?.isDownloading != nil, (downloadItem?.isDownloading)! {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.giftCardSaveComplete(ticketStatus: true, fileIndex: fileIndex, completeFlg: true)
            }
        } else{
            self.giftCardDownloadStarted(fileIndex: fileIndex)
        }
    }

}
