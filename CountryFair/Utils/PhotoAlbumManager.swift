//
//  PhotoAlbumManager.swift
//  CountryFair
//
//  Created by Micky on 8/20/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation
import Photos

class PhotoAlbumManager: NSObject {
    
    static let shared = PhotoAlbumManager()
    
    private override init() {
        super.init()
    }
    
    func createAlbum(name: String!, completionHandler:@escaping (_ success: Bool, _ error: Error?) -> ()) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        }) { success, error in
            completionHandler(success, error)
        }
    }
    
    func fetchAssetCollectionForAlbum(name: String!) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }
    
    func save(isImage: Bool, path: String!, albumName: String!, completionHandler:((_ success: Bool, _ error: Error?, _ assetIdentifier: String?) -> Void)? = nil) {
        let assetCollection = fetchAssetCollectionForAlbum(name: albumName)
        if assetCollection == nil {
            createAlbum(name: albumName, completionHandler: { (success, error) in
                let assetCollection = self.fetchAssetCollectionForAlbum(name: albumName)
                self.save(isImage: isImage, path: path, assetCollection: assetCollection, completionHandler: completionHandler)
            })
        } else {
            save(isImage: isImage, path: path, assetCollection: assetCollection, completionHandler: completionHandler)
        }
    }
    
    func delete(assetIdentifier: String!, completionHandler:((_ success: Bool, _ error: Error?) -> Void)? = nil) {
        PHPhotoLibrary.shared().performChanges({
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            PHAssetChangeRequest.deleteAssets(assets)
        }) { (success, error) in
            DispatchQueue.main.async {
                completionHandler?(success, error)
            }
        }
    }
    
    fileprivate func save(isImage: Bool, path: String!, assetCollection: PHAssetCollection!, completionHandler: ((_ success: Bool, _ error: Error?, _ assetIdentifier: String?) -> Void)? = nil) {
        var localIdentifier: String?
        PHPhotoLibrary.shared().performChanges({
            let url = URL(fileURLWithPath: path)
            let assetChangeRequest = isImage ? PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url) : PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            let assetPlaceHolder = assetChangeRequest?.placeholderForCreatedAsset
            localIdentifier = assetPlaceHolder?.localIdentifier
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
            let enumeration: NSArray = [assetPlaceHolder!]
            
            if assetCollection.estimatedAssetCount == 0 {
                albumChangeRequest!.addAssets(enumeration)
            } else {
                albumChangeRequest!.insertAssets(enumeration, at: [0])
            }
            
        }, completionHandler: { success , error in
            DispatchQueue.main.async {
                completionHandler?(success, error, localIdentifier)
            }
        })
    }
}
