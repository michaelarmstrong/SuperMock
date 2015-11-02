//
//  SuperMock.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

class SuperMock: NSObject {
    
    class func beginMocking(bundle: NSBundle!, mocksFile: String? = "Mocks.plist") {
        
        NSURLProtocol.registerClass(SuperMockURLProtocol)
        NSURLSessionConfiguration.defaultSessionConfiguration().protocolClasses = [SuperMockURLProtocol.self]
        NSURLSession.sharedSession().configuration.protocolClasses?.append(SuperMockURLProtocol)
        
        SuperMockResponseHelper.bundleForMocks = bundle
    
    }
    
    class func endMocking() {
        NSURLProtocol.unregisterClass(SuperMockURLProtocol)
    }

}
