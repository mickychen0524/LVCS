//
//  messageViewIncoming.swift
//  CountryFair
//
//  Created by MyMac on 6/29/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class messageViewIncoming: JSQMessagesCollectionViewCellIncoming {
    
    @IBOutlet weak var timeLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
