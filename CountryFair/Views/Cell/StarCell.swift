//
//  StarCell.swift
//  CountryFair
//
//  Created by Micky on 8/19/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import Cosmos

class StarCell: UITableViewCell {
    
    @IBOutlet weak var skuNameLabel: UILabel!
    @IBOutlet weak var ratingView: CosmosView!
    @IBOutlet weak var lifeTimeCountLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
