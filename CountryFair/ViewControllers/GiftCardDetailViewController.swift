//
//  GiftCardDetailViewController.swift
//  CountryFair
//
//  Created by MyMac on 6/22/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class GiftCardDetailViewController: UIViewController {
    
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var scrollPreView: UIScrollView!

    var previewItem : [String : Any]!
    var avPlayer: AVPlayer!
    var imageView : UIImageView!
    var playerLayer : AVPlayerLayer!
    var singleTap : UITapGestureRecognizer!
    override func viewDidLoad() {
        super.viewDidLoad()
        singleTap = UITapGestureRecognizer(target: self, action: #selector(GiftCardDetailViewController.imageViewTaped))
        singleTap.numberOfTapsRequired = 1 // you can change this value
        
        imageAndVideoDisplay()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @objc  func imageViewTaped() {
        if (avPlayer != nil) {
            if ((avPlayer.currentItem != nil) && avPlayer.rate == 1.0) {
                avPlayer.rate = 0.0
            }
        }
        self.dismiss(animated: true, completion: nil)
//        _ = navigationController?.popViewController(animated: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        if UIDevice.current.orientation.isLandscape {
            print("landscape state")
            convertedImageAndVideoDisplay()
        } else {
            print("portrite state")
            convertedImageAndVideoDisplay()
        }
    }
    
    func imageAndVideoDisplay() {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        guard let fileName : String = previewItem["fileName"] as? String else {
            return
        }
        
        let filePath = String.init(format: "%@/%@", documentPath, fileName)
        
        if fileName.range(of: "mp4") == nil {
            if (self.imageView != nil) {
                self.imageView.removeFromSuperview()
            }
            let imageFile = UIImage.init(contentsOfFile: filePath)
            if ((imageFile?.size.width)! < self.view.frame.width) {
                
                if ((imageFile?.size.height)! < self.view.frame.height) {
                    self.imageView = UIImageView(frame: CGRect(
                        x: self.scrollPreView.frame.origin.x + ((self.view.frame.width - (imageFile?.size.width)!) / 2)
                        ,y: self.scrollPreView.frame.origin.y + ((self.view.frame.height - (imageFile?.size.height)!) / 2)
                        ,width: (imageFile?.size.width)!
                        ,height: (imageFile?.size.height)!))
                } else {
                    self.imageView = UIImageView(frame: CGRect(
                        x: self.scrollPreView.frame.origin.x + ((self.view.frame.width - (imageFile?.size.width)!) / 2)
                        ,y: self.scrollPreView.frame.origin.y
                        ,width: (imageFile?.size.width)!
                        ,height: (imageFile?.size.height)!))
                }
                
                self.scrollPreView.contentSize = CGSize(width: self.view.frame.width, height: (imageFile?.size.height)!)
                
            } else {
                self.imageView = UIImageView(frame: CGRect(
                    x: self.scrollPreView.frame.origin.x
                    ,y: self.scrollPreView.frame.origin.y
                    ,width: self.view.frame.width
                    ,height: (imageFile?.size.height)! * (self.view.frame.width / (imageFile?.size.width)!)))
                
                self.scrollPreView.contentSize = CGSize(width: self.view.frame.width, height: (imageFile?.size.height)! * (self.view.frame.width / (imageFile?.size.width)!))
                
            }
            self.imageView.isUserInteractionEnabled = true
            self.imageView.addGestureRecognizer(singleTap)
            self.imageView.image = imageFile
            self.scrollPreView.addSubview(self.imageView)
        } else {
            //            let videoURL = NSURL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
            let videoURL = NSURL(fileURLWithPath: filePath)
            
            if (self.playerLayer != nil) {
                self.playerLayer.removeFromSuperlayer()
            }
            if (self.avPlayer == nil) {
                avPlayer = AVPlayer(url: videoURL as URL)
            }
            
            playerLayer = AVPlayerLayer(player: avPlayer)
            playerLayer.frame = CGRect(x: self.scrollPreView.frame.origin.x, y: self.scrollPreView.frame.origin.y, width: self.view.frame.width, height: self.view.frame.height)
            self.scrollPreView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height)
            self.scrollPreView.layer.addSublayer(playerLayer)
            
            self.imageView = UIImageView(frame: CGRect(
                x: self.scrollPreView.frame.origin.x
                ,y: self.scrollPreView.frame.origin.y
                ,width: self.view.frame.width
                ,height: self.view.frame.height))
            self.imageView.isUserInteractionEnabled = true
            self.imageView.addGestureRecognizer(singleTap)
            self.scrollPreView.addSubview(self.imageView)
            avPlayer.play()
        }
    }
    
    func convertedImageAndVideoDisplay() {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileName : String = previewItem["fileName"] as! String
        let filePath = String.init(format: "%@/%@", documentPath, fileName)
        
        if fileName.range(of: "mp4") == nil {
            if (self.imageView != nil) {
                self.imageView.removeFromSuperview()
            }
            let imageFile = UIImage.init(contentsOfFile: filePath)
            if ((imageFile?.size.width)! < self.view.frame.height) {
                
                if ((imageFile?.size.height)! < self.view.frame.width) {
                    self.imageView = UIImageView(frame: CGRect(
                        x: self.scrollPreView.frame.origin.x + ((self.view.frame.height - (imageFile?.size.width)!) / 2)
                        ,y: self.scrollPreView.frame.origin.y + ((self.view.frame.width - (imageFile?.size.height)!) / 2)
                        ,width: (imageFile?.size.width)!
                        ,height: (imageFile?.size.height)!))
                } else {
                    self.imageView = UIImageView(frame: CGRect(
                        x: self.scrollPreView.frame.origin.x + ((self.view.frame.height - (imageFile?.size.width)!) / 2)
                        ,y: self.scrollPreView.frame.origin.y
                        ,width: (imageFile?.size.width)!
                        ,height: (imageFile?.size.height)!))
                }
                
                self.scrollPreView.contentSize = CGSize(width: self.view.frame.width, height: (imageFile?.size.height)!)
                
            } else {
                self.imageView = UIImageView(frame: CGRect(
                    x:  self.scrollPreView.frame.origin.x
                    ,y: self.scrollPreView.frame.origin.y
                    ,width: self.view.frame.height
                    ,height: (imageFile?.size.height)! * (self.view.frame.height / (imageFile?.size.width)!)))
                
                self.scrollPreView.contentSize = CGSize(width: self.view.frame.height, height: (imageFile?.size.height)! * (self.view.frame.height / (imageFile?.size.width)!))
                
            }
            self.imageView.isUserInteractionEnabled = true
            self.imageView.addGestureRecognizer(singleTap)
            self.imageView.image = imageFile
            self.scrollPreView.addSubview(self.imageView)
        } else {
            //            let videoURL = NSURL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
            let videoURL = NSURL(fileURLWithPath: filePath)
            
            if (self.playerLayer != nil) {
                self.playerLayer.removeFromSuperlayer()
            }
            if (self.avPlayer == nil) {
                avPlayer = AVPlayer(url: videoURL as URL)
            }
            
            playerLayer = AVPlayerLayer(player: avPlayer)
            playerLayer.frame = CGRect(x: self.scrollPreView.frame.origin.x, y: self.scrollPreView.frame.origin.y, width: self.view.frame.height, height: self.view.frame.width)
            self.scrollPreView.contentSize = CGSize(width: self.view.frame.height, height: self.view.frame.width)
            self.scrollPreView.layer.addSublayer(playerLayer)
            
            self.imageView = UIImageView(frame: CGRect(
                x: self.scrollPreView.frame.origin.x
                ,y: self.scrollPreView.frame.origin.y
                ,width: self.view.frame.height
                ,height: self.view.frame.width))
            self.imageView.isUserInteractionEnabled = true
            self.imageView.addGestureRecognizer(singleTap)
            self.scrollPreView.addSubview(self.imageView)
            
            avPlayer.play()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
