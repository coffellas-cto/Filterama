//
//  HomeViewController.swift
//  Filterama
//
//  Created by Alex G on 13.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GalleryViewControllerDelegate {
    
    var innerGalleryVC: GalleryViewController?
    // MARK: IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // MARK: IBActions
    
    @IBAction func loadPicture(sender: AnyObject) {
        var alertController = UIAlertController(title: "Choose an option", message: "", preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Filterama Pictures", style: .Default, handler: { (action) -> Void in
            if self.innerGalleryVC == nil {
                self.innerGalleryVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("GALLERY_VC") as? GalleryViewController
                self.innerGalleryVC?.delegate = self
            }
            self.presentViewController(self.innerGalleryVC!, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Photo Library", style: .Default, handler: { (action) -> Void in
            self.showPickerViewWithSourceType(.PhotoLibrary)
        }))
        alertController.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { (action) -> Void in
            self.showPickerViewWithSourceType(.Camera)
            }))
        alertController.addAction(UIAlertAction(title: "Saved Photos", style: .Default, handler: { (action) -> Void in
            self.showPickerViewWithSourceType(.SavedPhotosAlbum)
        }))
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            alertController.modalPresentationStyle = .Popover
            alertController.popoverPresentationController?.sourceView = loadButton
            alertController.popoverPresentationController?.sourceRect = loadButton.bounds
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: Private Methods
    
    private func showPickerViewWithSourceType(type: UIImagePickerControllerSourceType) {
        if !UIImagePickerController.isSourceTypeAvailable(type) {
            self.showAlertForUnexistingSourceType(type)
            return
        }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = type
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    private func showAlertForUnexistingSourceType(type: UIImagePickerControllerSourceType) {
        var typeString: String!
        switch type {
        case .PhotoLibrary:
            typeString = "Photo Library"
        case .Camera:
            typeString = "Camera"
        default:
            typeString = "Saved Photos Album"
        }
        
        UIAlertView(title: "Error", message: "\(typeString) source is not available", delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    // MARK: UIImagePickerControllerDelegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        activityIndicator.startAnimating()
        imageView.backgroundColor = UIColor.blackColor()
        picker.dismissViewControllerAnimated(true, completion: nil)
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageView.image = selectedImage
        }
        else if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = selectedImage
        }
        
        activityIndicator.stopAnimating()
    }
    
    // MARK: GalleryViewControllerDelegate Methods
    
    func galleryVC(galleryVC: GalleryViewController, selectedImagePath: String) {
        activityIndicator.startAnimating()
        self.imageView.backgroundColor = UIColor.blackColor()
        galleryVC.dismissViewControllerAnimated(true, completion: nil)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let image = UIImage(contentsOfFile: selectedImagePath)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.imageView.image = image
                self.activityIndicator.stopAnimating()
            })
        })
    }
    
    // MARK: UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
