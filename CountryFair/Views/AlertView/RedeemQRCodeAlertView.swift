//
//  RedeemQRCodeAlertView.swift
//  CountryFair
//
//  Created by Micky on 8/16/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SCLAlertView
import Kingfisher
import QRCode

class RedeemQRCodeAlertView: SCLAlertView {

    var giftCard: [String: Any]!
    var visualCode: String!
    var qrCode: String!
    weak var delegate: RedeemAmountAlertViewDelegate?
    
    required init(giftCard : [String : Any]!, visualCode: String!, qrCode: String!) {
        self.giftCard = giftCard
        self.visualCode = visualCode
        self.qrCode = qrCode
        
        super.init(appearance: SCLAlertView.SCLAppearance(
            showCloseButton: false,
            showCircularIcon: true
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
        let contentView = UIView(frame: CGRect(x: 0,y: 0, width: 216, height: 350))
        
        let logoImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100,height: 60))
        logoImageView.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        logoImageView.contentMode = UIViewContentMode.scaleAspectFit
        if let giftItem = giftCard["giftItemObj"] as? [String: Any], let logoUrlString = giftItem["merchandiseImageUrl"] as? String {
            logoImageView.sd_setImage(with: URL(string: logoUrlString.replacingOccurrences(of: "https://demolngcdn.blob.core.windows.net", with: "https://dev2lngmstrasia.blob.core.windows.net")))
        }
        contentView.addSubview(logoImageView)
        
        let balanceLabel = UILabel(frame: CGRect(x: 80, y: 0, width: 136, height: 50))
        balanceLabel.textAlignment = .right
        balanceLabel.baselineAdjustment = .alignCenters
        balanceLabel.font = Style.Font.boldFontWithSize(size: 26)
        balanceLabel.text = "$200.00"
        contentView.addSubview(balanceLabel)
        
        let qrCodeView = UIView(frame: CGRect(x: 0, y: logoImageView.frame.origin.y + logoImageView.frame.size.height + 10, width: contentView.frame.size.width, height: contentView.frame.size.height - logoImageView.frame.size.height - 10))
        qrCodeView.backgroundColor = UIColor(hexString: qrCode)
        qrCodeView.layer.borderColor = UIColor.black.cgColor
        qrCodeView.layer.borderWidth = 1.0
        contentView.addSubview(qrCodeView)
        
        let codeLabel = UILabel(frame: CGRect(x: 0,y: 5,width: 210,height: 35))
        codeLabel.text = visualCode
        codeLabel.font = Style.Font.boldFontWithSize(size: 34)
        codeLabel.textColor = UIColor.contrastColor(color: qrCodeView.backgroundColor!)
        codeLabel.textAlignment = NSTextAlignment.center
        qrCodeView.addSubview(codeLabel)
        
        let qrCodeImageView = UIImageView(frame: CGRect(x: 15, y: codeLabel.frame.maxY + 5, width: 180, height: 180))
        qrCodeImageView.image = QRCode(qrCode)?.image
        qrCodeView.addSubview(qrCodeImageView)
        
        let instructionLabel = UILabel(frame: CGRect(x: 15,y: qrCodeImageView.frame.maxY + 5, width: 180, height: 45))
        instructionLabel.numberOfLines = 0
        instructionLabel.text = "OK, Show this code to your cashier"
        instructionLabel.font = UIFont.systemFont(ofSize: 14.0)
        instructionLabel.textColor = UIColor.contrastColor(color: qrCodeView.backgroundColor!)
        qrCodeView.addSubview(instructionLabel)
        
        customSubview = contentView
        _ = addButton("Cancel", backgroundColor: Style.Colors.darkLimeGreenColor, textColor: UIColor.white) {
            self.hideView()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
