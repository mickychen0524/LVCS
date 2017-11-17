//
//  TicketErrorListViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SCLAlertView

class TicketErrorListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnQuestionMark: UIBarButtonItem!
    @IBOutlet weak var BtnDone: UIBarButtonItem!
    
    var ticketErrorList : NSArray!
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var refundDLG : SCLAlertView?
    
    lazy var messageFrame = UIView()
    lazy var transprentView = UIView()
    lazy var activityIndicator = UIActivityIndicatorView()
    lazy var strLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.BtnDone.setTitleTextAttributes([ NSAttributedStringKey.font: Style.Font.boldFontWithSize(size: 20)], for: .normal)
        
        getAllTicketErrorList()
        
        if (!(self.config.getValue("refundTicketViewHelpOverlayShown", fromStore: "settings") as! Bool)){
            self.createOverlayView()
        }
        
        // Do any additional setup after loading the view.
    }
    // get all ticket error list
    func getAllTicketErrorList() {

        ticketErrorList = self.appDelegate.getTicketErrorJSONDataFromLocal()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnBackAction(_ sender: AnyObject) {
        gotoHomeView()
    }
    @IBAction func btnQuestionMarkAction(_ sender: Any) {
        self.createOverlayView()
    }
    
    func gotoHomeView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "mainNavViewController") as! UINavigationController
        let revealController:SWRevealViewController = self.revealViewController()
        revealController.setFront(vc, animated: true)
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
        
        return self.ticketErrorList.count
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row > -1 {
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :TicketErrorTableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "ticketErrorListViewCell") as? TicketErrorTableViewCell
        let sampleData: [String : Any] = self.ticketErrorList[indexPath.row] as! [String : Any]
        
        cell?.configWithData(item: sampleData)
        cell?.selectionStyle = .none
        
        return cell!
    }
    
    //Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let refund = UITableViewRowAction(style: .normal, title: "Refund") { action, index in
            if let item = self.ticketErrorList[indexPath.row] as? [String : Any] {
                self.refundTicketWithData(item: item)
            }
            
            self.getAllTicketErrorList()
            self.tableView.reloadData()
        }
        refund.backgroundColor = Style.Colors.salemColor
        
        return [refund]
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
    
    func refundTicketWithData(item: [String : Any]) {
        
        var data = [String: Any]()
        var middleData = [String: Any]()
        
        if let checkoutSessionLicenseCypherText = item["licenseCypherText"] as? String {
            middleData["checkoutSessionLicenseCypherText"] = checkoutSessionLicenseCypherText
        }
        
        if let ticketRefId = item["ticketRefId"] as? String {
            middleData["ticketRefId"] = ticketRefId
        } else {
            middleData["ticketRefId"] = "00000000-0000-0000-0000-000000000000"
        }
        
        if let amountDue = item["amountPaid"] as? Float {
            middleData["amountDue"] = amountDue
        } else {
            middleData["amountDue"] = 0.0
        }
        
        data = AlamofireRequestAndResponse.sharedInstance.createSmartDataWithParams(middleData)
        
        self.progressBarDisplayer("Loading...".localized(), true)
        //        print(self.appDelegate.JSONStringify(data))
        
        AlamofireRequestAndResponse.sharedInstance.ticketRefundApi(data, success: { (res: [String: Any]!) -> Void in
            
            self.messageFrame.removeFromSuperview()
            if let resData: [String: Any] = res["data"] as? [String: Any] {
                self.createRefundDlg(refundRes: resData)
                _ = self.appDelegate.deleteOneTicketErrorItem(data: item)
            }
            
            self.getAllTicketErrorList()
            
            self.tableView.reloadData()
            
        },
           failure: { (error: Error!) -> Void in
            let alert = UIAlertController(title: "Error".localized(), message: "Oops! Our services are not responding, \n try back later.".localized(), preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default) {
                UIAlertAction in
                
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            self.messageFrame.removeFromSuperview()
        })
    }
    
    // MARK: additional view creating
    
    func createRefundDlg(refundRes : [String : Any]) {
        // Create custom Appearance Configuration
        
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        
        // Initialize SCLAlertView using custom Appearance
        self.refundDLG = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 290))
        subview.backgroundColor = UIColor.white
        subview.layer.borderColor = UIColor.black.cgColor
        subview.layer.borderWidth = 1.0
        let x = (subview.frame.width - 210) / 2
        
        // make label font color based the background color
        let lblFontColor : UIColor = UIColor.contrastColor(color: subview.backgroundColor!)
        
        // Add code number labeel
        let lblCode = UILabel(frame: CGRect(x: x,y: 5,width: 210,height: 35))
        lblCode.layer.borderWidth = 0.0
        lblCode.numberOfLines = 1
        lblCode.text = "Refund ID".localized()
        lblCode.font = Style.Font.boldFontWithSize(size: 34)
        lblCode.textColor = lblFontColor
        lblCode.textAlignment = NSTextAlignment.center
        subview.addSubview(lblCode)
        
        // Add qrcode image
        let qrcodeImg = UIImageView(frame: CGRect(x: x + 15, y: lblCode.frame.maxY + 5, width: 180,height: 180))
        let dataDecoded:NSData = NSData(base64Encoded: refundRes["qrCodeBase64"] as! String, options: NSData.Base64DecodingOptions(rawValue: 0))!
        qrcodeImg.image = UIImage(data: dataDecoded as Data)
        subview.addSubview(qrcodeImg)
        
        // Add instruction labeel
        let lblInstruction = UILabel(frame: CGRect(x: x + 15,y: qrcodeImg.frame.maxY + 5,width: 180,height: 45))
        lblInstruction.layer.borderWidth = 0.0
        lblInstruction.numberOfLines = 0
        lblInstruction.text = "OK, Show this code to your cashier".localized()
        lblInstruction.font = UIFont.systemFont(ofSize: 14.0)
        lblInstruction.textColor = lblFontColor
        lblInstruction.textAlignment = NSTextAlignment.left
        subview.addSubview(lblInstruction)
        
        // Add the subview to the alert's UI property
        self.refundDLG?.customSubview = subview
        _ = self.refundDLG?.addButton("OK".localized()) {
            
        }
        
        _ = self.refundDLG?.showSuccess("", subTitle: "")
        
    }
    
    
    // MARK: additional view section
    
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
        
        let label = UILabel(frame: CGRect(x: 30, y: 30, width: UIScreen.main.bounds.maxX - 30,height: UIScreen.main.bounds.maxY - 30))
        label.textAlignment = .left
        label.layer.borderWidth = 0.0
        label.alpha = 0.0
        label.font = UIFont.systemFont(ofSize: 56.0)
        label.numberOfLines = 0
        label.textColor = UIColor.white
        label.text = "Ticket Refund View Help Overlay".localized()
        
        UIView.animate(withDuration: 1.5, animations: {
            label.alpha = 1.0
        })
        transprentView.addSubview(label)
        
        self.view.addSubview(transprentView)
    }
    
    @objc func removeOverlayFromSuperView() {
        config.writeValue(true as AnyObject!, forKey: "refundTicketViewHelpOverlayShown", toStore: "settings")
        
        UIView.animate(withDuration: 1, animations: { self.transprentView.alpha = 0.0 }, completion: { Bool in
            self.transprentView.removeFromSuperview()
        })
    }


}
