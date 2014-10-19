//
//  VideoCaptureViewController.swift
//  Filterama
//
//  Created by Alex G on 16.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit
import AVFoundation

class VideoCaptureViewController: UIViewController {
    // MARK: Public Properties
    weak var delegate: PickerViewControllerDelegate?
    
    // MARK: Private Properties
    private var stillImageOutput = AVCaptureStillImageOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureSession = AVCaptureSession()
    private var imageOriginalData: NSData?
    private var input: AVCaptureDeviceInput!
    
    // MARK: Outlets
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    
    // MARK: Actions
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func choose(sender: AnyObject) {
        if let delegate = delegate {
            delegate.pickerVC(self, selectedImageData: imageOriginalData)
        }
    }
    
    @IBAction func takePicture(sender: AnyObject) {
        var videoConnection: AVCaptureConnection!
        outerLoop: for connection in stillImageOutput.connections {
            // Find a proper connection
            if let cameraConnection = connection as? AVCaptureConnection {
                for port in cameraConnection.inputPorts {
                    if let videoPort = port as? AVCaptureInputPort {
                        if videoPort.mediaType == AVMediaTypeVideo {
                            videoConnection = cameraConnection
                            break outerLoop
                        }
                    }
                }
            }
        }
        
        if videoConnection == nil {
            UIAlertView(title: "Error", message: "Something bad happened with videoConnection", delegate: nil, cancelButtonTitle: "OK")
            return
        }
        
        // Detecting orientation of camera
        var newOrientation: AVCaptureVideoOrientation
        switch UIDevice.currentDevice().orientation {
            case .PortraitUpsideDown:
                newOrientation = .PortraitUpsideDown;
                break;
            case .LandscapeLeft:
                newOrientation = .LandscapeRight;
                break;
            case .LandscapeRight:
                newOrientation = .LandscapeLeft;
                break;
            default:
                newOrientation = .Portrait;
        }
        
        println(newOrientation.toRaw())
        
        videoConnection.videoOrientation = newOrientation
        
        self.activityIndicator.startAnimating()
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(buffer : CMSampleBuffer!, error : NSError!) -> Void in
            // Boooooooo!
            self.imageOriginalData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
            if self.imageOriginalData != nil {
                ThumbnailGenerator.generateThumbnailFromData(self.imageOriginalData, size: 64, completion: { (thumbnailImage) -> Void in
                    self.previewImageView.image = thumbnailImage
                    self.activityIndicator.stopAnimating()
                })
            }
        })
        
    }
    
    // MARK: UIViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.bounds = captureView.bounds
        previewLayer.position = CGPointMake(0.5 * previewLayer.bounds.width, 0.5 * previewLayer.bounds.height);
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        captureView.layer.addSublayer(previewLayer)
    }
    
    override func viewDidAppear(animated: Bool) {
        var device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var error : NSError?
        if input == nil {
            input = AVCaptureDeviceInput.deviceInputWithDevice(device, error: &error) as AVCaptureDeviceInput!
            if input == nil {
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    UIAlertView(title: "Error", message: "Can't initialize camera", delegate: nil, cancelButtonTitle: "OK").show()
                })
                return
            }
            captureSession.addInput(input)
            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            captureSession.addOutput(self.stillImageOutput)
            captureSession.startRunning()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        imageOriginalData = nil
        previewImageView.image = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLayoutSubviews() {
        let newSize = captureView.bounds.size;
        previewLayer.position = CGPointMake(0.5 * newSize.width, 0.5 * newSize.height);
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut));
        updatePreviewLayerForOrientation(toInterfaceOrientation);
        CATransaction.commit();
    }
    
    func updatePreviewLayerForOrientation(interfaceOrientation: UIInterfaceOrientation)
    {
        // Correct position of previewLayer
        let newSize = captureView.bounds.size;
        previewLayer.position = CGPointMake(0.5 * newSize.width, 0.5 * newSize.height);
        var angle: Double!
        // Rotate the previewLayer, in order to have camera picture right
        switch interfaceOrientation {
            case .Portrait:
                angle = 0
            case .LandscapeLeft:
                angle = M_PI/2
            case .LandscapeRight:
                angle = -M_PI/2
            default: // .PortraitUpsideDown
                angle = M_PI
        }
        
        previewLayer.setAffineTransform(CGAffineTransformMakeRotation(CGFloat(angle)))
    }
}
