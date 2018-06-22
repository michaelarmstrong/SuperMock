//
//  SuperMock.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import UIKit

open class SuperMock: NSObject {
    
    /**
     Begin stubbing responses to NSURLConnection / NSURLSession methods.
     
     By default only works for NSURLConnection and NSURLSession.sharedSession() objects. Will work also with any NSURLSession 
     that uses the defaultSessionConfiguration object. Support for custom session's is coming in the future.
     
     - parameter bundle: the bundle which contains your Mocks.plist (demo project contains example).
     - parameter @optional mocksFile: optional override for the default Mocks.plist if required.
     
     - returns: void
     */
    open class func beginMocking(_ bundle: Bundle!, mocksFile: String? = "Mocks.plist") {
        
        URLProtocol.registerClass(SuperMockURLProtocol.self)
        URLSessionConfiguration.default.protocolClasses = [SuperMockURLProtocol.self]
        URLSession.shared.configuration.protocolClasses?.append(SuperMockURLProtocol.self)
        
        SuperMockResponseHelper.bundleForMocks = bundle
        SuperMockResponseHelper.sharedHelper.mocking = true
    }
    
    open class func beginRecording(_ bundle: Bundle?, mocksFile: String? = "Mocks.plist", policy: RecordPolicy) {
        
        URLProtocol.registerClass(SuperMockRecordingURLProtocol.self)
        URLSessionConfiguration.default.protocolClasses = [SuperMockRecordingURLProtocol.self]
        URLSession.shared.configuration.protocolClasses?.append(SuperMockRecordingURLProtocol.self)
        
        SuperMockResponseHelper.bundleForMocks = bundle
        SuperMockResponseHelper.sharedHelper.recording = true
        SuperMockResponseHelper.sharedHelper.recordPolicy = policy
        
    }
    
    open class func endRecording() {
        URLProtocol.unregisterClass(SuperMockRecordingURLProtocol.self)
        SuperMockResponseHelper.sharedHelper.recording = false
    }
    
    /**
     End stubbing responses to NSURLConnection / NSURLSession methods
     
     - returns: void
     */
    open class func endMocking() {
        URLProtocol.unregisterClass(SuperMockURLProtocol.self)
    }

}
