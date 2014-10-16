//
//  UIImage+Filterama.m
//  Filterama
//
//  Created by Alex G on 14.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

#import "UIImage+Filterama.h"
#import <ImageIO/ImageIO.h>

@implementation UIImage (Filterama)

+ (CGImageRef)newThumbnailImageFromData:(NSData *)data size:(CGFloat)imageSize
{
    CGImageRef        thumbnailImage = NULL;
    CGImageSourceRef  imageSource;
    CFDictionaryRef   options = NULL;
    CFStringRef       keys[3];
    CFTypeRef         values[3];
    CFNumberRef       thumbnailSize;
    
    //NSLog(@"%ld\n", (long)imageSize);
    
    // Create an image source from NSData; no options.
    imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    // Make sure the image source exists before continuing.
    if (imageSource == NULL){
        fprintf(stderr, "Image source is NULL.");
        return  NULL;
    }
    
    // Get image proportion
    CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
    NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
    CGSize imageSizeOriginal = CGSizeMake([width floatValue], [height floatValue]);
    CFRelease(imageProperties);
    CGFloat multiplier;
    if (imageSizeOriginal.width > imageSizeOriginal.height)
        multiplier = imageSizeOriginal.width / imageSizeOriginal.height;
    else
        multiplier = imageSizeOriginal.height / imageSizeOriginal.width;
    
    imageSize *= multiplier;
    
    // Package the integer as a  CFNumber object. Using CFTypes allows you
    // to more easily create the options dictionary later.
    thumbnailSize = CFNumberCreate(NULL, kCFNumberCGFloatType, &imageSize);
    //NSLog(@"%@\n", thumbnailSize);
    
    // Set up the thumbnail options.
    keys[0] = kCGImageSourceCreateThumbnailWithTransform;
    values[0] = (CFTypeRef)kCFBooleanTrue;
    keys[1] = kCGImageSourceCreateThumbnailFromImageAlways;
    values[1] = (CFTypeRef)kCFBooleanTrue;
    keys[2] = kCGImageSourceThumbnailMaxPixelSize;
    values[2] = (CFTypeRef)thumbnailSize;
    
    options = CFDictionaryCreate(NULL, (const void **)keys,
                                 (const void **)values, 3,
                                 &kCFTypeDictionaryKeyCallBacks,
                                 & kCFTypeDictionaryValueCallBacks);
    
    //NSLog(@"%@\n", options);
    
    // Create the thumbnail image using the specified options.
    thumbnailImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
    // Release the options dictionary and the image source
    // when you no longer need them.
    CFRelease(thumbnailSize);
    CFRelease(options);
    CFRelease(imageSource);
    
    //NSLog(@"%zu\n", CGImageGetWidth(thumbnailImage));
    
    // Make sure the thumbnail image exists before continuing.
    if (thumbnailImage == NULL){
        fprintf(stderr, "Thumbnail image not created from image source.");
        return NULL;
    }
    
    return thumbnailImage;
}


@end
