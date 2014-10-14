//
//  UIImage+Filterama.h
//  Filterama
//
//  Created by Alex G on 14.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Filterama)

+ (CGImageRef)createThumbnailImageFromData:(NSData *)data size:(NSNumber *)imageSizeNumber;

@end
