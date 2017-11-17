//
//  RedeemAmountAlertView.swift
//  CountryFair
//
//  Created by Micky on 8/16/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SCLAlertView
import Kingfisher

protocol RedeemAmountAlertViewDelegate: class {
    func didRedeemButtonClicked(_ redeemAmount: Float!)
}

class RedeemAmountAlertView: SCLAlertView {
    
    var giftCard: [String: Any]!
    weak var delegate: RedeemAmountAlertViewDelegate?
    
    required init(giftCard : [String : Any]!) {
        self.giftCard = giftCard
        
        super.init(appearance: SCLAlertView.SCLAppearance(
            kTitleFont: Style.Font.fontWithSize(size: 20),
            kTextFont: Style.Font.fontWithSize(size: 14),
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false,
            showCircularIcon: true,
            shouldAutoDismiss: false
        ))
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    public func show() {
        showSuccess("Redeem".localized(), subTitle: "")
    }
    
    private func setupUI() {
        let contentView = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 210))
        
        let logoImageView = UIImageView(frame: CGRect(x: contentView.frame.size.width / 2 - 80, y: 0, width: 160,height: 100))
        logoImageView.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        logoImageView.contentMode = UIViewContentMode.scaleAspectFit
        if let giftItem = giftCard["giftItemObj"] as? [String: Any], let logoUrlString = giftItem["merchandiseImageUrl"] as? String {
            logoImageView.sd_setImage(with: URL(string: logoUrlString.replacingOccurrences(of: "https://demolngcdn.blob.core.windows.net", with: "https://dev2lngmstrasia.blob.core.windows.net")))
        }
        contentView.addSubview(logoImageView)
        
        let balanceLabel = UILabel(frame: CGRect(x: 0, y: logoImageView.frame.origin.y + logoImageView.frame.size.height + 10, width: contentView.frame.size.width, height: 40))
        balanceLabel.textAlignment = .center
        balanceLabel.font = Style.Font.boldFontWithSize(size: 16)
        balanceLabel.text = "Balance: $200.00"
        balanceLabel.textColor = UIColor.gray
        contentView.addSubview(balanceLabel)
        
        let amountTextField = UITextField(frame: CGRect(x: 10, y: balanceLabel.frame.origin.y + balanceLabel.frame.size.height + 20, width: contentView.frame.size.width - 20, height: 30))
        amountTextField.borderStyle = .line
        amountTextField.font = Style.Font.boldFontWithSize(size: 14)
        amountTextField.placeholder = "Enter amount to redeem"
        amountTextField.keyboardType = .numberPad
        amountTextField.layer.sublayerTransform = CATransform3DMakeTranslation(5, 0, 0)
        contentView.addSubview(amountTextField)
            
        customSubview = contentView
        
        let _ = addButton("Redeem") {
            guard (amountTextField.text?.length)! > 0 else { return }
            UIView.animate(withDuration: 0.5, delay: 0.1, options: .curveEaseOut, animations: {
                var viewFrame = self.view.frame
                viewFrame.origin.y -= viewFrame.size.height
                self.view.frame = viewFrame
            }, completion: { finished in
                self.hideView()
                self.delegate?.didRedeemButtonClicked(Float(amountTextField.text!))
            })
        }
        
        _ = addButton("Cancel".localized(), backgroundColor: Style.Colors.pureYellowColor, textColor: Style.Colors.darkLimeGreenColor) {
            self.hideView()

        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
