//
//  GameSponsorImages.swift
//  CountryFair
//
//  Created by Mac on 10/6/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation

typealias imageParams = [String: String]

class SponsorImage: NSObject, NSCoding {
    var url: String
    var forPoint: Int
    
    init(url: String, forPoint: Int) {
        self.url = url
        self.forPoint = forPoint
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObject(forKey: "url") as! String
        let point = aDecoder.decodeInteger(forKey: "forPoint")
        self.init(url: url, forPoint: point)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: "url")
        aCoder.encode(forPoint, forKey: "forPoint")
    }
}

struct GameSponsorImages {
    var startGameImage: SponsorImage = SponsorImage(url: "", forPoint: 1)
    var images: [SponsorImage] = []
    var countOfImage: Int = 0
    
    init() {
        let data = UserDefaults.standard.object(forKey: "incentivePlaySponsorAchievementUrls")
        let savedImages = NSKeyedUnarchiver.unarchiveObject(with: data! as! Data) as! [SponsorImage]
        for element in savedImages {
            ImageLoader.sharedLoader.imageForUrl(urlString: element.url, completionHandler: { (image, url) in })
            images.append(element)
        }
    }
    
    func imageFor(_ point: Int) -> SponsorImage? {
        return images.filter({ image -> Bool in
            return image.forPoint == point
        }).first
    }
    
    mutating func next() -> SponsorImage {
        countOfImage += 1
        if countOfImage == images.count {
            countOfImage = 0
        }
        
        return images[countOfImage]
    }
    
    static func saveImages(_ response: [AnyObject]) {
        var images: [SponsorImage] = []
        
        for obj in response {
            if let newObj = obj as? [String: String] {
                let url = newObj["Url"] ?? ""
                let inPoint = Int(newObj["incentiveUnits"] ?? "0") ?? 0
                let image = SponsorImage(url: url, forPoint: inPoint)
                images.append(image)
                ImageLoader.sharedLoader.imageForUrl(urlString: image.url, completionHandler: { (image, url) in })
            }
        }
        
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: images)
        userDefaults.set(encodedData, forKey: "incentivePlaySponsorAchievementUrls")
        userDefaults.synchronize()
    }
}
