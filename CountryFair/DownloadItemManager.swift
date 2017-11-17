//
//  DonwloadItemManager.swift
//  CountryFair
//
//  Created by admin on 8/17/17.
//  Copyright © 2017 ATM. All rights reserved.
//

typealias DownloadProgress = (Double) -> Void
typealias DownloadSuccess = (Data) -> Void
typealias DownloadFailed = (Error) -> Void

import Foundation
import Alamofire

class DownloadItem : Hashable, Equatable {
    
    var fileName:String? = String()
    var downloadedData:Data? = Data()
    var downloadURL:String? = String()
    var isDownloading:Bool? = nil
    
    public init(_ fileName:String,_ _downloadURL:String?) {
        self.fileName = fileName
        self.downloadURL = _downloadURL
    }
    
    var hashValue: Int {
        return (fileName?.hashValue)! + (downloadedData?.hashValue)! + (downloadURL?.hashValue)! + (isDownloading?.hashValue)!
    }
    
    public static func ==(item1: DownloadItem, item2: DownloadItem) -> Bool {
        if (item1.downloadURL == item2.downloadURL && item1.downloadedData == item2.downloadedData &&
            item1.fileName == item2.fileName && item1.isDownloading == item2.isDownloading) {
            return true
        }
        return false
    }
}

protocol DownloadItemDelegate {
    func downloadProgress(progress:Double,fileName:String) -> Void;
    func downloadSuccess(entityData:Data,fileName:String) -> Void;
    func downloadFailed(error:Error,fileName:String) -> Void;
}

class DownloadItemManager : URLSession {
    
    public var manager: Alamofire.SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpMaximumConnectionsPerHost = 100
        let manager = Alamofire.SessionManager(
            configuration: URLSessionConfiguration.default
        )
        return manager
    }()
    
    fileprivate var session:SessionManager!
    
    public static let sharedManager = DownloadItemManager()
    public var downloadItems:[DownloadItem] = [DownloadItem]()
    public var delegateManager:DownloadItemDelegate?
    
    private override init() {
         super.init()
    }
    
    public func downloadItem(fileName:String, progressClosure:((Double) -> Swift.Void)? = nil, success: ((Data) -> Swift.Void)? = nil, failed: ((Error) -> Swift.Void)? = nil) {
        
        let downloadItem = self.getDownloadItem(withName: fileName)
        
        if downloadItem != nil, let fileURL = downloadItem?.downloadURL, downloadItem?.isDownloading == nil {
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsURL.appendingPathComponent(fileName)
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            self.editDownloadItem(forURL: fileURL, data: nil, load: false)
            
            let app = UIApplication.shared
            app.beginBackgroundTask(expirationHandler: {})
            
            manager.download(fileURL, method: .get, parameters: nil, to: destination)
                .downloadProgress { progress in
                    let progressItem:Double = progress.fractionCompleted
                    self.delegateManager?.downloadProgress(progress: progressItem, fileName: fileName)
                    if progressClosure != nil {
                        progressClosure!(progressItem)
                    }
                }.responseData { response in
                    guard let _ = response.request else {return}
                    let requestURL:String = (response.request?.url!.absoluteString)!
                    if let data = response.result.value {
                        self.editDownloadItem(forURL: requestURL, data: data, load:true)
                        self.delegateManager?.downloadSuccess(entityData: data, fileName: fileName)
                        if success != nil {
                            success!(data)
                        } else {
                            let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                            let filePath : String = String.init(format: "%@/%@", documentPath, fileName)
                            let isImage = UIImage(data: data) != nil
                            let albumName = "My Coupons"
                            PhotoAlbumManager.shared.save(isImage: isImage, path: filePath, albumName: albumName, completionHandler: nil)
                        }
                    } else {
                        self.delegateManager?.downloadFailed(error: response.result.error!, fileName: fileName)
                        if failed != nil {
                            failed!(response.result.error!)
                        }
                    }
            }
        } else if downloadItem != nil, let flag = downloadItem?.isDownloading, flag, let data = downloadItem?.downloadedData, progressClosure != nil, success != nil {
            progressClosure!(1.0)
            success!(data)
        } else {
//            self.downloadItem(fileName: fileName, progressClosure: progressClosure, success: success, failed: failed)
        }
    }
    
    public func getDownloadedItem(fileName:String, progressClosure:@escaping DownloadProgress, success:@escaping DownloadSuccess, failed:@escaping DownloadFailed) {
        let downloadItem = self.getDownloadItem(withName: fileName)
        if downloadItem != nil, let flag = downloadItem?.isDownloading, flag, let data = downloadItem?.downloadedData {
            progressClosure(1.0)
            success(data)
        } else {
            self.downloadItem(fileName: fileName, progressClosure: progressClosure, success: success, failed: failed)
        }
    }
    
    public func addDownloadEntity(_ fileName:String, _ fileURL:String) -> Bool {
        if !self.isExistEntity(fileName) {
            self.downloadItems.append(DownloadItem(fileName, fileURL))
            return true
        } else {
            return false
        }
    }
    
    public func editDownloadItem(forURL requestURL:String, data:Data?, load:Bool) {
        self.downloadItems = self.downloadItems.map({
            if ($0.downloadURL == requestURL) {
                $0.downloadedData = data
                $0.isDownloading = load
            }
            return $0
        })
    }
    
    private func removeDownloadItem(withName fileName:String) -> [DownloadItem] {
        return self.downloadItems.filter({$0.fileName != fileName})
    }
    
    private func removeDownloadItem(fromURL fileURL:String) -> [DownloadItem] {
        return self.downloadItems.filter({$0.downloadURL != fileURL})
    }
    
    public func getDownloadItem(withName fileName:String) -> DownloadItem? {
        if downloadItems.count > 0, let temp = self.downloadItems.first(where: {$0.fileName == fileName}) {
            return temp
        }
        return nil
    }
    
    private func getDownloadItem(fromURL fileURL:String) -> DownloadItem? {
        if let temp = self.downloadItems.filter({$0.downloadURL! == fileURL}).first {
            return temp
        }
        return nil
    }
    
    private func isExistEntity(_ fileName:String) -> Bool {
        return self.downloadItems.filter({$0.fileName == fileName}).count > 0
    }
}
