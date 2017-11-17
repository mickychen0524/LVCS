//
//  AlamofireRequestAndResponse.swift
//  VALotteryPlay
//
//  Created by Nyamsuren Enkhbold on 10/30/16.
//  Copyright © 2016 ATM. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation
import SwiftyJSON

class AlamofireRequestAndResponse: NSObject {
    
    
    var SERVER_URL = ""
    var BOT_SERVER_URL = ""
    var specialId: Int!
    var shouldRestart = false
    var networkStatus = "Unknown"
    var token: String = ""
    var botToken: String = ""
    var playToken : String = ""
    var brandLicenseCode : String = ""
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var gameRefId: String?
    
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
    
    class var sharedInstance: AlamofireRequestAndResponse {
        struct Static {
            static let instance: AlamofireRequestAndResponse = AlamofireRequestAndResponse()
        }
        return Static.instance
    }
    
    
    override init() {
        super.init()
        self.getToken()
        
        
        reachabilityManager?.listener = { status in
            switch status {
            case .unknown:          self.networkStatus = "Unknown"
            case .notReachable:     self.networkStatus = "Not Connected"
            case .reachable(.wwan): self.networkStatus = "WWAN"
            case .reachable(.ethernetOrWiFi): self.networkStatus = "WiFi"
            }
        }
        reachabilityManager?.startListening()
    }
    fileprivate func getToken() {
        if let plist = Plist(name: "settings") {
            let dict = plist.getMutablePlistFile()!
            if (dict.count != 0){
                if let devEndpointFlg = dict["devEndpoint"] as? Bool
                {
                    if devEndpointFlg {
                        if let token = dict["devToken"] as? String,
                            let playToken = dict["devPlayToken"] as? String,
                            let botToken = dict["botApiToken"] as? String,
                            let botServerBaseUrl = dict["botEndPoint"] as? String,
                            let brandRefIdLocal = dict["devBrandLicenseCode"] as? String,
                            let serverBaseURL = dict["devServerBaseUrl"] as? String
                        {
                            self.botToken = botToken
                            self.token = token
                            self.playToken = playToken
                            self.SERVER_URL = serverBaseURL
                            self.brandLicenseCode = brandRefIdLocal
                            self.BOT_SERVER_URL = botServerBaseUrl
                        }
                    } else {
                        if let token = dict["token"] as? String,
                            let playToken = dict["playToken"] as? String,
                            let botToken = dict["botApiToken"] as? String,
                            let botServerBaseUrl = dict["botEndPoint"] as? String,
                            let brandRefIdLocal = dict["BrandLicenseCode"] as? String,
                            let serverBaseURL = dict["serverBaseURL"] as? String
                        {
                            self.botToken = botToken
                            self.token = token
                            self.playToken = playToken
                            self.SERVER_URL = serverBaseURL
                            self.brandLicenseCode = brandRefIdLocal
                            self.BOT_SERVER_URL = botServerBaseUrl
                        }
                    }
                }
            }
        } else {
            print("Unable to get Plist")
        }
    }
    
    // ********************************* //
    // register bot api to the server
    // ********************************* //
    
    func registerBotApiToTheServer(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = BOT_SERVER_URL + "/v3/directline/conversations"
        let headers: HTTPHeaders = [
            "Authorization": self.botToken
        ]
        
        Alamofire.request(url, method: .post, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // register api
    // ********************************* //
    
    func registerWithUserImage(_ params: NSDictionary, success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v3/player/registration"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params as? Parameters, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if RegistrationManager.shared.tryRegistrationAgain {
                    RegistrationManager.shared.countOfAttempt += 1
                    self.registerWithUserImage(params, success: { response in
                    }, failure: { failure in })
                } else {
                    RegistrationManager.shared.countOfAttempt = 0
                    let retryAlert = UIAlertController(title: "Error", message: "Oops! It's not you, it's me! I can't call home right now. I've tried several times. Try back in a bit?", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Try again", style: .default) { (action) in
                        retryAlert.dismiss(animated: true, completion: nil)
                        self.registerWithUserImage(params, success: { response in
                        }, failure: { failure in })
                        
                    }
                    retryAlert.addAction(okAction)
                    guard let rootController = UIApplication.shared.keyWindow?.rootViewController else {
                        return
                    }
                    rootController.show(retryAlert, sender: rootController)
                    
                    
                }
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
            
        }
        
    }
    
