//
//  SuperMock.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

public class SuperMock: NSObject {
    
    /**
     Begin stubbing responses to NSURLConnection / NSURLSession methods.
     
     By default only works for NSURLConnection and NSURLSession.sharedSession() objects. Will work also with any NSURLSession 
     that uses the defaultSessionConfiguration object. Support for custom session's is coming in the future.
     
     - parameter bundle: the bundle which contains your Mocks.plist (demo project contains example).
     - parameter @optional mocksFile: optional override for the default Mocks.plist if required.
     
     - returns: void
     */
    public class func beginMocking(bundle: NSBundle!, mocksFile: String? = "Mocks.plist") {
        
        NSURLProtocol.registerClass(SuperMockURLProtocol)
        NSURLSessionConfiguration.defaultSessionConfiguration().protocolClasses = [SuperMockURLProtocol.self]
        NSURLSession.sharedSession().configuration.protocolClasses?.append(SuperMockURLProtocol)
        
        SuperMockResponseHelper.mocksFileName  = mocksFile
        SuperMockResponseHelper.bundleForMocks = bundle
        SuperMockResponseHelper.sharedHelper.mocking = true
    }
    
    public class func beginRecording(bundle: NSBundle?, mocksFile: String? = "Mocks.plist", policy: RecordPolicy) {
        
        NSURLProtocol.registerClass(SuperMockRecordingURLProtocol)
        NSURLSessionConfiguration.defaultSessionConfiguration().protocolClasses = [SuperMockRecordingURLProtocol.self]
        NSURLSession.sharedSession().configuration.protocolClasses?.append(SuperMockRecordingURLProtocol)
        
        SuperMockResponseHelper.mocksFileName  = mocksFile
        SuperMockResponseHelper.bundleForMocks = bundle
        SuperMockResponseHelper.sharedHelper.recording = true
        SuperMockResponseHelper.sharedHelper.recordPolicy = policy
    }
    
    public class func endRecording() {
        NSURLProtocol.unregisterClass(SuperMockRecordingURLProtocol)
        SuperMockResponseHelper.sharedHelper.recording = false
    }
    
    /**
     End stubbing responses to NSURLConnection / NSURLSession methods
     
     - returns: void
     */
    public class func endMocking() {
        NSURLProtocol.unregisterClass(SuperMockURLProtocol)
    }

}
