//
//  MyCustomCell.swift
//  CountryFair
//
//  Created by MyMac on 6/29/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class MyCustomCell: JSQMessagesCollectionViewCell {
    var textLabel: UILabel
    
    override init(frame: CGRect) {
        
        self.textLabel = UILabel(frame:  CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height/3))
        super.init(frame: frame)
        
        self.textLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        self.textLabel.textAlignment = .center
        contentView.addSubview(self.textLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
