//
//  PickerViewController.swift
//  Filterama
//
//  Created by Alex G on 13.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit

protocol PickerViewControllerDelegate : NSObjectProtocol {
    func galleryVC(galleryVC: PickerViewController, selectedImagePath: String)
}

enum PickerViewControllerMode {
    case Documents
    case PhotosFramework
}

class PickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    weak var delegate: PickerViewControllerDelegate?
    var mode: PickerViewControllerMode = .Documents
    private var imagesPathsArray = NSArray()

    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    // MARK: Private Methods
    
    private func documentsFilePaths() -> NSArray {
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
    }
    
    private func fetchSource() {
        activityIndicator.startAnimating()
        if mode == .Documents {
            imagesPathsArray = documentsFilePaths()
        }
        collection.reloadData()
        activityIndicator.stopAnimating()
    }
    
    // MARK: Public Methods
    
    func refreshSource(sender: UIRefreshControl) {
        fetchSource()
        sender.endRefreshing()
    }
    
    // MARK: UICollectionView Delegates Methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesPathsArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GALLERY_CELL", forIndexPath: indexPath) as GalleryCell
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        
        ThumbnailGenerator.generateThumbnailFromFileAtPath(self.imagesPathsArray[indexPath.row] as? String, size: 64) { (thumbnailImage) -> Void in
            if let cell = self.collection.cellForItemAtIndexPath(indexPath) as? GalleryCell {
                cell.imageView.image = thumbnailImage
            }
            cell.activityIndicator.stopAnimating()
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let delegate = delegate {
            delegate.galleryVC(self, selectedImagePath: imagesPathsArray[indexPath.row] as String)
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

}