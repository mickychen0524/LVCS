//
//  ScanReceiptViewController.swift
//  CountryFair
//
//  Created by MyMacBook on 7/14/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import AVFoundation

class ScanReceiptViewController: UIViewController {

    @IBOutlet weak var receiptPreview: UIView!
    @IBOutlet weak var retakePhotoBtn: UIButton!
    @IBOutlet weak var shootPhotoBtn: UIButton!
    
    var captureSession = AVCaptureSession()
    let stillImageOutput = AVCaptureStillImageOutput()
    var error: NSError?
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            // Set the input device on the capture session.
            captureSession.addInput(input)
            captureSession.sessionPreset = AVCaptureSession.Preset.photo
            captureSession.startRunning()
            stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = self.receiptPreview.layer.bounds
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.receiptPreview.layer.addSublayer(previewLayer)
        } catch {
        // If any error occurs, simply print it out and don't continue any more.
        print(error)
        return
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func retakePhotoBtnAction(_ sender: Any) {
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)
                UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData!)!, nil, nil, nil)
                self.getUploadingUrl(imageData: imageData!)
            }
        }
    }
    
    @IBAction func shootPhotoBtnAction(_ sender: Any) {
        if let videoConnection = stillImageOutput.connection(with: AVMediaType.video) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)
                UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData!)!, nil, nil, nil)
                self.getUploadingUrl(imageData: imageData!)
            }
        }
    }
    
    @IBAction func doneBtnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func getUploadingUrl(imageData : Data) {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Uploading..."
        let value = [String: Any]()
        AlamofireRequestAndResponse.sharedInstance.getReceiptUploadUrl(value, success: { (res: [String: Any]) -> Void in
            if let resData = res["data"] as? String {
                print(resData)
                self.uploadReceiptImg(toStorage: resData, imageData : imageData)
            }
        },
        failure: { (error: [String: Any]!) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Receipt image uploading error", style: AlertStyle.error)
        })
    }
    
    func uploadReceiptImg(toStorage : String, imageData : Data) {
        
        AlamofireRequestAndResponse.sharedInstance.uploadReceiptImage(toStorage, data: imageData, success: { (res: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Success!".localized(), subTitle: "Receipt image uploading success", style: AlertStyle.success)
        },
        failure: { (error: Error!) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
              _ = SweetAlert().showAlert("Error!".localized(), subTitle: "Receipt image uploading error", style: AlertStyle.error)
        })
    }

}
