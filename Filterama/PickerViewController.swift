//
//  PickerViewController.swift
//  Filterama
//
//  Created by Alex G on 13.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit
import Photos

protocol PickerViewControllerDelegate : NSObjectProtocol {
    func galleryVC(galleryVC: PickerViewController, selectedImagePath: String)
    func galleryVC(galleryVC: PickerViewController, selectedImage: UIImage?)
}

enum PickerViewControllerMode {
    case Documents
    case PhotosFramework
}

class PickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    weak var delegate: PickerViewControllerDelegate?
    var mode: PickerViewControllerMode = .Documents
    var assetSizeFinal: CGSize = CGSizeZero
    
    private var assetFetchResults: PHFetchResult!
    private var imageManager: PHCachingImageManager!
    lazy private var imagesPathsArray: NSArray = {
        var retVal = NSMutableArray()
        let fileManager = NSFileManager.defaultManager()
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as NSString
        var error: NSError?
        if let fileNames = fileManager.contentsOfDirectoryAtPath(documentsDirectory, error: &error) as? [String] {
            for fileName in fileNames {
                retVal.addObject(documentsDirectory.stringByAppendingPathComponent(fileName))
            }
        }
        
        return retVal.filteredArrayUsingPredicate(NSPredicate(format: "pathExtension IN %@", ["jpg", "jpeg", "png", "tiff", "bmp"]))
    }()

    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    // MARK: Private Methods
    
    private func fetchSource() {
        activityIndicator.startAnimating()
        if mode == .PhotosFramework {
            self.assetFetchResults = PHAsset.fetchAssetsWithOptions(nil)
        }
        collection.reloadData()
        activityIndicator.stopAnimating()
    }
    
    // MARK: Public Methods
    
    func refreshSource(sender: UIRefreshControl) {
        fetchSource()
        sender.endRefreshing()
    }
    
    func pinched(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Ended {
            let multiplier: CGFloat = gesture.velocity > 0 ? 2.0 : 0.5
            
            let layout = collection.collectionViewLayout as UICollectionViewFlowLayout
            let sideSize = layout.itemSize.width * multiplier
            if (sideSize > 20) && (sideSize < 300) {
                collection.performBatchUpdates({ () -> Void in
                    layout.itemSize = CGSize(width: layout.itemSize.width * multiplier, height: layout.itemSize.height * multiplier)
                }, completion: { (completed) -> Void in
                    // Need to reload data, so a new thumbnail is applied for every cell
                    self.collection.reloadSections(NSIndexSet(index: 0))
                })
            }
        }
    }
    
    // MARK: UICollectionView Delegates Methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if mode == .Documents {
            return imagesPathsArray.count
        }
        
        return self.assetFetchResults.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GALLERY_CELL", forIndexPath: indexPath) as GalleryCell
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        let sideSize = cell.frame.width
        
        if mode == .Documents {
            ThumbnailGenerator.generateThumbnailFromFileAtPath(self.imagesPathsArray[indexPath.row] as? String, size: sideSize) { (thumbnailImage) -> Void in
                if let cell = self.collection.cellForItemAtIndexPath(indexPath) as? GalleryCell {
                    cell.imageView.image = thumbnailImage
                }
                cell.activityIndicator.stopAnimating()
            }
        }
        else {
            if imageManager == nil {
                imageManager = PHCachingImageManager()
            }
            
            var asset = self.assetFetchResults[indexPath.row] as PHAsset
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                self.imageManager.requestImageForAsset(asset, targetSize: CGSize(width: sideSize, height: sideSize), contentMode: .AspectFill, options: nil) { (image, info) -> Void in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if let cell = self.collection.cellForItemAtIndexPath(indexPath) as? GalleryCell {
                            cell.imageView.image = image
                        }
                        cell.activityIndicator.stopAnimating()
                    })
                }
                
                return
            })
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let delegate = delegate {
            if mode == .Documents {
                delegate.galleryVC(self, selectedImagePath: imagesPathsArray[indexPath.row] as String)
            }
            else {
                if let cell = collection.cellForItemAtIndexPath(indexPath) as? GalleryCell {
                    var asset = self.assetFetchResults[indexPath.row] as PHAsset
                    self.imageManager.requestImageForAsset(asset, targetSize: assetSizeFinal, contentMode: .AspectFill, options: nil, resultHandler: { (image, info) -> Void in
                        delegate.galleryVC(self, selectedImage: image)
                        return
                    })
                }
            }
        }
    }
    
    // MARK: UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        collection.dataSource = self
        collection.delegate = self
        collection.alwaysBounceVertical = true
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: "refreshSource:", forControlEvents: .ValueChanged)
        collection.addSubview(refreshControl)
        
        collection.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "pinched:"))
        
        fetchSource()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

}
