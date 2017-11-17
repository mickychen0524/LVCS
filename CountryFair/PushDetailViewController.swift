//
//  PushDetailTableViewController.swift
//  CountryFair
//
//  Created by admin on 9/28/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class PushDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PushRecord.storedPushInfo.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return height(string: PushRecord.storedPushInfo[indexPath.row], withConstrainedWidth: self.view.frame.width*0.8, font: UIFont.systemFont(ofSize: 12))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PushDetailCell", for: indexPath) as! PushDetailTableViewCell
        cell.pushInfo.text = PushRecord.storedPushInfo[indexPath.row]
        return cell
    }

    func height(string:String, withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = string.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
}

class PushRecord {
    
    static var storedPushInfo : [String] {
        get {
            if let dataArray = UserDefaults.standard.object(forKey: "storedPushInfo") as? Data {
                if let resultArray = NSKeyedUnarchiver.unarchiveObject(with: dataArray) as? [String] {
                    return resultArray
                }
            }
            return [String]()
        }
    }
    
    static func addStoredFilter(pushInfo: String) {
        var defStoredPushInfo = self.storedPushInfo
        if defStoredPushInfo.count > 99 {
            defStoredPushInfo.removeLast()
        }
        defStoredPushInfo.insert(pushInfo, at: 0)
        let resultData = NSKeyedArchiver.archivedData(withRootObject: defStoredPushInfo)
        UserDefaults.standard.set(resultData, forKey: "storedPushInfo")
        UserDefaults.standard.synchronize()
    }
}
