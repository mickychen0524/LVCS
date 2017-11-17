//
//  GiftCardsListViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/20/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class GiftCardsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var tableView: UITableView!
    
    var giftCardArr : NSArray!
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        giftCardArr = NSArray()
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        getAllCardsList()
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
        
        return self.giftCardArr.count
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row > -1 {
            
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell :GiftCardsListTableViewCell? = self.tableView.dequeueReusableCell(withIdentifier: "giftCardTableViewCell") as? GiftCardsListTableViewCell
        
        if let sampleData: [String : Any] = self.giftCardArr[indexPath.row] as? [String : Any] {
            cell?.configWithData(item: sampleData)
        }
        cell?.selfViewController = self
        cell?.selectionStyle = .none
        cell?.delegate = self
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
    
    // MARK: alamofire api section
    func getAllCardsList() {
        var fullData = [String: Any]()
        let middleData = [String: Any]()
        
        AlamofireRequestAndResponse.sharedInstance.addCoordinateToParams(&fullData)
        fullData["data"] = middleData as Any?
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading..."
        AlamofireRequestAndResponse.sharedInstance.getAllMerchangiesFromServer(fullData, success: { (res: [String: Any]) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            let resData: [String : Any] = res["data"] as! [String : Any]
            self.giftCardArr = resData["merchandise"] as! NSArray
            self.tableView.reloadData()
            
        },
           failure: { (error: Error!) -> Void in
//            let alert = UIAlertController(title: "Error", message: "Gift cards getting error", preferredStyle: UIAlertControllerStyle.alert)
//            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
//                UIAlertAction in
//                
//            }
//            alert.addAction(okAction)
//            self.present(alert, animated: true, completion: nil)
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        })
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension GiftCardsListViewController: GiftCardsTableViewCellDelegate {
    func didGiftCardImageClicked(_ giftCardImageUrl: String?, terms: String?) {
        if let giftCardTermsViewController = storyboard?.instantiateViewController(withIdentifier: "GiftCardTermsViewController") as? GiftCardTermsViewController {
            giftCardTermsViewController.giftCardImageUrl = giftCardImageUrl
            giftCardTermsViewController.terms = terms
            present(giftCardTermsViewController, animated: true, completion: nil)
        }
    }
}
