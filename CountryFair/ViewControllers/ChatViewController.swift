//
//  ChatViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/13/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import UserNotifications
import Starscream
import Kingfisher

class ChatViewController: JSQMessagesViewController, UNUserNotificationCenterDelegate, WebSocketDelegate, WebSocketPongDelegate {

    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    var allMessages : [JSQMessage]!
    var currentUser : User!
    var socket : WebSocket!
    var botRegisteredData : [String : Any]! = [String : Any]()
    var targetImg : UIImageView!
    
    var myMessageShowFlg : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.backgroundColor = Style.Colors.blackBlueColor
        
        targetImg = UIImageView(frame: CGRect(x: 0, y: 0, width: 215,height: 215))
        
        let user1 = User(id:"1", name: "me")
        
        allMessages = [JSQMessage]()
        let botRegisterState = self.config.getValue("botRegisterState", fromStore: "settings") as! Bool
        if (botRegisterState) {
            getMessagesFromServer()
        }
        
        currentUser = user1
        self.senderId = currentUser.id
        self.senderDisplayName = currentUser.name
        
        hideKeyboardWhenTappedAround()
         addViewOnTop()
        
        if (checkRegisteredState() && socket == nil) {
            self.botRegisteredData = self.appDelegate.JSONParseArray( self.config.getValue("botRegisteredData", fromStore: "settings") as! String)
            
            let socketStreamUrl = self.botRegisteredData["streamUrl"] as! String
            let streamArr : [String] = socketStreamUrl.components(separatedBy: "-&t=")
            let newSocketUrl = "\(streamArr[0])-&t=\(self.botRegisteredData["token"] as! String)"
            
            socket = WebSocket(url: URL(string: newSocketUrl)!)
            socket.delegate = self
            socket.connect()
        }

        // Do any additional setup after loading the view.
    }
    
    func addViewOnTop() {
        
        let screenSize = UIScreen.main.bounds
        let topHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: 120))
        topHeaderView.backgroundColor = UIColor.clear
        
        let leftLotteryImg = UIImageView(frame: CGRect(x: 20, y: 30, width: 80, height: 80))
        leftLotteryImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        leftLotteryImg.contentMode = UIViewContentMode.scaleAspectFit
        leftLotteryImg.image = UIImage(named: "palotterylogolight")

        topHeaderView.addSubview(leftLotteryImg)
        
        let rightBotImg = UIImageView(frame: CGRect(x: screenSize.width - 100, y: 20, width: 80, height: 80))
        rightBotImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        rightBotImg.contentMode = UIViewContentMode.scaleAspectFit
        rightBotImg.image = UIImage(named: "lotbotlogo")
        
        topHeaderView.addSubview(rightBotImg)
        view.addSubview(topHeaderView)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if (socket != nil) {
            socket.disconnect()
        }
    }
    
    // MARK: getting message stuff
    
    func checkRegisteredState() -> Bool{
        let state = self.config.getValue("botRegisterState", fromStore: "settings") as! Bool
        if !state {
            botRegister()
        }
        return state
    }
    
    func startGettingMessage() {
        
        if (checkRegisteredState()) {
            getMessagesFromServer()
        }
    }
    
    // RESTFull method
    func getMessagesFromServer() {
        
        self.botRegisteredData = self.appDelegate.JSONParseArray( self.config.getValue("botRegisteredData", fromStore: "settings") as! String)
        let botId = self.botRegisteredData["conversationId"] as! String
        
        AlamofireRequestAndResponse.sharedInstance.getMessageFromBot([String : Any](), botId: botId, success: { (res: [String: Any]) -> Void in

            let messages = res["messages"] as! NSArray
            
            if (messages.count != 0) {
                self.allMessages = [JSQMessage]()
                
                for item in messages {
                    
                    let message = item as! [String : Any]
                    
                    if (message["from"] as! String != "devlngbot") {
                        let messageJSQ = JSQMessage(senderId: "1", displayName: message["from"] as! String, text: message["text"] as! String)
                        self.allMessages.append(messageJSQ!)
                    } else {
                        let messageJSQ = JSQMessage(senderId: "2", displayName: message["from"] as! String, text: message["text"] as! String)
                        self.allMessages.append(messageJSQ!)
                    }
                    
                }

            }
            
        },
         failure: { (error: Error!) -> Void in
            self.view.makeToast("message get error")
        })
    }
    
    // MARK: JSQMessagePart
    //************************************************//
    // JSQMessageView functions
    //************************************************//
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {

        view.endEditing(true)
        if (text != "") {

            myMessageShowFlg = false
            let messageJSQ = JSQMessage(senderId: "1", displayName: "Me", text: text)
            self.allMessages.append(messageJSQ!)
            
            let regObject = self.appDelegate.JSONParseArray( self.config.getValue("botRegisteredData", fromStore: "settings") as! String)
            
            let botId = regObject["conversationId"] as! String
            let botToken = regObject["token"] as! String
            let uuid = UUID().uuidString
            
            var data = [String : Any]()
            var channelData = [String : Any]()
            var fromData = [String : Any]()
            data["type"] = "message"
            data["text"] = text
            fromData["id"] = uuid
            data["from"] = fromData

            if (config.getValue("devEndpoint", fromStore: "settings") as? Bool)! {
                channelData["brandLicenseCode"] = config.getValue("devBrandLicenseCode", fromStore: "settings") as? String
                channelData["authorityLicenseCode"] = config.getValue("devToken", fromStore: "settings") as? String
                channelData["playerLicenseCode"] = config.getValue("devPlayToken", fromStore: "settings") as? String
            } else {
                channelData["brandLicenseCode"] = config.getValue("BrandLicenseCode", fromStore: "settings") as? String
                channelData["authorityLicenseCode"] = config.getValue("token", fromStore: "settings") as? String
                channelData["playerLicenseCode"] = config.getValue("playToken", fromStore: "settings") as? String
            }
            AlamofireRequestAndResponse.sharedInstance.addCoordinateToParams(&channelData)
            data["channelData"] = channelData
            
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.labelText = "Sending..."
            AlamofireRequestAndResponse.sharedInstance.sendMessageToTheBot(data, botId: botId, botToken : botToken, success: { (res: [String: Any]) -> Void in
                
                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                
            },
             failure: { (error: Error!) -> Void in
                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                self.view.makeToast("message send error")
            })
            finishSendingMessage()
        }
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMessages.count
    }
    
    // MARK : UICollectionView delegate for JSQMessageView
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return allMessages[indexPath.row]
    }
    
