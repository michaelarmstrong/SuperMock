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
    let maxFileLegth = 30
    
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
    
    enum RecordPolicy : String {
        case Override = "Override"
        case Record = "Record"
    }
    
    var recordPolicy = RecordPolicy.Record
    var recording = false
    
    func loadDefinitions() {
        
        guard let bundle = bundle else {
            fatalError("You must provide a bundle via NSBundle(class:) or NSBundle.mainBundle() before continuing.")
        }
        
        if let definitionsPath = bundle.pathForResource("Mocks", ofType: "plist"),
            let definitions = NSDictionary(contentsOfFile: definitionsPath) as? Dictionary<String,AnyObject>,
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
        
        if let responseFile = definitionsForMethod[url.absoluteString] as? String {
            
            if let responsePath = bundle?.pathForResource(responseFile, ofType: "") {
                return NSURL(fileURLWithPath: responsePath)
            } else if let responsePath = mockedResponseFilePath(url) {
                return NSURL(fileURLWithPath: responsePath)
            }
        }
        return url
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
    
    /**
     Record the data and save it in the mock file in the documents directory. The data is saved in a file with extension based on the mime of the request, the file name is unique dependent on the url of the request. The Mock file contains the request and the file name for the request data response.
     
     :param: data    data to save into the file
     :param: request Rapresent the request called for obtain the data
     */
    func recordDataForRequest(data: NSData?, request: NSURLRequest) {
        
        guard let definitionsPath = mockFileOutOfBundle(),
            let definitions = NSMutableDictionary(contentsOfFile: definitionsPath),
            let absoluteString = request.URL?.absoluteString,
            let httpMethod = request.HTTPMethod,
            let url = request.URL,
            let responseFile = mockedResponseFileName(url),
            let responsePath = mockedResponseFilePath(url),
            let data = data else {
                return
        }
        data.writeToFile(responsePath, atomically: true)
        let keyPath = "mocks.\(httpMethod)"
        if let mocks = definitions.valueForKeyPath(keyPath) as? NSMutableDictionary {
            
            if let _ = mocks["\(absoluteString)"] where recordPolicy == .Record {
                return
            }
            mocks["\(absoluteString)"] = responseFile
            
            if !definitions.writeToFile(definitionsPath, atomically: true) {
                print("Error writning the file, permission problems?")
            }
        }
    }
    
}

// MARK: File extension
extension SuperMockResponseHelper {
    
    private func fileType(mimeType: String) -> String {
        
        switch (mimeType) {
        case "text/plain":
            return "txt"
        case "text/html":
            return "html"
        case "application/json":
            return "json"
        default:
            return "txt"
        }
    }
    
    private func mockedResponseFilePath(url: NSURL)->String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        
        guard let fileName =  mockedResponseFileName(url),
            let filePath = documentsDirectory?.stringByAppendingString("/\(fileName)") else {
                return nil
        }
        
        print("Mocked response recorded in: \(filePath)")
        return filePath
    }
    
    private func mockedResponseFileName(url: NSURL)->String? {
        
        var urlString = url.absoluteString
        let urlStringLengh = urlString.characters.count
        let fromIndex = (urlStringLengh > maxFileLegth) ?maxFileLegth : urlStringLengh
        urlString = urlString.substringFromIndex(urlString.endIndex.advancedBy(-fromIndex))
        guard let fileName = urlString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet()) else {
            fatalError("You must provide a request with a valid URL")
        }
        return  fileName + "." + fileType(mimeType(url))
    }
    
    private func mockFileOutOfBundle()->String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as? String
        guard let mockPath = documentsDirectory?.stringByAppendingString("/Mocks.plist"),
            let bundle = bundle else {
                return nil
        }
        
        if !NSFileManager.defaultManager().fileExistsAtPath(mockPath),
            let definitionsPath = bundle.pathForResource("Mocks", ofType: "plist"),
            let definitions = NSMutableDictionary(contentsOfFile: definitionsPath) {
                definitions.writeToFile(mockPath, atomically: true)
        } else {
            let mockDictionary = NSDictionary(dictionary:["mimes":[["htm":"text/html"],["html":"text/html"],["json":"application/json"]],["mocks"]:[["DELETE":[:]],["POST":[:]],["PUT":[:]],["GET":[:]]]])
            mockDictionary.writeToFile(mockPath, atomically: true)
        }
        
        return mockPath
    }
}

