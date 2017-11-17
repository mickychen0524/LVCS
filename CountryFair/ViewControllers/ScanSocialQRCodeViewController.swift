//
//  ScanSocialQRCodeViewController.swift
//  CountryFair
//
//  Created by MyMac on 7/3/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class ScanSocialQRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var qrcodePreview: UIView!
    @IBOutlet weak var noThxBtn: UIButton!
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var alertState:Bool?
    var resultStr:String = ""
    
    // Added to support different barcodes
    let supportedBarCodes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.aztec]
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertState = false
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Detect all the supported bar code
            captureMetadataOutput.metadataObjectTypes = supportedBarCodes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = self.qrcodePreview.layer.bounds
            print(videoPreviewLayer?.frame.width)
            print(videoPreviewLayer?.frame.height)
            self.qrcodePreview.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession?.startRunning()
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                self.qrcodePreview.addSubview(qrCodeFrameView)
                self.qrcodePreview.bringSubview(toFront: qrCodeFrameView)
            }
            
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
    
    @IBAction func noThxBtnAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
//        self.config.writeValue(true as AnyObject!, forKey: "scanSocialImageState", toStore: "settings")
//        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
//        if let vc : SnapContainerViewController = mainStoryboard.instantiateViewController(withIdentifier: "snapContainerViewController") as? SnapContainerViewController {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                //                    self.navigationController?.pushViewController(vc, animated: true)
//                self.present(vc, animated: true, completion: nil)
//            }
//        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // Here we use filter method to check if the type of metadataObj is supported
        // Instead of hardcoding the AVMetadataObjectTypeQRCode, we check if the type
        // can be found in the array of supported bar codes.
        if supportedBarCodes.contains(metadataObj.type) {
            //        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                
                if (!alertState!){
                    
                    // spile and check the checkout refID format from scaned data
                    let length: Int = (metadataObj.stringValue?.length)!
                    if (length > 40) {
                        self.view.makeToast(metadataObj.stringValue!)
                        self.config.writeValue(true as AnyObject!, forKey: "scanSocialImageState", toStore: "settings")
                        config.writeValue(metadataObj.stringValue as AnyObject!, forKey: "SocialXGetYLicenseCodes", toStore: "settings")
                        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                        if let vc : SnapContainerViewController = mainStoryboard.instantiateViewController(withIdentifier: "snapContainerViewController") as? SnapContainerViewController {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                //                    self.navigationController?.pushViewController(vc, animated: true)
                                self.present(vc, animated: true, completion: nil)
                            }
                        }
                        
                    } else {
                        
                        // vibration and any sound
                        AudioServicesPlayAlertSound(SystemSoundID(1304))
                        self.view.makeToast("INVALID SCAN")
                        
                        
                    }
                    
                    
                }
                
                
            }
        }
    }

}