//    override func collectionView(_ collectionView: UICollectionView,  cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let message = self.allMessages[indexPath.item]
//        
//        if message.senderId == self.senderId {
//            
//            let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! messageViewOutgoing
//            
//            cell.timeLabel.text = "12:12 , 12"
//            
//            return cell
//            
//        } else {
//            
//            let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! messageViewIncoming
//            
//            cell.timeLabel.text = "12:12 , 12"
//
//            return cell
//        }
//    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        let message = allMessages[indexPath.row]
        
        if currentUser.id == message.senderId {
            return bubbleFactory?.incomingMessagesBubbleImage(with: Style.Colors.darkRedColor)
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: .blue)
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let placeHolderImage = UIImage(named: "circleselfiesample")
        let botPlaceHolderImage = UIImage(named: "cofairlucylogo")
        
        let message = allMessages[indexPath.row]
    
        if currentUser.id == message.senderId {
            return JSQMessagesAvatarImage(avatarImage: nil, highlightedImage: nil, placeholderImage: placeHolderImage)
        } else {
            return JSQMessagesAvatarImage(avatarImage: nil, highlightedImage: nil, placeholderImage: botPlaceHolderImage)
        }

    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = allMessages[indexPath.row]
        let messageUserName = message.senderDisplayName
        return NSAttributedString(string: messageUserName!)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    
    // MARK : WebSocket delegates
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocket is connected")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocket is disconnected: \(String(describing: error?.localizedDescription))")
        botRegister();
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        let resData : [String : Any] = self.appDelegate.JSONParseArray(text)
        print(self.appDelegate.JSONStringify(resData))
        if let messages = resData["activities"] as? NSArray {
            
            if (messages.count != 0) {

                for item in messages {
                    
                    let message = item as! [String : Any]
                    let fromObj : [String : Any] = message["from"] as! [String : Any]
                    
                    if (fromObj["id"] as! String != "devlngbot") {
                        if myMessageShowFlg {
                            let messageJSQ = JSQMessage(senderId: "1", displayName: "Me", text: message["text"] as! String)
                            self.allMessages.append(messageJSQ!)
                            finishSendingMessage()
                        }
  
                    } else {
                        let messageJSQ = JSQMessage(senderId: "2", displayName: fromObj["name"] as! String, text: message["text"] as! String)
                        self.allMessages.append(messageJSQ!)
                        finishSendingMessage()
                        var mediaImage = JSQPhotoMediaItem(image: nil)
                        
                        if let mediaArr : NSArray = message["attachments"] as? NSArray {
                            for mItem in mediaArr {
                                let mediaItem : [String : Any] = mItem as! [String : Any]
                                if let mType : String = mediaItem["contentType"] as? String {
                                    if (mType == "image/png") {
                                        
                                        let url = mediaItem["contentUrl"] as! String
                                        self.targetImg.kf.setImage(with: URL(string:url),
                                                      placeholder: nil,
                                                      options: [.transition(ImageTransition.fade(1))],
                                                      progressBlock: { receivedSize, totalSize in
                                                        
                                        },
                                                      completionHandler: { image, error, cacheType, imageURL in
                                                        mediaImage = JSQPhotoMediaItem(image: image)
                                                        let sendMessage = JSQMessage(senderId: "2", displayName: fromObj["name"] as! String, media: mediaImage)
                                                        let strIndex : String = resData["watermark"] as! String
                                                        self.allMessages.insert(sendMessage!, at: Int(strIndex)! + 1)
                                                        self.finishSendingMessage()
                                        })

                                    }
                                }
                            }
                            
                        }
                    }
                    
                }
                
            }
        }

    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("got some data: \(data.count)")
    }
    
    func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        print("Got pong! Maybe some data: \(String(describing: data?.count))")
    }
    
    // MARK : Bot api
    
    func botRegister() {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Bot Registering..."
        AlamofireRequestAndResponse.sharedInstance.registerBotApiToTheServer([String : Any](), success: { (res: [String: Any]) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.config.writeValue(true as AnyObject, forKey: "botRegisterState", toStore: "settings")
            self.config.writeValue(self.appDelegate.JSONStringify(res) as AnyObject, forKey: "botRegisteredData", toStore: "settings")
            let socketStreamUrl = res["streamUrl"] as! String
            let streamArr : [String] = socketStreamUrl.components(separatedBy: "-&t=")
            let newSocketUrl = "\(streamArr[0])-&t=\(res["token"] as! String)"
            
            self.socket = WebSocket(url: URL(string: newSocketUrl)!)
            self.socket.delegate = self
            self.socket.connect()
            
        },
         failure: { (error: Error!) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Register failed. \n Please restart after exit.", style: AlertStyle.error)
            
        })
    }
    
}
