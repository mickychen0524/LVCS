
//
//  AppDelegate.swift
//  CountryFair
//
//  Created by MyMac on 6/3/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import UserNotifications
import HockeySDK
import Kingfisher
import ZBarSDK
import CoreLocation
import Gzip
import EVURLCache
import GoogleMaps
import SwiftyJSON


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RPKManagerDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    
//    let tempLatitude = 42.129223
//    let tempLongitude = -80.085060
    
    var proximityKitManager : RPKManager?
    var config = GTStorage.sharedGTStorage
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var updateTimer: Timer?
    var locationManager: CLLocationManager!
    var myCoords: CLLocationCoordinate2D?
    var myAltitude : Double = 0.0
    var uploadFlag : Bool = false
    var getRetailerListFlag : Bool = false
    var beaconsFromRetailer: [BeaconItem] = []
    var selectedBeacons: [CLBeacon] = []
    var significantUUID: String? = ""
    var closestRetailerItem: [String : Any]!
    
    var giftCardDownloadFlg : Bool = false
    
    // beacon upload data for JSON type
    var beaconDistance : String = ""
    var beaconMajor : String = ""
    var beaconMinor : String = ""
    
    var retailerRefIdStr : String = ""
    var coreRelationRefId : String = "00000000-0000-0000-0000-000000000000"
    var globalStartCount : Int = 0
    var overlayPopped = false
    var locationMark : UIImageView = UIImageView(frame: CGRect(x: 155 + 5, y: 0 + 20, width: 40,height: 44))
    
    
    var mutableArr : NSMutableArray!
    var beaconArr : NSArray!
    var channelGroupGlobalArr : NSArray!
    var gameGlobalArr : NSArray!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // google map
        GMSServices.provideAPIKey(Config.Google.Maps.apiKey)
        
        // initi NSURLCache extension to 
        // cache webpages
        self.initURLCache()
        
        UserDefaults.standard.set(false, forKey: "retailerExistFlag")
        
        
        if (config.getValue("locationPermissionState", fromStore: "settings") as! Bool) {
            initLocationCoorp()
        }
        getAndSetHockeyAppID()
        
        // background task registering and playing
        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        updateTimer = Timer.scheduledTimer(timeInterval: 300, target: self,
                                           selector: #selector(startBeaconStuff), userInfo: nil, repeats: true)
        self.startBeaconStuff()
        
        registerBackgroundTask()
        
        self.mutableArr = NSMutableArray()
       
        self.channelGroupGlobalArr = NSArray()
        self.gameGlobalArr = NSArray()
        
        // check app start timing count
        if let startCount = UserDefaults.standard.integer(forKey: "wholeAppStartCount") as Int? {
            globalStartCount = startCount
            UserDefaults.standard.set(startCount + 1, forKey: "wholeAppStartCount")
        } else {
            UserDefaults.standard.set(0, forKey: "wholeAppStartCount")
        }
        
        // setting initial view controller when start the app
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        var vc = storyboard.instantiateViewController(withIdentifier: "permissionViewController")
        let cameraFlg = self.config.getValue("cameraPermissionState", fromStore: "settings") as! Bool
        let locationFlg = self.config.getValue("locationPermissionState", fromStore: "settings") as! Bool
        let photosFlg = self.config.getValue("photoPermissionState", fromStore: "settings") as! Bool
        let notificationFlg = self.config.getValue("notificationPermissionState", fromStore: "settings") as! Bool
        let microphoneFlg = self.config.getValue("microphonePermissionState", fromStore: "settings") as! Bool

        if (cameraFlg && locationFlg && notificationFlg && photosFlg && microphoneFlg) {
            vc = storyboard.instantiateViewController(withIdentifier: "snapContainerViewController")
        }
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
        // Override point for customization after application launch.
        return true
    }
    func initURLCache() {
        EVURLCache.LOGGING = false // We want to see all caching actions
        EVURLCache.MAX_FILE_SIZE = 26 // We want more than the default: 2^26 = 64MB
        EVURLCache.MAX_CACHE_SIZE = 30 // We want more than the default: 2^30 = 1GB
        EVURLCache.MAX_AGE = String(describing:Config.WebCache.expiryTime)
        EVURLCache.activate()
    
    }
    func initLocationCoorp() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = config.getValue("BLEDistanceFilter", fromStore: "settings") as! Double
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        if (UserDefaults.standard.object(forKey: "deviceTokenForPush") as? String) != nil {
            let deviceTokenStr = UserDefaults.standard.object(forKey: "deviceTokenForPush") as! String
            print("device token \(deviceTokenStr)")
        } else {
            let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
            UserDefaults.standard.set(deviceTokenString, forKey: "deviceTokenForPush")
            print("device token \(deviceTokenString)")
        }
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        print("i am not available in simulator \(error)")
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Push info \(JSON(userInfo))")
        PushRecord.addStoredFilter(pushInfo: userInfo.description)

        if let aps = userInfo["aps"] as? [String : Any] {
            if let content = aps["content-available"] as? Int, let operationType = userInfo["operationType"] as? Int {
                if content == 1 {
                    if operationType == 9 || operationType == 131072 {
                        if let payload = userInfo["payload"] as? [String:Any] {
                            if let sasUri = payload["sasUri"] as? String, let fileName = payload["fileName"] as? String {
                                _ = DownloadItemManager.sharedManager.addDownloadEntity(fileName, sasUri)
                                DownloadItemManager.sharedManager.downloadItem(fileName: fileName, progressClosure: nil, success: nil, failed: nil)
                                completionHandler(UIBackgroundFetchResult.newData)
//                                let giftSSItem = ["fileName" : payload["fileName"], "isGiftCard" : false,
//                                                  "value" : payload["value"] ?? 0, "mediaSize": payload["mediaSize"] ?? 0,
//                                                  "licenceCode": payload["licenseCode"]  ?? 0]
                                let _ = self.saveOneCouponItemToLocal(data: payload)
                            }
                        }
                    } else if operationType == 5 {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateCheckoutStatus"), object: nil)
                        completionHandler(UIBackgroundFetchResult.newData)
                    } else if operationType == 666 {
                        //FIXME: ADD SERVER POST
//                        self.getProximityUrl()
                    } else if operationType == 65536 {
                        if self.mutableArr.count > 0 && !self.uploadFlag {
                            self.getProximityUrl()
                        }
                    }
                }
            }
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }

    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        print(url.scheme ?? "nil")
        print(url.query ?? "nil")
        if ((url.scheme == "valotteryplay") && (url.query == "checkout")) {
            
        } else {
            
        }
        
        return true
    }

    // Push notification received
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        // hack to test
        for(key, value) in userInfo {
            print(key)
            print(value)
            let k =  key as? String ?? ""
            let v =  value as? String ?? ""
            if k == "operationType" {
                
                // just print for now
                print("Operation Type \(v)")
                
                // TODO: this is a temporary hack, may not work for all types of views...
                UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.view.makeToast("Operation Type \(v)")
                
                // case statement
                //switch v {
                //    case "1":
                //        print("Operation Type 1")
                //    case "2":
                //        print("Operation Type 2")
                //    default:
                //        print("Some other type")
                //}
            }

        }
        
        print("Push notification received: \(userInfo)")
    }

    // MARK: background service part
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func reinstateBackgroundTask() {
        if updateTimer != nil && (backgroundTask == UIBackgroundTaskInvalid) {
            registerBackgroundTask()
        }
    }
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    // MARK: beacon stuff
    
    @objc func startBeaconStuff() {
        
        if (!self.getRetailerListFlag) {
            self.getAllRetailers()
        }
        
//        switch UIApplication.shared.applicationState {
//        case .active:
//            print("active")
//            print("App is forground. Next number = \(beaconDistance)")
//        case .background:
//            print("App is backgrounded. Next number = \(beaconDistance)")
//            print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
//        case .inactive:
//            break
//        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        if (locations.count != 0){
            let location = locations[0]
            self.myAltitude = location.altitude
            self.myCoords = location.coordinate
            // just test
//            self.myCoords?.latitude = 47.91200350620526
//            self.myCoords?.longitude = 106.9116047436471
            
            getAllRetailers()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    self.startScanning()
                }
            }
        }
    }
    
    func startScanning() {
        if self.significantUUID != "" && self.significantUUID != nil {
//            let uuid = UUID(uuidString: Config.Proximity.beaconUDID)!
            
            let uuid = UUID(uuidString: self.significantUUID!)
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: "MyBeacon")
            
            locationManager.startMonitoring(for: beaconRegion)
            locationManager.startRangingBeacons(in: beaconRegion)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            
            if (UserDefaults.standard.object(forKey: "retailerExistFlag") as! Bool) {
                
                //add beacons
                for beacon in beacons {
                    print ("Detected Beacon Major:\(beacon.major)  Minor:\(beacon.minor)")
                    
                    for beaconFromRetailer in self.beaconsFromRetailer {
                        
                        print ("BeaconFromRetailer Major:\(String(describing: beaconFromRetailer.beaconMajor))  Minor:\(String(describing: beaconFromRetailer.beaconMinor))")
                        if (beacon.major as! Int) != beaconFromRetailer.beaconMajor {
                            continue
                        }
                        
                        if (beacon.minor as! Int) != beaconFromRetailer.beaconMinor {
                            continue
                        }
                        
                        updateDistance(beacon.proximity)
                        self.beaconMajor = String(beacon.major as! Int)
                        self.beaconMinor = String(beacon.minor as! Int)
                        self.beaconDistance = String(beacon.accuracy)
                        
                        let currentDate = Date()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MM/dd/YYYY hh:mm:ss a"
                        let convertedDate = dateFormatter.string(from: currentDate)
                        
                        var value = [String: Any]()
                        //                                    value["beaconRefId"] = Config.Proximity.beaconUDID
//                        value["beaconRefId"] = self.significantUUID
                        value["beaconRefId"] = beacon.proximityUUID.uuidString
                        value["major"] = String(beacon.major as! Int)
                        value["minor"] = String(beacon.minor as! Int)
                        value["rssi"] = String(beacon.rssi as Int)
                        value["accuracy"] = String(beacon.accuracy as Double)
                        switch beacon.proximity{
                        case .unknown:
                            value["proximity"] = "unknown"
                        case .far:
                            value["proximity"] = "far"
                        case .near:
                            value["proximity"] = "near"
                            print("near")
                        case .immediate:
                            value["proximity"] = "immediate"
                        }
                        value["createdOn"] = convertedDate
                        
                        self.mutableArr.add(value)
                    }
                }
            }
            
//            if (!self.uploadFlag) {
//                self.uploadFlag = true
//                self.setTimer()
            print("BLE MutableArr Count \(self.mutableArr.count)")
//            if (self.mutableArr.count > 0) {
//                self.getProximityUrl()
//            }
            
        } else {
            updateDistance(.unknown)
        }
    }
    
    func updateDistance(_ distance: CLProximity) {
        UIView.animate(withDuration: 0.8) {
            switch distance {
            case .unknown:
                print("Update Distance Unknown")
            case .far:
                print("Update Distance far")
            case .near:
                print("Update Distance near")
            case .immediate:
                print("Update Distance immediate")
            }
        }
    }
    
    func getProximityUrl() {
        if self.mutableArr.count > 0 {
            let value = [String: Any]()
            AlamofireRequestAndResponse.sharedInstance.getProximityUrlData(value as NSDictionary, success: { (res: [String: Any]) -> Void in
                if let resData = res["data"] as? String {
                    print(resData)
                    self.uploadBLEData(toStorage: resData)
                }
            },
                                                                           failure: { (error: Error!) -> Void in
                                                                            let alert = UIAlertController(title: "Error", message: "BLE data upload error", preferredStyle: UIAlertControllerStyle.alert)
                                                                            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                                                                                UIAlertAction in
                                                                                
                                                                            }
                                                                            alert.addAction(okAction)
                                                                            self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    func uploadBLEData(toStorage : String) {
        
        self.window?.rootViewController?.view.addSubview(locationMark)
        
//        var compressedData = Data()
        var encryptedData = Data()
        
        var beaconUploadData : [String: Any] = [String: Any]()
        var locationInfo : [String: Any] = [String: Any]()
        var spatial : [String: Any] = [String: Any]()
        
        spatial["longitude"] = self.myCoords?.longitude as Any?
        spatial["latitude"] = self.myCoords?.latitude as Any?
        spatial["altitude"] = self.myAltitude as Any?
        
        if (config.getValue("devEndpoint", fromStore: "settings") as? Bool)! {
            locationInfo["playerLicenseCode"] = config.getValue("devPlayToken", fromStore: "settings") as? String
        } else {
            locationInfo["playerLicenseCode"] = config.getValue("playToken", fromStore: "settings") as? String
        }
        
        if (self.retailerRefIdStr == "") {
            locationInfo["retailerRefId"] = "00000000-0000-0000-0000-000000000000"
        } else {
            locationInfo["retailerRefId"] = self.retailerRefIdStr
        }
        locationInfo["spatial"] = spatial
        locationInfo["beaconEvents"] = self.mutableArr.copy()
        
        beaconUploadData["locationInfo"] = locationInfo
        beaconUploadData["brandLicenseCode"] = config.getValue("devBrandLicenseCode", fromStore: "settings") as? String
        
        print(JSONStringify(beaconUploadData))
        
        if JSONSerialization.isValidJSONObject(beaconUploadData) {
            
            let file = "beaconFile.json" //this is the file. we will write to and read from it
            
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                
                let path = dir.appendingPathComponent(file)
                let text = self.JSONStringify(beaconUploadData)
                //writing
                do {
                    try text.write(to: path, atomically: false, encoding: String.Encoding.utf8)
                }
                catch {/* error handling here */}
                do{
                    
                    encryptedData = try Data.init(contentsOf: path)
//                    compressedData = try! encryptedData.gzipped()
                }catch let error1 as GzipError{
                    
                    print(error1.localizedDescription)
                    //Access error here
                }catch let error2 as NSError{
                    
                    print(error2.localizedDescription)
                    //Access error here
                }
            }
        }
        
        UIView.animate(withDuration: 0.3, animations: { self.locationMark.alpha = 1.0 }, completion: nil)
        
        AlamofireRequestAndResponse.sharedInstance.proximityUploadWithBLEBlobData(toStorage, data: encryptedData, success: { (res: [String: Any]) -> Void in
            self.uploadFlag = false
            self.mutableArr.removeAllObjects()
            UIView.animate(withDuration: 0.3, animations: { self.locationMark.alpha = 0.0 }, completion: { Bool in
                self.locationMark.removeFromSuperview()
                self.mutableArr = NSMutableArray()
                let currentDate = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = DateFormatter.Style.full
                let convertedDate = dateFormatter.string(from: currentDate)
                UserDefaults.standard.set(convertedDate, forKey: "lastUploadedDate")
//                UserDefaults.standard.set(true, forKey: "retailerExistFlag")
                
            })
        },
          failure: { (error: Error!) -> Void in
            self.window?.rootViewController?.view.makeToast("beacon upload error")
            UIView.animate(withDuration: 0.3, animations: { self.locationMark.alpha = 0.0 }, completion: { Bool in
                self.locationMark.removeFromSuperview()
            })
            
        })
    }
    
    func getAllRetailers() {
        var playToken = ""
        if self.config.getValue("devEndpoint", fromStore: "settings") as! Bool {
            playToken = self.config.getValue("devPlayToken", fromStore: "settings") as! String
        } else {
            playToken = self.config.getValue("playToken", fromStore: "settings") as! String
        }
        
        if playToken.length == 0 {
            return
        }
        
        if self.myCoords == nil {
            return
        }
        
        self.getRetailerListFlag = true
        let uuid = UIDevice.current.identifierForVendor!.uuidString
        var data = [String: Any]()
        let middleData = [String: Any]()
        
        data["uuid"] = uuid
        data["latitude"] = self.myCoords?.latitude as Any?
        data["longitude"] = self.myCoords?.longitude as Any?
        data["data"] = middleData as Any?
//        data["latitude"] = tempLatitude
//        data["longitude"] = tempLongitude
        
        
        AlamofireRequestAndResponse.sharedInstance.getRetailersWithLocation(data as NSDictionary, success: { (res: [String: Any]) -> Void in
            
            guard let resData: NSArray = res["data"] as? NSArray else {
                return
            }
            
            self.getRetailerListFlag = false
            
            
            if (resData.count != 0 && self.myCoords != nil) {
                self.beaconsFromRetailer.removeAll()
                
                var maxDistanceInMeters = 10000000.0
                var retailerAddress : String = ""
                
                let myCoordinate = CLLocation(latitude: (self.myCoords?.latitude)!, longitude: (self.myCoords?.longitude)!)
//                let tempmyCoordinate = CLLocation(latitude: self.tempLatitude, longitude: self.tempLongitude)
                
                // get the neast retailler based on the retailer coordinates
                for item in resData {
                    print ("ITEM \(item)")
                    if let retailerItem = item as? [String : Any] {
                        
                        //get location
                        self.retailerRefIdStr = retailerItem["retailerRefId"] as? String ?? ""
                        let addressLocation = retailerItem["addressLocation"] as? [String : Any]
                        if let retailerCoordsArr = addressLocation?["coordinates"] as? NSArray,
                            let latitude = retailerCoordsArr[1] as? CLLocationDegrees,
                            let longitude = retailerCoordsArr[0] as? CLLocationDegrees
                        {
                            let retailerCoordinates = CLLocation(latitude: latitude, longitude: longitude)
                            let distanceInMeters = myCoordinate.distance(from: retailerCoordinates)
                            
                            if (Double(distanceInMeters) < Double(maxDistanceInMeters)) {
                                maxDistanceInMeters = Double(distanceInMeters)
                                self.closestRetailerItem = retailerItem
                            }
                        }
                    }
                }
                
                //get beacons data(closest retailer item)
                if let beaconsArray: NSArray = self.closestRetailerItem["beacons"] as? NSArray {
                    
                    retailerAddress = String.init(format: "%@, %@, %@",
                                                  self.closestRetailerItem["retailerName"] as! String,
                                                  self.closestRetailerItem["addressLine1"] as! String,
                                                  self.closestRetailerItem["addressStateProvince"] as! String)
                    self.retailerRefIdStr = self.closestRetailerItem["retailerRefId"] as! String
                    
                    for beaconItem in beaconsArray {
                        let json = JSON(beaconItem)
                        let beacon = BeaconItem(json)
                        self.significantUUID = beacon!.beaconuuid
                        self.beaconsFromRetailer.append(beacon!)
                    }
                }
                
                let notification = UILocalNotification()
                notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                notification.alertBody = String.init(format: "Play now at %@ ", retailerAddress)
                notification.alertAction = "open"
                notification.hasAction = true
                notification.userInfo = ["UUID": Config.Proximity.beaconUDID]
                UIApplication.shared.scheduleLocalNotification(notification)
                UserDefaults.standard.set(true, forKey: "retailerExistFlag")
                self.getRetailerListFlag = false
                self.startScanning()
                
            } else {
                UserDefaults.standard.set(false, forKey: "retailerExistFlag")
//                self.beaconsFromRetailer.removeAll()
                self.getRetailerListFlag = false
            }
            
        },
        failure: { (error: Error!) -> Void in
            UserDefaults.standard.set(false, forKey: "retailerExistFlag")
            print("get retailer list error")
            self.getRetailerListFlag = false
            self.getAllRetailers()
        })
    }
    
//    func setTimer() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
//            self.uploadFlag = false
//        }
    //    }
    
    // MARK: get hockey app id and set
    func getAndSetHockeyAppID() {
        
        let data : [String : Any] = [String : Any]()
        
        AlamofireRequestAndResponse.sharedInstance.getHockeyAppID(data, success: { (res: [String : Any]) -> Void in
            
            if let resData: [String : Any] = res["data"] as? [String : Any],
                let hockeyAppId : String = resData["hockeyAppIdIos"] as? String,
                let dict = resData["incentivePlaySponsorAchievementUrls"] as? [AnyObject]
            {
                BITHockeyManager.shared().configure(withIdentifier: hockeyAppId)
                BITHockeyManager.shared().authenticator.authenticateInstallation()
                BITHockeyManager.shared().crashManager.crashManagerStatus = BITCrashManagerStatus.autoSend
                    BITHockeyManager.shared().start()
                
                func updateImages() {
                    GameSponsorImages.saveImages(dict)
                    UserDefaults.standard.set(Date(), forKey: "updateSponsorImageDate")
                    
                }
                guard let updateImageDate = UserDefaults.standard.object(forKey: "updateSponsorImageDate") as? Date else {
                    updateImages()
                    return
                }
                
                let isTheSameDay = Calendar.current.compare(updateImageDate, to: Date(), toGranularity: .day) == .orderedSame ? true : false
                
                if !isTheSameDay {
                    updateImages()
                }
                
            }
        },
                                                                  failure: { (error: Error!) -> Void in
                                                                    print("hockey app error")
        })
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    // MARK: delete all local files
    
    func deleteAllLocalFiles() {
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fm = FileManager.default
        do {
            let fileArr : Array = try fm.contentsOfDirectory(atPath: documentPath)
            for file in fileArr {
                if file.range(of: "plist") != nil{
                    break
                } else {
                    do{
                        try fm.removeItem(atPath: String.init(format: "%@/%@", documentPath, file))
                        print("deleted\(file)")
                    } catch let error as NSError{
                        print("delete error\(error)")
                    }
                }
                
            }
        } catch let error as NSError{
            print("file find error\(error)")
        }
    }
    
    func getFileItemFromLocal() {
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fm = FileManager.default
        do {
            let fileArr : Array = try fm.contentsOfDirectory(atPath: documentPath)
            for file in fileArr {
                if file.range(of: "plist") != nil{
                    break
                } else {
                    
                    let filePath : String = String.init(format: "%@/%@", documentPath, file)
                    print(filePath)
                }
                
            }
        } catch let error as NSError{
            print("file find error\(error)")
        }
    }
    
    //****************************************//
    //   JSON helper function
    //****************************************//
    
    func JSONStringify(_ value: Any,prettyPrinted:Bool = false) -> String{
        
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        
        
        if JSONSerialization.isValidJSONObject(value) {
            
            do{
                let data = try JSONSerialization.data(withJSONObject: value, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    
                    return string as String
                }
            }catch {
                
                print("stringfy error")
                //Access error here
            }
            
        }
        return ""
        
    }
    
    func JSONParseArray(_ string: String) -> [String : Any]{
        if let data = string.data(using: String.Encoding.utf8){
            
            do{
                
                if let array = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)  as? [String : Any] {
                    return array
                }
            }catch{
                
                print("parse array error")
                //handle errors here
            }
        }
        return [String : Any]()
    }
    
    func JSONParseForSimpleArray(_ string: String) -> NSArray{
        if let data = string.data(using: String.Encoding.utf8){
            
            do{
                if let array = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)  as? NSArray {
                    return array
                }
            }catch{
                print("simple array parse error")
                return NSArray()
                //handle errors here
            }
        }
        return NSArray()
    }
    
    // save shopping cart data using base64 string image data from url
    func saveShoppingCartDataWithBase64Image(shoppingCart: [String : Any], prettyPrinted:Bool = false) {
        
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        
        var shoppingCartNew = shoppingCart
        var sampleData: [String : Any] = shoppingCart["shoppingCarts"] as! [String:Any]
        let shoppingCartArr = sampleData["items"] as! NSArray
        
        let mutableUpdateCartArr = NSMutableArray()
        
        for shoppingCart in shoppingCartArr{
            var item = shoppingCart as! [String : Any]
            
            do {
                let tileUrl: URL = URL(string: item["tileUrl"] as! String)!
                let logoUrl =  item["gameLogoUrl"] as! String
                var imageFromUrl = Data()
                // confirm and set the widget view image
                var targetImage : UIImage = UIImage()
                
                if (item["animatedState"] as! Bool) {
                    targetImage = UIImage(named:"valogovertical_logo")!
                } else {
                    imageFromUrl = try Data.init(contentsOf: tileUrl)
                    targetImage = UIImage(data: imageFromUrl)!
                }
                var imageData = UIImageJPEGRepresentation(targetImage, 1.0)
                var strBase64:String = imageData!.base64EncodedString(options: .lineLength64Characters)
                item["tileUrl"] = strBase64
                
                let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let filePath = String.init(format: "%@/%@", documentPath, logoUrl)
                imageData = UIImageJPEGRepresentation(UIImage.init(contentsOfFile: filePath)!, 1.0)
                strBase64 = imageData!.base64EncodedString(options: .lineLength64Characters)
                item["gameLogoUrl"] = strBase64
            } catch {
                print("stringfy error")
                //Access error here
            }
            mutableUpdateCartArr.add(item)
        }
        
        sampleData["items"] = mutableUpdateCartArr.copy() as! NSArray
        shoppingCartNew["shoppingCarts"] = sampleData
        
        do {
            let data = try JSONSerialization.data(withJSONObject: shoppingCartNew, options: options)
            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                let defaults = UserDefaults(suiteName: "group.valottery.playapp.valot.todayWidget")
                
                
                defaults?.set(string, forKey: "shoppingCartWidgetStr")
                
                // tell the defaults to write to disk now
                defaults?.synchronize()
            }
        } catch {
            print("stringfy error")
            //Access error here
        }
    }
    
    // save top prizes cart to widget view storage
    func savePrizeCartWithBase64Images(prizeCartArr: NSArray, prettyPrinted:Bool = false) {
        
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        
        var prizeCartNew = prizeCartArr
        
        let mutableUpdateCartArr = NSMutableArray()
        
        for prizeCart in prizeCartArr{
            var item = prizeCart as! [String : Any]
            

            let logoUrl: String =  item["logoUrl"] as! String
            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath = String.init(format: "%@/%@", documentPath, logoUrl)
            self.getFileItemFromLocal()
            if let targetImage = UIImage.init(contentsOfFile: filePath) {
                let imageData = UIImageJPEGRepresentation(targetImage, 1.0)
                let strBase64:String = imageData!.base64EncodedString(options: .lineLength64Characters)
                item["logoUrl"] = strBase64
            }

            mutableUpdateCartArr.add(item)
        }
        
        prizeCartNew = mutableUpdateCartArr.copy() as! NSArray
        
        do {
            let data = try JSONSerialization.data(withJSONObject: prizeCartNew, options: options)
            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                let defaultsPrize = UserDefaults(suiteName: "group.playlazlo.player.valotapp.PrizeWidget")
                
                defaultsPrize?.set(string, forKey: "prizesCartStr")
                
                // tell the defaults to write to disk now
                defaultsPrize?.synchronize()
            }
        } catch {
            print("stringfy error")
            //Access error here
        }
    }
    
    
    // save shopping cart data to default user data
    func saveShoppingCartToLocal(data: [String : Any]) -> Bool{
        
        var jsonData = self.getJSONDataFromLocal()
        var updateFlag: Bool = false
        
        var shoppingCarts = jsonData["shoppingCarts"] as! [String:Any]
        var shoppingCartsItemArr = shoppingCarts["items"] as! NSArray
        let mutableUpdateCartArr = NSMutableArray()
        
        for shoppingCart in shoppingCartsItemArr{
            var item = shoppingCart as! [String : Any]
            if ((item["gameRefId"] as! String == data["gameRefId"] as! String) &&
                (item["drawRefId"] as! String == data["drawRefId"] as! String) &&
                (item["channelGroupRefId"] as! String == data["channelGroupRefId"] as! String) &&
                (item["channelRefId"] as! String == data["channelRefId"] as! String) &&
                (item["playAmount"] as! NSNumber == data["playAmount"] as! NSNumber) ){
                let oldCount = item["panelCount"] as! Int
                let newCount = data["panelCount"] as! Int
                item["panelCount"] = oldCount + newCount
                updateFlag = true
            }
            mutableUpdateCartArr.add(item)
        }
        if (!updateFlag){
            if let mutableCartArr = shoppingCartsItemArr.mutableCopy() as? NSMutableArray {
                mutableCartArr.add(data)
                shoppingCartsItemArr = mutableCartArr as NSArray
            }
        } else {
            shoppingCartsItemArr = mutableUpdateCartArr as NSArray
        }
        
        shoppingCarts["items"] = shoppingCartsItemArr
        jsonData["shoppingCarts"] = shoppingCarts
        
        self.saveShoppingCartDataWithBase64Image(shoppingCart: jsonData)
        
        if (JSONSerialization.isValidJSONObject(jsonData)){
            let jsonStr: String = self.JSONStringify(jsonData)
            UserDefaults.standard.set(jsonStr, forKey: "shoppingCardData")
            return true
        } else {
            
            return false
        }
        
    }
    
    // update shopping cart data to default user data using +, - buttons
    func updateShoppingCartToLocal(data: [String : Any]) -> Bool{
        
        _ = self.updateWidgetDataUsingButtons(data: data)
        var jsonData = self.getJSONDataFromLocal()
        var updateFlag: Bool = false
        
        var shoppingCarts = jsonData["shoppingCarts"] as! [String:Any]
        var shoppingCartsItemArr = shoppingCarts["items"] as! NSArray
        let mutableUpdateCartArr = NSMutableArray()
        
        for shoppingCart in shoppingCartsItemArr{
            var item = shoppingCart as! [String : Any]
            if ((item["gameRefId"] as! String == data["gameRefId"] as! String) &&
                (item["drawRefId"] as! String == data["drawRefId"] as! String) &&
                (item["channelGroupRefId"] as! String == data["channelGroupRefId"] as! String) &&
                (item["channelRefId"] as! String == data["channelRefId"] as! String) &&
                (item["playAmount"] as! NSNumber == data["playAmount"] as! NSNumber) ){
                item["panelCount"] = data["panelCount"]
                updateFlag = true
            }
            mutableUpdateCartArr.add(item)
        }
        if (!updateFlag){
            let mutableCartArr = shoppingCartsItemArr.mutableCopy() as! NSMutableArray
            mutableCartArr.add(data)
            shoppingCartsItemArr = mutableCartArr as NSArray
        } else {
            shoppingCartsItemArr = mutableUpdateCartArr as NSArray
        }
        
        shoppingCarts["items"] = shoppingCartsItemArr
        jsonData["shoppingCarts"] = shoppingCarts
        
        if (JSONSerialization.isValidJSONObject(jsonData)){
            
            let jsonStr: String = self.JSONStringify(jsonData)
            UserDefaults.standard.set(jsonStr, forKey: "shoppingCardData")
            return true
        } else {
            
            return false
        }
        
    }
    
    func updateWidgetDataUsingButtons(data: [String : Any]) -> Bool{
        
        let defaults = UserDefaults(suiteName: "group.valottery.playapp.valot.todayWidget")
        var jsonData = self.JSONParseArray((defaults?.object(forKey: "shoppingCartWidgetStr") as? String)!)
        var updateFlag: Bool = false
        
        var shoppingCarts = jsonData["shoppingCarts"] as! [String:Any]
        var shoppingCartsItemArr = shoppingCarts["items"] as! NSArray
        let mutableUpdateCartArr = NSMutableArray()
        
        for shoppingCart in shoppingCartsItemArr{
            var item = shoppingCart as! [String : Any]
            if ((item["gameRefId"] as! String == data["gameRefId"] as! String) &&
                (item["drawRefId"] as! String == data["drawRefId"] as! String) &&
                (item["channelGroupRefId"] as! String == data["channelGroupRefId"] as! String) &&
                (item["channelRefId"] as! String == data["channelRefId"] as! String) &&
                (item["playAmount"] as! NSNumber == data["playAmount"] as! NSNumber) ){
                item["panelCount"] = data["panelCount"]
                updateFlag = true
            }
            mutableUpdateCartArr.add(item)
        }
        if (!updateFlag){
            let mutableCartArr = shoppingCartsItemArr.mutableCopy() as! NSMutableArray
            mutableCartArr.add(data)
            shoppingCartsItemArr = mutableCartArr as NSArray
        } else {
            shoppingCartsItemArr = mutableUpdateCartArr as NSArray
        }
        
        shoppingCarts["items"] = shoppingCartsItemArr
        jsonData["shoppingCarts"] = shoppingCarts
        
        let options = JSONSerialization.WritingOptions(rawValue: 0)
        
        if (JSONSerialization.isValidJSONObject(jsonData)){
            do {
                let data = try JSONSerialization.data(withJSONObject: jsonData, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    defaults?.set(string, forKey: "shoppingCartWidgetStr")
                    
                    // tell the defaults to write to disk now
                    defaults?.synchronize()
                }
            } catch {
                print("stringfy error")
                //Access error here
            }
            return true
        } else {
            
            return false
        }
        
    }
    
    // get json data from local storage
    func getJSONDataFromLocal() -> [String:Any]{
        if ((UserDefaults.standard.object(forKey: "shoppingCardData")) != nil){
            if ((UserDefaults.standard.object(forKey: "shoppingCardData")) as! String != ""){
                let jsonStr = UserDefaults.standard.object(forKey: "shoppingCardData") as! String
                return self.JSONParseArray(jsonStr)
            } else {
                return self.saveInitJsonData()
            }
            
        } else {
            return self.saveInitJsonData()
        }
    }
    
    // delete one row from shopping cart table
    func deleteOneItem(data: [String : Any]) -> Bool{
        
        var jsonData = self.getJSONDataFromLocal()
        
        var shoppingCarts = jsonData["shoppingCarts"] as! [String:Any]
        var shoppingCartsItemArr = shoppingCarts["items"] as! NSArray
        let mutableCartArr = shoppingCartsItemArr.mutableCopy() as! NSMutableArray
        mutableCartArr.remove(data)
        shoppingCartsItemArr = mutableCartArr as NSArray
        
        shoppingCarts["items"] = shoppingCartsItemArr
        jsonData["shoppingCarts"] = shoppingCarts
        
        self.saveShoppingCartDataWithBase64Image(shoppingCart: jsonData)
        
        if (JSONSerialization.isValidJSONObject(jsonData)){
            let jsonStr: String = self.JSONStringify(jsonData)
            UserDefaults.standard.set(jsonStr, forKey: "shoppingCardData")
            return true
        } else {
            
            return false
        }
    }
    
    func saveInitJsonData() -> [String:Any]{
        var data = [String: Any]()
        var shoppingCarts = [String: Any]()
        var socialShoppingCarts1 = [String: Any]()
        
        socialShoppingCarts1["socialShoppingCartLicenseCode"] = "jhghghgk"
        socialShoppingCarts1["addedOn"] = "datetime"
        var socialShoppingCarts2 = [String: Any]()
        socialShoppingCarts2["socialShoppingCartLicenseCode"] = "jhghghgk"
        socialShoppingCarts2["addedOn"] = "datetime"
        let socialShoppingCarts = [socialShoppingCarts1, socialShoppingCarts2]
        
        shoppingCarts["shoppingCartName"] = "default"
        shoppingCarts["items"] = NSArray()
        
        data["shoppingCarts"] = shoppingCarts
        data["socialShoppingCarts"] = socialShoppingCarts
        
        self.saveShoppingCartDataWithBase64Image(shoppingCart: data)
        
        let jsonStr: String = self.JSONStringify(data)
        UserDefaults.standard.set(jsonStr, forKey: "shoppingCardData")
        return data
    }
    
    //****************************************//
    //   Ticket JSON helper function
    //****************************************//
    
    // save ticket array data to local storage
    func saveTicketJSONToLocal(arr: NSArray!) -> Bool{
        
        let jsonArr : NSArray = self.getTicketJSONDataFromLocal()
        let mutableUpdateCartArr = NSMutableArray()
        
        
        for addCart in arr{
            let item = addCart as! [String : Any]
            mutableUpdateCartArr.add(item)
        }
        
        for ticketCart in jsonArr{
            let item = ticketCart as! [String : Any]
            mutableUpdateCartArr.add(item)
        }
        
        let copyTickArr : NSArray = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(copyTickArr)){
            let jsonStr: String = self.JSONStringify(copyTickArr)
            UserDefaults.standard.set(jsonStr, forKey: "successedTicketData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // save one ticket file to local storage
    func saveOneTicketToLocal(data: [String : Any]) -> Bool{
        
        let jsonArr : NSArray = self.getTicketJSONDataFromLocal()
        let mutableUpdateCartArr = NSMutableArray()
        var isExists: Bool = false
        
        for ticketItem in jsonArr{
            var oneTicketItem = ticketItem as! [String : Any]
            if ((oneTicketItem["fileName"] as! String == data["fileName"] as! String) &&
                (oneTicketItem["licenseCypherText"] as! String == data["licenseCypherText"] as! String)){
                isExists = true
                break
            }
        }
        if (!isExists){
            mutableUpdateCartArr.add(data)
        }
        
        for ticketCart in jsonArr{
            let item = ticketCart as! [String : Any]
            mutableUpdateCartArr.add(item)
        }
        
        let copyTickArr : NSArray = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(copyTickArr)){
            let jsonStr: String = self.JSONStringify(copyTickArr)
            UserDefaults.standard.set(jsonStr, forKey: "successedTicketData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // update ticket data on to local storage
    func updateTicketToLocal(data: [String : Any], style : Int) -> Bool{
        
        var jsonArr = self.getTicketJSONDataFromLocal()
        var updateFlag: Bool = false
        let mutableUpdateCartArr = NSMutableArray()
        
        for ticketItem in jsonArr{
            var item = ticketItem as! [String : Any]
            if ((item["ticketRefId"] as! String == data["ticketRefId"] as! String) &&
                (item["ticketTemplateRefId"] as! String == data["ticketTemplateRefId"] as! String) &&
                (item["checkoutSessionRefId"] as! String == data["checkoutSessionRefId"] as! String)){
                switch(style) {
                case 1:
                    item["isValid"] = data["isValid"]
                    item["isCompleted"] = data["isCompleted"]
                    break;
                case 2:
                    item["licenseCypherText"] = data["licenseCypherText"]
                    break;
                case 3:
                    item["isClaimed"] = data["isClaimed"]
                    break;
                case 4:
                    item["downloaded"] = data["downloaded"]
                    break;
                default:
                    break;
                }
                updateFlag = true
            }
            mutableUpdateCartArr.add(item)
        }
        
        jsonArr = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(jsonArr)){
            let jsonStr: String = self.JSONStringify(jsonArr)
            UserDefaults.standard.set(jsonStr, forKey: "successedTicketData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // delete one ticket from local cart table
    func deleteOneTicketItem(data: [String : Any], fileName : String) -> Bool{
        
        let jsonArr = self.getTicketJSONDataFromLocal()
        
        let mutableCartArr = jsonArr.mutableCopy() as! NSMutableArray
        mutableCartArr.remove(data)
        
        let copyTickArr : NSArray = mutableCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(copyTickArr)){
            let jsonStr: String = self.JSONStringify(copyTickArr)
            UserDefaults.standard.set(jsonStr, forKey: "successedTicketData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fm = FileManager.default
        
        do{
            try fm.removeItem(atPath: String.init(format: "%@/%@", documentPath, fileName))
            print("deleted\(fileName)")
        } catch let error as NSError{
            print("delete error\(error)")
        }
        
    }
    
    // get ticket data from local storage
    func getTicketJSONDataFromLocal() -> NSArray{
        if ((UserDefaults.standard.object(forKey: "successedTicketData")) != nil){
            if ((UserDefaults.standard.object(forKey: "successedTicketData")) as! String != ""){
                let jsonStr = UserDefaults.standard.object(forKey: "successedTicketData") as! String
                return self.JSONParseForSimpleArray(jsonStr)
            } else {
                return NSArray()
            }
            
        } else {
            return NSArray()
        }
    }
    
    // save init ticket array onto local storage
    func saveInitTicketJSONData() -> [String:Any]{
        let data = [String: Any]()
        let jsonStr: String = self.JSONStringify(data)
        UserDefaults.standard.set(jsonStr, forKey: "successedTicketData")
        return data
    }
    
    //****************************************//
    //   Ticket ERROR JSON helper function
    //****************************************//
    // save ticket error data to local storage
    func saveTicketErrorJSONToLocal(arr: NSArray!) -> Bool{
        
        let jsonArr : NSArray = self.getTicketErrorJSONDataFromLocal()
        let mutableUpdateCartArr = NSMutableArray()
        
        for addCart in arr{
            if let item = addCart as? [String : Any] {
                mutableUpdateCartArr.add(item)
            }
        }
        
        for ticketCart in jsonArr{
            let item = ticketCart as! [String : Any]
            mutableUpdateCartArr.add(item)
        }
        
        let copyTickArr : NSArray = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(copyTickArr)){
            let jsonStr: String = self.JSONStringify(copyTickArr)
            UserDefaults.standard.set(jsonStr, forKey: "failedTicketData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // save ticket error data to local storage
    func saveOneTicketErrorItemToLocal(data: [String : Any]) -> Bool{
        
        let jsonArr : NSArray = self.getTicketErrorJSONDataFromLocal()
        let mutableUpdateCartArr = NSMutableArray()
        
        var isExists: Bool = false
        
        for ticketErrorItem in jsonArr{
            var oneTicketErrorItem = ticketErrorItem as! [String : Any]
            if ((oneTicketErrorItem["fileName"] as! String == data["fileName"] as! String) &&
                (oneTicketErrorItem["licenseCypherText"] as! String == data["licenseCypherText"] as! String)){
                isExists = true
                break
            }
        }
        if (!isExists){
            mutableUpdateCartArr.add(data)
        }
        
        for ticketCart in jsonArr{
            let item = ticketCart as! [String : Any]
            mutableUpdateCartArr.add(item)
        }
        
        let copyTickArr : NSArray = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(copyTickArr)){
            let jsonStr: String = self.JSONStringify(copyTickArr)
            UserDefaults.standard.set(jsonStr, forKey: "failedTicketData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // delete one ticket from local cart table
    func deleteOneTicketErrorItem(data: [String : Any]) -> Bool{
        
        let jsonArr = self.getTicketErrorJSONDataFromLocal()
        
        let mutableCartArr = jsonArr.mutableCopy() as! NSMutableArray
        mutableCartArr.remove(data)
        
        guard let copyTickArr : NSArray = mutableCartArr.copy() as? NSArray else {
            return false
        }
        
        if (JSONSerialization.isValidJSONObject(copyTickArr)){
            let jsonStr: String = self.JSONStringify(copyTickArr)
            UserDefaults.standard.set(jsonStr, forKey: "failedTicketData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // get ticket error data from local storage
    func getTicketErrorJSONDataFromLocal() -> NSArray{
        if ((UserDefaults.standard.object(forKey: "failedTicketData")) != nil){
            if ((UserDefaults.standard.object(forKey: "failedTicketData")) as! String != ""){
                let jsonStr = UserDefaults.standard.object(forKey: "failedTicketData") as! String
                return self.JSONParseForSimpleArray(jsonStr)
            } else {
                return NSArray()
            }
            
        } else {
            return NSArray()
        }
    }
    
    // save init ticket array onto local storage
    func saveInitTicketErrorJSONData() -> [String:Any]{
        let data = [String: Any]()
        let jsonStr: String = self.JSONStringify(data)
        UserDefaults.standard.set(jsonStr, forKey: "failedTicketData")
        return data
    }
    
    //****************************************//
    //   Redeem Card JSON helper function
    //****************************************//
    
    // get redeem card data from local storage
    func getRedeemCardJSONDataFromLocal() -> NSArray{
        if ((UserDefaults.standard.object(forKey: "redeemCardsData")) != nil){
            if ((UserDefaults.standard.object(forKey: "redeemCardsData")) as! String != ""){
                let jsonStr = UserDefaults.standard.object(forKey: "redeemCardsData") as! String
                return self.JSONParseForSimpleArray(jsonStr)
            } else {
                return NSArray()
            }
            
        } else {
            return NSArray()
        }
    }
    
    // save redeem card data from local storage
    func saveRedeemCardJSONDataToLocal(arr : NSArray) -> Bool{
        if (JSONSerialization.isValidJSONObject(arr)){
            let jsonStr: String = self.JSONStringify(arr)
            UserDefaults.standard.set(jsonStr, forKey: "redeemCardsData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
    }
    
    
    // save ticket redeem card to local storage
    func saveOneRedeemCardItemToLocal(data: [String : Any]) -> Bool{
        
        let jsonArr : NSArray = self.getRedeemCardJSONDataFromLocal()
        let mutableUpdateCartArr = NSMutableArray()
        
        var isExists: Bool = false
        
        if (!isExists){
            mutableUpdateCartArr.add(data)
        }
        
        for redeemCart in jsonArr {
            let item = redeemCart as! [String : Any]
            mutableUpdateCartArr.add(item)
        }
        
        let copyRedeemArr : NSArray = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(copyRedeemArr)){
            let jsonStr: String = self.JSONStringify(copyRedeemArr)
            UserDefaults.standard.set(jsonStr, forKey: "redeemCardsData")
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reedemListUpdate"), object: nil, userInfo: nil)
            
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // update redeem card data on to local storage
    func updateRedeemCardToLocal(data: [String : Any], style : Int) -> Bool{
        
        var jsonArr = self.getRedeemCardJSONDataFromLocal()
        var updateFlag: Bool = false
        let mutableUpdateCartArr = NSMutableArray()
        
        for redeemItem in jsonArr{
            var item = redeemItem as! [String : Any]
            if ((item["fileName"] as! String == data["fileName"] as! String) &&
                (item["licenseCypherText"] as! String == data["licenseCypherText"] as! String)){
                switch(style) {
                case 1:
                    item["isValid"] = data["isValid"]
                    item["isCompleted"] = data["isCompleted"]
                    break;
                case 2:
                    item["licenseCypherText"] = data["licenseCypherText"]
                    break;
                case 3:
                    item["isClaimed"] = data["isClaimed"]
                    break;
                case 4:
                    item["downloaded"] = data["downloaded"]
                    break;
                default:
                    break;
                }
                updateFlag = true
            }
            mutableUpdateCartArr.add(item)
        }
        
        jsonArr = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(jsonArr)){
            let jsonStr: String = self.JSONStringify(jsonArr)
            UserDefaults.standard.set(jsonStr, forKey: "redeemCardsData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // delete one redeem card from local cart table
    func deleteOneRedeemItem(data: [String : Any]) -> Bool{
        
        let jsonArr = self.getRedeemCardJSONDataFromLocal()
        
        let mutableCartArr = jsonArr.mutableCopy() as! NSMutableArray
        mutableCartArr.remove(data)
        
        guard let copyRedeemArr : NSArray = mutableCartArr.copy() as? NSArray else {
            return false
        }
        
        if (JSONSerialization.isValidJSONObject(copyRedeemArr)){
            let jsonStr: String = self.JSONStringify(copyRedeemArr)
            UserDefaults.standard.set(jsonStr, forKey: "redeemCardsData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // save init redeem card onto local storage
    func saveInitRedeemCardJSONData() -> [String:Any]{
        let data = [String: Any]()
        let jsonStr: String = self.JSONStringify(data)
        UserDefaults.standard.set(jsonStr, forKey: "redeemCardsData")
        return data
    }
    
    //****************************************//
    //   Coupon JSON helper function
    //****************************************//
    
    // get redeem card data from local storage
    func getCouponJSONDataFromLocal() -> NSArray{
        if ((UserDefaults.standard.object(forKey: "couponData")) != nil){
            if ((UserDefaults.standard.object(forKey: "couponData")) as! String != ""){
                let jsonStr = UserDefaults.standard.object(forKey: "couponData") as! String
                return self.JSONParseForSimpleArray(jsonStr)
            } else {
                return NSArray()
            }
            
        } else {
            return NSArray()
        }
    }
    
    // save redeem card data from local storage
    func saveCouponJSONDataToLocal(arr : NSArray) -> Bool{
        if (JSONSerialization.isValidJSONObject(arr)){
            let jsonStr: String = self.JSONStringify(arr)
            UserDefaults.standard.set(jsonStr, forKey: "couponData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
    }
    
    
    // save ticket redeem card to local storage
    func saveOneCouponItemToLocal(data: [String : Any]) -> Bool{
        
        let jsonArr : NSArray = self.getCouponJSONDataFromLocal()
        let mutableUpdateCartArr = NSMutableArray()
        
        let isExists: Bool = false
        
        if (!isExists){
            mutableUpdateCartArr.add(data)
        }
        
        for redeemCart in jsonArr{
            let item = redeemCart as! [String : Any]
            mutableUpdateCartArr.add(item)
        }
        
        let copyCouponArr : NSArray = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(copyCouponArr)){
            let jsonStr: String = self.JSONStringify(copyCouponArr)
            UserDefaults.standard.set(jsonStr, forKey: "couponData")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reedemListUpdate"), object: nil, userInfo: nil)
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // update redeem card data on to local storage
    func updateCouponToLocal(data: [String : Any], style : Int) -> Bool{
        
        var jsonArr = self.getCouponJSONDataFromLocal()
        var updateFlag: Bool = false
        let mutableUpdateCartArr = NSMutableArray()
        
        for redeemItem in jsonArr{
            var item = redeemItem as! [String : Any]
            if ((item["fileName"] as! String == data["fileName"] as! String) &&
                (item["licenseCypherText"] as! String == data["licenseCypherText"] as! String)){
                switch(style) {
                case 1:
                    item["isValid"] = data["isValid"]
                    item["isCompleted"] = data["isCompleted"]
                    break;
                case 2:
                    item["licenseCypherText"] = data["licenseCypherText"]
                    break;
                case 3:
                    item["isClaimed"] = data["isClaimed"]
                    break;
                case 4:
                    item["downloaded"] = data["downloaded"]
                    break;
                default:
                    break;
                }
                updateFlag = true
            }
            mutableUpdateCartArr.add(item)
        }
        
        jsonArr = mutableUpdateCartArr.copy() as! NSArray
        
        if (JSONSerialization.isValidJSONObject(jsonArr)){
            let jsonStr: String = self.JSONStringify(jsonArr)
            UserDefaults.standard.set(jsonStr, forKey: "couponData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // delete one redeem card from local cart table
    func deleteOneCouponItem(data: [String : Any]) -> Bool{
        
        let jsonArr = self.getCouponJSONDataFromLocal()
        
        let mutableCartArr = jsonArr.mutableCopy() as! NSMutableArray
        mutableCartArr.remove(data)
        
        guard let copyCouponArr : NSArray = mutableCartArr.copy() as? NSArray else {
            return false
        }
        
        if (JSONSerialization.isValidJSONObject(copyCouponArr)){
            let jsonStr: String = self.JSONStringify(copyCouponArr)
            UserDefaults.standard.set(jsonStr, forKey: "couponData")
            return true
        } else {
            print("JSON parsing error")
            return false
        }
        
    }
    
    // save init redeem card onto local storage
    func saveInitCouponJSONData() -> [String:Any]{
        let data = [String: Any]()
        let jsonStr: String = self.JSONStringify(data)
        UserDefaults.standard.set(jsonStr, forKey: "couponData")
        return data
    }
    
    // MARK: PRK
    func proximityKitDidSync(_ manager: RPKManager!) {
        
    }
    
    func proximityKit(_ manager: RPKManager!, didEnter region: RPKRegion!) {
        
    }
    
    func proximityKit(_ manager: RPKManager!, didRangeBeacons beacons: [Any]!, in region: RPKBeaconRegion!) {
        
    }
}

