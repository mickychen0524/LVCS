//
//  SettingViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/26/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import KMPlaceholderTextView

class SettingViewController: UIViewController {
    
    var pinPwdSha256Data: Data? = nil

    @IBOutlet weak var simulateLicenseLabel: UILabel!
    @IBOutlet var simulateLicenseTextView: KMPlaceholderTextView!
    @IBOutlet weak var simulateSwitch: UISwitch!
    
    @IBOutlet weak var pinPwdSwitch: UISwitch!
    @IBOutlet weak var pinPwdEditText: PaddingTextField!
    @IBOutlet weak var pinPwdConfirmEditText: PaddingTextField!
    
    @IBOutlet weak var showBotSwitch: UISwitch!
    
    @IBOutlet var showPushButton: UIButton!
    
    @IBOutlet weak var pushTokenLabel: UILabel!
    @IBOutlet weak var playerLicenseCodeLabel: UILabel!
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var osLabel: UILabel!
    
    @IBOutlet weak var simulateTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pinPwdEditTextHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pinPwdConfirmEditTextHeightConstraint: NSLayoutConstraint!
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinPwdConfirmEditText.delegate = self
        pinPwdEditText.delegate = self
        
        simulateSwitch.setOn(config.getValue("isSystemGenerated", fromStore: "settings") as! Bool, animated: true)
        simulateSwitchValueChanged(simulateSwitch)
        pinPwdSwitch.setOn(config.getValue("enablePinPwd", fromStore: "settings") as! Bool, animated: true)
        pinPwdSwitchValueChanged(pinPwdSwitch)
        showBotSwitch.setOn(config.getValue("showBot", fromStore: "settings") as! Bool, animated: true)
        showBotSwitchValueChanged(showBotSwitch)
        
        if let deviceToken = UserDefaults.standard.object(forKey: "deviceTokenForPush") as? String {
            pushTokenLabel.text = deviceToken
        }
        let tgrPush = UITapGestureRecognizer(target: self, action: #selector(self.pushTokenLabelTapped))
        tgrPush.numberOfTapsRequired = 1
        pushTokenLabel.addGestureRecognizer(tgrPush)
        
        playTokenUpdated()
        
        let tgrPlayerLicense = UITapGestureRecognizer(target: self, action: #selector(self.playerLicenseCodeLabelTapped))
        tgrPlayerLicense.numberOfTapsRequired = 1
        playerLicenseCodeLabel.isUserInteractionEnabled = true
        playerLicenseCodeLabel.addGestureRecognizer(tgrPlayerLicense)
        
        self.osLabel.text = UIDevice.current.systemVersion
        
        updatePinPwd()
        
        NotificationCenter.default.addObserver(self, selector: #selector(playTokenUpdated), name: NSNotification.Name(rawValue: "PlayTokenUpdatedNotification"), object: nil)
    }
    
    @objc func playTokenUpdated() {
        let isDev = config.getValue("devEndpoint", fromStore: "settings") as! Bool
        if isDev == true, let playerLicenseCode =  config.getValue("devPlayToken", fromStore: "settings") as? String {
            playerLicenseCodeLabel.text = playerLicenseCode
        } else {
            playerLicenseCodeLabel.text = config.getValue("playToken", fromStore: "settings") as? String
        }
    }
    
    func updatePinPwd() {
        guard let pinPwd = pinPwdEditText.text, let pinPwdConfirm = pinPwdConfirmEditText.text else { return }
        updatePinPwdSha256Data()

        if pinPwd.length > 0 && pinPwd == pinPwdConfirm {
            pinPwdEditText.backgroundColor = UIColor.lightGray
            pinPwdConfirmEditText.backgroundColor = UIColor.lightGray
        } else {
            pinPwdEditText.backgroundColor = UIColor.white
            pinPwdConfirmEditText.backgroundColor = UIColor.white
        }
    }
    
    fileprivate func updatePinPwdSha256Data() {
        pinPwdSha256Data = nil
        
        guard let pinText = pinPwdEditText.text, let confirmText = pinPwdConfirmEditText.text else { return }
        
        if pinText.length > 0, pinText == confirmText {
            guard let pinPwdTextData = pinText.data(using: .utf8) else { return }
            pinPwdSha256Data = pinPwdTextData.toSha256()
        }
        
        defer { pinPwdSha256Data = nil }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func simulateSwitchValueChanged(_ sender: Any) {
        self.config.writeValue(simulateSwitch.isOn as AnyObject!, forKey: "isSystemGenerated", toStore: "settings")
        simulateTextViewHeightConstraint.constant = simulateSwitch.isOn ? 100 : 0
    }
    
    @IBAction func pinPwdSwitchValueChanged(_ sender: UISwitch) {
        self.config.writeValue(pinPwdSwitch.isOn as AnyObject!, forKey: "enablePinPwd", toStore: "settings")
        pinPwdEditTextHeightConstraint.constant = pinPwdSwitch.isOn ? 40 : 0
        pinPwdConfirmEditTextHeightConstraint.constant = pinPwdSwitch.isOn ? 40 : 0
        
    }
    
    @IBAction func showBotSwitchValueChanged(_ sender: Any) {
        self.config.writeValue(showBotSwitch.isOn as AnyObject!, forKey: "showBot", toStore: "settings")
        if let snapContainerViewController = parent as? SnapContainerViewController {
            snapContainerViewController.addOrRemoveChatViewController(showBotSwitch.isOn)
        }
        
    }

    @IBAction func showPushDetatilAction(_ sender: Any) {
        if let pushDetailViewController = storyboard?.instantiateViewController(withIdentifier: "PushDetailViewController") as? PushDetailViewController {
            self.present(pushDetailViewController, animated: true, completion: nil)
        }
    }
    
    @objc func pushTokenLabelTapped(sender:UITapGestureRecognizer) {
        UIPasteboard.general.string = pushTokenLabel.text
        view.makeToast("push handle code copied to the clipboard")
    }
    @objc func playerLicenseCodeLabelTapped(sender:UITapGestureRecognizer) {
        UIPasteboard.general.string = self.playerLicenseCodeLabel.text
        self.view.makeToast("player license code copied to the clipboard")
    }
    
    @IBAction func pinPwdChanged(_ sender: Any) {
        updatePinPwd()
    }
    
    @IBAction func pinPwdConfirmChanged(_ sender: Any) {
        updatePinPwd()
    }
}

extension SettingViewController: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
