//
//  AppDelegate.swift
//  SuperMock
//
//  Created by Michael Armstrong on 11/02/2015.
//  Copyright (c) 2015 Michael Armstrong. All rights reserved.
//

import UIKit
import SuperMock

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        let appBundle = NSBundle(forClass: AppDelegate.self)
        SuperMock.beginMocking(appBundle)
            
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
    }


}

