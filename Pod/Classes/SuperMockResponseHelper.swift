//
//  SuperMockResponseHelper.swift
//  SuperMock
//
//  Created by Michael Armstrong on 02/11/2015.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation

class SuperMockResponseHelper: NSObject {
    
    static let sharedHelper = SuperMockResponseHelper()
    
    class var bundleForMocks : NSBundle? {
        set {
            sharedHelper.bundle = newValue
        }
        get {
            return sharedHelper.bundle
        }
    }
    
    let fileManager = NSFileManager.defaultManager()
    var bundle : NSBundle? {
        didSet {
            loadDefinitions()
        }
    }
    
    /**
     Automatically populated by Mocks.plist. A dictionary containing mocks loaded in from Mocks.plist, purposely not made private as can be modified at runtime to
     provide alternative mocks for URL's on subsequent requests. Better support for this feature is coming in the future.
     */
    var mocks = Dictionary<String,AnyObject>()
    /**
     Automatically populated by Mocks.plist. Dictionary containing all the associated and supported mime.types for mocks. Defaults to text/plain if none provided.
     */
    var mimes = Dictionary<String,String>()

    enum RequestMethod : String {
        case POST = "POST"
        case GET = "GET"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    func loadDefinitions() {
        
        guard let bundle = bundle else {
            fatalError("You must provide a bundle via NSBundle(class:) or NSBundle.mainBundle() before continuing.")
        }
        
        let definitionsPath = bundle.pathForResource("Mocks", ofType: "plist")
        if let definitions = NSDictionary(contentsOfFile: definitionsPath!) as? Dictionary<String,AnyObject>,
            let mocks = definitions["mocks"] as? Dictionary<String,AnyObject>,
            let mimes = definitions["mimes"] as? Dictionary<String,String> {
            self.mocks = mocks
            self.mimes = mimes
        }
    }
    
    /**
     Public method to construct and return (when needed) mock NSURLRequest objects.
     
     - parameter request: the original NSURLRequest to provide a mock for.
     
     - returns: NSURLRequest with manipulated resource identifier.
     */
    func mockRequest(request: NSURLRequest) -> NSURLRequest {
        
        let requestMethod = RequestMethod(rawValue: request.HTTPMethod!)!
        
        let mockURL = mockURLForRequestURL(request.URL!, requestMethod: requestMethod, mocks: mocks)
        if mockURL == request.URL {
            return request
        }
        
        let mocked = request.mutableCopy() as! NSMutableURLRequest
        mocked.URL = mockURL
        mocked.setValue("true", forHTTPHeaderField: "X-SUPERMOCK-MOCKREQUEST")
        let injectableRequest = mocked.copy() as! NSURLRequest
        
        return injectableRequest

    }
    
    private func mockURLForRequestURL(url: NSURL, requestMethod: RequestMethod, mocks: Dictionary<String,AnyObject>) -> NSURL? {
        
        guard let definitionsForMethod = mocks[requestMethod.rawValue] as? Dictionary<String,AnyObject> else {
            fatalError("Couldn't find definitions for request: \(requestMethod) make sure to create a node for it in the plist")
        }
        
        if let responseFile = definitionsForMethod[url.absoluteString] as? NSString,
            let responsePath = bundle?.pathForResource(responseFile.stringByDeletingPathExtension, ofType: responseFile.pathExtension) {
                return NSURL(fileURLWithPath: responsePath)
        } else {
            return url
        }
    }
    
    /**
     Public method to return data for associated mock requests.
     
     Will fail with a fatalError if called for items that are not represented on the local filesystem.
     
     - parameter request: the mock NSURLRequest object.
     
     - returns: NSData containing the mock response.
     */
    func responseForMockRequest(request: NSURLRequest!) -> NSData? {

        if request.URL?.fileURL == false {
            fatalError("You should only call this on mocked URLs")
        }
        
        return mockedResponse(request.URL!)
    }
    
    /**
     Public method to return associated mimeTypes from the Mocks.plist configuration.
  
     Always returns a value. Defaults to "text/plain"
     
     - parameter url: Any NSURL object for which a mime.type is to be obtained.
     
     - returns: String containing RFC 6838 compliant mime.type
     */
    func mimeType(url: NSURL!) -> String {
        
        if let pathExtension = url.pathExtension {
            if let mime = mimes[pathExtension] {
                return mime
            }
        }
        return "text/plain"
    }

    private func mockedResponse(url: NSURL) -> NSData? {
        if let data = NSData(contentsOfURL: url) {
            return data
        }
        return nil
    }
    
}
