//
//  CardsTableViewCell.swift
//  CountryFair
//
//  Created by MyMac on 7/5/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class CardsTableViewCell: UITableViewCell {

    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var cardName: UILabel!
    @IBOutlet weak var cardDescription: UILabel!
    
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
        
        self.cardName.text = item["merchantName"] as? String
        self.cardDescription.text = item["merchantTerms"] as? String
        
        let orgUrlStr = item["merchandiseImageUrl"] as! String
        let urlString = orgUrlStr.replacingOccurrences(of: "https://demolngcdn.blob.core.windows.net", with: "https://dev2lngmstrasia.blob.core.windows.net")
        let logoUrl: URL = URL(string: urlString)!
        
        DispatchQueue.global().async  {
            self.cardImageView.sd_setImage(with: logoUrl)
        }
        
    }

}
