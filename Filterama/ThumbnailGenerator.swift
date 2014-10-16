//
//  ThumbnailGenerator.swift
//  Filterama
//
//  Created by Alex G on 14.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import Foundation
import UIKit

class ThumbnailGenerator {
    class func generateThumbnailForImage(image: UIImage?, var size: CGFloat, completion: (thumbnailImage: UIImage?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let data = UIImagePNGRepresentation(image)
            self.generateThumbnailFromData(data, size: size, completion: { (thumbnailImage) -> Void in
                completion(thumbnailImage: thumbnailImage)
            })
        })
    }
    
    class func generateThumbnailFromFileAtPath(path: String?, var size: CGFloat, completion: (thumbnailImage: UIImage?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            if let path = path {
                let data = NSData(contentsOfFile: path)
                self.generateThumbnailFromData(data, size: size, completion: { (thumbnailImage) -> Void in
                    completion(thumbnailImage: thumbnailImage)
                })
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(thumbnailImage: nil)
            })
        })
    }
    
    class func generateThumbnailFromData(imageData: NSData?, var size: CGFloat, completion: (thumbnailImage: UIImage?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            if imageData != nil {
                let scale = UIScreen.mainScreen().scale
                size *= scale
                if let thumbnailImageRef = UIImage.newThumbnailImageFromData(imageData, size: size) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let image = UIImage(CGImage: thumbnailImageRef.takeUnretainedValue())
                        //println(image.size.width)
                        completion(thumbnailImage: image)
                    })
                    return
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion(thumbnailImage: nil)
            })
        })
    }
    
}