//
//  GalleryViewController.swift
//  Filterama
//
//  Created by Alex G on 13.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit

protocol GalleryViewControllerDelegate : NSObjectProtocol {
    func galleryVC(galleryVC: GalleryViewController, selectedImagePath: String)
}

class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    weak var delegate: GalleryViewControllerDelegate?
    var imagesPathsArray = [String]()
    
    // MARK: Private Properties
    lazy private var imageConvertionQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 10
        return queue
    }()

    @IBOutlet weak var collection: UICollectionView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // MARK: Private Methods
    
    private func documentsFilePaths() -> [String] {
        var retVal = [String]()
        let fileManager = NSFileManager.defaultManager()
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as NSString
        var error: NSError?
        if let fileNames = fileManager.contentsOfDirectoryAtPath(documentsDirectory, error: &error) as? [String] {
            for fileName in fileNames {
                retVal.append(documentsDirectory.stringByAppendingPathComponent(fileName))
            }
        }
        return retVal
    }
    
    // MARK: UICollectionView Delegates Methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesPathsArray.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("GALLERY_CELL", forIndexPath: indexPath) as GalleryCell
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        
        // TODO: all operations finish in the same time. Fix it
        
        imageConvertionQueue.addOperationWithBlock { () -> Void in
            let image = UIImage(contentsOfFile: self.imagesPathsArray[indexPath.row])
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if let cell = self.collection.cellForItemAtIndexPath(indexPath) as? GalleryCell {
                    cell.imageView.image = image
                    cell.activityIndicator.stopAnimating()
                }
            })
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let image = UIImage(contentsOfFile: self.imagesPathsArray[indexPath.row])
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                println(NSDate())
                if let cell = self.collection.cellForItemAtIndexPath(indexPath) as? GalleryCell {
                    cell.imageView.image = image
                    cell.activityIndicator.stopAnimating()
                }
            })
        })
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let delegate = delegate {
            delegate.galleryVC(self, selectedImagePath: imagesPathsArray[indexPath.row])
        }
    }
    
    // MARK: UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        collection.dataSource = self
        collection.delegate = self
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        imageConvertionQueue.cancelAllOperations()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.startAnimating()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        imagesPathsArray = documentsFilePaths()
        collection.reloadData()
        activityIndicator.stopAnimating()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
