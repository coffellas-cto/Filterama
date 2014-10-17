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

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PickerViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: Private Properties
    lazy private var innerGalleryVC: PickerViewController! = {
        var innerGalleryVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("GALLERY_VC") as? PickerViewController
        innerGalleryVC?.delegate = self
        return innerGalleryVC
    }()
    lazy private var photoFrameworkVC: PickerViewController! = {
        var photoFrameworkVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("GALLERY_VC") as PickerViewController!
        photoFrameworkVC.delegate = self
        photoFrameworkVC.mode = PickerViewControllerMode.PhotosFramework
        return photoFrameworkVC
    }()
    lazy var videoCaptureVC: VideoCaptureViewController! = {
        var videoCaptureVC = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("VIDEOCAPTURE_VC") as VideoCaptureViewController!
        return videoCaptureVC
    }()
    private var filtersActive = false
    private var mainImageOriginal: UIImage?
    private var thumbnailFilterImageOriginal: UIImage?
    private var thumbnailFilterImages = [Int: UIImage]()
    private var coreImageContext: CIContext!
    lazy private var fetchedResultsControllerFilters: NSFetchedResultsController! = {
        var request = NSFetchRequest(entityName: "Filter")
        request.sortDescriptors = [NSSortDescriptor(key: "idx", ascending: true)]
        var retVal = NSFetchedResultsController(fetchRequest: request, managedObjectContext: PersistenceManager.manager.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        var error: NSError?
        retVal.performFetch(&error)
        assert(error == nil, "\(error?.localizedDescription)")
        return retVal
    }()
    
    lazy private var filtersArray: [CIFilter]! = {
        var retVal = [CIFilter]()
        for filterManagedObject in self.fetchedResultsControllerFilters.fetchedObjects! as [Filter] {
            var curFilter = CIFilter(name: filterManagedObject.name)
            curFilter.setDefaults()
            retVal.append(curFilter)
        }
        
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
            self.presentViewController(self.innerGalleryVC, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Photos (Ph. Framework)", style: .Default, handler: { (action) -> Void in
            let sideSize = self.imageView.frame.width
            self.photoFrameworkVC.assetSizeFinal = CGSize(width: sideSize, height: sideSize)
            self.presentViewController(self.photoFrameworkVC, animated: true, completion: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Camera (AV Foundation)", style: .Default, handler: { (action) -> Void in
            self.presentViewController(self.videoCaptureVC, animated: true, completion: nil)
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
        thumbnailFilterImageOriginal = nil
        thumbnailFilterImages = [Int: UIImage]()
        
        if self.filtersActive {
            self.filterCollectionView.reloadData()
        }
        
        var completionFunction = { (thumbnailImage: UIImage?) -> Void in
            self.thumbnailFilterImageOriginal = thumbnailImage
            
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
    
    private func filteredImageWithFilter(filter: CIFilter, image: UIImage!) -> UIImage? {
        if image == nil {
            return nil
        }
        
        if let coreImageOriginal = CIImage(image: image) as CIImage? {
            filter.setValue(coreImageOriginal, forKey: kCIInputImageKey)
            if let coreImageFiltered = filter.valueForKey(kCIOutputImageKey) as CIImage? {
                var imageRef = self.coreImageContext.createCGImage(coreImageFiltered, fromRect: coreImageOriginal.extent())
                return UIImage(CGImage: imageRef)
            }
        }
        
        return image
    }
    
    private func setMainImage(image: UIImage?) {
        self.mainImageOriginal = image
        self.imageView.image = image
        self.activityIndicatorImage.stopAnimating()
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
            self.setMainImage(thumbnailImage)
        }
    }
    
    // MARK: PickerViewControllerDelegate Methods
    
    func galleryVC(galleryVC: PickerViewController, selectedImagePath: String) {
        activityIndicatorImage.startAnimating()
        galleryVC.dismissViewControllerAnimated(true, completion: nil)
        ThumbnailGenerator.generateThumbnailFromFileAtPath(selectedImagePath, size: self.imageView.frame.width, completion: { (thumbnailImage) -> Void in
            self.setMainImage(thumbnailImage)
        })
        
        generateFilterThumbnailWithOptions([kFilterThumbnailGenerationOptionKeyImagePath: selectedImagePath])
    }
    
    func galleryVC(galleryVC: PickerViewController, selectedImage: UIImage?) {
        activityIndicatorImage.startAnimating()
        galleryVC.dismissViewControllerAnimated(true, completion: nil)
        
        if selectedImage == nil {
            activityIndicatorImage.stopAnimating()
            return
        }
        
        ThumbnailGenerator.generateThumbnailForImage(selectedImage, size: self.imageView.frame.width) { (thumbnailImage) -> Void in
            self.setMainImage(thumbnailImage)
        }
        
        generateFilterThumbnailWithOptions([kFilterThumbnailGenerationOptionKeyImage: selectedImage!])
    }
    
    // MARK: UICollectionView Delegates Methods
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FILTER_CELL", forIndexPath: indexPath) as FilterCell
        
        let filterManagedObject = fetchedResultsControllerFilters?.objectAtIndexPath(indexPath) as Filter
        cell.titleLabel.text = filterManagedObject.friendlyName
        cell.imageView.image = thumbnailFilterImageOriginal
        
        if let filteredImage = thumbnailFilterImages[indexPath.row] {
            cell.imageView.image = filteredImage
        }
        else if thumbnailFilterImageOriginal != nil {
            
            if coreImageContext == nil {
                coreImageContext = CIContext(EAGLContext: EAGLContext(API: EAGLRenderingAPI.OpenGLES2), options: [kCIContextWorkingColorSpace: NSNull()])
            }
            // Must get filter on main thread, as it's lazy, thus not thread-safe
            var curFilter = self.filtersArray[indexPath.row]
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                var filteredImage = self.filteredImageWithFilter(curFilter, image: self.thumbnailFilterImageOriginal)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.thumbnailFilterImages[indexPath.row] = filteredImage
                    if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? FilterCell {
                        cell.imageView.image = filteredImage
                    }
                })
            })
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsControllerFilters.fetchedObjects!.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        activityIndicatorImage.startAnimating()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let filteredImage = self.filteredImageWithFilter(self.filtersArray[indexPath.row], image: self.mainImageOriginal)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if filteredImage != nil {
                    self.imageView.image = filteredImage
                }
                self.activityIndicatorImage.stopAnimating()
            })
        })
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
