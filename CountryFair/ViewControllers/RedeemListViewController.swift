//
//  RedeemListViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/13/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class RedeemListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sgcCouponControl: UISegmentedControl!
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    
    var redeemCardArr : NSArray!
    var coouponesArr : NSArray!
    
    lazy var refreshControl: UIRefreshControl! = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        redeemCardArr = NSArray()
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        refreshControl.addTarget(self, action: #selector(getAllRedeemList), for: .valueChanged)
        self.tableView.refreshControl = refreshControl
        self.sgcCouponControl.selectedSegmentIndex = 1
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(getAllRedeemList),
                                               name: NSNotification.Name(rawValue: "reedemListUpdate"),
                                               object: nil)
        getAllRedeemList()
        // Do any additional setup after loading the view.
    }
    
    // get all gift(ticket) list
    @objc func getAllRedeemList() {
        refreshControl.endRefreshing()
        sgcAction(sgcCouponControl)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sgcAction(_ sender: Any) {
        switch sgcCouponControl.selectedSegmentIndex {
        case 0:
            self.redeemCardArr = self.appDelegate.getCouponJSONDataFromLocal()
            self.tableView.reloadData()
        case 1:
            self.redeemCardArr = self.appDelegate.getRedeemCardJSONDataFromLocal()
            self.tableView.reloadData()
        default:
            break;
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
        
        return self.redeemCardArr.count
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row > -1 {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc : GiftCardDetailViewController = mainStoryboard.instantiateViewController(withIdentifier: "giftCardDetailViewController") as! GiftCardDetailViewController
            let sampleData: [String : Any] = self.redeemCardArr[indexPath.row] as! [String : Any]
            vc.previewItem = sampleData
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            guard let fileName : String = sampleData["fileName"] as? String else {
                return
            }
            let filePath = String.init(format: "%@/%@", documentPath, fileName)
            
            let sFileExists = FileManager.default.fileExists(atPath: filePath)
            if sFileExists == true {
                self.present(vc, animated: true, completion: nil)
            } else {
                self.view.makeToast("file error")
            }
//            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :RedeemTableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "redeemTableViewCell") as? RedeemTableViewCell
        if let sampleData: [String : Any] = self.redeemCardArr[indexPath.row] as? [String : Any] {
            cell?.configWithData(item: sampleData)
        }
        
        cell?.selectionStyle = .none
        return cell!
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
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
