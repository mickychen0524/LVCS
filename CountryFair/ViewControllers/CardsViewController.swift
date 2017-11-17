//
//  CardsViewController.swift
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


class CardsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var btnLogo: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var lblTotalAmont: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // class parameters
    var cardsList : NSArray! = []
    var claimTicketData : [String : Any]!
    var totalAmount : Double!
    var claimLicenseCode : String!
    var termsString : String!
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    // additional view and dialogs

    var agreeToTermsDLG : SCLAlertView?
    var claimCompleteDLG : SCLAlertView?
    
    deinit {
        self.tableView.dataSource = nil
        self.tableView.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.lblTotalAmont.text = String(self.totalAmount)
        self.getAllCardsList()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.goToTicketListView()
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
        
        return self.cardsList.count
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row > -1 {
            let sampleData: [String : Any] = self.cardsList[indexPath.row] as! [String : Any]
            self.createTermsDialog(merchandiseData: sampleData)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :CardsTableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "cardTableViewCell") as? CardsTableViewCell
        let sampleData: [String : Any] = self.cardsList[indexPath.row] as! [String : Any]
        
        cell?.configWithData(item: sampleData)
        cell?.selectionStyle = .none
        
        return cell!
    }
    
    //Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    // MARK: alamofire api section
    func getAllCardsList() {
        let uuid = UUID().uuidString
        var fullData = [String: Any]()
        let middleData = [String: Any]()
        
        fullData["uuid"] = uuid
        fullData["data"] = middleData as Any?
        
        fullData["latitude"] = self.appDelegate.myCoords?.latitude as Any?
        fullData["longitude"] = self.appDelegate.myCoords?.longitude as Any?
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading...".localized()
        
        AlamofireRequestAndResponse.sharedInstance.getAllMerchangiesFromServer(fullData, success: { (res: [String: Any]) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            let resData: [String : Any] = res["data"] as! [String : Any]
            self.cardsList = resData["merchandise"] as! NSArray
            self.tableView.reloadData()
            self.getTermsStringFromServer()
            
        },
       failure: { (error: Error!) -> Void in
            let alert = UIAlertController(title: "Error".localized(), message: "Getting error".localized(), preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default) {
                UIAlertAction in
                
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        })
    }
    
    func completeClaimWithMerchandiesData(merchandiesData : [String : Any]) {
        let uuid = UUID().uuidString
        var fullData = [String: Any]()
        var middleData = [String: Any]()
        var merchandiesItemData = [String : Any]()
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.full
        let convertedDate = dateFormatter.string(from: currentDate)
        
        fullData["uuid"] = uuid
        fullData["correlationRefId"] = "00000000-0000-0000-0000-000000000000"
        fullData["createdOn"] = convertedDate
        
        
        middleData["claimLicenseCode"] = self.claimLicenseCode
        middleData["photoBase64"] = nil
        middleData["pin"] = nil
        
        merchandiesItemData["merchandiseRefId"] = merchandiesData["merchandiseRefId"] as! String
        merchandiesItemData["amount"] = self.totalAmount
        
        middleData["merchandise"] = [merchandiesItemData]
        
        fullData["data"] = middleData
        
        fullData = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading...".localized()
        print(self.appDelegate.JSONStringify(fullData))
        
        AlamofireRequestAndResponse.sharedInstance.ticketClaimComplete(fullData, success: { (res: [String: Any]!) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            let resData: NSArray = res["data"] as! NSArray
            if (resData.count != 0) {
                if let item = resData[0] as? [String : Any] {
                    self.createClaimDialog(merchandiseData: item)
                }
            } else {
                self.createClaimDialog(merchandiseData: [String : Any]())
            }
            
            if (!(self.claimTicketData["isClaimed"] as! Bool)) {
                self.claimTicketData["isClaimed"] = true
                _ = self.appDelegate.updateTicketToLocal(data: self.claimTicketData, style: 3)
            }
            
            
        },
       failure: { (error: [String: Any]!) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            print(self.appDelegate.JSONStringify(error))
            if let errorData: [String: Any] = error["error"] as? [String: Any] {
                let errorDescription = errorData["message"] as! String
                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Checkout error. \n \(errorDescription)", style: AlertStyle.error)
            } else {
                _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Oops! We seem to be having a problem connecting.\n Please try again later.".localized(), style: AlertStyle.error)
            }
        })
    }
    
    func getTermsStringFromServer () {
        var fullData = [String: Any]()
        let middleData = [String: Any]()
        
        AlamofireRequestAndResponse.sharedInstance.addCoordinateToParams(&fullData)
        
        fullData["data"] = middleData as Any?
        
        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        
        AlamofireRequestAndResponse.sharedInstance.getTermsStringOnClaim(fullData, success: { (res: [String: Any]) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            let resData: [String : Any] = res["data"] as! [String : Any]
            self.termsString = resData["terms"] as! String
            
        },
         failure: { (error: Error!) -> Void in
            let alert = UIAlertController(title: "Error".localized(), message: "Getting error".localized(), preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default) {
                UIAlertAction in
                
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        })
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
    
    
    // MARK: additional view section
        
    func createTermsDialog(merchandiseData: [String : Any]) {
        // Create custom Appearance Configuration
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false,
            showCircularIcon: false,
            contentViewColor : UIColor.black,
            contentViewBorderColor : UIColor.black
        )
        
        // Initialize SCLAlertView using custom Appearance
        let alert = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 304))
        let x = (subview.frame.width - 180) / 2
        
        // Add image
        let targetImg = UIImageView(frame: CGRect(x: 0, y: 0, width: 216,height: 144))
        let orgUrlStr = merchandiseData["merchandiseImageUrl"] as! String
        let urlString = orgUrlStr.replacingOccurrences(of: "https://demolngcdn.blob.core.windows.net", with: "https://dev2lngmstrasia.blob.core.windows.net")
        let logoUrl: URL = URL(string: urlString)!
        
        DispatchQueue.global().async  {
            targetImg.sd_setImage(with: logoUrl)
        }
        subview.addSubview(targetImg)
        
        // Add label
        let label = UILabel(frame: CGRect(x: x, y: targetImg.frame.maxY + 5, width: 180,height: 45))
        label.textColor = UIColor.white
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 20.0)
        label.text = "Agree To Terms:".localized()
        subview.addSubview(label)
        
        // Add textArea
        let txtArea = UITextView(frame: CGRect(x: 5, y: label.frame.maxY + 5, width: 206,height: 110))
        txtArea.text = self.termsString
        txtArea.font = UIFont.systemFont(ofSize: 15.0)
        subview.addSubview(txtArea)
        
        // Add the subview to the alert's UI property
        alert.customSubview = subview
        _ = alert.addButton("OK".localized()) {
            self.completeClaimWithMerchandiesData(merchandiesData: merchandiseData)
        }
        
        // Add Button with Duration Status and custom Colors
        
        _ = alert.addButton("Nope".localized(), backgroundColor: UIColor.rgb(255, green: 249, blue: 0), textColor: UIColor.rgb(0, green: 151, blue: 7)) {
            self.goToTicketListView()
            print("Cancel Button tapped")
        }
        alert.showSuccess("", subTitle: "")
        
    }
    
    func createClaimDialog(merchandiseData: [String : Any]) {
        // Create custom Appearance Configuration
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false,
            showCircularIcon: false,
            contentViewColor : UIColor.black,
            contentViewBorderColor : UIColor.black
        )
        
        // Initialize SCLAlertView using custom Appearance
        let alert = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 334))
        let x = (subview.frame.width - 180) / 2
        
        // Add image
        let targetImg = UIImageView(frame: CGRect(x: 0, y: 0, width: 216,height: 144))
        if let targetBase64Str = merchandiseData["merchandiseImageBase64"] as? String {
            do {
                let dataDecoded : NSData = try NSData(contentsOf: URL(string: targetBase64Str)!)
                targetImg.image = UIImage(data: dataDecoded as Data)
                UIImageWriteToSavedPhotosAlbum(targetImg.image!, self, nil, nil)
            } catch let error as NSError {
                print(error)
            }
            
        } else {
            targetImg.image = UIImage(named: "target.png")
        }
        
        subview.addSubview(targetImg)
        
        // Add label
        let labelDone = UILabel(frame: CGRect(x: x, y: targetImg.frame.maxY + 2, width: 180,height: 35))
        labelDone.textColor = UIColor.white
        labelDone.textAlignment = .center
        labelDone.font = UIFont.systemFont(ofSize: 22.0)
        labelDone.text = "Done!".localized()
        subview.addSubview(labelDone)
        
        // Add number label
        let labelNumber = UILabel(frame: CGRect(x: x, y: labelDone.frame.maxY + 2, width: 180,height: 25))
        labelNumber.textColor = UIColor.white
        labelNumber.textAlignment = .center
        labelNumber.font = UIFont.systemFont(ofSize: 20.0)
        if let lblNumberStr = merchandiseData["merchandiseCode"] as? String {
            labelNumber.text = lblNumberStr
        } else {
            labelNumber.text = "12345-7865"
        }
        
        subview.addSubview(labelNumber)
        
        // Add description label
        let labelDesc = UILabel(frame: CGRect(x: x, y: labelNumber.frame.maxY + 2, width: 180,height: 80))
        labelDesc.textColor = UIColor.white
        labelDesc.textAlignment = .left
        labelDesc.numberOfLines = 5
        labelDesc.font = UIFont.systemFont(ofSize: 15.0)
        labelDesc.text = "We have saved this card to your photos folder. The code is your cash value so please redeem it now.".localized()
        subview.addSubview(labelDesc)
        
        // Add wallet image
        let walletImg = UIImageView(frame: CGRect(x: x + 35, y: labelDesc.frame.maxY + 5, width: 110,height: 40))
        walletImg.image = UIImage(named:"apple_wallet.png")
        subview.addSubview(walletImg)
        
        // Add the subview to the alert's UI property
        alert.customSubview = subview
        _ = alert.addButton("OK".localized()) {
            self.claimTicketData["isCompleted"] = true
            _ = self.appDelegate.updateTicketToLocal(data: self.claimTicketData, style: 1)
            self.goToTicketListView()
        }
        
        alert.showSuccess("", subTitle: "")
        
    }
    
    // go to ticket list view after complete or cancel
    func goToTicketListView() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        if let vc : SnapContainerViewController = mainStoryboard.instantiateViewController(withIdentifier: "snapContainerViewController") as? SnapContainerViewController {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
}
