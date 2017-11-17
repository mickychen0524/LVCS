//
//  StarViewController.swift
//  CountryFair
//
//  Created by Micky on 8/19/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class StarViewController: UIViewController {

    @IBOutlet weak var historyCountLabel: UILabel!
    @IBOutlet weak var ratingTableView: UITableView!
    
    var stars: [Star]? = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ratingTableView.tableFooterView = UIView(frame: .zero)
        let count = Receipt.loadAll().count
        if count > 0 {
            historyCountLabel.text = "\(count)"
            historyCountLabel.isHidden = false
        } else {
            historyCountLabel.isHidden = true
        }
        
        loadStars()
    }
    
    func loadStars() {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud?.labelText = "Loading..."
        AlamofireRequestAndResponse.sharedInstance.loadStars { (stars, error) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.stars = stars
            if self.stars != nil {
                self.ratingTableView.reloadData()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func history(_ sender: Any) {
        if let historyViewController = storyboard?.instantiateViewController(withIdentifier: "HistoryViewController") as? HistoryViewController {
            present(historyViewController, animated: true, completion: nil)
        }
    }

}

extension StarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stars!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StarCell", for: indexPath) as! StarCell
        
        let star = stars?[indexPath.row]
        cell.skuNameLabel.text = star?.skuName
        
        if let pendingCount = star?.pendingCount {
            cell.ratingView.rating = Double(pendingCount)
        } else {
            cell.ratingView.rating = 0
        }
        let color = UIColor.randomColor() 
        cell.ratingView.settings.filledColor = color
        cell.ratingView.settings.filledBorderColor = color
        cell.ratingView.settings.emptyColor = UIColor.white
        cell.ratingView.settings.emptyBorderColor = color
        
        if let lifeTimeCount = star?.lifeTimeCount {
            cell.lifeTimeCountLabel.text = "\(lifeTimeCount)"
        } else {
            cell.lifeTimeCountLabel.text = ""
        }
        
        return cell
    }
}
