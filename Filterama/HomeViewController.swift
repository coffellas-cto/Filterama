//
//  HomeViewController.swift
//  Filterama
//
//  Created by Alex G on 13.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit
import CoreImage
import CoreData

let kFilterThumbnailGenerationOptionKeyImagePath = "imagePath"
let kFilterThumbnailGenerationOptionKeyImage = "image"

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GalleryViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: Private Properties
    private var innerGalleryVC: GalleryViewController?
    private var filtersActive = false
    private var thumbnailFiltersOriginal: UIImage?
    lazy private var fetchedResultsControllerFilters: NSFetchedResultsController! = {
        var request = NSFetchRequest(entityName: "Filter")
        request.sortDescriptors = [NSSortDescriptor(key: "idx", ascending: true)]
        var retVal = NSFetchedResultsController(fetchRequest: request, managedObjectContext: PersistenceManager.manager.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        var error: NSError?
        retVal.performFetch(&error)
        assert(error == nil, "\(error?.localizedDescription)")
        return retVal
    }()
    
    // MARK: IBOutlets
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var showFiltersButton: UIButton!
    @IBOutlet weak var activityIndicatorImage: UIActivityIndicatorView!
    
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
        constraintHeightFilterCollectionView.constant = filtersActive ? 0 : 100
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
    
    private func generateFilterThumbnailWithOptions(options: NSDictionary) {
        thumbnailFiltersOriginal = nil
        if self.filtersActive {
            self.filterCollectionView.reloadData()
        }
        
        var completionFunction = { (thumbnailImage: UIImage?) -> Void in
            self.thumbnailFiltersOriginal = thumbnailImage
            if self.filtersActive {
                self.filterCollectionView.reloadData()
            }
        }
        
        if let imagePath = options[kFilterThumbnailGenerationOptionKeyImagePath] as? String {
            ThumbnailGenerator.generateThumbnailFromFileAtPath(imagePath, size: 60) { (thumbnailImage) -> Void in
                completionFunction(thumbnailImage)
            }
        }
        else if let image = options[kFilterThumbnailGenerationOptionKeyImage] as? UIImage {
            ThumbnailGenerator.generateThumbnailForImage(image, size: 60, completion: { (thumbnailImage) -> Void in
                completionFunction(thumbnailImage)
            })
        }
    }
    
    // MARK: UIImagePickerControllerDelegate Methods
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        activityIndicatorImage.startAnimating()
        picker.dismissViewControllerAnimated(true, completion: nil)
        var selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage
        if selectedImage == nil {
            selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        
        if selectedImage == nil {
            println("Error. Couldn't load image from UIImagePickerController")
            return
        }
        
        generateFilterThumbnailWithOptions([kFilterThumbnailGenerationOptionKeyImage: selectedImage!])
        
        ThumbnailGenerator.generateThumbnailForImage(selectedImage, size: self.imageView.frame.width) { (thumbnailImage) -> Void in
            self.imageView.image = selectedImage
            self.activityIndicatorImage.stopAnimating()
        }
    }
    
    // MARK: GalleryViewControllerDelegate Methods
    
    func galleryVC(galleryVC: GalleryViewController, selectedImagePath: String) {
        activityIndicatorImage.startAnimating()
        galleryVC.dismissViewControllerAnimated(true, completion: nil)
        ThumbnailGenerator.generateThumbnailFromFileAtPath(selectedImagePath, size: self.imageView.frame.width, completion: { (thumbnailImage) -> Void in
            self.imageView.image = thumbnailImage
            self.activityIndicatorImage.stopAnimating()
        })
        
        generateFilterThumbnailWithOptions([kFilterThumbnailGenerationOptionKeyImagePath: selectedImagePath])
    }
    
    // MARK: UICollectionView Delegates Methods
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FILTER_CELL", forIndexPath: indexPath) as FilterCell
        cell.imageView.image = thumbnailFiltersOriginal
        
        let filter = fetchedResultsControllerFilters?.objectAtIndexPath(indexPath) as Filter
        cell.titleLabel.text = filter.friendlyName
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsControllerFilters.fetchedObjects!.count
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
        activityIndicatorImage.layer.cornerRadius = imageView.layer.cornerRadius
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

}
