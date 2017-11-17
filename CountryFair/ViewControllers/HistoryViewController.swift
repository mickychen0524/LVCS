//
//  HistoryViewController.swift
//  CountryFair
//
//  Created by Administrator on 10/21/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {
    
    @IBOutlet weak var historyTableView: UITableView!
    
    var receipts: [Receipt] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        historyTableView.tableFooterView = UIView(frame: .zero)
        
        loadHistory()
    }
    
    func loadHistory() {
        receipts = Receipt.loadAll()
        historyTableView.reloadData()
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return receipts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReceiptCell", for: indexPath) as! ReceiptCell
        let receipt = receipts[indexPath.row]
        cell.contentLabel.text = "\(receipt.occurredOn) Tx: \(receipt.receiptId)"
        
        return cell
    }
    
    
}
