//
//  TicketListViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/24/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SCLAlertView
import QRCode
import ZBarSDK
import MGSwipeTableCell

class TicketListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TicketListTableViewCellDelegate {

    @IBOutlet weak var recentSegCtrl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var ticketDataArr : NSArray!
    var orgTicketDataArr : NSArray!
    
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        getAllTicketsList()
        self.recentSegCtrl.selectedSegmentIndex = 1
        self.config.writeValue(true as AnyObject?, forKey: "ticketRecentFlag", toStore: "settings")
        self.rearrangeTableView()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        
        return self.ticketDataArr.count
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row > -1 {
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc : TicketDetailViewController = mainStoryboard.instantiateViewController(withIdentifier: "ticketDetailViewController") as! TicketDetailViewController
            let sampleData: [String : Any] = self.ticketDataArr[indexPath.row] as! [String : Any]
            vc.previewItem = sampleData
            guard let _ : String = sampleData["fileName"] as? String else {
                return
            }
            
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :TicketListTableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "ticketListViewCell") as? TicketListTableViewCell
        
        if let sampleData: [String : Any] = self.ticketDataArr[indexPath.row] as? [String : Any] {
            cell?.configWithData(item: sampleData)
        }
        cell?.selfViewController = self
        cell?.selectionStyle = .none
        cell?.cellDelegate = self
        
        // swipe right button and action of table view
//        cell?.leftButtons = [MGSwipeButton(title: "Delete", backgroundColor: .red){
//            (sender: MGSwipeTableCell!) -> Bool in
//            
//            let sampleData: [String : Any] = self.ticketDataArr[indexPath.row] as! [String : Any]
//            self.validateTicketWithHash(ticketData: sampleData, type : 2)
//            return true
//            }]
//        
//        cell?.leftSwipeSettings.transition = .drag
        return cell!
    }
    
    //Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let sampleData: [String : Any] = self.ticketDataArr[indexPath.row] as! [String : Any]
        
        let claim = UITableViewRowAction(style: .normal, title: "Claim") { action, index in
            self.validateTicketWithHash(ticketData: sampleData, type : 1)
        }
        
        claim.backgroundColor = UIColor.rgb(31, green: 123, blue: 76)
        
        if (!(sampleData["isCompleted"] as! Bool)) {
            return [claim]
        } else {
            return []
        }
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
    
    @IBAction func ticektListSegCtrlAction(_ sender: Any) {
        self.rearrangeTableView()
    }
    
    func rearrangeTableView() {
        if (self.orgTicketDataArr.count > 5) {
            if (recentSegCtrl.selectedSegmentIndex == 1) {
                
                self.config.writeValue(true as AnyObject?, forKey: "ticketRecentFlag", toStore: "settings")
                self.ticketDataArr = Array(self.ticketDataArr.prefix(5)) as NSArray!
                self.tableView.reloadData()
            } else {
                
                self.config.writeValue(false as AnyObject?, forKey: "ticketRecentFlag", toStore: "settings")
                self.ticketDataArr = self.orgTicketDataArr.copy() as! NSArray
                self.tableView.reloadData()
            }
        } else {
            if (recentSegCtrl.selectedSegmentIndex == 1) {
                
                self.config.writeValue(true as AnyObject?, forKey: "ticketRecentFlag", toStore: "settings")
                self.tableView.reloadData()
            } else {
                
                self.config.writeValue(false as AnyObject?, forKey: "ticketRecentFlag", toStore: "settings")
                self.tableView.reloadData()
            }
        }
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
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading...".localized()
        
        AlamofireRequestAndResponse.sharedInstance.ticketValidateApi(data, success: { (res: [String: Any]!) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
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
                    self.tableView.reloadData()
                    
                    vc.totalAmount = totalAmount
                    vc.claimLicenseCode = claimLicenseCode
                    
                    self.present(vc, animated: true, completion: nil)
                    
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
                                self.getAllTicketsList()
                                self.tableView.reloadData()
                            }
                            
                        }
                    }
                    
                }
                break;
            default:
                
                break;
            }
            
            
        }, failure: { (_ error: NSError?, _ statusCode: Int?) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! We seem to be having a problem connecting. \n Please try again later.".localized(), style: AlertStyle.error)
        })
    }

    func getAllTicketsList() {
        
        print(self.appDelegate.JSONStringify(self.appDelegate.getTicketJSONDataFromLocal()))
        self.ticketDataArr = self.appDelegate.getTicketJSONDataFromLocal()
        self.orgTicketDataArr = self.ticketDataArr.copy() as! NSArray
    }
    
    // MARK: shopping cart cell delegate
    func buttonClicked() {
        self.getAllTicketsList()
        self.tableView.reloadData()
    }
}
