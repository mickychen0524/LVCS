//
//  ExtUIBarButtonItem.swift
//  CountryFair
//
//  Created by Administrator on 10/12/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

extension CAShapeLayer {
    func drawCircleAtLocation(location: CGPoint, withRadius radius: CGFloat, andColor color: UIColor, filled: Bool) {
        fillColor = filled ? color.cgColor : UIColor.white.cgColor
        strokeColor = color.cgColor
        let origin = CGPoint(x: location.x - radius, y: location.y - radius)
        path = UIBezierPath(ovalIn: CGRect(origin: origin, size: CGSize(width: radius * 2, height: radius * 2))).cgPath
    }
    
    func drawRoundedRectAtLocation(location: CGPoint,size: CGSize, withRadius radius: CGFloat, andColor color: UIColor, filled: Bool) {
        fillColor = filled ? color.cgColor : UIColor.white.cgColor
        strokeColor = color.cgColor
        let origin = CGPoint(x: location.x - radius, y: location.y - radius)
        path = UIBezierPath(roundedRect: CGRect(origin: origin, size: size), cornerRadius: radius).cgPath
    }
}

private var handle: UInt8 = 0

class BadgeUIBarButtonItem : UIBarButtonItem {
    
    private var badgeLayer: CAShapeLayer? {
        if let b: AnyObject = objc_getAssociatedObject(self, &handle) as AnyObject? {
            return b as? CAShapeLayer
        } else {
            return nil
        }
    }
    
    var btn = UIButton()
    
    override func awakeFromNib() {
        btn.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        btn.setBackgroundImage(self.image, for: .normal)
        
    }
    
    func addBadge(number: Int, withOffset offset: CGPoint = CGPoint.zero, andColor color: UIColor = UIColor.green, andFilled filled: Bool = true, fontColor: UIColor = UIColor.red) {
        badgeLayer?.removeFromSuperlayer()
        
        // Initialize Badge
        let badge = CAShapeLayer()
        
        
        // check if the view is RTL
        var isRight = false
        if #available(iOS 9.0, *) {
            if UIView.userInterfaceLayoutDirection(
                for: btn.semanticContentAttribute) == .rightToLeft {
                
                isRight = true
                // The view is shown in right-to-left mode right now.
            }
        } else {
            // Use the previous technique
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                isRight = true
                // The view is in right-to-left mode
            }
        }
        
        // set the position of the badge based if the direction of the view
        let location = CGPoint(x: (isRight ? offset.x : btn.frame.width), y: (offset.y))
        
        // Initialiaze Badge's label
        let label = CATextLayer()
        label.string = "\(number)"
        label.alignmentMode = kCAAlignmentCenter
        label.fontSize = 11
        label.frame = CGRect(origin: CGPoint(x: location.x - 4, y: offset.y-7), size: label.preferredFrameSize())
        label.foregroundColor = filled ? fontColor.cgColor : color.cgColor
        label.backgroundColor = UIColor.clear.cgColor
        label.contentsScale = UIScreen.main.scale
        
        badge.drawRoundedRectAtLocation(location: location, size: CGSize.init(width: label.preferredFrameSize().width+8, height: 16), withRadius: 8, andColor: color, filled: filled)
        
        btn.layer.addSublayer(badge)
        
        badge.addSublayer(label)
        
        customView = btn
        
        // Save Badge as UIBarButtonItem property
        objc_setAssociatedObject(self, &handle, badge, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func updateBadge(number: Int) {
        if let text = badgeLayer?.sublayers?.filter({ $0 is CATextLayer }).first as? CATextLayer {
            text.string = "\(number)"
        }
    }
    
    func removeBadge() {
        badgeLayer?.removeFromSuperlayer()
    }
}
