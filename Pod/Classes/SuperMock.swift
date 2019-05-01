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
    open class func beginMocking(_ bundle: Bundle!,
                                 mocksFile: String = "Mocks.plist",
                                 urlProtocol: URLProtocol.Type = URLProtocol.self,
                                 configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                                 session: URLSession = URLSession.shared) {
        
        urlProtocol.registerClass(SuperMockURLProtocol.self)
        registerForMocking(configuration: configuration)
        
        session.configuration.protocolClasses?.append(SuperMockURLProtocol.self)

        SuperMockResponseHelper.sharedHelper.mocksFile = mocksFile
        SuperMockResponseHelper.bundleForMocks = bundle
        SuperMockResponseHelper.sharedHelper.mocking = true


    }
    
    open class func beginRecording(_ bundle: Bundle?,
                                   mocksFile: String = "Mocks.plist",
                                   policy: RecordPolicy = .Record,
                                   urlProtocol: URLProtocol.Type = URLProtocol.self,
                                   configuration: URLSessionConfiguration = URLSessionConfiguration.default,
                                   session: URLSession = URLSession.shared) {
        
        urlProtocol.registerClass(SuperMockRecordingURLProtocol.self)
        registerForRecording(configuration: configuration)
        session.configuration.protocolClasses?.append(SuperMockRecordingURLProtocol.self)
        
        SuperMockResponseHelper.sharedHelper.mocksFile = mocksFile
        SuperMockResponseHelper.bundleForMocks = bundle
        SuperMockResponseHelper.sharedHelper.recording = true
        SuperMockResponseHelper.sharedHelper.recordPolicy = policy
    }
    
    @objc
    open class func registerForMocking(configuration: URLSessionConfiguration) {
        var protocolClasses = [AnyClass]()
        protocolClasses.append(SuperMockURLProtocol.self)
        configuration.protocolClasses = protocolClasses
    }
    
    @objc
    open class func registerForRecording(configuration: URLSessionConfiguration) {
        var protocolClasses = [AnyClass]()
        protocolClasses.append(SuperMockRecordingURLProtocol.self)
        configuration.protocolClasses = protocolClasses
    }
    
    open class func endRecording(urlProtocol: URLProtocol.Type = URLProtocol.self) {
        urlProtocol.unregisterClass(SuperMockRecordingURLProtocol.self)
        SuperMockResponseHelper.sharedHelper.recording = false
    }
    
    /**
     End stubbing responses to NSURLConnection / NSURLSession methods
     
     - returns: void
     */
    open class func endMocking(urlProtocol: URLProtocol.Type = URLProtocol.self) {
        urlProtocol.unregisterClass(SuperMockURLProtocol.self)
        SuperMockResponseHelper.sharedHelper.mocking = false
    }
    
}
