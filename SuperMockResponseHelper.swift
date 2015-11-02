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
    
    var mocks = Dictionary<String,AnyObject>()
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
    

    func responseForMockRequest(request: NSURLRequest!) -> NSData? {

        if request.URL?.fileURL == false {
            fatalError("You should only call this on mocked URLs")
        }
        
        return mockedResponse(request.URL!)
    }
    
    func mimeType(url: NSURL!) -> String? {
        return mimes[url.pathExtension!]
    }

    private func mockedResponse(url: NSURL) -> NSData? {
        if let data = NSData(contentsOfURL: url) {
            return data
        }
        return nil
    }
    
}
