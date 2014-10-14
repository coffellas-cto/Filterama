//
//  AppDelegate.swift
//  Filterama
//
//  Created by Alex G on 13.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import UIKit
import OpenGLES

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    lazy var grpahicsContext: CIContext? = {
        return CIContext(EAGLContext: EAGLContext(API: EAGLRenderingAPI.OpenGLES2), options: [kCIContextWorkingColorSpace: NSNull()])
    }()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Populate some data on first run
        let notFirstRunKey = "notFirstRunKey"
        let notFirstRun = NSUserDefaults.standardUserDefaults().objectForKey(notFirstRunKey) as Bool?
        if notFirstRun == nil {
            println("First run")
            let fileManager = NSFileManager.defaultManager()
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as NSString
            
            for i in 1...5 {
                let picName = "pic0\(i)"
                let toPath = documentsDirectory.stringByAppendingPathComponent("\(picName).jpg")
                var error: NSError?
                fileManager.copyItemAtPath(NSBundle.mainBundle().pathForResource(picName, ofType: "jpg")!, toPath: toPath, error: &error)
            }
            
            PersistenceManager.manager.populateFilters()
            
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: notFirstRunKey)
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
        PersistenceManager.manager.saveContext()
    }
    
}

