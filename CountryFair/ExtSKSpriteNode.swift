//
//  ExtSKSpriteNode.swift
//  CountryFair
//
//  Created by Mac on 10/9/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import SpriteKit
import Foundation

extension SKSpriteNode {
    
    func aspectFillToSize(fillSize: CGSize) {
        
        if texture != nil {
            self.size = texture!.size()
            
            let verticalRatio = fillSize.height / self.texture!.size().height
            let horizontalRatio = fillSize.width /  self.texture!.size().width
            
            let scaleRatio = horizontalRatio > verticalRatio ? horizontalRatio : verticalRatio
            
            self.setScale(scaleRatio)
        }
    }
    
}
