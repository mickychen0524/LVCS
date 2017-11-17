//
//  StoreCell.swift
//  CountryFair
//
//  Created by Micky on 8/19/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class StoreCell: UITableViewCell {
    
    @IBOutlet weak var retailerNameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
