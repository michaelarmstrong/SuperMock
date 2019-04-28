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

    private func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // You could conditionally enable/disable this based on target macro or build parameter.
        let appBundle = Bundle(for: AppDelegate.self)
        SuperMock.beginMocking(appBundle)
        
        return true
    }
}

