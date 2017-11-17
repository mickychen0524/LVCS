//
//  TicketErrorTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class TicketErrorTableViewCell: UITableViewCell {

    @IBOutlet weak var tileImage: FLAnimatedImageView!
    @IBOutlet weak var lblError: UILabel!
    @IBOutlet weak var brandImage: UIImageView!
    @IBOutlet weak var pasteImage: UIImageView!
    var config = GTStorage.sharedGTStorage
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)!
    }
    
    // make table view cell using channel group data
    func configWithData(item: [String: Any]) {
        
        self.brandImage.autoresizingMask = [.flexibleHeight]
        self.brandImage.contentMode = UIViewContentMode.scaleAspectFit
        
        self.pasteImage.autoresizingMask = [.flexibleHeight]
        self.pasteImage.contentMode = UIViewContentMode.scaleAspectFit
        
        let data = item
        let gameData : [String : Any] = data["gameData"] as! [String : Any]
        if let tileUrl = gameData["tileUrl"] as? String,
            let animatedTileUrl = gameData["animatedTileUrl"] as? String,
            let logoUrl = gameData["gameLogoUrl"] as? String
        {
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            var filePath = String.init(format: "%@/%@", documentPath, animatedTileUrl)
            if (self.config.getValue("powerSavingState", fromStore: "settings") as! Bool) {
                if let _ = gameData["localSavingStateStatic"] as? Bool {
                    filePath = String.init(format: "%@/%@", documentPath, tileUrl)
                    self.tileImage.image = UIImage.init(contentsOfFile: filePath)
                } else {
                    self.tileImage.sd_setImage(with: URL(string: tileUrl)!)
                }
            } else {
                
                if let _ = gameData["localSavingState"] as? Bool {
                    filePath = String.init(format: "%@/%@", documentPath, animatedTileUrl)
                    self.tileImage.animatedImage = FLAnimatedImage.init(animatedGIFData: NSData(contentsOfFile:filePath) as Data!)
                } else {
                    do {
                        self.tileImage.animatedImage = try FLAnimatedImage.init(animatedGIFData: Data(contentsOf:URL(string : tileUrl)!))
                    } catch let error as NSError {
                        print(error)
                    }
                }
                
            }
            
            filePath = "\(documentPath)/\(logoUrl)"
            self.brandImage.image = UIImage.init(contentsOfFile: filePath)
        }
    }

}
