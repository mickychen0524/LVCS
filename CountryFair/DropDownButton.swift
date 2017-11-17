//
//  DropDownButton.swift
//  VALotteryPlay
//
//  Created by Nyamsuren Enkhbold on 10/18/16.
//  Copyright © 2016 ATM. All rights reserved.
//

import UIKit

class DropDownButton: UIButton {

    override func awakeFromNib() {
        super.awakeFromNib()
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.6494, green: 0.8155, blue: 1.0, alpha: 1.0)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        view.addConstraint(NSLayoutConstraint(
            item: view,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1,
            constant: 1
            )
        )
        
        addConstraint(NSLayoutConstraint(
            item: view,
            attribute: .left,
            relatedBy: .equal,
            toItem: self,
            attribute: .left,
            multiplier: 1,
            constant: 0
            )
        )
        
        addConstraint(NSLayoutConstraint(
            item: view,
            attribute: .right,
            relatedBy: .equal,
            toItem: self,
            attribute: .right,
            multiplier: 1,
            constant: 0
            )
        )
        
        addConstraint(NSLayoutConstraint(
            item: view,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1,
            constant: 0
            )
        )
        setImage(UIImage(named: "dropdown_triangle"), for: .normal)
        
        sizeToFit()
        
        titleEdgeInsets = UIEdgeInsets(top: 0, left: -imageRect(forContentRect: bounds).width - 17.0, bottom: 0, right: 0)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: -2, right: 0)
    }

}