    // ********************************* //
    // send message to the bot
    // ********************************* //
    
    func sendMessageToTheBot(_ params: [String : Any], botId : String, botToken : String, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = BOT_SERVER_URL + "/v3/directline/conversations/" + botId + "/activities"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer " + botToken,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
        
    }
    
    // ********************************* //
    // get hockey app sdk id from server
    // ********************************* //
    
    func getHockeyAppID(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/utility/app/config"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    var organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    
                    var resData: [String : Any] = organisationInfo["data"] as! [String : Any]
                    let images = self.appDelegate.JSONParseArray(resData["incentivePlaySponsorAchievementUrls"] as! String)
                    resData["incentivePlaySponsorAchievementUrls"] = images["uriList"]
                    organisationInfo["data"] = resData
                    
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // get messages from server
    // ********************************* //
    
    func getMessageFromBot(_ params: [String : Any], botId : String, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = BOT_SERVER_URL + "/api/conversations/" + botId + "/messages"
        let headers: HTTPHeaders = [
            "Authorization": self.botToken,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
    }
    
    // ************************************** //
    // get draw list about the game ref id
    // ************************************** //
    
    func getDrawListForGame(_ gameRefId: String, success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v3/draws/bygame/" + gameRefId + "/display"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
            
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // get retailer lists
    // ********************************* //
    
    func getRetailersWithLocation(_ params: NSDictionary, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/retailers/display/bylocation"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params as? Parameters, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
    }
    
    // ********************************* //
    // selfie update api
    // ********************************* //
    
    func updateWithUserImage(_ params: NSDictionary, success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v3/player/registration/update"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params as? Parameters, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
            
        }
        
    }
    
    // ********************************* //
    // register push notification
    // ********************************* //
    
    func registerPushNotification(_ params: NSDictionary, success: @escaping () -> Void, failure: @escaping () -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v2/notification/player/register"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .put, parameters: params as? Parameters, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseJSON { response in
            switch response.result {
            case .success:
                success()
            case .failure(let error):
                print(error)
                failure()
            }
            
        }
        
    }
    
    // ********************************* //
    // proximity upload api
    // ********************************* //
    
    func getProximityUrlData(_ params: NSDictionary, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {

        self.getToken()
        let url = SERVER_URL + "/api/v1/shopping/proximity/upload/url"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // proximity upload using blob api
    // ********************************* //
    
    func proximityUploadWithBLEBlobData(_ toStorage: String, data: Data, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Content-Type": "gzip",
            "x-ms-blob-type": "BlockBlob"
        ]
        
        Alamofire.upload(data, to: toStorage, method: .put, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // checkout with shopping cart list
    // ********************************* //
    
    func checkoutWithShoppingCart(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v3/shopping/checkout"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Accept": "application/json"

        ]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
        }
        
    }
    
    // ************************************** //
    // get status of checkout with get method
    // ************************************** //
    
    func getStatusWithCheckoutSessionGetMethod(_ sessionId: String, lisenceCode : String,  success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
//        let url = SERVER_URL + "/api/v2/shopping/checkout/" + sessionId + "/status/tickets"
        self.getToken()
        let url = SERVER_URL + "/api/v3/shopping/checkout/status/tickets"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Lazlo-ActionLicenseCode": lisenceCode,
            "Accept": "application/json"
            
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // cancel the checkout in running
    // ********************************* //
    
    func cancelCheckoutWithSession(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v2/shopping/checkout/cancel"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"

        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    
    
    // ********************************* //
    // download social image from server
    // ********************************* //
    
    func downloadSocialPhoto(_ params: NSDictionary, success: @escaping (UIImage) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let playerLicenseCode : String = params["playerLicenseCode"] as! String
        let coreRefID : String = params["correlationRefId"] as! String
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": playerLicenseCode,
            "Lazlo-CorrelationRefId" : coreRefID
        ]
        
        let url = SERVER_URL + "/api/player/social/connect/image"
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("social.png")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        Alamofire.download(url, method: .get, parameters: nil, headers: headers, to: destination).validate(statusCode: 200..<300).responseData { response in
            
            switch response.result {
            case .success:
                if let data = response.result.value {
                    let image = UIImage(data: data)
                    success(image!)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }

        }
    }
    
    // ********************************* //
    // get all game list
    // ********************************* //
    
    func getAllGameList(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v2/games/display"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // get all brand list
    // ********************************* //
    
    func getAllBrandList(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v2/brands/display"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // get all channelgroup list
    // ********************************* //
    
    func getAllChannelgroupList(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/channelgroups/display"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // get all brands abd channelgroup list
    // ********************************* //
    
    func getAllBrandsAndChannelgroupList(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/brands/channelgroup/display"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // checkout ticket receive api
    // ********************************* //
    
    func ticketReceivedCall(_ params: [String: Any], success: @escaping (NSArray!) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/shopping/checkout/ticket/received"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseForSimpleArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // ticket refund api
    // ********************************* //
    
    func ticketRefundApi(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/shopping/ticket/refund/initiate"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // social connect api
    // ********************************* //
    
    func socialConnectApi(_ params: [String: Any], success: @escaping ([String: Any]!) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/player/social/connect"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // ticket validate check api
    // ********************************* //
    
    func ticketValidateApi(_ params: [String: Any], success: @escaping ([String: Any]!) -> Void, failure: @escaping (_ error: NSError?, _ statusCode: Int?) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/validation/validate"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!, response.response?.statusCode)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // merchandies getting api for claim
    // ********************************* //
    
    func getAllMerchangiesFromServer(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/claims/exchange/merchandise"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // get terms string on ticket claim part
    // ********************************* //
    
    func getTermsStringOnClaim(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/claims/exchange/terms"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // ticket claim complete api
    // ********************************* //
    
    func ticketClaimComplete(_ params: [String: Any], success: @escaping ([String: Any]!) -> Void, failure: @escaping ([String: Any]!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/claim/exchange/low"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
            }
        }
    }
    
    // MARK : New apis for the gift cards
    // ************************************** //
    // get status of gift cards with get method
    // ************************************** //
    
    func getStatusWithCheckoutSessionGetMethodForGift(_ sessionId: String, lisenceCode : String,  success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {

        self.getToken()
        let url = SERVER_URL + "/api/v1/shopping/checkout/status/giftcards"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Lazlo-ActionLicenseCode": lisenceCode,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // checkout gift cards receive api
    // ********************************* //
    
    func giftCardReceivedCall(_ params: [String: Any], success: @escaping (NSArray!) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/shopping/checkout/giftcard/received"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseForSimpleArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ************************************** //
    // get status of coupon with get method
    // ************************************** //
    
    func getStatusWithCheckoutSessionGetMethodForCoupons(_ sessionId: String, lisenceCode : String,  success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/shopping/checkout/status/coupons"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Lazlo-ActionLicenseCode": lisenceCode,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // checkout coupon receive api
    // ********************************* //
    
    func couponsReceivedCall(_ params: [String: Any], success: @escaping (NSArray!) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/shopping/checkout/coupon/received"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseForSimpleArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************************************* //
    // global checkout api for ticket, gift card and coupons
    // ********************************************************* //
    
    func getStatusWithCheckoutSessionGetMethodForGlobal(_ sessionId: String, lisenceCode : String, coreRefID : String, success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/shopping/checkout/status"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Lazlo-CorrelationRefId" : coreRefID,
            "Lazlo-ActionLicenseCode": lisenceCode,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // redeem amount api
    // ********************************* //
    
    func applyRedeemAmount(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/claim/giftcard/initiate"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // redeem coupon amount api
    // ********************************* //
    
    func applyRedeemCoupon(_ params: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/claim/coupon/initiate"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ************************************** //
    // get receipt uploading url from server
    // ************************************** //
    
    func getReceiptUploadUrl(_ data: [String: Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/loyalty/purchase/verification/upload/url"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
        }
    }
    // ************************************** //
    // upload receiptRefId
    // ************************************** //
    
    func putReceiptOCRBody(_ receiptId: String, ocrRaw: String, correlationRefId: String, receipt:[String:Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = SERVER_URL + "/api/v1/loyalty/purchase/verification"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Lazlo-CorrelationRefId": correlationRefId,
            "Accept": "application/json"
        ]

        let receiptDict = NSMutableDictionary(dictionary:receipt)
        receiptDict["receiptRefId"] = receiptId
        receiptDict["ocrRaw"] = ocrRaw

        print(receiptDict)
        
        var params = [String:Any]()
        params["data"] = receiptDict
        params["correlationRefId"] = correlationRefId
        
        addCoordinateToParams(&params)
        
        print("sending request to url", url)
        
        print("Params JSON Data", JSON(params))
        
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    print ("JSON Response Data", JSON(data))
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
        }
    }

    
    // ********************************* //
    // receipt image uploading api
    // ********************************* //
    
    func uploadReceiptImage(_ toStorage: String, data: Data, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Content-Type": "image/png",
            "Accept": "application/json",
            "x-ms-blob-type": "BlockBlob",
            "x-ms-blob-content-type" : "image/png"
//            "x-ms-blob-content-type" : "application/octet-stream"
        ]
        
        Alamofire.upload(data, to: toStorage, method: .put, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    print ("Upload receipt image headers", JSON(headers))
//                    print ("", String(data:data, encoding:.ascii))
//                    print ("", String(data:data, encoding:.utf8))
                    let organisationInfo = self.appDelegate.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // store locator api
    // ********************************* //
    func loadStores(_ latitude: Double!, longitude: Double!, completionHandler: @escaping (_ stores: [Store]?, _ error: Error?) -> Void) {
        guard let latitude = latitude, let longitude = longitude else { return }
        
        self.getToken()
        let url = SERVER_URL + "/api/v2/retailers/display/bylocation/F6E45C9B-C201-47A7-B5F1-55A5DB7EA797/\(latitude)/\(longitude)"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Content-Type": "application/json"
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200 ..< 300).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                var stores: Array<Store> = Array()
                for (_, subJson) in json["data"] {
                    let store = Store(subJson)
                    stores.append(store!)
                }
                completionHandler(stores, nil)
                break;
            case .failure(let error):
                completionHandler(nil, error)
                break;
            }
        }
    }
    
    // ********************************* //
    // star api
    // ********************************* //
    func loadStars(_ completionHandler: @escaping (_ stores: [Star]?, _ error: Error?) -> Void) {
        self.getToken()
        
        let url = SERVER_URL + "/api/v1/loyalty/rewards"
        
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Lazlo-BrandLicenseCode": self.brandLicenseCode,
            "Content-Type": "application/json"
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200 ..< 300).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                var stars: [Star] = []
                for (_, subJson) in json["data"] {
                    let star = Star(subJson)
                    stars.append(star!)
                }
                completionHandler(stars, nil)
                break;
            case .failure(let error):
                completionHandler(nil, error)
                break;
            }
        }
    }
    
    // ********************************* //
    // Send game points
    // ********************************* //
    func sendGamePoints(_ gamePoints: Int, completionHandler: @escaping () -> Void) {
        self.getToken()

        let url = SERVER_URL + "/api/v1/loyalty/incentiveplay"
        
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.token,
            "Lazlo-PlayerLicenseCode": self.playToken,
            "Accept": "application/json"
        ]
        
        var params = [String:Any]()
        params["incentivePlayLicenseCode"] = "abcde"
        params["incentiveUnits"] = gamePoints
        
        if gameRefId != nil {
            print("ref sended")
            params["correlationRefId"] = gameRefId
        }
        
        params = self.createSmartDataWithParams(params)
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200 ..< 600).responseString(completionHandler: { response in
            
            if let data = response.data, self.gameRefId == nil {
                let json = JSON(data)
                let refId = json["correlationRefId"].rawString()
                self.gameRefId = refId
            }

            print(response)
            completionHandler()
        })
    }
}


extension AlamofireRequestAndResponse {
    func createSmartDataWithParams(_ params: [String: Any]) -> [String: Any]{
        let uuid = UUID().uuidString
        var fullData = [String: Any]()
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.full
        let convertedDate = dateFormatter.string(from: currentDate)
        
        fullData["uuid"] = uuid
        fullData["correlationRefId"] = "00000000-0000-0000-0000-000000000000"
        fullData["createdOn"] = convertedDate
        
        addCoordinateToParams(&fullData)
        
        fullData["data"] = params
        
        return fullData
    }
    
    func addCoordinateToParams(_ params: inout [String: Any]) {
        params["latitude"] = self.appDelegate.myCoords?.latitude as Any?
        params["longitude"] = self.appDelegate.myCoords?.longitude as Any?
        params["uuid"] = UUID().uuidString
    }
}
