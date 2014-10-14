//
//  HomeViewController.swift
//  Filterama
//
//  Created by Alex G on 13.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit
import CoreImage

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GalleryViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: Private Properties
    private var innerGalleryVC: GalleryViewController?
    private var filtersActive = false
    private var thumbnailFiltersOriginal: UIImage?
    
    // MARK: IBOutlets
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var showFiltersButton: UIButton!
    
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

    @IBAction func showFilters(sender: AnyObject) {
        showFiltersButton.setTitle(filtersActive ? "Show filters" : "Hide filters", forState: .Normal)
        constraintHeightFilterCollectionView.constant = filtersActive ? 0 : 60
        if !filtersActive {
            filterCollectionView.reloadData()
        }
        
        filtersActive = !filtersActive
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    // MARK: Constraints
    
    @IBOutlet weak var constraintHeightFilterCollectionView: NSLayoutConstraint!
    
    // MARK: Private Methods
    
    private func setImage(image: UIImage) {
        imageView.image = image
        ThumbnailGenerator.generateThumbnailForImage(image, size: 30) { (thumbnailImage) -> Void in
            self.thumbnailFiltersOriginal = thumbnailImage
            if self.filtersActive {
                self.filterCollectionView.reloadData()
            }
        }
    }
    
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
        picker.dismissViewControllerAnimated(true, completion: nil)
        if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            setImage(selectedImage)
        }
        else if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            setImage(selectedImage)
        }
    }
    
    // MARK: GalleryViewControllerDelegate Methods
    
    func galleryVC(galleryVC: GalleryViewController, selectedImagePath: String) {
        galleryVC.dismissViewControllerAnimated(true, completion: nil)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let image = UIImage(contentsOfFile: selectedImagePath)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.setImage(image)
            })
        })
    }
    
    // MARK: UICollectionView Delegates Methods
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FILTER_CELL", forIndexPath: indexPath) as FilterCell
        cell.imageView.image = imageView.image
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    
    // MARK: UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filterCollectionView.delegate = self
        filterCollectionView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        imageView.layer.cornerRadius = imageView.frame.width / 2
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
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
