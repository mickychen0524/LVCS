//
//  PaddingTextField.swift
//  CountryFair
//
//  Created by Administrator on 8/22/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class PaddingTextField: UITextField {

    let padding = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5);
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }

}
